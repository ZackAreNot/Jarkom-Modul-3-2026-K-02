#!/bin/bash
# ==============================================================================
# /root/init.sh - Universal Node Initialization & Recovery Script
# Praktikum Jarkom Modul 3 - Kelompok K-02 (Prefix: 192.212.x.x, Domain: jujutsu.k02.com)
# "Curtain Protocol: Shibuya Incident"
#
# Penggunaan:
#   bash /root/init.sh [node_name]
#   (Jika tanpa argumen, otomatis mendeteksi dari $(hostname))
# ==============================================================================

NODE_NAME="${1:-$(hostname)}"
NODE_LOWER=$(echo "$NODE_NAME" | tr '[:upper:]' '[:lower:]')

# Helper: Set DNS gateway awal
set_gateway_resolver() {
    cat << 'EOF' > /etc/resolv.conf
nameserver 192.168.122.1
EOF
}

# Helper: Set resolver DNS internal jujutsu.k02.com
set_internal_resolver() {
    cat << 'EOF' > /etc/resolv.conf
nameserver 192.212.1.2
nameserver 192.212.1.3
nameserver 192.168.122.1
search jujutsu.k02.com k02.com
EOF
}

# Pastikan hostname system-wide
echo "$NODE_LOWER" > /etc/hostname 2>/dev/null || true
hostname "$NODE_LOWER" 2>/dev/null || true

case "$NODE_LOWER" in
    # ── Central Router & DHCP Relay ──────────────────────────────────────────
    *jichi*|*router*)
        echo "=== [jichi] Mengonfigurasi Central Router & Gateway ==="
        cat << 'EOF' > /etc/network/interfaces
auto eth0
iface eth0 inet dhcp
    post-up iptables -t nat -C POSTROUTING -o eth0 -j MASQUERADE 2>/dev/null || iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
    post-up sysctl -w net.ipv4.ip_forward=1

auto eth1
iface eth1 inet static
    address 192.212.1.1
    netmask 255.255.255.0

auto eth2
iface eth2 inet static
    address 192.212.2.1
    netmask 255.255.255.0

auto eth3
iface eth3 inet static
    address 192.212.3.1
    netmask 255.255.255.0

auto eth4
iface eth4 inet static
    address 192.212.4.1
    netmask 255.255.255.0
    post-up bash /root/setup_jichi.sh >/var/log/autostart_jichi.log 2>&1 || true
EOF

        # Terapkan IP statis langsung ke kernel
        ip addr replace 192.212.1.1/24 dev eth1 2>/dev/null || true
        ip addr replace 192.212.2.1/24 dev eth2 2>/dev/null || true
        ip addr replace 192.212.3.1/24 dev eth3 2>/dev/null || true
        ip addr replace 192.212.4.1/24 dev eth4 2>/dev/null || true

        for i in 0 1 2 3 4; do
            ip link set eth$i up 2>/dev/null || true
        done

        # Request WAN DHCP via udhcpc jika eth0 belum punya IP WAN
        cat << 'EOF' > /etc/udhcpc.script
#!/bin/sh
[ "$1" = "bound" ] || [ "$1" = "renew" ] || exit 0
ip addr replace $ip/$mask dev $interface 2>/dev/null || true
[ -n "$router" ] && ip route replace default via $router dev $interface 2>/dev/null || true
[ -n "$dns" ] && echo "nameserver $dns" > /etc/resolv.conf
EOF
        chmod +x /etc/udhcpc.script
        ln -sf /tmp/gns3/bin/busybox /bin/udhcpc 2>/dev/null || true
        ln -sf /tmp/gns3/bin/busybox /sbin/udhcpc 2>/dev/null || true
        udhcpc -i eth0 -s /etc/udhcpc.script -n -q 2>/dev/null || true

        # NAT & Forwarding
        sysctl -w net.ipv4.ip_forward=1 >/dev/null 2>&1 || true
        iptables -t nat -C POSTROUTING -o eth0 -j MASQUERADE 2>/dev/null || iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE 2>/dev/null || true
        set_gateway_resolver

        # Jika skrip relay ada, aktifkan
        if [ -f /root/setup_jichi.sh ]; then
            bash /root/setup_jichi.sh || true
        fi
        echo "[OK] jichi siap!"
        ;;

    # ── Network 1: DMZ (utahime, shoko, gojo) ────────────────────────────────
    *utahime*)
        echo "=== [utahime] Mengonfigurasi DNS Master (192.212.1.2) ==="
        cat << 'EOF' > /etc/network/interfaces
