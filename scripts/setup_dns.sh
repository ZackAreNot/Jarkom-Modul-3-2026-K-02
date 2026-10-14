#!/bin/bash
# ==============================================================================
# setup_dns.sh — Konfigurasi BIND9 DNS Server (Master & Slave)
# Modul 3: Soal 11
# Kelompok K-02 (Domain: jujutsu.k02.com, Prefix: 192.212.x.x)
# ==============================================================================

ROLE="${1:-$(hostname)}"
ROLE_LOWER=$(echo "$ROLE" | tr '[:upper:]' '[:lower:]')

echo "nameserver 192.168.122.1" > /etc/resolv.conf

# 1. Pastikan BIND9 dan dnsutils terpasang
if ! command -v named &>/dev/null; then
    echo "[*] Menginstal paket bind9 dan bind9-dnsutils..."
    apt-get update -y
    apt-get install -y bind9 bind9-dnsutils bind9-utils
fi

case "$ROLE_LOWER" in
    *utahime*)
        echo "=== [utahime] Konfigurasi BIND9 DNS Master (192.212.1.2) ==="
        mkdir -p /etc/bind/zones

        # Konfigurasi named.conf.local
        cat << 'EOF' > /etc/bind/named.conf.local
zone "jujutsu.k02.com" {
    type master;
    file "/etc/bind/zones/db.jujutsu.k02.com";
    allow-transfer { 192.212.1.3; };
    also-notify { 192.212.1.3; };
    notify yes;
};
EOF

        # File database zona forward jujutsu.k02.com
        cat << 'EOF' > /etc/bind/zones/db.jujutsu.k02.com
$TTL    604800
@       IN      SOA     utahime.jujutsu.k02.com. root.jujutsu.k02.com. (
                        2026101401      ; Serial
                        28800           ; Refresh (8 jam)
                        7200            ; Retry (2 jam)
                        2419200         ; Expire (4 minggu)
                        86400 )         ; Negative Cache TTL (1 hari)

; Name Server Delegasi
@       IN      NS      utahime.jujutsu.k02.com.
@       IN      NS      shoko.jujutsu.k02.com.

; A Records untuk Name Servers
utahime IN      A       192.212.1.2
shoko   IN      A       192.212.1.3

; Apex A Record (menuju gojo)
@       IN      A       192.212.1.4
EOF

        # Validasi sintaks
        named-checkconf /etc/bind/named.conf
        named-checkzone jujutsu.k02.com /etc/bind/zones/db.jujutsu.k02.com

        # Restart service
        service named restart || service bind9 restart || /etc/init.d/named restart
        echo "[OK] DNS Master utahime siap!"
        ;;

    *shoko*)
        echo "=== [shoko] Konfigurasi BIND9 DNS Slave (192.212.1.3) ==="
        mkdir -p /var/cache/bind
        chown -R bind:bind /var/cache/bind 2>/dev/null || true

        # Konfigurasi named.conf.local
        cat << 'EOF' > /etc/bind/named.conf.local
zone "jujutsu.k02.com" {
    type slave;
    file "/var/cache/bind/db.jujutsu.k02.com";
    masters { 192.212.1.2; };
};
EOF

        # Validasi sintaks
        named-checkconf /etc/bind/named.conf

        # Restart service
        service named restart || service bind9 restart || /etc/init.d/named restart
        echo "[OK] DNS Slave shoko siap!"
        ;;

    *)
        echo "[-] Hostname tidak dikenali untuk DNS: $ROLE_LOWER"
        ;;
esac

