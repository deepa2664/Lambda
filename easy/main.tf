provider "aws" {
  region = "us-east-1"
}

# 1. Create source and destination S3 Buckets
resource "aws_s3_bucket" "source" {
  bucket = "my-source-bucket-unique-name789"  # Ensure this name is globally unique
}

resource "aws_s3_bucket" "destination" {
  bucket = "my-destination-bucket-unique-name456"  # Ensure this name is globally unique
}

# 2. IAM role for Lambda to allow access to S3 buckets
resource "aws_iam_role" "lambda_exec" {
  name = "lambda_s3_copy_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# 3. IAM policy for Lambda to access the source and destination S3 buckets
resource "aws_iam_role_policy" "lambda_policy" {
  name = "lambda_s3_policy"
  role = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ],
        Resource = [
          "${aws_s3_bucket.source.arn}/*",
          "${aws_s3_bucket.destination.arn}/*"
        ]
      },
      {
        Effect = "Allow",
        Action = "logs:*",
        Resource = "*"
      }
    ]
  })
}

# 4. Lambda function that triggers on file upload to S3 and copies the file to the destination bucket
resource "aws_lambda_function" "s3_copy" {
  function_name    = "S3CopyFunction"
  filename         = "lambda_function_payload.zip"  # You will need to create and zip the Lambda function code
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.9"
  role             = aws_iam_role.lambda_exec.arn
  source_code_hash = filebase64sha256("lambda_function_payload.zip")
}

# 5. S3 Bucket Notification to trigger Lambda on file upload
resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.source.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.s3_copy.arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.allow_s3]
}

# 6. Allow S3 to invoke Lambda
resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowExecutionFromS3"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.s3_copy.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.source.arn
}
