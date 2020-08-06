import json
import boto3
import tempfile
import os 
import csv
import json
from botocore.config import Config

from boto3.dynamodb.conditions import Key, Attr


#### Region based configuration
west2_config = Config(
    region_name = 'us-west-2'
)

dynamodb = boto3.resource('dynamodb', config=west2_config)


def create_presigned_url(bucket_name, key_name, expiration=300):
    s3 = boto3.client('s3')
    try:
        response = s3.generate_presigned_url('get_object',
                                                    Params={'Bucket': bucket_name,
                                                            'Key': key_name},
                                                    ExpiresIn=expiration)
    except ClientError as e:
        logging.error(e)
        return None

    # The response contains the presigned URL
    return response

def getdbItem(searchfor):
    dynamodb_cl = boto3.client('dynamodb', config=west2_config)
    table = dynamodb.Table('imagerek')
    scan_kwargs = {
        'FilterExpression': Attr(searchfor.lower()).exists()
    }
    print(searchfor)
    print(scan_kwargs)
    response = table.scan(**scan_kwargs)
    items = response['Items']
    output = []
    for i in items:
        print(str(i))
        output.append(str(i["s3key"]))
    return output
    

### api input get method 
## <apipath>/<stage>/<resources>?input1=100&input2=200

def lambda_handler(event,context):
    try:
        input1 = event["queryStringParameters"]["input1"]
        output = getdbItem(input1.lower())
        
        print(input1)
        print(output)
        
        column = 1 
        
        testresponse = "<html><head><style>table, th, td {border: 5px solid red;border-collapse: collapse;}</style></head><table>"
        print(type(output))
        for i in output:
            #abc = json.loads(i)
            print("--------->")
            
            signed_url = create_presigned_url("yogeshagrawal",str(i),10000)
            if column == 1 :
                testresponse =  testresponse + "<tr>"
            testresponse = testresponse + "<td><img src="+ str(signed_url) + " width=\"200\" height=\"200\" ><br></td>"
            column += 1 
            #testresponse = testresponse + "<a href= "+ str(signed_url) + "> Images for "+ input1 + " </a><br>" 
            if column == 4:
                testresponse = testresponse +  "</tr>"
                column = 1 
        testresponse = testresponse + "</table></html>"
        
        print(testresponse)
    except Exception as e:
        print(e)
        testresponse = {}
        testresponse["myinput"] = "myinput"
        testresponse["myinput1"] = input1


    responseobj = {}
    responseobj["statusCode"] = 200
    responseobj["headers"]= {}
    responseobj["headers"]["Content-Type"] = "text/html"
    responseobj["body"] = testresponse

    return responseobj