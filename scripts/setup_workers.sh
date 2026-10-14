#!/bin/bash
# ==============================================================================
# setup_workers.sh — Konfigurasi Worker Frontend & API (Nginx + PHP-FPM)
# Modul 3: Soal 14 (dan integrasi Soal 15, 16, 17, 18)
# Kelompok K-02 (Prefix: 192.212.x.x)
#
# Penggunaan:
#   bash /root/setup_workers.sh [maki|panda|nanami|todo|kirara]
# ==============================================================================

WORKER="${1:-$(hostname)}"
WORKER_LOWER=$(echo "$WORKER" | tr '[:upper:]' '[:lower:]')

echo "=== Memulai Konfigurasi Worker: $WORKER_LOWER ==="

# 1. Pastikan DNS internet aktif untuk install paket
echo "nameserver 192.168.122.1" > /etc/resolv.conf

# 2. Instalasi Nginx dan PHP-FPM
if ! command -v nginx &>/dev/null || ! command -v php &>/dev/null; then
    echo "[*] Menginstal Nginx dan PHP-FPM..."
    apt-get update -y
    apt-get install -y nginx php-fpm php-mysql curl
fi

# Cari socket PHP-FPM yang aktif di sistem Debian
service php*-fpm start 2>/dev/null || true
PHP_SOCK=$(ls -1 /run/php/php*-fpm.sock 2>/dev/null | head -n 1)
if [ -z "$PHP_SOCK" ]; then
    # Fallback default socket Debian
    PHP_SOCK="/run/php/php-fpm.sock"
fi
echo "[*] Socket PHP-FPM terdeteksi: $PHP_SOCK"

# 3. Konfigurasi berdasarkan tipe worker
case "$WORKER_LOWER" in
    # ── Frontend Workers (maki & panda) ──────────────────────────────────────
    *maki*|*panda*)
        echo "[*] Mengonfigurasi Web Frontend Worker ($WORKER_LOWER)..."
        mkdir -p /var/www/html

        # Halaman Frontend menyajikan hostname masing-masing
        cat << 'EOF' > /var/www/html/index.php
<!DOCTYPE html>
<html>
<head>
    <title>Jujutsu High - Frontend Portal</title>
    <style>
        body { font-family: sans-serif; background: #1a1a2e; color: #e94560; text-align: center; padding-top: 50px; }
        .card { background: #16213e; display: inline-block; padding: 30px; border-radius: 12px; box-shadow: 0 4px 15px rgba(0,0,0,0.5); }
        h1 { margin-bottom: 10px; color: #0f3460; background: #e94560; color: white; padding: 10px 20px; border-radius: 8px; }
        .host { font-size: 24px; color: #4ecca3; font-weight: bold; }
    </style>
</head>
<body>
    <div class="card">
        <h1>Jujutsu High - Web Portal</h1>
        <p>Respon dari Frontend Worker:</p>
        <p class="host"><?php echo htmlspecialchars(gethostname()); ?></p>
        <p><small>IP Worker: <?php echo $_SERVER['SERVER_ADDR'] ?? '192.212.4.x'; ?></small></p>
    </div>
</body>
</html>
EOF

        # Virtual host Nginx dengan ACL Pembatasan Akses
        # - Hanya menerima trafik dari proxy web (gojo: 192.212.1.4)
        # - Menolak akses langsung dari klien Divisi A & B
        cat << EOF > /etc/nginx/sites-available/default
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    server_name jujutsu.k02.com www.jujutsu.k02.com;
    root /var/www/html;
    index index.php index.html;

    # ── ACL: Batasi Akses Langsung (Soal 14) ──
    allow 192.212.1.4;       # Public Reverse Proxy (gojo)
    allow 192.212.4.0/24;     # Subnet internal Data Center (untuk pengujian internal)
    allow 127.0.0.1;         # Localhost
    deny all;                # TOLAK seluruh akses langsung dari klien Network 2 & 3

    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:$PHP_SOCK;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }
}
EOF
        ;;

    # ── API Workers (nanami, todo, kirara) ────────────────────────────────────
    *nanami*|*todo*|*kirara*)
        echo "[*] Mengonfigurasi API Worker ($WORKER_LOWER)..."
        mkdir -p /var/www/api

        # Endpoint API mencatat log ke database Yaga dan merespons JSON
        cat << 'EOF' > /var/www/api/index.php
<?php
header('Content-Type: application/json');

$hostname = gethostname();
// Mendapatkan IP asli klien yang diteruskan oleh proxy gojo & geto (Soal 17)
$client_ip = $_SERVER['HTTP_X_REAL_IP'] ?? $_SERVER['HTTP_X_FORWARDED_FOR'] ?? $_SERVER['REMOTE_ADDR'];

// Konfigurasi Database Master Yaga (Network 4: 192.212.4.8)
$db_host = '192.212.4.8';
$db_user = 'shibuya_user';
$db_pass = 'shibuya_pass';
$db_name = 'db_shibuya_k02';

$db_status = "unrecorded";

try {
    $dsn = "mysql:host=$db_host;dbname=$db_name;charset=utf8mb4";
    $pdo = new PDO($dsn, $db_user, $db_pass, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_SILENT,
        PDO::ATTR_TIMEOUT => 2
    ]);
    
    $stmt = $pdo->prepare("INSERT INTO request_logs (worker_name, client_ip, request_uri, created_at) VALUES (?, ?, ?, NOW())");
    if ($stmt && $stmt->execute([$hostname, $client_ip, $_SERVER['REQUEST_URI'] ?? '/api'])) {
        $db_status = "saved_to_yaga";
    }
} catch (Exception $e) {
    $db_status = "db_offline_or_uninitialized";
}

echo json_encode([
    'status'    => 'success',
    'message'   => 'Curtain Protocol API Service',
    'worker'    => $hostname,
    'client_ip' => $client_ip,
    'db_log'    => $db_status,
    'timestamp' => date('Y-m-d H:i:s')
], JSON_PRETTY_PRINT) . "\n";
?>
EOF

        # Virtual host Nginx API dengan ACL Pembatasan Akses
        # - Hanya menerima trafik dari geto (192.212.4.2)
        # - Menolak akses langsung dari klien
        cat << EOF > /etc/nginx/sites-available/default
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    server_name jujutsu.k02.com www.jujutsu.k02.com;
    root /var/www/api;
    index index.php index.html;

    # ── ACL: Batasi Akses Langsung (Soal 14) ──
    allow 192.212.4.2;       # Internal Load Balancer (geto)
    allow 192.212.4.0/24;     # Subnet internal Data Center (untuk pengujian internal)
    allow 127.0.0.1;         # Localhost
    deny all;                # TOLAK seluruh akses langsung dari klien Network 2 & 3

    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:$PHP_SOCK;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }
}
EOF
        ;;

    *)
        echo "[-] Worker $WORKER_LOWER tidak dikenali!"
        exit 1
        ;;
esac

# 4. Validasi sintaks dan restart layanan
nginx -t
service php*-fpm restart 2>/dev/null || true
service nginx restart

echo "[OK] Worker $WORKER_LOWER berhasil dikonfigurasi dan aktif!"

