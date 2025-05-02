import boto3
import os

def lambda_handler(event, context):
    s3 = boto3.client('s3')
    
    # Get the uploaded object info
    source_bucket = event['Records'][0]['s3']['bucket']['name']
    key = event['Records'][0]['s3']['object']['key']
    destination_bucket = 'my-destination-bucket-unique-name'
    
    # Copy the object
    copy_source = {'Bucket': source_bucket, 'Key': key}
    s3.copy_object(CopySource=copy_source, Bucket=destination_bucket, Key=key)

    return {"status": "success"}
