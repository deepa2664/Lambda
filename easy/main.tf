provider "aws" {
  region = "us-east-1"  # Set the region to your desired AWS region
}

# 1. Create source S3 bucket
resource "aws_s3_bucket" "source" {
  bucket = "my-source-bucket-unique-name1234"  # Ensure the name is globally unique
}

# 2. Create destination S3 bucket
resource "aws_s3_bucket" "destination" {
  bucket = "my-destination-bucket-unique-name1234"  # Ensure the name is globally unique
}

# 3. IAM Role for Lambda to allow access to S3 buckets
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

# 4. IAM policy for Lambda to access the source and destination S3 buckets
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
          "${aws_s3_bucket.source.arn}/*",  # Allow read access to objects in the source bucket
          "${aws_s3_bucket.destination.arn}/*"  # Allow write access to the destination bucket
        ]
      },
      {
        Effect = "Allow",
        Action = "logs:*",  # Allow CloudWatch logs for Lambda
        Resource = "*"
      }
    ]
  })
}

# 5. Lambda function that is triggered by S3 event (file upload) and copies the file to destination
resource "aws_lambda_function" "s3_copy" {
  function_name    = "S3CopyFunction"
  filename         = "lambda_function_payload.zip"  # You need to create and zip the Lambda function code
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.9"
  role             = aws_iam_role.lambda_exec.arn
  source_code_hash = filebase64sha256("lambda_function_payload.zip")
}

# 6. S3 Bucket Notification to trigger Lambda on file upload (S3 -> Lambda)
resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.source.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.s3_copy.arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.allow_s3]
}

# 7. Allow S3 to invoke Lambda function when an object is created
resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowExecutionFromS3"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.s3_copy.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.source.arn
}

# 8. Lambda Function Code (Python code)
# Save this Python code as lambda_function.py, zip it, and upload it as lambda_function_payload.zip
