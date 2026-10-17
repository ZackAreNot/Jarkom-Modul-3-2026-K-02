# Panduan Lengkap Demo Praktikum Jarkom Modul 3 (Soal 11 - 20)
**Curtain Protocol: Shibuya Incident**  
**Presenter:** Naila Anggun Eka Rizqy (5027251122)  
**Kelompok:** K-02 (Prefix IP: `192.212.x.x` | Domain: `jujutsu.k02.com`)

---

## 📌 Tips Umum Menghadapi Asisten Praktikum (Asprak)
1. **Pahami "Mengapa", Bukan Cuma "Bagaimana"**: Asprak biasanya tidak hanya melihat perintah berjalan, tapi akan bertanya: *"Kenapa pakai parameter ini?"* atau *"Apa dampaknya kalau baris ini dihapus?"*.
2. **Ketenangan & Kontak Mata**: Bicaralah dengan tempo sedang, jangan terburu-buru. Tunjukkan baris kode atau baris log yang sedang kamu bahas di layar.
3. **Buka Terminal Sesuai Urutan Sebelum Presentasi Dimulai**:
   - `itadori` & `kusakabe` (Klien pengujian utama)
   - `gojo` (Public Reverse Proxy DMZ)
   - `geto` (Internal Load Balancer Data Center)
   - `yaga` & `inumaki` (Database Master-Slave)
   - `utahime` & `shoko` (DNS Master-Slave)
   - `nanami` / `todo` / `kirara` (API Workers)
4. **Gunakan Script Helper Otomatis**: Di node klien dan server sudah disiapkan script helper (`test_cache.sh`, `test_rate_limit.sh`, `test_api_client.sh`, `check_db_logs.sh`, `run_benchmark_root.sh`, dsb) agar demo kamu terlihat rapi, bersih, dan bebas dari typo.

---

## Soal 11: BIND9 DNS Master-Slave dengan Zone Transfer

### 1. Konsep Utama
Membangun redundansi layanan DNS. `utahime` bertindak sebagai Master Server (pemegang zona otoritatif primer), sedangkan `shoko` bertindak sebagai Slave Server yang menyalin data zona secara berkala melalui mekanisme *Zone Transfer* (AXFR).

### 2. Parameter Jaringan
- **DNS Master (`utahime`)**: `192.212.1.2`
- **DNS Slave (`shoko`)**: `192.212.1.3`
- **Zone**: `jujutsu.k02.com`

### 3. Langkah Demo Live & Skrip Percakapan

#### Step 1: Tunjukkan Konfigurasi di Master (`utahime`)
Jalankan di terminal `utahime`:
```bash
cat /etc/bind/named.conf.local
cat /etc/bind/zones/db.jujutsu.k02.com
```
🗣️ **Yang Diucapkan ke Asprak:**
> *"Permisi Kak, untuk Soal 11 mengenai implementasi DNS Master-Slave redundan antara utahime sebagai Master (192.212.1.2) dan shoko sebagai Slave (192.212.1.3).*  
> *Pertama di node utahime, bisa dilihat pada file `named.conf.local`, zona `jujutsu.k02.com` diset sebagai `type master` dengan file zona di `/etc/bind/zones/db.jujutsu.k02.com`. Di sini kami menambahkan direktif `allow-transfer` dan `also-notify` yang dikunci khusus ke IP shoko (192.212.1.3) agar transfer zona aman dan tidak bisa di-download oleh sembarang pihak luar.*  
> *Lalu pada file zona `db.jujutsu.k02.com`, kita memiliki SOA record dengan serial number `2026101401` sebagai penanda versi database zona."*

#### Step 2: Tunjukkan Konfigurasi di Slave (`shoko`)
Jalankan di terminal `shoko`:
```bash
cat /etc/bind/named.conf.local
ls -la /var/cache/bind/
```
🗣️ **Yang Diucapkan ke Asprak:**
> *"Selanjutnya di node shoko, pada `named.conf.local` tipenya diset sebagai `type slave` dengan master yang mengarah ke utahime. Dan jika kita periksa direktori cache BIND di `/var/cache/bind/`, file salinan zona `db.jujutsu.k02.com` sudah otomatis terbentuk berkat proses zone transfer AXFR dari utahime."*

