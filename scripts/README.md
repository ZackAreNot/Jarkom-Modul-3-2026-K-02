# Direktori Skrip Otomasi Node (/root)

Direktori ini menampung seluruh skrip bash shell yang akan diinjeksikan ke dalam direktori `/root` pada masing-masing container GNS3:

1. **`init.sh`**: Skrip universal inisialisasi node, konfigurasi IP address statis/DHCP, default gateway, DNS resolver (`/etc/resolv.conf`), dan persistensi layanan saat boot ulang.
2. **`setup_jichi.sh`**: Konfigurasi router `jichi` (IP forwarding, iptables NAT masquerade, dan DHCP Relay).
3. **`setup_tengen.sh`**: Konfigurasi DHCP Server `isc-dhcp-server` di node `tengen` (Pool 1, Pool 2, short/long lease, static lease Kugisaki).
4. **`setup_dns.sh`**: Konfigurasi BIND9 Master (`utahime`) dan Slave (`shoko`).
5. **`setup_database.sh`**: Konfigurasi MariaDB Master (`yaga`) dan Slave (`inumaki`) beserta database `db_shibuya_k02` dan tabel `request_logs`.
6. **`setup_workers.sh`**: Konfigurasi Nginx & PHP-FPM pada worker frontend (`maki`, `panda`) dan API (`nanami`, `todo`, `kirara`).
7. **`setup_loadbalancer.sh`**: Konfigurasi Nginx Weighted Round Robin LB pada `geto` dan backup failover `kirara`.
8. **`setup_reverse_proxy.sh`**: Konfigurasi Public Reverse Proxy pada `gojo` (Path-based routing `/` dan `/api`, caching, rate limiting).

