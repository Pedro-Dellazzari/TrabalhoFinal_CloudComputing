provider "aws" {
  region = "us-east-1"  # Substitua pela região AWS desejada
}



##################### EVENT BRIDGE ##############################
# Criando o Barramento de Eventos
resource "aws_cloudwatch_event_bus" "pizzaria_event_bus" {
  name = "pizzaria_event_bus" # Nome do barramento de eventos
}

resource "aws_cloudwatch_event_rule" "pizza_status_change" {
  name           = "PizzaStatusChange"
  description    = "Capture changes in pizza status"
  event_bus_name = aws_cloudwatch_event_bus.pizzaria_event_bus.name

  event_pattern = jsonencode({
    "source" : ["com.pizza.status"],
    "detail-type" : ["Alteracao Pizza"]
  })
}

resource "aws_cloudwatch_event_rule" "pizza_ready_change" {
  name           = "PizzaReadyChange"
  description    = "Capture pizzas that are ready"
  event_bus_name = aws_cloudwatch_event_bus.pizzaria_event_bus.name

  event_pattern = jsonencode({
    "source" : ["com.pizza.status"],
    "detail-type" : ["Alteracao Pizza"],
    "detail" : {
      "status" : ["pronto"]
    }
  })
}

############################ DYNAMODB ################################
resource "aws_dynamodb_table" "eventos_pizzaria" {
  name         = "eventos-pizzaria"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "pedido"
  range_key    = "status"
  attribute {
    name = "pedido"
    type = "S"
  }
  attribute {
    name = "status"
    type = "S"
  }
}

############################ SQS Queue ################################
resource "aws_sqs_queue" "espera_entrega" {
  name             = "espera-entrega"
  delay_seconds    = 0
  max_message_size = 1024
}



################################# LAMBDA FUNCTIONS ########################
###### Função que vai salvar TODAS as informações no DynamoDB ##########
data "archive_file" "DynamoFunction_data" {
  type        = "zip"
  source_dir  = "./lambdas/Dynamo_Ingest/"
  output_path = "./lambdas/Dynamo_Ingest/function.zip"
}

resource "aws_lambda_function" "DynamoDB_function" {
  function_name    = "DynamoDB_Ingest"
  handler          = "function.lambda_handler"
  runtime          = "python3.9"
  filename         = data.archive_file.DynamoFunction_data.output_path
  source_code_hash = data.archive_file.DynamoFunction_data.output_base64sha256
  role             = "arn:aws:iam::950885656696:role/LabRole"
}

resource "aws_cloudwatch_event_target" "sendTo_Lambda_DynamoIngest" {
  rule           = aws_cloudwatch_event_rule.pizza_status_change.name
  event_bus_name = aws_cloudwatch_event_bus.pizzaria_event_bus.name
  target_id      = "DynamoDB_Ingest"
  arn            = aws_lambda_function.DynamoDB_function.arn
}

resource "aws_lambda_permission" "allow_eventbridge_persist" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.DynamoDB_function.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.pizza_status_change.arn
}


###### Função que vai enviar PRONTOS para o SQS ##########
data "archive_file" "SQSFunction_data" {
  type        = "zip"
  source_dir  = "./lambdas/ReadySender_SQS/"
  output_path = "./lambdas/ReadySender_SQS/function.zip"
}

resource "aws_lambda_function" "SQS_function" {
  function_name    = "SQS_Ingest"
  handler          = "function.lambda_handler"
  runtime          = "python3.9"
  filename         = data.archive_file.SQSFunction_data.output_path
  source_code_hash = data.archive_file.SQSFunction_data.output_base64sha256
  role             = "arn:aws:iam::950885656696:role/LabRole"
}

resource "aws_cloudwatch_event_target" "sendTo_Lambda_SQSIngest" {
  rule           = aws_cloudwatch_event_rule.pizza_ready_change.name
  event_bus_name = aws_cloudwatch_event_bus.pizzaria_event_bus.name
  target_id      = "DynamoDB_Ingest"
  arn            = aws_lambda_function.SQS_function.arn
}

resource "aws_lambda_permission" "allow_eventbridge_sqssender" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.SQS_function.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.pizza_ready_change.arn
}

###### Pegar a mensagem do SQS e mudar para entregue ##########
data "archive_file" "SQSConsumer_data" {
  type        = "zip"
  source_dir  = "./lambdas/SQS_Consumer/"
  output_path = "./lambdas/SQS_Consumer/function.zip"
}

resource "aws_lambda_function" "SQSConsumer_function" {
  function_name    = "SQS_Consumer"
  handler          = "function.lambda_handler"
  runtime          = "python3.9"
  filename         = data.archive_file.SQSConsumer_data.output_path
  source_code_hash = data.archive_file.SQSConsumer_data.output_base64sha256
  role             = "arn:aws:iam::950885656696:role/LabRole"
}

resource "aws_lambda_event_source_mapping" "sqs_event_source" {
  event_source_arn = aws_sqs_queue.espera_entrega.arn
  function_name    = aws_lambda_function.SQSConsumer_function.function_name
  batch_size       = 1
}