# osl_php_wordpress

Installs and configures a WordPress instance served by Apache and php-fpm.
WordPress core is installed from the wordpress.org tarball into
`/var/www/<fqdn>/wordpress`, [WP-CLI](https://wp-cli.org/) is installed to
`/usr/local/bin/wp`, and the site is served through an `apache_app` vhost
proxying PHP to a dedicated php-fpm pool.

The caller is expected to provide PHP (e.g. `osl_php_install` with at least the
`mysqlnd` extension) and a MySQL/MariaDB database (e.g. `osl-mysql`) — see the
examples below.

## Actions

- `:install`: Installs and configures the WordPress instance (default).

## Properties

| Property                | Type        | Default  | Required | Description                                                             |
|-------------------------|-------------|----------|----------|-------------------------------------------------------------------------|
| `db_host`               | String      |          | no       | Database host (`DB_HOST`)                                               |
| `db_name`               | String      |          | no       | Database name (`DB_NAME`)                                               |
| `db_password`           | String      |          | no       | Database password (`DB_PASSWORD`)                                       |
| `db_prefix`             | String      | `wp_`    | no       | Database table prefix (`$table_prefix`)                                 |
| `db_username`           | String      |          | no       | Database user (`DB_USER`)                                               |
| `fpm_max_children`      | Integer     | `15`     | no       | php-fpm pool `pm.max_children`                                          |
| `fpm_max_spare_servers` | Integer     | `6`      | no       | php-fpm pool `pm.max_spare_servers`                                     |
| `fpm_min_spare_servers` | Integer     | `2`      | no       | php-fpm pool `pm.min_spare_servers`                                     |
| `fpm_start_servers`     | Integer     | `4`      | no       | php-fpm pool `pm.start_servers`                                         |
| `fqdn`                  | String      | name     | no       | FQDN of the site vhost, defaults to the resource name                   |
| `salts`                 | Hash        | `{}`     | no       | WordPress authentication keys and salts, see [Salts](#salts)            |
| `self_managed`          | true, false | `false`  | no       | Customer manages the instance themselves, see [Upgrades](#upgrades)     |
| `version`               | String      | `7.1`    | no       | WordPress version to install (and upgrade to when Chef-managed)         |
| `wp_cli_version`        | String      | `2.12`   | no       | WP-CLI version prefix, resolved to the latest matching GitHub release   |

## Upgrades

The resource supports two management modes:

### Chef-managed (default)

Core files are owned by root (only `wp-content` is writable by `apache`, for
media uploads) and WordPress's automatic updater is disabled
(`AUTOMATIC_UPDATER_DISABLED`), so the instance always runs the pinned
`version`. Bumping `version` upgrades the site on the next converge using
WordPress's own upgrader: `wp core update` replaces the core files (removing
files dropped upstream) and then `wp core update-db` runs any pending database
migrations. `wp-config.php` and `.htaccess` are fully managed by Chef.

### Self-managed (`self_managed true`)

For customers who manage upgrades themselves from the WordPress dashboard. The
entire webroot is owned by `apache` so WordPress can update itself, and
`FS_METHOD` is set to `direct`. `wp-config.php` and `.htaccess` are only
bootstrapped if missing, since customers and their plugins routinely modify
them — later changes to `db_password`, `salts`, etc. will NOT propagate unless
the file is removed and re-converged. `version` only applies to the initial
install.

## Salts

The `salts` property renders the WordPress
[authentication unique keys and salts](https://api.wordpress.org/secret-key/1.1/salt/)
(`AUTH_KEY`, `SECURE_AUTH_KEY`, ..., `NONCE_SALT`) into `wp-config.php`, keyed
by constant name. If unset, WordPress generates secrets itself and stores them
in the database. Note that rotating salts invalidates every user's login
cookies, and on self-managed instances they only apply at bootstrap.

## Examples

A Chef-managed instance:

```ruby
osl_php_install 'wordpress' do
  version '8.4'
  php_packages %w(gd mbstring mysqlnd xml)
end

osl_php_wordpress 'blog.example.org' do
  db_host 'localhost'
  db_name 'wordpress'
  db_username 'wordpress_owner'
  db_password 'wordpress_password'
  salts(
    'AUTH_KEY' => '...',
    'SECURE_AUTH_KEY' => '...',
    'LOGGED_IN_KEY' => '...',
    'NONCE_KEY' => '...',
    'AUTH_SALT' => '...',
    'SECURE_AUTH_SALT' => '...',
    'LOGGED_IN_SALT' => '...',
    'NONCE_SALT' => '...'
  )
end
```

A customer-managed instance:

```ruby
osl_php_wordpress 'blog.example.org' do
  db_host 'localhost'
  db_name 'wordpress'
  db_username 'wordpress_owner'
  db_password 'wordpress_password'
  self_managed true
end
```
