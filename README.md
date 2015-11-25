# Meteor on Google Compute Engine using PM2
Install scripts to run Meteor on Google Compute Engine.

## Local installation
Install PM2 meteor on your local machine.

```
npm i -g pm2-meteor
```

### Generate settings file (optional)
PM2-meteor requires a settings file with some required parameters. If you're checking out an exiting project using PM2, this will not be an issue. If you're starting from scratch, you can use the command below to generate a new settings file.

```
cd [My Meteor Project]
pm2-meteor init
```

**!** make sure you to use **fork_mode** as exec_mode. *cluster_mode* will give weird errors since PM2 on the server doesn't support clustermode on Node 0.10.40 (which is the version Meteor is using atm).

See: [PM2 and clustermode](http://pm2.keymetrics.io/docs/usage/cluster-mode/#node-0-10-x-cluster-mode)

## Server setup
1. Create a new project on GCE:  
   [https://console.cloud.google.com/](https://console.cloud.google.com)

2. Add your __public__ ssh key to *Metadata -> SSH Keys*. A great explanation on how to generate SSH keys on your local machine and copy them to your clipboard can be found  [here](https://help.github.com/articles/generating-ssh-keys/).

3. Create a new VM instance:
 - Zone:  Europe
 - Boot disk: Ubuntu latest (because it's package management is more up-to-date)
 - Check the boxes __Allow HTTP trafic__ and __Allow HTTPS trafic__ under Firewall.

## Server installation
Make an ssh connection to the server

### Node.js / PM2
```  
curl -sL https://deb.nodesource.com/setup_0.10 | sudo bash -
sudo apt-get install -y nodejs
sudo npm install pm2 -g
```
### User rights management

*is this the best way?*

For safe deployments and when you want to give access to multiple developers, you will need to create and give specific rights to one user inside the server. 

SSH into the VM instance with your Google Cloud login.
Create a user for the deploy and which will start the PM2 instance. __The user created here should be the same as the one in your settings file on your local machine.__ As an example, this will create the user __pm2-meteor__.

```
useradd pm2-meteor
```
   
Add your (and anyone else that needs access) public SSH key to this user manually.

```
[Your public SSH key] >> /home/pm2-meteor/.ssh/authorized_keys
```
   
Give the new user permission to read, write and execute inside the deployment folder. The default folder used by PM2 is the /opt folder, therefore as an example, here is how you set the right permissions to this folder.

```
chown -R pm2-meteor:pm2-meteor /opt
```

### Nginx
```
sudo apt-get update
sudo apt-get install nginx
```

Create a config file for nginx containing your application information. Here is an example config file you can add to: /etc/nginx/sites-enabled/default
```
server {
 server_name someapp.q42.nl;
 listen 80;
 
 gzip on;
 gzip_types      text/html text/plain;
 gzip_min_length 1000;

 location / {
   proxy_set_header X-Real-IP $remote_addr;
   proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
   proxy_set_header Host $http_host;
   proxy_set_header X-NginX-Proxy true;
   proxy_pass http://127.0.0.1:3000;
   proxy_redirect off;
 }
}
```
__Remember to set the proxy_pass to the address on port on which PM2 will run__

```
sudo service nginx restart
```

## Deploy your app
See:
[PM2 quick-start](http://pm2.keymetrics.io/docs/usage/quick-start/)

1. In the same location you keep your __pm2-meteor.json__ file, run pm2-meteor deploy
2. When finished, [install path]/bundle/programs/server an dru npm install
3. After that, run pm2-meteor start from the same location as step 1
4. Check if the server runs correctly by stype pm2-meteor status

Afterwards your app should be available at: someapp.q42.nl.
