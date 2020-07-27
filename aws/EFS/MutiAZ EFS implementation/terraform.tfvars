appname      = "ya"
subnet_cidr = ["10.0.1.0/24","10.0.2.0/24","10.0.3.0/24","10.0.4.0/24"]
ami          = {
        "us-west-2" = "ami-0e34e7b9ca0ace12d"
        "us-east-2" = "ami-026dea5602e368e96"
}    
region       = "us-west-2"


localip           = "0.0.0.0/0"
instance_type     = "t2.micro"
key_name          = "ec2_keyname"
iam_instance_role = "s3-readonly-access"


#### EFS information 

efsname = "fs01"
pathname = "/fs01"

azcount = [0,1,2]

