<?php
// api/kamar/update.php

require_once '../config/database.php';
require_once '../utils/auth_check.php';

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: PUT, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-User-ID, X-User-Role');

// Handle OPTIONS request for CORS preflight
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

if ($_SERVER['REQUEST_METHOD'] === 'PUT') {
    $data = json_decode(file_get_contents('php://input'), true);

    $kamar_id = $data['id'] ?? '';

    $user_id_from_header = $_SERVER['HTTP_X_USER_ID'] ?? '';
    $user_role_from_header = $_SERVER['HTTP_X_USER_ROLE'] ?? '';

    // Otorisasi: hanya pemilik_kos yang bisa update kamar
    $authorized_user_id = checkAuthorization(['pemilik_kos'], [
        'user_id' => $user_id_from_header,
        'role_name' => $user_role_from_header
    ]);

    if (empty($kamar_id) || !is_numeric($kamar_id)) {
        http_response_code(400);
        echo json_encode(['status' => 'error', 'message' => 'ID Kamar wajib diisi dan harus berupa angka.']);
        exit();
    }

    $nama_kamar = $data['nama_kamar'] ?? null;
    $harga_sewa = $data['harga_sewa'] ?? null;
    $luas_kamar = $data['luas_kamar'] ?? null;
    $fasilitas = $data['fasilitas'] ?? null;
    $status = $data['status'] ?? null; // Status kamar: 'tersedia', 'terisi', 'perbaikan'

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
            echo json_encode(['status' => 'error', 'message' => 'Anda tidak diizinkan memperbarui kamar ini.']);
            $pdo->rollBack();
            exit();
        }

        // 2. Siapkan query UPDATE secara dinamis
        $set_parts = [];
        $params = [];

        if ($nama_kamar !== null) {
            $set_parts[] = 'nama_kamar = ?';
            $params[] = $nama_kamar;
        }
        if ($harga_sewa !== null && is_numeric($harga_sewa)) {
            $set_parts[] = 'harga_sewa = ?';
            $params[] = $harga_sewa;
        }
        if ($luas_kamar !== null) {
            $set_parts[] = 'luas_kamar = ?';
            $params[] = $luas_kamar;
        }
        if ($fasilitas !== null) {
            $set_parts[] = 'fasilitas = ?';
            $params[] = $fasilitas;
        }
        if ($status !== null && in_array($status, ['tersedia', 'terisi', 'perbaikan'])) {
            $set_parts[] = 'status = ?';
            $params[] = $status;
        }

        if (empty($set_parts)) {
            http_response_code(400);
            echo json_encode(['status' => 'info', 'message' => 'Tidak ada data untuk diperbarui.']);
            $pdo->rollBack();
            exit();
        }

        $sql = "UPDATE kamar_kos SET " . implode(', ', $set_parts) . " WHERE id = ?";
        $params[] = $kamar_id;

        $stmt = $pdo->prepare($sql);
        $stmt->execute($params);

        if ($stmt->rowCount() > 0) {
            $pdo->commit();
            echo json_encode(['status' => 'success', 'message' => 'Data kamar berhasil diperbarui.']);
            http_response_code(200);
        } else {
            $pdo->rollBack();
            echo json_encode(['status' => 'info', 'message' => 'Tidak ada perubahan pada data kamar atau kamar tidak ditemukan.']);
            http_response_code(200);
        }

    } catch (PDOException $e) {
        $pdo->rollBack();
        error_log("Error updating kamar: " . $e->getMessage());
        http_response_code(500);
        echo json_encode(['status' => 'error', 'message' => 'Gagal memperbarui kamar.']);
    }

} else {
    http_response_code(405);
    echo json_encode(['status' => 'error', 'message' => 'Metode request tidak diizinkan. Hanya PUT.']);
}
?>