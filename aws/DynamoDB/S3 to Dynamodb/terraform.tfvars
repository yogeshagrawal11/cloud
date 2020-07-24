appname      = "ya"  
region       = "us-west-2"


### dynamodb 

dynamodbtablename = "nps_parks"
dynamodbreadcapacity = "1"
dynamodbwritecapacity = "1"
dynamodb_hashkey = "Name"
dynamodb_hashkey_type = "S"


#####  Lambda function 
lambdafuncname = "insertS3toDynamodb"
sourcebucket = "sourcebucket"
smsphoneno = "+11234567899"