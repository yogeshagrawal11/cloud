variable appname {}
variable region {}
variable subnet_cidr {}
variable ami { type = map}
variable instance_type {}
variable localip {}
variable key_name {}
variable iam_instance_role {}


variable efsname {}
variable pathname {}


variable azcount {} 

data aws_availability_zones "azs" {}


data "aws_ssm_parameter" "data_key_name" {
    name = "ec2_keyname"
}

data "template_file" "user_data_file" {
    template = file("user_data_import.tpl")
    count = length(var.azcount)
    vars =  {
        
        efsip = aws_efs_mount_target.app-mount-target[count.index].ip_address
        fspath = var.pathname
        
    }
}


#-------  Provider Information  ------------
provider "aws" {
  version = "~> 2.0"
  region  = var.region
  profile = "ya"

}

#-------  VPC Config ------------
resource "aws_vpc" "app_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name    = "${var.appname}_vpc"
    appname = "${var.appname}"
  }
}


#------- Internet Gateway  ------------
resource "aws_internet_gateway" "app_ig" {
  vpc_id = aws_vpc.app_vpc.id

  tags = {
    Name    = "${var.appname}_ig"
    appname = "${var.appname}"
  }
}

#------- Non Default Route Table   ------------
resource "aws_route_table" "app_rt" {
  vpc_id = aws_vpc.app_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.app_ig.id
  }
}


#-------  Subnet config  ------------
### this will create sebnets on all availability zone
resource "aws_subnet" "app_subnets" {
  vpc_id = aws_vpc.app_vpc.id
  count = length(data.aws_availability_zones.azs.names)
  cidr_block        = element(var.subnet_cidr,count.index)
  availability_zone = data.aws_availability_zones.azs.names[count.index]
  tags = {
    Name    = "${var.appname}_subnet_${element(data.aws_availability_zones.azs.names,count.index)}"
    appname = var.appname
  }
}



#------- Route table association to Subnet  ------------
resource "aws_route_table_association" "app_rt_subnets" {
  count = length(data.aws_availability_zones.azs.names)
  subnet_id      = aws_subnet.app_subnets[count.index].id
  route_table_id = aws_route_table.app_rt.id
}




#-------  Security group ------------
resource "aws_security_group" "app_sg_allow_localip" {
  vpc_id      = aws_vpc.app_vpc.id
  name        = "allow_localip"
  description = "Allow HTTP inbound traffic"
  ingress {
    description = "http to VPC from localip"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.localip,]
  }

  ingress {
    description = "http to VPC from localip"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups  = [aws_security_group.app_sg_allow_public.id]
  }

  ingress {
    description = "ssh to VPC from localip"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.localip}"]
  }

  ingress {
    description = "ping to VPC from localip"
    from_port   = 0
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = ["${var.localip}"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "allow_http"
  }
}


resource "aws_security_group" "app_sg_allow_public" {
  vpc_id      = aws_vpc.app_vpc.id
  name        = "allow_publicip"
  description = "Allow HTTP inbound traffic"
  ingress {
    description = "http to VPC from localip"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "allow_http"
  }
}




#------- EC2 Instance configuration  ------------

 

resource "aws_instance" "app-web" {
  ami                         = lookup(var.ami,var.region)
  instance_type               = var.instance_type
  vpc_security_group_ids      = [aws_security_group.app_sg_allow_localip.id]
  count = length(var.azcount)
  subnet_id                   = aws_subnet.app_subnets[count.index].id
  associate_public_ip_address = true
  key_name                    = data.aws_ssm_parameter.data_key_name.value
  iam_instance_profile        = var.iam_instance_role
  user_data                   = data.template_file.user_data_file[count.index].rendered
  tags = {
    Name = "${var.appname}-web",
    mapefs = var.efsname 

    efsip = aws_efs_mount_target.app-mount-target[count.index].ip_address
  }
}



#

#----------- EFS FS ------------------

resource "aws_efs_file_system" "app-efs1" {
  creation_token = var.efsname 
  performance_mode = "generalPurpose"

  tags = {
    Name = "${var.appname}-${var.efsname}"
    appname = var.appname
  }
}


resource "aws_efs_mount_target" "app-mount-target" {
  file_system_id = aws_efs_file_system.app-efs1.id
  count = length(var.azcount)
  subnet_id      = aws_subnet.app_subnets[count.index].id
  security_groups = [aws_security_group.app-ingress-efs-sg.id]
  #ip_address = aws_instance.app-web.private_ip

}



resource "aws_efs_access_point" "app-efs_access_point" {
  file_system_id = aws_efs_file_system.app-efs1.id

}

resource "aws_security_group" "app-ingress-efs-sg" {
   name        = "${var.appname}-efs-sg"
   vpc_id      = aws_vpc.app_vpc.id

   // NFS
   ingress {
     security_groups = [aws_security_group.app_sg_allow_localip.id]
     from_port = 2049
     to_port = 2049
     protocol = "tcp"
   }

   // Terraform removes the default rule
   egress {
     security_groups = [aws_security_group.app_sg_allow_localip.id]
     from_port = 0
     to_port = 0
     protocol = "-1"
   }
}



output "efsip" {
    value = {
        for mounttarget in aws_efs_mount_target.app-mount-target:
        mounttarget.id => mounttarget.ip_address 
    }
}


output "instact_public_ip" {
    #count = length(data.aws_availability_zones.azs.names)
    
    value = {
        for instance in aws_instance.app-web:
            instance.id =>  instance.public_ip 
    }
}

