#!/bin/bash
# ==============================================================================
# setup_jichi.sh — Konfigurasi DHCP Relay pada Router Jichi
# Modul 3: Soal 3
# Kelompok K-02 (Prefix: 192.212.x.x)
# ==============================================================================

echo "=== [jichi] Memulai Konfigurasi DHCP Relay ==="

# 1. Pastikan IP forwarding dan nameserver aktif
sysctl -w net.ipv4.ip_forward=1 >/dev/null 2>&1 || true
echo "nameserver 192.168.122.1" > /etc/resolv.conf

# 2. Instalasi isc-dhcp-relay jika belum terpasang
if ! command -v dhcrelay &>/dev/null; then
    echo "[*] Menginstal paket isc-dhcp-relay..."
    DEBIAN_FRONTEND=noninteractive apt-get update -y
    DEBIAN_FRONTEND=noninteractive apt-get install -y isc-dhcp-relay
fi

# 3. Konfigurasi /etc/default/isc-dhcp-relay
# eth2: Network 2 (Divisi A)
# eth3: Network 3 (Divisi B)
# eth4: Network 4 (Data Center menuju tengen 192.212.4.10)
echo '[*] Mengonfigurasi /etc/default/isc-dhcp-relay...'
cat << 'EOF' > /etc/default/isc-dhcp-relay
SERVERS="192.212.4.10"
INTERFACES="eth2 eth3 eth4"
OPTIONS=""
EOF

# 4. Aktifkan autostart service isc-dhcp-relay (Soal 10)
update-rc.d isc-dhcp-relay defaults >/dev/null 2>&1 || true
update-rc.d isc-dhcp-relay enable >/dev/null 2>&1 || true
if ! grep -q "setup_jichi.sh" /root/.bashrc 2>/dev/null; then
    cat << 'EOF' >> /root/.bashrc
# Autostart ISC DHCP Relay (Soal 10)
if ! pgrep dhcrelay >/dev/null 2>&1; then
    bash /root/setup_jichi.sh >/dev/null 2>&1 &
fi
EOF
fi

# 5. Restart service isc-dhcp-relay
echo '[*] Memulai ulang layanan isc-dhcp-relay...'
pkill -9 dhcrelay 2>/dev/null || true
sleep 1
service isc-dhcp-relay restart || /etc/init.d/isc-dhcp-relay restart || true

# Fallback jika service init script terkendala
sleep 1
if ! pgrep dhcrelay >/dev/null; then
    echo "[*] Menjalankan dhcrelay daemon langsung..."
    dhcrelay -4 -i eth2 -i eth3 -i eth4 192.212.4.10 || true
fi

if pgrep dhcrelay >/dev/null; then
    echo "[OK] isc-dhcp-relay berjalan aktif di router jichi! PID: $(pgrep dhcrelay)"
else
    echo "[-] Gagal menjalankan isc-dhcp-relay!"
fi


