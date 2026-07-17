#!/bin/bash

# Install MySQL
sudo apt-get install -y mysql-server

# Set the root password (uses caching_sha2_password — required for MySQL 8.4 on Ubuntu 24.04)
# mysql_native_password was removed as a default plugin in MySQL 8.4
sudo mysql -u root -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH caching_sha2_password BY '$installs_database_root_password';"

# Harden MySQL security — replaces the fragile expect/mysql_secure_installation approach.
# mysql_secure_installation prompts changed in MySQL 8.4, making expect scripts unreliable.
sudo mysql -u root -p"$installs_database_root_password" -e "
  -- Remove anonymous users
  DELETE FROM mysql.user WHERE User='';

  -- Disallow remote root login
  DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');

  -- Remove test database
  DROP DATABASE IF EXISTS test;
  DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';

  -- Apply changes
  FLUSH PRIVILEGES;
"
