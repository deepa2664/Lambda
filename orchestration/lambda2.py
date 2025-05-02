import boto3
import json
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

lambda_client = boto3.client('lambda')

def lambda_handler(event, context):
    for record in event['Records']:
        try:
            sns_message = json.loads(record['body'])   # SQS wraps SNS
            message = json.loads(sns_message['Message'])

            message_id = message.get('id')
            logger.info(f"Processing message ID: {message_id}")

            if message_id in [3, 8]:
                logger.info(f"Invoking Lambda2 for ID: {message_id}")
                lambda_client.invoke(
                    FunctionName='lambda2',
                    InvocationType='Event',
                    Payload=json.dumps(message).encode('utf-8')
                )
            else:
                logger.info(f"Skipping ID: {message_id}")
        except Exception as e:
            logger.error(f"Error: {e}")
            raise
