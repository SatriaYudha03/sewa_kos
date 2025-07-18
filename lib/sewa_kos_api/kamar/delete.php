<?php
// api/kamar/delete.php

require_once '../config/database.php';
require_once '../utils/auth_check.php';

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-User-ID, X-User-Role');

// Handle OPTIONS request for CORS preflight
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

if ($_SERVER['REQUEST_METHOD'] === 'DELETE') {
    $data = json_decode(file_get_contents('php://input'), true);
    $kamar_id = $data['id'] ?? '';

    $user_id_from_header = $_SERVER['HTTP_X_USER_ID'] ?? '';
    $user_role_from_header = $_SERVER['HTTP_X_USER_ROLE'] ?? '';

    // Otorisasi: hanya pemilik_kos yang bisa menghapus kamar
    $authorized_user_id = checkAuthorization(['pemilik_kos'], [
        'user_id' => $user_id_from_header,
        'role_name' => $user_role_from_header
    ]);

    if (empty($kamar_id) || !is_numeric($kamar_id)) {
        http_response_code(400);
        echo json_encode(['status' => 'error', 'message' => 'ID Kamar wajib diisi dan harus berupa angka.']);
        exit();
    }

    try {
        $pdo = getDBConnection();
        $pdo->beginTransaction();

        // 1. Ambil info kamar dan kos terkait untuk verifikasi kepemilikan
        $stmt_kamar_info = $pdo->prepare("SELECT mk.kos_id, k.user_id as kos_owner_id FROM kamar_kos mk JOIN kos k ON mk.kos_id = k.id WHERE mk.id = ?");
        $stmt_kamar_info->execute([$kamar_id]);
        $kamar_info = $stmt_kamar_info->fetch();

        if (!$kamar_info) {
            http_response_code(404);
            echo json_encode(['status' => 'error', 'message' => 'Kamar tidak ditemukan.']);
            $pdo->rollBack();
            exit();
        }
        if ($kamar_info['kos_owner_id'] != $authorized_user_id) {
            http_response_code(403);
            echo json_encode(['status' => 'error', 'message' => 'Anda tidak diizinkan menghapus kamar ini.']);
            $pdo->rollBack();
            exit();
        }

        // 2. Hapus pemesanan terkait dengan kamar ini terlebih dahulu (jika ada)
        // Atau Anda bisa menambahkan ON DELETE CASCADE di FK pemesanan.kamar_id
        $stmt_delete_pemesanan = $pdo->prepare("DELETE FROM pemesanan WHERE kamar_id = ?");
        $stmt_delete_pemesanan->execute([$kamar_id]);

        // 3. Hapus data kamar
        $stmt_delete_kamar = $pdo->prepare("DELETE FROM kamar_kos WHERE id = ?");
        $stmt_delete_kamar->execute([$kamar_id]);

        if ($stmt_delete_kamar->rowCount() > 0) {
            $pdo->commit();
            echo json_encode(['status' => 'success', 'message' => 'Kamar dan pemesanan terkait berhasil dihapus.']);
            http_response_code(200);
        } else {
            $pdo->rollBack();
            echo json_encode(['status' => 'info', 'message' => 'Kamar tidak ditemukan atau tidak ada perubahan.']);
            http_response_code(200);
        }

    } catch (PDOException $e) {
        $pdo->rollBack();
        error_log("Error deleting kamar: " . $e->getMessage());
        http_response_code(500);
        echo json_encode(['status' => 'error', 'message' => 'Gagal menghapus kamar.']);
    }

} else {
    http_response_code(405);
    echo json_encode(['status' => 'error', 'message' => 'Metode request tidak diizinkan. Hanya DELETE.']);
}
?>