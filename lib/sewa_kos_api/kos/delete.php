<?php
// api/kos/delete.php (DIUPDATE)

require_once '../config/database.php';
require_once '../utils/auth_check.php';

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-User-ID, X-User-Role');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

if ($_SERVER['REQUEST_METHOD'] === 'DELETE') {
    $data = json_decode(file_get_contents('php://input'), true);
    $kos_id = $data['id'] ?? '';

    $user_id_from_header = $_SERVER['HTTP_X_USER_ID'] ?? '';
    $user_role_from_header = $_SERVER['HTTP_X_USER_ROLE'] ?? '';

    // Otorisasi: hanya pemilik_kos yang bisa menghapus
    $authorized_user_id = checkAuthorization(['pemilik_kos'], [
        'user_id' => $user_id_from_header,
        'role_name' => $user_role_from_header
    ]);

    if (empty($kos_id) || !is_numeric($kos_id)) {
        http_response_code(400);
        echo json_encode(['status' => 'error', 'message' => 'ID Kos wajib diisi dan harus berupa angka.']);
        exit();
    }

    try {
        $pdo = getDBConnection();

        // Ambil data kos untuk verifikasi kepemilikan sebelum menghapus
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
            echo json_encode(['status' => 'error', 'message' => 'Anda tidak diizinkan menghapus kos ini.']);
            exit();
        }
        
        $pdo->beginTransaction();

        // Hapus kamar_kos terkait terlebih dahulu
        $stmt_delete_kamar = $pdo->prepare("DELETE FROM kamar_kos WHERE kos_id = ?");
        $stmt_delete_kamar->execute([$kos_id]);

        // Hapus data kos
        $stmt_delete_kos = $pdo->prepare("DELETE FROM kos WHERE id = ?");
        $stmt_delete_kos->execute([$kos_id]);

        if ($stmt_delete_kos->rowCount() > 0) {
            $pdo->commit(); 
            echo json_encode(['status' => 'success', 'message' => 'Kos dan kamar terkait berhasil dihapus.']);
            http_response_code(200);
        } else {
            $pdo->rollBack(); 
            echo json_encode(['status' => 'info', 'message' => 'Kos tidak ditemukan atau tidak ada perubahan.']);
            http_response_code(200);
        }

    } catch (PDOException $e) {
        $pdo->rollBack(); 
        error_log("Error deleting kos: " . $e->getMessage());
        http_response_code(500);
        echo json_encode(['status' => 'error', 'message' => 'Gagal menghapus kos.']);
    }

} else {
    http_response_code(405);
    echo json_encode(['status' => 'error', 'message' => 'Metode request tidak diizinkan. Hanya DELETE.']);
}
?>