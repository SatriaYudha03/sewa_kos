<?php
// api/pemesanan/create.php

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

    $user_id_from_header = $_SERVER['HTTP_X_USER_ID'] ?? '';
    $user_role_from_header = $_SERVER['HTTP_X_USER_ROLE'] ?? '';

    // Hanya penyewa yang bisa membuat pemesanan
    $authorized_user_id = checkAuthorization(['penyewa'], [
        'user_id' => $user_id_from_header,
        'role_name' => $user_role_from_header
    ]);

    $kamar_id = $data['kamar_id'] ?? '';
    $tanggal_mulai = $data['tanggal_mulai'] ?? '';
    $durasi_sewa = $data['durasi_sewa'] ?? ''; // Dalam bulan

    // Validasi input
    if (empty($kamar_id) || !is_numeric($kamar_id) || empty($tanggal_mulai) || empty($durasi_sewa) || !is_numeric($durasi_sewa) || $durasi_sewa <= 0) {
        http_response_code(400);
        echo json_encode(['status' => 'error', 'message' => 'ID Kamar, tanggal mulai, dan durasi sewa wajib diisi dan valid.']);
        exit();
    }

    try {
        $pdo = getDBConnection();
        $pdo->beginTransaction(); // Mulai transaksi

        // 1. Ambil detail kamar dan cek statusnya
        $stmt_kamar = $pdo->prepare("SELECT harga_sewa, status FROM kamar_kos WHERE id = ?");
        $stmt_kamar->execute([$kamar_id]);
        $kamar = $stmt_kamar->fetch();

        if (!$kamar) {
            http_response_code(404);
            echo json_encode(['status' => 'error', 'message' => 'Kamar tidak ditemukan.']);
            $pdo->rollBack();
            exit();
        }

        if ($kamar['status'] !== 'tersedia') {
            http_response_code(409); // Conflict
            echo json_encode(['status' => 'error', 'message' => 'Kamar tidak tersedia untuk disewa. Status: ' . $kamar['status']]);
            $pdo->rollBack();
            exit();
        }

        // 2. Hitung total harga
        $total_harga = $kamar['harga_sewa'] * $durasi_sewa;

        // 3. Masukkan data pemesanan
        $stmt_pemesanan = $pdo->prepare("INSERT INTO pemesanan (user_id, kamar_id, tanggal_mulai, durasi_sewa, total_harga, status_pemesanan) VALUES (?, ?, ?, ?, ?, 'menunggu_pembayaran')");
        $stmt_pemesanan->execute([$authorized_user_id, $kamar_id, $tanggal_mulai, $durasi_sewa, $total_harga]);
        $pemesanan_id = $pdo->lastInsertId();

        // 4. Update status kamar menjadi 'terisi' (atau 'pending_booking' jika ada status itu)
        // Untuk saat ini, kita langsung ubah menjadi 'terisi' setelah pemesanan dibuat.
        // Anda mungkin ingin status 'pending' sampai pembayaran diverifikasi.
        $stmt_update_kamar = $pdo->prepare("UPDATE kamar_kos SET status = 'terisi' WHERE id = ?");
        $stmt_update_kamar->execute([$kamar_id]);

        $pdo->commit(); // Commit transaksi jika semua berhasil

        echo json_encode([
            'status' => 'success',
            'message' => 'Pemesanan berhasil dibuat. Menunggu pembayaran.',
            'pemesanan_id' => $pemesanan_id,
            'total_harga' => $total_harga
        ]);
        http_response_code(201);

    } catch (PDOException $e) {
        $pdo->rollBack(); // Rollback jika ada error
        error_log("Error creating pemesanan: " . $e->getMessage());
        http_response_code(500);
        echo json_encode(['status' => 'error', 'message' => 'Gagal membuat pemesanan.']);
    }

} else {
    http_response_code(405);
    echo json_encode(['status' => 'error', 'message' => 'Metode request tidak diizinkan. Hanya POST.']);
}
?>