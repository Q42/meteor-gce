# Meteor on Google Compute Engine
Install scripts to run Meteor on Google Compute Engine.

## Option 1: using MUP
This is a fast solution, but doesn't work on Windows yet :(. It uses Meteor UP (https://github.com/arunoda/meteor-up), has SSH Key authentication for GCE, and only works on Ubuntu images.

Issues with this one: you can't attach a persistent disk so if it crashes you lose your data. You can fix this by using a hosted mongodb solution.

1. Create an SSH key (a great tutorial and explanation on SSH keys can be found [here](https://www.digitalocean.com/community/tutorials/how-to-set-up-ssh-keys--2)) and insert it in `Compute` - `Compute Engine` - `Metadata` - `SSH keys`
2. Create a GCE VM instance via:
  - http://cloud.google.com/console:
    + create a new project or choose an existing one
    + in `Compute` - `Compute Engine` - `VM instances` click `New instance`
    + check `Allow HTTP traffic` and `Allow HTTPS traffic`
    + MUP only works on Ubuntu. Choose an ubuntu image, preferably the latest LTS (long-term-support) version, currently 1404
    + use a Static IP address so that you can point your DNS to it
  - commandline: `gcloud compute --project "my-meteor-project" instances create "meteor-vm" --zone "europe-west1-d" --machine-type "n1-standard-1" --network "default" --address 104.155.35.68 --maintenance-policy "MIGRATE" --scopes "https://www.googleapis.com/auth/devstorage.read_only" "https://www.googleapis.com/auth/logging.write" --tags "http-server" "https-server" --image "https://www.googleapis.com/compute/v1/projects/ubuntu-os-cloud/global/images/ubuntu-1404-trusty-v20150316" --boot-disk-type "pd-standard" --boot-disk-device-name "meteor-vm"`
3. Install MUP on your local machine: `npm install -g mup`
4. In your project directory, run `mup init`, this creates mup.json and settings.json 
  * Note: if you're adding mup to an existing project that already contains a settings.json file, you will see a __A Project Already Exists__ message. If this happens, you can either manually create a mup.json or rename your settings and then init. The settings.json file created by mup doesn't contain anything interesting, so you can just delete it afterwards and re-rename your settings.json back to it's original name.
5. In mup.json, edit the following:
  - servers.host = ip adress of your VM
  - servers.username = name of the used SSH key
  - comment the "servers.password" field
  - uncomment the "servers.pem" field
  __- "nodeVersion": "4.2.3"__
  - app = location of the file on disk (for current directory, use `'.'`)
  - env.ROOT_URL = url to your site, like `'http://mydomain.com'`
  - env.PORT = `80`
  - env.MONGO_URL = `'mongodb://localhost'`
6. Run `mup setup`
7. Run `mup deploy`


## Option 2: manually 
1. Create a new project on GCE:  
   https://console.developers.google.com/

2. Download the gcloud tool:  
   https://developers.google.com/cloud/sdk/

3. Authenticate to Google Cloud Platform:  
   `gcloud auth login`

4. Configure gcloud to use your new project by default:  
   `gcloud config set project <YOUR_PROJECT_ID>`

5. Create a bucket in Google Cloud Storage (it needs to be unique) for example:  
   `gsutil mb gs://iloveq42`

6. Edit startup.sh to use your bucket. For example:  
   `export BUCKET='iloveq42'`

7. Copy startup.sh (replace 'iloveq42' with your bucket name):  
   `gsutil cp startup.sh gs://iloveq42`

8. Bundle your Meteor app into the parent directory:  
   `meteor build .. --architecture os.linux.x86_64`

9. Copy your app to your bucket (replace 'iloveq42' with your bucket name):  
   `gsutil cp ../<YOUR_APP_NAME>.tar.gz gs://iloveq42/versions/default.tar.gz`

10. Create a new persistent disk for MongoDB:  
    `gcloud compute disks create "mongo-data" --size "200GB" --zone "europe-west1-d" --type "pd-standard"`

11. Create a compute engine instance using the startup.sh script (replace 'iloveq42' with your bucket name):  
    `gcloud compute instances create "meteor" --zone "europe-west1-d" --tags "http-server" --scopes storage-ro --metadata startup-script-url=gs://iloveq42/startup.sh --disk "name=mongo-data" "mode=rw" "boot=no"`

This will output something like this:

    NAME   ZONE           MACHINE_TYPE  INTERNAL_IP   EXTERNAL_IP   STATUS
    meteor europe-west1-d n1-standard-1 10.240.134.93 130.211.62.68 RUNNING

Done! At this point your site should be reachable on the external IP (http://130.211.62.68 in this case).


