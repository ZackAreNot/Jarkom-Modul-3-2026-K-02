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

# Network 4: Data Center (Subnet lokal tengen tanpa pool dinamis)
# Mencegah error "No subnet declaration for eth0"
subnet 192.212.4.0 netmask 255.255.255.0 {
}

# Network 2: Divisi A Scope
subnet 192.212.2.0 netmask 255.255.255.0 {
    option routers 192.212.2.1;
    option subnet-mask 255.255.255.0;
    option broadcast-address 192.212.2.255;
}

# Network 3: Divisi B Scope
subnet 192.212.3.0 netmask 255.255.255.0 {
    option routers 192.212.3.1;
    option subnet-mask 255.255.255.0;
    option broadcast-address 192.212.3.255;
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
