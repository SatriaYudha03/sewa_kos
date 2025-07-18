<?php
// api/auth/login.php (TIDAK BERUBAH DARI SEBELUMNYA)

require_once '../config/database.php';

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *'); 
header('Access-Control-Allow-Methods: POST, GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $data = json_decode(file_get_contents('php://input'), true);

    $username_or_email = $data['username_or_email'] ?? '';
    $password = $data['password'] ?? '';

    if (empty($username_or_email) || empty($password)) {
        echo json_encode(['status' => 'error', 'message' => 'Username/email dan password wajib diisi.']);
        http_response_code(400); 
        exit();
    }

    try {
        $pdo = getDBConnection();

        $stmt = $pdo->prepare("SELECT u.id, u.username, u.email, u.password, r.role_name
                               FROM users u
                               JOIN roles r ON u.role_id = r.id
                               WHERE u.username = ? OR u.email = ?");
        $stmt->execute([$username_or_email, $username_or_email]);
        $user = $stmt->fetch();

        if ($user && password_verify($password, $user['password'])) {
            unset($user['password']); 
            
            echo json_encode([
                'status' => 'success',
                'message' => 'Login berhasil.',
                'user' => $user 
            ]);
            http_response_code(200);

        } else {
            echo json_encode(['status' => 'error', 'message' => 'Username/email atau password salah.']);
            http_response_code(401); 
        }

    } catch (PDOException $e) {
        error_log("Login error: " . $e->getMessage());
        echo json_encode(['status' => 'error', 'message' => 'Terjadi kesalahan saat login.']);
        http_response_code(500); 
    }
} else {
    echo json_encode(['status' => 'error', 'message' => 'Metode request tidak diizinkan. Hanya POST.']);
    http_response_code(405); 
}
?>