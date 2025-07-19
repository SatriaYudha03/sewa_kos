<?php
// api/images/serve.php (ENDPOINT BARU UNTUK MENYAJIKAN GAMBAR DARI DB)

// --- DEBUGGING (HAPUS ini di produksi!) ---
error_reporting(E_ALL); 
ini_set('display_errors', 0); // Jangan tampilkan error langsung di output gambar
ini_set('log_errors', 1);
ini_set('error_log', '../../php_error.log'); 

error_log("SERVE IMAGE DEBUG: Script execution started. Request Method: " . $_SERVER['REQUEST_METHOD']);

// --- HEADER CORS UNIVERSAL ---
header('Access-Control-Allow-Origin: *'); 
header('Access-Control-Allow-Methods: GET, OPTIONS'); 
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-User-ID, X-User-Role'); 

// --- IMPORTS ---
require_once '../config/database.php';
// auth_check tidak diperlukan di sini karena ini endpoint publik untuk gambar,
// tapi jika gambar sensitif, bisa ditambahkan autentikasi.

// --- HANDLE PREFLIGHT OPTIONS REQUEST ---
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    header('Access-Control-Allow-Origin: *'); 
    header('Access-Control-Allow-Methods: GET, OPTIONS'); 
    header('Access-Control-Allow-Headers: Origin, X-Requested-With, Content-Type, Accept, Authorization, X-User-ID, X-User-Role'); 
    header('Access-Control-Max-Age: 3600'); 
    http_response_code(200); 
    exit(); 
}

// Hanya izinkan metode GET untuk menyajikan gambar
if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    $type = $_GET['type'] ?? null; // 'kos' atau 'bukti_pembayaran'
    $id = $_GET['id'] ?? null;     // ID Kos atau ID Detail Pembayaran

    if (empty($type) || empty($id) || !is_numeric($id)) {
        http_response_code(400);
        echo "Missing type or ID."; // Output pesan error sederhana (bukan JSON)
        error_log("SERVE IMAGE DEBUG: Missing type or ID. Type: $type, ID: $id");
        exit();
    }

    try {
        $pdo = getDBConnection();
        $image_data = null;
        $mime_type = null;

        if ($type === 'kos') {
            $stmt = $pdo->prepare("SELECT foto_utama FROM kos WHERE id = ?");
            $stmt->execute([$id]);
            $result = $stmt->fetch();
            if ($result && $result['foto_utama']) {
                $image_data = $result['foto_utama'];
                // Anda perlu menyimpan MIME type di DB saat upload jika ingin lebih akurat
                // Untuk sementara, coba deteksi atau asumsikan JPEG/PNG
                $finfo = new finfo(FILEINFO_MIME_TYPE);
                $mime_type = $finfo->buffer($image_data);
                error_log("SERVE IMAGE DEBUG: Kos image ID $id, detected MIME: $mime_type");
            }
        } elseif ($type === 'bukti_pembayaran') {
            $stmt = $pdo->prepare("SELECT bukti_transfer FROM detail_pembayaran WHERE id = ?");
            $stmt->execute([$id]);
            $result = $stmt->fetch();
            if ($result && $result['bukti_transfer']) {
                $image_data = $result['bukti_transfer'];
                $finfo = new finfo(FILEINFO_MIME_TYPE);
                $mime_type = $finfo->buffer($image_data);
                error_log("SERVE IMAGE DEBUG: Bukti pembayaran image ID $id, detected MIME: $mime_type");
            }
        } else {
            http_response_code(400);
            echo "Invalid image type.";
            error_log("SERVE IMAGE DEBUG: Invalid type parameter: $type.");
            exit();
        }

        if ($image_data) {
            if ($mime_type) {
                header("Content-Type: $mime_type");
            } else {
                // Fallback jika mime_type tidak terdeteksi atau tidak disimpan
                header("Content-Type: image/jpeg"); // Asumsikan JPEG sebagai default
                error_log("SERVE IMAGE DEBUG: MIME type not detected, defaulting to image/jpeg.");
            }
            http_response_code(200);
            echo $image_data; // Output data binary gambar
            exit();
        } else {
            http_response_code(404);
            echo "Image not found or no image data.";
            error_log("SERVE IMAGE DEBUG: Image data not found for type $type, ID $id.");
            exit();
        }

    } catch (PDOException $e) {
        error_log("SERVE IMAGE DEBUG: PDOException: " . $e->getMessage());
        http_response_code(500);
        echo "Database error.";
    } catch (Exception $e) {
        error_log("SERVE IMAGE DEBUG: General Exception: " . $e->getMessage());
        http_response_code(500);
        echo "Server error.";
    }

} else {
    http_response_code(405);
    echo "Metode request tidak diizinkan. Hanya GET.";
    error_log("SERVE IMAGE DEBUG: Invalid request method: " . $_SERVER['REQUEST_METHOD']);
}
?>