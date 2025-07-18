<?php
// api/pemesanan/update_status.php

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

    $pemesanan_id = $data['id'] ?? '';
    $new_status = $data['status'] ?? ''; // 'terkonfirmasi', 'dibatalkan', 'selesai'

    $user_id_from_header = $_SERVER['HTTP_X_USER_ID'] ?? '';
    $user_role_from_header = $_SERVER['HTTP_X_USER_ROLE'] ?? '';

    // Hanya pemilik_kos yang bisa update status pemesanan
    $authorized_user_id = checkAuthorization(['pemilik_kos'], [
        'user_id' => $user_id_from_header,
        'role_name' => $user_role_from_header
    ]);

    if (empty($pemesanan_id) || !is_numeric($pemesanan_id) || empty($new_status)) {
        http_response_code(400);
        echo json_encode(['status' => 'error', 'message' => 'ID Pemesanan dan status baru wajib diisi.']);
        exit();
    }

    // Validasi status yang diizinkan
    $allowed_statuses = ['terkonfirmasi', 'dibatalkan', 'selesai'];
    if (!in_array($new_status, $allowed_statuses)) {
        http_response_code(400);
        echo json_encode(['status' => 'error', 'message' => 'Status tidak valid. Pilih dari: ' . implode(', ', $allowed_statuses)]);
        exit();
    }

    try {
        $pdo = getDBConnection();
        $pdo->beginTransaction();

        // 1. Ambil detail pemesanan dan kos terkait untuk verifikasi kepemilikan
        $stmt = $pdo->prepare("SELECT p.user_id, p.kamar_id, mk.kos_id, k.user_id as kos_owner_id, p.status_pemesanan as current_status
                               FROM pemesanan p
                               JOIN kamar_kos mk ON p.kamar_id = mk.id
                               JOIN kos k ON mk.kos_id = k.id
                               WHERE p.id = ?");
        $stmt->execute([$pemesanan_id]);
        $pemesanan_info = $stmt->fetch();

        if (!$pemesanan_info) {
            http_response_code(404);
            echo json_encode(['status' => 'error', 'message' => 'Pemesanan tidak ditemukan.']);
            $pdo->rollBack();
            exit();
        }

        // 2. Verifikasi kepemilikan kos
        if ($pemesanan_info['kos_owner_id'] != $authorized_user_id) {
            http_response_code(403);
            echo json_encode(['status' => 'error', 'message' => 'Anda tidak diizinkan memperbarui status pemesanan ini.']);
            $pdo->rollBack();
            exit();
        }

        // 3. Update status pemesanan
        $stmt_update_pemesanan = $pdo->prepare("UPDATE pemesanan SET status_pemesanan = ? WHERE id = ?");
        $stmt_update_pemesanan->execute([$new_status, $pemesanan_id]);

        // 4. Logika tambahan berdasarkan status baru
        if ($new_status === 'dibatalkan') {
            // Jika pemesanan dibatalkan, ubah status kamar kembali menjadi 'tersedia'
            $stmt_update_kamar = $pdo->prepare("UPDATE kamar_kos SET status = 'tersedia' WHERE id = ?");
            $stmt_update_kamar->execute([$pemesanan_info['kamar_id']]);
        }
        // Tambahkan logika lain jika status berubah ke 'selesai' atau 'terkonfirmasi'
        // Misalnya, saat 'terkonfirmasi', mungkin bisa kirim notifikasi ke penyewa.
        // Atau saat 'selesai', bisa memicu proses review.

        $pdo->commit();

        echo json_encode(['status' => 'success', 'message' => 'Status pemesanan berhasil diperbarui menjadi ' . $new_status . '.']);
        http_response_code(200);

    } catch (PDOException $e) {
        $pdo->rollBack();
        error_log("Error updating pemesanan status: " . $e->getMessage());
        http_response_code(500);
        echo json_encode(['status' => 'error', 'message' => 'Gagal memperbarui status pemesanan.']);
    }

} else {
    http_response_code(405);
    echo json_encode(['status' => 'error', 'message' => 'Metode request tidak diizinkan. Hanya PUT.']);
}
?>