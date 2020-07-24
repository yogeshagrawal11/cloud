variable appname {}
variable region {}

variable dynamodbtablename {}
variable dynamodbreadcapacity {}
variable dynamodbwritecapacity {}
variable dynamodb_hashkey {}
variable dynamodb_hashkey_type {}


variable lambdafuncname {}
variable sourcebucket {}
variable smsphoneno {}

data aws_availability_zones "azs" {}

data "aws_s3_bucket" "app-sourcebucket" {
  bucket = var.sourcebucket
}

data "aws_iam_policy" "AWSLambdaBasicExecutionRole-pol" {
  arn = "arn:aws:iam:::policy/AWSLambdaBasicExecutionRole"
}
data "aws_iam_policy" "AWSXRayDaemonWriteAccess-pol" {
  arn = "arn:aws:iam:::policy/AWSXRayDaemonWriteAccess"
}

#-------  Provider Information  ------------
provider "aws" {
  version = "~> 2.0"
  region  = var.region
  profile = "ya"
  #access_key = "my-access-key"
  #secret_key = "my-secret-key"
}

#------------- Lambda function -----------------


resource "aws_iam_role" "app-lambda_role" {
  name = "${var.appname}-lambda_role"
  #attach policy AWSLambdaBasicExecutionRole and AWSXRayDaemonWriteAccess to role 
  #"Action" :  "sts:AssumeRole",
  assume_role_policy = <<EOF
{
  "Version" : "2012-10-17",
  "Statement" : [
    {
      "Action" : "sts:AssumeRole",
      "Principal" : {
        "Service" : "lambda.amazonaws.com"
      },
      "Effect" : "Allow",
      "Sid" : ""
    }
  ]
}
  EOF
}


resource "aws_iam_policy" "app-lambda-cloud-watch-policy" {
  name        = "app-lambda-cloud-watch-policy"
  description = "Cloudwatch access policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "xray:PutTraceSegments",
        "xray:PutTelemetryRecords",
        "xray:GetSamplingRules",
        "xray:GetSamplingTargets",
        "xray:GetSamplingStatisticSummaries"
      ],
      "Effect": "Allow",
      "Resource": "*"
    },
    {
      "Action": [
        "s3:*"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:s3:::*"
    },
    {
      "Effect": "Allow",
      "Action": [
          "s3:Get*",
          "s3:List*"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
          "dynamodb:*"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "SNS:Publish"
      ],
      "Resource": "${aws_sns_topic.app-snstopic.arn}"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "app-lambda-cloud-watch-policy-attachment" {
  role       = aws_iam_role.app-lambda_role.name
  policy_arn = aws_iam_policy.app-lambda-cloud-watch-policy.arn
}





resource "aws_lambda_permission" "allow_bucket" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.app-lambda-func.arn
  principal     = "s3.amazonaws.com"
  source_arn    = data.aws_s3_bucket.app-sourcebucket.arn
}




resource "aws_lambda_function" "app-lambda-func" {
  filename = "${var.lambdafuncname}.zip"
  function_name = var.lambdafuncname
  role = aws_iam_role.app-lambda_role.arn
  handler = "${var.lambdafuncname}.lambda_handler"

  source_code_hash = filebase64sha256 ("${var.lambdafuncname}.zip")
  runtime = "python3.8"

  environment {
    variables = {
      function_name = var.lambdafuncname,
      SNSTOPIC = aws_sns_topic.app-snstopic.arn
      SMSTOPIC = aws_sns_topic.app-snstopic-sms.arn
    }
  }
  depends_on = [aws_sns_topic.app-snstopic]
}


resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = data.aws_s3_bucket.app-sourcebucket.id


  lambda_function {
    lambda_function_arn = aws_lambda_function.app-lambda-func.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "source/"
    filter_suffix       = ".csv"
  }

  depends_on = [aws_lambda_permission.allow_bucket]
}

#--------  SNS topic -------------------

resource "aws_sns_topic" "app-snstopic" {
  name = "${var.appname}-topic"
  delivery_policy = <<EOF
{
  "http": {
    "defaultHealthyRetryPolicy": {
      "minDelayTarget": 20,
      "maxDelayTarget": 20,
      "numRetries": 3,
      "numMaxDelayRetries": 0,
      "numNoDelayRetries": 0,
      "numMinDelayRetries": 0,
      "backoffFunction": "linear"
    },
    "disableSubscriptionOverrides": false,
    "defaultThrottlePolicy": {
      "maxReceivesPerSecond": 1
    }
  }
}
EOF

}



resource "aws_sns_topic_subscription" "app-sqs-target" {
  topic_arn = aws_sns_topic.app-snstopic.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.app-sqs.arn
}




### ---------  SMS Notification 
resource "aws_sns_topic" "app-snstopic-sms" {
  name = "${var.appname}-topic-sms"
  delivery_policy = <<EOF
{
  "http": {
    "defaultHealthyRetryPolicy": {
      "minDelayTarget": 20,
      "maxDelayTarget": 20,
      "numRetries": 3,
      "numMaxDelayRetries": 0,
      "numNoDelayRetries": 0,
      "numMinDelayRetries": 0,
      "backoffFunction": "linear"
    },
    "disableSubscriptionOverrides": false,
    "defaultThrottlePolicy": {
      "maxReceivesPerSecond": 1
    }
  }
}
EOF

}



resource "aws_sns_topic_subscription" "app-sms-target" {
  topic_arn = aws_sns_topic.app-snstopic.arn
  protocol  = "sms"
  endpoint  = var.smsphoneno
}


#---------  SQS ----------------------

resource "aws_sqs_queue" "app-sqs" {
  name = "${var.appname}-queue"
  policy = <<EOF
  {
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": "*",
      "Action": [
        "SQS:SendMessage",
        "SQS:ListDeadLetterSourceQueues"
      ],
      "Resource": "*"
    }
  ]
}
  EOF 
}





#----------- Dynamodb ----------------


resource "aws_dynamodb_table" "app-dynamodb-table" {
  name = var.dynamodbtablename 
  #billingmode = "PROVISIONED"
  read_capacity = var.dynamodbreadcapacity
  write_capacity = var.dynamodbwritecapacity
  hash_key = var.dynamodb_hashkey 
  #range_key = var.dynamodb_rangekey

  attribute {
    name = var.dynamodb_hashkey
    type = var.dynamodb_hashkey_type
  }


  
  tags = {
    Name = "${var.appname}-dynamodb-${var.dynamodbtablename}"
    appname = var.appname

  }
}

