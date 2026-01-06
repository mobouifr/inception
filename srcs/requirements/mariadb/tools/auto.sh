#!/bin/sh

# Exit on first error and on use of unset variables
set -eu

# Read application database user password from Docker secret
if [ -f /run/secrets/db_password ]; then
    DB_PASSWORD=$(cat /run/secrets/db_password)
else
    echo "ERROR: db_password secret not found!"
    exit 1
fi

# Read MariaDB root password from Docker secret
if [ -f /run/secrets/db_root_password ]; then
    DB_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)
else
    echo "ERROR: db_root_password secret not found!"
    exit 1
fi

# Prepare runtime directory for MariaDB socket and PID
mkdir -p /run/mysqld
chown -R mysql:mysql /run/mysqld

# Ensure MariaDB owns its data directory
chown -R mysql:mysql /var/lib/mysql

# Command used to run MariaDB
MARIADB_DAEMON="mysqld_safe"

# Path to MariaDB Unix socket
SOCKET="/run/mysqld/mysqld.sock"


# Initialize the data directory only on first run
if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo ">>>>>>>>>>>>>>Initializing MySQL data directory..."
    mariadb-install-db --user=mysql --datadir=/var/lib/mysql
fi

# Start a temporary MariaDB instance in the background without network access(setup mode)
echo ">>>>>>>>>>>>>>Start MariaDB in background"
$MARIADB_DAEMON --user=mysql --skip-networking --socket=$SOCKET &

# Remember PID of the temporary MariaDB process
MYSQL_PID=$!

echo ">>>>>>>>>>>>>>Waiting for MariaDB to be ready..."

# Wait until MariaDB responds on the local socket (with or without root password)
until mysqladmin  --socket=$SOCKET ping --silent >/dev/null 2>&1 \
    || mysqladmin --socket=$SOCKET -uroot -p"${DB_ROOT_PASSWORD}" ping --silent >/dev/null 2>&1
do
    echo ">>>>>>>>>>>>>>Sleeping..."
    sleep 1;
done

echo ">>>>>>>>>>>>>>MariaDB is up!"

# Helper command to execute SQL as root on the temporary instance
MARIADB="mariadb -u root -p${DB_ROOT_PASSWORD} --socket=${SOCKET}"

echo ">>>>>>>>>>>>>>Create database and its user and alter root"
${MARIADB} << EOF
CREATE DATABASE IF NOT EXISTS ${DB_NAME};
CREATE USER IF NOT EXISTS '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'%';
ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASSWORD}';
FLUSH PRIVILEGES;
EOF

# Stop the temporary MariaDB instance cleanly
echo ">>>>>>>>>>>>>>Stopping temporary MariaDB instance..."
mysqladmin --socket=$SOCKET -uroot -p"${DB_ROOT_PASSWORD}" shutdown
wait $MYSQL_PID

# Start the final MariaDB server in the foreground (container main process)
echo ">>>>>>>>>>>>>>Starting MariaDB server..."
exec $MARIADB_DAEMON --user=mysql