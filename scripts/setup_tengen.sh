#!/bin/bash
# ==============================================================================
# setup_tengen.sh — Konfigurasi ISC DHCP Server pada Node Tengen
# Modul 3: Soal 2
# Kelompok K-02 (Prefix: 192.212.x.x)
# ==============================================================================

echo "=== [tengen] Memulai Konfigurasi ISC DHCP Server ==="

# 1. Pastikan nameserver internet aktif
echo "nameserver 192.168.122.1" > /etc/resolv.conf

# 2. Instalasi isc-dhcp-server jika belum terpasang
if ! command -v dhcpd &>/dev/null; then
    echo "[*] Menginstal paket isc-dhcp-server..."
    apt-get update -y
    apt-get install -y isc-dhcp-server
fi

# 3. Konfigurasi interface /etc/default/isc-dhcp-server
echo '[*] Mengonfigurasi /etc/default/isc-dhcp-server...'
cat << 'EOF' > /etc/default/isc-dhcp-server
INTERFACESv4="eth0"
INTERFACESv6=""
EOF

# 4. Konfigurasi /etc/dhcp/dhcpd.conf
echo '[*] Menyusun /etc/dhcp/dhcpd.conf...'
cat << 'EOF' > /etc/dhcp/dhcpd.conf
# /etc/dhcp/dhcpd.conf - Konfigurasi DHCP Server Tengen (K-02)
default-lease-time 600;
max-lease-time 7200;
authoritative;

# Global DHCP Options (DNS & Domain Search)
option domain-name-servers 192.212.1.2, 192.212.1.3;
option domain-search "k02.com";
option domain-name "k02.com";

# DHCP Classes untuk Divisi A (Network 2)
class "pool-dev" {
    match pick-first-value (option dhcp-client-identifier, hardware);
}
subclass "pool-dev" 1:02:42:01:94:12:00;  # itadori
subclass "pool-dev" 1:02:42:2d:a4:7c:00;  # fushiguro

class "pool-support" {
    match pick-first-value (option dhcp-client-identifier, hardware);
}
subclass "pool-support" 1:02:42:03:14:51:00;  # zenin
subclass "pool-support" 1:02:42:27:c7:c1:00;  # okkotsu
subclass "pool-support" 1:f2:dd:ec:51:c9:cb;  # okkotsu (alt)

# DHCP Classes untuk Divisi B (Network 3)
class "pool-short" {
    match pick-first-value (option dhcp-client-identifier, hardware);
}
subclass "pool-short" 1:02:42:c1:1e:00:00;  # ino
subclass "pool-short" 1:02:42:23:9f:ee:00;  # kusakabe
subclass "pool-short" 1:02:42:03:14:53:00;  # kusakabe (alt)

class "pool-long" {
    match pick-first-value (option dhcp-client-identifier, hardware);
}
subclass "pool-long" 1:02:42:1f:2a:46:00;  # miwa

# Network 4: Data Center (Subnet lokal tengen tanpa pool dinamis)
subnet 192.212.4.0 netmask 255.255.255.0 {
}

# Network 2: Divisi A Scope (Dua Pool Terpisah)
subnet 192.212.2.0 netmask 255.255.255.0 {
    option routers 192.212.2.1;
    option subnet-mask 255.255.255.0;
    option broadcast-address 192.212.2.255;
    option domain-name-servers 192.212.1.2, 192.212.1.3;
    option domain-search "k02.com";
    option domain-name "k02.com";

    # Pool 1: Tim Dev (itadori, fushiguro)
    pool {
        allow members of "pool-dev";
        deny members of "pool-support";
        range 192.212.2.10 192.212.2.35;
    }

    # Pool 2: Tim Support (zenin, okkotsu)
    pool {
        allow members of "pool-support";
        deny members of "pool-dev";
        range 192.212.2.70 192.212.2.95;
    }
}

# Network 3: Divisi B Scope (Short Lease & Long Lease)
subnet 192.212.3.0 netmask 255.255.255.0 {
    option routers 192.212.3.1;
    option subnet-mask 255.255.255.0;
    option broadcast-address 192.212.3.255;
    option domain-name-servers 192.212.1.2, 192.212.1.3;
    option domain-search "k02.com";
    option domain-name "k02.com";

    # Short lease pool: 30 menit (1800 detik) untuk ino dan kusakabe
    pool {
        allow members of "pool-short";
        deny members of "pool-long";
        default-lease-time 1800;
        max-lease-time 1800;
        range 192.212.3.10 192.212.3.89;
    }

    # Long lease pool: 12 jam (43200 detik) untuk miwa
    pool {
        allow members of "pool-long";
        deny members of "pool-short";
        default-lease-time 43200;
        max-lease-time 43200;
        range 192.212.3.100 192.212.3.199;
    }
}

# Soal 6: Reservasi Fixed Address VIP Kugisaki
# Berada di luar seluruh pool dinamis (192.212.3.10-89 & 192.212.3.100-199)
host kugisaki {
    hardware ethernet 02:42:88:94:88:00;
    fixed-address 192.212.3.99;
    option routers 192.212.3.1;
    option subnet-mask 255.255.255.0;
    option broadcast-address 192.212.3.255;
    option domain-name-servers 192.212.1.2, 192.212.1.3;
    option domain-search "k02.com";
}
EOF

# 5. Pastikan direktori dan berkas lease tersedia
mkdir -p /var/lib/dhcp
touch /var/lib/dhcp/dhcpd.leases

# 6. Validasi sintaks konfigurasi
echo '[*] Menjalankan validasi sintaks dhcpd...'
dhcpd -t -cf /etc/dhcp/dhcpd.conf

# 7. Restart service isc-dhcp-server
echo '[*] Memulai ulang layanan isc-dhcp-server...'
service isc-dhcp-server restart || /etc/init.d/isc-dhcp-server restart || true

# 8. Verifikasi status proses
sleep 1
if pgrep dhcpd >/dev/null; then
    echo "[OK] isc-dhcp-server berjalan aktif di node tengen! PID: $(pgrep dhcpd)"
else
    echo "[-] isc-dhcp-server gagal berjalan. Menjalankan fallback daemon langsung..."
    dhcpd -user dhcpd -group dhcpd -4 -cf /etc/dhcp/dhcpd.conf eth0 || true
fi

