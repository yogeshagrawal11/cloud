import json
import boto3
import tempfile
import os 
import csv
import json
from botocore.config import Config


west2_config = Config(
    region_name = 'us-west-2'
)


def lambda_handler(event, context):
    
    #print (event)
    #print(context)
    
    
    #### S3 client and Dynamo db client 
    s3 = boto3.client("s3")
    west2_config = Config(region_name = 'us-west-2')
    dynamodb = boto3.resource('dynamodb',config=west2_config)
    table = dynamodb.Table('nps_parks')

    sns = boto3.client('sns')
    SNSTOPIC = os.environ['SNSTOPIC']
    SMSTOPIC = os.environ['SMSTOPIC']

    #### event will send list of records. In this case just 1 put request. So i can still use [0] object no 
    for eachrecord in event["Records"]:
        bucketname = eachrecord["s3"]["bucket"]['name']
        ### filename includes complete path to object 
        filename = eachrecord["s3"]["object"]["key"]
        print("***** Adding data from file {}\\{}".format(bucketname,filename))
        try: 
            with tempfile.TemporaryDirectory() as tmpdir:
                ### download path csv file 
                path = os.path.join(tmpdir , filename.split("/")[-1])
                jsonfilename = os.path.join(tmpdir , filename.split("/")[-1].replace("csv","json"))
                ### CSV file will be downloaded from S3
                s3.download_file(bucketname, filename, path)
                
                ### Convert CSV format into Dictionary
                
                data = {} 
                with open (path) as csvFile :
                    csvReader = csv.DictReader(csvFile)
                    for rows in csvReader:
                        id = rows['Name']
                        data[id] = rows
                
                '''  ### print eachrow if needed into cloudwatch
                f = open(path, "r")
                with open(path) as f:
                    for line in f:
                        print(line)
                '''

                ### Add json based data into table using batch writer.
                
                with open(jsonfilename, "w") as jsonfile:
                    jsonfile.write(json.dumps(data, indent=4))
                
                with open(jsonfilename) as f1:
                    data = json.load(f1)
                    ### insert item/rows into dynamoDB database
                    ### PS. All data is read as string. If like can be converted to integer or respective types
                    with table.batch_writer() as batch:
                        for key in data.keys():
                            additem = data[key]
                            batch.put_item(Item=additem)

                #f.close()
                output = output = bucketname+ ";" + filename + ";" + "Successful"
                snsresp = sns.publish(TargetArn = SNSTOPIC, Message=output)
                print(snsresp)

                f1.close()
                jsonfile.close()

        except Exception as e:
            print("Exception ----->")
            print(e)
            return {
                "statusCode" : 1
            }
            

    return {
        'statusCode': 200
    }
