<?php
// api/auth/profile.php

require_once '../../config/database.php';
require_once '../../utils/auth_check.php';

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *'); // Sesuaikan di produksi
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-User-ID, X-User-Role');

// Handle OPTIONS request for CORS preflight
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    $user_id_from_header = $_SERVER['HTTP_X_USER_ID'] ?? '';
    $user_role_from_header = $_SERVER['HTTP_X_USER_ROLE'] ?? '';

    // Pastikan user terautentikasi dan ID serta role ada
    $authorized_user_id = checkAuthorization(['penyewa', 'pemilik_kos'], [
        'user_id' => $user_id_from_header,
        'role_name' => $user_role_from_header
    ]);

    try {
        $pdo = getDBConnection();

        // Ambil data user lengkap dari database
        $stmt = $pdo->prepare("SELECT u.id, u.username, u.email, u.nama_lengkap, u.no_telepon, r.role_name
                               FROM users u
                               JOIN roles r ON u.role_id = r.id
                               WHERE u.id = ?");
        $stmt->execute([$authorized_user_id]);
        $user_data = $stmt->fetch();

        if ($user_data) {
            echo json_encode(['status' => 'success', 'data' => $user_data]);
            http_response_code(200);
        } else {
            http_response_code(404);
            echo json_encode(['status' => 'error', 'message' => 'Profil pengguna tidak ditemukan.']);
        }

    } catch (PDOException $e) {
        error_log("Error fetching user profile: " . $e->getMessage());
        http_response_code(500);
        echo json_encode(['status' => 'error', 'message' => 'Gagal mengambil profil pengguna.']);
    }

} else {
    http_response_code(405);
    echo json_encode(['status' => 'error', 'message' => 'Metode request tidak diizinkan. Hanya GET.']);
}
?>