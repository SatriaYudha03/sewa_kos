<?php
// api/auth/update_profile.php

// --- DEBUGGING SANGAT AGRESIF (HAPUS ini di produksi!) ---
error_reporting(E_ALL); 
ini_set('display_errors', 1);
ini_set('log_errors', 1);
ini_set('error_log', '../../php_error.log'); 

error_log("UPDATE_PROFILE.PHP DEBUG: Script execution started. Request Method: " . $_SERVER['REQUEST_METHOD']);

// --- HEADER CORS UNIVERSAL ---
header('Access-Control-Allow-Origin: *'); 
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS'); 
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-User-ID, X-User-Role'); 

// --- IMPORTS ---
require_once '../config/database.php';
require_once '../utils/auth_check.php';

// --- HANDLE PREFLIGHT OPTIONS REQUEST ---
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    error_log("UPDATE_PROFILE.PHP DEBUG: Handling OPTIONS request.");
    header('Access-Control-Allow-Origin: *'); 
    header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS'); 
    header('Access-Control-Allow-Headers: Origin, X-Requested-With, Content-Type, Accept, Authorization, X-User-ID, X-User-Role'); 
    header('Access-Control-Max-Age: 3600'); 
    http_response_code(200); 
    exit(); 
}

// --- LOGIKA UTAMA UNTUK PUT REQUEST ---
if ($_SERVER['REQUEST_METHOD'] === 'PUT') {
    error_log("UPDATE_PROFILE.PHP DEBUG: Handling PUT request.");
    $raw_input = file_get_contents('php://input');
    $data = json_decode($raw_input, true);

    error_log("UPDATE_PROFILE.PHP DEBUG: Raw input: " . $raw_input);
    error_log("UPDATE_PROFILE.PHP DEBUG: Decoded data: " . print_r($data, true));

    $user_id_from_header = $_SERVER['HTTP_X_USER_ID'] ?? '';
    $user_role_from_header = $_SERVER['HTTP_X_USER_ROLE'] ?? '';

    // Otentikasi dan otorisasi: user hanya bisa update profilnya sendiri
    $authorized_user_id = checkAuthorization(['penyewa', 'pemilik_kos'], [
        'user_id' => $user_id_from_header,
        'role_name' => $user_role_from_header
    ]);

    // Data yang bisa diupdate dari request
    $nama_lengkap = $data['nama_lengkap'] ?? null;
    $no_telepon = $data['no_telepon'] ?? null;

    // Validasi minimal: setidaknya salah satu field harus ada untuk diupdate
    if (empty($nama_lengkap) && empty($no_telepon)) {
        http_response_code(400);
        echo json_encode(['status' => 'error', 'message' => 'Setidaknya Nama Lengkap atau Nomor Telepon harus diisi untuk diperbarui.']);
        error_log("UPDATE_PROFILE.PHP DEBUG: No valid fields provided for update.");
        exit();
    }

    try {
        $pdo = getDBConnection();
        $pdo->beginTransaction();

        $set_parts = [];
        $params = [];

        if ($nama_lengkap !== null) {
            $set_parts[] = 'nama_lengkap = ?';
            $params[] = $nama_lengkap;
        }
        if ($no_telepon !== null) {
            $set_parts[] = 'no_telepon = ?';
            $params[] = $no_telepon;
        }
        
        // Hanya update jika ada bagian yang perlu di-set
        if (empty($set_parts)) {
            http_response_code(200);
            echo json_encode(['status' => 'info', 'message' => 'Tidak ada perubahan yang diminta.']);
            $pdo->rollBack();
            error_log("UPDATE_PROFILE.PHP DEBUG: No actual fields to update after processing nulls.");
            exit();
        }

        $sql = "UPDATE users SET " . implode(', ', $set_parts) . " WHERE id = ?";
        $params[] = $authorized_user_id;

        $stmt = $pdo->prepare($sql);
        $stmt->execute($params);

        if ($stmt->rowCount() > 0) {
            $pdo->commit();
            http_response_code(200);
            echo json_encode(['status' => 'success', 'message' => 'Profil berhasil diperbarui.']);
            error_log("UPDATE_PROFILE.PHP DEBUG: Profile updated successfully for user ID: $authorized_user_id.");
        } else {
            $pdo->rollBack();
            http_response_code(200);
            echo json_encode(['status' => 'info', 'message' => 'Tidak ada perubahan pada profil atau user tidak ditemukan.']);
            error_log("UPDATE_PROFILE.PHP DEBUG: No rows affected for user ID: $authorized_user_id.");
        }

    } catch (PDOException $e) {
        $pdo->rollBack();
        error_log("UPDATE_PROFILE.PHP DEBUG: PDOException: " . $e->getMessage());
        http_response_code(500);
        echo json_encode(['status' => 'error', 'message' => 'Gagal memperbarui profil (Database Error).']);
    } catch (Exception $e) { 
        $pdo->rollBack();
        error_log("UPDATE_PROFILE.PHP DEBUG: General Exception: " . $e->getMessage());
        http_response_code(500);
        echo json_encode(['status' => 'error', 'message' => 'Terjadi kesalahan internal.']);
    }

} else {
    http_response_code(405);
    echo json_encode(['status' => 'error', 'message' => 'Metode request tidak diizinkan. Hanya PUT.']);
    error_log("UPDATE_PROFILE.PHP DEBUG: Invalid request method: " . $_SERVER['REQUEST_METHOD']);
}
?>