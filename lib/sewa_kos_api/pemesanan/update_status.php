<?php
// api/pemesanan/update_status.php (REVISI LENGKAP dengan Debugging Data)

// --- DEBUGGING SANGAT AGRESIF (HAPUS ini di produksi!) ---
error_reporting(E_ALL); 
ini_set('display_errors', 1);
ini_set('log_errors', 1);
ini_set('error_log', '../../php_error.log'); // Lokasi log error PHP (pastikan path ini ada)

error_log("UPDATE_STATUS.PHP DEBUG: Script execution started. Received Method: " . $_SERVER['REQUEST_METHOD']);

// --- HEADER CORS UNIVERSAL (untuk semua method) ---
header('Access-Control-Allow-Origin: *'); 
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS'); 
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-User-ID, X-User-Role'); 

// --- IMPORTS ---
require_once '../config/database.php';
require_once '../utils/auth_check.php';

// --- HANDLE PREFLIGHT OPTIONS REQUEST ---
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    error_log("UPDATE_STATUS.PHP DEBUG: Handling OPTIONS request.");
    header('Access-Control-Allow-Origin: *'); 
    header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS'); 
    header('Access-Control-Allow-Headers: Origin, X-Requested-With, Content-Type, Accept, Authorization, X-User-ID, X-User-Role'); 
    header('Access-Control-Max-Age: 3600'); 
    http_response_code(200); 
    exit(); 
}

// --- LOGIKA UTAMA UNTUK PUT REQUEST ---
if ($_SERVER['REQUEST_METHOD'] === 'PUT') {
    error_log("UPDATE_STATUS.PHP DEBUG: Method is PUT. Attempting to read input.");

    // Membaca raw POST/PUT data
    $raw_input = file_get_contents('php://input');
    error_log("UPDATE_STATUS.PHP DEBUG: Raw input received: " . $raw_input);

    $data = json_decode($raw_input, true);
    error_log("UPDATE_STATUS.PHP DEBUG: Decoded data (print_r): " . print_r($data, true)); // <--- INI AKAN MENAMPILKAN ISI $data

    $pemesanan_id = $data['pemesanan_id'] ?? null; // Pastikan ini 'pemesanan_id' sesuai Flutter
    $new_status = $data['status_pemesanan'] ?? null; // Pastikan ini 'status_pemesanan' sesuai Flutter

    error_log("UPDATE_STATUS.PHP DEBUG: pemesanan_id from data: " . var_export($pemesanan_id, true));
    error_log("UPDATE_STATUS.PHP DEBUG: new_status from data: " . var_export($new_status, true));

    // Ambil user_id dan role dari header (sudah ada dari auth_check, tapi perlu untuk log)
    $user_id_from_header = $_SERVER['HTTP_X_USER_ID'] ?? '';
    $user_role_from_header = $_SERVER['HTTP_X_USER_ROLE'] ?? '';

    // Hanya pemilik_kos yang bisa mengubah status
    $authorized_user_id = checkAuthorization(['pemilik_kos'], [
        'user_id' => $user_id_from_header,
        'role_name' => $user_role_from_header
    ]);

    if (empty($pemesanan_id) || !is_numeric($pemesanan_id) || empty($new_status)) {
        http_response_code(400);
        echo json_encode(['status' => 'error', 'message' => 'ID Pemesanan dan status baru wajib diisi.']);
        error_log("UPDATE_STATUS.PHP DEBUG: Validation failed: ID or status is empty/invalid.");
        exit();
    }

    $allowed_statuses = ['terkonfirmasi', 'dibatalkan', 'selesai'];
    if (!in_array($new_status, $allowed_statuses)) {
        http_response_code(400);
        echo json_encode(['status' => 'error', 'message' => 'Status tidak valid. Pilih dari: ' . implode(', ', $allowed_statuses)]);
        error_log("UPDATE_STATUS.PHP DEBUG: Invalid status value: $new_status.");
        exit();
    }

    try {
        $pdo = getDBConnection();
        $pdo->beginTransaction();

        // 1. Ambil detail pemesanan dan kos terkait untuk verifikasi kepemilikan
        $stmt = $pdo->prepare("SELECT p.user_id as tenant_id, p.kamar_id, mk.kos_id, k.user_id as kos_owner_id, p.status_pemesanan as current_status
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
            error_log("UPDATE_STATUS.PHP DEBUG: Pemesanan $pemesanan_id not found.");
            exit();
        }

        // 2. Verifikasi kepemilikan kos oleh pemilik kos
        if ($pemesanan_info['kos_owner_id'] != $authorized_user_id) {
            http_response_code(403);
            echo json_encode(['status' => 'error', 'message' => 'Anda tidak diizinkan memperbarui status pemesanan ini.']);
            $pdo->rollBack();
            error_log("UPDATE_STATUS.PHP DEBUG: User $authorized_user_id not authorized for pemesanan $pemesanan_id.");
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
            error_log("UPDATE_STATUS.PHP DEBUG: Pemesanan $pemesanan_id dibatalkan. Kamar ${pemesanan_info['kamar_id']} diubah menjadi 'tersedia'.");
        } else if ($new_status === 'terkonfirmasi') {
            error_log("UPDATE_STATUS.PHP DEBUG: Pemesanan $pemesanan_id terkonfirmasi.");
        } else if ($new_status === 'selesai') {
            error_log("UPDATE_STATUS.PHP DEBUG: Pemesanan $pemesanan_id selesai.");
        }


        $pdo->commit();

        echo json_encode(['status' => 'success', 'message' => 'Status pemesanan berhasil diperbarui menjadi ' . $new_status . '.']);
        http_response_code(200);
        error_log("UPDATE_STATUS.PHP DEBUG: Pemesanan $pemesanan_id status updated to $new_status.");

    } catch (PDOException $e) {
        $pdo->rollBack();
        error_log("UPDATE_STATUS.PHP DEBUG: PDOException: " . $e->getMessage());
        http_response_code(500);
        echo json_encode(['status' => 'error', 'message' => 'Gagal memperbarui status pemesanan (Database Error).']);
    } catch (Exception $e) { 
        $pdo->rollBack();
        error_log("UPDATE_STATUS.PHP DEBUG: General Exception: " . $e->getMessage());
        http_response_code(500);
        echo json_encode(['status' => 'error', 'message' => 'Terjadi kesalahan internal.']);
    }

} else {
    // --- METODE REQUEST TIDAK DIJINKAN ---
    http_response_code(405); 
    echo json_encode(['status' => 'error', 'message' => 'Metode request tidak diizinkan. Hanya PUT.']);
    error_log("UPDATE_STATUS.PHP DEBUG: Invalid request method: " . $_SERVER['REQUEST_METHOD']);
}
?>