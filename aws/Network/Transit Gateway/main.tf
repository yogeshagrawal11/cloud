variable appname {
  default = "ya"
}
variable region {
  default = "us-west-2"
}


variable subnet_cidr {
  default = "10.0.1.0/24"
}
variable ami { 
  default = "ami-0528a5175983e7f28" 
}

variable instance_type {
  default = "t2.micro"
}

variable iam_instance_role {
  default = "s3-readonly-access"
}


variable keypair-name {
  default = "ec2-keypair"
}


#-------  Provider Information  ------------


variable localip {
  default = "0.0.0.0/0"
}



#-------  Provider Information  ------------
provider "aws" {
  version = "~> 2.0"
  region  = var.region
  profile = "ya"
}


provider "google" {
  region  = "us-west3"
  zone    = "us-west3-a"
  project = var.gcpprojectid

}

##############   Transit Gateway   ####################



resource "aws_vpc" "management_vpc" {
  cidr_block = "10.1.0.0/16"
  tags = {
    "Name"    = "management_vpc"
    "appname" = var.appname
  }
}


resource "aws_vpc" "project_vpc1" {
  cidr_block = "10.2.0.0/16"
  tags = {
    "Name"    = "project_vpc1"
    "appname" = var.appname
  }
}

resource "aws_vpc" "project_vpc2" {
  cidr_block = "10.3.0.0/16"
  tags = {
    "Name"    = "project_vpc2"
    "appname" = var.appname
  }
}

resource "aws_vpc" "private_vpc" {
  cidr_block = "10.4.0.0/16"
  tags = {
    "Name"    = "private_vpc"
    "appname" = var.appname
  }
}



#------- Internet Gateway  ------------
resource "aws_internet_gateway" "management_vpc_ig" {
  vpc_id = aws_vpc.management_vpc.id
  tags = {
    Name = "management_vpc_ig"
  }
}


resource "aws_internet_gateway" "project_vpc1_ig" {
  vpc_id = aws_vpc.project_vpc1.id
  tags = {
    Name = "project_vpc1_ig"
  }
}


resource "aws_internet_gateway" "project_vpc2_ig" {
  vpc_id = aws_vpc.project_vpc2.id
  tags = {
    Name = "project_vpc2_ig"
  }
}


resource "aws_internet_gateway" "private_vpc_ig" {
  vpc_id = aws_vpc.private_vpc.id
  tags = {
    Name = "private_vpc_ig"
  }
}

#-------  Subnet config  ------------
### this will create sebnets on all availability zone
resource "aws_subnet" "management_vpc_subnet1" {
  vpc_id = aws_vpc.management_vpc.id
  #count = "${length(var.azs)}"
  cidr_block        = "10.1.1.0/24"
  availability_zone = "us-west-2a"
  tags = {
    Name    = "management_vpc_subnet1"
    appname = var.appname
  }
}


resource "aws_subnet" "project_vpc1_subnet1" {
  vpc_id = aws_vpc.project_vpc1.id
  #count = "${length(var.azs)}"
  cidr_block        = "10.2.1.0/24"
  availability_zone = "us-west-2a"
  tags = {
    Name    = "project_vpc1_subnet1"
    appname = var.appname
  }
}

resource "aws_subnet" "project_vpc2_subnet1" {
  vpc_id = aws_vpc.project_vpc2.id
  #count = "${length(var.azs)}"
  cidr_block        = "10.3.1.0/24"
  availability_zone = "us-west-2a"
  tags = {
    Name    = "project_vpc2_subnet1"
    appname = var.appname
  }
}


resource "aws_subnet" "private_vpc_subnet1" {
  vpc_id = aws_vpc.private_vpc.id
  #count = "${length(var.azs)}"
  cidr_block        = "10.4.1.0/24"
  availability_zone = "us-west-2a"
  tags = {
    Name    = "private_vpc_subnet1"
    appname = var.appname
  }
}

#------ internet route 
resource "aws_route_table" "management_vpc_rt" {
  vpc_id = aws_vpc.management_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.management_vpc_ig.id
  }
  
  route {
    cidr_block = "10.2.0.0/16"
    transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  }
  route {
    cidr_block = "10.3.0.0/16"
    transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  }

  route {
    cidr_block = "10.4.0.0/16"
    transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  }
  
  tags = {
    "Name" = "management_vpc_rt"
  }
}

resource "aws_route_table" "project_vpc1_rt" {
  vpc_id = aws_vpc.project_vpc1.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.project_vpc1_ig.id
  }
  
  route {
    cidr_block = "10.1.0.0/16"
    transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  }
  route {
    cidr_block = "10.3.0.0/16"
    transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  }
  
  tags = {
    "Name" = "project_vpc1_rt"
  }
}