#### Step 3: Pengujian Resolusi dari Klien (`itadori`)
Jalankan di terminal `itadori`:
```bash
# Query ke Master
dig @192.212.1.2 jujutsu.k02.com
# Query ke Slave
dig @192.212.1.3 jujutsu.k02.com
```
🗣️ **Yang Diucapkan ke Asprak:**
> *"Sekarang saya buktikan resolusinya dari klien itadori Kak. Ketika saya query `dig` ke Master utahime, statusnya `NOERROR` dan mengembalikan A record yang mengarah ke IP gojo (192.212.1.4).*  
> *Lalu ketika saya query ke Slave shoko, hasilnya identik dan serial number-nya sinkron. Ini membuktikan Slave siap melayani query klien jika suatu saat Master mengalami kendala."*

### 4. Prediksi Pertanyaan Asprak & Jawaban Cerdas
- **T: Apa fungsi serial number pada SOA record?**  
  *J: Sebagai penanda versi database zona. Saat Master memperbarui isi zona dan menaikkan nilai serial number, Slave yang menerima notifikasi akan membandingkan serial tersebut. Jika serial di Master lebih besar, Slave akan meminta zone transfer.*
- **T: Mengapa transfer zona harus dibatasi dengan `allow-transfer`?**  
  *J: Untuk mencegah serangan DNS Zone Walking (AXFR query abuse). Tanpa pembatasan, pihak luar dapat men-download seluruh daftar host dan topologi jaringan internal kita.*

---

## Soal 12: DNS Record (A & CNAME), Reverse PTR, dan DNS Forwarder

### 1. Konsep Utama
Melengkapi DNS dengan pemetaan alias (*CNAME*), pemetaan balik IP ke Domain (*Reverse DNS / PTR*), serta meneruskan query domain publik/internet ke gateway (*Forwarder*).

### 2. Parameter Jaringan
- **A Record**: `gojo` -> `192.212.1.4`
- **CNAME**: `www.jujutsu.k02.com` -> `jujutsu.k02.com`
- **Reverse Zone**: `1.212.192.in-addr.arpa` -> `gojo.jujutsu.k02.com`
- **DNS Forwarder**: `192.168.122.1`

### 3. Langkah Demo Live & Skrip Percakapan (di Klien `itadori`)

#### Step 1: Uji Record CNAME (`www`)
Jalankan di terminal `itadori`:
```bash
dig @192.212.1.2 www.jujutsu.k02.com
```
🗣️ **Yang Diucapkan ke Asprak:**
> *"Lanjut ke Soal 12 Kak, di sini kita menguji CNAME `www`. Bisa dilihat pada bagian ANSWER SECTION, domain `www.jujutsu.k02.com` dipetakan sebagai alias CNAME menuju domain kanonikal `jujutsu.k02.com`, yang kemudian langsung diterjemahkan ke IP 192.212.1.4."*

#### Step 2: Uji Reverse DNS (PTR)
Jalankan di terminal `itadori`:
```bash
dig @192.212.1.2 -x 192.212.1.4
```
🗣️ **Yang Diucapkan ke Asprak:**
> *"Kedua untuk Reverse DNS, saya jalankan query balik `dig -x 192.212.1.4`. Di sini outputnya mengembalikan PTR record `gojo.jujutsu.k02.com` pada zona balik `1.212.192.in-addr.arpa`. Jadi pemetaan dari alamat IP kembali ke nama host sudah terverifikasi valid."*

#### Step 3: Uji DNS Forwarder ke Internet
Jalankan di terminal `itadori`:
```bash
dig @192.212.1.2 google.com
ping -c 2 google.com
```
🗣️ **Yang Diucapkan ke Asprak:**
> *"Ketiga untuk Forwarder, di utahime kami mengonfigurasi `forwarders { 192.168.122.1; };`. Saat itadori meminta resolusi domain publik seperti `google.com` ke utahime, query tersebut berhasil diteruskan ke gateway internet dan dibalas dengan IP publik serta berhasil di-ping Kak."*

*(Tips: Jika Asprak meminta melihat file konfigurasi aslinya di `utahime`, jalankan ini di utahime:)*
```bash
cat /etc/bind/zones/db.192.212.1      # File Zona Reverse PTR
cat /etc/bind/named.conf.options     # File Konfigurasi Forwarders
```

