appname      = "ya"
subnet_cidr = ["10.0.1.0/24","10.0.2.0/24","10.0.3.0/24","10.0.4.0/24"]
ami          = {
        "us-west-2" = "ami-0e34e7b9ca0ace12d"
        "us-east-2" = "ami-026dea5602e368e96"
}    
region       = "us-west-2"
#localip = "0.0.0.0/0"
localip           = "8.8.8.8/32"
instance_type     = "t2.micro"
key_name          = "ec2-keypair"


accesslogbucket_parameter_name = "accesslogbucket"


dynamodbtablename = "nps_parks"
dynamodbreadcapacity = "1"
dynamodbwritecapacity = "1"
dynamodb_hashkey = "Name"
dynamodb_hashkey_type = "S"



