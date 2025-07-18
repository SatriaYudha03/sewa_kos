<?php
// api/kos/update.php (DIUPDATE: Handle Base64 Image Upload)

require_once '../config/database.php';
require_once '../utils/auth_check.php';

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *'); // Sesuaikan di produksi
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

    $user_id_from_header = $_SERVER['HTTP_X_USER_ID'] ?? '';
    $user_role_from_header = $_SERVER['HTTP_X_USER_ROLE'] ?? '';

    // Otorisasi: hanya pemilik_kos yang bisa update
    $authorized_user_id = checkAuthorization(['pemilik_kos'], [
        'user_id' => $user_id_from_header,
        'role_name' => $user_role_from_header
    ]);

    if (empty($kos_id) || !is_numeric($kos_id)) {
        http_response_code(400);
        echo json_encode(['status' => 'error', 'message' => 'ID Kos wajib diisi dan harus berupa angka.']);
        exit();
    }

    $nama_kos = $data['nama_kos'] ?? null;
    $alamat = $data['alamat'] ?? null;
    $deskripsi = $data['deskripsi'] ?? null;
    $foto_utama_input = $data['foto_utama'] ?? null; // Menerima Base64 string atau URL/path lama
    $fasilitas_umum = $data['fasilitas_umum'] ?? null;

    $image_db_path = null; // Path gambar yang akan disimpan di database

    try {
        $pdo = getDBConnection();
        $pdo->beginTransaction(); // Mulai transaksi

        // 1. Ambil data kos yang sudah ada untuk verifikasi kepemilikan dan current foto_utama
        $stmt_kos = $pdo->prepare("SELECT user_id, foto_utama FROM kos WHERE id = ?");
        $stmt_kos->execute([$kos_id]);
        $kos_info = $stmt_kos->fetch();

        if (!$kos_info) {
            http_response_code(404);
            echo json_encode(['status' => 'error', 'message' => 'Kos tidak ditemukan.']);
            $pdo->rollBack();
            exit();
        }

        // Verifikasi kepemilikan
        if ($kos_info['user_id'] != $authorized_user_id) {
            http_response_code(403);
            echo json_encode(['status' => 'error', 'message' => 'Anda tidak diizinkan memperbarui kos ini.']);
            $pdo->rollBack();
            exit();
        }

        // Logika untuk menangani upload gambar Base64 atau mempertahankan yang lama
        if ($foto_utama_input) {
            // Cek apakah ini string base64
            if (strpos($foto_utama_input, 'data:image/') === 0 || base64_encode(base64_decode($foto_utama_input, true)) === $foto_utama_input) {
                // Hapus gambar lama jika ada dan berbeda dengan yang baru (opsional)
                if ($kos_info['foto_utama'] && strpos($kos_info['foto_utama'], '/uploads/') === 0) {
                    $old_file_path = '../../' . ltrim($kos_info['foto_utama'], '/'); // Convert /uploads/ to ../../uploads/
                    if (file_exists($old_file_path)) {
                        unlink($old_file_path); // Hapus file lama
                    }
                }

                $base64_parts = explode(',', $foto_utama_input);
                $base64_string = end($base64_parts);

                $decoded_image = base64_decode($base64_string);
                if ($decoded_image === false) {
                     http_response_code(400);
                     echo json_encode(['status' => 'error', 'message' => 'Format gambar Base64 tidak valid.']);
                     $pdo->rollBack();
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
                        exit();
                }

                $upload_dir = '../../uploads/kos_images/'; // Path relatif dari folder 'api/kos/'
                $file_name = uniqid() . $extension;
                $file_path = $upload_dir . $file_name;

                if (!is_dir($upload_dir)) {
                    mkdir($upload_dir, 0777, true);
                }
                
                if (file_put_contents($file_path, $decoded_image)) {
                    $image_db_path = '/uploads/kos_images/' . $file_name; // Path baru untuk DB
                } else {
                    http_response_code(500);
                    echo json_encode(['status' => 'error', 'message' => 'Gagal menyimpan file gambar di server.']);
                    $pdo->rollBack();
                    exit();
                }
            } else {
                // Jika bukan Base64, asumsikan ini adalah URL/path gambar lama yang tidak diubah
                $image_db_path = $foto_utama_input; 
            }
        } else {
            // Jika foto_utama_input adalah null/kosong, berarti ingin menghapus gambar
            // Hapus gambar lama jika ada
            if ($kos_info['foto_utama'] && strpos($kos_info['foto_utama'], '/uploads/') === 0) {
                $old_file_path = '../../' . ltrim($kos_info['foto_utama'], '/');
                if (file_exists($old_file_path)) {
                    unlink($old_file_path);
                }
            }
            $image_db_path = null; // Set ke null di DB
        }

        // Siapkan query UPDATE secara dinamis
        $set_parts = [];
        $params = [];

        if ($nama_kos !== null) { $set_parts[] = 'nama_kos = ?'; $params[] = $nama_kos; }
        if ($alamat !== null) { $set_parts[] = 'alamat = ?'; $params[] = $alamat; }
        if ($deskripsi !== null) { $set_parts[] = 'deskripsi = ?'; $params[] = $deskripsi; }
        // Update foto_utama hanya jika ada perubahan atau dihapus
        $set_parts[] = 'foto_utama = ?'; $params[] = $image_db_path; 
        if ($fasilitas_umum !== null) { $set_parts[] = 'fasilitas_umum = ?'; $params[] = $fasilitas_umum; }
        
        if (empty($set_parts)) {
            http_response_code(400);
            echo json_encode(['status' => 'info', 'message' => 'Tidak ada data untuk diperbarui.']);
            $pdo->rollBack();
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
        } else {
            $pdo->rollBack();
            echo json_encode(['status' => 'info', 'message' => 'Tidak ada perubahan pada data kos atau kos tidak ditemukan.']);
            http_response_code(200);
        }

    } catch (PDOException $e) {
        $pdo->rollBack();
        error_log("Error updating kos: " . $e->getMessage());
        http_response_code(500);
        echo json_encode(['status' => 'error', 'message' => 'Gagal memperbarui kos.']);
    } catch (Exception $e) { // Tangani exception lain, misal dari finfo
        $pdo->rollBack();
        error_log("General error updating kos: " . $e->getMessage());
        http_response_code(500);
        echo json_encode(['status' => 'error', 'message' => 'Terjadi kesalahan internal.']);
    }

} else {
    http_response_code(405);
    echo json_encode(['status' => 'error', 'message' => 'Metode request tidak diizinkan. Hanya PUT.']);
}
?>