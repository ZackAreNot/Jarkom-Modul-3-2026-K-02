# Panduan Demo Praktikum Jarkom Modul 3 (Soal 11 - 20)
**Curtain Protocol: Shibuya Incident**  
**Presenter:** Naila Anggun Eka Rizqy (5027251122)  
**Kelompok:** K-02 (Prefix IP: `192.212.x.x` | Domain: `jujutsu.k02.com`)

---

## 📌 Tips Umum Menghadapi Asisten Praktikum (Asprak)
1. **Pahami "Mengapa", Bukan Cuma "Bagaimana"**: Asprak biasanya tidak hanya melihat perintah berjalan, tapi akan bertanya: *"Kenapa pakai parameter ini?"* atau *"Apa dampaknya kalau baris ini dihapus?"*.
2. **Buka Terminal Sesuai Urutan**: Buka tab terminal node-node penting terlebih dahulu:
   - `utahime` & `shoko` (DNS)
   - `yaga` & `inumaki` (Database)
   - `gojo` (Public Reverse Proxy DMZ)
   - `geto` (Internal Load Balancer Data Center)
   - `nanami` / `todo` / `kirara` (API Workers)
   - `itadori` (Klien Network 2) & `kusakabe` (Klien Network 3)
3. **Gunakan Script Helper yang Sudah Tersedia**: Di node-node klien dan server sudah dibuatkan script otomatis untuk mempermudah eksekusi cepat saat demo.

---

## Soal 11: BIND9 DNS Master-Slave dengan Zone Transfer

### 1. Konsep Utama
Membangun redundansi layanan DNS. `utahime` bertindak sebagai Master Server (pemegang zona otoritatif primer), sedangkan `shoko` bertindak sebagai Slave Server yang menyalin data zona secara berkala melalui mekanisme *Zone Transfer* (AXFR).

### 2. Parameter Jaringan
- **DNS Master (`utahime`)**: `192.212.1.2`
- **DNS Slave (`shoko`)**: `192.212.1.3`
- **Zone**: `jujutsu.k02.com`

### 3. Langkah Demo Live
1. **Tunjukkan Konfigurasi di Master (`utahime`)**:
   ```bash
   cat /etc/bind/named.conf.local
   cat /etc/bind/jujutsu/jujutsu.k02.com
   ```
   *Poin yang ditunjukkan:* Direktif `allow-transfer { 192.212.1.3; };` dan `also-notify { 192.212.1.3; };`, serta serial number pada SOA record.

2. **Tunjukkan Konfigurasi di Slave (`shoko`)**:
   ```bash
   cat /etc/bind/named.conf.local
   ls -la /var/cache/bind/
   ```
   *Poin yang ditunjukkan:* Direktif `type slave;` dan `masters { 192.212.1.2; };`, serta file zona hasil transfer `db.jujutsu.k02.com` di direktori cache BIND.

3. **Uji Resolusi DNS dari Klien (`itadori`)**:
   ```bash
   # Uji query ke Master
   dig @192.212.1.2 jujutsu.k02.com
   # Uji query ke Slave
   dig @192.212.1.3 jujutsu.k02.com
   ```

### 4. Output yang Diharapkan
- Status query: `status: NOERROR`
- Bagian `ANSWER SECTION` mengembalikan A record yang valid (`jujutsu.k02.com. IN A 192.212.1.4`).
- Nilai serial number di Master dan Slave identik.

### 5. Prediksi Pertanyaan Asprak & Jawaban Cerdas
- **T: Apa fungsi serial number pada SOA record?**  
  *J: Sebagai penanda versi database zona. Saat Master memperbarui zona dan menaikkan serial number, Slave membandingkan serial tersebut. Jika serial di Master lebih besar, Slave akan meminta zone transfer.*
- **T: Mengapa transfer zona harus dibatasi dengan `allow-transfer`?**  
  *J: Untuk keamanan (prevent DNS zone walking). Tanpa `allow-transfer`, pihak luar dapat mendownload seluruh daftar host dan struktur jaringan internal kita menggunakan query AXFR.*

---

