<?php
// api/kos/update.php (Kode Lengkap - Path Dikonfirmasi Benar untuk Struktur Anda)

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
header('Access-Control-Allow-Methods: PUT, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-User-ID, X-User-Role');

// Handle OPTIONS request for CORS preflight
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

if ($_SERVER['REQUEST_METHOD'] === 'PUT') {
    $data = json_decode(file_get_contents('php://input'), true);

    $kos_id = $data['id'] ?? '';

    $user_id_from_header = $data['user_id_from_header'] ?? ($_SERVER['HTTP_X_USER_ID'] ?? '');
    $user_role_from_header = $data['user_role_from_header'] ?? ($_SERVER['HTTP_X_USER_ROLE'] ?? '');

    error_log("UPDATE KOS DEBUG: Request received. Kos ID: $kos_id, User ID: $user_id_from_header, Role: $user_role_from_header");

    // Otorisasi: hanya pemilik_kos yang bisa update
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
    $foto_utama_input = $data['foto_utama'] ?? null; 
    $fasilitas_umum = $data['fasilitas_umum'] ?? null;

    $image_db_path = null; 

    try {
        $pdo = getDBConnection();
        $pdo->beginTransaction(); 

        // 1. Ambil data kos yang sudah ada untuk verifikasi kepemilikan dan current foto_utama
        $stmt_kos = $pdo->prepare("SELECT user_id, foto_utama FROM kos WHERE id = ?");
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

        // Logika untuk menangani upload gambar Base64 atau mempertahankan yang lama
        if ($foto_utama_input) {
            error_log("UPDATE KOS DEBUG: foto_utama_input received. Length: " . strlen($foto_utama_input));

            if (strpos($foto_utama_input, 'data:image/') === 0 || base64_encode(base64_decode($foto_utama_input, true)) === $foto_utama_input) {
                error_log("UPDATE KOS DEBUG: foto_utama_input detected as Base64. Processing new image.");

                // Hapus gambar lama jika ada dan merupakan file yang kita kelola
                if ($kos_info['foto_utama'] && strpos($kos_info['foto_utama'], '/uploads/') === 0) {
                    $old_file_path = '../..' . $kos_info['foto_utama']; 
                    if (file_exists($old_file_path)) {
                        unlink($old_file_path); 
                        error_log("UPDATE KOS DEBUG: Old image '$old_file_path' deleted.");
                    } else {
                        error_log("UPDATE KOS DEBUG: Old image '$old_file_path' not found for deletion.");
                    }
                }

                $base64_parts = explode(',', $foto_utama_input);
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
                $extension = '';
                switch ($mime_type) {
                    case 'image/jpeg': $extension = '.jpg'; break;
                    case 'image/png': $extension = '.png'; break;
                    case 'image/gif': $extension = '.gif'; break;
                    case 'image/webp': $extension = '.webp'; break;
                    default:
                        http_response_code(400);
                        echo json_encode(['status' => 'error', 'message' => 'Tipe gambar tidak didukung: ' . $mime_type]);
                        $pdo->rollBack();
                        error_log("UPDATE KOS DEBUG: Unsupported new image type: " . $mime_type);
                        exit();
                }
                error_log("UPDATE KOS DEBUG: Detected new image MIME type: $mime_type, Extension: $extension");

                $upload_dir = '../uploads/kos_images/'; // <-- PATH INI BENAR untuk struktur Anda!
                $file_name = uniqid() . $extension;
                $file_path = $upload_dir . $file_name;

                if (!is_dir($upload_dir)) {
                    error_log("UPDATE KOS DEBUG: Upload directory '$upload_dir' does not exist. Trying to create.");
                    if (!mkdir($upload_dir, 0777, true)) {
                        http_response_code(500);
                        echo json_encode(['status' => 'error', 'message' => 'Gagal membuat folder upload. Pastikan izin folder benar.']);
                        $pdo->rollBack();
                        error_log("UPDATE KOS DEBUG: Failed to create upload directory: '$upload_dir'");
                        exit();
                    }
                }
                if (!is_writable($upload_dir)) {
                    http_response_code(500);
                    echo json_encode(['status' => 'error', 'message' => 'Folder upload tidak memiliki izin tulis.']);
                    $pdo->rollBack();
                    error_log("UPDATE KOS DEBUG: Upload directory '$upload_dir' is not writable.");
                    exit();
                }
                
                if (file_put_contents($file_path, $decoded_image)) {
                    $image_db_path = '/uploads/kos_images/' . $file_name; 
                    error_log("UPDATE KOS DEBUG: New image successfully saved to: " . $file_path . ". DB path: " . $image_db_path);
                } else {
                    $last_php_error = error_get_last();
                    $error_message = $last_php_error ? $last_php_error['message'] : 'Unknown error';
                    http_response_code(500);
                    echo json_encode(['status' => 'error', 'message' => 'Gagal menyimpan file gambar baru di server.']);
                    $pdo->rollBack();
                    error_log("UPDATE KOS DEBUG: Failed to save new image. Path: " . $file_path . ". PHP Error: " . $error_message);
                    exit();
                }
            } else {
                $image_db_path = $foto_utama_input; 
                error_log("UPDATE KOS DEBUG: foto_utama_input is not Base64. Retaining current path: " . $image_db_path);
            }
        } else {
            error_log("UPDATE KOS DEBUG: foto_utama_input is null/empty. Attempting to delete old image.");
            if ($kos_info['foto_utama'] && strpos($kos_info['foto_utama'], '/uploads/') === 0) {
                $old_file_path = '../..' . $kos_info['foto_utama'];
                if (file_exists($old_file_path)) {
                    unlink($old_file_path);
                    error_log("UPDATE KOS DEBUG: Old image '$old_file_path' deleted.");
                } else {
                    error_log("UPDATE KOS DEBUG: Old image '$old_file_path' not found for deletion.");
                }
            }
            $image_db_path = null; 
        }

        $set_parts = [];
        $params = [];

        if ($nama_kos !== null) { $set_parts[] = 'nama_kos = ?'; $params[] = $nama_kos; }
        if ($alamat !== null) { $set_parts[] = 'alamat = ?'; $params[] = $alamat; }
        if ($deskripsi !== null) { $set_parts[] = 'deskripsi = ?'; $params[] = $deskripsi; }
        $set_parts[] = 'foto_utama = ?'; $params[] = $image_db_path; 
        if ($fasilitas_umum !== null) { $set_parts[] = 'fasilitas_umum = ?'; $params[] = $fasilitas_umum; }
        
        if (empty($set_parts)) {
            http_response_code(400);
            echo json_encode(['status' => 'info', 'message' => 'Tidak ada data untuk diperbarui.']);
            $pdo->rollBack();
            error_log("UPDATE KOS DEBUG: No data to update.");
            exit();
        }

        $sql = "UPDATE kos SET " . implode(', ', $set_parts) . " WHERE id = ?";
        $params[] = $kos_id;

        $stmt = $pdo->prepare($sql);
        $stmt->execute($params);

        if ($stmt->rowCount() > 0) {
            $pdo->commit();
            echo json_encode(['status' => 'success', 'message' => 'Data kos berhasil diperbarui.', 'foto_utama_path' => $image_db_path]);
            http_response_code(200);
            error_log("UPDATE KOS DEBUG: Kos updated successfully. ID: $kos_id.");
        } else {
            $pdo->rollBack();
            echo json_encode(['status' => 'info', 'message' => 'Tidak ada perubahan pada data kos atau kos tidak ditemukan.']);
            http_response_code(200);
            error_log("UPDATE KOS DEBUG: No rows affected during update for ID: $kos_id.");
        }

    } catch (PDOException $e) {
        $pdo->rollBack();
        error_log("UPDATE KOS DEBUG: PDOException during update: " . $e->getMessage());
        http_response_code(500);
        echo json_encode(['status' => 'error', 'message' => 'Gagal memperbarui kos (Database Error).']);
    } catch (Exception $e) { 
        $pdo->rollBack();
        error_log("UPDATE KOS DEBUG: General Exception during update: " . $e->getMessage());
        http_response_code(500);
        echo json_encode(['status' => 'error', 'message' => 'Terjadi kesalahan internal.']);
    }

} else {
    http_response_code(405);
    echo json_encode(['status' => 'error', 'message' => 'Metode request tidak diizinkan. Hanya PUT.']);
    error_log("UPDATE KOS DEBUG: Invalid request method: " . $_SERVER['REQUEST_METHOD']);
}
?>