resource "aws_route_table" "project_vpc2_rt" {
  vpc_id = aws_vpc.project_vpc2.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.project_vpc2_ig.id
  }
  
    route {
    cidr_block = "10.1.0.0/16"
    transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  }
  route {
    cidr_block = "10.2.0.0/16"
    transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  }
  
  tags = {
    "Name" = "project_vpc2_rt"
  }
}



resource "aws_route_table" "private_vpc_rt" {
  vpc_id = aws_vpc.private_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.private_vpc_ig.id
  }
  
    route {
    cidr_block = "10.1.0.0/16"
    transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  }

  tags = {
    "Name" = "private_vpc_rt"
  }
}



#------- Route table association to Subnet  ------------
resource "aws_route_table_association" "management_rt_subnets" {
  subnet_id      = aws_subnet.management_vpc_subnet1.id
  route_table_id = aws_route_table.management_vpc_rt.id
}

resource "aws_route_table_association" "project_vpc1_rt_subnets" {
  subnet_id      = aws_subnet.project_vpc1_subnet1.id
  route_table_id = aws_route_table.project_vpc1_rt.id
}

resource "aws_route_table_association" "project_vpc2_rt_subnets" {
  subnet_id      = aws_subnet.project_vpc2_subnet1.id
  route_table_id = aws_route_table.project_vpc2_rt.id
}


resource "aws_route_table_association" "private_vpc_rt_subnets" {
  subnet_id      = aws_subnet.private_vpc_subnet1.id
  route_table_id = aws_route_table.private_vpc_rt.id
}

#-------  Security group ------------
resource "aws_security_group" "app_sg_allow_localip_management_vpc" {
  vpc_id      = aws_vpc.management_vpc.id
  name        = "allow_localip"
  description = "Allow HTTP inbound traffic"

  ingress {
    description = "ssh to VPC from localip"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.localip}", "10.1.0.0/16", "10.2.0.0/16", "10.3.0.0/16" , "10.4.0.0/16"]
  }

  ingress {
    description = "ping to VPC from localip"
    from_port   = "-1"
    to_port     = "-1"
    protocol    = "icmp"
    cidr_blocks = ["${var.localip}", "10.1.0.0/16", "10.2.0.0/16", "10.3.0.0/16", "10.4.0.0/16"]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    "Name" = "app_sg_allow_localip_management_vpc"
  }
}

resource "aws_security_group" "app_sg_allow_localip_project_vpc1" {
  vpc_id      = aws_vpc.project_vpc1.id
  name        = "allow_localip"
  description = "Allow HTTP inbound traffic"

  ingress {
    description = "ssh to VPC from localip"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.localip}", "10.1.0.0/16", "10.2.0.0/16", "10.3.0.0/16"]
  }

  ingress {
    description = "ping to VPC from localip"
    from_port   = "-1"
    to_port     = "-1"
    protocol    = "icmp"
    cidr_blocks = ["${var.localip}", "10.1.0.0/16", "10.2.0.0/16", "10.3.0.0/16"]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    "Name" = "app_sg_allow_localip_project_vpc1"
  }
}

resource "aws_security_group" "app_sg_allow_localip_project_vpc2" {
  vpc_id      = aws_vpc.project_vpc2.id
  name        = "allow_localip"
  description = "Allow HTTP inbound traffic"

  ingress {
    description = "ssh to VPC from localip"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.localip}", "10.1.0.0/16", "10.2.0.0/16", "10.3.0.0/16"]
  }

  ingress {
    description = "ping to VPC from localip"
    from_port   = "-1"
    to_port     = "-1"
    protocol    = "icmp"
    cidr_blocks = ["${var.localip}", "10.1.0.0/16", "10.2.0.0/16", "10.3.0.0/16"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    "Name" = "app_sg_allow_localip_project_vpc2"
  }
}

## private VPC only communicate with management VPC
resource "aws_security_group" "app_sg_allow_localip_private_vpc" {
  vpc_id      = aws_vpc.private_vpc.id
  name        = "allow_localip"
  description = "Allow HTTP inbound traffic"

  ingress {
    description = "ssh to VPC from localip"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.localip}", "10.1.0.0/16"]
  }

  ingress {
    description = "ping to VPC from localip"
    from_port   = "-1"
    to_port     = "-1"
    protocol    = "icmp"
    cidr_blocks = ["${var.localip}", "10.1.0.0/16"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    "Name" = "app_sg_allow_localip_private_vpc"
  }
}


#--------------- Transit Gateway Configuration -----------------