auto eth0
iface eth0 inet static
    address 192.212.1.2
    netmask 255.255.255.0
    gateway 192.212.1.1
    up echo "nameserver 192.168.122.1" > /etc/resolv.conf
EOF
        ip addr replace 192.212.1.2/24 dev eth0 2>/dev/null || true
        ip route replace default via 192.212.1.1 dev eth0 2>/dev/null || true
        set_gateway_resolver

        if [ -f /root/setup_dns.sh ]; then
            bash /root/setup_dns.sh utahime || true
        fi
        echo "[OK] utahime siap!"
        ;;

    *shoko*)
        echo "=== [shoko] Mengonfigurasi DNS Slave (192.212.1.3) ==="
        cat << 'EOF' > /etc/network/interfaces
auto eth0
iface eth0 inet static
    address 192.212.1.3
    netmask 255.255.255.0
    gateway 192.212.1.1
    up echo "nameserver 192.168.122.1" > /etc/resolv.conf
EOF
        ip addr replace 192.212.1.3/24 dev eth0 2>/dev/null || true
        ip route replace default via 192.212.1.1 dev eth0 2>/dev/null || true
        set_gateway_resolver

        if [ -f /root/setup_dns.sh ]; then
            bash /root/setup_dns.sh shoko || true
        fi
        echo "[OK] shoko siap!"
        ;;

    *gojo*)
        echo "=== [gojo] Mengonfigurasi Public Reverse Proxy (192.212.1.4) ==="
        cat << 'EOF' > /etc/network/interfaces
auto eth0
iface eth0 inet static
    address 192.212.1.4
    netmask 255.255.255.0
    gateway 192.212.1.1
    up echo "nameserver 192.168.122.1" > /etc/resolv.conf
EOF
        ip addr replace 192.212.1.4/24 dev eth0 2>/dev/null || true
        ip route replace default via 192.212.1.1 dev eth0 2>/dev/null || true
        set_gateway_resolver

        if [ -f /root/setup_proxy.sh ]; then
            bash /root/setup_proxy.sh || true
        fi
        echo "[OK] gojo siap!"
        ;;

    # ── Network 4: Data Center ───────────────────────────────────────────────
    *tengen*)
        echo "=== [tengen] Mengonfigurasi DHCP Server (192.212.4.10) ==="
        cat << 'EOF' > /etc/network/interfaces
auto eth0
iface eth0 inet static
    address 192.212.4.10
    netmask 255.255.255.0
    gateway 192.212.4.1
    up echo "nameserver 192.168.122.1" > /etc/resolv.conf
    post-up bash /root/setup_tengen.sh >/var/log/autostart_tengen.log 2>&1 || true
EOF
        ip addr replace 192.212.4.10/24 dev eth0 2>/dev/null || true
        ip route replace default via 192.212.4.1 dev eth0 2>/dev/null || true
        set_gateway_resolver

        if [ -f /root/setup_tengen.sh ]; then
            bash /root/setup_tengen.sh || true
        fi
        echo "[OK] tengen siap!"
        ;;

    *geto*)
        echo "=== [geto] Mengonfigurasi Internal Load Balancer (192.212.4.2) ==="
        cat << 'EOF' > /etc/network/interfaces
