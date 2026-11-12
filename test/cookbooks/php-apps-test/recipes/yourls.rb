osl_mysql_test 'yourls' do
  username 'yourls_owner'
  password 'yourls_password'
end

osl_php_install 'yourls' do
  version '8.4'
  php_packages %w(mysqlnd)
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
  plugins(
    'qr-code-designer' => {
      'url' => 'https://github.com/Waterproof-Web-Wizard-GmbH/yourls-qr-code-designer/archive/09b78f9121dba1d93804f5273c46cbc43e764978.tar.gz',
      'checksum' => 'd40f42e2e901892ec71a5b3ef7d18a43d4bcd12601429bf7df049d0adeefd173',
    },
    'rbac' => {
      'url' => 'https://github.com/saahmadnejad/YOURLS-RBAC/archive/2fe5e6c63be965fc842e2470bb0901cf8dbef23d.tar.gz',
      'checksum' => 'a29727968f97552ce20cbfc9d51d906ecfe878196a2896593adb3d1365587653',
    }
  )
end
