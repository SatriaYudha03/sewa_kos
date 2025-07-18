<?php
// api/pembayaran/verify.php

require_once '../config/database.php';
require_once '../utils/auth_check.php';

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: PUT, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-User-ID, X-User-Role');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

if ($_SERVER['REQUEST_METHOD'] === 'PUT') {
    $data = json_decode(file_get_contents('php://input'), true);

    $detail_pembayaran_id = $data['id'] ?? '';
    $status_verifikasi = $data['status'] ?? ''; // 'terverifikasi' atau 'gagal'

    $user_id_from_header = $_SERVER['HTTP_X_USER_ID'] ?? '';
    $user_role_from_header = $_SERVER['HTTP_X_USER_ROLE'] ?? '';

    // Hanya pemilik_kos yang bisa memverifikasi pembayaran
    $authorized_user_id = checkAuthorization(['pemilik_kos'], [
        'user_id' => $user_id_from_header,
        'role_name' => $user_role_from_header
    ]);

    if (empty($detail_pembayaran_id) || !is_numeric($detail_pembayaran_id) || empty($status_verifikasi)) {
        http_response_code(400);
        echo json_encode(['status' => 'error', 'message' => 'ID Detail Pembayaran dan status verifikasi wajib diisi.']);
        exit();
    }

    $allowed_statuses_verifikasi = ['terverifikasi', 'gagal'];
    if (!in_array($status_verifikasi, $allowed_statuses_verifikasi)) {
        http_response_code(400);
        echo json_encode(['status' => 'error', 'message' => 'Status verifikasi tidak valid. Pilih dari: ' . implode(', ', $allowed_statuses_verifikasi)]);
        exit();
    }

    try {
        $pdo = getDBConnection();
        $pdo->beginTransaction();

        // 1. Ambil detail pembayaran dan pemesanan terkait untuk verifikasi kepemilikan
        $stmt_pembayaran = $pdo->prepare("SELECT dp.pemesanan_id, p.user_id as tenant_id, p.status_pemesanan as pemesanan_current_status, mk.kos_id, k.user_id as kos_owner_id
                                           FROM detail_pembayaran dp
                                           JOIN pemesanan p ON dp.pemesanan_id = p.id
                                           JOIN kamar_kos mk ON p.kamar_id = mk.id
                                           JOIN kos k ON mk.kos_id = k.id
                                           WHERE dp.id = ?");
        $stmt_pembayaran->execute([$detail_pembayaran_id]);
        $pembayaran_info = $stmt_pembayaran->fetch();

        if (!$pembayaran_info) {
            http_response_code(404);
            echo json_encode(['status' => 'error', 'message' => 'Detail pembayaran tidak ditemukan.']);
            $pdo->rollBack();
            exit();
        }

        // 2. Verifikasi kepemilikan kos oleh pemilik kos
        if ($pembayaran_info['kos_owner_id'] != $authorized_user_id) {
            http_response_code(403);
            echo json_encode(['status' => 'error', 'message' => 'Anda tidak diizinkan memverifikasi pembayaran ini.']);
            $pdo->rollBack();
            exit();
        }
        
        // 3. Update status detail pembayaran
        $stmt_update_detail_pembayaran = $pdo->prepare("UPDATE detail_pembayaran SET status_pembayaran = ? WHERE id = ?");
        $stmt_update_detail_pembayaran->execute([$status_verifikasi, $detail_pembayaran_id]);

        // 4. Update status pemesanan jika pembayaran terverifikasi
        if ($status_verifikasi === 'terverifikasi') {
            $stmt_update_pemesanan_status = $pdo->prepare("UPDATE pemesanan SET status_pemesanan = 'terkonfirmasi' WHERE id = ?");
            $stmt_update_pemesanan_status->execute([$pembayaran_info['pemesanan_id']]);

            // Opsional: Kirim notifikasi ke penyewa bahwa pembayaran sudah terverifikasi
        } else if ($status_verifikasi === 'gagal') {
            // Jika pembayaran gagal diverifikasi, mungkin perlu ubah status pemesanan kembali ke 'menunggu_pembayaran'
            // Atau ke 'pembayaran_gagal' jika ada status itu.
            // Untuk saat ini, kita biarkan saja status pemesanan tetap 'menunggu_pembayaran' agar penyewa bisa coba lagi.
            // Atau jika ingin tegas, ubah ke 'dibatalkan'
            // $stmt_update_pemesanan_status = $pdo->prepare("UPDATE pemesanan SET status_pemesanan = 'dibatalkan' WHERE id = ?");
            // $stmt_update_pemesanan_status->execute([$pembayaran_info['pemesanan_id']]);
        }

        $pdo->commit();

        echo json_encode(['status' => 'success', 'message' => 'Status pembayaran berhasil diperbarui menjadi ' . $status_verifikasi . '.']);
        http_response_code(200);

    } catch (PDOException $e) {
        $pdo->rollBack();
        error_log("Error verifying payment: " . $e->getMessage());
        http_response_code(500);
        echo json_encode(['status' => 'error', 'message' => 'Gagal memverifikasi pembayaran.']);
    }

} else {
    http_response_code(405);
    echo json_encode(['status' => 'error', 'message' => 'Metode request tidak diizinkan. Hanya PUT.']);
}
?>