## Soal 12: DNS Record (A & CNAME), Reverse PTR, dan DNS Forwarder

### 1. Konsep Utama
Melengkapi DNS dengan pemetaan alias (*CNAME*), pemetaan balik IP ke Domain (*Reverse DNS / PTR*), serta meneruskan query domain eksternal/internet ke gateway (*Forwarder*).

### 2. Parameter Jaringan
- **A Record**: `gojo` -> `192.212.1.4`
- **CNAME**: `www.jujutsu.k02.com` -> `jujutsu.k02.com`
- **Reverse Zone**: `1.212.192.in-addr.arpa` -> `gojo.jujutsu.k02.com`
- **DNS Forwarder**: `192.168.122.1`

### 3. Langkah Demo Live (di Klien `itadori`)
1. **Uji Record CNAME**:
   ```bash
   dig @192.212.1.2 www.jujutsu.k02.com
   ```
   *Tunjukkan:* Baris `CNAME` mengarah ke `jujutsu.k02.com` dan diterjemahkan ke IP `192.212.1.4`.

2. **Uji Reverse DNS (PTR)**:
   ```bash
   dig @192.212.1.2 -x 192.212.1.4
   ```
   *Tunjukkan:* Bagian ANSWER menghasilkan `4.1.212.192.in-addr.arpa. IN PTR gojo.jujutsu.k02.com.`.

3. **Uji DNS Forwarder**:
   ```bash
   dig @192.212.1.2 google.com
   ping -c 2 google.com
   ```
   *Tunjukkan:* Domain internet publik berhasil di-resolve melalui `utahime` berkat forwarder `192.168.122.1`.

### 4. Prediksi Pertanyaan Asprak & Jawaban Cerdas
- **T: Mengapa reverse DNS menggunakan domain khusus `in-addr.arpa` dan oktet IP-nya dibalik?**  
  *J: DNS membaca hirarki dari kanan ke kiri (TLD ke host). Alamat IP `192.212.1.4` memiliki segmen network di awal, sehingga harus dibalik menjadi `4.1.212.192.in-addr.arpa` agar sesuai dengan struktur pohon DNS (arpa -> in-addr -> 192 -> 212 -> 1 -> host 4).*
- **T: Apa perbedaan Forwarder dengan Root Hints?**  
  *J: Forwarder langsung meneruskan recursive query ke server perantara (seperti ISP/gateway), sedangkan Root Hints menelusuri dari root name server dunia secara iteratif.*

---

## Soal 13: Replikasi Database MariaDB Master-Slave

### 1. Konsep Utama
Menjamin konsistensi data secara asinkron antara database utama (`yaga`) dan cadangan (`inumaki`). Setiap transaksi tulis di Master dicatat dalam *Binary Log* dan dieksekusi ulang di Slave melalui *I/O Thread* dan *SQL Thread*.

### 2. Parameter Jaringan
- **Master (`yaga`)**: `192.212.4.8` (server-id: 1)
- **Slave (`inumaki`)**: `192.212.4.9` (server-id: 2)
- **Database & User**: `db_shibuya_k02`, user `replica`@`%`

### 3. Langkah Demo Live
1. **Cek Status Master di `yaga`**:
   ```bash
   mariadb -e "SHOW MASTER STATUS\G"
   ```
   *Tunjukkan:* Nilai `File` (misal `mariadb-bin.000001`) dan `Position`.

2. **Cek Status Slave di `inumaki`**:
   ```bash
   mariadb -e "SHOW SLAVE STATUS\G"
   ```
   *Poin krusial yang ditunjukkan ke Asprak:*
   - `Slave_IO_Running: Yes` (I/O thread berhasil konek ke Master dan membaca binlog).
   - `Slave_SQL_Running: Yes` (SQL thread berhasil mengeksekusi event log ke database lokal).
   - `Seconds_Behind_Master: 0` (tidak ada lag replikasi).

