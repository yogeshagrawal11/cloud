#!/bin/bash
/usr/bin/aws s3 cp ${s3bucket}/userdata/aws-userdata-script.sh /root/userdata/aws-userdata-script.sh
/usr/bin/aws s3 cp ${s3bucket}/userdata/nps_parks.csv /root/userdata/nps_parks.csv
/usr/bin/aws s3 cp ${s3bucket}/userdata/dynamodb.py /root/userdata/dynamodb.py
chmod u+x /root/userdata/aws-userdata-script.sh
/root/userdata/aws-userdata-script.sh
yum install python3 -y 
python3 -m pip install --upgrade pip
python3 -m pip install boto3
python3 -m pip install mysql-connector-python
chmod u+x /root/userdata/dynamodb.py
python3 /root/userdata/dynamodb.py