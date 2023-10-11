#Importando bibliotecas
import json
import boto3
import random
from datetime import datetime


#Dados possíveis
clientes = ['rafael','maria','teresa', 'tatiane', 'murilo']
statusPossiveis = ['pedido feito','montando', 'no forno','saiu do forno', 'embalando','pronto']

current_date_and_time = datetime.now()


# Nome da tabela DynamoDB onde você deseja armazenar os dados
table_name = "eventos-pizzaria"

def lambda_handler(event, context):
    
    # Nome da fila SQS
    queue_name = 'DataCreation_Queue'

    # Criar um cliente SQS
    sqs = boto3.client('sqs')
    
    for i in range(0,100):
        # Dados que você deseja armazenar no DynamoDB (substitua isso pelo seu próprio dicionário)
        data_to_store = {
          "timestamp": str(current_date_and_time),
          "status": random.choice(statusPossiveis),
          "pedido": str(i),
          "cliente": random.choice(clientes)
        }
        
        try:
            response = sqs.send_message(
                QueueUrl=queue_name,
                MessageBody=json.dumps(data_to_store)
            )
            
        except Exception as e:
            # Em caso de erro, registre o erro e retorne uma resposta de erro
            return {
                "statusCode": 500,
                "body": json.dumps(f"Erro ao inserir dados no DynamoDB: {str(e)}")
            }
        
    # Resposta bem-sucedida
    return {
        "statusCode": 200,
        "body": json.dumps("Dados inseridos com sucesso no SQS!")
    }
    