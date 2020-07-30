#!/usr/bin/python3
import boto3
import os 
from boto3.dynamodb.conditions import Key, Attr

from botocore.config import Config
import csv, json

west2_config = Config(
    region_name = 'us-west-2'
)


def add_emp():
    global table

    csvfile = "nps_parks.csv"
    jsonfilename = "nps_parks.json"

    data = {}

    with open (csvfile) as csvFile :
        csvReader = csv.DictReader(csvFile)
        for rows in csvReader:
            #print (rows)
            id = rows['Name']
            data[id] = rows

    with open(jsonfilename, "w") as jsonfile:
        jsonfile.write(json.dumps(data, indent=4))

    with open(jsonfilename) as f:
        data = json.load(f)
        #print(data)

        for key in data.keys():
            #print (str(key) + "---->" + str(data[key]))
            additem = data[key]
            table.put_item(Item=additem)
            
    #print (myitem)
    #return table.put_item(Item=myitem)
'''
    Item={
        'lastname': 'agrawal',
        'firstname': 'yogesh',
        'empid': 'ya123',
        'age': 30,
        'position': 'CEO',
    }
)
'''

def get_emp(mymap):
    global table
    return table.get_item(Key=mymap)

def scan_emp():
    global table
    #FilterExpression=Attr('State').gt(0))
    response = table.scan()
    items = response['Items']
    #print (items)
    for i in items:
        print(str(i)) 
    #print(items)
    return items



os.chdir("/root/userdata/")


dynamodb = boto3.resource('dynamodb', config=west2_config)

table = dynamodb.Table('nps_parks')

add_emp()

scanlist = scan_emp()



htmlfile = open("/var/www/html/index.html", "a+")

sorted_by_state_dict = {} 
print ("Sorted by Name:")
htmlfile.write ("<h1>NPS data (sorted by Name)</h1><br><table><tr><th>Name</th><th>State</TH><th>Sq Mil</th><th>Est_Year</th></tr>")

for i in scanlist:
    sorted_by_state_dict[i['Name']] = i 
print ("------------------------------------")
for key in  sorted(sorted_by_state_dict.keys()):
    print(sorted_by_state_dict[key])
    htmlfile.write ("<tr><td>" + sorted_by_state_dict[key]['Name'] + "</td><td>" + sorted_by_state_dict[key]['State'] + "</td><td>" + sorted_by_state_dict[key]['Sq-mi'] +"</td><td>" + sorted_by_state_dict[key]['Est_Year'] + "</td></tr>" )
htmlfile.write ("</table><br><br><br>")


sorted_by_state_dict = {} 
print ("Sorted by State:")
htmlfile.write ("<h1>NPS data (sorted by State)</h1><br><table><tr><th>Name</th><th>State</TH><th>Sq Mil</th><th>Est_Year</th></tr>")
for i in scanlist:
    sorted_by_state_dict[i['State'] +  "_"  + i['Name']] = i 
print ("------------------------------------")
for key in  sorted(sorted_by_state_dict.keys()):
    print(sorted_by_state_dict[key])
    htmlfile.write ("<tr><td>" + sorted_by_state_dict[key]['Name'] + "</td><td>" + sorted_by_state_dict[key]['State'] + "</td><td>" + sorted_by_state_dict[key]['Sq-mi'] +"</td><td>" + sorted_by_state_dict[key]['Est_Year'] + "</td></tr>" )
htmlfile.write ("</table><br><br><br>")

sorted_by_state_dict = {} 
print ("Sorted by Size:")
htmlfile.write ("<h1>NPS data (sorted by Size)</h1><br><table><tr><th>Name</th><th>State</TH><th>Sq Mil</th><th>Est_Year</th></tr>")
for i in scanlist:
    sorted_by_state_dict[int(i['Sq-mi'])] = i 
print ("------------------------------------")
for key in  sorted(sorted_by_state_dict.keys()):
    print(sorted_by_state_dict[key])
    htmlfile.write ("<tr><td>" + sorted_by_state_dict[key]['Name'] + "</td><td>" + sorted_by_state_dict[key]['State'] + "</td><td>" + sorted_by_state_dict[key]['Sq-mi'] +"</td><td>" + sorted_by_state_dict[key]['Est_Year'] + "</td></tr>" )
htmlfile.write ("</table><br><br><br></html>")

