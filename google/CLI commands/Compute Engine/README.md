# Create multiple instances at same time 

Create Multiple instances at same time
for i in {1..3}; \
do \
gcloud compute instances create "nginxstack-$i" \
--machine-type "f1-micro" \
--tags https-tcp-443,http-tcp-80 \
--zone us-west1-b \
--image=debian-9-stretch-v20190514 --image-project=debian-cloud
--boot-disk-size "10" --boot-disk-type "pd-standard" \
--boot-disk-device-name "nginxstack-$i"; \
done

# Creating instance with startup script

gcloud compute instances create example-instance --tags http-server --metadata startup-script='#! /bin/bash # Installs apache and a custom homepage # Go to root directory sudo su - # For automatic Updates apt-get update # Install apache apt-get install -y apache2 '

# Add startup script for running instance

gcloud compute instances add-metadata [INSTANCE NAME] --metadata-from-file startup-script=path/to/file

# Creating and then attaching persistent disk to instance

gcloud compute disks create [DISK NAME] --size=100GB --zone [ZONE NAME]
gcloud compute instances attach-disk [INSTANCE NAME] --disk [DISK NAME] --zone [ZONE NAME]
ls -l /dev/disk/by-id #To check persistent disk in instance
sudo lsblk
sudo mkfs.ext4 -m 0 -F -E lazy_itable_init=0, lazy_journal_init=0, discard /dev/sda
sudo mkdir /mnt/my-mounting-dir
sudo mount -o discard, defaults /dev/sda /mnt/my-mounting-dir
sudo chmod a+w /mnt/my-mounting-dir


# Sharing a persistent disk between multiple instances
gcloud compute instances attach-disk test-instance --disk sdb --mode ro ### run command on all instances

# Resising a persistent disk
gcloud compute disk resize [DISK NAME] —size [DISK_SIZE]
sudo growpart /dev/sda [PARTITION NUMBER]
sudo resize2fs /dev/sda/[PARTITION_NUMBER]
df -h


# create an image of a disk

gcloud compute images create [INSTANCE-NAME] --source-disk [DISK-NAME] --source-disk-zone [ZONE-NAME] --family debian-9
gcloud compute images create [IMAGE_NAME] --source-image [SOURCE_IMAGE] --source-image-project [IMAGE_PROJECT] --family [IMAGE_FAMILY]