resource "aws_ec2_transit_gateway" "tgw" {
  description = "Transit Gateway"
  tags = {
    "Name" = "tgw"
  }
}

# Attach VPC to Transit Gateway
resource "aws_ec2_transit_gateway_vpc_attachment" "tgw_to_management_vpc" {
  subnet_ids         = [aws_subnet.management_vpc_subnet1.id]
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  vpc_id             = aws_vpc.management_vpc.id
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation  = false

  tags = {
    "Name" = "tgw_to_management_vpc"
  }

}

resource "aws_ec2_transit_gateway_vpc_attachment" "tgw_to_project_vpc1" {
  subnet_ids         = [aws_subnet.project_vpc1_subnet1.id]
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  vpc_id             = aws_vpc.project_vpc1.id
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation  = false
  tags = {
    "Name" = "tgw_to_project_vpc1"
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "tgw_to_project_vpc2" {
  subnet_ids         = [aws_subnet.project_vpc2_subnet1.id]
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  vpc_id             = aws_vpc.project_vpc2.id
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation  = false
  tags = {
    "Name" = "tgw_to_project_vpc2"
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "tgw_to_private_vpc" {
  subnet_ids         = [aws_subnet.private_vpc_subnet1.id]
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  vpc_id             = aws_vpc.private_vpc.id
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation  = false
  tags = {
    "Name" = "tgw_to_private_vpc"
  }
}

# Create Route table for each VPC 
resource "aws_ec2_transit_gateway_route_table" "management_vpc_routetable" {
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  tags = {
    "Name" = "management_vpc_routetable"
  }
}

resource "aws_ec2_transit_gateway_route_table" "project_vpc_routetable" {
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  tags = {
    "Name" = "project_vpc_routetable"
  }
}



resource "aws_ec2_transit_gateway_route_table" "private_vpc_routetable" {
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  tags = {
    "Name" = "private_vpc_routetable"
  }
}

# Associate VPC to route table 
resource "aws_ec2_transit_gateway_route_table_association" "management_vpc_routetable_to_public_vpc1" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.tgw_to_management_vpc.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.management_vpc_routetable.id
}

/*
resource "aws_ec2_transit_gateway_route_table_association" "management_vpc_routetable_to_public_vpc2" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.tgw_to_project_vpc2.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.management_vpc_routetable.id

}

resource "aws_ec2_transit_gateway_route_table_association" "management_vpc_routetable_to_private_vpc" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.tgw_to_private_vpc.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.management_vpc_routetable.id

}
*/
resource "aws_ec2_transit_gateway_route_table_association" "project_routetable_to_vpc1" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.tgw_to_project_vpc1.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.project_vpc_routetable.id

}

resource "aws_ec2_transit_gateway_route_table_association" "project_routetable_to_vpc2" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.tgw_to_project_vpc2.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.project_vpc_routetable.id

}


resource "aws_ec2_transit_gateway_route_table_association" "private_routetable_to_vpc" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.tgw_to_private_vpc.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.private_vpc_routetable.id

}

# Route Propogation Allow VPC data flow 
# Allow management VPC to all 
/*
resource "aws_ec2_transit_gateway_route_table_propagation" "management_vpc_to_management_vpc" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.tgw_to_management_vpc.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.management_vpc_routetable.id

}
*/
# Allow VPC 2 to VPC 1 traffic, VPC2 routetable and vpc1 attachement
resource "aws_ec2_transit_gateway_route_table_propagation" "management_vpc_to_project_vpc1" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.tgw_to_project_vpc1.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.management_vpc_routetable.id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "management_vpc_to_project_vpc2" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.tgw_to_project_vpc2.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.management_vpc_routetable.id

}

resource "aws_ec2_transit_gateway_route_table_propagation" "management_vpc_to_private_vpc" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.tgw_to_private_vpc.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.management_vpc_routetable.id

}


# Allow  management  VPC to project route table  traffic
resource "aws_ec2_transit_gateway_route_table_propagation" "project_vpc_to_project_vpc1" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.tgw_to_project_vpc1.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.project_vpc_routetable.id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "project_vpc_to_project_vpc2" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.tgw_to_project_vpc2.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.project_vpc_routetable.id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "project_vpc_to_management_vpc" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.tgw_to_management_vpc.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.project_vpc_routetable.id
}



# Allow  management  VPC to private route table  traffic
resource "aws_ec2_transit_gateway_route_table_propagation" "private_vpc_to_management_vpc" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.tgw_to_management_vpc.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.private_vpc_routetable.id
}

