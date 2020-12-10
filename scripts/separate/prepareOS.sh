#!/bin/bash

. config.sh 
echo $git_key
if [ $# -eq 1 ]
then

    ssh_port=50142
    user=mechanic
    group=mechanic

    domain=".databridge.website"
    name=$1

    if [ -z "$(grep -E "^$group:" /etc/group)" ]
        then
            sudo groupadd $group
    fi

    if [ -z "$(grep -E "www-data:" /etc/group)" ]
        then
            sudo groupadd www-data
    fi

    #20 Create user mechanic with password mechanic
    if [ -z "$(grep -E "^$user:" /etc/passwd)" ]
        then
            sudo useradd $user -g $group -s /bin/bash -d /home/$user -p $(openssl passwd -6 mechanic)
    fi

    if ! [ -d /home/$user ]
        then
            sudo mkdir /home/$user
    fi

    if ! [ -d /home/$user/.ssh ]
        then
            sudo mkdir /home/$user/.ssh
    fi

    if ! [ -d /home/$user/.ssh/github ]
        then
            sudo mkdir -p /home/$user/.ssh/github
    fi
    

    if [ -f /home/$user/.ssh/authorized_keys ]
        then
            if [ -z "$(grep  "$(cat $ssh_key)" /home/$user/.ssh/authorized_keys)" ]
                then
                    cat $ssh_key >> /home/$user/.ssh/authorized_keys
            fi
        else
            cp $ssh_key /home/$user/.ssh/authorized_keys
    fi

    sudo chown -R $user:$group /home/$user
    sudo chmod 700 /home/$user/.ssh /home/$user/.ssh/github

    usermod -aG sudo $user
    usermod -aG www-data $user

    sudo apt update && apt upgrade -y

    if [ -z $(which git) ]
        then
            sudo apt install -y git
    fi
    
    if [ -z $(which containerd) ]
        then
            sudo apt install -y containerd
    fi

    if [ -z $(which docker) ]
        then
            sudo apt install -y docker
    fi

    if [ -z $(which docker-compose) ]
        then
            sudo apt install -y docker-compose
    fi

    if [ -e /var/run/docker.pid ]
        then
            systemctl unmask docker
            systemctl start docker
    fi


    if ! [ -d ~/.ssh/github ]
        then
            sudo mkdir -p ~/.ssh/github
    fi
    
    sudo chmod 700 ~/.ssh ~/.ssh/github

    # Add private key for repo

#    if [ -f ~/.ssh/github/id_rsa ]
#        then
#            if [ ! -s ~/.ssh/github/id_rsa ]
#                then
#                    sudo rm -f ~/.ssh/github/id_rsa
#            fi
#    fi

    if   [ -f $git_key ]
        then    
            if [ -s $git_key ]
                then
                    sudo cp -f $git_key ~/.ssh/github/id_rsa
                    sudo cp -f $git_key /home/$user/.ssh/github/id_rsa
                else
                    echo "Private key file $git_key is empty"
            fi
        else
            echo "Not found file private key in $git_key"
    fi

    if [ -f ~/.ssh/github/id_rsa ]
        then
            if ! [ -s ~/.ssh/github/id_rsa ]
                then
                    echo "Private key file ~/.ssh/github/id_rsa is empty"
                    exit 0
            fi
        else
            echo "Private key file ~/.ssh/github/id_rsa is absent"
            exit 0
    fi
 

    sudo chown $USER: ~/.ssh/github/id_rsa
    sudo chmod 600 ~/.ssh/github/id_rsa

    sudo chown $user /home/$user/.ssh/github/id_rsa
    sudo chmod 600 /home/$user/.ssh/github/id_rsa

    if ! [ -f ~/.ssh/config ]
        then
            sudo touch ~/.ssh/config
    fi
    sudo chmod 600 ~/.ssh/config
    if [ -z "$(grep -E "^Host github.com" ~/.ssh/config)" ]
        then
            cat << EOF | sudo tee ~/.ssh/config > /dev/null
    Host github.com
        IdentityFile ~/.ssh/github/id_rsa
EOF
    fi

    #70 SWAPfile
    sudo fallocate -l 1.5G /swapfile
    sudo chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile

    if [ -z "$(grep -E "/swapfile none swap sw 0 0" /etc/fstab)" ]
        then
            echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
    fi

    

    #10 Change ssh port
    #sudo sed -i "s/.*Port.*/Port $ssh_port/" /etc/ssh/sshd_config
    sudo systemctl restart sshd

    domainname="$name$domain"
    echo $domainname

    cd /docker-laravel/scripts

    sudo sed -i "s/localhost.localdomain/$domainname/" /docker-laravel/init/docker-compose.yml
    sudo sed -i "s/localhost.localdomain/$domainname/" /docker-laravel/init/nginx/nginx-config

    sudo sed -i "s/localhost.localdomain/$domainname/" /docker-laravel/nginx/nginx-config
    sudo sed -i "s/localhost.localdomain/$domainname/" /docker-laravel/php-fpm/dockerfile
    sudo sed -i "s/localhost.localdomain/$domainname/" /docker-laravel/docker-compose.yml

    sudo sed -i "s/MYSQL_ROOT_PASSWORD:.*/MYSQL_ROOT_PASSWORD: $mysql_root_pass/" /docker-laravel/docker-compose.yml
    sudo sed -i "s/MYSQL_USER:.*/MYSQL_USER: $mysql_user/" /docker-laravel/docker-compose.yml
    sudo sed -i "s/MYSQL_PASSWORD:.*/MYSQL_PASSWORD: $mysql_user_pass/" /docker-laravel/docker-compose.yml
    sudo sed -i "s/MYSQL_DATABASE:.*/MYSQL_DATABASE: $mysql_db_name/" /docker-laravel/docker-compose.yml

    sudo sed -i "s/DB_HOST=.*/DB_HOST=db/" $env_file
    sudo sed -i "s/DB_DATABASE=.*/DB_DATABASE=$mysql_db_name/" $env_file
    sudo sed -i "s/DB_USERNAME=.*/DB_USERNAME=$mysql_user/" $env_file
    sudo sed -i "s/DB_PASSWORD=.*/DB_PASSWORD=$mysql_user_pass/" $env_file



fi