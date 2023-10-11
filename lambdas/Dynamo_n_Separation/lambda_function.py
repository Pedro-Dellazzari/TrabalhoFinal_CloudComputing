#Importando bibliotecas
import json
import boto3

# Nome da tabela DynamoDB onde você deseja armazenar os dados
table_name = "eventos-pizzaria"

def lambda_handler(event, context):
    
    # Nome da fila SQS
    queue_name = 'PedidosProntos_Queue'

    # Criar um cliente SQS
    sqs = boto3.client('sqs')
    
    dynamodb = boto3.client("dynamodb")
    
    messagens_event = event['Records']
    
    for mensagem in messagens_event:
        
        data_body = mensagem['body']

        date_order = json.loads(data_body)['timestamp']
        pedido = json.loads(data_body)['pedido']
        cliente = json.loads(data_body)['cliente']
        status = json.loads(data_body)['status']
        
        # Dados que você deseja armazenar no DynamoDB (substitua isso pelo seu próprio dicionário)
        data_to_store = {
          "timestamp": date_order,
          "status": status,
          "pedido": pedido,
          "cliente": cliente
        }
        
        try:
            response = dynamodb.put_item(
                TableName=table_name,
                Item={
                    "pedido": {"S": data_to_store["pedido"]},
                    "timestamp" : {"S": data_to_store["timestamp"]},# S para string, N para número, etc.
                    "status": {"S": data_to_store["status"]},
                    "cliente": {"S": data_to_store["cliente"]}
                }
            )
            
        except Exception as e:
            # Em caso de erro, registre o erro e retorne uma resposta de erro
            return {
                "statusCode": 500,
                "body": json.dumps(f"Erro ao inserir dados no DynamoDB: {str(e)}")
            }
            
            
        if status == 'pronto':
            response = sqs.send_message(
                QueueUrl=queue_name,
                MessageBody=json.dumps(data_to_store)
            )
            
        else:
            pass
        
    # Resposta bem-sucedida
    return {
        "statusCode": 200,
        "body": json.dumps("Dados inseridos com sucesso no SQS!")
    }
    