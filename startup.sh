#!/bin/bash

# Change this to your GCS bucket name:
export BUCKET='meteor'


# MongoDB
apt-key adv --keyserver keyserver.ubuntu.com --recv 7F0CEB10
echo 'deb http://downloads-distro.mongodb.org/repo/debian-sysvinit dist 10gen' | tee /etc/apt/sources.list.d/mongodb.list

# Nginx
gpg --keyserver keyserver.ubuntu.com --recv-key ABF5BD827BD9BF62
gpg -a --export ABF5BD827BD9BF62 | apt-key add -
echo 'deb http://nginx.org/packages/debian/ wheezy nginx' | tee /etc/apt/sources.list.d/nginx.list

# Node.js (this script already runs apt-get update)
curl -sL https://deb.nodesource.com/setup | bash -

# Install packages
apt-get install -y mongodb-10gen nodejs nginx
npm install -g --unsafe-perm pm2


# Mount mongo-data disk and configure MongoDB to use it
mkdir /mongo-data
/usr/share/google/safe_format_and_mount -m "mkfs.ext4 -F" /dev/sdb /mongo-data
mkdir /mongo-data/mongodb
chown mongodb:mongodb /mongo-data/mongodb
echo 'dbpath=/mongo-data/mongodb
logpath=/var/log/mongodb/mongodb.log
logappend=true
' | tee /etc/mongodb.conf
/etc/init.d/mongodb restart


# Configure nginx
echo 'server {
    listen       80;
    server_name  localhost;

    #access_log  /var/log/nginx/log/host.access.log  main;

    location / {
        proxy_pass       http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $http_host;

        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forward-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forward-Proto http;
        proxy_set_header X-Nginx-Proxy true;

        proxy_redirect off;
    }
}
' | tee /etc/nginx/conf.d/default.conf
/etc/init.d/nginx restart


# Get app code
cd /opt
gsutil cp gs://$BUCKET/versions/default.tar.gz .
tar zxf default.tar.gz
cd bundle
(cd programs/server && npm install)


# Run
export MONGO_URL='mongodb://localhost'
export ROOT_URL='http://localhost'
export PORT=3000
pm2 start main.js --name 'meteor-project'
