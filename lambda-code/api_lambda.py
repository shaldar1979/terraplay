import json
import os
from datetime import datetime


def lambda_handler(event, context):
    """
    Sample API Lambda function.
    Works with API Gateway (AWS_PROXY integration).
    """

    try:
        environment = os.environ.get("ENVIRONMENT", "unknown")

        http_method = event.get("httpMethod", "UNKNOWN")
        path = event.get("path", "/")
        query_params = event.get("queryStringParameters") or {}
        body = event.get("body")

        response = {
            "message": "API Lambda executed successfully",
            "environment": environment,
            "http_method": http_method,
            "path": path,
            "query_params": query_params,
            "body": body,
            "timestamp": datetime.utcnow().isoformat()
        }

        return {
            "statusCode": 200,
            "headers": {
                "Content-Type": "application/json"
            },
            "body": json.dumps(response)
        }

    except Exception as e:
        return {
            "statusCode": 500,
            "headers": {
                "Content-Type": "application/json"
            },
            "body": json.dumps({
                "error": str(e)
            })
        }
