variable appname {
  type = string
  default = "ya"
}

variable region {
  type = string
  default = "us-west-2"
}
variable subnet_cidr {
  type = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24", "10.0.4.0/24"]
}
variable ami { 
  type = map 
  default = {
  "us-west-2" = "ami-0e34e7b9ca0ace12d"
  "us-east-2" = "ami-026dea5602e368e96"
  }
}




variable instance_type {
  type = string
  default = "t2.micro"
}
variable localip {
  type = string
  default = "0.0.0.0/0" #### Add your system ip to test ssh and ping connectivity
}
variable key_name {
  type = string
  default = "ec2-keypair"
}
variable gcpprojectid {
  type = string
  default = "yagrawal999"
}

variable tunnelcount {
  type = number
  default = 2 
}


variable "bgp_cr_session_range" {
  type        = list(string)
  description = "Please enter the cloud-router interface IP/Session IP network"
  default     = ["169.254.1.8/30", "169.254.1.12/30"]
}

variable "bdp_tunnelip" {
  type        = list(string)
  description = "Please enter the remote environments BGP Session IP"
  default     = ["169.254.1.9", "169.254.1.10","169.254.1.13", "169.254.1.14"]
}


data "aws_ssm_parameter" "ec2_keyname" {
  name = "ec2_keyname"
}


#-------  Provider Information  ------------
provider "aws" {
  version = "~> 2.0"
  region  = var.region
  profile = "ya"
}


resource "aws_vpc" "app_vpc1" {
  cidr_block = "10.1.0.0/16"
  tags = {
    "name"    = "${var.appname}_vpc1"
    "appname" = var.appname
  }
}



#------- Internet Gateway  ------------
resource "aws_internet_gateway" "app_ig1" {
  vpc_id = aws_vpc.app_vpc1.id
  tags = {
    Name = "vpn_ig1"
  }
}


#------- Non Default Route Table   ------------
resource "aws_route_table" "app_rt1" {
  vpc_id = aws_vpc.app_vpc1.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.app_ig1.id
  }
  tags = {
    "Name" = "app_rt1"
  }
}


#-------  Subnet config  ------------
### this will create sebnets on all availability zone
resource "aws_subnet" "app_subnet1" {
  vpc_id = aws_vpc.app_vpc1.id
  cidr_block        = "10.1.1.0/24"
  availability_zone = "us-west-2a"
  tags = {
    appname = var.appname
  }
}



#------- Route table association to Subnet  ------------
resource "aws_route_table_association" "app_rt_subnets" {
  subnet_id      = aws_subnet.app_subnet1.id
  route_table_id = aws_route_table.app_rt1.id
}


#-------  Security group ------------
resource "aws_security_group" "app_sg_allow_localip" {
  vpc_id      = aws_vpc.app_vpc1.id
  name        = "allow_localip"
  description = "Allow HTTP inbound traffic"
  ingress {
    description = "http to VPC from localip"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.localip, ]
  }


  ingress {
    description = "ssh to VPC from localip"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.localip}", "10.100.1.0/24"]
  }

  ingress {
    description = "ping to VPC from localip"
    from_port   = 0
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = ["${var.localip}", "10.100.1.0/24"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    "Name" = "allow_http1"
  }
}


resource "aws_eip" "one" {

}

resource "aws_customer_gateway" "cust_gw1" {
  bgp_asn    = 65001
  ip_address = google_compute_address.vpn_static_ip.address
  type       = "ipsec.1"

}


resource "aws_vpn_gateway" "vpn_gw1" {
  vpc_id            = aws_vpc.app_vpc1.id
  availability_zone = "us-west-2a"
  amazon_side_asn   = 65002

  tags = {
    Name = "vpn_gw1"
  }
}


resource "aws_vpn_gateway_attachment" "vpn_attachment1" {
  vpc_id         = aws_vpc.app_vpc1.id
  vpn_gateway_id = aws_vpn_gateway.vpn_gw1.id
}



