resource "null_resource" "runtime_zip" {
  provisioner "local-exec" {
    command = "zip -r ./runtime.zip bootstrap bin"
  }
}

resource "null_resource" "vendor_zip" {
  provisioner "local-exec" {
    command = "zip -r ./vendor.zip vendor"
  }
}

resource "aws_lambda_layer_version" "runtime_layer" {
  layer_name = "swoole-runtime"
  filename = "runtime.zip"
  depends_on = [null_resource.runtime_zip]
}

resource "aws_lambda_layer_version" "vendor_layer" {
  layer_name = "swoole-vendor"
  filename = "vendor.zip"
  depends_on = [null_resource.vendor_zip]
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
