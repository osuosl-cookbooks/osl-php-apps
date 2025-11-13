require_relative '../../spec_helper'

describe 'php-apps-test::yourls' do
  ALL_PLATFORMS.each do |p|
    context "#{p[:platform]} #{p[:version]}" do
      cached(:chef_run) do
        ChefSpec::SoloRunner.new(p.merge(step_into: 'osl_php_yourls')).converge(described_recipe)
      end

      it 'converges successfully' do
        expect { chef_run }.to_not raise_error
      end

      it { is_expected.to install_package 'tar' }

      %w(osl-apache osl-selinux).each do |r|
        it { is_expected.to include_recipe r }
      end

      %w(proxy proxy_fcgi).each do |m|
        it { is_expected.to enable_apache2_module m }
        it { expect(chef_run.apache2_module(m)).to notify('apache2_service[osuosl]').to(:reload) }
      end

      it do
        is_expected.to put_ark('yourls').with(
          url: 'https://github.com/YOURLS/YOURLS/archive/refs/tags/1.10.2.tar.gz',
          path: '/var/www/yourls.example.com',
          version: '1.10.2'
        )
      end

      it do
        is_expected.to create_template('/var/www/yourls.example.com/yourls/user/config.php').with(
          source: 'config.php.erb',
          cookbook: 'osl-php-apps',
          sensitive: true,
          variables: {
            cookiekey: '0h4U_DP&fGgxUFOD-044UZma_W8n)DVTs1B)gbx-',
            db_host: 'localhost',
            db_name: 'yourls',
            db_password: 'yourls_password',
            db_prefix: 'yourls_',
            db_username: 'yourls_owner',
            domain: 'http://yourls.example.com',
            language: '',
            private: true,
            reserved_urls: [],
            unique_urls: true,
            url_convert: 36,
            user_passwords: [
              'admin' => 'adminpassword',
            ],
          }
        )
      end

      it do
        is_expected.to create_cookbook_file('/var/www/yourls.example.com/yourls/.htaccess').with(
          source: 'yourls/htaccess',
          cookbook: 'osl-php-apps'
        )
      end

      it do
        is_expected.to install_php_fpm_pool('yourls.example.com').with(
          listen: '/var/run/yourls.example.com-fpm.sock',
          max_children: 15,
          start_servers: 4,
          min_spare_servers: 2,
          max_spare_servers: 6
        )
      end

      it do
        is_expected.to create_apache_app('yourls.example.com').with(
          directory: '/var/www/yourls.example.com/yourls',
          allow_override: 'All',
          directory_options: %w(FollowSymLinks MultiViews),
          directive_http: [
            '<FilesMatch "\.(php|phar)$">',
            '  SetHandler "proxy:unix:/var/run/yourls.example.com-fpm.sock|fcgi://localhost/"',
            '</FilesMatch>',
          ]
        )
      end
    end
  end
end
