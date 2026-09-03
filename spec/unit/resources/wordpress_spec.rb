require_relative '../../spec_helper'

describe 'php-apps-test::wordpress' do
  ALL_PLATFORMS.each do |p|
    context "#{p[:platform]} #{p[:version]}" do
      before do
        allow(Net::HTTP).to receive(:get).and_call_original
        allow(Net::HTTP).to receive(:get)
          .with(URI('https://api.github.com/repos/wp-cli/wp-cli/releases'))
          .and_return([{ 'name' => 'Version 2.12.0', 'tag_name' => 'v2.12.0' }].to_json)
        allow(::File).to receive(:exist?).and_call_original
        allow(::File).to receive(:exist?)
          .with('/var/www/wordpress.example.com/wordpress/wp-includes/version.php').and_return(true)
        allow(::File).to receive(:read).and_call_original
        allow(::File).to receive(:read)
          .with('/var/www/wordpress.example.com/wordpress/wp-includes/version.php')
          .and_return(%($wp_version = '7.1';))
      end
      cached(:chef_run) do
        ChefSpec::SoloRunner.new(p.merge(step_into: 'osl_php_wordpress')).converge(described_recipe)
      end

      it 'converges successfully' do
        expect { chef_run }.to_not raise_error
      end

      it { is_expected.to install_package 'tar' }

      it { expect(chef_run.node['osl-apache']['behind_loadbalancer']).to be true }

      %w(osl-apache osl-selinux).each do |r|
        it { is_expected.to include_recipe r }
      end

      %w(proxy proxy_fcgi).each do |m|
        it { is_expected.to enable_apache2_module m }
        it { expect(chef_run.apache2_module(m)).to notify('apache2_service[osuosl]').to(:reload) }
      end

      it do
        is_expected.to create_remote_file('/usr/local/bin/wp').with(
          source: 'https://github.com/wp-cli/wp-cli/releases/download/v2.12.0/wp-cli-2.12.0.phar',
          mode: '0755'
        )
      end

      it do
        is_expected.to put_ark('wordpress').with(
          url: 'https://wordpress.org/wordpress-7.1.tar.gz',
          path: '/var/www/wordpress.example.com',
          version: '7.1'
        )
      end

      it do
        is_expected.to create_template('/var/www/wordpress.example.com/wordpress/wp-config.php').with(
          source: 'wp-config.php.erb',
          cookbook: 'osl-php-apps',
          sensitive: true,
          variables: {
            self_managed: false,
            db_host: 'localhost',
            db_name: 'wordpress',
            db_password: 'wordpress_password',
            db_prefix: 'wp_',
            db_username: 'wordpress_owner',
            salts: {
              'AUTH_KEY' => 'auth_key',
              'SECURE_AUTH_KEY' => 'secure_auth_key',
              'LOGGED_IN_KEY' => 'logged_in_key',
              'NONCE_KEY' => 'nonce_key',
              'AUTH_SALT' => 'auth_salt',
              'SECURE_AUTH_SALT' => 'secure_auth_salt',
              'LOGGED_IN_SALT' => 'logged_in_salt',
              'NONCE_SALT' => 'nonce_salt',
            },
          }
        )
      end

      it do
        is_expected.to create_cookbook_file('/var/www/wordpress.example.com/wordpress/.htaccess').with(
          source: 'wordpress/htaccess',
          cookbook: 'osl-php-apps'
        )
      end

      it do
        is_expected.to create_directory('/var/www/wordpress.example.com/wordpress/wp-content').with(
          owner: 'apache',
          group: 'apache'
        )
      end

      it { is_expected.to_not run_execute('chown -R apache:apache /var/www/wordpress.example.com/wordpress') }

      # Installed version matches the pinned version, no upgrade needed
      it { is_expected.to_not run_execute('wp core update wordpress.example.com') }
      it { is_expected.to_not run_execute('wp core update-db wordpress.example.com') }

      context 'pending core upgrade' do
        before do
          allow(::File).to receive(:read)
            .with('/var/www/wordpress.example.com/wordpress/wp-includes/version.php')
            .and_return(%($wp_version = '6.8.2';))
        end
        cached(:chef_run) do
          ChefSpec::SoloRunner.new(p.merge(step_into: 'osl_php_wordpress')).converge(described_recipe)
        end

        it do
          is_expected.to run_execute('wp core update wordpress.example.com').with(
            command: '/usr/local/bin/wp core update --version=7.1 --force --path=/var/www/wordpress.example.com/wordpress --allow-root',
            live_stream: true
          )
        end

        it do
          expect(chef_run.execute('wp core update wordpress.example.com')).to \
            notify('execute[wp core update-db wordpress.example.com]').to(:run)
        end
      end

      it do
        is_expected.to install_php_fpm_pool('wordpress.example.com').with(
          listen: '/var/run/wordpress.example.com-fpm.sock',
          max_children: 15,
          start_servers: 4,
          min_spare_servers: 2,
          max_spare_servers: 6
        )
      end

      it do
        is_expected.to create_apache_app('wordpress.example.com').with(
          directory: '/var/www/wordpress.example.com/wordpress',
          allow_override: 'All',
          directory_options: %w(FollowSymLinks MultiViews),
          directive_http: [
            '<FilesMatch "\.(php|phar)$">',
            '  SetHandler "proxy:unix:/var/run/wordpress.example.com-fpm.sock|fcgi://localhost/"',
            '</FilesMatch>',
          ]
        )
      end
    end
  end
end
