import json
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def process_large_payload(body):
    # Simulated heavy processing
    total = 0
    for i in range(1000000):
        total += i
    return total

def lambda_handler(event, context):
    logger.info("Received event: %s", json.dumps(event))

    for record in event['Records']:
        body = record['body']
        result = process_large_payload(body)
        logger.info(f"Processed result: {result}")

    return {
        "statusCode": 200,
        "body": "Processing complete"
    }
