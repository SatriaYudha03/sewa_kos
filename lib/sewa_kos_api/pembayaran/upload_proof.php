<?php
// api/pembayaran/upload_proof.php

error_reporting(E_ALL);
ini_set('display_errors', 1);
ini_set('log_errors', 1);
ini_set('error_log', '../../php_error.log');

require_once '../config/database.php';
require_once '../utils/auth_check.php';

header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-User-ID, X-User-Role');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    header('Access-Control-Allow-Origin: *');
    header('Access-Control-Allow-Methods: POST, GET, OPTIONS');
    header('Access-Control-Allow-Headers: Origin, X-Requested-With, Content-Type, Accept, Authorization, X-User-ID, X-User-Role');
    header('Access-Control-Max-Age: 3600');
    http_response_code(200);
    exit();
}

// Hanya izinkan POST request
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $user_id_from_header = $_SERVER['HTTP_X_USER_ID'] ?? '';
    $user_role_from_header = $_SERVER['HTTP_X_USER_ROLE'] ?? '';

    // Hanya penyewa yang bisa upload bukti pembayaran
    $authorized_user_id = checkAuthorization(['penyewa'], [
        'user_id' => $user_id_from_header,
        'role_name' => $user_role_from_header
    ]);

    $pemesanan_id = $_POST['pemesanan_id'] ?? null;
    $jumlah_bayar = $_POST['jumlah_bayar'] ?? null;
    $metode_pembayaran = $_POST['metode_pembayaran'] ?? null;

    // Validasi input dasar
    if (!$pemesanan_id || !$jumlah_bayar || !$metode_pembayaran || !isset($_FILES['bukti_pembayaran'])) {
        http_response_code(400);
        echo json_encode(['status' => 'error', 'message' => 'Data tidak lengkap.']);
        exit();
    }

    $file = $_FILES['bukti_pembayaran'];
    $upload_dir = '../../uploads/bukti_pembayaran/'; // Direktori penyimpanan bukti pembayaran
    $file_extension = pathinfo($file['name'], PATHINFO_EXTENSION);
    $new_file_name = uniqid('bukti_') . '.' . $file_extension;
    $target_file = $upload_dir . $new_file_name;
    $file_path_for_db = 'uploads/bukti_pembayaran/' . $new_file_name; // Path relatif untuk DB

    // Pastikan direktori upload ada
    if (!is_dir($upload_dir)) {
        mkdir($upload_dir, 0777, true);
    }

    // Pindahkan file yang diupload
    if (move_uploaded_file($file['tmp_name'], $target_file)) {
        try {
            $pdo = getDBConnection();
            $pdo->beginTransaction();

            // 1. Masukkan data pembayaran ke tabel 'pembayaran'
            $stmt_pembayaran = $pdo->prepare("INSERT INTO pembayaran (pemesanan_id, jumlah_bayar, metode_pembayaran, bukti_pembayaran, tanggal_pembayaran) VALUES (?, ?, ?, ?, NOW())");
            $stmt_pembayaran->execute([$pemesanan_id, $jumlah_bayar, $metode_pembayaran, $file_path_for_db]);
            $pembayaran_id = $pdo->lastInsertId();

            // 2. Update status pemesanan menjadi 'menunggu_verifikasi'
            $stmt_pemesanan = $pdo->prepare("UPDATE pemesanan SET status_pemesanan = 'menunggu_verifikasi' WHERE id = ? AND user_id = ?");
            $stmt_pemesanan->execute([$pemesanan_id, $authorized_user_id]);

            if ($stmt_pemesanan->rowCount() == 0) {
                throw new Exception("Pemesanan tidak ditemukan atau Anda tidak memiliki izin untuk mengupdate.");
            }

            $pdo->commit();
            http_response_code(200);
            echo json_encode(['status' => 'success', 'message' => 'Bukti pembayaran berhasil diunggah dan menunggu verifikasi.']);

        } catch (PDOException $e) {
            $pdo->rollBack();
            error_log("Database error during payment upload: " . $e->getMessage());
            http_response_code(500);
            echo json_encode(['status' => 'error', 'message' => 'Terjadi kesalahan database saat mengunggah bukti pembayaran.']);
        } catch (Exception $e) {
            $pdo->rollBack();
            error_log("Application error during payment upload: " . $e->getMessage());
            http_response_code(500);
            echo json_encode(['status' => 'error', 'message' => $e->getMessage()]);
        }
    } else {
        http_response_code(500);
        echo json_encode(['status' => 'error', 'message' => 'Gagal mengunggah file bukti pembayaran.']);
    }

} else {
    http_response_code(405);
    echo json_encode(['status' => 'error', 'message' => 'Metode request tidak diizinkan. Hanya POST.']);
}
?>