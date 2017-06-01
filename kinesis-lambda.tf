provider "aws" {
  region     = "eu-west-1"
}

# IAM

## IAM Role
resource "aws_iam_role" "iam_for_terraform_lambda" {
    name = "kinesis_streamer_iam_role"
    assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

## IAM Role Policies

resource "aws_iam_role_policy_attachment" "terraform_lambda_iam_policy_basic_execution" {
  role = "${aws_iam_role.iam_for_terraform_lambda.id}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "terraform_lambda_iam_policy_kinesis_execution" {
  role = "${aws_iam_role.iam_for_terraform_lambda.id}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaKinesisExecutionRole"
}

# Lambda

resource "aws_lambda_function" "terraform_kinesis_streamer_func" {
    filename = "lambda-func.zip"
    function_name = "echo_func"
    role = "${aws_iam_role.iam_for_terraform_lambda.arn}"
    handler = "echo_func.echo_func"
    runtime = "python3.6"
    source_code_hash = "${base64sha256(file("lambda-func.zip"))}"
}

resource "aws_lambda_event_source_mapping" "kinesis_lambda_event_mapping" {
    batch_size =1
    event_source_arn = "${aws_kinesis_stream.kinesis_streamer_demo_stream.arn}"
    enabled = true
    function_name = "${aws_lambda_function.terraform_kinesis_streamer_func.arn}"
    starting_position = "TRIM_HORIZON"
}

# Kinesis

## Kinesis Streams
resource "aws_kinesis_stream" "kinesis_streamer_demo_stream" {
    name = "terraform-kinesis-streamer-demo-stream"
    shard_count = 1
    retention_period = 24
    shard_level_metrics = [
        "IncomingBytes",
        "OutgoingBytes"
    ]
    tags {
        Environment = "terraform-kinesis-streamer-test"
    }
}
