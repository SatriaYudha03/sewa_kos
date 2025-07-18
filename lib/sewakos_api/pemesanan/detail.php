<?php
// api/pemesanan/detail.php

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
    $pemesanan_id = $_GET['id'] ?? '';

    // Ambil data user dari header
    $user_id_from_header = $_SERVER['HTTP_X_USER_ID'] ?? '';
    $user_role_from_header = $_SERVER['HTTP_X_USER_ROLE'] ?? '';

    // Memastikan user terautentikasi dan memiliki role yang diizinkan untuk melihat detail pemesanan
    checkAuthorization(['penyewa', 'pemilik_kos'], [
        'user_id' => $user_id_from_header,
        'role_name' => $user_role_from_header
    ]);

    // Validasi input ID pemesanan
    if (empty($pemesanan_id) || !is_numeric($pemesanan_id)) {
        http_response_code(400);
        echo json_encode(['status' => 'error', 'message' => 'ID Pemesanan wajib diisi dan harus berupa angka.']);
        exit();
    }

    try {
        $pdo = getDBConnection();
        
        // Query untuk mengambil detail pemesanan beserta informasi terkait
        // Ditambahkan 'k.user_id AS kos_owner_id' untuk memudahkan otorisasi pemilik kos
        $stmt = $pdo->prepare("SELECT p.*, mk.nama_kamar, mk.harga_sewa, k.nama_kos, k.alamat,
                                     u_tenant.username as tenant_username, u_tenant.nama_lengkap as tenant_name,
                                     u_owner.username as owner_username, u_owner.nama_lengkap as owner_name,
                                     k.user_id AS kos_owner_id -- ID pemilik kos ditambahkan di sini
                               FROM pemesanan p
                               JOIN kamar_kos mk ON p.kamar_id = mk.id
                               JOIN kos k ON mk.kos_id = k.id
                               JOIN users u_tenant ON p.user_id = u_tenant.id
                               JOIN users u_owner ON k.user_id = u_owner.id
                               WHERE p.id = ?");
        $stmt->execute([$pemesanan_id]);
        $pemesanan_detail = $stmt->fetch();

        if ($pemesanan_detail) {
            // Logika otorisasi:
            // 1. Jika user adalah 'penyewa', pastikan pemesanan ini miliknya.
            // 2. Jika user adalah 'pemilik_kos', pastikan kos dari pemesanan ini adalah miliknya.
            if ($user_role_from_header === 'penyewa' && $pemesanan_detail['user_id'] != $user_id_from_header) {
                http_response_code(403); // Forbidden
                echo json_encode(['status' => 'error', 'message' => 'Anda tidak memiliki akses ke detail pemesanan ini.']);
                exit();
            } elseif ($user_role_from_header === 'pemilik_kos' && $pemesanan_detail['kos_owner_id'] != $user_id_from_header) {
                http_response_code(403); // Forbidden
                echo json_encode(['status' => 'error', 'message' => 'Anda tidak memiliki akses ke detail pemesanan ini.']);
                exit();
            }

            // Jika otorisasi lolos, kirim data detail pemesanan
            echo json_encode(['status' => 'success', 'data' => $pemesanan_detail]);
            http_response_code(200);
        } else {
            // Jika pemesanan tidak ditemukan
            http_response_code(404); // Not Found
            echo json_encode(['status' => 'error', 'message' => 'Pemesanan tidak ditemukan.']);
        }

    } catch (PDOException $e) {
        // Tangani kesalahan database
        error_log("Error fetching pemesanan detail: " . $e->getMessage()); // Catat error ke log server
        http_response_code(500); // Internal Server Error
        echo json_encode(['status' => 'error', 'message' => 'Gagal mengambil detail pemesanan.']);
    }

} else {
    // Metode request tidak diizinkan
    http_response_code(405); // Method Not Allowed
    echo json_encode(['status' => 'error', 'message' => 'Metode request tidak diizinkan. Hanya GET.']);
}
?>