3. **Uji Replikasi Data**:
   - Di `yaga`:
     ```bash
     mariadb -e "INSERT INTO db_shibuya_k02.request_logs (worker_name, client_ip, proxy_ip, user_agent) VALUES ('test-master', '127.0.0.1', '127.0.0.1', 'demo-test');"
     ```
   - Di `inumaki`:
     ```bash
     mariadb -e "SELECT * FROM db_shibuya_k02.request_logs WHERE worker_name='test-master';"
     ```
   *Tunjukkan:* Data langsung muncul di `inumaki` secara real-time!

### 4. Prediksi Pertanyaan Asprak & Jawaban Cerdas
- **T: Apa peran masing-masing dari Slave_IO_Running dan Slave_SQL_Running?**  
  *J: `Slave_IO_Running` bertugas menghubungkan Slave ke Master, membaca event baru dari binlog Master, dan menyimpannya ke Relay Log Slave. `Slave_SQL_Running` membaca Relay Log lokal tersebut dan mengeksekusinya ke tabel database Slave.*

---

## Soal 14: Frontend & API Workers + Access Control List (ACL)

### 1. Konsep Utama
Pemisahan peran worker dan pengamanan lapis dalam (*defense in depth*). Worker tidak boleh diakses secara langsung dari subnet klien (Divisi A / Divisi B), melainkan wajib melalui Reverse Proxy (`gojo`) atau Load Balancer (`geto`).

### 2. Pembagian Worker
- **Frontend Workers**: `maki` (`192.212.4.3`) & `panda` (`192.212.4.4`) -> Nginx + PHP-FPM web portal.
  - *ACL:* `allow 192.212.1.4; allow 192.212.4.0/24; allow 127.0.0.1; allow ::1; deny all;`
- **API Workers**: `nanami` (`192.212.4.5`), `todo` (`192.212.4.6`), `kirara` (`192.212.4.7`) -> Nginx + PHP API service.
  - *ACL:* `allow 192.212.4.2; allow 192.212.4.0/24; allow 127.0.0.1; allow ::1; deny all;`

### 3. Langkah Demo Live
1. **Buktikan Blokir Akses Langsung (dari Klien `itadori`)**:
   ```bash
   curl -i http://192.212.4.3/
   curl -i http://192.212.4.5/
   ```
   *Tunjukkan:* Respons **`HTTP/1.1 403 Forbidden`**! Klien dilarang bypass proxy.

2. **Buktikan Akses Diizinkan dari Proxy yang Sah**:
   - Dari terminal `gojo`:
     ```bash
     curl -s http://192.212.4.3/ | grep -A 2 "Worker Hostname"
     ```
     *Tunjukkan:* Respons **`200 OK`** menampilkan `Worker Hostname: maki`.
   - Dari terminal `geto`:
     ```bash
     curl -s http://192.212.4.5/
     ```
     *Tunjukkan:* Respons **`200 OK`** JSON API dari `nanami`.

### 4. Prediksi Pertanyaan Asprak & Jawaban Cerdas
- **T: Mengapa konfigurasi ACL ditaruh di level web server worker, padahal sudah ada router gateway?**  
  *J: Sebagai prinsip Defense in Depth (keamanan berlapis). Jika penyerang berhasil menembus atau melakukan spoofing pada jaringan router, server backend tetap terlindungi oleh policy access control Nginx.*

---

## Soal 15: Internal Load Balancer Weighted Round Robin (3:1)

### 1. Konsep Utama
Distribusi beban trafik API di Data Center menggunakan `geto` dengan pembobotan kapasitas: `nanami` menangani 3 request untuk setiap 1 request yang ditangani `todo` (rasio 75% : 25%).

### 2. Node & Upstream
- **Load Balancer (`geto`)**: `192.212.4.2`
- **Upstream `api_cluster`**:
  - `server 192.212.4.5:80 weight=3;` (`nanami`)
  - `server 192.212.4.6:80 weight=1;` (`todo`)

### 3. Langkah Demo Live (di Node `geto`)
1. **Tunjukkan Konfigurasi Upstream**:
   ```bash
   cat /etc/nginx/sites-available/default
   ```
   *Sorot:* Baris `upstream api_cluster` dengan direktif `weight=3` dan `weight=1`.

