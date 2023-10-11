provider "aws" {
  region = "us-east-1"  # Substitua pela região AWS desejada
}

resource "aws_sqs_queue" "queue_datacreation" {
  name                      = "DataCreation_Queue"  # Substitua pelo nome desejado para a fila
  delay_seconds             = 0
  max_message_size          = 256000
  message_retention_seconds = 86400
  visibility_timeout_seconds = 30
}

data "archive_file" "zip_creation_data" {
  type        = "zip"
  source_dir  = "${path.module}/lambdas/Creation_Data"
  output_path = "${path.module}/lambdas/Creation_Data/lambda_function.zip"
}

resource "aws_lambda_function" "lambda_creation_data" {
  function_name = "CreationData_Func"
  handler      = "lambda_function.lambda_handler"
  runtime      = "python3.10"
  timeout     = 30# Substitua pela linguagem e versão desejadas

  # Código da função Lambda (usando o arquivo ZIP gerado pelo data "archive_file")
  filename = data.archive_file.zip_creation_data.output_path
  source_code_hash = data.archive_file.zip_creation_data.output_base64sha256
  role = "arn:aws:iam::950885656696:role/LabRole"  # Adicione aspas ao redor do ARN
}


resource "aws_sqs_queue" "queue_prontos" {
  name                      = "PedidosProntos_Queue"  # Substitua pelo nome desejado para a fila
  delay_seconds             = 0
  max_message_size          = 256000
  message_retention_seconds = 86400
  visibility_timeout_seconds = 30
}

data "archive_file" "zip_separation_n_dynamo" {
  type        = "zip"
  source_dir  = "${path.module}/lambdas/Dynamo_n_Separation"
  output_path = "${path.module}/lambdas/Dynamo_n_Separation/lambda_function.zip"
}

resource "aws_lambda_function" "lambda_separation_n_dynamo" {
  function_name = "Separation_n_Dynamo"
  handler      = "lambda_function.lambda_handler"
  runtime      = "python3.10"
  timeout     = 30# Substitua pela linguagem e versão desejadas

  # Código da função Lambda (usando o arquivo ZIP gerado pelo data "archive_file")
  filename = data.archive_file.zip_separation_n_dynamo.output_path
  source_code_hash = data.archive_file.zip_separation_n_dynamo.output_base64sha256
  role = "arn:aws:iam::950885656696:role/LabRole"  # Adicione aspas ao redor do ARN
}

resource "aws_lambda_event_source_mapping" "example_trigger" {
  event_source_arn = aws_sqs_queue.queue_datacreation.arn
  function_name    = aws_lambda_function.lambda_separation_n_dynamo.function_name
  batch_size       = 10  # Número de mensagens a serem processadas por invocação da função
}
