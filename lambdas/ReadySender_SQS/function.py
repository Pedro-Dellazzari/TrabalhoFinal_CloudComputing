import json

from sqsHandler import SqsHandler


def lambda_handler(event, context):

    detail = event.get('detail', {})
    payload_str = json.dumps(detail)
    sqs_handler = SqsHandler("espera-entrega")
    sqs_handler.send(payload_str)

    return True
