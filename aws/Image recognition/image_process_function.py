import boto3
from botocore.config import Config

from boto3.dynamodb.conditions import Key, Attr
from botocore.config import Config

from urllib.parse import unquote_plus

#### Requirement Create Table name "imagerek"
#### create keyname "s3key" as primary key
s3 = boto3.client("s3")
west2_config = Config(region_name = 'us-west-2')
dynamodb = boto3.resource('dynamodb',config=west2_config)
dynamodb_tablename = 'imagerek'
table = dynamodb.Table(dynamodb_tablename)
rek = boto3.client('rekognition' , config=west2_config)
 

def updateDbAttribute(keyname,myattr,myvalue):
    table.update_item(TableName=dynamodb_tablename, Key = { "s3key" : keyname  }, UpdateExpression='SET #attr1 = :val1', ExpressionAttributeNames={"#attr1": myattr.lower()}, ExpressionAttributeValues = { ":val1" :  int(myvalue) } )
 


def deleteDbAttribute(keyname,myattr):
    table.update_item(TableName=dynamodb_tablename, Key = { "s3key" : keyname  }, UpdateExpression='REMOVE #attr1', ExpressionAttributeNames={"#attr1": myattr})


def rek_labels(bucketname,key):
    s3obj = { 'Bucket' : bucketname, 'Name'  : key }
    output = rek.detect_labels( Image = {'S3Object': s3obj},MaxLabels=10)
    
    for label in output["Labels"]:
        updateDbAttribute(key,label["Name"].lower(),int(label["Confidence"]))
        print("Labelname: {} Confidence: {}".format(label["Name"].lower(),str(label["Confidence"])))



def rek_celebrities(bucketname, key):
    if "." in key:
        s3obj = {
            'Bucket' : bucketname,
            'Name'  : key
        }
        rek_cel =  rek.recognize_celebrities(
            Image={
                'S3Object':  s3obj 
        })
        #putitem = {} 
        #putitem["s3key"] = key
        for name in rek_cel["CelebrityFaces"]:
            print (" {}  {}".format(name["Name"], name["MatchConfidence"] ))
            #putitem[name["Name"]] = int(name["MatchConfidence"])
            updateDbAttribute(key,name["Name"],name["MatchConfidence"])
        #adddbItem(putitem)
            
            
            

def lambda_handler(event, context):
    # TODO implement

    ##print(str(event["Records"]))
    
    for eachrecord in event["Records"]:
        bucketname = eachrecord["s3"]["bucket"]['name']
        ### filename includes complete path to object 
        #keyname = eachrecord["s3"]["object"]["key"]
        keyname = unquote_plus(eachrecord['s3']['object']['key'])
        
        print("Keyname : {}".format(keyname))
        rek_celebrities(bucketname,keyname)
        rek_labels(bucketname,keyname)
        
    return {
        'statusCode': 200,
        'body': json.dumps('Image processing complete')
    }
