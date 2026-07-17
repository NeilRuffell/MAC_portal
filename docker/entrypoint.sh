#!/bin/bash
set -u

PORTAL_ROOT="/var/www/html/stalker_portal"
CONFIG="${PORTAL_ROOT}/server/config.ini"
CUSTOM="${PORTAL_ROOT}/server/custom.ini"
BUILD="${PORTAL_ROOT}/deploy/build.xml"

echo "Stopping bundled MySQL if present..."
service mysql stop || true

echo "Waiting for MySQL..."
until mysqladmin ping -h "${STALKER_DB_HOST:-stalker-db}" -u root -p"${STALKER_DB_PASSWORD}" --silent; do
  sleep 2
done

echo "Configuring portal database..."
sed -i "s|mysql_host = .*|mysql_host = ${STALKER_DB_HOST:-stalker-db}|g" "$CONFIG"
sed -i "s|mysql_db = .*|mysql_db = ${STALKER_DB_NAME:-stalker_db}|g" "$CONFIG"
sed -i "s|mysql_user = .*|mysql_user = root|g" "$CONFIG"
sed -i "s|mysql_pass = .*|mysql_pass = ${STALKER_DB_PASSWORD}|g" "$CONFIG"
sed -i "s|default_locale = .*|default_locale = en_GB.utf8|g" "$CONFIG"

touch "$CUSTOM"
sed -i "/^default_language = /d" "$CUSTOM"
echo "default_language = en" >> "$CUSTOM"

echo "Patching legacy deploy script..."
sed -i "s|mysql -u root -p|mysql -h ${STALKER_DB_HOST:-stalker-db} -u root -p${STALKER_DB_PASSWORD}|g" "$BUILD"
sed -i "s|mysql -u root|mysql -h ${STALKER_DB_HOST:-stalker-db} -u root -p${STALKER_DB_PASSWORD}|g" "$BUILD"
sed -i 's|apt-get update 2>&1|env DEBIAN_FRONTEND=noninteractive apt-get update -y 2>&1|g' "$BUILD"
sed -i 's|apt-get -y install|env DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold install|g' "$BUILD"
sed -i 's#command=".*init_apps.php.*"#command="timeout --kill-after=10s 180s php ${project_path}/server/tools/init_apps.php || true"#g' "$BUILD"
sed -i 's|command=".*change_permissions.php.*"|command="echo Skipping change_permissions"|g' "$BUILD"
sed -i 's#command="php ${project_path}/deploy/composer/composer.phar install"#command="echo Skipping obsolete Composer install"#g' "$BUILD"

echo "Disabling obsolete Composer dependency enforcement..."
echo '{}' > "${PORTAL_ROOT}/deploy/composer.json"
rm -f "${PORTAL_ROOT}/deploy/composer.lock"
if [ -d "${PORTAL_ROOT}/deploy/ministra" ]; then
  echo '{}' > "${PORTAL_ROOT}/deploy/ministra/composer.json"
  rm -f "${PORTAL_ROOT}/deploy/ministra/composer.lock"
fi

echo "Reducing old PHP notice noise..."
if ! grep -q "E_DEPRECATED" "${PORTAL_ROOT}/admin/app.php"; then
  sed -i 's|\\E_ALL|\\E_ALL \& ~\\E_DEPRECATED \& ~\\E_USER_DEPRECATED \& ~\\E_NOTICE \& ~\\E_STRICT|g' "${PORTAL_ROOT}/admin/app.php" || true
fi

echo "Running portal deployment..."
cd "${PORTAL_ROOT}/deploy"
BUILD_STATUS=0
phing build || BUILD_STATUS=$?

if [ "$BUILD_STATUS" -ne 0 ]; then
  echo "WARNING: deployment returned ${BUILD_STATUS}; starting Apache anyway."
fi

echo "Starting services..."
service memcached start || true
echo "ServerName localhost" > /etc/apache2/conf-available/servername.conf
a2enconf servername >/dev/null 2>&1 || true
service apache2 stop || true
killall -9 apache2 2>/dev/null || true
rm -f /var/run/apache2/apache2.pid

exec /usr/sbin/apache2ctl -D FOREGROUND
