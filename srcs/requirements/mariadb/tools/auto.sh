#!/bin/sh
set -eu

# Read secrets from files
if [ -f /run/secrets/db_password ]; then
    DB_PASSWORD=$(cat /run/secrets/db_password)
else
    echo "ERROR: db_password secret not found!"
    exit 1
fi

if [ -f /run/secrets/db_root_password ]; then
    DB_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)
else
    echo "ERROR: db_root_password secret not found!"
    exit 1
fi

mkdir -p /run/mysqld
chown -R mysql:mysql /run/mysqld
chown -R mysql:mysql /var/lib/mysql


MARIADB_DAEMON="mysqld_safe"

SOCKET="/run/mysqld/mysqld.sock"


if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo ">>>>>>>>>>>>>>Initializing MySQL data directory..."
    mariadb-install-db --user=mysql --datadir=/var/lib/mysql
fi

echo ">>>>>>>>>>>>>>Start MariaDB in background"
$MARIADB_DAEMON --user=mysql --skip-networking --socket=$SOCKET &

MYSQL_PID=$!

echo ">>>>>>>>>>>>>>Waiting for MariaDB to be ready..."

until mysqladmin  --socket=$SOCKET ping --silent >/dev/null 2>&1 \
	|| mysqladmin --socket=$SOCKET -uroot -p"${DB_ROOT_PASSWORD}" ping --silent >/dev/null 2>&1
do
	echo ">>>>>>>>>>>>>>Sleeping..."
	sleep 1;
done

echo ">>>>>>>>>>>>>>MariaDB is up!"

MARIADB="mariadb -u root --socket=$SOCKET"
if mysqladmin --socket=$SOCKET ping --silent >/dev/null 2>&1; then
	MARIADB="mariadb -u root -p${DB_ROOT_PASSWORD} --socket=${SOCKET}"
fi

echo "MARIADB COMMAND: ${MARIADB}"
echo ">>>>>>>>>>>>>>Create database and its user and alter root"
${MARIADB} << EOF
CREATE DATABASE IF NOT EXISTS ${DB_NAME};
CREATE USER IF NOT EXISTS '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'%';
ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASSWORD}';
FLUSH PRIVILEGES;
EOF

echo ">>>>>>>>>>>>>>Stopping temporary MariaDB instance..."
mysqladmin --socket=$SOCKET -uroot -p"${DB_ROOT_PASSWORD}" shutdown
wait $MYSQL_PID

echo ">>>>>>>>>>>>>>Starting MariaDB server..."
exec $MARIADB_DAEMON --user=mysql