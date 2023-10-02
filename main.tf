locals {
    app_name = "my_app"
    lambda_name = "hello_world_lambda"
}

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "lambda_role" {
    name               = "${local.app_name}-${local.lambda_name}"
    assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role_policy_attachment" "basic_execution_role_policy_attachment" {
    role        = aws_iam_role.lambda_role.name
    policy_arn  = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "archive_file" "lambda_archive" {
  type        = "zip"
  source_file = "${path.module}/target/lambda/HelloWorldRustLambda/bootstrap"
  output_path = "${path.module}/target/archive/HelloWorldRustLambda.zip"
}

resource "aws_lambda_function" "lambda" {
  filename      = data.archive_file.lambda_archive.output_path
  function_name = "${local.app_name}-${local.lambda_name}"
  role          = aws_iam_role.lambda_role.arn

  handler = "bootstrap"

  source_code_hash = data.archive_file.lambda_archive.output_base64sha256

  runtime = "provided.al2"

  architectures = ["arm64"]

  memory_size = 1024
}

resource "aws_lambda_function_url" "lambda_url" {
  function_name      = aws_lambda_function.lambda.function_name
  authorization_type = "NONE"
}

output "lambda_url" {
  value = aws_lambda_function_url.lambda_url.function_url
}
