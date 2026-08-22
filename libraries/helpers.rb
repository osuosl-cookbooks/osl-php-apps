module OSLPhpApps
  module Cookbook
    module Helpers
      require 'etc'

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
    end
  end
end
Chef::DSL::Recipe.include ::OSLPhpApps::Cookbook::Helpers
Chef::Resource.include ::OSLPhpApps::Cookbook::Helpers
