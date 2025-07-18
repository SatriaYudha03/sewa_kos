<?php
// api/kamar/detail.php

require_once '../config/database.php';
require_once '../utils/auth_check.php';

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-User-ID, X-User-Role');

// Handle OPTIONS request for CORS preflight
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    $kamar_id = $_GET['id'] ?? '';

    $user_id_from_header = $_SERVER['HTTP_X_USER_ID'] ?? '';
    $user_role_from_header = $_SERVER['HTTP_X_USER_ROLE'] ?? 'penyewa';

    checkAuthorization(['penyewa', 'pemilik_kos'], [
        'user_id' => $user_id_from_header,
        'role_name' => $user_role_from_header
    ]);

    if (empty($kamar_id) || !is_numeric($kamar_id)) {
        http_response_code(400);
        echo json_encode(['status' => 'error', 'message' => 'ID Kamar wajib diisi dan harus berupa angka.']);
        exit();
    }

    try {
        $pdo = getDBConnection();
        $stmt = $pdo->prepare("SELECT mk.*, k.user_id as kos_owner_id, k.nama_kos, k.alamat
                               FROM kamar_kos mk
                               JOIN kos k ON mk.kos_id = k.id
                               WHERE mk.id = ?");
        $stmt->execute([$kamar_id]);
        $kamar_detail = $stmt->fetch();

        if ($kamar_detail) {
            // Otorisasi tambahan: Pemilik kos hanya boleh melihat detail kamar di kos miliknya
            if ($user_role_from_header === 'pemilik_kos' && $kamar_detail['kos_owner_id'] != $user_id_from_header) {
                http_response_code(403);
                echo json_encode(['status' => 'error', 'message' => 'Anda tidak memiliki akses ke detail kamar ini.']);
                exit();
            }

            echo json_encode(['status' => 'success', 'data' => $kamar_detail]);
            http_response_code(200);
        } else {
            http_response_code(404);
            echo json_encode(['status' => 'error', 'message' => 'Kamar tidak ditemukan.']);
        }

    } catch (PDOException $e) {
        error_log("Error fetching kamar detail: " . $e->getMessage());
        http_response_code(500);
        echo json_encode(['status' => 'error', 'message' => 'Gagal mengambil detail kamar.']);
    }

} else {
    http_response_code(405);
    echo json_encode(['status' => 'error', 'message' => 'Metode request tidak diizinkan. Hanya GET.']);
}
?>