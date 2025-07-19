<?php
// api/pembayaran/upload_proof.php (DIUPDATE: Menyimpan file upload ke DB sebagai BLOB)

error_reporting(E_ALL);
ini_set('display_errors', 1);
ini_set('log_errors', 1);
ini_set('error_log', '../../php_error.log');

require_once '../config/database.php';
require_once '../utils/auth_check.php';

header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-User-ID, X-User-Role');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    header('Access-Control-Allow-Origin: *');
    header('Access-Control-Allow-Methods: POST, GET, OPTIONS');
    header('Access-Control-Allow-Headers: Origin, X-Requested-With, Content-Type, Accept, Authorization, X-User-ID, X-User-Role');
    header('Access-Control-Max-Age: 3600');
    http_response_code(200);
    exit();
}

// Hanya izinkan POST request
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $user_id_from_header = $_SERVER['HTTP_X_USER_ID'] ?? '';
    $user_role_from_header = $_SERVER['HTTP_X_USER_ROLE'] ?? '';

    // Hanya penyewa yang bisa upload bukti pembayaran
    $authorized_user_id = checkAuthorization(['penyewa'], [
        'user_id' => $user_id_from_header,
        'role_name' => $user_role_from_header
    ]);

    $pemesanan_id = $_POST['pemesanan_id'] ?? null;
    $jumlah_bayar = $_POST['jumlah_bayar'] ?? null;
    $metode_pembayaran = $_POST['metode_pembayaran'] ?? null;

    error_log("UPLOAD_PROOF.PHP DEBUG: Request received. Pemesanan ID: $pemesanan_id, Jumlah: $jumlah_bayar, Metode: $metode_pembayaran");

    // Validasi input dasar
    if (empty($pemesanan_id) || !is_numeric($pemesanan_id) || empty($jumlah_bayar) || !is_numeric($jumlah_bayar) || empty($metode_pembayaran)) {
        http_response_code(400);
        echo json_encode(['status' => 'error', 'message' => 'Data tidak lengkap. ID Pemesanan, jumlah bayar, dan metode pembayaran wajib diisi.']);
        error_log("UPLOAD_PROOF.PHP DEBUG: Missing required fields.");
        exit();
    }

    $image_binary_data = null;
    $image_mime_type = null;

    if (isset($_FILES['bukti_pembayaran']) && $_FILES['bukti_pembayaran']['error'] === UPLOAD_ERR_OK) {
        $file = $_FILES['bukti_pembayaran'];
        $image_binary_data = file_get_contents($file['tmp_name']); // Baca konten file binary
        $image_mime_type = $file['type']; // Dapatkan MIME type dari upload

        error_log("UPLOAD_PROOF.PHP DEBUG: File uploaded. Name: ${file['name']}, Size: ${file['size']}, Type: ${file['type']}");

        // Verifikasi tipe MIME
        if (!in_array($image_mime_type, ['image/jpeg', 'image/png', 'image/gif', 'image/webp'])) {
            http_response_code(400);
            echo json_encode(['status' => 'error', 'message' => 'Tipe gambar tidak didukung: ' . $image_mime_type]);
            error_log("UPLOAD_PROOF.PHP DEBUG: Unsupported image type: " . $image_mime_type);
            exit();
        }
    } else {
        http_response_code(400);
        echo json_encode(['status' => 'error', 'message' => 'Bukti pembayaran gambar wajib diunggah.']);
        error_log("UPLOAD_PROOF.PHP DEBUG: No file uploaded or upload error: " . ($_FILES['bukti_pembayaran']['error'] ?? 'No file'));
        exit();
    }

    try {
        $pdo = getDBConnection();
        $pdo->beginTransaction();

        // 1. Verifikasi bahwa pemesanan adalah milik user yang sedang login
        $stmt_pemesanan = $pdo->prepare("SELECT user_id, status_pemesanan, total_harga FROM pemesanan WHERE id = ?");
        $stmt_pemesanan->execute([$pemesanan_id]);
        $pemesanan = $stmt_pemesanan->fetch();

        if (!$pemesanan) {
            http_response_code(404);
            echo json_encode(['status' => 'error', 'message' => 'Pemesanan tidak ditemukan.']);
            $pdo->rollBack();
            error_log("UPLOAD_PROOF.PHP DEBUG: Pemesanan $pemesanan_id not found.");
            exit();
        }

        if ($pemesanan['user_id'] != $authorized_user_id) {
            http_response_code(403);
            echo json_encode(['status' => 'error', 'message' => 'Anda tidak diizinkan mengupload bukti pembayaran untuk pemesanan ini.']);
            $pdo->rollBack();
            error_log("UPLOAD_PROOF.PHP DEBUG: User $authorized_user_id not authorized for pemesanan $pemesanan_id.");
            exit();
        }

        if ($pemesanan['status_pemesanan'] !== 'menunggu_pembayaran') {
            http_response_code(409);
            echo json_encode(['status' => 'error', 'message' => 'Pemesanan tidak dalam status "menunggu pembayaran".']);
            $pdo->rollBack();
            error_log("UPLOAD_PROOF.PHP DEBUG: Pemesanan $pemesanan_id status is ${pemesanan['status_pemesanan']}, not 'menunggu_pembayaran'.");
            exit();
        }
        
        // 2. Masukkan data pembayaran
        // Simpan binary data dan mime type (jika ingin disimpan, tambahkan kolom mime_type di DB)
        $stmt_pembayaran = $pdo->prepare("INSERT INTO detail_pembayaran (pemesanan_id, jumlah_bayar, metode_pembayaran, bukti_transfer, status_pembayaran, tanggal_pembayaran) VALUES (?, ?, ?, ?, 'menunggu_verifikasi', NOW())");
        $stmt_pembayaran->bindParam(1, $pemesanan_id);
        $stmt_pembayaran->bindParam(2, $jumlah_bayar);
        $stmt_pembayaran->bindParam(3, $metode_pembayaran);
        $stmt_pembayaran->bindParam(4, $image_binary_data, PDO::PARAM_LOB); // Gunakan PDO::PARAM_LOB
        // Jika Anda ingin menyimpan mime_type, tambahkan kolom di DB dan bind: $stmt_pembayaran->bindParam(x, $image_mime_type);
        $stmt_pembayaran->execute();
        $pembayaran_id = $pdo->lastInsertId();

        // 3. Update status pemesanan menjadi 'menunggu_verifikasi'
        $stmt_pemesanan_update = $pdo->prepare("UPDATE pemesanan SET status_pemesanan = 'menunggu_verifikasi' WHERE id = ?");
        $stmt_pemesanan_update->execute([$pemesanan_id]);

        $pdo->commit();
        http_response_code(200);
        echo json_encode(['status' => 'success', 'message' => 'Bukti pembayaran berhasil diunggah. Menunggu verifikasi.', 'pembayaran_id' => $pembayaran_id]);
        error_log("UPLOAD_PROOF.PHP DEBUG: Payment proof uploaded for pemesanan $pemesanan_id. Pembayaran ID: $pembayaran_id.");

    } catch (PDOException $e) {
        $pdo->rollBack();
        error_log("UPLOAD_PROOF.PHP DEBUG: PDOException: " . $e->getMessage());
        http_response_code(500);
        echo json_encode(['status' => 'error', 'message' => 'Terjadi kesalahan database saat mengunggah bukti pembayaran.']);
    } catch (Exception $e) {
        $pdo->rollBack();
        error_log("UPLOAD_PROOF.PHP DEBUG: General Exception: " . $e->getMessage());
        http_response_code(500);
        echo json_encode(['status' => 'error', 'message' => 'Terjadi kesalahan internal.']);
    }

} else {
    http_response_code(405);
    echo json_encode(['status' => 'error', 'message' => 'Metode request tidak diizinkan. Hanya POST.']);
    error_log("UPLOAD_PROOF.PHP DEBUG: Invalid request method: " . $_SERVER['REQUEST_METHOD']);
}
?>