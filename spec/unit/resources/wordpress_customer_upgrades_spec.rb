require_relative '../../spec_helper'

describe 'php-apps-test::wordpress_customer_upgrades' do
  ALL_PLATFORMS.each do |p|
    context "#{p[:platform]} #{p[:version]}" do
      cached(:chef_run) do
        ChefSpec::SoloRunner.new(p.merge(step_into: 'osl_php_wordpress')).converge(described_recipe)
      end

      before do
        allow_any_instance_of(Chef::Resource).to receive(:osl_github_latest_version).with('wp-cli/wp-cli', '2.12', 'tag_name').and_return('2.12.0')
        allow(::File).to receive(:stat).and_call_original
        allow(::File).to receive(:stat)
          .with('/var/www/blog.example.com/wordpress/index.php').and_raise(Errno::ENOENT)
      end

      it 'converges successfully' do
        expect { chef_run }.to_not raise_error
      end

      it do
        is_expected.to put_ark('wordpress').with(
          url: 'https://wordpress.org/wordpress-7.1.tar.gz',
          path: '/var/www/blog.example.com',
          version: '7.1'
        )
      end

      it do
        is_expected.to create_if_missing_template('/var/www/blog.example.com/wordpress/wp-config.php').with(
          source: 'wp-config.php.erb',
          cookbook: 'osl-php-apps',
          sensitive: true,
          variables: {
            self_managed: true,
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
        is_expected.to create_if_missing_cookbook_file('/var/www/blog.example.com/wordpress/.htaccess').with(
          source: 'wordpress/htaccess',
          cookbook: 'osl-php-apps'
        )
      end

      it { is_expected.to run_execute('chown -R apache:apache /var/www/blog.example.com/wordpress') }

      # The customer upgrades WordPress from the dashboard, not wp-cli
      it { is_expected.to_not run_execute('wp core update blog.example.com') }
      it { is_expected.to_not run_execute('wp core update-db blog.example.com') }
    end
  end
end