2. **Jalankan Pengujian Rasio**:
   ```bash
   /root/test_ratio.sh
   ```
   *(Atau script loop 40 request: `for i in $(seq 1 40); do curl -s http://localhost/ | grep '"worker"'; done | sort | uniq -c`)*

### 4. Output yang Diharapkan
- Dari 40 request yang dikirimkan:
  - `nanami`: tepat **30 request** (75%)
  - `todo`: tepat **10 request** (25%)
- Rasio terbukti presisi **3 : 1**.

### 5. Prediksi Pertanyaan Asprak & Jawaban Cerdas
- **T: Kapan Weighted Round Robin lebih dipilih dibandingkan Least Connections?**  
  *J: Weighted Round Robin ideal saat karakteristik request seragam (komputasi serupa) tetapi hardware/spesifikasi server berbeda (misal server A punya CPU 3x lebih kuat dari server B). Least Connections lebih cocok jika durasi tiap request sangat bervariasi.*

---

## Soal 16: Public Reverse Proxy & Path-Based Routing

### 1. Konsep Utama
`gojo` berfungsi sebagai gerbang tunggal (*Single Point of Contact*) di zona DMZ. Ia melakukan inspeksi Layer 7 pada URI path: request `/` diarahkan ke frontend cluster, sedangkan `/api` diteruskan ke internal load balancer `geto`.

### 2. Konfigurasi Routing pada `gojo` (`/etc/nginx/sites-available/default`)
- `upstream frontend_cluster { server 192.212.4.3:80; server 192.212.4.4:80; }`
- `location /` -> `proxy_pass http://frontend_cluster;`
- `location /api` -> `proxy_pass http://192.212.4.2;`

### 3. Langkah Demo Live (dari Klien `itadori`)
1. **Uji Path Root (`/`)**:
   ```bash
   curl -s http://jujutsu.k02.com/ | grep -A 2 "Worker Hostname"
   curl -s http://jujutsu.k02.com/ | grep -A 2 "Worker Hostname"
   ```
   *Tunjukkan:* Respon menampilkan halaman HTML dan worker bergantian antara `maki` dan `panda` (Round Robin).

2. **Uji Path API (`/api`)**:
   ```bash
   curl -s http://jujutsu.k02.com/api
   ```
   *Tunjukkan:* Respon langsung mengembalikan data JSON dari kluster API backend (`nanami` / `todo`).

### 4. Prediksi Pertanyaan Asprak & Jawaban Cerdas
- **T: Apa keuntungan menaruh Reverse Proxy di DMZ dibandingkan membiarkan klien langsung mengakses Data Center?**  
  *J: Isolasi jaringan. Klien luar tidak pernah mengetahui IP asli server aplikasi/database di Data Center. Reverse Proxy juga menjadi tempat sentral untuk SSL termination, caching, dan filtering serangan.*

---

## Soal 17: Preservasi Real Client IP & Database Logging

### 1. Konsep Utama
Karena request melewati 2 lapis proxy (`gojo` -> `geto`), IP asal klien berisiko tertutup menjadi IP proxy. Melalui modul `ngx_http_realip_module` pada `geto` dan forwarding header, IP asli klien dipertahankan dan diverifikasi hanya dari proxy terpercaya, lalu disimpan permanen ke database MariaDB `yaga`.

### 2. Direktif Kunci di `geto`
- `set_real_ip_from 192.212.1.4;` (Hanya percaya header dari `gojo`)
- `real_ip_header X-Forwarded-For;`
- `real_ip_recursive on;`

### 3. Langkah Demo Live
1. **Tunjukkan Konfigurasi Trusted Proxy di `geto`**:
   ```bash
   cat /etc/nginx/sites-available/default
   ```
   *Sorot blok `set_real_ip_from 192.212.1.4`.*

2. **Kirim Request dari Klien Berbeda**:
   - Dari `itadori` (Network 2: `192.212.2.10`):
     ```bash
     /root/test_api_client.sh
     ```
     *Tunjukkan output JSON:* `"client_ip": "192.212.2.10"` dan `"proxy_ip": "192.212.4.2"`.
   - Dari `kusakabe` (Network 3: `192.212.3.11`):
     ```bash
     /root/test_api_client.sh
     ```
     *Tunjukkan output JSON:* `"client_ip": "192.212.3.11"`.

