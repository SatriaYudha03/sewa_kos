<?php
// api/kos/add.php (DIUPDATE)

require_once '../config/database.php';
require_once '../utils/auth_check.php';

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-User-ID, X-User-Role'); 

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $data = json_decode(file_get_contents('php://input'), true);

    $user_id_from_header = $_SERVER['HTTP_X_USER_ID'] ?? '';
    $user_role_from_header = $_SERVER['HTTP_X_USER_ROLE'] ?? '';

    // Lakukan otorisasi: hanya pemilik_kos yang bisa menambah kos
    // checkAuthorization akan menghentikan eksekusi jika tidak diizinkan
    $authorized_user_id = checkAuthorization(['pemilik_kos'], [
        'user_id' => $user_id_from_header,
        'role_name' => $user_role_from_header
    ]);

    $nama_kos = $data['nama_kos'] ?? '';
    $alamat = $data['alamat'] ?? '';
    $deskripsi = $data['deskripsi'] ?? null;
    $foto_utama = $data['foto_utama'] ?? null; 
    $fasilitas_umum = $data['fasilitas_umum'] ?? null;

    // Pemilik kos hanya bisa menambah kos untuk dirinya sendiri
    $owner_id = $authorized_user_id; 

    if (empty($nama_kos) || empty($alamat)) {
        http_response_code(400);
        echo json_encode(['status' => 'error', 'message' => 'Nama kos dan alamat wajib diisi.']);
        exit();
    }

    try {
        $pdo = getDBConnection();
        $stmt = $pdo->prepare("INSERT INTO kos (user_id, nama_kos, alamat, deskripsi, foto_utama, fasilitas_umum) VALUES (?, ?, ?, ?, ?, ?)");
        $stmt->execute([$owner_id, $nama_kos, $alamat, $deskripsi, $foto_utama, $fasilitas_umum]);

        echo json_encode(['status' => 'success', 'message' => 'Kos berhasil ditambahkan.', 'id' => $pdo->lastInsertId()]);
        http_response_code(201); 

    } catch (PDOException $e) {
        error_log("Error adding kos: " . $e->getMessage());
        http_response_code(500);
        echo json_encode(['status' => 'error', 'message' => 'Gagal menambahkan kos.']);
    }

} else {
    http_response_code(405);
    echo json_encode(['status' => 'error', 'message' => 'Metode request tidak diizinkan. Hanya POST.']);
}
?>