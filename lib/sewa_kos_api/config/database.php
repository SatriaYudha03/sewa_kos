<?php
// api/config/database.php

// Konfigurasi Database
define('DB_HOST', 'localhost'); // Ganti jika database Anda di server lain
define('DB_NAME', 'sewa_kos'); // Nama database yang sudah Anda buat
define('DB_USER', 'root');     // Username database Anda
define('DB_PASS', '');         // Password database Anda

// Fungsi untuk mendapatkan koneksi PDO
function getDBConnection() {
    $dsn = 'mysql:host=' . DB_HOST . ';dbname=' . DB_NAME . ';charset=utf8mb4';
    $options = [
        PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        PDO::ATTR_EMULATE_PREPARES   => false,
    ];
    try {
        $pdo = new PDO($dsn, DB_USER, DB_PASS, $options);
        return $pdo;
    } catch (PDOException $e) {
        // Log the error for debugging, but don't expose sensitive info to client
        error_log("Database connection failed: " . $e->getMessage());
        // Return a generic error message to the client
        http_response_code(500); // Internal Server Error
        echo json_encode(['status' => 'error', 'message' => 'Failed to connect to database.']);
        exit();
    }
}
?>