3. **Periksa Pencatatan Database di Node `yaga`**:
   ```bash
   /root/check_db_logs.sh
   ```
   *(Atau: `mariadb -e "SELECT id, worker_name, client_ip, proxy_ip, created_at FROM db_shibuya_k02.request_logs;"`)*

### 4. Output yang Diharapkan
Tabel `request_logs` mencatat alamat IP asli klien secara akurat:
- Baris Network 2: `client_ip = 192.212.2.10`
- Baris Network 3: `client_ip = 192.212.3.11`
- Kolom `proxy_ip = 192.212.4.2` (`geto`)

### 5. Prediksi Pertanyaan Asprak & Jawaban Cerdas
- **T: Mengapa harus ada `set_real_ip_from`? Mengapa tidak langsung percaya saja pada header `X-Forwarded-For` dari request masuk?**  
  *J: Untuk mencegah IP Spoofing. Jika tidak dibatasi dengan `set_real_ip_from`, penyerang bisa mengirimkan header palsu `X-Forwarded-For: 8.8.8.8`, dan server akan mempercayai IP palsu tersebut. Dengan `set_real_ip_from`, Nginx hanya mengganti remote address jika request datang dari proxy internal yang terpercaya.*

---

## Soal 18: High Availability, Passive Health Check & Failover

### 1. Konsep Utama
Toleransi kesalahan (*fault tolerance*) pada kluster API. Jika seluruh worker utama (`nanami` dan `todo`) gagal merespons, trafik secara otomatis dialihkan ke server cadangan (*hot-standby*) `kirara` tanpa memunculkan error 502 Bad Gateway di sisi pengguna.

### 2. Parameter Health Check pada `geto`
- `max_fails=2`: Server ditandai *down* jika gagal 2 kali berturut-turut.
- `fail_timeout=5s`: Durasi suspend/penalti selama 5 detik sebelum dicoba kembali.
- `backup`: Menandai `kirara` hanya aktif jika worker utama semuanya *down*.

### 3. Langkah Demo Live
1. **Tunjukkan Konfigurasi di `geto`**:
   ```bash
   grep -A 7 "upstream api_cluster" /etc/nginx/sites-available/default
   ```

2. **Simulasikan Gangguan Total pada Worker Utama**:
   - Di terminal `nanami`:
     ```bash
     service nginx stop
     ```
   - Di terminal `todo`:
     ```bash
     service nginx stop
     ```

3. **Kirim Request dari Klien (`itadori`)**:
   ```bash
   curl -s http://jujutsu.k02.com/api
   ```
   *Sorot bagian respon JSON:*
   - `"worker": "kirara"`
   - `"status": "success"`
   - Tidak ada error `502 Bad Gateway`.

4. **Kembalikan Layanan Normal (Recovery)**:
   - Di `nanami`: `service nginx start`
   - Di `todo`: `service nginx start`
   - Kirim request lagi dari `itadori`: trafik langsung kembali ke `nanami` dan `todo`!

### 4. Prediksi Pertanyaan Asprak & Jawaban Cerdas
- **T: Apa perbedaan Passive Health Check dengan Active Health Check?**  
  *J: Passive Health Check memantau kesehatan server berdasarkan request nyata dari klien (jika request klien gagal hingga batas max_fails, server dinonaktifkan sementara). Active Health Check secara periodik mengirimkan probe/heartbeat sendiri ke backend terlepas ada trafik klien atau tidak (fitur ini memerlukan modul komersial Nginx Plus).*

---

## Soal 19: Nginx Proxy Caching & Rate Limiting

### 1. Konsep Utama
Dua fitur optimasi dan proteksi pada `gojo`:
1. **Proxy Caching**: Menyimpan respon halaman frontend di cache disk/memori `gojo` selama 10 menit untuk mempercepat akses dan menghemat beban server backend.
2. **Rate Limiting**: Membatasi kuota request ke `/api` maksimal 10 request/detik per IP klien untuk mencegah brute-force atau spamming.

