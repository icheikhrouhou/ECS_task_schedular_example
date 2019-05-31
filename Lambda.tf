provider "archive" {}

data "archive_file" "zip" {
  type        = "zip"
  source_file = "lambda_script.py"
  output_path = "lambda_script.zip"
}

resource "aws_cloudwatch_event_rule" "everyday" {
  name                = "everyday"
  description         = "cron for everyday"
  schedule_expression = "rate(1440 minutes)"
}

resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "lambda_logging" {
  name        = "lambda_logging"
  path        = "/"
  description = "IAM policy for logging from a lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = "${aws_iam_role.iam_for_lambdas.name}"
  policy_arn = "${aws_iam_policy.lambda_logging.arn}"
}


resource "aws_lambda_function" "batch_lambda" {
  function_name    = "lambda_function_batch"
  role             = "${aws_iam_role.iam_for_lambda.arn}"
  filename         = "${data.archive_file.zip.output_path}"
  source_code_hash = "${data.archive_file.zip.output_base64sha256}"
  handler          = "lambda_script.lambda_handler"
  runtime          = "python3.7"

  environment {
    variables = {
      env = "dev"
    }
  }
}

resource "aws_cloudwatch_log_group" "log_groupbatch" {
  name              = "/aws/lambda/lambda_function_batch"
  retention_in_days = 14
}

resource "aws_cloudwatch_event_target" "everyday" {
  rule      = "${aws_cloudwatch_event_rule.everyday.name}"
  target_id = "batch_lambda"
  arn       = "${aws_lambda_function.batch_lambda.arn}"
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_lambda" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.batch_lambda.function_name}"
  principal     = "events.amazonaws.com"
  source_arn    = "${aws_cloudwatch_event_rule.everyday.arn}"
}


resource "aws_iam_role" "ecs_execution_task_role" {
  name = "ecsTaskExecutionRole"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ecs_execution" {
  role       = "${aws_iam_role.ecs_execution_task_role.name}"
  policy_arn = "${aws_iam_policy.ecs_execution.arn}"
}

resource "aws_iam_policy" "ecs_execution" {
  name        = "ecs execution task"
  path        = "/"
  description = "IAM policy for logging from a lambda"

  policy = <<EOF
{
  {
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "*"
    }
  ]
}
}
EOF
}

resource "aws_iam_policy" "lambda_ecs" {
  name = "run-ecs-task-policy"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "ecs:RunTask",
            "arn:aws:ecs:<region>:<aws_account_id>:task-definition/<task_family>:*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "iam:PassRole"
            ],
            "Resource": [
                "${aws_iam_role.ecs_execution_task_role.arn}"
            ],
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_ecs" {
  role       = "${aws_iam_role.iam_for_lambda.name}"
  policy_arn = "${aws_iam_policy.lambda_ecs.arn}"
}
