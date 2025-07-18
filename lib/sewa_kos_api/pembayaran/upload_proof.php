<?php
// api/pembayaran/upload_proof.php

require_once '../config/database.php';
require_once '../utils/auth_check.php';

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-User-ID, X-User-Role');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $data = json_decode(file_get_contents('php://input'), true);

    $pemesanan_id = $data['pemesanan_id'] ?? '';
    $jumlah_bayar = $data['jumlah_bayar'] ?? '';
    $metode_pembayaran = $data['metode_pembayaran'] ?? '';
    $bukti_transfer_url = $data['bukti_transfer_url'] ?? null; // URL atau path ke bukti transfer yang diupload

    $user_id_from_header = $_SERVER['HTTP_X_USER_ID'] ?? '';
    $user_role_from_header = $_SERVER['HTTP_X_USER_ROLE'] ?? '';

    // Hanya penyewa yang bisa mengupload bukti pembayaran
    $authorized_user_id = checkAuthorization(['penyewa'], [
        'user_id' => $user_id_from_header,
        'role_name' => $user_role_from_header
    ]);

    if (empty($pemesanan_id) || !is_numeric($pemesanan_id) || empty($jumlah_bayar) || !is_numeric($jumlah_bayar) || empty($metode_pembayaran)) {
        http_response_code(400);
        echo json_encode(['status' => 'error', 'message' => 'ID Pemesanan, jumlah bayar, dan metode pembayaran wajib diisi dan valid.']);
        exit();
    }

    try {
        $pdo = getDBConnection();
        $pdo->beginTransaction();

        // 1. Verifikasi bahwa pemesanan adalah milik user yang sedang login
        $stmt_pemesanan = $pdo->prepare("SELECT user_id, status_pemesanan, total_harga FROM pemesanan WHERE id = ?");
        $stmt_pemesanan->execute([$pemesanan_id]);
        $pemesanan = $stmt_pemesanan->fetch();

        if (!$pemesanan) {
            http_response_code(404);
            echo json_encode(['status' => 'error', 'message' => 'Pemesanan tidak ditemukan.']);
            $pdo->rollBack();
            exit();
        }

        if ($pemesanan['user_id'] != $authorized_user_id) {
            http_response_code(403);
            echo json_encode(['status' => 'error', 'message' => 'Anda tidak diizinkan mengupload bukti pembayaran untuk pemesanan ini.']);
            $pdo->rollBack();
            exit();
        }

        if ($pemesanan['status_pemesanan'] !== 'menunggu_pembayaran') {
            http_response_code(409);
            echo json_encode(['status' => 'error', 'message' => 'Pemesanan tidak dalam status "menunggu pembayaran".']);
            $pdo->rollBack();
            exit();
        }
        
        // Opsional: Cek apakah jumlah bayar sesuai atau mendekati total_harga
        // if ($jumlah_bayar < $pemesanan['total_harga']) {
        //     http_response_code(400);
        //     echo json_encode(['status' => 'error', 'message' => 'Jumlah pembayaran kurang dari total harga pemesanan.']);
        //     $pdo->rollBack();
        //     exit();
        // }

        // 2. Masukkan data pembayaran
        $stmt_pembayaran = $pdo->prepare("INSERT INTO detail_pembayaran (pemesanan_id, jumlah_bayar, metode_pembayaran, bukti_transfer, status_pembayaran) VALUES (?, ?, ?, ?, 'menunggu_verifikasi')");
        $stmt_pembayaran->execute([$pemesanan_id, $jumlah_bayar, $metode_pembayaran, $bukti_transfer_url]);

        // 3. Opsional: Update status pemesanan jika pembayaran berhasil diupload (misal menjadi 'menunggu_verifikasi_pembayaran')
        // Ini bisa diabaikan jika status pemesanan hanya berubah saat pemilik kos memverifikasi.
        // Untuk saat ini, kita biarkan status pemesanan tetap 'menunggu_pembayaran' sampai pemilik kos memverifikasi
        // Atau Anda bisa menambahkan status baru seperti 'menunggu_verifikasi_pembayaran' di ENUM pemesanan.status_pemesanan

        $pdo->commit();

        echo json_encode(['status' => 'success', 'message' => 'Bukti pembayaran berhasil diupload. Menunggu verifikasi.']);
        http_response_code(201);

    } catch (PDOException $e) {
        $pdo->rollBack();
        error_log("Error uploading payment proof: " . $e->getMessage());
        http_response_code(500);
        echo json_encode(['status' => 'error', 'message' => 'Gagal mengupload bukti pembayaran.']);
    }

} else {
    http_response_code(405);
    echo json_encode(['status' => 'error', 'message' => 'Metode request tidak diizinkan. Hanya POST.']);
}
?>