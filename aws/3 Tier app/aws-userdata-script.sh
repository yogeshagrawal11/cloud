#!/bin/bash
sudo yum update -y
sudo amazon-linux-extras install -y lamp-mariadb10.2-php7.2 php7.2
sudo yum install -y httpd 

usermod -a -G apache ec2-user
chown -R ec2-user:apache /var/www
chmod 2775 /var/www
find /var/www -type d -exec chmod 2775 {} \;
find /var/www -type f -exec chmod 0664 {} \;

echo "<HTML><table style="width:30%" > <tr> <th> Environment </th> <th> Value </th></tr>" > /var/www/html/index.html


echo "<tr><td>" >> /var/www/html/index.html
TOKEN=`curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"` && curl -H "X-aws-ec2-metadata-token: $TOKEN"  http://169.254.169.254/latest/meta-data/hostname | tee abc
echo "Instace hostname </td><td>" >> /var/www/html/index.html
cat abc  >> /var/www/html/index.html
echo "</td></tr>" >> /var/www/html/index.html


echo "<tr><td>" >> /var/www/html/index.html
echo "Instance id </td><td> " >> /var/www/html/index.html
curl -H "X-aws-ec2-metadata-token: $TOKEN"  http://169.254.169.254/latest/meta-data/instance-id | tee abc 
cat abc  >> /var/www/html/index.html
echo "</td></tr>" >> /var/www/html/index.html


echo "<tr><td>" >> /var/www/html/index.html
echo "public ip </td><td> " >> /var/www/html/index.html
curl -H "X-aws-ec2-metadata-token: $TOKEN"  http://169.254.169.254/latest/meta-data/public-ipv4| tee abc 
cat abc  >> /var/www/html/index.html
echo "</td></tr>" >> /var/www/html/index.html


echo "<tr><td>" >> /var/www/html/index.html
echo "private IP </td><td> " >> /var/www/html/index.html
curl -H "X-aws-ec2-metadata-token: $TOKEN"  http://169.254.169.254/latest/meta-data/local-ipv4 | tee abc 
cat abc  >> /var/www/html/index.html
echo "</td></tr>" >> /var/www/html/index.html


echo "<tr><td>" >> /var/www/html/index.html
echo "Zone </td><td>" >> /var/www/html/index.html
curl -H "X-aws-ec2-metadata-token: $TOKEN"  http://169.254.169.254/latest/meta-data/placement/availability-zone/ | tee abc
cat abc  >> /var/www/html/index.html
echo "</td></tr>" >> /var/www/html/index.html

echo "</table></html>" >> /var/www/html/index.html
rm abc 
sudo service httpd restart