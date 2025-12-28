<?php
// api/kos/detail.php (DIUPDATE: Tambah kolom has_image)

// --- DEBUGGING SANGAT AGRESIF (HAPUS ini di produksi!) ---
error_reporting(E_ALL);
ini_set('display_errors', 1);
ini_set('log_errors', 1);
ini_set('error_log', '../php_error.log');

error_log("KOS DETAIL DEBUG: Script execution started. Request Method: " . $_SERVER['REQUEST_METHOD']);

// --- HEADER CORS UNIVERSAL ---
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-User-ID, X-User-Role');

// --- IMPORTS ---
require_once '../config/database.php';
require_once '../utils/auth_check.php';

// --- HANDLE PREFLIGHT OPTIONS REQUEST ---
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    error_log("KOS DETAIL DEBUG: Handling OPTIONS request.");
    header('Access-Control-Allow-Origin: *');
    header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
    header('Access-Control-Allow-Headers: Origin, X-Requested-With, Content-Type, Accept, Authorization, X-User-ID, X-User-Role');
    http_response_code(200);
    exit();
}

if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    $kos_id = $_GET['id'] ?? '';

    $user_id_from_header = $_SERVER['HTTP_X_USER_ID'] ?? '';
    $user_role_from_header = $_SERVER['HTTP_X_USER_ROLE'] ?? 'penyewa';

    error_log("KOS DETAIL DEBUG: Request received. Kos ID: $kos_id, User ID: $user_id_from_header, Role: $user_role_from_header");

    checkAuthorization(['penyewa', 'pemilik_kos'], [
        'user_id' => $user_id_from_header,
        'role_name' => $user_role_from_header
    ]);

    if (empty($kos_id) || !is_numeric($kos_id)) {
        http_response_code(400);
        echo json_encode(['status' => 'error', 'message' => 'ID Kos wajib diisi dan harus berupa angka.']);
        error_log("KOS DETAIL DEBUG: Missing or invalid Kos ID.");
        exit();
    }

    try {
        $pdo = getDBConnection();
        // --- Query menggunakan kolom foto_utama_url sesuai schema database ---
        $stmt = $pdo->prepare("SELECT k.id, k.user_id, k.nama_kos, k.alamat, k.deskripsi, k.fasilitas_umum, k.foto_utama_url, k.created_at, k.updated_at,
                                     (k.foto_utama_url IS NOT NULL) AS has_image,
                                     u.username as owner_username, u.nama_lengkap as owner_name 
                               FROM kos k 
                               JOIN users u ON k.user_id = u.id 
                               WHERE k.id = ?");
        $stmt->execute([$kos_id]);
        $kos_detail = $stmt->fetch();

        if ($kos_detail) {
            if ($user_role_from_header === 'pemilik_kos' && $kos_detail['user_id'] != $user_id_from_header) {
                http_response_code(403);
                echo json_encode(['status' => 'error', 'message' => 'Anda tidak memiliki akses ke detail kos ini.']);
                error_log("KOS DETAIL DEBUG: Access denied for owner on Kos ID $kos_id (owner is ${kos_detail['user_id']}, requested by $user_id_from_header).");
                exit();
            }

            echo json_encode(['status' => 'success', 'data' => $kos_detail]);
            http_response_code(200);
            error_log("KOS DETAIL DEBUG: Kos detail found for ID: $kos_id. Data: " . print_r($kos_detail, true));
        } else {
            http_response_code(404);
            echo json_encode(['status' => 'error', 'message' => 'Kos tidak ditemukan.']);
            error_log("KOS DETAIL DEBUG: Kos with ID $kos_id not found.");
        }
    } catch (PDOException $e) {
        error_log("KOS DETAIL DEBUG: PDOException: " . $e->getMessage());
        http_response_code(500);
        echo json_encode(['status' => 'error', 'message' => 'Gagal mengambil detail kos (Database Error).']);
    }
} else {
    http_response_code(405);
    echo json_encode(['status' => 'error', 'message' => 'Metode request tidak diizinkan. Hanya GET.']);
    error_log("KOS DETAIL DEBUG: Invalid request method: " . $_SERVER['REQUEST_METHOD']);
}
