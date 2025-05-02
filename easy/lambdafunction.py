import os
import json
import boto3
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

DEST_BUCKET = os.environ['DEST_BUCKET']

def lambda_handler(event, context):
    s3 = boto3.client('s3')

    try:
        record = event['Records'][0]
        source_bucket = record['s3']['bucket']['name']
        key = record['s3']['object']['key']

        logger.info(f"Copying '{key}' from '{source_bucket}' to '{DEST_BUCKET}'")
        s3.copy_object(
            CopySource={'Bucket': source_bucket, 'Key': key},
            Bucket=DEST_BUCKET,
            Key=key
        )

        return {
            'statusCode': 200,
            'body': json.dumps('File copied successfully!')
        }

    except Exception as e:
        logger.error(f"Error copying file: {e}")
        raise
