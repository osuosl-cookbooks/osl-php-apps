module OSLPhpApps
  module Cookbook
    module Helpers
      require 'etc'
      require 'shellwords'

      # Return true if the WordPress webroot is owned by apache so WordPress
      # can upgrade itself from the dashboard
      def wordpress_apache_owned?(webroot)
        Etc.getpwuid(::File.stat("#{webroot}/index.php").uid).name == 'apache'
      rescue Errno::ENOENT
        false
      end

      # Return true if the installed WordPress core matches the given version
      def wordpress_version?(webroot, version)
        version_php = "#{webroot}/wp-includes/version.php"
        ::File.exist?(version_php) && ::File.read(version_php).include?("wp_version = '#{version}';")
      end

      # Return true once the site has been installed, so the install runs once
      def wordpress_installed?(webroot)
        shell_out(wordpress_wp_cli(webroot, 'core is-installed')).exitstatus == 0
      end

      def wp_cli_path
        '/usr/local/bin/wp'
      end

      # Build a wp-cli command line against the given webroot
      def wordpress_wp_cli(webroot, *args)
        [wp_cli_path, *args, "--path=#{webroot}", '--allow-root'].join(' ')
      end

      # Build the command that completes the install and creates the admin
      # account, escaped because the values come from a data bag
      def wordpress_install_cmd(webroot, url:, title:, admin_user:, admin_password:, admin_email:)
        wordpress_wp_cli(
          webroot,
          'core install',
          "--url=#{url.shellescape}",
          "--title=#{title.shellescape}",
          "--admin_user=#{admin_user.shellescape}",
          "--admin_password=#{admin_password.shellescape}",
          "--admin_email=#{admin_email.shellescape}",
          '--skip-email'
        )
      end
    end
  end
end
Chef::DSL::Recipe.include ::OSLPhpApps::Cookbook::Helpers
Chef::Resource.include ::OSLPhpApps::Cookbook::Helpers
