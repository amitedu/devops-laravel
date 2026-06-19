# Deployment Steps
## 1. Provision Infrastructure in AWS
## 2. Prepare Ubuntu Instances
## 3. Deploy Web
## 4. Deploy Workers
## 5. Deploy Schedulers
## 6. Migrate from SQLite to MySql
## 7. Setup Domain name and TLS/SSL

***

## 1. Provision Infrastructure in AWS
First create a VPC for multiple availability zone by searching VPC in AWS console. VPC is important for production as it provides isolation and security to your application. Choose Availability Zone as per your region. 

Step 1: Create VPC
- Select VPC and more
- Create two subnet in first availability zone.
  - One public subnet
  - One private subnet
- Create two subnet in second availability zone.
  - One public subnet
  - One private subnet

- Change the name tag(keep your project name)

- Keep the default for most of the settings 

- In production, you probably gonna deploy at least 1 NAT 

Now Click 'Create VPC' button.

Step 2: Create EC2 Instance

Search EC2 in AWS console and click 'Launch Instance'
- Give a name tag, e.g. my-laravel-app
- Select Ubuntu
- Keep the default for Free tier.
- Create a key pair and save it in your host machine. It will help you to access the instance later. Change the .pem file permission: chmod 0600 /path/to/key.pem. This is means we are the only one read and write to it. Otherwise it may show Unprotected Private Key File error.
- Select the VPC we just create
- Select subnets as per availability zone in which you want to deploy. Select public1 for example
- Auto assign public IP- ENABLE
- Create security group if not exists as app_name_sg(eg. prod_app_name_sg)
  - Inbound rules:
    - SSH		Port 22	Allow all IP addresses
    - HTTP		Port 80	Allow all IP addresses
    - HTTPS		Port 443	Allow all IP addresses

- Change the Description name first part as well(before created)
- Storage: if you want keep 8GB
- Look at the summary in the right section.
- Launch instance
- Once launch, click on the instance ID and copy the Public IP
- Keep refreshing until it shows 'running' not 'pending'

## 2. Prepare Ubuntu Instances
1. Copy the IPv4 address of the instance. It will be in the format like [13.60.8.190]. Every time you shutdown or restart the instance, the public IP will change. So it's better to use a elastic IP for production.
2. SSH into the instance: ssh -i /path/to/key.pem ubuntu@[IP_ADDRESS]
  - If it is a new IP then it will ask to continue? then type 'yes'.
  - If the .pem file permission is not set properly, then it will show Unprotected Private Key File error.

3. Update and install necessary packages
    - sudo apt update
    - sudo apt upgrade -y
    - sudo apt install -y curl git zip unzip
  - If the update wants to reboot the instance, then reboot it in the AWS UI or via SSH. I would prefer SSH.
  - Once done, check again "sudo apt update" to make sure it is up to date.
4. Install nginx,php
  - sudo apt install nginx -y
  - sudo add-apt-repository ppa:ondrej/php -y
  - sudo apt update -y
  - sudo apt install -y php8.3-cli php8.3-fpm php8.3-mysql php8.3-curl php8.3-gd php8.3-mbstring php8.3-xml php8.3-zip php8.3-redis php8.3-bcmath php8.3-sqlite3 
  
5. Install Composer
  - curl -sS https://getcomposer.org/installer | php
  - sudo mv composer.phar /usr/local/bin/composer
  - composer -v
 
6. Install NPM and Node.js(Particular version)
   ```
   curl -fsSL https://deb.nodesource.com/setup_21.x | sudo -E bash - 
   ```
   ```
   sudo apt install -y nodejs
   ```
   - npm -v