### 4. Prediksi Pertanyaan Asprak & Jawaban Cerdas
- **T: Mengapa reverse DNS menggunakan format `in-addr.arpa` dan oktet IP-nya dibalik?**  
  *J: Karena struktur DNS dibaca dari kanan ke kiri (dari yang paling umum/TLD ke spesifik). Format IPv4 `192.212.1.4` meletakkan network ID di depan, sehingga harus dibalik menjadi `4.1.212.192.in-addr.arpa` agar sesuai dengan struktur hierarki pohon DNS.*
- **T: Apa perbedaan Forwarder dengan Root Hints?**  
  *J: Forwarder langsung mendelegasikan query rekursif ke server perantara (seperti router/ISP), sedangkan Root Hints akan menelusuri dari server root tingkat dunia secara mandiri dan bertahap.*

---

## Soal 13: Replikasi Database MariaDB Master-Slave

### 1. Konsep Utama
Menjamin ketersediaan data dan redundansi database secara asinkron antara database utama (`yaga`) dan cadangan (`inumaki`). Setiap transaksi tulis di Master dicatat dalam *Binary Log* dan dieksekusi ulang di Slave melalui *I/O Thread* dan *SQL Thread*.

### 2. Parameter Jaringan
- **Master (`yaga`)**: `192.212.4.8` (server-id: 1)
- **Slave (`inumaki`)**: `192.212.4.9` (server-id: 2)
- **Database & User**: `db_shibuya_k02`, user `replica`@`%`

### 3. Langkah Demo Live & Skrip Percakapan

#### Step 1: Cek Status Master di Node `yaga`
Jalankan di terminal `yaga`:
```bash
mariadb -e "SHOW MASTER STATUS\G"
```
🗣️ **Yang Diucapkan ke Asprak:**
> *"Masuk ke Soal 13 mengenai replikasi database MariaDB Master-Slave. Pertama di node yaga, saya tampilkan status master dengan `SHOW MASTER STATUS`. Terlihat Binary Log aktif pada file `mariadb-bin.000001` dengan database yang direplikasi adalah `db_shibuya_k02`."*

#### Step 2: Cek Status Replikasi di Node `inumaki`
Jalankan di terminal `inumaki`:
```bash
mariadb -e "SHOW SLAVE STATUS\G"
```
🗣️ **Yang Diucapkan ke Asprak:**
> *"Kemudian di node inumaki, kita periksa status replikasinya. Dua indikator terpenting di sini Kak:  
> 1. `Slave_IO_Running: Yes`, membuktikan thread I/O berhasil terkoneksi ke yaga dan menyalin binlog ke relay log lokal inumaki.  
> 2. `Slave_SQL_Running: Yes`, membuktikan thread SQL sukses membaca relay log dan mengeksekusinya ke database lokal.  
> Dan nilai `Seconds_Behind_Master: 0` menunjukkan replikasi berjalan sinkron tanpa lag."*

#### Step 3: Uji Replikasi Real-Time
Jalankan di `yaga`:
```bash
mariadb -e "INSERT INTO db_shibuya_k02.request_logs (worker_name, client_ip, proxy_ip, user_agent) VALUES ('test-master', '127.0.0.1', '127.0.0.1', 'demo-test');"
```
Lalu langsung cek di `inumaki`:
```bash
mariadb -e "SELECT * FROM db_shibuya_k02.request_logs WHERE worker_name='test-master';"
```
🗣️ **Yang Diucapkan ke Asprak:**
> *"Untuk pembuktian real-time, saya coba insert satu data dummy di yaga. Dan saat kita periksa di inumaki, datanya langsung terduplikasi secara otomatis Kak."*

### 4. Prediksi Pertanyaan Asprak & Jawaban Cerdas
- **T: Apa peran masing-masing dari Slave_IO_Running dan Slave_SQL_Running?**  
  *J: `Slave_IO_Running` bertugas menghubungkan Slave ke Master, mengunduh event baru dari Binary Log Master, dan menulisnya ke Relay Log lokal. Sementara `Slave_SQL_Running` bertugas membaca Relay Log tersebut dan mengeksekusi perintah SQL-nya ke tabel lokal Slave.*

---

## Soal 14: Frontend & API Workers + Access Control List (ACL)

### 1. Konsep Utama
Pemisahan tugas server dan isolasi backend Data Center (*defense in depth*). Klien di Network 2 & 3 dilarang keras mengakses worker secara langsung (menghasilkan 403 Forbidden), dan hanya boleh lewat proxy resmi.

