<?php
// api/auth/profile.php (REVISI LENGKAP dengan Debugging & CORS)

// --- DEBUGGING SANGAT AGRESIF (HAPUS ini di produksi!) ---
error_reporting(E_ALL); 
ini_set('display_errors', 1);
ini_set('log_errors', 1);
ini_set('error_log', '../../php_error.log'); // Lokasi log error PHP (pastikan path ini ada)

error_log("PROFILE.PHP DEBUG: Script execution started. Request Method: " . $_SERVER['REQUEST_METHOD']);

// --- HEADER CORS UNIVERSAL ---
header('Access-Control-Allow-Origin: *'); 
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS'); 
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-User-ID, X-User-Role'); 

// --- IMPORTS ---
require_once '../config/database.php';
require_once '../utils/auth_check.php';

// --- HANDLE PREFLIGHT OPTIONS REQUEST ---
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    error_log("PROFILE.PHP DEBUG: Handling OPTIONS request.");
    header('Access-Control-Allow-Origin: *'); 
    header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS'); 
    header('Access-Control-Allow-Headers: Origin, X-Requested-With, Content-Type, Accept, Authorization, X-User-ID, X-User-Role'); 
    header('Access-Control-Max-Age: 3600'); 
    http_response_code(200); 
    exit(); 
}

// --- LOGIKA UTAMA UNTUK GET REQUEST ---
if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    error_log("PROFILE.PHP DEBUG: Handling GET request.");

    $user_id_from_header = $_SERVER['HTTP_X_USER_ID'] ?? '';
    $user_role_from_header = $_SERVER['HTTP_X_USER_ROLE'] ?? '';

    // Otentikasi dan otorisasi: user hanya bisa update profilnya sendiri
    $authorized_user_id = checkAuthorization(['penyewa', 'pemilik_kos'], [
        'user_id' => $user_id_from_header,
        'role_name' => $user_role_from_header
    ]);

    try {
        $pdo = getDBConnection();

        // Ambil data user lengkap dari database
        $stmt = $pdo->prepare("SELECT u.id, u.username, u.email, u.nama_lengkap, u.no_telepon, r.role_name
                               FROM users u
                               JOIN roles r ON u.role_id = r.id
                               WHERE u.id = ?");
        $stmt->execute([$authorized_user_id]);
        $user_data = $stmt->fetch();

        if ($user_data) {
            echo json_encode(['status' => 'success', 'data' => $user_data]);
            http_response_code(200);
            error_log("PROFILE.PHP DEBUG: User data found for ID: $authorized_user_id. Data: " . print_r($user_data, true));
        } else {
            http_response_code(404);
            echo json_encode(['status' => 'error', 'message' => 'Profil pengguna tidak ditemukan.']);
            error_log("PROFILE.PHP DEBUG: User data NOT found for ID: $authorized_user_id.");
        }

    } catch (PDOException $e) {
        error_log("PROFILE.PHP DEBUG: PDOException: " . $e->getMessage());
        http_response_code(500);
        echo json_encode(['status' => 'error', 'message' => 'Gagal mengambil profil pengguna (Database Error).']);
    }

} else {
    http_response_code(405);
    echo json_encode(['status' => 'error', 'message' => 'Metode request tidak diizinkan. Hanya GET.']);
    error_log("PROFILE.PHP DEBUG: Invalid request method: " . $_SERVER['REQUEST_METHOD']);
}
?>