resource "aws_vpn_gateway_route_propagation" "vpn_gw_rt_1" {
  vpn_gateway_id = aws_vpn_gateway.vpn_gw1.id
  route_table_id = aws_route_table.app_rt1.id
}



resource "aws_vpn_connection" "aws_to_gcp" {
  vpn_gateway_id        = aws_vpn_gateway.vpn_gw1.id
  customer_gateway_id   = aws_customer_gateway.cust_gw1.id
  type                  = "ipsec.1"
  static_routes_only    = false
  tunnel1_inside_cidr  = var.bgp_cr_session_range[0]
  tunnel2_inside_cidr  = var.bgp_cr_session_range[1]
}



resource "aws_ssm_parameter" "vpn_sharedkey_aws_to_gcp_tunnel1" {
  name  = "vpn_sharedkey_aws_to_gcp_tunnel1"
  type  = "String"
  value = aws_vpn_connection.aws_to_gcp.tunnel1_preshared_key
}



resource "aws_ssm_parameter" "vpn_sharedkey_aws_to_gcp_tunnel2" {
  name  = "vpn_sharedkey_aws_to_gcp_tunnel2"
  type  = "String"
  value = aws_vpn_connection.aws_to_gcp.tunnel2_preshared_key
}



resource "aws_instance" "app-web1" {
  ami                         = lookup(var.ami, var.region)
  instance_type               = var.instance_type
  vpc_security_group_ids      = [aws_security_group.app_sg_allow_localip.id]
  subnet_id                   = aws_subnet.app_subnet1.id
  associate_public_ip_address = true
  key_name                    = var.key_name
  tags = {
    name = "instance_vpc1"
  }

  user_data                   = <<EOF
#!/bin/bash
curl https://cloudtechsavvy.com
EOF
}


output "ec2_public" {
  value = aws_instance.app-web1.public_ip
}
output "ec2_private" {
  value = aws_instance.app-web1.private_ip
}

output "gcp_instance_private_ip" {
  value = google_compute_instance.gcp_compute.network_interface.0.network_ip
}

output "customer_gw1" {
  value = aws_customer_gateway.cust_gw1.ip_address
}


output "aws_tunnel1_public_address" {
  value = aws_vpn_connection.aws_to_gcp.tunnel1_address
}
output "aws_tunnel1_inside_gcp_address" {
  value = aws_vpn_connection.aws_to_gcp.tunnel1_cgw_inside_address
}
output "aws_tunnel1_inside_aws_address" {
  value = aws_vpn_connection.aws_to_gcp.tunnel1_vgw_inside_address
}

output "aws_tunnel2_public_address" {
  value = aws_vpn_connection.aws_to_gcp.tunnel2_address
}
output "aws_tunnel2_inside_gcp_address" {
  value = aws_vpn_connection.aws_to_gcp.tunnel2_cgw_inside_address
}
output "aws_tunnel2_inside_aws_address" {
  value = aws_vpn_connection.aws_to_gcp.tunnel2_vgw_inside_address
}
/*

output "aws_tunnel1_bgp1_peer_ip" {
  value = google_compute_router_peer.gcp_cloud_router_peer1.peer_ip_address
}
output "aws_tunnel1_bgp1_ip" {
  value = google_compute_router_peer.gcp_cloud_router_peer1.ip_address
}

output "gcp_tunnel1_bgp_ip" {
  value = google_compute_router_peer.gcp_cloud_router_peer1.ip_address
}

output "gcp_tunnel1_bgp_peer_ip" {
  value = google_compute_router_peer.gcp_cloud_router_peer1.peer_ip_address
}

output "gcp_tunnel2_bgp_ip" {
  value = google_compute_router_peer.gcp_cloud_router_peer2.ip_address
}

output "gcp_tunnel2_bgp_peer_ip" {
  value = google_compute_router_peer.gcp_cloud_router_peer2.peer_ip_address
}
*/
