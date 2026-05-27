locals {
  safe_domain_name = replace(var.domain_name, "/[^a-zA-Z0-9_-]/", "_")
}

data "archive_file" "ddns" {
  type        = "zip"
  source_file = "${path.module}/../lambda/lambda.py"
  output_path = "${path.module}/lambda.zip"
}

resource "aws_lambda_function" "ddns" {
  filename         = data.archive_file.ddns.output_path
  source_code_hash = data.archive_file.ddns.output_base64sha256
  function_name    = "ddns-${local.safe_domain_name}"
  role             = aws_iam_role.ddns.arn
  handler          = "lambda.handler"
  runtime          = "python3.12"
  memory_size      = 2048
  timeout          = 5

  environment {
    variables = {
      HOSTED_ZONE_ID = var.hosted_zone_id
    }
  }
}

resource "aws_lambda_permission" "allow_apig" {
  statement_id  = "AllowExecutionFromAPIG"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ddns.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.ddns.execution_arn}/*"
}
