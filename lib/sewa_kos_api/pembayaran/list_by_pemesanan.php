<?php
// api/pembayaran/list_by_pemesanan.php

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
    $pemesanan_id = $_GET['pemesanan_id'] ?? '';

    $user_id_from_header = $_SERVER['HTTP_X_USER_ID'] ?? '';
    $user_role_from_header = $_SERVER['HTTP_X_USER_ROLE'] ?? '';

    checkAuthorization(['penyewa', 'pemilik_kos'], [
        'user_id' => $user_id_from_header,
        'role_name' => $user_role_from_header
    ]);

    if (empty($pemesanan_id) || !is_numeric($pemesanan_id)) {
        http_response_code(400);
        echo json_encode(['status' => 'error', 'message' => 'ID Pemesanan wajib diisi dan harus berupa angka.']);
        exit();
    }

    try {
        $pdo = getDBConnection();

        // Ambil info pemesanan untuk verifikasi kepemilikan/akses
        $stmt_pemesanan_info = $pdo->prepare("SELECT p.user_id as tenant_id, mk.kos_id, k.user_id as kos_owner_id
                                              FROM pemesanan p
                                              JOIN kamar_kos mk ON p.kamar_id = mk.id
                                              JOIN kos k ON mk.kos_id = k.id
                                              WHERE p.id = ?");
        $stmt_pemesanan_info->execute([$pemesanan_id]);
        $pemesanan_info = $stmt_pemesanan_info->fetch();

        if (!$pemesanan_info) {
            http_response_code(404);
            echo json_encode(['status' => 'error', 'message' => 'Pemesanan tidak ditemukan.']);
            exit();
        }

        // Otorisasi: hanya penyewa dari pemesanan ini, ATAU pemilik kos dari kos yang dipesan
        if ($user_role_from_header === 'penyewa' && $pemesanan_info['tenant_id'] != $user_id_from_header) {
            http_response_code(403);
            echo json_encode(['status' => 'error', 'message' => 'Anda tidak diizinkan melihat riwayat pembayaran untuk pemesanan ini.']);
            exit();
        } elseif ($user_role_from_header === 'pemilik_kos' && $pemesanan_info['kos_owner_id'] != $user_id_from_header) {
            http_response_code(403);
            echo json_encode(['status' => 'error', 'message' => 'Anda tidak diizinkan melihat riwayat pembayaran untuk pemesanan ini.']);
            exit();
        }

        // Ambil daftar pembayaran
        $stmt_payments = $pdo->prepare("SELECT * FROM detail_pembayaran WHERE pemesanan_id = ? ORDER BY created_at DESC");
        $stmt_payments->execute([$pemesanan_id]);
        $payments_list = $stmt_payments->fetchAll();

        if ($payments_list) {
            echo json_encode(['status' => 'success', 'data' => $payments_list]);
            http_response_code(200);
        } else {
            echo json_encode(['status' => 'success', 'message' => 'Tidak ada riwayat pembayaran untuk pemesanan ini.', 'data' => []]);
            http_response_code(200);
        }

    } catch (PDOException $e) {
        error_log("Error fetching payment list: " . $e->getMessage());
        http_response_code(500);
        echo json_encode(['status' => 'error', 'message' => 'Gagal mengambil daftar pembayaran.']);
    }

} else {
    http_response_code(405);
    echo json_encode(['status' => 'error', 'message' => 'Metode request tidak diizinkan. Hanya GET.']);
}
?>