7. You wanna create a deployment user for our application. Imagine if this instance is big enough to deploy multiple applications then you can create a deployment user for each application. And you can use it as non-root user.
  - sudo adduser <your_username> (give a password when prompted, can be anything)
  - Exit from the root user (if you are in root user)
  - SSH into the instance using the new user: ssh -i /path/to/key.pem <your_username>@[IP_ADDRESS]
    - It will prompt to continue? type 'yes'
    - If the .pem file permission is not set properly, then it will show Unprotected Private Key File error.
    - Once done, check again "ssh -i /path/to/key.pem <your_username>@[IP_ADDRESS]" to make sure it is up to date.
  - sudo usermod -aG sudo <your_username> (if you need root access)
  - sudo su - <your_username> (Switch to the deployment user. If you did not add Sudo access to this user then you will not be able to switch to it. In that case, you will be using root user for all the deployment steps from here)
  - cd ~/ (It will take you to the home directory of the deployment user)
  - To interact with github.com or gitlab.com, we need to generate ssh keys.
    - Generate ssh key for <your_username>:
      ```
      ssh-keygen -f /home/deploy/.ssh/github_key -t ed25519 -C "<your_email>"
      ```
      - It will ask for a passphrase. Press Enter to skip it.
      - add a config file to ssh directory for github.com or gitlab.com, if you are using github.com then config file should be:
      ```
      Host github.com
          IdentityFile ~/.ssh/github_rsa
          IdentitiesOnly yes 
      ```
      - change the file and folder permission
      ```
      chmod 600 ~/.ssh/github_key
      chmod 700 ~/.ssh
      ```
      - ssh-add ~/.ssh/github_key
      - cat ~/.ssh/github_key.pub (copy the public key)
    - Go to github.com or gitlab.com and add the public key to your account.
    - Test the ssh connection:
      - ssh -T git@[IP_ADDRESS]

## 3. Deploy Web
  ### 1. Create Deployment User 
  We already did that in the previous step.

    sudo adduser deploy
    usermod -aG sudo deploy
    su - deploy
    ssh-keygen -f /home/deploy/.ssh/github_key -t ed25519 -C "[EMAIL_ADDRESS]"
    chmod 600 ~/.ssh/github_key
    chmod 700 ~/.ssh
    cat ~/.ssh/github_key.pub
    ssh -T git@[IP_ADDRESS]
    
  ### 2. Git Clone
  - change the user to deploy user(here laravel_demo) from ubuntu
    
        sudo su - laravel_demo
    
  - Copy the github ssh public key to the github.com
  
        cat ~/.ssh/github_key.pub (copy the public key)
    
  - Paste this public key into your GitHub repository's Deploy Keys section under settings.
  - put a title for this key(e.g. app_name)
  - Don't allow write access. only read access is enough.
  - Clone the repo the code directory

          git clone <repo_url> code
          cd code

  ### 3. Install Laravel & NPM Dependencies
  - Install the php packages
  
        composer install --prefer-dist --no-dev

  - Create .env file based on the env.example

        cp .env.example .env
        
  - Or if you have a .env file stored elsewhere, copy it to the current directory.
  
        cp <path-to-.env-file>/<filename>.env code/.env
        
  - Check the .env if anything needs to be changed
  
  - Generate APP_KEY
  
        php artisan key:generate
        
  - If you use sqlite database create the file
  
        touch database/database.sqlite
  - Run the migration
  
        php artisan migrate
  - Now install the front-end dependencies
  
        npm install
  - Run the build
  
        npm run build      
        
  ### 4. Configure Nginx
  Now prepare the nginx config file for our application. I usually remove the default nginx symlink file if exists. And you need to do it from root user as the default config file is owned by root user. You can check the owner of the file using ls -l /etc/nginx/sites-enabled/. For the content of conf file check the test.conf file.
    
    sudo rm /etc/nginx/sites-enabled/default
    sudo nano /etc/nginx/sites-available/app_name.conf
    sudo ln -s /etc/nginx/sites-available/app_name.conf /etc/nginx/sites-enabled/
    sudo nginx -t
    sudo service nginx reload
        
  ### 5. Fix Permissions
  Context: We want to serve multiple website from one server.
  If it shows File not found in above step or something similar, then first check the nginx error.log file for more information.

    sudo cat /var/log/nginx/error.log or sudo nano /var/log/nginx/error.log

If it says permission issue on the public directory or files. We are gonna add a new group(laravel_demo here) to the www-data.

    sudo usermod -aG laravel_demo www-data

