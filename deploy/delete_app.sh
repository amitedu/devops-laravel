#!/bin/bash

# Expecting one argument that is the app name to delete
my_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
if [ $# -eq 0 ]; then
  echo "No app specified!"
  existing_apps=$(ls $my_path/../apps/ 2>/dev/null | grep '\.sh$' | grep -v '^_app\.sh$' | sed -e 's|\.[^.]*$||')
  echo "Try one of these applications:"
  echo "$existing_apps"
  exit 1
fi

# Application to delete is argument #1
app_name="$1"

# Save current directory and cd into script path
initial_working_directory=$(pwd)
my_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
cd "$my_path"

# Load common
source $my_path/../common/load_common.sh

error "You are about to delete the following:"
status "Application Cron: $app_name"
status "Directory and All Files: /home/$app_name/*"
status "User: $app_name"
status "MySQL User: $app_name"
status "MySQL Database: $app_name"
status "Nginx Configuration: /etc/nginx/sites-available/$app_name.conf"
status "PHP FPM Pool: /etc/php/$installs_php_version/fpm/pool.d/$app_name.conf"
status "Supervisor Confs: /etc/supervisor/conf.d/$app_name.conf & ${app_name}_pulse.conf"
status "App Config: $root_path/apps/$app_name.sh"
read -p "Are you sure you want to continue? [y/N] " response
echo

if [[ $response =~ ^[Yy]([Ee][Ss])?$ ]]
then

  # 1. Stop and Delete Supervisor Configurations (Horizon & Pulse)
  title "Supervisor Configurations"
  sudo supervisorctl stop horizon_$username:* pulse_$username:* 2>/dev/null
  if [ -f /etc/supervisor/conf.d/$username.conf ]; then
    sudo rm -f /etc/supervisor/conf.d/$username.conf
    status "Deleted: /etc/supervisor/conf.d/$username.conf"
  fi
  if [ -f /etc/supervisor/conf.d/${username}_pulse.conf ]; then
    sudo rm -f /etc/supervisor/conf.d/${username}_pulse.conf
    status "Deleted: /etc/supervisor/conf.d/${username}_pulse.conf"
  fi
  sudo supervisorctl reread 2>/dev/null
  sudo supervisorctl update 2>/dev/null
  status "Supervisor updated"

  # 2. Nginx Configuration
  title "Nginx Configuration"
  restart_nginx=0
  if [ -f /etc/nginx/sites-enabled/$username.conf ] || [ -L /etc/nginx/sites-enabled/$username.conf ]; then
    sudo rm -f /etc/nginx/sites-enabled/$username.conf
    status "Deleted: /etc/nginx/sites-enabled/$username.conf"
    restart_nginx=1
  else
    status "Does not exist: /etc/nginx/sites-enabled/$username.conf"
  fi
  if [ -f /etc/nginx/sites-available/$app_name.conf ]; then
    sudo rm -f /etc/nginx/sites-available/$app_name.conf
    status "Deleted: /etc/nginx/sites-available/$app_name.conf"
    restart_nginx=1
  else
    status "Does not exist: /etc/nginx/sites-available/$app_name.conf"
  fi
  if [ $restart_nginx -eq 1 ]; then
    sudo service nginx restart
    status "Nginx restarted"
  fi

  # 3. PHP-FPM Pool
  title "PHP FPM Pool"
  if [ -f /etc/php/$installs_php_version/fpm/pool.d/$app_name.conf ]; then
    sudo rm -f /etc/php/$installs_php_version/fpm/pool.d/$app_name.conf
    status "Deleted: /etc/php/$installs_php_version/fpm/pool.d/$app_name.conf"
    sudo service php$installs_php_version-fpm restart
    status "PHP FPM restarted"
  else
    status "Does not exist: /etc/php/$installs_php_version/fpm/pool.d/$app_name.conf"
  fi

  # 4. Application Cron
  title "Deleting Application Cron"
  if sudo -u $app_name crontab -l >/dev/null 2>&1; then
    sudo -u $app_name crontab -r
    status "Crontab deleted"
  else
    status "Crontab does not exist"
  fi

  # 5. Remove www-data from group
  title "Removing www-data from $app_name group"
  if getent group $app_name | grep -qw "www-data"; then
    sudo deluser www-data $app_name
    status "Removed www-data from $app_name group"
  else
    status "www-data not part of the group"
  fi

  # 6. Drop MySQL Database and User
  title "Dropping MySQL Database and User"
  mysql -u root -p$installs_database_root_password <<SQL
DROP DATABASE IF EXISTS $app_name;
DROP USER IF EXISTS '$username'@'localhost';
FLUSH PRIVILEGES;
SQL
  status "Dropped $app_name user and database from MySQL"

  # 7. Delete User and All Files
  title "Deleting User and All Files: $app_name"
  if id "$username" >/dev/null 2>&1; then
    sudo deluser $app_name --remove-all-files
    status "User $app_name has been deleted."
  else
    status "User $app_name does not exist."
  fi
  if [ -d /home/$app_name ]; then
    sudo rm -rf /home/$app_name
    status "Deleted: /home/$app_name"
  fi

  # 8. Delete Application Config File
  title "Deleting Application Config: $root_path/apps/$app_name.sh"
  if [ -f $root_path/apps/$app_name.sh ]; then
    sudo rm -f $root_path/apps/$app_name.sh
    status "Deleted: $root_path/apps/$app_name.sh"
  else
    status "Does not exist: $root_path/apps/$app_name.sh"
  fi

else
  echo "Deletion cancelled."
  exit 0
fi

# Return back to the original directory
cd $initial_working_directory || exit
