#!/bin/bash
sudo yum update
sudp yum upgrade
sudo amazon-linux-extras install ansible2
### mounting EFS IP=${efsip} export into ${fspath}
sudo mkdir ${fspath}
sudo mount ${efsip}:/ ${fspath}