### 2. Pembagian Worker
- **Frontend Workers**: `maki` (`192.212.4.3`) & `panda` (`192.212.4.4`) -> Nginx + PHP-FPM web portal.
- **API Workers**: `nanami` (`192.212.4.5`), `todo` (`192.212.4.6`), `kirara` (`192.212.4.7`) -> Nginx + PHP API JSON.

### 3. Langkah Demo Live & Skrip Percakapan

#### Step 1: Buktikan Blokir Akses Langsung dari Klien (`itadori`)
Jalankan di terminal `itadori`:
```bash
# Coba akses langsung ke worker frontend
curl -i http://192.212.4.3/
# Coba akses langsung ke worker API
curl -i http://192.212.4.5/
```
🗣️ **Yang Diucapkan ke Asprak:**
> *"Di Soal 14, kita mengonfigurasi worker web dan API sekaligus menerapkan Access Control List (ACL) pada Nginx.  
> Untuk membuktikannya, sekarang saya coba bypass dari klien itadori dengan langsung menembak IP worker maki dan nanami. Hasilnya langsung ditolak dengan respons `HTTP/1.1 403 Forbidden` karena terkena aturan `deny all`."*

#### Step 2: Buktikan Akses Diizinkan dari Proxy Resmi
Jalankan di terminal `gojo`:
```bash
curl -s http://192.212.4.3/ | grep -A 2 "Worker Hostname"
```
Dan di terminal `geto`:
```bash
curl -s http://192.212.4.5/
```
🗣️ **Yang Diucapkan ke Asprak:**
> *"Namun jika request datang dari proxy resmi—yaitu gojo untuk worker frontend dan geto untuk worker API—akses diizinkan dengan status `200 OK` dan data worker ditampilkan. Ini menjamin worker backend terlindungi dari akses ilegal langsung Kak."*

### 4. Prediksi Pertanyaan Asprak & Jawaban Cerdas
- **T: Mengapa konfigurasi ACL ditaruh di level web server worker, padahal di router sudah ada segmentasi jaringan?**  
  *J: Sebagai penerapan prinsip Defense in Depth (keamanan berlapis). Jika penyerang berhasil menembus router atau melakukan IP spoofing di jaringan lokal, server backend tetap aman karena memiliki filter otorisasi sendiri di level aplikasi Nginx.*

---

## Soal 15: Internal Load Balancer Weighted Round Robin (3:1)

### 1. Konsep Utama
Distribusi beban trafik API di Data Center menggunakan `geto` dengan pembobotan kapasitas: `nanami` menangani 3 request untuk setiap 1 request yang ditangani `todo` (rasio 75% : 25%).

### 2. Upstream `api_cluster` pada `geto`
- `server 192.212.4.5:80 weight=3;` (`nanami`)
- `server 192.212.4.6:80 weight=1;` (`todo`)

### 3. Langkah Demo Live & Skrip Percakapan (di Node `geto`)

#### Step 1: Tunjukkan Konfigurasi Upstream
Jalankan di terminal `geto`:
```bash
cat /etc/nginx/sites-available/default
```
🗣️ **Yang Diucapkan ke Asprak:**
> *"Untuk Soal 15, node geto (192.212.4.2) dikonfigurasi sebagai Internal Load Balancer. Di sini pada blok `upstream api_cluster`, worker nanami kami berikan `weight=3` dan worker todo kami berikan `weight=1`."*

#### Step 2: Jalankan Pengujian Rasio 40 Request
Jalankan di terminal `geto`:
```bash
/root/test_ratio.sh
```
🗣️ **Yang Diucapkan ke Asprak:**
> *"Sekarang saya jalankan pengujian 40 request secara otomatis menggunakan script `/root/test_ratio.sh`.  
> Bisa kita lihat hasil akhirnya di layar Kak: dari 40 request yang dikirimkan, nanami melayani tepat 30 request (75%), dan todo melayani tepat 10 request (25%). Ini membuktikan algoritma Weighted Round Robin bekerja secara presisi dengan rasio 3 banding 1."*

### 4. Prediksi Pertanyaan Asprak & Jawaban Cerdas
- **T: Kapan kita menggunakan Weighted Round Robin dibandingkan Least Connections?**  
  *J: Weighted Round Robin cocok saat spesifikasi hardware server berbeda (misal server A kapasitasnya 3 kali lipat dari server B) dengan beban komputasi per request yang seragam. Sedangkan Least Connections lebih cocok jika durasi proses tiap request sangat bervariasi.*

