import json
import boto3

# Necessary for connecting to DynamoDB using boto3
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('cloudresumechallengedb')

def updateCount():
    
    # Get the partition key "app", value 'cloudresumechallengesite'
    response = table.get_item(Key={
        'app': 'cloudresumechallengesite'
    })

    # Return the Item 'views' from the table, add 1, save in new variable
    updated_views = response['Item']['views']
    updated_views += 1

    # Updates the table with new visitor count
    response = table.put_item(Item={
        'app': 'cloudresumechallengesite',
        'views': updated_views
    })

def getCount():
    
    # Get the partition key "app", value 'cloudresumechallengesite'
    response = table.get_item(Key={
        'app': 'cloudresumechallengesite'
    })
    
    # Return the Item 'views' from the table
    return response['Item']['views']

def lambda_handler(event, context):
    
    # Update the visitor counter
    updateCount()
    
    # Return the total number of visitors
    return getCount()