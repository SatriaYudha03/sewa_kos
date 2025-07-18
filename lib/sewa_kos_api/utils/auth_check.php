<?php
// api/utils/auth_check.php

// Fungsi untuk memeriksa otorisasi
function checkAuthorization($required_role_names, $user_data) {
    if (!isset($user_data['user_id']) || !isset($user_data['role_name'])) {
        http_response_code(401); // Unauthorized
        echo json_encode(['status' => 'error', 'message' => 'Authorization data missing.']);
        exit();
    }

    $user_id = $user_data['user_id'];
    $role_name = $user_data['role_name'];

    // Cek apakah role_name user ada dalam daftar role yang diizinkan
    if (!in_array($role_name, $required_role_names)) {
        http_response_code(403); // Forbidden
        echo json_encode(['status' => 'error', 'message' => 'Akses ditolak. Anda tidak memiliki izin.']);
        exit();
    }

    // Jika otorisasi lolos, kembalikan user_id untuk penggunaan lebih lanjut
    return $user_id;
}
?>