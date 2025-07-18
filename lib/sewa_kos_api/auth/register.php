<?php
// api/auth/register.php (DIUPDATE)

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

    $username = $data['username'] ?? '';
    $email = $data['email'] ?? '';
    $password = $data['password'] ?? '';
    $role_name = $data['role'] ?? 'penyewa'; // Default role

    // --- Validasi Input ---
    if (empty($username) || empty($email) || empty($password)) {
        echo json_encode(['status' => 'error', 'message' => 'Username, email, dan password wajib diisi.']);
        http_response_code(400); 
        exit();
    }

    if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
        echo json_encode(['status' => 'error', 'message' => 'Format email tidak valid.']);
        http_response_code(400);
        exit();
    }

    // Hanya izinkan role 'penyewa' atau 'pemilik_kos'
    if (!in_array($role_name, ['penyewa', 'pemilik_kos'])) {
        echo json_encode(['status' => 'error', 'message' => 'Role tidak valid. Pilih "penyewa" atau "pemilik_kos".']);
        http_response_code(400);
        exit();
    }

    $hashed_password = password_hash($password, PASSWORD_DEFAULT);

    try {
        $pdo = getDBConnection();

        // Dapatkan role_id berdasarkan role_name
        $stmt = $pdo->prepare("SELECT id FROM roles WHERE role_name = ?");
        $stmt->execute([$role_name]);
        $role = $stmt->fetch();

        if (!$role) { // Seharusnya tidak terjadi jika roles sudah di-insert dengan benar
            echo json_encode(['status' => 'error', 'message' => 'Terjadi masalah internal dengan peran pengguna.']);
            http_response_code(500);
            exit();
        }
        $role_id = $role['id'];

        // Masukkan user baru ke tabel users
        $stmt = $pdo->prepare("INSERT INTO users (username, email, password, role_id) VALUES (?, ?, ?, ?)");
        $stmt->execute([$username, $email, $hashed_password, $role_id]);

        echo json_encode(['status' => 'success', 'message' => 'Registrasi berhasil.']);
        http_response_code(201); 

    } catch (PDOException $e) {
        if ($e->getCode() == 23000) { 
            echo json_encode(['status' => 'error', 'message' => 'Username atau email sudah digunakan.']);
            http_response_code(409); 
        } else {
            error_log("Registration error: " . $e->getMessage());
            echo json_encode(['status' => 'error', 'message' => 'Terjadi kesalahan saat registrasi.']);
            http_response_code(500);
        }
    }
} else {
    echo json_encode(['status' => 'error', 'message' => 'Metode request tidak diizinkan. Hanya POST.']);
    http_response_code(405); 
}
?>