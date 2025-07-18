<?php
// api/kos/list.php (DIUPDATE)

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
    $user_id_from_header = $_SERVER['HTTP_X_USER_ID'] ?? '';
    $user_role_from_header = $_SERVER['HTTP_X_USER_ROLE'] ?? 'penyewa';

    // Otorisasi: semua role bisa melihat daftar kos, tapi scope-nya beda
    checkAuthorization(['penyewa', 'pemilik_kos'], [
        'user_id' => $user_id_from_header,
        'role_name' => $user_role_from_header
    ]);

    try {
        $pdo = getDBConnection();
        $sql = "SELECT k.*, u.username as owner_username, u.nama_lengkap as owner_name 
                FROM kos k 
                JOIN users u ON k.user_id = u.id";
        $params = [];

        if ($user_role_from_header === 'pemilik_kos') {
            $sql .= " WHERE k.user_id = ?";
            $params[] = $user_id_from_header;
        }
        // Penyewa melihat semua kos.

        $stmt = $pdo->prepare($sql);
        $stmt->execute($params);
        $kos_list = $stmt->fetchAll();

        if ($kos_list) {
            echo json_encode(['status' => 'success', 'data' => $kos_list]);
            http_response_code(200);
        } else {
            echo json_encode(['status' => 'success', 'message' => 'Tidak ada data kos ditemukan.', 'data' => []]);
            http_response_code(200);
        }

    } catch (PDOException $e) {
        error_log("Error fetching kos list: " . $e->getMessage());
        http_response_code(500);
        echo json_encode(['status' => 'error', 'message' => 'Gagal mengambil daftar kos.']);
    }

} else {
    http_response_code(405);
    echo json_encode(['status' => 'error', 'message' => 'Metode request tidak diizinkan. Hanya GET.']);
}
?>