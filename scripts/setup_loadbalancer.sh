#!/bin/bash
# ==============================================================================
# setup_loadbalancer.sh — Konfigurasi Internal Load Balancer pada Node Geto
# Modul 3: Soal 15 (dan integrasi Soal 17 & 18)
# Kelompok K-02 (Prefix: 192.212.x.x)
# ==============================================================================

echo "=== [geto] Memulai Konfigurasi Internal Load Balancer ==="

# 1. Pastikan nameserver internet aktif
echo "nameserver 192.168.122.1" > /etc/resolv.conf

# 2. Instalasi Nginx dan Curl jika belum ada
if ! command -v nginx &>/dev/null; then
    echo "[*] Menginstal Nginx..."
    apt-get update -y
    apt-get install -y nginx curl
fi

# 3. Konfigurasi Upstream Weighted Round Robin (Soal 15)
# Nanami (bobot 3) : Todo (bobot 1)
cat << 'EOF' > /etc/nginx/sites-available/default
upstream api_cluster {
    # Weighted Round Robin (3:1)
    server 192.212.4.5:80 weight=3;   # nanami (worker API utama 1)
    server 192.212.4.6:80 weight=1;   # todo (worker API utama 2)
}

server {
    listen 80 default_server;
    listen [::]:80 default_server;

    server_name jujutsu.k02.com www.jujutsu.k02.com _;

    location / {
        proxy_pass http://api_cluster;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_connect_timeout 2s;
        proxy_read_timeout 3s;
    }
}
EOF

# 4. Validasi sintaks dan restart layanan
nginx -t
service nginx restart

echo "[OK] Internal Load Balancer geto aktif dengan Weighted Round Robin 3:1!"

