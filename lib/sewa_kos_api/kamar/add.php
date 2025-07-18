<?php
// api/kamar/add.php

require_once '../config/database.php';
require_once '../utils/auth_check.php';

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-User-ID, X-User-Role');

// Handle OPTIONS request for CORS preflight
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $data = json_decode(file_get_contents('php://input'), true);

    $user_id_from_header = $_SERVER['HTTP_X_USER_ID'] ?? '';
    $user_role_from_header = $_SERVER['HTTP_X_USER_ROLE'] ?? '';

    // Otorisasi: hanya pemilik_kos yang bisa menambah kamar
    $authorized_user_id = checkAuthorization(['pemilik_kos'], [
        'user_id' => $user_id_from_header,
        'role_name' => $user_role_from_header
    ]);

    $kos_id = $data['kos_id'] ?? '';
    $nama_kamar = $data['nama_kamar'] ?? '';
    $harga_sewa = $data['harga_sewa'] ?? '';
    $luas_kamar = $data['luas_kamar'] ?? null;
    $fasilitas = $data['fasilitas'] ?? null;

    // Validasi input
    if (empty($kos_id) || !is_numeric($kos_id) || empty($nama_kamar) || empty($harga_sewa) || !is_numeric($harga_sewa) || $harga_sewa <= 0) {
        http_response_code(400);
        echo json_encode(['status' => 'error', 'message' => 'ID Kos, nama kamar, dan harga sewa wajib diisi dan valid.']);
        exit();
    }

    try {
        $pdo = getDBConnection();
        $pdo->beginTransaction();

        // 1. Verifikasi kepemilikan Kos: Pastikan Kos_ID ini dimiliki oleh user yang sedang login
        $stmt_kos_owner = $pdo->prepare("SELECT user_id FROM kos WHERE id = ?");
        $stmt_kos_owner->execute([$kos_id]);
        $kos_info = $stmt_kos_owner->fetch();

        if (!$kos_info) {
            http_response_code(404);
            echo json_encode(['status' => 'error', 'message' => 'Kos tidak ditemukan.']);
            $pdo->rollBack();
            exit();
        }
        if ($kos_info['user_id'] != $authorized_user_id) {
            http_response_code(403);
            echo json_encode(['status' => 'error', 'message' => 'Anda tidak diizinkan menambahkan kamar ke kos ini.']);
            $pdo->rollBack();
            exit();
        }

        // 2. Masukkan data kamar baru
        $stmt_add_kamar = $pdo->prepare("INSERT INTO kamar_kos (kos_id, nama_kamar, harga_sewa, luas_kamar, fasilitas) VALUES (?, ?, ?, ?, ?)");
        $stmt_add_kamar->execute([$kos_id, $nama_kamar, $harga_sewa, $luas_kamar, $fasilitas]);
        $kamar_id = $pdo->lastInsertId();

        $pdo->commit();

        echo json_encode(['status' => 'success', 'message' => 'Kamar berhasil ditambahkan.', 'id' => $kamar_id]);
        http_response_code(201); // Created

    } catch (PDOException $e) {
        $pdo->rollBack();
        error_log("Error adding kamar: " . $e->getMessage());
        http_response_code(500);
        echo json_encode(['status' => 'error', 'message' => 'Gagal menambahkan kamar.']);
    }

} else {
    http_response_code(405);
    echo json_encode(['status' => 'error', 'message' => 'Metode request tidak diizinkan. Hanya POST.']);
}
?>