/*

# Allow VPC 1 to VPC 3 traffic, VPC1 routetable and vpc3 attachement
resource "aws_ec2_transit_gateway_route_table_propagation" "vpc1_to_vpc3" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.tgw_to_public_vpc2.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.vpc1_routetable.id
}

# Allow VPC 3 to VPC 1 traffic, VPC2 routetable and vpc1 attachement
resource "aws_ec2_transit_gateway_route_table_propagation" "vpc3_to_vpc1" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.tgw_to_vpc1.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.vpc3_routetable.id
}
*/
# VPC 2 and VPC3 will not be able to talk to each other. 



#--------   Instances in each subnet 


resource "aws_instance" "mgmt_ADserver" {
  ami                         = var.ami
  instance_type               = var.instance_type
  vpc_security_group_ids      = [aws_security_group.app_sg_allow_localip_management_vpc.id]
  subnet_id                   = aws_subnet.management_vpc_subnet1.id
  associate_public_ip_address = true
  key_name                    = var.keypair-name
  iam_instance_profile        = var.iam_instance_role
  tags = {
    Name = "mgmt_ADserver"
  }

  user_data                   = <<EOF
#!/bin/bash
sudo yum install telnet.x86_64
/usr/bin/aws s3 cp s3://yogeshagrawal/userdata/cloudtechsavvy.sh /tmp/cloudtechsavvy.sh
chmod u+x /tmp/cloudtechsavvy.sh
/tmp/cloudtechsavvy.sh
EOF
}


resource "aws_instance" "project_instance1" {
  ami                         = var.ami
  instance_type               = var.instance_type
  vpc_security_group_ids      = [aws_security_group.app_sg_allow_localip_project_vpc1.id]
  subnet_id                   = aws_subnet.project_vpc1_subnet1.id
  associate_public_ip_address = true
  key_name                    = var.keypair-name
  iam_instance_profile        = var.iam_instance_role
  tags = {
    Name = "project_instance1"
  }

  user_data                   = <<EOF
#!/bin/bash
sudo yum install telnet.x86_64
/usr/bin/aws s3 cp s3://yogeshagrawal/userdata/cloudtechsavvy.sh /tmp/cloudtechsavvy.sh
chmod u+x /tmp/cloudtechsavvy.sh
/tmp/cloudtechsavvy.sh
EOF
}

resource "aws_instance" "project_instance2" {
  ami                         = var.ami
  instance_type               = var.instance_type
  vpc_security_group_ids      = [aws_security_group.app_sg_allow_localip_project_vpc2.id]
  subnet_id                   = aws_subnet.project_vpc2_subnet1.id
  associate_public_ip_address = true
  key_name                    = var.keypair-name
  iam_instance_profile        = var.iam_instance_role
  tags = {
    Name = "project_instance2"
  }

  user_data                   = <<EOF
#!/bin/bash
sudo yum install telnet.x86_64
/usr/bin/aws s3 cp s3://yogeshagrawal/userdata/cloudtechsavvy.sh /tmp/cloudtechsavvy.sh
chmod u+x /tmp/cloudtechsavvy.sh
/tmp/cloudtechsavvy.sh
EOF
}

resource "aws_instance" "private_instance" {
  ami                         = var.ami
  instance_type               = var.instance_type
  vpc_security_group_ids      = [aws_security_group.app_sg_allow_localip_private_vpc.id]
  subnet_id                   = aws_subnet.private_vpc_subnet1.id
  associate_public_ip_address = true
  key_name                    = var.keypair-name
  iam_instance_profile        = var.iam_instance_role
  tags = {
    Name = "private_instance"
  }

  user_data                   = <<EOF
#!/bin/bash
sudo yum install telnet.x86_64
/usr/bin/aws s3 cp s3://yogeshagrawal/userdata/cloudtechsavvy.sh /tmp/cloudtechsavvy.sh
chmod u+x /tmp/cloudtechsavvy.sh
/tmp/cloudtechsavvy.sh
EOF
}


output "mgmt_ADserver_public" {
  value = aws_instance.mgmt_ADserver.public_ip
}
output "mgmt_ADserver_private" {
  value = aws_instance.mgmt_ADserver.private_ip
}


output "project_instance1_public" {
  value = aws_instance.project_instance1.public_ip
}
output "project_instance1_private" {
  value = aws_instance.project_instance1.private_ip
}


output "project_instance2_public" {
  value = aws_instance.project_instance2.public_ip
}
output "project_instance2_private" {
  value = aws_instance.project_instance2.private_ip
}

output "private_instance_public" {
  value = aws_instance.private_instance.public_ip
}
output "private_instance_private" {
  value = aws_instance.private_instance.private_ip
}

