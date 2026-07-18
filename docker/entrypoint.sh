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

echo "Disabling obsolete Composer dependency enforcement..."
echo '{}' > "${PORTAL_ROOT}/deploy/composer.json"
echo '{}' > "${PORTAL_ROOT}/deploy/ministra/composer.json"

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

echo "Applying packaged server customizations..."
EPG_TARGET="$(find "${PORTAL_ROOT}/server" -type f -iname 'epg.class.php' -print -quit)"
if [ -z "$EPG_TARGET" ]; then
  echo "ERROR: could not locate the deployed EPG server class."
  exit 1
fi
echo "Installing EPG server customization at ${EPG_TARGET}"
install -m 0644 /opt/mac-portal-overrides/server/lib/epg.class.php "$EPG_TARGET"
if ! cmp -s /opt/mac-portal-overrides/server/lib/epg.class.php "$EPG_TARGET"; then
  echo "ERROR: failed to install the packaged EPG server customization."
  exit 1
fi

echo "Starting services..."
service memcached start || true
service apache2 stop || true
killall -9 apache2 2>/dev/null || true
rm -f /var/run/apache2/apache2.pid

exec /usr/sbin/apache2ctl -D FOREGROUND
