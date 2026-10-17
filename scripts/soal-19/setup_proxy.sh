#!/bin/bash
# ==============================================================================
# setup_proxy.sh — Konfigurasi Public Reverse Proxy pada Node Gojo (DMZ)
# Modul 3: Soal 16 & Soal 19
# Kelompok K-02 (Prefix: 192.212.x.x)
# ==============================================================================

echo "=== [gojo] Memulai Konfigurasi Public Reverse Proxy, Caching & Rate Limiting ==="

# 1. Pastikan nameserver internet aktif
echo "nameserver 192.168.122.1" > /etc/resolv.conf

# 2. Instalasi Nginx dan Curl
if ! command -v nginx &>/dev/null; then
    echo "[*] Menginstal Nginx dan Curl..."
    apt-get update -y
    apt-get install -y nginx curl
fi

# 3. Buat direktori proxy cache jika belum ada
mkdir -p /var/cache/nginx
chown -R www-data:www-data /var/cache/nginx

# 4. Konfigurasi Zone Caching & Rate Limiting (Soal 19)
cat << 'EOF' > /etc/nginx/conf.d/proxy_optimize.conf
# Proxy Cache Zone: 10m keys zone, max 100m, inactive 60m
proxy_cache_path /var/cache/nginx levels=1:2 keys_zone=web_cache:10m max_size=100m inactive=60m use_temp_path=off;

# Rate Limiting Zone: 10 requests/second per client IP (Soal 19)
limit_req_zone $binary_remote_addr zone=api_limit:10m rate=10r/s;
EOF

# 5. Konfigurasi Reverse Proxy & Routing pada Nginx (Soal 16 & Soal 19)
cat << 'EOF' > /etc/nginx/sites-available/default
upstream frontend_cluster {
    # Round Robin default ke worker frontend
    server 192.212.4.3:80;   # maki
    server 192.212.4.4:80;   # panda
}

server {
    listen 80 default_server;
    listen [::]:80 default_server;

    server_name jujutsu.k02.com www.jujutsu.k02.com _;

    # ── Path-Based Routing (Soal 16) & Proxy Caching 10 Menit (Soal 19) ──
    # Request root (/) diteruskan ke frontend cluster dengan caching 10 menit
    location / {
        proxy_pass http://frontend_cluster;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_connect_timeout 2s;
        proxy_read_timeout 3s;

        # Proxy Caching (Masa berlaku 10 menit, header X-Cache-Status)
        proxy_cache web_cache;
        proxy_cache_valid 200 10m;
        add_header X-Cache-Status $upstream_cache_status;
    }

    # ── Path-Based Routing (Soal 16) & Rate Limiting 10 req/s (Soal 19) ──
    # Request path /api dibatasi 10 request/detik per IP klien
    location /api {
        limit_req zone=api_limit burst=5 nodelay;

        proxy_pass http://192.212.4.2;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_connect_timeout 2s;
        proxy_read_timeout 3s;
    }
}
EOF

# 6. Validasi sintaks dan restart layanan
nginx -t
service nginx restart

echo "[OK] Public Reverse Proxy gojo aktif dengan Caching dan Rate Limiting!"


