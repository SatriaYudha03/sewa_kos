<?php
// api/kos/add.php (DIUPDATE: Menyimpan gambar Base64 ke DB sebagai BLOB)

// --- DEBUGGING SANGAT AGRESIF (HAPUS ini di produksi!) ---
error_reporting(E_ALL);
ini_set('display_errors', 1);
ini_set('log_errors', 1);
ini_set('error_log', '../../php_error.log');

error_log("ADD KOS DEBUG: Script execution started. Request Method: " . $_SERVER['REQUEST_METHOD']);

// --- HEADER CORS UNIVERSAL ---
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, GET, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-User-ID, X-User-Role');

// --- IMPORTS ---
require_once '../config/database.php';
require_once '../utils/auth_check.php';

// --- HANDLE PREFLIGHT OPTIONS REQUEST ---
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    error_log("ADD KOS DEBUG: Handling OPTIONS request.");
    header('Access-Control-Allow-Origin: *');
    header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
    header('Access-Control-Allow-Headers: Origin, X-Requested-With, Content-Type, Accept, Authorization, X-User-ID, X-User-Role');
    header('Access-Control-Max-Age: 3600');
    http_response_code(200);
    exit();
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $raw_input = file_get_contents('php://input');
    error_log("ADD KOS DEBUG: Raw input length: " . strlen($raw_input));
    error_log("ADD KOS DEBUG: Raw input preview (first 500 chars): " . substr($raw_input, 0, 500));

    $data = json_decode($raw_input, true);

    if ($data === null) {
        error_log("ADD KOS DEBUG: JSON decode failed. JSON error: " . json_last_error_msg());
        http_response_code(400);
        echo json_encode(['status' => 'error', 'message' => 'Invalid JSON data: ' . json_last_error_msg()]);
        exit();
    }

    error_log("ADD KOS DEBUG: Decoded data keys: " . implode(', ', array_keys($data)));

    $user_id_from_header = $_SERVER['HTTP_X_USER_ID'] ?? '';
    $user_role_from_header = $_SERVER['HTTP_X_USER_ROLE'] ?? '';

    error_log("ADD KOS DEBUG: Request received. User ID: $user_id_from_header, Role: $user_role_from_header");

    $authorized_user_id = checkAuthorization(['pemilik_kos'], [
        'user_id' => $user_id_from_header,
        'role_name' => $user_role_from_header
    ]);

    $nama_kos = $data['nama_kos'] ?? '';
    $alamat = $data['alamat'] ?? '';
    $deskripsi = $data['deskripsi'] ?? null;
    $foto_utama_base64 = $data['foto_utama'] ?? null; // Menerima Base64 string
    $fasilitas_umum = $data['fasilitas_umum'] ?? null;

    error_log("ADD KOS DEBUG: nama_kos = $nama_kos");
    error_log("ADD KOS DEBUG: alamat = $alamat");
    error_log("ADD KOS DEBUG: deskripsi = " . ($deskripsi ?? 'NULL'));
    error_log("ADD KOS DEBUG: foto_utama_base64 provided = " . ($foto_utama_base64 ? 'YES' : 'NO'));
    if ($foto_utama_base64) {
        error_log("ADD KOS DEBUG: foto_utama_base64 length = " . strlen($foto_utama_base64));
        error_log("ADD KOS DEBUG: foto_utama_base64 preview (first 100): " . substr($foto_utama_base64, 0, 100));
    }
    error_log("ADD KOS DEBUG: fasilitas_umum = " . ($fasilitas_umum ?? 'NULL'));

    $owner_id = $authorized_user_id;

    if (empty($nama_kos) || empty($alamat)) {
        http_response_code(400);
        echo json_encode(['status' => 'error', 'message' => 'Nama kos dan alamat wajib diisi.']);
        error_log("ADD KOS DEBUG: Missing nama_kos or alamat.");
        exit();
    }

    $image_binary_data = null; // Ini akan menyimpan data BLOB untuk database
    $image_mime_type = null;   // Menyimpan tipe MIME (misal: image/jpeg)

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

        // Cek tipe MIME yang diizinkan
        if (!in_array($mime_type, ['image/jpeg', 'image/png', 'image/gif', 'image/webp'])) {
            http_response_code(400);
            echo json_encode(['status' => 'error', 'message' => 'Tipe gambar tidak didukung: ' . $mime_type]);
            error_log("ADD KOS DEBUG: Unsupported image type: " . $mime_type);
            exit();
        }

        $image_binary_data = $decoded_image;
        $image_mime_type = $mime_type;
        error_log("ADD KOS DEBUG: Image data ready for DB (MIME: $image_mime_type).");
    } else {
        error_log("ADD KOS DEBUG: No foto_utama_base64 provided.");
    }

    try {
        $pdo = getDBConnection();
        $pdo->beginTransaction();

        // Simpan URL gambar ke kolom foto_utama_url sesuai schema database
        // CATATAN: Untuk implementasi penuh, Anda perlu upload gambar ke storage dan dapatkan URL-nya
        // Untuk sementara, kita simpan sebagai data URI atau NULL
        $foto_utama_url = null;
        if ($image_binary_data !== null) {
            // Konversi binary ke data URI untuk disimpan sebagai TEXT
            $foto_utama_url = 'data:' . $image_mime_type . ';base64,' . base64_encode($image_binary_data);
            error_log("ADD KOS DEBUG: Created data URI. Length: " . strlen($foto_utama_url));
            error_log("ADD KOS DEBUG: Data URI preview (first 100): " . substr($foto_utama_url, 0, 100));
        }

        error_log("ADD KOS DEBUG: Final foto_utama_url to save = " . ($foto_utama_url ? 'YES (length: ' . strlen($foto_utama_url) . ')' : 'NULL'));

        $stmt = $pdo->prepare("INSERT INTO kos (user_id, nama_kos, alamat, deskripsi, foto_utama_url, fasilitas_umum) VALUES (?, ?, ?, ?, ?, ?)");
        $stmt->bindParam(1, $owner_id);
        $stmt->bindParam(2, $nama_kos);
        $stmt->bindParam(3, $alamat);
        $stmt->bindParam(4, $deskripsi);
        $stmt->bindParam(5, $foto_utama_url);
        $stmt->bindParam(6, $fasilitas_umum);

        error_log("ADD KOS DEBUG: Executing INSERT query...");
        $stmt->execute();
        $kos_id = $pdo->lastInsertId();

        error_log("ADD KOS DEBUG: INSERT successful. New kos_id: $kos_id");

        $pdo->commit();

        echo json_encode(['status' => 'success', 'message' => 'Kos berhasil ditambahkan.', 'id' => $kos_id, 'foto_utama_url' => $foto_utama_url]);
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
