# Panduan Demonstrasi & Verifikasi Praktikum Modul 3
**Kelompok**: K-02  
**IP Prefix**: `192.212.x.x`  
**Domain**: `jujutsu.k02.com`  
**Topologi**: Curtain Protocol: Shibuya Incident (17 Node, 4 Subnet LAN + 1 WAN NAT)

---

## 1. Pemetaan Entitas & Subnet Jaringan

| Entitas | Subnet / IP | Peran Topologi | File / Layanan Kunci |
|---|---|---|---|
| **jichi** | `192.212.1.1` s.d. `4.1` | Router Sentral & DHCP Relay | NAT WAN (`eth0`), IP Forwarding, `isc-dhcp-relay` |
| **utahime** | `192.212.1.2` | DNS Master | BIND9 Master (`jujutsu.k02.com`, PTR) |
| **shoko** | `192.212.1.3` | DNS Slave | BIND9 Slave (Zone Replication) |
| **gojo** | `192.212.1.4` | Public Reverse Proxy | Nginx (Path routing `/` & `/api`, Cache, Rate Limit) |
| **itadori, fushiguro** | `192.212.2.10`–`.2.35` | Divisi A (Dev Pool 1) | DHCP Client (`alpinet`) |
| **zenin, okkotsu** | `192.212.2.70`–`.2.95` | Divisi A (Support Pool 2) | DHCP Client (`alpinet`) |
| **ino, kusakabe** | `192.212.3.10`–`.3.89` | Divisi B (Short Lease 1800s) | DHCP Client (`alpinet`) |
| **kugisaki** | `192.212.3.99` | Divisi B (Fixed Address VIP) | DHCP Static Lease (`alpinet`) |
| **miwa** | `192.212.3.100`–`.3.199`| Divisi B (Long Lease 43200s) | DHCP Client (`alpinet`) |
| **tengen** | `192.212.4.10` | DHCP Server Sentral | `isc-dhcp-server` (Pools, Classes, Fixed lease) |
| **geto** | `192.212.4.2` | Internal Load Balancer | Nginx (Weighted Round Robin 3:1 + Backup) |
| **maki, panda** | `192.212.4.3`, `.4.4` | Worker Frontend | Nginx + PHP-FPM (HTML Hostname) |
| **nanami, todo** | `192.212.4.5`, `.4.6` | Worker API Utama | API Logger ke MariaDB Master |
| **kirara** | `192.212.4.7` | Worker API Backup | API Logger ke MariaDB (Failover) |
| **yaga** | `192.212.4.8` | Database Master | MariaDB Master (`db_shibuya_k02`, binlog) |
| **inumaki** | `192.212.4.9` | Database Slave | MariaDB Slave (Replikasi Realtime) |

---

## 2. Struktur Berkas Skrip di `/root/`

| Node | Berkas Skrip di `/root/` | Fungsi Utama Skrip |
|---|---|---|
| **Semua Node** | `/root/init.sh` | Skrip universal: restore IP, gateway, resolv.conf, dan service |
| **jichi** | `/root/setup_jichi.sh` | Otomasi IP forwarding, iptables NAT Masquerade, dan DHCP Relay |
| **tengen** | `/root/setup_tengen.sh` | Otomasi `isc-dhcp-server` (deklarasi subnet, class, fixed IP) |
| **utahime & shoko** | `/root/setup_dns.sh` | Otomasi BIND9 Master & Slave |
| **yaga & inumaki** | `/root/setup_database.sh` | Otomasi MariaDB Master-Slave Replikasi |
| **maki, panda, nanami, todo, kirara** | `/root/setup_workers.sh` | Otomasi Nginx, PHP-FPM, API script, dan ACL |
| **geto** | `/root/setup_loadbalancer.sh`| Otomasi Weighted Round Robin LB dan Backup Failover |
| **gojo** | `/root/setup_proxy.sh` | Otomasi Public Reverse Proxy, Caching, dan Rate Limiting |

---

## 3. Checklist Verifikasi Saat Demonstrasi

- [ ] **Soal 1**: Ping antar host infrastruktur ke gateway (`192.212.x.1`) dan uji ping `google.com` dari node.
- [ ] **Soal 2**: Status service `isc-dhcp-server` di `tengen` aktif tanpa error subnet.
- [ ] **Soal 3**: Client Network 2 & 3 menerima IP via DHCP Relay di `jichi`.
- [ ] **Soal 4**: Pembuktian `itadori`/`fushiguro` mendapat IP Pool 1 (`.2.10-.2.35`) dan `zenin`/`okkotsu` mendapat IP Pool 2 (`.2.70-.2.95`).
- [ ] **Soal 5**: Pembuktian lease time `ino`/`kusakabe` (1800s) dan `miwa` (43200s), serta opsi DNS (`.1.2`, `.1.3`).
- [ ] **Soal 6**: Pembuktian `kugisaki` menerima fixed IP `192.212.3.99` berdasarkan MAC address.
- [ ] **Soal 7**: Audit tabel routing, broadcast, dan isi file `/var/lib/dhcp/dhcpd.leases` di `tengen`.
- [ ] **Soal 8**: Packet capture DORA (tcpdump) menunjukkan 4 pesan DHCP dan `giaddr` sesuai gateway subnet.
- [ ] **Soal 9**: Simulasi matikan service relay di `jichi` (renew gagal), nyalakan kembali (renew sukses).
- [ ] **Soal 10**: Reboot `tengen` & `jichi`, buktikan autostart aktif dan client tetap mendapatkan lease sesuai kebijakan.
- [ ] **Soal 11**: Sinkronisasi zona DNS Master `utahime` ke Slave `shoko` dengan update nomor serial SOA.
- [ ] **Soal 12**: Resolusi A record `jujutsu.k02.com`, CNAME `www`, Reverse PTR IP `gojo`, dan forwarder ke gateway WAN.
- [ ] **Soal 13**: Insert data ke master `yaga` dan verifikasi data otomatis muncul di slave `inumaki`.
- [ ] **Soal 14**: Akses langsung ke IP worker ditolak (403/Forbidden/Timeout), akses via reverse proxy sukses.
- [ ] **Soal 15**: Loop request ke endpoint API menghasilkan distribusi respon 3:1 antara `nanami` dan `todo`.
- [ ] **Soal 16**: Akses ke `/` dibalas worker frontend (`maki`/`panda`), akses ke `/api` diteruskan ke worker API.
- [ ] **Soal 17**: Header `X-Real-IP` tercatat sesuai IP asli client pengirim pada tabel `request_logs`.
- [ ] **Soal 18**: Matikan `nanami` dan `todo`, request ke `/api` otomatis difailover ke worker cadangan `kirara` tanpa 502.
- [ ] **Soal 19**: Header cache `X-Cache-Status` MISS pada akses pertama dan HIT pada akses kedua; uji rate limit 10 req/s.
- [ ] **Soal 20**: Hasil output Apache Benchmark (`ab -n 600 -c 30`) dari terminal `kusakabe`.
