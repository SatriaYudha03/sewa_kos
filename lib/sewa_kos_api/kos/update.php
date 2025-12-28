<?php
// api/kos/update.php (DIUPDATE: Menyimpan gambar Base64 ke DB sebagai BLOB)

// --- DEBUGGING SANGAT AGRESIF (HAPUS ini di produksi!) ---
error_reporting(E_ALL);
ini_set('display_errors', 1);
ini_set('log_errors', 1);
ini_set('error_log', '../../php_error.log');

error_log("UPDATE KOS DEBUG: Script execution started. Request Method: " . $_SERVER['REQUEST_METHOD']);

// --- HEADER CORS UNIVERSAL ---
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-User-ID, X-User-Role');

// --- IMPORTS ---
require_once '../config/database.php';
require_once '../utils/auth_check.php';

// --- HANDLE PREFLIGHT OPTIONS REQUEST ---
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    error_log("UPDATE KOS DEBUG: Handling OPTIONS request.");
    header('Access-Control-Allow-Origin: *');
    header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
    header('Access-Control-Allow-Headers: Origin, X-Requested-With, Content-Type, Accept, Authorization, X-User-ID, X-User-Role');
    header('Access-Control-Max-Age: 3600');
    http_response_code(200);
    exit();
}

if ($_SERVER['REQUEST_METHOD'] === 'PUT') {
    $raw_input = file_get_contents('php://input');
    $data = json_decode($raw_input, true);

    error_log("UPDATE KOS DEBUG: Raw input: " . $raw_input);
    error_log("UPDATE KOS DEBUG: Decoded data: " . print_r($data, true));

    $kos_id = $data['id'] ?? '';

    $user_id_from_header = $_SERVER['HTTP_X_USER_ID'] ?? '';
    $user_role_from_header = $_SERVER['HTTP_X_USER_ROLE'] ?? '';

    error_log("UPDATE KOS DEBUG: Request received. Kos ID: $kos_id, User ID: $user_id_from_header, Role: $user_role_from_header");

    $authorized_user_id = checkAuthorization(['pemilik_kos'], [
        'user_id' => $user_id_from_header,
        'role_name' => $user_role_from_header
    ]);

    if (empty($kos_id) || !is_numeric($kos_id)) {
        http_response_code(400);
        echo json_encode(['status' => 'error', 'message' => 'ID Kos wajib diisi dan harus berupa angka.']);
        error_log("UPDATE KOS DEBUG: Missing or invalid Kos ID.");
        exit();
    }

    $nama_kos = $data['nama_kos'] ?? null;
    $alamat = $data['alamat'] ?? null;
    $deskripsi = $data['deskripsi'] ?? null;
    $foto_utama_base64 = $data['foto_utama'] ?? null; // Menerima Base64 string atau null (jika dihapus)
    $fasilitas_umum = $data['fasilitas_umum'] ?? null;

    $image_binary_data = null; // Ini akan menyimpan data BLOB untuk database
    $image_mime_type = null;   // Menyimpan tipe MIME (misal: image/jpeg)

    try {
        $pdo = getDBConnection();
        $pdo->beginTransaction();

        // 1. Ambil data kos yang sudah ada untuk verifikasi kepemilikan dan current foto_utama_url
        $stmt_kos = $pdo->prepare("SELECT user_id, foto_utama_url FROM kos WHERE id = ?");
        $stmt_kos->execute([$kos_id]);
        $kos_info = $stmt_kos->fetch();

        if (!$kos_info) {
            http_response_code(404);
            echo json_encode(['status' => 'error', 'message' => 'Kos tidak ditemukan.']);
            $pdo->rollBack();
            error_log("UPDATE KOS DEBUG: Kos with ID $kos_id not found.");
            exit();
        }

        // Verifikasi kepemilikan
        if ($kos_info['user_id'] != $authorized_user_id) {
            http_response_code(403);
            echo json_encode(['status' => 'error', 'message' => 'Anda tidak diizinkan memperbarui kos ini.']);
            $pdo->rollBack();
            error_log("UPDATE KOS DEBUG: User $authorized_user_id attempted to update kos owned by ${kos_info['user_id']}. Access denied.");
            exit();
        }

        // Logika untuk menangani upload gambar Base64 atau menghapus/mempertahankan
        if ($foto_utama_base64) { // Jika ada data gambar yang dikirim (bisa base64 baru atau string path lama - yang sekarang tidak relevan)
            error_log("UPDATE KOS DEBUG: foto_utama_base64 received. Length: " . strlen($foto_utama_base64));

            // Periksa apakah ini string base64 baru (dimulai dengan 'data:image/' atau valid base64)
            if (strpos($foto_utama_base64, 'data:image/') === 0 || base64_encode(base64_decode($foto_utama_base64, true)) === $foto_utama_base64) {
                error_log("UPDATE KOS DEBUG: foto_utama_input detected as Base64. Processing new image.");

                $base64_parts = explode(',', $foto_utama_base64);
                $base64_string = end($base64_parts);

                $decoded_image = base64_decode($base64_string);
                if ($decoded_image === false) {
                    http_response_code(400);
                    echo json_encode(['status' => 'error', 'message' => 'Format gambar Base64 tidak valid.']);
                    $pdo->rollBack();
                    error_log("UPDATE KOS DEBUG: Base64 decode failed for new image.");
                    exit();
                }

                $finfo = new finfo(FILEINFO_MIME_TYPE);
                $mime_type = $finfo->buffer($decoded_image);

                // Cek tipe MIME yang diizinkan
                if (!in_array($mime_type, ['image/jpeg', 'image/png', 'image/gif', 'image/webp'])) {
                    http_response_code(400);
                    echo json_encode(['status' => 'error', 'message' => 'Tipe gambar tidak didukung: ' . $mime_type]);
                    $pdo->rollBack();
                    error_log("UPDATE KOS DEBUG: Unsupported new image type: " . $mime_type);
                    exit();
                }

                // Konversi binary ke data URI untuk disimpan sebagai TEXT
                $image_binary_data = 'data:' . $mime_type . ';base64,' . base64_encode($decoded_image);
                $image_mime_type = $mime_type;
                error_log("UPDATE KOS DEBUG: New image data ready for DB (MIME: $image_mime_type).");
            } else {
                // Ini kasus di mana Flutter mengirim URL lama atau data URI
                // Pertahankan URL/data URI yang sudah ada
                $image_binary_data = $kos_info['foto_utama_url'];
                error_log("UPDATE KOS DEBUG: foto_utama_input is not Base64. Assuming no image change. Retaining existing URL.");
            }
        } else { // foto_utama_base64 adalah null atau kosong
            // Ini berarti user ingin menghapus gambar
            $image_binary_data = null; // Set ke null di DB
            error_log("UPDATE KOS DEBUG: foto_utama_input is null/empty. Setting image to null in DB.");
        }


        // Siapkan query UPDATE secara dinamis
        $set_parts = [];
        $params = [];

        if ($nama_kos !== null) {
            $set_parts[] = 'nama_kos = ?';
            $params[] = $nama_kos;
        }
        if ($alamat !== null) {
            $set_parts[] = 'alamat = ?';
            $params[] = $alamat;
        }
        if ($deskripsi !== null) {
            $set_parts[] = 'deskripsi = ?';
            $params[] = $deskripsi;
        }

        // Foto utama selalu diupdate karena bisa null, atau URL/data URI baru
        $set_parts[] = 'foto_utama_url = ?';
        $params[] = $image_binary_data; // Sekarang ini adalah URL atau data URI, bukan binary

        if ($fasilitas_umum !== null) {
            $set_parts[] = 'fasilitas_umum = ?';
            $params[] = $fasilitas_umum;
        }

        if (empty($set_parts)) {
            http_response_code(200);
            echo json_encode(['status' => 'info', 'message' => 'Tidak ada data untuk diperbarui.']);
            $pdo->rollBack();
            error_log("UPDATE KOS DEBUG: No data to update.");
            exit();
        }

        $sql = "UPDATE kos SET " . implode(', ', $set_parts) . " WHERE id = ?";
        $params[] = $kos_id; // Tambahkan kos_id sebagai parameter terakhir

        $stmt = $pdo->prepare($sql);
        $stmt->execute($params);

        if ($stmt->rowCount() > 0) {
            $pdo->commit();
            http_response_code(200);
            echo json_encode(['status' => 'success', 'message' => 'Data kos berhasil diperbarui.']);
            error_log("UPDATE KOS DEBUG: Kos updated successfully. ID: $kos_id.");
        } else {
            $pdo->rollBack();
            http_response_code(200);
            echo json_encode(['status' => 'info', 'message' => 'Tidak ada perubahan pada data kos atau kos tidak ditemukan.']);
            error_log("UPDATE KOS DEBUG: No rows affected during update for ID: $kos_id.");
        }
    } catch (PDOException $e) {
        $pdo->rollBack();
        error_log("UPDATE KOS DEBUG: PDOException: " . $e->getMessage());
        http_response_code(500);
        echo json_encode(['status' => 'error', 'message' => 'Gagal memperbarui kos (Database Error).']);
    } catch (Exception $e) {
        $pdo->rollBack();
        error_log("UPDATE KOS DEBUG: General Exception: " . $e->getMessage());
        http_response_code(500);
        echo json_encode(['status' => 'error', 'message' => 'Terjadi kesalahan internal.']);
    }
} else {
    http_response_code(405);
    echo json_encode(['status' => 'error', 'message' => 'Metode request tidak diizinkan. Hanya PUT.']);
    error_log("UPDATE KOS DEBUG: Invalid request method: " . $_SERVER['REQUEST_METHOD']);
}
