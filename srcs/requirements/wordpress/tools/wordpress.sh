#!/bin/sh

set -eu

echo "Reading secrets..."

if [ ! -f /run/secrets/db_password ]; then
    echo "ERROR: db_password secret not found!"
    exit 1
fi

if [ ! -f /run/secrets/wp_admin_password ]; then
    echo "ERROR: wp_admin_password secret not found!"
    exit 1
fi

if [ ! -f /run/secrets/wp_user_password ]; then
    echo "ERROR: wp_user_password secret not found!"
    exit 1
fi

# Read passwords from secret files
DB_PASSWORD=$(cat /run/secrets/db_password)
WP_ADMIN_PASSWORD=$(cat /run/secrets/wp_admin_password)
WP_USER_PASSWORD=$(cat /run/secrets/wp_user_password)


echo "Secrets loaded successfully!"

if [ ! -f wp-settings.php ]; then
    echo ">>>>>>>>>>>>>>Downloading WordPress..."
    wp core download --allow-root
else
    echo ">>>>>>>>>>>>>>WordPress Already Downloaded!"
fi


echo ">>>>>>>>>>>>>>Waiting for mariadb..."
while ! /usr/bin/mariadb-admin ping -h "${DB_HOST}" -u "${DB_USER}" -p"${DB_PASSWORD}" --silent; do
	echo ">>>>>>>>>>>>>>Database is unavailable - sleeping..."
	sleep 2
done


if [ ! -f wp-config.php ]; then
    echo "Creating wp-config.php..."
    
    # Create wp-config.php using WP-CLI
    wp config create \
        --dbname="${DB_NAME}" \
        --dbuser="${DB_USER}" \
        --dbpass="${DB_PASSWORD}" \
        --dbhost="${DB_HOST_PORT}" \
        --locale=en_US \
        --allow-root
    
    echo "✅ wp-config.php created!"
    
    # ========================================
    # ADD SECURITY SETTINGS
    # ========================================
    echo "Adding security settings..."
    wp config set FORCE_SSL_ADMIN true --raw --allow-root
    wp config set FORCE_SSL_LOGIN true --raw --allow-root
    
    # ========================================
    # GENERATE SECURITY KEYS
    # ========================================
    echo "Generating WordPress security keys..."
    wp config shuffle-salts --allow-root
    
    echo "✅ Configuration complete!"
else
    echo "✅ wp-config.php already exists!"
fi


if ! wp core is-installed --allow-root; then
    echo ">>>>>>>>>>>>>>Installing Wordpress..."
        wp core install \
        --url="${URL}" \
        --title="${TITLE}" \
        --admin_user="${WP_ADMIN_USER}" \
        --admin_password="${WP_ADMIN_PASSWORD}" \
        --admin_email="${WP_ADMIN_EMAIL}" \
        --skip-email --allow-root

else
    echo ">>>>>>>>>>>>>>Wordpress Already Installed!"
fi


# ================================================================
# CREATE ADDITIONAL AUTHOR USER
# ================================================================
if [ -n "${WP_USER:-}" ] && [ -n "${WP_USER_EMAIL:-}" ]; then
    if ! wp user get "${WP_USER}" --field=ID --allow-root >/dev/null 2>&1; then
        echo "Creating additional WordPress user ${WP_USER} with role ${WP_ROLE:-author}..."
        wp user create "${WP_USER}" "${WP_USER_EMAIL}" \
            --role="${WP_ROLE:-author}" \
            --user_pass="${WP_USER_PASSWORD}" \
            --allow-root
    else
        echo "User ${WP_USER} already exists, skipping creation."
    fi
fi


# ================================================================
# FIX PERMISSIONS (MOVED TO END, BEFORE PHP-FPM STARTS)
# ================================================================
echo ">>> Fixing file permissions..."
chown -R www-data:www-data /var/www/html/
find /var/www/html/ -type d -exec chmod 755 {} \;
find /var/www/html/ -type f -exec chmod 644 {} \;
chmod -R 775 /var/www/html/wp-content/
chmod 640 /var/www/html/wp-config.php 2>/dev/null || true
echo "✅ Permissions fixed!"

exec php-fpm8.2 -F