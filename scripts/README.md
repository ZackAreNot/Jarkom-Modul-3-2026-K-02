# Direktori Skrip Otomasi Node (/root)

Direktori ini menampung seluruh skrip bash shell otomasi yang dikelompokkan ke dalam direktori masing-masing nomor soal (`soal-1` hingga `soal-20`). Skrip-skrip ini diinjeksikan ke dalam direktori `/root` pada masing-masing container GNS3 sesuai dengan peran dan kebutuhan layanannya.

## Pemetaan Skrip Berdasarkan Nomor Soal

| Folder | Skrip Shell | Node Target | Deskripsi dan Fungsi Layanan |
| :--- | :--- | :--- | :--- |
| **`soal-1/`** | `init.sh` | Seluruh Node & `jichi` | Inisialisasi universal: penamaan hostname, alokasi IP statis/DHCP, konfigurasi gateway, nameserver awal, dan routing NAT Masquerade pada router `jichi`. |
| **`soal-2/`** | `setup_tengen.sh` | `tengen` | Konfigurasi DHCP Server `isc-dhcp-server`: deklarasi subnet lokal Network 4 tanpa pool dinamis, serta pendefinisian subnet scope Network 2 dan Network 3. |
| **`soal-3/`** | `setup_jichi.sh` | `jichi` | Konfigurasi DHCP Relay `isc-dhcp-relay` pada router `jichi` meneruskan permintaan DHCP dari `eth2` dan `eth3` menuju server `tengen` (`192.212.4.10`) melalui `eth4`. |
| **`soal-4/`** | `setup_tengen.sh` | `tengen` | Pembagian alokasi pool Network 2 (Divisi A) berbasis DHCP Class MAC Address: `pool-dev` (`.2.10`–`.2.35`) untuk Itadori & Fushiguro, serta `pool-support` (`.2.70`–`.2.95`) untuk Zenin & Okkotsu. |
| **`soal-5/`** | `setup_tengen.sh` | `tengen` | Pengaturan masa sewa DHCP pada Network 3 (Divisi B): Short Lease 30 menit (`.3.10`–`.3.89`) untuk Ino & Kusakabe, Long Lease 12 jam (`.3.100`–`.3.199`) untuk Miwa, beserta opsi DNS resolver dan domain search `k02.com`. |
| **`soal-6/`** | `setup_tengen.sh` | `tengen` | Konfigurasi DHCP Static Lease (reservasi IP tetap VIP) untuk personel `kugisaki` pada alamat `192.212.3.99` berbasis MAC Address di luar pool dinamis. |
| **`soal-7/`** | `setup_tengen.sh` | `tengen` | Validasi parameter jaringan seluruh client (subnet mask `/24`, default gateway, broadcast, DNS resolver) dan verifikasi pencatatan database sewa pada `/var/lib/dhcp/dhcpd.leases`. |
| **`soal-8/`** | `setup_tengen.sh` | `tengen` | Konfigurasi DHCP Server yang melayani proses DORA (DHCPDISCOVER, DHCPOFFER, DHCPREQUEST, DHCPACK) dan validasi field `giaddr` melalui packet capture `tcpdump`. |
| **`soal-9/`** | `setup_jichi.sh` | `jichi` | Pengelolaan dan simulasi penanganan gangguan layanan DHCP Relay pada router `jichi` (penghentian sementara dan pemulihan layanan). |
| **`soal-10/`** | `setup_tengen.sh`<br>`setup_jichi.sh` | `tengen`<br>`jichi` | Konfigurasi persistensi autostart sistem: registrasi layanan ke init runlevels (`update-rc.d`) dan injeksi ke `/root/.bashrc` agar DHCP Server dan DHCP Relay otomatis aktif setelah reboot. |
| **`soal-11/`** | `setup_dns.sh` | `utahime`, `shoko` | Konfigurasi BIND9 DNS Master (`utahime`) dan DNS Slave (`shoko`) untuk zona `jujutsu.k02.com` dengan otorisasi zone transfer (`allow-transfer` dan `also-notify`). |
| **`soal-12/`** | `setup_dns.sh` | `utahime`, `shoko` | Konfigurasi DNS A record, alias CNAME `www`, Zona Reverse PTR (`1.212.192.in-addr.arpa`), serta DNS Forwarder menuju IP Gateway Internet WAN (`192.168.122.1`). |
| **`soal-13/`** | `setup_database.sh` | `yaga`, `inumaki` | Konfigurasi MariaDB Master-Slave realtime replication: binary logging (`log-bin`, `server-id`), sinkronisasi `CHANGE MASTER TO`, pembuatan database `db_shibuya_k02`, tabel `request_logs`, dan hak akses remote. |
| **`soal-14/`** | `setup_workers.sh` | `maki`, `panda`, `nanami`, `todo`, `kirara` | Konfigurasi Web Frontend (`maki`, `panda`) dan API Workers (`nanami`, `todo`, `kirara`) menggunakan Nginx + PHP-FPM, virtual host, serta ACL penolakan akses langsung dari client. |
| **`soal-15/`** | `setup_loadbalancer.sh` | `geto` | Konfigurasi Internal Load Balancer Nginx pada `geto` dengan upstream `api_cluster` menggunakan algoritma Weighted Round Robin (bobot 3:1 antara `nanami` dan `todo`). |
| **`soal-16/`** | `setup_proxy.sh` | `gojo` | Konfigurasi Public Reverse Proxy Nginx pada `gojo` (DMZ) dengan Path-Based Routing: request root (`/`) diteruskan ke Frontend Workers, sedangkan request `/api` diteruskan ke Internal LB `geto`. |
| **`soal-17/`** | `setup_loadbalancer.sh`<br>`setup_workers.sh` | `geto`<br>API Workers | Konfigurasi penerusan IP asli client (`X-Real-IP`, `X-Forwarded-For`), verifikasi proxy terpercaya (`set_real_ip_from`), dan pencatatan riwayat request ke database `yaga`. |
| **`soal-18/`** | `setup_loadbalancer.sh` | `geto` | Konfigurasi Passive Health Check (`max_fails=2`, `fail_timeout=5s`) pada worker API utama dan penyiapan `kirara` sebagai server backup failover otomatis. |
| **`soal-19/`** | `setup_proxy.sh` | `gojo` | Konfigurasi Nginx Proxy Caching (masa berlaku cache 10 menit, header respons `X-Cache-Status`) dan proteksi Rate Limiting (10 request/detik per client IP) pada `gojo`. |
| **`soal-20/`** | `setup_proxy.sh` | `gojo` | Konfigurasi Public Reverse Proxy & Rate Limiter yang diaudit menggunakan Apache Benchmark (`ab -n 600 -c 30`) dari `kusakabe` untuk evaluasi kapasitas dan ketahanan beban tinggi. |
