<?php
// api/pemesanan/list.php (ENDPOINT BARU & TERPADU)

// Aktifkan pelaporan error untuk debugging (HAPUS ini di produksi!)
error_reporting(E_ALL); 
ini_set('display_errors', 1);
ini_set('log_errors', 1);
ini_set('error_log', '../../php_error.log'); // Sesuaikan path log error jika perlu

// Path untuk require_once relatif dari folder 'pemesanan/'
require_once '../config/database.php';
require_once '../utils/auth_check.php';

// Header CORS ini penting untuk mengizinkan permintaan dari origin berbeda (Flutter Web)
header('Access-Control-Allow-Origin: *'); 
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS'); 
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-User-ID, X-User-Role'); 

// Handle OPTIONS request for CORS preflight (HARUS ADA DI SETIAP FILE API PHP)
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    header('Access-Control-Allow-Origin: *'); 
    header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS'); 
    header('Access-Control-Allow-Headers: Origin, X-Requested-With, Content-Type, Accept, Authorization, X-User-ID, X-User-Role'); 
    header('Access-Control-Max-Age: 3600'); 
    http_response_code(200);
    exit(); 
}

// Hanya izinkan metode GET untuk mengambil daftar
if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    $user_id_from_header = $_SERVER['HTTP_X_USER_ID'] ?? '';
    $user_role_from_header = $_SERVER['HTTP_X_USER_ROLE'] ?? '';

    error_log("PEMESANAN LIST DEBUG: Request received. User ID: $user_id_from_header, Role: $user_role_from_header");

    // Otorisasi: penyewa atau pemilik_kos bisa mengakses, scope-nya berbeda
    $authorized_user_id = checkAuthorization(['penyewa', 'pemilik_kos'], [
        'user_id' => $user_id_from_header,
        'role_name' => $user_role_from_header
    ]);

    try {
        $pdo = getDBConnection();
        $sql = "";
        $params = [];

        if ($user_role_from_header === 'penyewa') {
            // Jika penyewa, ambil pemesanan miliknya sendiri
            $sql = "SELECT p.*, mk.nama_kamar, mk.harga_sewa, k.nama_kos, k.alamat,
                           u_owner.username as owner_username, u_owner.nama_lengkap as owner_name
                    FROM pemesanan p
                    JOIN kamar_kos mk ON p.kamar_id = mk.id
                    JOIN kos k ON mk.kos_id = k.id
                    JOIN users u_owner ON k.user_id = u_owner.id
                    WHERE p.user_id = ?
                    ORDER BY p.created_at DESC";
            $params[] = $authorized_user_id;
            error_log("PEMESANAN LIST DEBUG: Fetching bookings for tenant ID: $authorized_user_id");

        } elseif ($user_role_from_header === 'pemilik_kos') {
            // Jika pemilik kos, ambil pemesanan yang masuk ke kos miliknya
            $sql = "SELECT p.*, mk.nama_kamar, mk.harga_sewa, k.nama_kos, 
                           u_tenant.username as tenant_username, u_tenant.nama_lengkap as tenant_name
                    FROM pemesanan p
                    JOIN kamar_kos mk ON p.kamar_id = mk.id
                    JOIN kos k ON mk.kos_id = k.id
                    JOIN users u_tenant ON p.user_id = u_tenant.id
                    WHERE k.user_id = ? -- Filter berdasarkan pemilik kos
                    ORDER BY p.created_at DESC";
            $params[] = $authorized_user_id;
            error_log("PEMESANAN LIST DEBUG: Fetching incoming bookings for owner ID: $authorized_user_id");

        } else {
            // Role tidak dikenal atau tidak memiliki akses
            http_response_code(403);
            echo json_encode(['status' => 'error', 'message' => 'Akses ditolak. Peran tidak valid.']);
            error_log("PEMESANAN LIST DEBUG: Access denied. Invalid role: $user_role_from_header");
            exit();
        }

        $stmt = $pdo->prepare($sql);
        $stmt->execute($params);
        $pemesanan_list = $stmt->fetchAll();

        if ($pemesanan_list) {
            echo json_encode(['status' => 'success', 'data' => $pemesanan_list]);
            http_response_code(200);
            error_log("PEMESANAN LIST DEBUG: " . count($pemesanan_list) . " bookings found.");
        } else {
            echo json_encode(['status' => 'success', 'message' => 'Tidak ada pemesanan ditemukan.', 'data' => []]);
            http_response_code(200);
            error_log("PEMESANAN LIST DEBUG: No bookings found.");
        }

    } catch (PDOException $e) {
        error_log("PEMESANAN LIST DEBUG: PDOException: " . $e->getMessage());
        http_response_code(500);
        echo json_encode(['status' => 'error', 'message' => 'Gagal mengambil daftar pemesanan (Database Error).']);
    }

} else {
    http_response_code(405);
    echo json_encode(['status' => 'error', 'message' => 'Metode request tidak diizinkan. Hanya GET.']);
    error_log("PEMESANAN LIST DEBUG: Invalid request method: " . $_SERVER['REQUEST_METHOD']);
}
?>