Now if look the error again, it should fix the permission issue. After that if there is showing fastcgi error then check the php-fpm config file and check the user. If it is www-data then add the deploy user(here it is laravel_demo) and the www-data same group. If we serve only one website then you can change the owner of the file to the deploy user. But we are planning to serve multiple website from one server so we are not going to change the owner of the file. We will just add the deploy user and the www-data in the same group. For the php-fpm config file location check this - sudo nano /etc/php/8.3/fpm/pool.d/www.conf. Change these places - 

    [laravel_demo]          # Pool name (was [www] at line no 4) — good ✅
    user = laravel_demo     # PHP-FPM worker runs as this user ✅
    group = laravel_demo    # PHP-FPM worker runs as this group ✅
    listen.owner = laravel_demo   # Socket file owned by this user ✅
    listen.group = laravel_demo   # Socket file group ✅

  Restart the php-fpm.

    sudo systemctl restart php8.3-fpm
    sudo service nginx reload

  ## 4. Deploy Workers
  Install Redis server

    sudo apt install redis-server -y
    
  Install supervisor

    sudo apt install supervisor -y
    
  Create a conf file for supervisor. We need to create a conf file for supervisor to run the queue workers. 
    
    sudo nano /etc/supervisor/conf.d/laravel_demo_horizon.conf

  Here is the file content:

    [program:laravel_demo_horizon]
    process_name=%(program_name)s_%(process_num)d
    command=php /home/laravel_demo/code/artisan horizon
    user=laravel_demo
    numprocs=1
    autostart=true
    autorestart=true
    redirect_stderr=true
    stdout_logfile=/home/laravel_demo/code/horizon/logs/horizon.log
    stderr_logfile=/home/laravel_demo/code/horizon/logs/horizon.err
    stopwaitsecs=3600
      
  Restart the supervisor after config changes

    sudo service supervisor restart

  Check the horizon process

    sudo service supervisor status
    
Change .env to use redis as cache and queue driver.

    SESSION_DRIVER=redis
    CACHE_DRIVER=redis
    QUEUE_CONNECTION=redis
    CACHE_STORE=redis
  
These are redis port

    REDIS_HOST=127.0.0.1
    REDIS_PASSWORD=null
    REDIS_PORT=6379
    REDIS_CLIENT=phpredis

## 5. Deploy Schedulers

### 1. To check if there is any cron entries for the current user use - 

    crontab -l
    
### 2. Configure Cron
To create or edit the cron use - 

    crontab -e

If there is no entry then add the following entry - 

    * * * * * cd /home/laravel_demo/code && php artisan schedule:run >> /home/laravel_demo/code/storage/logs/cron.log 2>&1

### 3. Verify working it in horizon
Check the /horizon if it is working correctly.

### 4. Verify log file

    nano /home/laravel_demo/code/storage/logs/cron.log

### 5. To remove or disable the cron
To remove you can delete the line or put a # sign before the line for temporary disabling it.

## 6. Migrate from SQLite to MySQL

### 1. Install MySQL Server

    sudo apt install mysql-server -y
    
### 2. Create a MySQL database and user

    sudo mysql

    ALTER USER 'root'@'localhost' IDENTIFIED WITH caching_sha2_password BY 'secret';
    FLUSH PRIVILEGES;
    EXIT;

  Then immediately verify it works:

    mysql -u root -p

  If that login succeeds, then run

    mysql_secure_installation

  follow the steps:
  1. Change the root password - yes(if you want to change). then enter the new password, confirm it again and press enter.
  2. Remove anonymous users? -> yes
  3. Disallow root login remotely? -> yes
  4. Remove test database and access to it? -> yes
  5. Reload privilege tables now? -> yes

If you need to create/update a user, here's the SQL:

    CREATE USER 'laravel_demo'@'localhost' IDENTIFIED BY 'devops#Demo18';

Grant all the privileges to the user

    GRANT ALL PRIVILEGES ON laravel_demo.* TO 'laravel_demo'@'localhost';
    FLUSH PRIVILEGES;
    EXIT;

