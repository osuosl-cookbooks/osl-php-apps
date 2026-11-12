require_relative '../../spec_helper'

describe 'php-apps-test::yourls' do
  ALL_PLATFORMS.each do |p|
    context "#{p[:platform]} #{p[:version]}" do
      before do
        allow(Net::HTTP).to receive(:get).and_call_original
        allow(Net::HTTP).to receive(:get)
          .with(URI('https://api.github.com/repos/yourls/yourls/releases'))
          .and_return([{ 'name' => '1.10.4' }].to_json)
      end
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
        it { is_expected.to enable_apache2_module(m).with(conf: false) }
        it { expect(chef_run.apache2_module(m)).to notify('apache2_service[osuosl]').to(:reload) }
      end

      it do
        is_expected.to put_ark('yourls').with(
          url: 'https://github.com/YOURLS/YOURLS/archive/refs/tags/1.10.4.tar.gz',
          path: '/var/www/yourls.example.com',
          version: '1.10.4'
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
            no_hash_password: true,
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
        expect(chef_run).to render_file('/var/www/yourls.example.com/yourls/user/config.php')
          .with_content("define( 'YOURLS_NO_HASH_PASSWORD', true );")
      end

      {
        'qr-code-designer' => {
          url: 'https://github.com/Waterproof-Web-Wizard-GmbH/yourls-qr-code-designer/archive/09b78f9121dba1d93804f5273c46cbc43e764978.tar.gz',
          checksum: 'd40f42e2e901892ec71a5b3ef7d18a43d4bcd12601429bf7df049d0adeefd173',
        },
        'rbac' => {
          url: 'https://github.com/saahmadnejad/YOURLS-RBAC/archive/2fe5e6c63be965fc842e2470bb0901cf8dbef23d.tar.gz',
          checksum: 'a29727968f97552ce20cbfc9d51d906ecfe878196a2896593adb3d1365587653',
        },
      }.each do |plugin, source|
        it do
          is_expected.to put_ark(plugin).with(
            url: source[:url],
            checksum: source[:checksum],
            path: '/var/www/yourls.example.com/yourls/user/plugins',
            owner: 'root'
          )
        end
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

describe 'php-apps-test::yourls_hash_passwords' do
  before do
    allow(Net::HTTP).to receive(:get).and_call_original
    allow(Net::HTTP).to receive(:get)
      .with(URI('https://api.github.com/repos/yourls/yourls/releases'))
      .and_return([{ 'name' => '1.10.4' }].to_json)
  end

  cached(:chef_run) do
    ChefSpec::SoloRunner.new(ALMA_9.merge(step_into: 'osl_php_yourls')).converge(described_recipe)
  end

  it do
    expect(chef_run).to_not render_file('/var/www/yourls.example.com/yourls/user/config.php')
      .with_content('YOURLS_NO_HASH_PASSWORD')
  end

  it { expect(chef_run).to_not put_ark('rbac') }
end

describe 'osl_php_yourls plugins validation' do
  before do
    allow(Net::HTTP).to receive(:get).and_call_original
    allow(Net::HTTP).to receive(:get)
      .with(URI('https://api.github.com/repos/yourls/yourls/releases'))
      .and_return([{ 'name' => '1.10.4' }].to_json)
  end

  {
    'a key with a space' => { 'Bad Key' => {} },
    'a parent directory key' => { '..' => {} },
    'the yourls key' => { 'yourls' => {} },
    'no checksum' => { 'rbac' => { 'url' => 'https://example.org/rbac.tar.gz' } },
  }.each do |desc, plugins|
    context "plugins with #{desc}" do
      let(:url) { 'https://example.org/p.tar.gz' }
      let(:sum) { 'a' * 64 }
      let(:bad) do
        plugins.transform_values { |v| v.empty? ? { 'url' => url, 'checksum' => sum } : v }
      end
      let(:chef_run) do
        p = bad
        ChefSpec::SoloRunner.new(platform: 'almalinux', version: '9', step_into: 'osl_php_yourls')
                            .converge_block { osl_php_yourls('yourls.example.com') { plugins p } }
      end

      it do
        expect { chef_run }.to raise_error(Chef::Exceptions::ValidationFailed)
      end
    end
  end
end