---

## Soal 16: Public Reverse Proxy & Path-Based Routing

### 1. Konsep Utama
`gojo` berfungsi sebagai gerbang tunggal (*Single Point of Entry*) di DMZ yang mengabstraksi seluruh topologi internal. Ia melakukan inspeksi Layer 7 pada URI path: request `/` diarahkan ke frontend cluster, sedangkan `/api` diteruskan ke internal load balancer `geto`.

### 2. Langkah Demo Live & Skrip Percakapan (dari Klien `itadori`)

#### Step 1: Uji Path Root Frontend (`/`)
Jalankan di terminal `itadori`:
```bash
curl -s http://jujutsu.k02.com/ | grep -A 2 "Worker Hostname"
curl -s http://jujutsu.k02.com/ | grep -A 2 "Worker Hostname"
```
🗣️ **Yang Diucapkan ke Asprak:**
> *"Di Soal 16, node gojo (192.212.1.4) di DMZ bertindak sebagai Public Reverse Proxy dengan Path-Based Routing.  
> Ketika saya mengakses domain utama `http://jujutsu.k02.com/`, request diarahkan ke cluster frontend dan dilayani bergantian oleh worker maki dan panda secara Round Robin."*

#### Step 2: Uji Path API (`/api`)
Jalankan di terminal `itadori`:
```bash
curl -s http://jujutsu.k02.com/api
```
🗣️ **Yang Diucapkan ke Asprak:**
> *"Sedangkan ketika saya mengakses path `http://jujutsu.k02.com/api`, gojo secara otomatis membelokkan trafik ke internal load balancer geto, yang kemudian mengembalikan respon JSON valid dari worker API backend Kak."*

### 3. Prediksi Pertanyaan Asprak & Jawaban Cerdas
- **T: Mengapa arsitektur microservices atau modern web lebih menyukai Path-Based Routing via Reverse Proxy?**  
  *J: Karena pengguna luar hanya perlu mengingat satu nama domain utama (`jujutsu.k02.com`), sementara di belakang layar kita bebas memisahkan teknologi frontend (HTML/CSS) dan backend (REST API) ke cluster server yang terpisah tanpa mengubah URL klien.*

---

## Soal 17: Preservasi Real Client IP & Database Logging

### 1. Konsep Utama
Karena request melewati 2 lapis proxy (`gojo` -> `geto`), IP asal klien berisiko tertukar menjadi IP proxy. Modul `ngx_http_realip_module` pada `geto` memverifikasi IP klien hanya dari proxy resmi (`gojo`), lalu skrip API mencatat IP asli tersebut ke database MariaDB `yaga`.

### 2. Langkah Demo Live & Skrip Percakapan

#### Step 1: Tunjukkan Konfigurasi Trusted Proxy di `geto`
Jalankan di terminal `geto`:
```bash
cat /etc/nginx/sites-available/default
```
🗣️ **Yang Diucapkan ke Asprak:**
> *"Di Soal 17, kita menyelesaikan masalah hilangnya IP asli klien akibat multi-hop proxy.  
> Pada node geto, kami mengaktifkan direktif `set_real_ip_from 192.212.1.4;` dan `real_ip_header X-Forwarded-For;`. Ini memastikan geto hanya mempercayai informasi IP asli jika request datang dari proxy resmi gojo untuk mencegah IP spoofing."*

#### Step 2: Kirim Request dari Klien Subnet Berbeda
Jalankan di `itadori` (Network 2):
```bash
/root/test_api_client.sh
```
Lalu jalankan di `kusakabe` (Network 3):
```bash
/root/test_api_client.sh
```
🗣️ **Yang Diucapkan ke Asprak:**
> *"Sekarang saya kirim request dari dua subnet berbeda:  
> Dari itadori (Network 2), respon JSON mengonfirmasi `client_ip: 192.212.2.10`.  
> Dan dari kusakabe (Network 3), respon JSON mengonfirmasi `client_ip: 192.212.3.11`.  
> Keduanya menampilkan status `db_log: saved_to_yaga`."*

