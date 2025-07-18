<?php
// api/kos/add.php (Kode Lengkap - Path Dikonfirmasi Benar untuk Struktur Anda)

// Aktifkan semua pelaporan error untuk debugging (HAPUS ini di produksi!)
error_reporting(E_ALL); 
ini_set('display_errors', 1);
ini_set('log_errors', 1);
ini_set('error_log', '../../php_error.log'); // <-- Path ini relatif dari 'kos/', jadi log akan di sewa_kos_api/php_error.log

// Path untuk require_once relatif dari folder 'kos/'
require_once '../config/database.php'; // <-- PATH INI BENAR
require_once '../utils/auth_check.php'; // <-- PATH INI BENAR

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

    $user_id_from_header = $data['user_id_from_header'] ?? ($_SERVER['HTTP_X_USER_ID'] ?? '');
    $user_role_from_header = $data['user_role_from_header'] ?? ($_SERVER['HTTP_X_USER_ROLE'] ?? '');


    error_log("ADD KOS DEBUG: Request received. User ID: $user_id_from_header, Role: $user_role_from_header");

    // Otorisasi: hanya pemilik_kos yang bisa menambah kos
    $authorized_user_id = checkAuthorization(['pemilik_kos'], [
        'user_id' => $user_id_from_header,
        'role_name' => $user_role_from_header
    ]);

    $nama_kos = $data['nama_kos'] ?? '';
    $alamat = $data['alamat'] ?? '';
    $deskripsi = $data['deskripsi'] ?? null;
    $foto_utama_base64 = $data['foto_utama'] ?? null; 
    $fasilitas_umum = $data['fasilitas_umum'] ?? null;

    $owner_id = $authorized_user_id; 

    if (empty($nama_kos) || empty($alamat)) {
        http_response_code(400);
        echo json_encode(['status' => 'error', 'message' => 'Nama kos dan alamat wajib diisi.']);
        error_log("ADD KOS DEBUG: Missing nama_kos or alamat.");
        exit();
    }

    $image_db_path = null; 

    if ($foto_utama_base64) {
        error_log("ADD KOS DEBUG: foto_utama_base64 received. Length: " . strlen($foto_utama_base64));

        $base64_parts = explode(',', $foto_utama_base64);
        $base64_string = end($base64_parts); 

        $decoded_image = base64_decode($base64_string);

        if ($decoded_image === false) {
             http_response_code(400);
             echo json_encode(['status' => 'error', 'message' => 'Format gambar Base64 tidak valid.']);
             error_log("ADD KOS DEBUG: Base64 decode failed for input starting with: " . substr($base64_string, 0, 50) . "...");
             exit();
        }
        error_log("ADD KOS DEBUG: Image decoded. Size: " . strlen($decoded_image) . " bytes.");

        $finfo = new finfo(FILEINFO_MIME_TYPE);
        $mime_type = $finfo->buffer($decoded_image);
        $extension = '';
        switch ($mime_type) {
            case 'image/jpeg': $extension = '.jpg'; break;
            case 'image/png': $extension = '.png'; break;
            case 'image/gif': $extension = '.gif'; break;
            case 'image/webp': $extension = '.webp'; break;
            default:
                http_response_code(400);
                echo json_encode(['status' => 'error', 'message' => 'Tipe gambar tidak didukung: ' . $mime_type]);
                error_log("ADD KOS DEBUG: Unsupported image type: " . $mime_type);
                exit();
        }
        error_log("ADD KOS DEBUG: Detected MIME type: $mime_type, Extension: $extension");

        $upload_dir = '../uploads/kos_images/'; // <-- PATH INI BENAR untuk struktur Anda!
        $file_name = uniqid() . $extension;
        $file_path = $upload_dir . $file_name;

        $absolute_upload_path = realpath($upload_dir);
        if (!is_dir($upload_dir)) {
            error_log("ADD KOS DEBUG: Upload directory '$upload_dir' does not exist. Trying to create.");
            if (!mkdir($upload_dir, 0777, true)) {
                http_response_code(500);
                echo json_encode(['status' => 'error', 'message' => 'Gagal membuat folder upload. Pastikan izin folder benar.']);
                error_log("ADD KOS DEBUG: Failed to create upload directory: '$upload_dir'");
                exit();
            }
            error_log("ADD KOS DEBUG: Upload directory created successfully.");
        }
        
        if (!is_writable($upload_dir)) {
            http_response_code(500);
            echo json_encode(['status' => 'error', 'message' => 'Folder upload tidak memiliki izin tulis.']);
            error_log("ADD KOS DEBUG: Upload directory '$upload_dir' is not writable. Check permissions.");
            exit();
        }
        error_log("ADD KOS DEBUG: Upload directory '$upload_dir' is writable.");

        if (file_put_contents($file_path, $decoded_image)) {
            $image_db_path = '/uploads/kos_images/' . $file_name; 
            error_log("ADD KOS DEBUG: Image successfully saved to: " . $file_path . ". DB path: " . $image_db_path);
        } else {
            $last_php_error = error_get_last();
            $error_message = $last_php_error ? $last_php_error['message'] : 'Unknown error';
            http_response_code(500);
            echo json_encode(['status' => 'error', 'message' => 'Gagal menyimpan file gambar di server.']);
            error_log("ADD KOS DEBUG: Failed to save image. Path: " . $file_path . ". PHP Error: " . $error_message);
            exit();
        }
    } else {
        error_log("ADD KOS DEBUG: No foto_utama_base64 provided.");
    }

    try {
        $pdo = getDBConnection();
        $pdo->beginTransaction(); 

        $stmt = $pdo->prepare("INSERT INTO kos (user_id, nama_kos, alamat, deskripsi, foto_utama, fasilitas_umum) VALUES (?, ?, ?, ?, ?, ?)");
        $stmt->execute([$owner_id, $nama_kos, $alamat, $deskripsi, $image_db_path, $fasilitas_umum]);
        $kos_id = $pdo->lastInsertId();

        $pdo->commit(); 

        echo json_encode(['status' => 'success', 'message' => 'Kos berhasil ditambahkan.', 'id' => $kos_id, 'foto_utama_path' => $image_db_path]);
        http_response_code(201); 
        error_log("ADD KOS DEBUG: Kos added successfully. ID: $kos_id.");

    } catch (PDOException $e) {
        $pdo->rollBack(); 
        error_log("ADD KOS DEBUG: PDOException during insert: " . $e->getMessage());
        http_response_code(500);
        echo json_encode(['status' => 'error', 'message' => 'Gagal menambahkan kos (Database Error).']);
    }

} else {
    http_response_code(405);
    echo json_encode(['status' => 'error', 'message' => 'Metode request tidak diizinkan. Hanya POST.']);
    error_log("ADD KOS DEBUG: Invalid request method: " . $_SERVER['REQUEST_METHOD']);
}
?>