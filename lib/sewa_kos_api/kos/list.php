<?php
// api/kos/list.php (DIUPDATE: Tambah kolom has_image)

// --- DEBUGGING SANGAT AGRESIF (HAPUS ini di produksi!) ---
error_reporting(E_ALL); 
ini_set('display_errors', 1);
ini_set('log_errors', 1);
ini_set('error_log', '../php_error.log');

error_log("KOS LIST DEBUG: Script execution started. Request Method: " . $_SERVER['REQUEST_METHOD']);

// --- HEADER CORS UNIVERSAL ---zz
header('Access-Control-Allow-Origin: *'); 
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS'); 
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-User-ID, X-User-Role'); 

// --- IMPORTS ---
require_once '../config/database.php';
require_once '../utils/auth_check.php';

// --- HANDLE PREFLIGHT OPTIONS REQUEST ---
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    error_log("KOS LIST DEBUG: Handling OPTIONS request.");
    header('Access-Control-Allow-Origin: *'); 
    header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS'); 
    header('Access-Control-Allow-Headers: Origin, X-Requested-With, Content-Type, Accept, Authorization, X-User-ID, X-User-Role'); 
    http_response_code(200); 
    exit(); 
}

if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    $user_id_from_header = $_SERVER['HTTP_X_USER_ID'] ?? '';
    $user_role_from_header = $_SERVER['HTTP_X_USER_ROLE'] ?? 'penyewa';

    error_log("KOS LIST DEBUG: Request received. User ID: $user_id_from_header, Role: $user_role_from_header");

    $authorized_user_id = checkAuthorization(['penyewa', 'pemilik_kos'], [
        'user_id' => $user_id_from_header,
        'role_name' => $user_role_from_header
    ]);

    try {
        $pdo = getDBConnection();
        // --- PERBAIKAN DI SINI: Tambah kolom has_image ---
        $sql = "SELECT k.id, k.user_id, k.nama_kos, k.alamat, k.deskripsi, k.fasilitas_umum, k.created_at, k.updated_at,
                       (k.foto_utama IS NOT NULL) AS has_image, -- <--- TAMBAHKAN INI
                       u.username as owner_username, u.nama_lengkap as owner_name 
                FROM kos k 
                JOIN users u ON k.user_id = u.id";
        $params = [];

        if ($user_role_from_header === 'pemilik_kos') {
            $sql .= " WHERE k.user_id = ?";
            $params[] = $authorized_user_id;
            error_log("KOS LIST DEBUG: Filtering for owner ID: $authorized_user_id.");
        } else {
            error_log("KOS LIST DEBUG: Showing all kos for tenant/unknown role.");
        }

        $sql .= " ORDER BY k.created_at DESC"; 

        error_log("KOS LIST DEBUG: SQL Query: " . $sql);
        error_log("KOS LIST DEBUG: Query Params: " . implode(", ", $params));

        $stmt = $pdo->prepare($sql);
        $stmt->execute($params);
        $kos_list = $stmt->fetchAll();

        if ($kos_list) {
            echo json_encode(['status' => 'success', 'data' => $kos_list]);
            http_response_code(200);
            error_log("KOS LIST DEBUG: " . count($kos_list) . " kos properties found. Data: " . print_r($kos_list, true));
        } else {
            echo json_encode(['status' => 'success', 'message' => 'Tidak ada data kos ditemukan.', 'data' => []]);
            http_response_code(200);
            error_log("KOS LIST DEBUG: No kos properties found.");
        }

    } catch (PDOException $e) {
        error_log("KOS LIST DEBUG: PDOException: " . $e->getMessage());
        http_response_code(500);
        echo json_encode(['status' => 'error', 'message' => 'Gagal mengambil daftar kos (Database Error).']);
    }

} else {
    http_response_code(405);
    echo json_encode(['status' => 'error', 'message' => 'Metode request tidak diizinkan. Hanya GET.']);
    error_log("KOS LIST DEBUG: Invalid request method: " . $_SERVER['REQUEST_METHOD']);
}
?>