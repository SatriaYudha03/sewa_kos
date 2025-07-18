<?php
// api/kamar/list_by_kos.php

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
    $kos_id = $_GET['kos_id'] ?? '';

    $user_id_from_header = $_SERVER['HTTP_X_USER_ID'] ?? '';
    $user_role_from_header = $_SERVER['HTTP_X_USER_ROLE'] ?? 'penyewa'; // Default penyewa

    // Otorisasi: semua role bisa melihat, tapi scope-nya beda
    checkAuthorization(['penyewa', 'pemilik_kos'], [
        'user_id' => $user_id_from_header,
        'role_name' => $user_role_from_header
    ]);

    if (empty($kos_id) || !is_numeric($kos_id)) {
        http_response_code(400);
        echo json_encode(['status' => 'error', 'message' => 'ID Kos wajib diisi dan harus berupa angka.']);
        exit();
    }

    try {
        $pdo = getDBConnection();

        // Verifikasi kepemilikan Kos jika user adalah pemilik_kos
        $stmt_kos_owner = $pdo->prepare("SELECT user_id FROM kos WHERE id = ?");
        $stmt_kos_owner->execute([$kos_id]);
        $kos_info = $stmt_kos_owner->fetch();

        if (!$kos_info) {
            http_response_code(404);
            echo json_encode(['status' => 'error', 'message' => 'Kos tidak ditemukan.']);
            exit();
        }

        if ($user_role_from_header === 'pemilik_kos' && $kos_info['user_id'] != $user_id_from_header) {
            http_response_code(403);
            echo json_encode(['status' => 'error', 'message' => 'Anda tidak diizinkan melihat kamar di kos ini.']);
            exit();
        }

        $sql = "SELECT * FROM kamar_kos WHERE kos_id = ?";
        $params = [$kos_id];

        // Jika user adalah penyewa, hanya tampilkan kamar yang 'tersedia'
        if ($user_role_from_header === 'penyewa') {
            $sql .= " AND status = 'tersedia'";
        }

        $sql .= " ORDER BY nama_kamar ASC";

        $stmt = $pdo->prepare($sql);
        $stmt->execute($params);
        $kamar_list = $stmt->fetchAll();

        if ($kamar_list) {
            echo json_encode(['status' => 'success', 'data' => $kamar_list]);
            http_response_code(200);
        } else {
            echo json_encode(['status' => 'success', 'message' => 'Tidak ada kamar ditemukan untuk kos ini.', 'data' => []]);
            http_response_code(200);
        }

    } catch (PDOException $e) {
        error_log("Error fetching kamar list by kos: " . $e->getMessage());
        http_response_code(500);
        echo json_encode(['status' => 'error', 'message' => 'Gagal mengambil daftar kamar.']);
    }

} else {
    http_response_code(405);
    echo json_encode(['status' => 'error', 'message' => 'Metode request tidak diizinkan. Hanya GET.']);
}
?>