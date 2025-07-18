<?php
// api/kos/add.php (DIUPDATE: Handle Base64 Image Upload)

require_once '../config/database.php';
require_once '../utils/auth_check.php';

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *'); // Sesuaikan di produksi
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-User-ID, X-User-Role');

// Handle OPTIONS request for CORS preflight
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $data = json_decode(file_get_contents('php://input'), true);

    $user_id_from_header = $_SERVER['HTTP_X_USER_ID'] ?? '';
    $user_role_from_header = $_SERVER['HTTP_X_USER_ROLE'] ?? '';

    // Otorisasi: hanya pemilik_kos yang bisa menambah kos
    $authorized_user_id = checkAuthorization(['pemilik_kos'], [
        'user_id' => $user_id_from_header,
        'role_name' => $user_role_from_header
    ]);

    $nama_kos = $data['nama_kos'] ?? '';
    $alamat = $data['alamat'] ?? '';
    $deskripsi = $data['deskripsi'] ?? null;
    $foto_utama_base64 = $data['foto_utama'] ?? null; // Menerima Base64 string atau null
    $fasilitas_umum = $data['fasilitas_umum'] ?? null;

    $owner_id = $authorized_user_id; 

    // Validasi input dasar
    if (empty($nama_kos) || empty($alamat)) {
        http_response_code(400);
        echo json_encode(['status' => 'error', 'message' => 'Nama kos dan alamat wajib diisi.']);
        exit();
    }

    $image_db_path = null; // Path gambar yang akan disimpan di database

    if ($foto_utama_base64) {
        // Logika untuk menangani upload gambar Base64
        $base64_parts = explode(',', $foto_utama_base64);
        $base64_string = end($base64_parts); // Ambil bagian Base64 setelah koma (jika ada prefix data:image/...)

        $decoded_image = base64_decode($base64_string);

        if ($decoded_image === false) {
             http_response_code(400);
             echo json_encode(['status' => 'error', 'message' => 'Format gambar Base64 tidak valid.']);
             exit();
        }

        // Tentukan ekstensi file (sederhana, bisa lebih robust)
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
                exit();
        }

        $upload_dir = '../../uploads/kos_images/'; // Path relatif dari folder 'api/kos/'
        $file_name = uniqid() . $extension;
        $file_path = $upload_dir . $file_name;

        // Pastikan folder upload ada
        if (!is_dir($upload_dir)) {
            if (!mkdir($upload_dir, 0777, true)) {
                http_response_code(500);
                echo json_encode(['status' => 'error', 'message' => 'Gagal membuat folder upload. Pastikan izin folder benar.']);
                exit();
            }
        }
        
        if (file_put_contents($file_path, $decoded_image)) {
            // Sukses menyimpan file, simpan path relatif ke DB
            $image_db_path = '/uploads/kos_images/' . $file_name; // Ini yang akan di database
        } else {
            http_response_code(500);
            echo json_encode(['status' => 'error', 'message' => 'Gagal menyimpan file gambar di server.']);
            exit();
        }
    }

    try {
        $pdo = getDBConnection();
        $pdo->beginTransaction(); // Mulai transaksi

        $stmt = $pdo->prepare("INSERT INTO kos (user_id, nama_kos, alamat, deskripsi, foto_utama, fasilitas_umum) VALUES (?, ?, ?, ?, ?, ?)");
        $stmt->execute([$owner_id, $nama_kos, $alamat, $deskripsi, $image_db_path, $fasilitas_umum]);
        $kos_id = $pdo->lastInsertId();

        $pdo->commit(); // Commit transaksi jika berhasil

        echo json_encode(['status' => 'success', 'message' => 'Kos berhasil ditambahkan.', 'id' => $kos_id, 'foto_utama_path' => $image_db_path]);
        http_response_code(201); // Created

    } catch (PDOException $e) {
        $pdo->rollBack(); // Rollback jika ada error
        error_log("Error adding kos: " . $e->getMessage());
        http_response_code(500);
        echo json_encode(['status' => 'error', 'message' => 'Gagal menambahkan kos.']);
    }

} else {
    http_response_code(405);
    echo json_encode(['status' => 'error', 'message' => 'Metode request tidak diizinkan. Hanya POST.']);
}
?>