# Laporan Resmi Praktikum Modul 3
### Komunikasi Data & Jaringan Komputer 2026

**Kelompok:** K-02  
**Prefix IP Kelompok:** `192.212.x.x`  
**Tema:** *Curtain Protocol: Shibuya Incident*  

>Maulana Zaki Putra Zakaria | 5027251009

>Naila Anggun Eka Rizqy | 5027251122

---

## Daftar Isi
- [Ringkasan Arsitektur & Tabel Pengalamatan IP](#ringkasan-arsitektur--tabel-pengalamatan-ip)
- [Bagian 1: DHCP & Konektivitas Jaringan (Soal 1 - 10)](#bagian-1-dhcp--konektivitas-jaringan-soal-1---10)
  - [Soal 1](#soal-1)
  - [Soal 2](#soal-2)
  - [Soal 3](#soal-3)
  - [Soal 4](#soal-4)
  - [Soal 5](#soal-5)
  - [Soal 6](#soal-6)
  - [Soal 7](#soal-7)
  - [Soal 8](#soal-8)
  - [Soal 9](#soal-9)
  - [Soal 10](#soal-10)
- [Bagian 2: DNS, Database Replikasi, Reverse Proxy & Load Balancing (Soal 11 - 20)](#bagian-2-dns-database-replikasi-reverse-proxy--load-balancing-soal-11---20)
  - [Soal 11](#soal-11)
  - [Soal 12](#soal-12)
  - [Soal 13](#soal-13)
  - [Soal 14](#soal-14)
  - [Soal 15](#soal-15)
  - [Soal 16](#soal-16)
  - [Soal 17](#soal-17)
  - [Soal 18](#soal-18)
  - [Soal 19](#soal-19)
  - [Soal 20](#soal-20)

---

## Ringkasan Arsitektur & Tabel Pengalamatan IP

### Tabel Alokasi IP Address (Prefix `192.212.x.x`)

| Segmen | Network ID | Node / Host | Interface | Alamat IP | Netmask | Default Gateway | Keterangan |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **WAN** | `192.168.122.0/24` | `jichi` | `eth0` | DHCP (`192.168.122.x`) | Sesuai DHCP | `192.168.122.1` | Koneksi WAN / Internet |
| **Network 1** (DMZ) | `192.212.1.0/24` | `jichi`<br>`utahime`<br>`shoko`<br>`gojo` | `eth1`<br>`eth0`<br>`eth0`<br>`eth0` | `192.212.1.1`<br>`192.212.1.2`<br>`192.212.1.3`<br>`192.212.1.4` | `255.255.255.0`<br>`255.255.255.0`<br>`255.255.255.0`<br>`255.255.255.0` | None (Gateway)<br>`192.212.1.1`<br>`192.212.1.1`<br>`192.212.1.1` | Router Gateway Net 1<br>DNS Master BIND9<br>DNS Slave BIND9<br>Public Reverse Proxy |
| **Network 2** (Divisi A) | `192.212.2.0/24` | `jichi`<br>`itadori`<br>`fushiguro`<br>`zenin`<br>`okkotsu` | `eth2`<br>`eth0`<br>`eth0`<br>`eth0`<br>`eth0` | `192.212.2.1`<br>`192.212.2.10`–`.2.35`<br>`192.212.2.10`–`.2.35`<br>`192.212.2.70`–`.2.95`<br>`192.212.2.70`–`.2.95` | `255.255.255.0`<br>`255.255.255.0`<br>`255.255.255.0`<br>`255.255.255.0`<br>`255.255.255.0` | None (Gateway)<br>`192.212.2.1`<br>`192.212.2.1`<br>`192.212.2.1`<br>`192.212.2.1` | Router & DHCP Relay Net 2<br>DHCP Pool 1 (Dev)<br>DHCP Pool 1 (Dev)<br>DHCP Pool 2 (Support)<br>DHCP Pool 2 (Support) |
| **Network 3** (Divisi B) | `192.212.3.0/24` | `jichi`<br>`ino`<br>`kusakabe`<br>`kugisaki`<br>`miwa` | `eth3`<br>`eth0`<br>`eth0`<br>`eth0`<br>`eth0` | `192.212.3.1`<br>`192.212.3.10`–`.3.89`<br>`192.212.3.10`–`.3.89`<br>`192.212.3.99`<br>`192.212.3.100`–`.3.199` | `255.255.255.0`<br>`255.255.255.0`<br>`255.255.255.0`<br>`255.255.255.0`<br>`255.255.255.0` | None (Gateway)<br>`192.212.3.1`<br>`192.212.3.1`<br>`192.212.3.1`<br>`192.212.3.1` | Router & DHCP Relay Net 3<br>DHCP Short Lease (1800s)<br>DHCP Short Lease (1800s)<br>DHCP Fixed Address (Static)<br>DHCP Long Lease (43200s) |
| **Network 4** (Data Center) | `192.212.4.0/24` | `jichi`<br>`tengen`<br>`geto`<br>`maki`<br>`panda`<br>`nanami`<br>`todo`<br>`kirara`<br>`yaga`<br>`inumaki` | `eth4`<br>`eth0`<br>`eth0`<br>`eth0`<br>`eth0`<br>`eth0`<br>`eth0`<br>`eth0`<br>`eth0`<br>`eth0` | `192.212.4.1`<br>`192.212.4.10`<br>`192.212.4.2`<br>`192.212.4.3`<br>`192.212.4.4`<br>`192.212.4.5`<br>`192.212.4.6`<br>`192.212.4.7`<br>`192.212.4.8`<br>`192.212.4.9` | `255.255.255.0`<br>`255.255.255.0`<br>`255.255.255.0`<br>`255.255.255.0`<br>`255.255.255.0`<br>`255.255.255.0`<br>`255.255.255.0`<br>`255.255.255.0`<br>`255.255.255.0`<br>`255.255.255.0` | None (Gateway)<br>`192.212.4.1`<br>`192.212.4.1`<br>`192.212.4.1`<br>`192.212.4.1`<br>`192.212.4.1`<br>`192.212.4.1`<br>`192.212.4.1`<br>`192.212.4.1`<br>`192.212.4.1` | Router Gateway Net 4<br>DHCP Server (isc-dhcp)<br>Internal LB (Nginx)<br>Worker Frontend 1<br>Worker Frontend 2<br>Worker API 1<br>Worker API 2<br>Worker API Backup<br>Database Master MariaDB<br>Database Slave MariaDB |

---

# Bagian 1: DHCP & Konektivitas Jaringan (Soal 1 - 10)

## Soal 1

>Dikerjakan Oleh Zaki

### Soal
> Ketika Curtain menutup Shibuya, jalur komunikasi antar zona Jujutsu High terputus. Pulihkan konektivitas dasar dengan mengonfigurasi jichi: eth0 memperoleh WAN dari NAT, sedangkan eth1–eth4 menjadi gateway Network 1–4 sesuai tabel pemetaan. Aktifkan IPv4 forwarding dan source NAT, lalu tetapkan IP statis host infrastruktur sesuai tabel spesifikasi. Buktikan konektivitas setiap host ke gateway dan akses eksternal dari host yang relevan.

### Langkah Pengerjaan
1. Konfigurasi interface router `jichi` dan iptables source NAT masquerade.
2. Konfigurasi alamat IP statis untuk host infrastruktur.
3. Pengujian konektivitas dasar menuju gateway dan akses internet.

### Bukti dan Hasil
- *Screenshot topologi GNS3*: `Screenshot/soal-1/topologi.png`
- *Screenshot ip route jichi*: `Screenshot/soal-1/ip-jichi.png`
- *Screenshot ping gateway*: `Screenshot/soal-1/ping-gateway.png`

---

## Soal 2

>Dikerjakan Oleh Zaki

### Soal
> Tengen, penjaga pusat distribusi di Data Center, harus mengambil alih pengalokasian alamat bagi wilayah yang membutuhkan konfigurasi dinamis. Konfigurasikan isc-dhcp-server pada [PREFIX IP].4.10. Deklarasikan Network 4 ([PREFIX IP].4.0/24) sebagai subnet lokal tanpa pool dinamis, lalu siapkan scope DHCP untuk Network 2 ([PREFIX IP].2.0/24) dan Network 3 ([PREFIX IP].3.0/24). Validasi konfigurasi dan pastikan service aktif tanpa error “No subnet declaration”.

### Langkah Pengerjaan
1. Instalasi `isc-dhcp-server` pada `tengen`.
2. Pengaturan file konfigurasi `/etc/dhcp/dhcpd.conf` dengan deklarasi subnet lokal Network 4 serta scope remote Network 2 dan 3.
3. Verifikasi status service `isc-dhcp-server`.

### Bukti dan Hasil
- *Screenshot konfigurasi dhcpd.conf*: `Screenshot/soal-2/dhcpd-conf.png`
- *Screenshot status service*: `Screenshot/soal-2/service-status.png`

---

## Soal 3

>Dikerjakan Oleh Zaki

### Soal
> Permintaan alamat dari Divisi A dan Divisi B tidak dapat menyeberangi subnet secara langsung. Konfigurasikan jichi sebagai DHCP Relay menuju tengen ([PREFIX IP].4.10), menggunakan eth2 untuk Network 2 dan eth3 untuk Network 3. Buktikan bahwa client dari kedua subnet berhasil memperoleh lease melalui relay.

### Langkah Pengerjaan
1. Instalasi `isc-dhcp-relay` pada router `jichi`.
2. Penentuan interfaces relay (`eth2`, `eth3`) dan target DHCP server (`192.212.4.10`).
3. Pengujian perolehan lease pada client Network 2 dan Network 3.

### Bukti dan Hasil
- *Screenshot konfigurasi relay*: `Screenshot/soal-3/relay-conf.png`
- *Screenshot perolehan IP client*: `Screenshot/soal-3/client-lease.png`

---

## Soal 4

>Dikerjakan Oleh Zaki

### Soal
> Agar tim Dev dan Support di Divisi A menerima jatah alamat yang berbeda, atur dua pool DHCP pada Network 2. Tetapkan Pool 1 ([PREFIX IP].2.10–[PREFIX IP].2.35) untuk itadori dan fushiguro, serta Pool 2 ([PREFIX IP].2.70–[PREFIX IP].2.95) untuk zenin dan okkotsu. Rentang [PREFIX IP].2.36–[PREFIX IP].2.69 tidak boleh dialokasikan. Karena seluruh client berada pada subnet yang sama, gunakan DHCP class berdasarkan MAC Address atau Client ID untuk memisahkan kedua kelompok.

### Langkah Pengerjaan
1. Definisi DHCP Class `pool-dev` dan `pool-support` berdasarkan hardware ethernet / client-identifier.
2. Pembatasan akses pool menggunakan `allow members of` dan `deny members of`.
3. Verifikasi alamat IP yang diperoleh masing-masing klien di Divisi A.

### Bukti dan Hasil
- *Screenshot konfigurasi class & pool*: `Screenshot/soal-4/class-pool-conf.png`
- *Screenshot alokasi IP itadori & zenin*: `Screenshot/soal-4/alokasi-ip.png`

---

## Soal 5

>Dikerjakan Oleh Zaki

### Soal
> Setiap tim lapangan memiliki durasi operasi yang berbeda. Pada Network 3, berikan short lease 30 menit (1800 detik) kepada ino dan kusakabe, serta long lease 12 jam (43200 detik) kepada miwa. Gunakan pool short lease [PREFIX IP].3.10–[PREFIX IP].3.89 dan pool long lease [PREFIX IP].3.100–[PREFIX IP].3.199. Sesuaikan default-lease-time dan max-lease-time untuk setiap kelas client. Berikan pula DHCP options berupa DNS [PREFIX IP].1.2 dan [PREFIX IP].1.3, serta domain-search <xxxx>.com.

### Langkah Pengerjaan
1. Konfigurasi lease time spesifik pada class / pool Network 3.
2. Penambahan opsi DHCP domain name servers dan domain search `k02.com`.
3. Verifikasi lease time dan DNS resolver pada klien `ino` dan `miwa`.

### Bukti dan Hasil
- *Screenshot konfigurasi lease time*: `Screenshot/soal-5/lease-conf.png`
- *Screenshot lease info pada client*: `Screenshot/soal-5/client-lease-info.png`

---

## Soal 6

>Dikerjakan Oleh Zaki

### Soal
> Kugisaki ditetapkan sebagai personel VIP yang harus mempertahankan alamat yang sama setiap kali terhubung. Buat DHCP static lease berdasarkan MAC Address client tersebut dengan fixed address [PREFIX IP].3.99. Pastikan alamat ini berada di luar seluruh pool dinamis, validasi konfigurasi server, lalu renew lease pada client. Buktikan bahwa alamat yang diterima sesuai dengan reservasi.

### Langkah Pengerjaan
1. Pengambilan MAC Address interface `eth0` pada node `kugisaki`.
2. Pendeklarasian blok `host kugisaki` dengan parameter `hardware ethernet` dan `fixed-address 192.212.3.99`.
3. Renew IP pada `kugisaki` dan verifikasi alamat yang didapat.

### Bukti dan Hasil
- *Screenshot deklarasi host kugisaki*: `Screenshot/soal-6/fixed-address-conf.png`
- *Screenshot renew IP kugisaki*: `Screenshot/soal-6/kugisaki-renew.png`

---

## Soal 7

>Dikerjakan Oleh Zaki

### Soal
> Setelah aturan alokasi diterapkan, pastikan setiap client menerima konfigurasi jaringan sesuai wilayahnya: subnet mask 255.255.255.0 (/24), gateway dan broadcast address yang benar, DNS [PREFIX IP].1.2 serta [PREFIX IP].1.3, dan domain-search yang ditentukan. Periksa IP address dan routing seluruh client Divisi A dan Divisi B, kemudian cocokkan lease dengan /var/lib/dhcp/dhcpd.leases pada tengen. Pastikan tidak ada alamat yang bertabrakan atau berada di luar kebijakan pool.

### Langkah Pengerjaan
1. Audit konfigurasi IP, subnet mask, default gateway, dan resolv.conf di seluruh client.
2. Analisis berkas database sewa `/var/lib/dhcp/dhcpd.leases` pada `tengen`.
3. Pengecekan konsistensi alamat terhadap rentang pool yang ditentukan.

### Bukti dan Hasil
- *Screenshot audit klien Network 2 & 3*: `Screenshot/soal-7/audit-klien.png`
- *Screenshot dhcpd.leases*: `Screenshot/soal-7/dhcpd-leases.png`

---

## Soal 8

>Dikerjakan Oleh Zaki

### Soal
> Sebelum Curtain dibuka kembali, buktikan bahwa proses pemberian alamat berjalan sesuai protokol. Lakukan packet capture saat salah satu client Network 2 atau Network 3 meminta lease baru. Gunakan tcpdump pada tengen atau jalur menuju Data Center untuk menunjukkan urutan DHCPDISCOVER → DHCPOFFER → DHCPREQUEST → DHCPACK. Identifikasi alamat server, alamat yang diberikan, lease time, dan field giaddr. Pastikan nilai giaddr sesuai dengan interface jichi yang menerima request dari subnet client.

### Langkah Pengerjaan
1. Menjalankan `tcpdump -i any -n port 67 or port 68` pada `tengen` / `jichi`.
2. Meminta perpanjangan lease baru pada client (`udhcpc -R -i eth0`).
3. Analisis 4 paket DORA dan pemeriksaan field `giaddr`.

### Bukti dan Hasil
- *Screenshot DORA capture*: `Screenshot/soal-8/dora-packets.png`
- *Screenshot detail giaddr*: `Screenshot/soal-8/giaddr-detail.png`

---

## Soal 9

>Dikerjakan Oleh Zaki

### Soal
> Sebuah gangguan memutus jalur relay dan membuat permintaan alamat tidak sampai ke Data Center. Hentikan service DHCP Relay pada jichi, lalu paksa salah satu client di Network 2 atau Network 3 meminta lease baru dan catat gejalanya. Pulihkan service relay, ulangi permintaan DHCP, lalu buktikan bahwa client kembali memperoleh alamat dari pool yang benar dengan gateway semula.

### Langkah Pengerjaan
1. Penghentian service `isc-dhcp-relay` di `jichi` dan pengujian renew lease pada klien.
2. Pencatatan gejala kegagalan (DHCPDISCOVER timeout).
3. Pemulihan service relay dan pengujian ulang perolehan lease.

### Bukti dan Hasil
- *Screenshot kegagalan saat relay down*: `Screenshot/soal-9/relay-failure.png`
- *Screenshot pemulihan saat relay aktif*: `Screenshot/soal-9/relay-recovered.png`

---

## Soal 10

>Dikerjakan Oleh Zaki

### Soal
> Setelah gangguan Shibuya tertangani, pastikan pemulihan bertahan setelah restart. Aktifkan autostart DHCP Server pada tengen dan DHCP Relay pada jichi, lalu restart kedua node. Verifikasi status layanan, IP, gateway, lease, dan konektivitas client Network 2–3. Pastikan kebijakan Pool 1, Pool 2, short lease, long lease, dan fixed address tetap berlaku.

### Langkah Pengerjaan
1. Pemasangan skrip persistensi dan autostart pada `tengen` dan `jichi`.
2. Eksekusi restart / reload container pada GNS3.
3. Verifikasi pemulihan otomatis service, routing, dan alokasi IP client.

### Bukti dan Hasil
- *Screenshot status autostart setelah restart*: `Screenshot/soal-10/autostart-status.png`
- *Screenshot verifikasi konektivitas client*: `Screenshot/soal-10/reboot-verify.png`

---

# Bagian 2: DNS, Database Replikasi, Reverse Proxy & Load Balancing (Soal 11 - 20)

## Soal 11

>Dikerjakan Oleh Anggun

### Soal
> Utahime dan Shoko ditugaskan membangun sistem penamaan domain resmi agar seluruh pos tidak perlu menghafal alamat IP mentah. Konfigurasikan BIND9 pada utahime sebagai DNS Master dan shoko sebagai DNS Slave untuk mengelola domain jujutsu.<xxxx>.com. Atur SOA record, NS delegasi untuk kedua server, dan terapkan allow-transfer dari Master ke Slave. Pastikan file zona berhasil tersinkronisasi otomatis ke shoko saat nomor serial di utahime dinaikkan, lalu buktikan dengan melakukan query dig ke kedua server dari salah satu client.

### Langkah Pengerjaan
1. Konfigurasi BIND9 Master pada `utahime` (`jujutsu.k02.com`).
2. Konfigurasi BIND9 Slave pada `shoko` dengan `masters { 192.212.1.2; };`.
3. Uji replikasi zona dan query `dig` dari client.

### Bukti dan Hasil
- *Screenshot konfigurasi BIND9*: `Screenshot/soal-11/bind9-conf.png`
- *Screenshot verifikasi dig*: `Screenshot/soal-11/dig-verify.png`

---

## Soal 12

>Dikerjakan Oleh Anggun

### Soal
> Peta domain harus memetakan pintu masuk utama dan tetap bisa mencari alamat di luar kawasan Shibuya. Pada utahime, buat A record jujutsu.<xxxx>.com yang mengarah ke gojo, serta CNAME www yang merujuk ke domain utama tersebut. Buat pula Reverse DNS (zona PTR) untuk melacak IP gojo kembali ke domain resminya, dan aktifkan fitur DNS Forwarder pada BIND9 mengarah ke IP gateway internet (192.168.122.1). Uji dari client dengan dig untuk mengecek CNAME, PTR, dan buktikan client tetap bisa melakukan ping ke domain internet seperti google.com.

### Langkah Pengerjaan
1. Penambahan A record `jujutsu.k02.com -> 192.212.1.4` dan CNAME `www`.
2. Pembuatan zona PTR Reverse DNS untuk IP `gojo`.
3. Konfigurasi forwarder ke `192.168.122.1` dan pengujian ping internet.

### Bukti dan Hasil
- *Screenshot dig A record & CNAME*: `Screenshot/soal-12/dig-a-cname.png`
- *Screenshot dig PTR & ping internet*: `Screenshot/soal-12/dig-ptr-ping.png`

---

## Soal 13

>Dikerjakan Oleh Anggun

### Soal
> Kepala Sekolah Yaga dan Inumaki mendirikan database terpusat yang redundan agar log aktivitas kutukan tetap aman tersimpan. Konfigurasikan MariaDB pada yaga sebagai DB-Master dan inumaki sebagai DB-Slave. Buat database db_shibuya_<xxxx> beserta tabel request_logs di Master, aktifkan binary logging (log-bin, server-id), lalu hubungkan inumaki sebagai Slave yang menyalin data secara realtime dengan CHANGE MASTER TO. Berikan hak akses remote bagi seluruh node di Network 4, lalu buktikan replikasi berhasil dengan memasukkan data baru di Master dan memeriksa hasilnya di Slave.

### Langkah Pengerjaan
1. Konfigurasi MariaDB Master di `yaga` (`server-id=1`, `log-bin`).
2. Konfigurasi MariaDB Slave di `inumaki` (`server-id=2`, `CHANGE MASTER TO`).
3. Pengujian replikasi tabel `request_logs` di database `db_shibuya_k02`.

### Bukti dan Hasil
- *Screenshot status replikasi Slave*: `Screenshot/soal-13/slave-status.png`
- *Screenshot pembuktian replikasi data*: `Screenshot/soal-13/replication-test.png`

---

## Soal 14

>Dikerjakan Oleh Anggun

### Soal
> Para penyihir lapangan bersiaga di Data Center sebagai pekerja backend untuk memproses aplikasi. Pasang Nginx dan PHP-FPM pada maki dan panda untuk menyajikan web frontend yang menampilkan hostname masing-masing. Pada nanami, todo, dan kirara, siapkan layanan API yang mencatat log request ke database yaga. Konfigurasikan virtual host agar worker merespons domain layanan yang ditentukan. Batasi akses langsung dari klien ke worker, web worker hanya menerima trafik melalui jalur proxy web yang ditentukan, sedangkan worker API hanya menerima trafik melalui geto. Uji bahwa akses langsung dari klien ditolak, sementara akses melalui reverse proxy tetap berhasil.

### Langkah Pengerjaan
1. Pemasangan Nginx + PHP-FPM pada frontend worker (`maki`, `panda`) dan API worker (`nanami`, `todo`, `kirara`).
2. Pembatasan akses langsung (ACL `allow`/`deny` atau iptables).
3. Pengujian akses ditolak secara langsung dan berhasil via proxy.

### Bukti dan Hasil
- *Screenshot response worker*: `Screenshot/soal-14/worker-response.png`
- *Screenshot uji ACL*: `Screenshot/soal-14/acl-test.png`

---

## Soal 15

>Dikerjakan Oleh Anggun

### Soal
> Geto bertugas mengendalikan pembagian beban request API di internal Data Center agar server tidak tumbang bersamaan. Konfigurasikan Nginx pada geto sebagai Load Balancer internal dengan upstream api_cluster yang mengarahkan trafik ke nanami dan todo. Terapkan algoritma Weighted Round Robin dengan bobot 3:1, di mana nanami menerima porsi beban tiga kali lebih banyak daripada todo. Buktikan distribusi beban ini dengan melakukan loop request berulang kali ke geto dari jaringan lokal Data Center dan periksa rasio responnya.

### Langkah Pengerjaan
1. Konfigurasi upstream `api_cluster` di `geto` (`weight=3` untuk nanami, `weight=1` untuk todo).
2. Uji distribusi beban menggunakan skrip looping request.
3. Analisis rasio respon 3:1.

### Bukti dan Hasil
- *Screenshot konfigurasi upstream geto*: `Screenshot/soal-15/geto-upstream.png`
- *Screenshot hasil loop request*: `Screenshot/soal-15/loop-ratio.png`

---

## Soal 16

>Dikerjakan Oleh Anggun

### Soal
> Gojo berdiri di perbatasan DMZ sebagai gerbang publik tunggal bagi seluruh client dari luar maupun dalam. Konfigurasikan Nginx pada gojo untuk melayani domain jujutsu.<xxxx>.com dan www.jujutsu.<xxxx>.com menggunakan metode Path-Based Routing. Atur agar request root (/) diteruskan secara Round Robin ke worker frontend (maki dan panda), sedangkan request ke path /api diteruskan langsung ke geto. Uji dari client Divisi A atau B bahwa akses ke web utama dibalas oleh Maki/Panda, sedangkan akses ke /api diteruskan dan dijawab oleh Nanami/Todo.

### Langkah Pengerjaan
1. Konfigurasi Nginx `gojo` dengan server_name `jujutsu.k02.com` dan `www.jujutsu.k02.com`.
2. Pengaturan routing: `location /` proxy ke frontend worker, `location /api` proxy ke `geto`.
3. Pengujian akses dari klien Divisi A dan Divisi B.

### Bukti dan Hasil
- *Screenshot konfigurasi gojo*: `Screenshot/soal-16/gojo-routing.png`
- *Screenshot uji akses root dan /api*: `Screenshot/soal-16/curl-endpoints.png`

---

## Soal 17

>Dikerjakan Oleh Anggun

### Soal
> Komando pusat perlu mengetahui IP asli klien yang mengirimkan request tanpa tertukar dengan IP proxy perantara. Konfigurasikan gojo dan geto agar meneruskan informasi alamat klien melalui header X-Real-IP dan X-Forwarded-For. Pastikan geto hanya mempercayai informasi alamat klien yang diterima dari proxy terpercaya, dan skrip API menyimpan alamat klien yang telah diverifikasi ke kolom client_ip pada tabel request_logs di database yaga. Uji dengan mengirimkan request dari klien Network 2 dan Network 3 ke endpoint /api, kemudian periksa database untuk memastikan alamat yang tercatat sesuai dengan IP klien asal, bukan IP gojo atau geto.

### Langkah Pengerjaan
1. Konfigurasi header forwarding (`proxy_set_header X-Real-IP`, `X-Forwarded-For`) pada `gojo` dan `geto`.
2. Konfigurasi `set_real_ip_from` pada `geto`.
3. Pengecekan isi tabel `request_logs` di database MariaDB `yaga`.

### Bukti dan Hasil
- *Screenshot header proxy*: `Screenshot/soal-17/header-proxy.png`
- *Screenshot data client_ip di database*: `Screenshot/soal-17/db-real-ip.png`

---

## Soal 18

>Dikerjakan Oleh Anggun

### Soal
> nanami dan todo merupakan worker API utama, sedangkan kirara disiapkan sebagai worker cadangan. Konfigurasikan upstream api_cluster pada geto agar kirara menjadi server backup, serta terapkan passive health check dengan parameter max_fails=2 dan fail_timeout=5s pada worker API utama. Pastikan kirara menjalankan layanan API yang kompatibel dengan endpoint utama. Simulasikan gangguan dengan menghentikan layanan Nginx atau layanan API pada nanami dan todo. Buktikan dari klien bahwa request ke /api dialihkan ke kirara dan menghasilkan respons API yang valid tanpa error 502 Bad Gateway.

### Langkah Pengerjaan
1. Penambahan parameter `backup`, `max_fails=2`, dan `fail_timeout=5s` pada upstream `geto`.
2. Simulasi kegagalan pada `nanami` dan `todo`.
3. Pembuktian failover request menuju `kirara` tanpa error 502.

### Bukti dan Hasil
- *Screenshot upstream backup geto*: `Screenshot/soal-18/backup-upstream.png`
- *Screenshot failover ke kirara*: `Screenshot/soal-18/failover-test.png`

---

## Soal 19

>Dikerjakan Oleh Anggun

### Soal
> gojo bertugas mengoptimalkan layanan web sekaligus membatasi request berlebihan. Konfigurasikan Nginx Proxy Caching untuk halaman web frontend dengan masa berlaku cache 10 menit dan tambahkan header X-Cache-Status. Terapkan rate limiting pada path /api dengan batas 10 request per detik per IP klien. Buktikan bahwa request ke halaman web yang memenuhi syarat cache menghasilkan status MISS pada akses awal dan HIT pada akses berikutnya. Uji rate limiting secara terpisah dengan mengirimkan request beruntun ke /api, kemudian catat status respons yang dihasilkan ketika batas terlampaui.

### Langkah Pengerjaan
1. Konfigurasi `proxy_cache_path` dan header `X-Cache-Status $upstream_cache_status` pada `gojo`.
2. Konfigurasi `limit_req_zone` 10r/s pada `location /api`.
3. Pengujian cache (MISS lalu HIT) dan pengujian rate limit (respons 429 atau 503).

### Bukti dan Hasil
- *Screenshot cache MISS & HIT*: `Screenshot/soal-19/cache-status.png`
- *Screenshot rate limit response*: `Screenshot/soal-19/rate-limit.png`

---

## Soal 20

>Dikerjakan Oleh Anggun

### Soal
> Sebelum Curtain di Shibuya resmi dibuka, Kusakabe memimpin audit untuk menguji kapasitas layanan. Dari terminal kusakabe, jalankan benchmark menggunakan Apache Benchmark dengan parameter -n 600 -c 30 menuju http://jujutsu.<xxxx>.com/. Catat Requests per Second (RPS), latensi, dan jumlah request yang gagal. Lakukan pengujian tambahan pada endpoint /api untuk mengamati efek rate limiting. Bandingkan hasil pengujian baseline dengan hasil ketika rate limiting aktif, serta gunakan access log gojo untuk membedakan kegagalan aplikasi, koneksi, dan request yang ditolak oleh kebijakan rate limit.

### Langkah Pengerjaan
1. Instalasi `apache2-utils` pada `kusakabe`.
2. Eksekusi `ab -n 600 -c 30 http://jujutsu.k02.com/` dan pengujian pada endpoint `/api`.
3. Analisis metrik RPS, latency, failed requests, dan access log `gojo`.

### Bukti dan Hasil
- *Screenshot hasil ab benchmark root*: `Screenshot/soal-20/ab-root.png`
- *Screenshot hasil ab benchmark /api*: `Screenshot/soal-20/ab-api.png`
- *Screenshot access log gojo*: `Screenshot/soal-20/access-log.png`

---

