resource "aws_lambda_layer_version" "runtime_layer" {
  layer_name = "swoole-runtime"
  filename = "runtime.zip"
  source_code_hash = filebase64sha256("runtime.zip")
}

resource "aws_lambda_layer_version" "vendor_layer" {
  layer_name = "swoole-vendor"
  filename = "vendor.zip"
  source_code_hash = filebase64sha256("vendor.zip")
}

data "archive_file" "swoole_lambda" {
  type = "zip"
  source_file = "handler.php"
  output_path = "function.zip"
}

resource "aws_lambda_function" "swoole_lambda" {
  filename = data.archive_file.swoole_lambda.output_path
  function_name = "swoole-lambda"
  role = aws_iam_role.role_for_lambda.arn
  handler = "handler.handler"
  source_code_hash = data.archive_file.swoole_lambda.output_base64sha256
  runtime = "provided"
  layers = [
    aws_lambda_layer_version.runtime_layer.arn,
    aws_lambda_layer_version.vendor_layer.arn,
  ]
  timeout = 10
  environment {
    variables = {
      URLS = join(",", var.urls)
    }
  }
}

resource "aws_iam_role" "role_for_lambda" {
  name = "swoole-lambda-role"

  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Service": "lambda.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_cloudwatch_log_group" "logs" {
  name = "/aws/lambda/swoole-lambda"
  retention_in_days = 3
}

resource "aws_iam_policy" "swoole_lambda_policy" {
  name = "swoole-lambda-policy"

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Resource": [
          "${aws_cloudwatch_log_group.logs.arn}:*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attachment" {
  role       = aws_iam_role.role_for_lambda.name
  policy_arn = aws_iam_policy.swoole_lambda_policy.arn
}
