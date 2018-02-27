#####
# Providers
#

provider "aws" {
  # access_key = "${var.access_key}"
  # secret_key = "${var.secret_key}"
  region = "${var.region}"
}

#####
# Modules
#

module "sns_to_spark" {
  source = "../../module"
  spark_channel_map = "${var.spark_channel_map}"
  spark_bearer_token = "${var.spark_bearer_token}"
}

#####
# CloudWatch Alarms
#

resource "aws_cloudwatch_metric_alarm" "lambda_duration" {
  alarm_name = "lambda-duration"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods = "1"
  metric_name = "Duration"
  namespace = "AWS/Lambda"
  period = "120"
  statistic = "Average"
  threshold = "500"
  alarm_description = "This metric monitors AWS Lambda duration"

  insufficient_data_actions = [
    "${aws_sns_topic.testing_spark_alarms.arn}"
  ]

  alarm_actions = [
    "${aws_sns_topic.testing_spark_alarms.arn}"
  ]

  ok_actions = [
    "${aws_sns_topic.testing_spark_alarms.arn}"
  ]
}

#####
# SNS Topics
#

resource "aws_sns_topic" "testing_spark_alarms" {
  name = "testingSpark-notices"
}

#####
# SNS Subscriptions
#

resource "aws_lambda_permission" "allow_lambda_sns_to_spark" {
  statement_id = "AllowSNSToSparkExecutionFromSNS"
  action = "lambda:invokeFunction"
  function_name = "${module.sns_to_spark.lambda_function_arn}"
  principal = "sns.amazonaws.com"
  source_arn = "${aws_sns_topic.testing_spark_alarms.arn}"
}

resource "aws_sns_topic_subscription" "lambda_sns_to_spark" {
  topic_arn = "${aws_sns_topic.testing_spark_alarms.arn}"
  protocol = "lambda"
  endpoint = "${module.sns_to_spark.lambda_function_arn}"
}