auto eth0
iface eth0 inet static
    address 192.212.4.2
    netmask 255.255.255.0
    gateway 192.212.4.1
    up echo "nameserver 192.168.122.1" > /etc/resolv.conf
EOF
        ip addr replace 192.212.4.2/24 dev eth0 2>/dev/null || true
        ip route replace default via 192.212.4.1 dev eth0 2>/dev/null || true
        set_gateway_resolver

        if [ -f /root/setup_loadbalancer.sh ]; then
            bash /root/setup_loadbalancer.sh || true
        fi
        echo "[OK] geto siap!"
        ;;

    *maki*)
        echo "=== [maki] Mengonfigurasi Frontend Worker 1 (192.212.4.3) ==="
        cat << 'EOF' > /etc/network/interfaces
auto eth0
iface eth0 inet static
    address 192.212.4.3
    netmask 255.255.255.0
    gateway 192.212.4.1
    up echo "nameserver 192.168.122.1" > /etc/resolv.conf
EOF
        ip addr replace 192.212.4.3/24 dev eth0 2>/dev/null || true
        ip route replace default via 192.212.4.1 dev eth0 2>/dev/null || true
        set_gateway_resolver

        if [ -f /root/setup_workers.sh ]; then
            bash /root/setup_workers.sh maki || true
        fi
        echo "[OK] maki siap!"
        ;;

    *panda*)
        echo "=== [panda] Mengonfigurasi Frontend Worker 2 (192.212.4.4) ==="
        cat << 'EOF' > /etc/network/interfaces
auto eth0
iface eth0 inet static
    address 192.212.4.4
    netmask 255.255.255.0
    gateway 192.212.4.1
    up echo "nameserver 192.168.122.1" > /etc/resolv.conf
EOF
        ip addr replace 192.212.4.4/24 dev eth0 2>/dev/null || true
        ip route replace default via 192.212.4.1 dev eth0 2>/dev/null || true
        set_gateway_resolver

        if [ -f /root/setup_workers.sh ]; then
            bash /root/setup_workers.sh panda || true
        fi
        echo "[OK] panda siap!"
        ;;

    *nanami*)
        echo "=== [nanami] Mengonfigurasi API Worker Utama 1 (192.212.4.5) ==="
        cat << 'EOF' > /etc/network/interfaces
auto eth0
iface eth0 inet static
    address 192.212.4.5
    netmask 255.255.255.0
    gateway 192.212.4.1
    up echo "nameserver 192.168.122.1" > /etc/resolv.conf
EOF
        ip addr replace 192.212.4.5/24 dev eth0 2>/dev/null || true
        ip route replace default via 192.212.4.1 dev eth0 2>/dev/null || true
        set_gateway_resolver

        if [ -f /root/setup_workers.sh ]; then
            bash /root/setup_workers.sh nanami || true
        fi
        echo "[OK] nanami siap!"
        ;;

    *todo*)
        echo "=== [todo] Mengonfigurasi API Worker Utama 2 (192.212.4.6) ==="
        cat << 'EOF' > /etc/network/interfaces
auto eth0
iface eth0 inet static
    address 192.212.4.6
    netmask 255.255.255.0
    gateway 192.212.4.1
    up echo "nameserver 192.168.122.1" > /etc/resolv.conf
EOF
        ip addr replace 192.212.4.6/24 dev eth0 2>/dev/null || true
        ip route replace default via 192.212.4.1 dev eth0 2>/dev/null || true
        set_gateway_resolver

        if [ -f /root/setup_workers.sh ]; then
            bash /root/setup_workers.sh todo || true
        fi
        echo "[OK] todo siap!"
        ;;

    *kirara*)
        echo "=== [kirara] Mengonfigurasi API Worker Backup (192.212.4.7) ==="
        cat << 'EOF' > /etc/network/interfaces
auto eth0
iface eth0 inet static
    address 192.212.4.7
    netmask 255.255.255.0
    gateway 192.212.4.1
    up echo "nameserver 192.168.122.1" > /etc/resolv.conf
