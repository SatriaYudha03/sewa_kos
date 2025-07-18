<?php
// api/pemesanan/list_by_user.php

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
    $user_id_from_header = $_SERVER['HTTP_X_USER_ID'] ?? '';
    $user_role_from_header = $_SERVER['HTTP_X_USER_ROLE'] ?? '';

    // Hanya penyewa yang bisa melihat daftar pemesanan mereka
    $authorized_user_id = checkAuthorization(['penyewa'], [
        'user_id' => $user_id_from_header,
        'role_name' => $user_role_from_header
    ]);

    try {
        $pdo = getDBConnection();
        $stmt = $pdo->prepare("SELECT p.*, mk.nama_kamar, mk.harga_sewa, k.nama_kos, k.alamat
                               FROM pemesanan p
                               JOIN kamar_kos mk ON p.kamar_id = mk.id
                               JOIN kos k ON mk.kos_id = k.id
                               WHERE p.user_id = ?
                               ORDER BY p.created_at DESC");
        $stmt->execute([$authorized_user_id]);
        $pemesanan_list = $stmt->fetchAll();

        if ($pemesanan_list) {
            echo json_encode(['status' => 'success', 'data' => $pemesanan_list]);
            http_response_code(200);
        } else {
            echo json_encode(['status' => 'success', 'message' => 'Tidak ada pemesanan ditemukan.', 'data' => []]);
            http_response_code(200);
        }

    } catch (PDOException $e) {
        error_log("Error fetching user pemesanan list: " . $e->getMessage());
        http_response_code(500);
        echo json_encode(['status' => 'error', 'message' => 'Gagal mengambil daftar pemesanan.']);
    }

} else {
    http_response_code(405);
    echo json_encode(['status' => 'error', 'message' => 'Metode request tidak diizinkan. Hanya GET.']);
}
?>