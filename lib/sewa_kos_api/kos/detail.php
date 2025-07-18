<?php
// api/kos/detail.php (DIUPDATE)

require_once '../config/database.php';
require_once '../utils/auth_check.php';

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-User-ID, X-User-Role');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    $kos_id = $_GET['id'] ?? '';

    $user_id_from_header = $_SERVER['HTTP_X_USER_ID'] ?? '';
    $user_role_from_header = $_SERVER['HTTP_X_USER_ROLE'] ?? 'penyewa';

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
        $stmt = $pdo->prepare("SELECT k.*, u.username as owner_username, u.nama_lengkap as owner_name 
                               FROM kos k 
                               JOIN users u ON k.user_id = u.id 
                               WHERE k.id = ?");
        $stmt->execute([$kos_id]);
        $kos_detail = $stmt->fetch();

        if ($kos_detail) {
            // Otorisasi tambahan: Pemilik kos hanya boleh melihat detail kos miliknya sendiri
            if ($user_role_from_header === 'pemilik_kos' && $kos_detail['user_id'] != $user_id_from_header) {
                http_response_code(403);
                echo json_encode(['status' => 'error', 'message' => 'Anda tidak memiliki akses ke detail kos ini.']);
                exit();
            }

            echo json_encode(['status' => 'success', 'data' => $kos_detail]);
            http_response_code(200);
        } else {
            http_response_code(404);
            echo json_encode(['status' => 'error', 'message' => 'Kos tidak ditemukan.']);
        }

    } catch (PDOException $e) {
        error_log("Error fetching kos detail: " . $e->getMessage());
        http_response_code(500);
        echo json_encode(['status' => 'error', 'message' => 'Gagal mengambil detail kos.']);
    }

} else {
    http_response_code(405);
    echo json_encode(['status' => 'error', 'message' => 'Metode request tidak diizinkan. Hanya GET.']);
}
?>