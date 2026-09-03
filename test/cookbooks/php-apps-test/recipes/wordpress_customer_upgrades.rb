osl_mysql_test 'wordpress' do
  username 'wordpress_owner'
  password 'wordpress_password'
end

osl_php_install 'wordpress' do
  version '8.4'
  php_packages %w(gd mbstring mysqlnd xml)
end

osl_php_wordpress 'blog.example.com' do
  db_username 'wordpress_owner'
  db_password 'wordpress_password'
  db_name 'wordpress'
  db_host 'localhost'
  self_managed true
  salts(
    'AUTH_KEY' => 'auth_key',
    'SECURE_AUTH_KEY' => 'secure_auth_key',
    'LOGGED_IN_KEY' => 'logged_in_key',
    'NONCE_KEY' => 'nonce_key',
    'AUTH_SALT' => 'auth_salt',
    'SECURE_AUTH_SALT' => 'secure_auth_salt',
    'LOGGED_IN_SALT' => 'logged_in_salt',
    'NONCE_SALT' => 'nonce_salt'
  )
end
