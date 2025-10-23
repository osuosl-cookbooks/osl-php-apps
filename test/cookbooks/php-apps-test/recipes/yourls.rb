osl_mysql_test 'yourls' do
  username 'yourls_owner'
  password 'yourls_password'
end

osl_php_install 'yourls' do
  version '8.4'
end

osl_php_yourls 'yourls.example.com' do
  version '1.10'
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
