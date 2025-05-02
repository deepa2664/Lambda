import json
import boto3
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    s3 = boto3.client('s3')

    try:
        source_bucket = event['Records'][0]['s3']['bucket']['name']
        key = event['Records'][0]['s3']['object']['key']
        destination_bucket = 'my-destination-bucket-unique-name456'  # ✅ Correct bucket name

        logger.info(f"Copying '{key}' from '{source_bucket}' to '{destination_bucket}'")
        s3.copy_object(
            CopySource={'Bucket': source_bucket, 'Key': key},
            Bucket=destination_bucket,
            Key=key
        )

        return {
            'statusCode': 200,
            'body': json.dumps('File successfully copied!')
        }

    except Exception as e:
        logger.error(f"Error copying file: {str(e)}")
        raise
