import json
import boto3

def lambda_handler(event, context):
    s3 = boto3.client('s3')
    
    # Extract bucket and file details from the event
    source_bucket = event['Records'][0]['s3']['bucket']['name']
    key = event['Records'][0]['s3']['object']['key']
    destination_bucket = 'my-destination-bucket-unique-name'  # Replace with your destination bucket name
    
    # Copy the object to the destination bucket
    copy_source = {'Bucket': source_bucket, 'Key': key}
    s3.copy_object(CopySource=copy_source, Bucket=destination_bucket, Key=key)

    return {
        'statusCode': 200,
        'body': json.dumps('File successfully copied!')
    }
