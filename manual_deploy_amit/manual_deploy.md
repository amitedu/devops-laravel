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

    - sudo adduser deploy
    - sudo usermod -aG sudo deploy
    - sudo su - deploy
    - ssh-keygen -f /home/deploy/.ssh/github_key -t ed25519 -C "[EMAIL_ADDRESS]"
    - chmod 600 ~/.ssh/github_key
    - chmod 700 ~/.ssh
    - cat ~/.ssh/github_key.pub
    - ssh -T git@[IP_ADDRESS]
    
  ### 2. Git Clone
  ### 3. Install Laravel & NPM Dependencies
  ### 4. Configure Nginx
  ### 5. Fix Permissions