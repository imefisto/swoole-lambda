resource "aws_apigatewayv2_api" "swoole_lambda" {
  name = "swoole-lambda"
  protocol_type = "HTTP"
  target = aws_lambda_function.swoole_lambda.invoke_arn
}

resource "aws_lambda_permission" "api_gw" {
  statement_id = "AllowExecutionFromAPIGateway"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.swoole_lambda.function_name
  principal = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.swoole_lambda.execution_arn}/*/*"
}
