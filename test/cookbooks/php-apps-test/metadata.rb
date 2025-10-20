name             'php-apps-test'
maintainer       'Oregon State University'
maintainer_email 'chef@osuosl.org'
license          'Apache-2.0'
chef_version     '>= 12.18'
issues_url       'https://github.com/osuosl-cookbooks/osl-php-apps/issues'
source_url       'https://github.com/osuosl-cookbooks/osl-php-apps'
description      'Installs/Configures php-apps-test'
version          '0.1.0'


depends          'osl-mysql'
depends          'osl-php'
depends          'osl-php-apps'
depends          'osl-apache'

supports         'almalinux', '~> 8.0'
supports         'almalinux', '~> 9.0'