EOF
        ip addr replace 192.212.4.7/24 dev eth0 2>/dev/null || true
        ip route replace default via 192.212.4.1 dev eth0 2>/dev/null || true
        set_gateway_resolver

        if [ -f /root/setup_workers.sh ]; then
            bash /root/setup_workers.sh kirara || true
        fi
        echo "[OK] kirara siap!"
        ;;

    *yaga*)
        echo "=== [yaga] Mengonfigurasi MariaDB Master (192.212.4.8) ==="
        cat << 'EOF' > /etc/network/interfaces
auto eth0
iface eth0 inet static
    address 192.212.4.8
    netmask 255.255.255.0
    gateway 192.212.4.1
    up echo "nameserver 192.168.122.1" > /etc/resolv.conf
EOF
        ip addr replace 192.212.4.8/24 dev eth0 2>/dev/null || true
        ip route replace default via 192.212.4.1 dev eth0 2>/dev/null || true
        set_gateway_resolver

        if [ -f /root/setup_database.sh ]; then
            bash /root/setup_database.sh master || true
        fi
        echo "[OK] yaga siap!"
        ;;

    *inumaki*)
        echo "=== [inumaki] Mengonfigurasi MariaDB Slave (192.212.4.9) ==="
        cat << 'EOF' > /etc/network/interfaces
auto eth0
iface eth0 inet static
    address 192.212.4.9
    netmask 255.255.255.0
    gateway 192.212.4.1
    up echo "nameserver 192.168.122.1" > /etc/resolv.conf
EOF
        ip addr replace 192.212.4.9/24 dev eth0 2>/dev/null || true
        ip route replace default via 192.212.4.1 dev eth0 2>/dev/null || true
        set_gateway_resolver

        if [ -f /root/setup_database.sh ]; then
            bash /root/setup_database.sh slave || true
        fi
        echo "[OK] inumaki siap!"
        ;;

    # ── Client Nodes (Network 2 & 3 - Alpinet) ────────────────────────────────
    *itadori*|*fushiguro*|*zenin*|*okkotsu*|*ino*|*kusakabe*|*kugisaki*|*miwa*)
        echo "=== [$NODE_LOWER] Mengonfigurasi DHCP Client ==="
        case "$NODE_LOWER" in
            *itadori*)   CLIENT_MAC="02:42:01:94:12:00" ;;
            *fushiguro*) CLIENT_MAC="02:42:2d:a4:7c:00" ;;
            *zenin*)     CLIENT_MAC="02:42:03:14:51:00" ;;
            *okkotsu*)   CLIENT_MAC="02:42:27:c7:c1:00" ;;
            *ino*)       CLIENT_MAC="02:42:c1:1e:00:00" ;;
            *kusakabe*)  CLIENT_MAC="02:42:23:9f:ee:00" ;;
            *kugisaki*)  CLIENT_MAC="02:42:88:94:88:00" ;;
            *miwa*)      CLIENT_MAC="02:42:1f:2a:46:00" ;;
        esac
        cat << EOF > /etc/network/interfaces
auto eth0
iface eth0 inet dhcp
    pre-up ip link set dev eth0 address $CLIENT_MAC
    udhcpc_opts -O broadcast -O search
    post-up udhcpc -i eth0 -O broadcast -O search -n -q >/dev/null 2>&1 || true
EOF
        ip link set dev eth0 address "$CLIENT_MAC" 2>/dev/null || true
        ip link set eth0 up 2>/dev/null || true
        # Request lease lengkap dengan opsi broadcast & domain-search
        udhcpc -i eth0 -O broadcast -O search -n -q 2>/dev/null || true
        echo "[OK] $NODE_LOWER siap!"
        ;;

    *)
        echo "[-] Node tidak dikenali: $NODE_LOWER"
        ;;
esac

