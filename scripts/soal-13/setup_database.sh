#!/bin/bash
# setup_database.sh — MariaDB Master-Slave Replication Configuration for Modul 3 (K-02)
# Usage:
#   bash setup_database.sh master
#   bash setup_database.sh slave [master_ip] [log_file] [log_pos]

set -e

ROLE="${1:-master}"
MASTER_IP="${2:-192.212.4.8}"
LOG_FILE="$3"
LOG_POS="$4"
DB_NAME="db_shibuya_k02"

echo "=== [MariaDB Setup] Role: $ROLE ==="

# 1. Pastikan paket terpasang
if ! which mariadb >/dev/null 2>&1 && ! which mysqld >/dev/null 2>&1; then
    echo "[+] Memasang MariaDB Server & Client..."
    DEBIAN_FRONTEND=noninteractive apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y mariadb-server mariadb-client
fi

# Pastikan direktori log mysql tersedia
mkdir -p /var/log/mysql
chown -R mysql:mysql /var/log/mysql || true

if [ "$ROLE" = "master" ]; then
    echo "[+] Mengonfigurasi MariaDB Master (yaga)..."
    
    # Edit /etc/mysql/mariadb.conf.d/50-server.cnf jika ada
    if [ -f /etc/mysql/mariadb.conf.d/50-server.cnf ]; then
        sed -i 's/^bind-address.*/bind-address = 0.0.0.0/' /etc/mysql/mariadb.conf.d/50-server.cnf
    fi

    cat << 'EOF' > /etc/mysql/mariadb.conf.d/60-replication.cnf
[mysqld]
bind-address            = 0.0.0.0
server-id               = 1
log_bin                 = /var/log/mysql/mariadb-bin
binlog_do_db            = db_shibuya_k02
expire_logs_days        = 10
max_binlog_size         = 100M
EOF

    echo "[+] Menjalankan/Restart MariaDB..."
    service mariadb restart || /etc/init.d/mariadb restart

    # Tunggu MariaDB siap
    until mysqladmin ping --silent >/dev/null 2>&1; do
        sleep 1
    done

    echo "[+] Menyiapkan Database, Tabel, dan Hak Akses..."
    mariadb << 'EOSQL'
CREATE DATABASE IF NOT EXISTS db_shibuya_k02;
USE db_shibuya_k02;

CREATE TABLE IF NOT EXISTS request_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    worker_name VARCHAR(50) NOT NULL,
    client_ip VARCHAR(50) NOT NULL,
    proxy_ip VARCHAR(50) NOT NULL,
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- User Replikasi untuk Slave (inumaki)
CREATE USER IF NOT EXISTS 'replica'@'%' IDENTIFIED BY 'shibuya_replica';
GRANT REPLICATION SLAVE ON *.* TO 'replica'@'%';

-- Hak akses remote bagi seluruh node di Network 4
CREATE USER IF NOT EXISTS 'kelompok'@'%' IDENTIFIED BY 'password123';
GRANT ALL PRIVILEGES ON db_shibuya_k02.* TO 'kelompok'@'%';

CREATE USER IF NOT EXISTS 'kelompok'@'192.212.4.%' IDENTIFIED BY 'password123';
GRANT ALL PRIVILEGES ON db_shibuya_k02.* TO 'kelompok'@'192.212.4.%';

CREATE USER IF NOT EXISTS 'jujutsu_user'@'%' IDENTIFIED BY 'jujutsu_pass';
GRANT ALL PRIVILEGES ON db_shibuya_k02.* TO 'jujutsu_user'@'%';

CREATE USER IF NOT EXISTS 'jujutsu_user'@'192.212.4.%' IDENTIFIED BY 'jujutsu_pass';
GRANT ALL PRIVILEGES ON db_shibuya_k02.* TO 'jujutsu_user'@'192.212.4.%';

CREATE USER IF NOT EXISTS 'root'@'%' IDENTIFIED BY 'root';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;

FLUSH PRIVILEGES;
EOSQL

    echo "[OK] Master MariaDB siap!"
    mariadb -e "SHOW MASTER STATUS;"

elif [ "$ROLE" = "slave" ]; then
    echo "[+] Mengonfigurasi MariaDB Slave (inumaki)..."

    if [ -f /etc/mysql/mariadb.conf.d/50-server.cnf ]; then
        sed -i 's/^bind-address.*/bind-address = 0.0.0.0/' /etc/mysql/mariadb.conf.d/50-server.cnf
    fi

    cat << 'EOF' > /etc/mysql/mariadb.conf.d/60-replication.cnf
[mysqld]
bind-address            = 0.0.0.0
server-id               = 2
EOF

    echo "[+] Menjalankan/Restart MariaDB..."
    service mariadb restart || /etc/init.d/mariadb restart

    # Tunggu MariaDB siap
    until mysqladmin ping --silent >/dev/null 2>&1; do
        sleep 1
    done

    # Buat database & tabel jika belum ada
    mariadb << 'EOSQL'
CREATE DATABASE IF NOT EXISTS db_shibuya_k02;
USE db_shibuya_k02;
CREATE TABLE IF NOT EXISTS request_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    worker_name VARCHAR(50) NOT NULL,
    client_ip VARCHAR(50) NOT NULL,
    proxy_ip VARCHAR(50) NOT NULL,
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
EOSQL

    # Jika LOG_FILE atau LOG_POS tidak diberikan, coba ambil otomatis dari Master jika bisa konek
    if [ -z "$LOG_FILE" ] || [ -z "$LOG_POS" ]; then
        echo "[*] Mencoba mengambil Binary Log File dan Position dari Master ($MASTER_IP)..."
        MASTER_INFO=$(mariadb -h "$MASTER_IP" -u root -proot -e "SHOW MASTER STATUS\G" 2>/dev/null || true)
        if [ -n "$MASTER_INFO" ]; then
            LOG_FILE=$(echo "$MASTER_INFO" | grep "File:" | awk '{print $2}')
            LOG_POS=$(echo "$MASTER_INFO" | grep "Position:" | awk '{print $2}')
            echo "[*] Master status terdeteksi: File=$LOG_FILE, Pos=$LOG_POS"
        fi
    fi

    if [ -n "$LOG_FILE" ] && [ -n "$LOG_POS" ]; then
        echo "[+] Mengonfigurasi Slave dengan CHANGE MASTER TO..."
        mariadb << EOSQL
STOP SLAVE;
CHANGE MASTER TO
  MASTER_HOST='$MASTER_IP',
  MASTER_USER='replica',
  MASTER_PASSWORD='shibuya_replica',
  MASTER_LOG_FILE='$LOG_FILE',
  MASTER_LOG_POS=$LOG_POS,
  MASTER_CONNECT_RETRY=10;
START SLAVE;
EOSQL
        echo "[OK] Replikasi dimulai!"
    else
        echo "[!] Peringatan: Log file/pos tidak diberikan atau tidak dapat diakses otomatis."
    fi

    mariadb -e "SHOW SLAVE STATUS\G"
fi

