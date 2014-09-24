# Meteor on Google Compute Engine
Install scripts to run Meteor on Google Compute Engine.


## Usage
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

7. Copy startup.sh to your bucket. For example:  
   `gsutil cp startup.sh gs://iloveq42`

8. Bundle your Meteor app:  
   `meteor bundle ../app0.0.1.tar.gz`

9. Copy your app to your bucket. For example:  
   `gsutil cp ../app0.0.1.tar.gz gs://iloveq42/versions/default.tar.gz`

10. Create a new persistent disk for MongoDB:  
    `gcloud compute disks create "mongo-data" --size "200" --zone "europe-west1-a" --type "pd-standard"`

11. Create a compute engine instance:  
    `gcloud compute instances create "meteor" --zone "europe-west1-a" --tags "http-server" --scopes storage-ro --metadata startup-script-url=gs://iloveq42/startup.sh --disk "name=mongo-data" "mode=rw" "boot=no"`

This will output something like this:

    NAME   ZONE           MACHINE_TYPE  INTERNAL_IP   EXTERNAL_IP   STATUS
    meteor europe-west1-a n1-standard-1 10.240.134.93 130.211.62.68 RUNNING

At this point your site should be reachable on the external IP (http://130.211.62.68 in this case).
