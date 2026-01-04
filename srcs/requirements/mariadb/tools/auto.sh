#!/bin/bash
set -eu

DB_NAME=wordpress
DB_USER=mobouifr
DB_PASSWORD=wppassword
DB_PASS_ROOT=rootpassword

mkdir -p /run/mysqld
chown -R  mysql:mysql /run/mysqld

# Start MariaDB in the background to create users and DB
mysqld --skip-networking --user=mysql &
pid="$!"

# Wait until MariaDB is ready
until mariadb -u root -e "SELECT 1;" >/dev/null 2>&1; do
    sleep 1
done

# Only create DB/user if first run
if [ ! -f "/var/lib/mysql/.initialized" ]; then
    mariadb -u root <<EOF
CREATE DATABASE IF NOT EXISTS $DB_NAME;
CREATE USER IF NOT EXISTS '$DB_USER'@'%' IDENTIFIED BY '$DB_PASSWORD';
GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'%';
ALTER USER 'root'@'localhost' IDENTIFIED BY '$DB_PASS_ROOT';
FLUSH PRIVILEGES;
EOF
    touch /var/lib/mysql/.initialized
fi

# Stop background MariaDB safely
mysqladmin -u root -p"$DB_PASS_ROOT" shutdown 2>/dev/null || kill "$pid" || true

# Start MariaDB as PID 1
exec mysqld --user=mysql