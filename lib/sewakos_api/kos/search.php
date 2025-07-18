<?php
// api/kos/search.php

require_once '../config/database.php';
require_once '../utils/auth_check.php';

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-User-ID, X-User-Role');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    // Ambil data user dari header. Untuk pencarian, semua user bisa melakukan ini.
    $user_id_from_header = $_SERVER['HTTP_X_USER_ID'] ?? '';
    $user_role_from_header = $_SERVER['HTTP_X_USER_ROLE'] ?? 'penyewa';

    // Memastikan user terautentikasi (meskipun semua role diizinkan)
    checkAuthorization(['penyewa', 'pemilik_kos'], [
        'user_id' => $user_id_from_header,
        'role_name' => $user_role_from_header
    ]);

    // Parameter pencarian dari query string
    $keyword = $_GET['keyword'] ?? null; // Mencari di nama_kos, alamat, deskripsi, fasilitas_umum
    $min_price = $_GET['min_price'] ?? null;
    $max_price = $_GET['max_price'] ?? null;
    $fasilitas = $_GET['fasilitas'] ?? null; // Fasilitas kamar (misal: AC, KM_Dalam)

    try {
        $pdo = getDBConnection();

        $sql = "SELECT k.*, u.username as owner_username, u.nama_lengkap as owner_name, 
                       GROUP_CONCAT(CONCAT(mk.nama_kamar, ' (Rp', mk.harga_sewa, ')') ORDER BY mk.harga_sewa ASC SEPARATOR '; ') AS available_rooms
                FROM kos k 
                JOIN users u ON k.user_id = u.id
                LEFT JOIN kamar_kos mk ON k.id = mk.kos_id AND mk.status = 'tersedia'"; // Hanya kamar tersedia yang digabungkan

        $conditions = [];
        $params = [];

        if ($keyword) {
            $conditions[] = "(k.nama_kos LIKE ? OR k.alamat LIKE ? OR k.deskripsi LIKE ? OR k.fasilitas_umum LIKE ?)";
            $params[] = "%$keyword%";
            $params[] = "%$keyword%";
            $params[] = "%$keyword%";
            $params[] = "%$keyword%";
        }

        if ($min_price !== null && is_numeric($min_price)) {
            $conditions[] = "mk.harga_sewa >= ?";
            $params[] = $min_price;
        }
        if ($max_price !== null && is_numeric($max_price)) {
            $conditions[] = "mk.harga_sewa <= ?";
            $params[] = $max_price;
        }
        
        if ($fasilitas) {
            // Memisahkan fasilitas jika lebih dari satu dan mencari kecocokan parsial
            $fasilitas_arr = array_map('trim', explode(',', $fasilitas));
            $fasilitas_conditions = [];
            foreach ($fasilitas_arr as $f) {
                $fasilitas_conditions[] = "mk.fasilitas LIKE ?";
                $params[] = "%$f%";
            }
            if (!empty($fasilitas_conditions)) {
                $conditions[] = "(" . implode(' OR ', $fasilitas_conditions) . ")";
            }
        }
        
        // Gabungkan kondisi
        if (!empty($conditions)) {
            $sql .= " WHERE " . implode(' AND ', $conditions);
        }

        $sql .= " GROUP BY k.id ORDER BY k.created_at DESC"; // Urutkan berdasarkan yang terbaru

        $stmt = $pdo->prepare($sql);
        $stmt->execute($params);
        $kos_list = $stmt->fetchAll();

        if ($kos_list) {
            echo json_encode(['status' => 'success', 'data' => $kos_list]);
            http_response_code(200);
        } else {
            echo json_encode(['status' => 'success', 'message' => 'Tidak ada kos ditemukan dengan kriteria tersebut.', 'data' => []]);
            http_response_code(200);
        }

    } catch (PDOException $e) {
        error_log("Error searching kos: " . $e->getMessage());
        http_response_code(500);
        echo json_encode(['status' => 'error', 'message' => 'Gagal melakukan pencarian kos.']);
    }

} else {
    http_response_code(405);
    echo json_encode(['status' => 'error', 'message' => 'Metode request tidak diizinkan. Hanya GET.']);
}
?>