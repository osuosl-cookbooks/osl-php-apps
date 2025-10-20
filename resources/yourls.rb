resource_name :osl_php_apps_yourls
provides :osl_php_apps_yourls
unified_mode true

default_action :install

property :version, String, default: '1.4'
property :fqdn, String, name_property: true
property :db_username, String
property :db_password, String, sensitive: true
property :db_name, String
property :db_host, String
property :db_prefix, String, default: 'yourls_'
property :domain, String, sensitive: true
property :language, String, default: '', sensitive: true
property :unique_urls, [true, false], default: true, sensitive: true
property :private, [true, false], default: true, sensitive: true
property :cookiekey, String, sensitive: true
property :user_passwords, Array, default: [], sensitive: true
property :url_convert, Integer, default: 36
property :reserved_urls, Array, default: []

action :install do
  package %w(php-mysqlnd tar)

include_recipe 'osl-selinux'
include_recipe 'osl-apache'

%w(proxy proxy_fcgi).each do |m|
  apache2_module m do
    notifies :reload, 'apache2_service[osuosl]'
  end
end

  yourls_version = osl_github_latest_version('yourls/yourls', new_resource.version)

  begin
    ark 'yourls' do
      url "https://github.com/YOURLS/YOURLS/archive/refs/tags/#{yourls_version}.tar.gz"
      path "/var/www/#{new_resource.name}"
      version yourls_version
      action :put
    end
  rescue
    Chef::Log.warn("Error downloading yourls-#{yourls_version}, skipping for now")
  end

  template "/var/www/#{new_resource.name}/yourls/user/config.php" do
    source 'config.php.erb'
    cookbook 'osl-php-apps'
    variables(
        cookiekey: new_resource.cookiekey,
        db_host: new_resource.db_host,
        db_name: new_resource.db_name,
        db_password: new_resource.db_password,
        db_prefix: new_resource.db_prefix,
        db_username: new_resource.db_username,
        domain: new_resource.domain,
        language: new_resource.language,
        private: new_resource.private,
        reserved_urls: new_resource.reserved_urls,
        unique_urls: new_resource.unique_urls,
        url_convert: new_resource.url_convert,
        user_passwords: new_resource.user_passwords
      )
  end

  cookbook_file "/var/www/#{new_resource.name}/yourls/.htaccess" do
    source '.htaccess'
    owner 'root'
    group 'root'
    mode '0644'
    cookbook 'osl-php-apps'
  end

  fpm_settings = osl_php_fpm_settings(52)

  php_fpm_pool "#{new_resource.name}" do
    listen "/var/run/#{new_resource.name}-fpm.sock"
    max_children fpm_settings['max_children']
    start_servers fpm_settings['start_servers']
    min_spare_servers fpm_settings['min_spare_servers']
    max_spare_servers fpm_settings['max_spare_servers']
  end

  yourls_webroot = "/var/www/#{new_resource.name}/yourls"

  apache_app "#{new_resource.name}" do
    directory yourls_webroot
    allow_override 'All'
    directory_options %w(FollowSymLinks MultiViews)
    directive_http [
      '<FilesMatch "\.(php|phar)$">',
      "  SetHandler \"proxy:unix:/var/run/#{new_resource.name}-fpm.sock|fcgi://localhost/\"",
      '</FilesMatch>',
    ]
  end
end
