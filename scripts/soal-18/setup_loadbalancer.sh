#!/bin/bash
# ==============================================================================
# setup_loadbalancer.sh — Konfigurasi Internal Load Balancer pada Node Geto
# Modul 3: Soal 15, Soal 17 & Soal 18
# Kelompok K-02 (Prefix: 192.212.x.x)
# ==============================================================================

echo "=== [geto] Memulai Konfigurasi Internal Load Balancer, Real IP & HA Failover ==="

# 1. Pastikan nameserver internet aktif
echo "nameserver 192.168.122.1" > /etc/resolv.conf

# 2. Instalasi Nginx dan Curl jika belum ada
if ! command -v nginx &>/dev/null; then
    echo "[*] Menginstal Nginx dan Curl..."
    apt-get update -y
    apt-get install -y nginx curl
fi

# 3. Konfigurasi Upstream Weighted Round Robin (Soal 15) & Health Check + Backup (Soal 18)
cat << 'EOF' > /etc/nginx/sites-available/default
upstream api_cluster {
    # Worker API utama dengan Weighted Round Robin (3:1) dan Passive Health Check (Soal 15 & 18)
    server 192.212.4.5:80 weight=3 max_fails=2 fail_timeout=5s;   # nanami
    server 192.212.4.6:80 weight=1 max_fails=2 fail_timeout=5s;   # todo

    # Worker API cadangan (backup) (Soal 18)
    server 192.212.4.7:80 backup;                                  # kirara
}

server {
    listen 80 default_server;
    listen [::]:80 default_server;

    server_name jujutsu.k02.com www.jujutsu.k02.com _;

    # ── Soal 17: Memverifikasi IP Asli hanya dari Proxy Terpercaya (gojo: 192.212.1.4) ──
    set_real_ip_from 192.212.1.4;
    set_real_ip_from 192.212.1.0/24;
    real_ip_header X-Forwarded-For;
    real_ip_recursive on;

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

echo "[OK] Internal Load Balancer geto aktif dengan Weighted Round Robin 3:1, Real IP, dan HA Backup!"


