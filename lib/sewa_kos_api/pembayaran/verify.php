<?php
// api/pembayaran/verify.php (REVISI LENGKAP TERBARU)

// --- DEBUGGING SANGAT AGRESIF (HAPUS ini di produksi!) ---
error_reporting(E_ALL); 
ini_set('display_errors', 1); // Akan menampilkan error di respon HTTP (hapus di produksi)
ini_set('log_errors', 1); // Akan log error ke file
ini_set('error_log', '../../php_error.log'); // Lokasi log error PHP (pastikan path ini ada)

error_log("VERIFY.PHP DEBUG: Script execution started. Received Method: " . $_SERVER['REQUEST_METHOD']); // <--- BARIS INI AKAN MENCATAT METODE YANG DITERIMA

// --- HEADER CORS UNIVERSAL (untuk semua method) ---
header('Access-Control-Allow-Origin: *'); // Izinkan semua origin
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS'); // Metode yang diizinkan
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-User-ID, X-User-Role'); // Header kustom yang diizinkan

// --- IMPORTS ---
require_once '../config/database.php';
require_once '../utils/auth_check.php';

// --- HANDLE PREFLIGHT OPTIONS REQUEST ---
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    error_log("VERIFY.PHP DEBUG: Handling OPTIONS request.");
    // Header-header ini HARUS dikirimkan khusus untuk OPTIONS request
    header('Access-Control-Allow-Origin: *'); 
    header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS'); 
    header('Access-Control-Allow-Headers: Origin, X-Requested-With, Content-Type, Accept, Authorization, X-User-ID, X-User-Role'); 
    header('Access-Control-Max-Age: 3600'); // Cache preflight response for 1 hour

    http_response_code(200); // Respons OK untuk preflight
    error_log("VERIFY.PHP DEBUG: OPTIONS request handled and exited.");
    exit(); // Sangat penting untuk keluar setelah mengirim header untuk OPTIONS
}

// --- LOGIKA UTAMA UNTUK PUT REQUEST ---
if ($_SERVER['REQUEST_METHOD'] === 'PUT') {
    error_log("VERIFY.PHP DEBUG: Method is PUT. Processing request.");
    $data = json_decode(file_get_contents('php://input'), true);

    $detail_pembayaran_id = $data['id'] ?? '';
    $status_verifikasi = $data['status'] ?? ''; // 'terverifikasi' atau 'gagal'

    $user_id_from_header = $_SERVER['HTTP_X_USER_ID'] ?? '';
    $user_role_from_header = $_SERVER['HTTP_X_USER_ROLE'] ?? '';

    // Hanya pemilik_kos yang bisa memverifikasi pembayaran
    $authorized_user_id = checkAuthorization(['pemilik_kos'], [
        'user_id' => $user_id_from_header,
        'role_name' => $user_role_from_header
    ]);

    if (empty($detail_pembayaran_id) || !is_numeric($detail_pembayaran_id) || empty($status_verifikasi)) {
        http_response_code(400);
        echo json_encode(['status' => 'error', 'message' => 'ID Detail Pembayaran dan status verifikasi wajib diisi.']);
        error_log("VERIFY.PHP DEBUG: Missing ID or status.");
        exit();
    }

    $allowed_statuses_verifikasi = ['terverifikasi', 'gagal'];
    if (!in_array($status_verifikasi, $allowed_statuses_verifikasi)) {
        http_response_code(400);
        echo json_encode(['status' => 'error', 'message' => 'Status verifikasi tidak valid. Pilih dari: ' . implode(', ', $allowed_statuses_verifikasi)]);
        error_log("VERIFY.PHP DEBUG: Invalid status: $status_verifikasi");
        exit();
    }

    try {
        $pdo = getDBConnection();
        $pdo->beginTransaction();

        // 1. Ambil detail pembayaran dan pemesanan terkait untuk verifikasi kepemilikan
        $stmt_pembayaran = $pdo->prepare("SELECT dp.pemesanan_id, p.user_id as tenant_id, p.status_pemesanan as pemesanan_current_status, mk.kos_id, k.user_id as kos_owner_id
                                           FROM detail_pembayaran dp
                                           JOIN pemesanan p ON dp.pemesanan_id = p.id
                                           JOIN kamar_kos mk ON p.kamar_id = mk.id
                                           JOIN kos k ON mk.kos_id = k.id
                                           WHERE dp.id = ?");
        $stmt_pembayaran->execute([$detail_pembayaran_id]);
        $pembayaran_info = $stmt_pembayaran->fetch();

        if (!$pembayaran_info) {
            http_response_code(404);
            echo json_encode(['status' => 'error', 'message' => 'Detail pembayaran tidak ditemukan.']);
            $pdo->rollBack();
            error_log("VERIFY.PHP DEBUG: Payment detail $detail_pembayaran_id not found.");
            exit();
        }

        // 2. Verifikasi kepemilikan kos oleh pemilik kos
        if ($pembayaran_info['kos_owner_id'] != $authorized_user_id) {
            http_response_code(403);
            echo json_encode(['status' => 'error', 'message' => 'Anda tidak diizinkan memverifikasi pembayaran ini.']);
            $pdo->rollBack();
            error_log("VERIFY.PHP DEBUG: User $authorized_user_id not authorized for payment $detail_pembayaran_id (owner is ${pembayaran_info['kos_owner_id']}).");
            exit();
        }
        
        // 3. Update status detail pembayaran
        $stmt_update_detail_pembayaran = $pdo->prepare("UPDATE detail_pembayaran SET status_pembayaran = ? WHERE id = ?");
        $stmt_update_detail_pembayaran->execute([$status_verifikasi, $detail_pembayaran_id]);

        // 4. Update status pemesanan jika pembayaran terverifikasi
        if ($status_verifikasi === 'terverifikasi') {
            $stmt_update_pemesanan_status = $pdo->prepare("UPDATE pemesanan SET status_pemesanan = 'terkonfirmasi' WHERE id = ?");
            $stmt_update_pemesanan_status->execute([$pembayaran_info['pemesanan_id']]);
            error_log("VERIFY.PHP DEBUG: Payment $detail_pembayaran_id verified. Pemesanan ${pembayaran_info['pemesanan_id']} status updated to terkonfirmasi.");

        } else if ($status_verifikasi === 'gagal') {
            error_log("VERIFY.PHP DEBUG: Payment $detail_pembayaran_id marked as failed. Pemesanan ${pembayaran_info['pemesanan_id']} status retained.");
        }

        $pdo->commit();

        echo json_encode(['status' => 'success', 'message' => 'Status pembayaran berhasil diperbarui menjadi ' . $status_verifikasi . '.']);
        http_response_code(200);

    } catch (PDOException $e) {
        $pdo->rollBack();
        error_log("VERIFY.PHP DEBUG: PDOException verifying payment: " . $e->getMessage());
        http_response_code(500);
        echo json_encode(['status' => 'error', 'message' => 'Gagal memverifikasi pembayaran (Database Error).']);
    } catch (Exception $e) { 
        $pdo->rollBack();
        error_log("VERIFY.PHP DEBUG: General Exception verifying payment: " . $e->getMessage());
        http_response_code(500);
        echo json_encode(['status' => 'error', 'message' => 'Terjadi kesalahan internal.']);
    }

} else {
    // --- METODE REQUEST TIDAK DIJINKAN ---
    http_response_code(405); 
    echo json_encode(['status' => 'error', 'message' => 'Metode request tidak diizinkan. Hanya PUT.']);
    error_log("VERIFY.PHP DEBUG: Invalid request method: " . $_SERVER['REQUEST_METHOD']);
}
?>