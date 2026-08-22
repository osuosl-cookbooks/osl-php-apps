# osl_php_yourls

Installs and configures a [YOURLS](https://yourls.org/) (URL shortener)
instance served by Apache and php-fpm. YOURLS is installed from the GitHub
release tarball into `/var/www/<fqdn>/yourls` and served through an
`apache_app` vhost proxying PHP to a dedicated php-fpm pool. The `version`
property is resolved to the latest matching GitHub release, so `1.10` installs
the newest `1.10.x`.

The caller is expected to provide PHP (e.g. `osl_php_install` with at least the
`mysqlnd` extension) and a MySQL/MariaDB database (e.g. `osl-mysql`) — see the
example below.

## Actions

- `:install`: Installs and configures the YOURLS instance (default).

## Properties

| Property                | Type        | Default   | Required | Description                                                          |
|-------------------------|-------------|-----------|----------|----------------------------------------------------------------------|
| `cookiekey`             | String      |           | no       | Secret used to sign cookies (`YOURLS_COOKIEKEY`)                     |
| `db_host`               | String      |           | no       | Database host (`YOURLS_DB_HOST`)                                     |
| `db_name`               | String      |           | no       | Database name (`YOURLS_DB_NAME`)                                     |
| `db_password`           | String      |           | no       | Database password (`YOURLS_DB_PASS`)                                 |
| `db_prefix`             | String      | `yourls_` | no       | Database table prefix (`YOURLS_DB_PREFIX`)                           |
| `db_username`           | String      |           | no       | Database user (`YOURLS_DB_USER`)                                     |
| `domain`                | String      |           | no       | Full site URL including scheme (`YOURLS_SITE`)                       |
| `fpm_max_children`      | Integer     | `15`      | no       | php-fpm pool `pm.max_children`                                       |
| `fpm_max_spare_servers` | Integer     | `6`       | no       | php-fpm pool `pm.max_spare_servers`                                  |
| `fpm_min_spare_servers` | Integer     | `2`       | no       | php-fpm pool `pm.min_spare_servers`                                  |
| `fpm_start_servers`     | Integer     | `4`       | no       | php-fpm pool `pm.start_servers`                                      |
| `fqdn`                  | String      | name      | no       | FQDN of the site vhost, defaults to the resource name                |
| `language`              | String      | `''`      | no       | Localization (`YOURLS_LANG`)                                         |
| `private`               | true, false | `true`    | no       | Require login to create short URLs (`YOURLS_PRIVATE`)                |
| `reserved_urls`         | Array       | `[]`      | no       | Keywords that short URLs cannot use (`$yourls_reserved_URL`)         |
| `unique_urls`           | true, false | `true`    | no       | One short URL per long URL (`YOURLS_UNIQUE_URLS`)                    |
| `url_convert`           | Integer     | `36`      | no       | Short URL character set: `36` (a-z0-9) or `62` (a-zA-Z0-9)           |
| `user_passwords`        | Array       | `[]`      | no       | Array of `'username' => 'password'` hashes for YOURLS admin users    |
| `version`               | String      | `1.10`    | no       | YOURLS version prefix, resolved to the latest matching release       |

## Examples

```ruby
osl_php_install 'yourls' do
  version '8.4'
  php_packages %w(mysqlnd)
end

osl_php_yourls 'yourls.example.com' do
  db_host 'localhost'
  db_name 'yourls'
  db_username 'yourls_owner'
  db_password 'yourls_password'
  domain 'http://yourls.example.com'
  cookiekey 'some-long-random-secret'
  user_passwords [
    'admin' => 'adminpassword',
  ]
end
```