Update the .env file with the new database credentials:

    DB_CONNECTION=mysql
    DB_HOST=[IP_ADDRESS]
    DB_PORT=3306
    DB_DATABASE=laravel_demo
    DB_USERNAME=laravel_demo
    DB_PASSWORD=[PASSWORD]  # If the password contains '#' or special characters then wrap the password in double quotes

Clear the cache and run the migration

    php artisan config:clear
    php artisan cache:clear
    php artisan route:clear
    php artisan view:clear
    php artisan optimize:clear

Run the migration

    php artisan migrate

Check the url for the application. It should work now. You can register a new user.
Now check the database using MySQL client. You can access it using laravel_demo user as we created in step 2. If you have ubuntu user access then you can use it also.

    sudo mysql -u laravel_demo -p

Now we need to give access to laravel_demo user to access the database from their local machine. First we need to create ssh key for the laravel_demo user. We can do it using the following command - 

    ssh-keygen -t ed25519 -C "deployments and ssh access" -f ~/Desktop/laravel_dmeo/key

Then copy the public key 

    cat ~/Desktop/laravel_dmeo/key.pub

Copy the contains of the file and paste it to the authorized_keys file for the laravel_demo user. 

    nano ~/.ssh/authorized_keys

Now open another terminal (your local machine) and try to login as laravel_demo user. It should not ask for the password.

    ssh -i ~/Desktop/laravel_demo/key laravel_demo@<server-ip>

After login try to login to mysql database using the laravel_demo user.

    mysql -u laravel_demo -p  

Now you can configure local mysql client to access the remote database. Use the following details:

    DB_HOST=127.0.0.1
    DB_PORT=3306
    DB_DATABASE=laravel_demo
    DB_USERNAME=laravel_demo
    DB_PASSWORD=[PASSWORD]

    SSH HOST=[IP_ADDRESS]
    SSH USER=laravel_demo
    SSH PORT=22
    SSH KEY=~/Desktop/laravel_dmeo/key  

Connect the Database and check.

## 7. Setup Domain name and TLS/SSL

I have bought a domain from godaddy.
Select Route53 and choose "Create hosted zone". Enter the domain name and click on "Create hosted zone". Now copy the NS records under "Hosted zone details" and paste it to godaddy domains -> DNS Management -> Nameservers -> Change to custom nameservers

Now go to Route53 -> Hosted zone -> <domain-name> -> "Create record"

Give a record name e.g. laraveldemo(note without underscore symbol)
Record Type - CNAME
value - copy Public IPv4 DNS name of the ec2 server and paste it here. Because we don't have fixed ip address for the ec2 instance so in the mean we will use DNS name instead of IP address.
click on Create Record
Check the status

Now go to the browser and type the subdomain.domain(e.g. laraveldemo.dudameweb.com). It should open the laravel application. Remember it will only be http. It may take hours before the changes propagate through the DNS system.

### Make it secure with TLS/SSL
Login to ec2 instance and run the following command - 

    sudo apt install certbot python3-certbot-nginx -y

Now go to nginx configration file - 

    sudo nano /etc/nginx/sites-available/laravel-demo.conf


Replace the underscore in the server_name with laraveldemo.amitdass.website

anytime we change the nginx config, we should check the syntax of the config file using the following command -

    sudo nginx -t
    
Then reload the nginx service to apply the changes

    sudo systemctl reload nginx
    
As cert will change the config file, we should backup the file first.

    sudo cp /etc/nginx/sites-available/laravel-demo.conf /etc/nginx/sites-available/laravel-demo.conf.bak

Now run the certbot command to get the certificate.

    sudo certbot --nginx

Follow the instruction and provide the required details. For example, 
  - provide email address, 
  - agree to the terms of service, 
  - select no for sharing email address, 
  - choose names of the server that you want to secure, e.g., laraveldemo.amitdass.website
  - put 1 and enter

Now it will create a redirect from HTTP to HTTPS and will enable the auto renewal of the certificate.

    sudo systemctl status certbot.timer

Dry run for testing purposes

    sudo certbot renew --dry-run



---

This is the end.
