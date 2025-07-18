<?php
// api/kos/update.php (DIUPDATE)

require_once '../config/database.php';
require_once '../utils/auth_check.php';

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: PUT, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-User-ID, X-User-Role');

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
    $foto_utama = $data['foto_utama'] ?? null;
    $fasilitas_umum = $data['fasilitas_umum'] ?? null;
    // user_id_owner dihapus karena tidak ada admin yang bisa mengubah pemilik

    try {
        $pdo = getDBConnection();

        // Ambil data kos untuk verifikasi kepemilikan
        $stmt = $pdo->prepare("SELECT user_id FROM kos WHERE id = ?");
        $stmt->execute([$kos_id]);
        $kos = $stmt->fetch();

        if (!$kos) {
            http_response_code(404);
            echo json_encode(['status' => 'error', 'message' => 'Kos tidak ditemukan.']);
            exit();
        }

        // Verifikasi kepemilikan
        if ($kos['user_id'] != $authorized_user_id) {
            http_response_code(403);
            echo json_encode(['status' => 'error', 'message' => 'Anda tidak diizinkan memperbarui kos ini.']);
            exit();
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
        if ($foto_utama !== null) {
            $set_parts[] = 'foto_utama = ?';
            $params[] = $foto_utama;
        }
        if ($fasilitas_umum !== null) {
            $set_parts[] = 'fasilitas_umum = ?';
            $params[] = $fasilitas_umum;
        }
        
        if (empty($set_parts)) {
            http_response_code(400);
            echo json_encode(['status' => 'error', 'message' => 'Tidak ada data untuk diperbarui.']);
            exit();
        }

        $sql = "UPDATE kos SET " . implode(', ', $set_parts) . " WHERE id = ?";
        $params[] = $kos_id;

        $stmt = $pdo->prepare($sql);
        $stmt->execute($params);

        if ($stmt->rowCount() > 0) {
            echo json_encode(['status' => 'success', 'message' => 'Data kos berhasil diperbarui.']);
            http_response_code(200);
        } else {
            echo json_encode(['status' => 'info', 'message' => 'Tidak ada perubahan pada data kos atau kos tidak ditemukan.']);
            http_response_code(200);
        }

    } catch (PDOException $e) {
        error_log("Error updating kos: " . $e->getMessage());
        http_response_code(500);
        echo json_encode(['status' => 'error', 'message' => 'Gagal memperbarui kos.']);
    }

} else {
    http_response_code(405);
    echo json_encode(['status' => 'error', 'message' => 'Metode request tidak diizinkan. Hanya PUT.']);
}
?>