#### Step 3: Buktikan Pencatatan di Database `yaga`
Jalankan di terminal `yaga`:
```bash
/root/check_db_logs.sh
```
🗣️ **Yang Diucapkan ke Asprak:**
> *"Sebagai bukti pamungkas, kita buka database yaga. Bisa dilihat pada tabel `request_logs` Kak:  
> Kolom `client_ip` mencatat alamat asli klien secara presisi (192.212.2.10 dan 192.212.3.11), sedangkan IP proxy geto tersimpan terpisah di kolom `proxy_ip`. Identitas klien tidak tertukar sama sekali Kak."*

### 3. Prediksi Pertanyaan Asprak & Jawaban Cerdas
- **T: Mengapa tidak langsung membaca header `X-Forwarded-For` saja tanpa `set_real_ip_from`?**  
  *J: Karena header HTTP bisa dipalsukan oleh klien jahat dari luar. Tanpa `set_real_ip_from`, klien bisa mengirimkan header palsu `X-Forwarded-For: 1.1.1.1` dan server akan tertipu. Dengan `set_real_ip_from`, Nginx hanya mempercayai header jika paket berasal dari proxy terpercaya kita sendiri.*

---

## Soal 18: High Availability, Passive Health Check & Failover

### 1. Konsep Utama
Toleransi kesalahan (*fault tolerance*) pada kluster API. Jika seluruh worker utama (`nanami` dan `todo`) mengalami gangguan, trafik otomatis dialihkan seketika ke worker cadangan (*hot-standby*) `kirara` tanpa error 502 Bad Gateway.

### 2. Langkah Demo Live & Skrip Percakapan

#### Step 1: Tunjukkan Konfigurasi Upstream di `geto`
Jalankan di terminal `geto`:
```bash
grep -A 7 "upstream api_cluster" /etc/nginx/sites-available/default
```
🗣️ **Yang Diucapkan ke Asprak:**
> *"Untuk Soal 18, pada upstream `api_cluster` di node geto, kami menerapkan Passive Health Check dengan `max_fails=2` dan `fail_timeout=5s` pada worker utama nanami dan todo. Serta menandai kirara dengan direktif `backup`."*

#### Step 2: Simulasikan Gangguan Total Worker Utama
Jalankan di terminal `nanami`:
```bash
service nginx stop
```
Dan di terminal `todo`:
```bash
service nginx stop
```
🗣️ **Yang Diucapkan ke Asprak:**
> *"Sekarang saya simulasikan skenario darurat di mana kedua worker API utama mengalami down. Saya matikan Nginx di nanami dan todo."*

#### Step 3: Uji Failover Otomatis dari Klien `itadori`
Jalankan di terminal `itadori`:
```bash
curl -s http://jujutsu.k02.com/api
```
🗣️ **Yang Diucapkan ke Asprak:**
> *"Saat kedua worker utama down, saya kirim request dari itadori. Bisa dilihat Kak, request langsung dijawab oleh server cadangan `worker: kirara` dengan status `success`, tanpa ada jeda atau error `502 Bad Gateway`! Proses failover berjalan transparan bagi pengguna."*

#### Step 4: Pemulihan (Recovery)
Jalankan di `nanami` dan `todo`:
```bash
service nginx start
```
🗣️ **Yang Diucapkan ke Asprak:**
> *"Dan ketika layanan di nanami dan todo dinyalakan kembali, trafik otomatis kembali normal ke worker utama, sementara kirara kembali siaga sebagai cadangan Kak."*

---

## Soal 19: Nginx Proxy Caching & Rate Limiting

### 1. Konsep Utama
Dua mekanisme proteksi dan optimasi di gerbang depan `gojo`:
1. **Proxy Caching**: Menyimpan salinan halaman frontend selama 10 menit untuk mempercepat latensi respon dan mengurangi beban worker.
2. **Rate Limiting**: Membatasi kuota request ke `/api` maksimal 10 request/detik per IP klien untuk mencegah DoS flooding.

### 2. Langkah Demo Live & Skrip Percakapan (di Klien `itadori`)

#### Step 1: Uji Proxy Caching (MISS lalu HIT)
Jalankan di terminal `itadori`:
```bash
/root/test_cache.sh
```
🗣️ **Yang Diucapkan ke Asprak:**
> *"Di Soal 19, kita menguji efektivitas Proxy Caching dan Rate Limiting di node gojo.  
> Pertama untuk Caching, saya jalankan `/root/test_cache.sh`.  
> Bisa dilihat di layar Kak:  
> - Pada Request 1 (akses awal): statusnya adalah `X-Cache-Status: MISS` karena konten baru pertama kali diambil dari upstream.  
> - Pada Request 2 (akses berikutnya): statusnya langsung berubah menjadi `X-Cache-Status: HIT` karena konten disajikan langsung dari penyimpanan cache lokal gojo."*

