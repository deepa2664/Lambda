provider "aws" {
  region = "us-east-1"
}

# SNS Topic
resource "aws_sns_topic" "main" {
  name = "message-topic"
}

# DLQ for SQS
resource "aws_sqs_queue" "dlq" {
  name = "message-dlq"
}

# Main SQS Queue (subscribed to SNS)
resource "aws_sqs_queue" "main_queue" {
  name = "message-queue"

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = 3
  })
}

# SQS Permissions for SNS
resource "aws_sqs_queue_policy" "sqs_policy" {
  queue_url = aws_sqs_queue.main_queue.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = "*",
      Action = "sqs:SendMessage",
      Resource = aws_sqs_queue.main_queue.arn,
      Condition = {
        ArnEquals = {
          "aws:SourceArn" = aws_sns_topic.main.arn
        }
      }
    }]
  })
}

# SNS Subscription to SQS
resource "aws_sns_topic_subscription" "sqs_sub" {
  topic_arn = aws_sns_topic.main.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.main_queue.arn
}

# IAM Role for Lambdas
resource "aws_iam_role" "lambda_exec" {
  name = "lambda_exec_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = "sts:AssumeRole",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# IAM Policy
resource "aws_iam_role_policy" "lambda_policy" {
  name = "lambda_policy"
  role = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:*",
          "sqs:*",
          "sns:*",
          "lambda:InvokeFunction"
        ],
        Resource = "*"
      }
    ]
  })
}

# Lambda1: triggered by SQS, invokes Lambda2
resource "aws_lambda_function" "lambda1" {
  function_name = "lambda1"
  filename      = "lambda1.zip"
  handler       = "lambda1.lambda_handler"
  runtime       = "python3.9"
  role          = aws_iam_role.lambda_exec.arn
  source_code_hash = filebase64sha256("lambda1.zip")
}

# Lambda2: processing target
resource "aws_lambda_function" "lambda2" {
  function_name = "lambda2"
  filename      = "lambda2.zip"
  handler       = "lambda2.lambda_handler"
  runtime       = "python3.9"
  role          = aws_iam_role.lambda_exec.arn
  source_code_hash = filebase64sha256("lambda2.zip")
}

# Event Source: SQS → Lambda1
resource "aws_lambda_event_source_mapping" "lambda1_trigger" {
  event_source_arn = aws_sqs_queue.main_queue.arn
  function_name    = aws_lambda_function.lambda1.arn
  batch_size       = 1
  enabled          = true
}
