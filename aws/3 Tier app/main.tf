variable appname {}
variable region {}
variable subnet_cidr {}
variable ami { type = map}
variable instance_type {}
variable localip {}
variable key_name {}
#variable iam_instance_role {}


variable dynamodbtablename {}
variable dynamodbreadcapacity {}
variable dynamodbwritecapacity {}
variable dynamodb_hashkey {}
variable dynamodb_hashkey_type {}

variable accesslogbucket_parameter_name {} 


data "aws_ssm_parameter" "s3bucket" {
  name = "s3bucket"
}

data "aws_ssm_parameter" "accesslogbucket" {
  name = var.accesslogbucket_parameter_name
}

data aws_availability_zones "azs" {}

data "template_file" "user_data_file" {
    template = file("user_data.tpl")
    vars =  {
        s3bucket = data.aws_ssm_parameter.s3bucket.value
        
    }
}


#-------  Provider Information  ------------
provider "aws" {
  version = "~> 2.0"
  region  = var.region
  profile = "ya"
  #access_key = "my-access-key"
  #secret_key = "my-secret-key"
}

#-------  VPC Config ------------
resource "aws_vpc" "app_vpc" {
  cidr_block = "10.0.0.0/16"
  #name = "${var.appname}_vpc"
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
  #count = "${length(var.azs)}"
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

resource "aws_iam_role_policy" "app_s3_dynamodb_access_role_policy" {
  name = "${var.appname}-s3access_role_policy"
  role = aws_iam_role.app_s3_dynamodb_access_role.id
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:Get*",
                "s3:List*",
                "dynamodb:*",
                "iam:PassRole",
                "iam:ListInstanceProfiles",
                "ec2:*"
            ],
            "Resource": "*"
        }
    ]
}
  EOF
}

resource "aws_iam_role" "app_s3_dynamodb_access_role" {
  name = "${var.appname}-s3access_role"
  #attach policy AWSLambdaBasicExecutionRole and AWSXRayDaemonWriteAccess to role 
  #"Action" :  "sts:AssumeRole",
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "ec2.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
      }
    ]
  }
  EOF
}


resource "aws_iam_instance_profile" "app_instance_profile" {
  name = "${var.appname}-instance-profile"
  role = aws_iam_role.app_s3_dynamodb_access_role.name
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
  subnet_id                   = aws_subnet.app_subnets[0].id
  associate_public_ip_address = true
  key_name                    = var.key_name
  #iam_instance_profile        = var.iam_instance_role
  iam_instance_profile        = aws_iam_instance_profile.app_instance_profile.name
  user_data                   = data.template_file.user_data_file.rendered
  
  tags = {
    Name = "${var.appname}-web"
  }
}



### DynamodDB

resource "aws_dynamodb_table" "app-dynamodb-table" {
  name = var.dynamodbtablename 
  #billingmode = "PROVISIONED"
  read_capacity = var.dynamodbreadcapacity
  write_capacity = var.dynamodbwritecapacity
  hash_key = var.dynamodb_hashkey 
  #range_key = var.dynamodb_rangekey

  attribute {
    name = var.dynamodb_hashkey
    type = var.dynamodb_hashkey_type
  }


  
  tags = {
    Name = "${var.appname}-dynamodb-${var.dynamodbtablename}"
    appname = var.appname

  }
}



#------------  EC2 AMI --------------------------

resource "aws_ami_from_instance" "app-ami" {
  name               = "${var.appname}-golden-ami"
  source_instance_id = aws_instance.app-web.id
}

#-----------  Launch Configuration ----------------

resource "aws_launch_configuration" "app-launch-config" {
  image_id = aws_ami_from_instance.app-ami.id
  name = "${var.appname}-launch-config"
  instance_type = var.instance_type
  
  iam_instance_profile        = aws_iam_instance_profile.app_instance_profile.name
  associate_public_ip_address  = true
  security_groups     = [aws_security_group.app_sg_allow_localip.id]
  key_name = var.key_name
  user_data =  data.template_file.user_data_file.rendered
}

#------- Auto Scalling group ----------------------

resource "aws_autoscaling_group" "app-asg" {
  name               = "${var.appname}-asg"
  max_size           = 3
  min_size           = 2
  desired_capacity   = 2
  launch_configuration = aws_launch_configuration.app-launch-config.name
  vpc_zone_identifier       = [aws_subnet.app_subnets[0].id,aws_subnet.app_subnets[1].id]
  lifecycle {
    create_before_destroy = true
  }
  #load_balancers = [aws_lb.app-lb.id]
  target_group_arns = [aws_lb_target_group.app-lb-tg.arn]
  depends_on = [aws_lb_target_group.app-lb-tg,aws_lb.app-lb]

}



#---------- Elastic IP for load balancer -------------
resource "aws_eip" "lb_eip" {
  vpc = true
  tags = {
    name = "${var.appname}-eip"
    appname = var.appname
    type = "eip"
  }
}



#--------- Application Load Balancer -----------------

# Load balancer
resource "aws_lb" "app-lb" {
  name = "${var.appname}-lb"
  internal = false
  load_balancer_type = "application"
  security_groups = [aws_security_group.app_sg_allow_public.id]
  subnets = [aws_subnet.app_subnets[0].id,aws_subnet.app_subnets[1].id]

  tags = {
    name = "${var.appname}-lb"
    appname = var.appname
  }


  access_logs {
    bucket = data.aws_ssm_parameter.accesslogbucket.value
    prefix = "${var.appname}-lb"
    enabled = true
  }

}

# LB listener

resource "aws_lb_listener" "app-lb_listner" {
  load_balancer_arn = aws_lb.app-lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.app-lb-tg.arn
  }
}
#LB target group 
resource "aws_lb_target_group" "app-lb-tg" {
  name     = "${var.appname}-lb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.app_vpc.id

  stickiness {
    type = "lb_cookie"
    cookie_duration = 20 ## sec
    enabled = true
  }

  health_check {
    enabled = true
    interval = 10  ## 10 sec 
    path = "/"
    protocol = "HTTP"
    timeout = 8
    healthy_threshold = 3
    unhealthy_threshold = 3

  }
}





output "DNS_public_link" {  
    value = aws_lb.app-lb.dns_name
}