#### Step 2: Uji Rate Limiting pada `/api`
Jalankan di terminal `itadori`:
```bash
/root/test_rate_limit.sh
```
🗣️ **Yang Diucapkan ke Asprak:**
> *"Kedua untuk Rate Limiting, saya kirimkan 15 request cepat berturut-turut ke `/api`.  
> Terlihat Request 1 sampai 7 berhasil dengan status `HTTP Status: 200`.  
> Namun begitu kapasitas burst terlampaui, Request 8 sampai 15 langsung dipotong dan ditolak dengan status `HTTP Status: 503 Service Unavailable`. Ini membuktikan sistem berhasil menahan flooding request."*

### 3. Prediksi Pertanyaan Asprak & Jawaban Cerdas
- **T: Mengapa kita memakai `$binary_remote_addr` alih-alih `$remote_addr` untuk parameter `limit_req_zone`?**  
  *J: Untuk efisiensi memori. `$remote_addr` menyimpan alamat IP dalam format string teks (berukuran 7 hingga 15 byte), sedangkan `$binary_remote_addr` menyimpannya dalam format biner (hanya 4 byte untuk IPv4). Dengan biner, alokasi memori 10MB bisa menampung sekitar 160.000 sesi IP klien secara bersamaan.*

---

## Soal 20: Audit Kapasitas Layanan Menggunakan Apache Benchmark

### 1. Konsep Utama
Uji beban komprehensif (*stress testing*) dari node `kusakabe` (Network 3) menggunakan Apache Benchmark (`ab -n 600 -c 30`) untuk membuktikan keunggulan performa Caching sekaligus validitas penolakan terukur pada Rate Limiting.

### 2. Langkah Demo Live & Skrip Percakapan

#### Step 1: Benchmark Web Utama (Baseline + Caching)
Jalankan di terminal `kusakabe`:
```bash
/root/run_benchmark_root.sh
```
🗣️ **Yang Diucapkan ke Asprak:**
> *"Terakhir untuk Soal 20 Kak, kita melakukan audit kapasitas menggunakan Apache Benchmark dengan 600 total request dan 30 konkruensi.  
> Pertama pada web utama, bisa kita lihat hasilnya di layar:  
> - `Complete requests: 600`  
> - `Failed requests: 0` (100% request sukses tanpa error)  
> - Throughput mencapai **4.749 request per detik** dengan latensi rata-rata hanya 6 milidetik!  
> Performa tinggi dan zero failure ini dicapai karena respon dilayani langsung dari cache Nginx tanpa membebani server PHP backend."*

#### Step 2: Benchmark Endpoint `/api` (Proteksi Rate Limiting)
Jalankan di terminal `kusakabe`:
```bash
/root/run_benchmark_api.sh
```
🗣️ **Yang Diucapkan ke Asprak:**
> *"Kedua pada endpoint `/api` dengan beban yang sama, hasilnya menunjukkan:  
> - Terdapat **594 Non-2xx responses**.  
> - Namun perhatikan bagian bawahnya Kak: `Connect: 0`, `Receive: 0`, dan `Exceptions: 0`.  
> Ini membuktikan tidak ada kegagalan koneksi jaringan atau crash pada aplikasi; seluruh 594 request tersebut murni merupakan respons penolakan sah HTTP 503 dari kebijakan Rate Limiting kita."*

#### Step 3: Verifikasi Log Akses di Node `gojo`
Jalankan di terminal `gojo`:
```bash
tail -n 20 /var/log/nginx/access.log
```
🗣️ **Yang Diucapkan ke Asprak:**
> *"Dan sebagai penutup, kita periksa log akses di gojo. Terlihat deretan log dari IP kusakabe (192.212.3.11) dengan kode status `503` dan User-Agent `ApacheBench/2.3`. Ini membuktikan bahwa request berlebih langsung di-drop di lapisan pintu gerbang DMZ, sehingga menghemat resource komputasi dan database di jaringan dalam.*  
>  
> *Sekian demonstrasi dari saya untuk Soal 11 sampai 20 Praktikum Modul 3, terima kasih banyak Kak!"*

---
*(Dokumen ini siap dijadikan contekan saat presentasi langsung di depan asisten praktikum)*