### 2. Langkah Demo Live (di Klien `itadori`)
1. **Uji Caching Frontend (MISS lalu HIT)**:
   ```bash
   /root/test_cache.sh
   ```
   *Poin yang ditunjukkan ke Asprak:*
   - Request 1: Terdapat header **`X-Cache-Status: MISS`** (konten diambil dari backend).
   - Request 2: Terdapat header **`X-Cache-Status: HIT`** (konten disajikan instan dari cache proxy).

2. **Uji Rate Limiting pada `/api`**:
   ```bash
   /root/test_rate_limit.sh
   ```
   *Poin yang ditunjukkan ke Asprak:*
   - Request 1 sampai 7 menghasilkan status **`HTTP Status: 200`**.
   - Begitu batas burst terlampaui, Request 8 sampai 15 langsung ditolak dengan status **`HTTP Status: 503`** (Service Temporarily Unavailable).

### 3. Prediksi Pertanyaan Asprak & Jawaban Cerdas
- **T: Mengapa kita memakai `$binary_remote_addr` alih-alih `$remote_addr` untuk `limit_req_zone`?**  
  *J: Efisiensi memori. `$remote_addr` menyimpan IP sebagai string (7 hingga 15 byte untuk IPv4), sedangkan `$binary_remote_addr` menyimpannya dalam representasi biner 4 byte untuk IPv4 (atau 16 byte untuk IPv6), sehingga zona memori 10MB bisa menampung jauh lebih banyak sesi IP klien.*

---

## Soal 20: Audit Kapasitas Layanan Menggunakan Apache Benchmark

### 1. Konsep Utama
Uji beban stres (*load testing*) dari node `kusakabe` untuk memvalidasi performa web bertaraf tinggi (berkat Caching) serta membuktikan penolakan terukur pada endpoint API (berkat Rate Limiting).

### 2. Parameter Audit
- Alat: `ab` (ApacheBench) dari `kusakabe` (`192.212.3.11`)
- Beban: `-n 600` (total 600 request), `-c 30` (30 koneksi konkruen)

### 3. Langkah Demo Live
1. **Audit Web Utama di `kusakabe`**:
   ```bash
   /root/run_benchmark_root.sh
   ```
   *Tunjukkan metrik utama ke Asprak:*
   - `Complete requests: 600`
   - **`Failed requests: 0`** (100% sukses!)
   - **`Requests per second: ~4700 - 5600 [#/sec]`**
   - `Time per request: ~6 ms`
   *Penjelasan:* Performa tinggi dan 0 failure tercapai karena request dilayani sepenuhnya dari cache memory `gojo`.

2. **Audit Endpoint API di `kusakabe`**:
   ```bash
   /root/run_benchmark_api.sh
   ```
   *Tunjukkan metrik utama ke Asprak:*
   - `Complete requests: 600`
   - **`Non-2xx responses: ~594`**
   - **`Connect: 0, Receive: 0, Exceptions: 0`**
   *Penjelasan krusial:* Tekankan bahwa `Connect: 0` dan `Exceptions: 0` membuktikan **tidak ada server atau koneksi yang crash**. 594 request tersebut murni ditolak secara sengaja oleh kebijakan Rate Limiting (status 503).

3. **Verifikasi Log Akses di `gojo`**:
   ```bash
   tail -n 20 /var/log/nginx/access.log
   ```
   *Tunjukkan:* Baris-baris log request dari `192.212.3.11` dengan status kode `503 190` dan User-Agent `ApacheBench/2.3`.

### 4. Ringkasan Komparasi untuk Penutup Presentasi
*"Berdasarkan hasil audit kapasitas, arsitektur Curtain Protocol terbukti tangguh: layanan frontend mampu melayani lebih dari 4.700 request per detik dengan 0% kegagalan, sementara layanan API terlindungi secara ketat dari serangan banjir request dengan menjatuhkan kelebihan beban langsung di gerbang proxy, tanpa membebani database internal."*

---
*(Dokumen ini siap dijadikan contekan saat presentasi langsung di depan asisten praktikum)*
