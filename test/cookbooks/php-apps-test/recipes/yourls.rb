osl_mysql_test 'yourls' do
  username 'yourls_owner'
  password 'yourls_password'
end

osl_php_install 'yourls' do
  version '8.4'
  php_packages %w(fpm mysqlnd)
end

osl_php_yourls 'yourls.example.com' do
  db_username 'yourls_owner'
  db_password 'yourls_password'
  db_name 'yourls'
  db_host 'localhost'
  domain 'http://yourls.example.com'
  user_passwords [
    'admin' => 'adminpassword',
  ]
  cookiekey '0h4U_DP&fGgxUFOD-044UZma_W8n)DVTs1B)gbx-'
end
