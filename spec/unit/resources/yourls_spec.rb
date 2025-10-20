require_relative '../../spec_helper'

describe 'php-apps-test::yourls' do
  ALL_PLATFORMS.each do |p|
    context "#{p[:platform]} #{p[:version]}" do
      cached(:chef_run) do
        ChefSpec::SoloRunner.new(p.merge(step_into: 'osl_php_apps_yourls')).converge(described_recipe)
      end

      it 'converges successfully' do
        expect { chef_run }.to_not raise_error
      end

      it { is_expected.to install_package %w(php-mysqlnd tar) }

      it do
        is_expected.to put_ark('yourls').with(
          url: 'https://github.com/YOURLS/YOURLS/archive/refs/tags/1.10.2.tar.gz',
          path: '/var/www/yourls.example.com',
          version: '1.10.2'
        )
      end
    end
  end
end
