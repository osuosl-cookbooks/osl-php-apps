resource_name :osl_php_wordpress
provides :osl_php_wordpress
unified_mode true

default_action :install

property :db_host, String
property :db_name, String
property :db_password, String, sensitive: true
property :db_prefix, String, default: 'wp_'
property :db_username, String
property :fpm_max_children, Integer, default: 15
property :fpm_max_spare_servers, Integer, default: 6
property :fpm_min_spare_servers, Integer, default: 2
property :fpm_start_servers, Integer, default: 4
property :fqdn, String, name_property: true
property :salts, Hash, default: {}, sensitive: true
property :self_managed, [true, false], default: false
property :version, String, default: '7.1'
property :wp_cli_version, String, default: '2.12'

action :install do
  package 'tar'

  include_recipe 'osl-apache'
  include_recipe 'osl-selinux'

  %w(proxy proxy_fcgi).each do |m|
    apache2_module m do
      notifies :reload, 'apache2_service[osuosl]'
    end
  end

  wordpress_webroot = "/var/www/#{new_resource.name}/wordpress"

  wp_cli_version = osl_github_latest_version('wp-cli/wp-cli', new_resource.wp_cli_version, 'tag_name')

  remote_file '/usr/local/bin/wp' do
    source "https://github.com/wp-cli/wp-cli/releases/download/v#{wp_cli_version}/wp-cli-#{wp_cli_version}.phar"
    mode '0755'
  end

  # Initial install only, upgrades are done with wp-cli so stale core files are
  # removed and database migrations run
  ark 'wordpress' do
    url "https://wordpress.org/wordpress-#{new_resource.version}.tar.gz"
    path "/var/www/#{new_resource.name}"
    version new_resource.version
    action :put
    not_if { ::File.exist?("#{wordpress_webroot}/wp-load.php") }
  end

  # Customers and their plugins modify these files (e.g. WP_CACHE in
  # wp-config.php or rewrite rules in .htaccess), so only bootstrap them on
  # self-managed instances
  config_action = new_resource.self_managed ? :create_if_missing : :create

  template "#{wordpress_webroot}/wp-config.php" do
    source 'wp-config.php.erb'
    cookbook 'osl-php-apps'
    sensitive true
    variables(
      self_managed: new_resource.self_managed,
      db_host: new_resource.db_host,
      db_name: new_resource.db_name,
      db_password: new_resource.db_password,
      db_prefix: new_resource.db_prefix,
      db_username: new_resource.db_username,
      salts: new_resource.salts
    )
    action config_action
  end

  cookbook_file "#{wordpress_webroot}/.htaccess" do
    source 'wordpress/htaccess'
    cookbook 'osl-php-apps'
    action config_action
  end

  # wp-content must be writable by php-fpm for media uploads
  directory "#{wordpress_webroot}/wp-content" do
    owner 'apache'
    group 'apache'
  end

  # Self-managed instances upgrade WordPress from the dashboard, which
  # requires the entire webroot to be writable by php-fpm
  if new_resource.self_managed
    execute "chown -R apache:apache #{wordpress_webroot}" do
      not_if { wordpress_apache_owned?(wordpress_webroot) }
    end
  else
    # Upgrade core files with WordPress's own upgrader when the pinned version
    # changes, then run any pending database migrations
    execute "wp core update #{new_resource.name}" do
      command "/usr/local/bin/wp core update --version=#{new_resource.version} --force --path=#{wordpress_webroot} --allow-root"
      live_stream true
      not_if { wordpress_version?(wordpress_webroot, new_resource.version) }
      notifies :run, "execute[wp core update-db #{new_resource.name}]"
    end

    execute "wp core update-db #{new_resource.name}" do
      command "/usr/local/bin/wp core update-db --path=#{wordpress_webroot} --allow-root"
      live_stream true
      action :nothing
    end
  end

  php_fpm_pool new_resource.name.to_s do
    listen "/var/run/#{new_resource.name}-fpm.sock"
    max_children new_resource.fpm_max_children
    start_servers new_resource.fpm_start_servers
    min_spare_servers new_resource.fpm_min_spare_servers
    max_spare_servers new_resource.fpm_max_spare_servers
  end

  apache_app new_resource.name.to_s do
    directory wordpress_webroot
    allow_override 'All'
    directory_options %w(FollowSymLinks MultiViews)
    directive_http [
      '<FilesMatch "\.(php|phar)$">',
      "  SetHandler \"proxy:unix:/var/run/#{new_resource.name}-fpm.sock|fcgi://localhost/\"",
      '</FilesMatch>',
    ]
  end
end
