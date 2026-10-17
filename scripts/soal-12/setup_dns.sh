#!/bin/bash
# ==============================================================================
# setup_dns.sh — Konfigurasi BIND9 DNS Server (Master & Slave)
# Modul 3: Soal 11 & Soal 12
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

# 2. Konfigurasi DNS Forwarder ke gateway internet (192.168.122.1)
cat << 'EOF' > /etc/bind/named.conf.options
options {
    directory "/var/cache/bind";

    // Forwarder menuju IP Gateway Internet (Soal 12)
    forwarders {
        192.168.122.1;
    };

    allow-query { any; };
    auth-nxdomain no;    # conform to RFC1035
    listen-on-v6 { any; };
    dnssec-validation no;
};
EOF

case "$ROLE_LOWER" in
    *utahime*)
        echo "=== [utahime] Konfigurasi BIND9 DNS Master (192.212.1.2) ==="
        mkdir -p /etc/bind/zones

        # Konfigurasi named.conf.local (Forward & Reverse Zone)
        cat << 'EOF' > /etc/bind/named.conf.local
// Zona Forward jujutsu.k02.com
zone "jujutsu.k02.com" {
    type master;
    file "/etc/bind/zones/db.jujutsu.k02.com";
    allow-transfer { 192.212.1.3; };
    also-notify { 192.212.1.3; };
    notify yes;
};

// Zona Reverse PTR untuk subnet 192.212.1.0/24 (Soal 12)
zone "1.212.192.in-addr.arpa" {
    type master;
    file "/etc/bind/zones/db.192.212.1";
    allow-transfer { 192.212.1.3; };
    also-notify { 192.212.1.3; };
    notify yes;
};
EOF

        # File database zona forward db.jujutsu.k02.com
        cat << 'EOF' > /etc/bind/zones/db.jujutsu.k02.com
$TTL    604800
@       IN      SOA     utahime.jujutsu.k02.com. root.jujutsu.k02.com. (
                        2026101402      ; Serial
                        28800           ; Refresh (8 jam)
                        7200            ; Retry (2 jam)
                        2419200         ; Expire (4 minggu)
                        86400 )         ; Negative Cache TTL (1 hari)

; Name Server Delegasi (Soal 11)
@       IN      NS      utahime.jujutsu.k02.com.
@       IN      NS      shoko.jujutsu.k02.com.

; A Records Name Server
utahime IN      A       192.212.1.2
shoko   IN      A       192.212.1.3

; Apex A Record & gojo (Soal 12)
@       IN      A       192.212.1.4
gojo    IN      A       192.212.1.4

; CNAME www merujuk ke domain utama (Soal 12)
www     IN      CNAME   jujutsu.k02.com.
EOF

        # File database zona reverse PTR db.192.212.1
        cat << 'EOF' > /etc/bind/zones/db.192.212.1
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

; PTR Record melacak 192.212.1.4 kembali ke jujutsu.k02.com (Soal 12)
4       IN      PTR     jujutsu.k02.com.
EOF

        # Validasi sintaks konfigurasi dan file zona
        named-checkconf /etc/bind/named.conf
        named-checkzone jujutsu.k02.com /etc/bind/zones/db.jujutsu.k02.com
        named-checkzone 1.212.192.in-addr.arpa /etc/bind/zones/db.192.212.1

        # Restart service
        service named restart || service bind9 restart || /etc/init.d/named restart
        echo "[OK] DNS Master utahime siap!"
        ;;

    *shoko*)
        echo "=== [shoko] Konfigurasi BIND9 DNS Slave (192.212.1.3) ==="
        mkdir -p /var/cache/bind
        chown -R bind:bind /var/cache/bind 2>/dev/null || true

        # Konfigurasi named.conf.local (Forward & Reverse Slave Zones)
        cat << 'EOF' > /etc/bind/named.conf.local
zone "jujutsu.k02.com" {
    type slave;
    file "/var/cache/bind/db.jujutsu.k02.com";
    masters { 192.212.1.2; };
};

zone "1.212.192.in-addr.arpa" {
    type slave;
    file "/var/cache/bind/db.192.212.1";
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
