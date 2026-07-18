# Locale Fix Proposal

## Confirmed Problem

The client main menu gets its date/time strings from the `get_localization` API response.

The live API response was returning raw gettext keys:

```json
"date_format": "date_format",
"time_format": "time_format"
```

That explains why the client showed `date_format` before the current time.

## Confirmed Root Cause

Inside the `stalker-portal` container:

```sh
locale -a
```

showed only:

```text
C
C.UTF-8
POSIX
```

The configured locale was:

```ini
default_locale = en_GB.utf8
allowed_locales[English] = en_GB.utf8
```

But both locale probes failed:

```sh
php -r "var_dump(setlocale(LC_MESSAGES, 'en_GB.utf8'));"
php -r "var_dump(setlocale(LC_MESSAGES, 'en_US.UTF-8'));"
```

Both returned:

```text
bool(false)
```

PHP gettext itself was installed:

```sh
php -m | grep -i gettext
```

returned:

```text
gettext
```

So the issue is not missing PHP gettext and not missing translation files. The container did not have the configured OS locale generated.

## Successful Live Test

The following Apache environment variables fixed the live API response:

```sh
export LANG=C.UTF-8
export LC_ALL=C.UTF-8
export LANGUAGE=en
```

The successful direct PHP probe was:

```sh
php -r "putenv('LANGUAGE=en'); require '/var/www/html/stalker_portal/server/common.php'; setlocale(LC_MESSAGES, 'C.UTF-8'); bindtextdomain('stb','/var/www/html/stalker_portal/server/locale'); textdomain('stb'); bind_textdomain_codeset('stb','UTF-8'); require '/var/www/html/stalker_portal/server/lang/stb.php'; echo \$words['date_format'], PHP_EOL;"
```

It returned:

```text
{0}, {2} {1}, {3}
```

After setting Apache's environment and restarting Apache, the actual client endpoint returned correct localization values.

## Proposed Durable Change

Use the locale already available in the container:

```text
C.UTF-8
```

and explicitly set gettext language:

```text
LANGUAGE=en
```

### `minsitra-stack.yml`

Add these environment variables to the `stalker-portal` service:

```yaml
LANG: "C.UTF-8"
LC_ALL: "C.UTF-8"
LANGUAGE: "en"
```

### `docker/entrypoint.sh`

Change the config rewrite from:

```sh
sed -i "s|default_locale = .*|default_locale = en_GB.utf8|g" "$CONFIG"
```

to:

```sh
sed -i "s|default_locale = .*|default_locale = C.UTF-8|g" "$CONFIG"
sed -i "s|allowed_locales\\[English\\] = .*|allowed_locales[English] = C.UTF-8|g" "$CONFIG"
```

Also consider adding the Apache environment exports to `/etc/apache2/envvars` in the entrypoint so Apache workers inherit them reliably:

```sh
grep -q '^export LANG=C.UTF-8$' /etc/apache2/envvars || cat >> /etc/apache2/envvars <<'EOF'
export LANG=C.UTF-8
export LC_ALL=C.UTF-8
export LANGUAGE=en
EOF
```

### Existing Users

The database had existing users with:

```text
users.locale = en_GB.utf8
```

If the app continues to use the saved user locale for localization, existing rows may need to be migrated:

```sql
UPDATE users SET locale = 'C.UTF-8' WHERE locale = 'en_GB.utf8';
```

This should be applied cautiously, ideally after confirming no other app behavior depends on `en_GB.utf8`.

## Alternative

Instead of using `C.UTF-8`, install/generate real locales in the image, such as `en_GB.utf8` or `en_US.UTF-8`.

That would preserve the current config/user values but requires adding locale package installation/generation to the image. The confirmed low-resistance path is `C.UTF-8` plus `LANGUAGE=en`.
