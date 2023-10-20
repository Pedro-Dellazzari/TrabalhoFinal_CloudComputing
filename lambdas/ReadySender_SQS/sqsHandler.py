import boto3


class SqsHandler:
    def __init__(self, queue_identifier):
        self.__sqs = boto3.client('sqs')
        if queue_identifier.startswith("https://"):
            self.__queueUrl = queue_identifier
        else:
            self.__queueUrl = self.get_queue_url_by_name(queue_identifier)
        if not self.__queueUrl:
            raise ValueError(f"Invalid queue identifier: {queue_identifier}")

    def get_queue_url_by_name(self, queue_name):
        try:
            response = self.__sqs.get_queue_url(QueueName=queue_name)
            return response['QueueUrl']
        except self.__sqs.exceptions.QueueDoesNotExist:
            raise ValueError(f"Queue {queue_name} does not exist.")

    def getMessage(self, qtdMsgs):
        response = self.__sqs.receive_message(
            QueueUrl=self.__queueUrl,
            MaxNumberOfMessages=qtdMsgs
        )
        return response

    def deleteMessage(self, receiptHandle):
        response = self.__sqs.delete_message(
            QueueUrl=self.__queueUrl,
            ReceiptHandle=receiptHandle
        )
        return response

    def deleteBatch(self, lista):
        response = self.__sqs.delete_message_batch(
            QueueUrl=self.__queueUrl,
            Entries=lista
        )
        print(response)

    def sendBatch(self, lista):
        response = self.__sqs.send_message_batch(
            QueueUrl=self.__queueUrl,
            Entries=lista
        )
        print(response)

    def send(self, msg):
        response = self.__sqs.send_message(
            QueueUrl=self.__queueUrl,
            MessageBody=msg
        )
        print(response)