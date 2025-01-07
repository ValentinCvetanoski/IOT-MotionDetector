provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "motion_images" {
  bucket = "iotmotionimagebucketall"
}

resource "aws_s3_bucket_public_access_block" "block_public_access" {
  bucket = aws_s3_bucket.motion_images.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "allow_full_access" {
  bucket = aws_s3_bucket.motion_images.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket",
          "s3:GetObject"
        ],
        Resource = [
          aws_s3_bucket.motion_images.arn,
          "${aws_s3_bucket.motion_images.arn}/*"
        ],
        Principal = {
          AWS = "arn:aws:iam::058264380193:user/valentin.cvetanoski"
        }
      }
    ]
  })
}

resource "aws_iam_role" "lambda_role" {
  name = "lambda_s3_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "lambda_s3_policy" {
  name = "lambda_s3_policy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ],
        Resource = [
          aws_s3_bucket.motion_images.arn,
          "${aws_s3_bucket.motion_images.arn}/*"
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "rekognition:DetectFaces",
          "rekognition:SearchFacesByImage"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = "logs:CreateLogGroup",
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "arn:aws:logs:*:*:log-group:/aws/lambda/*:*"
      },
      {
        Effect = "Allow",
        Action = "sns:Publish",
        Resource = aws_sns_topic.face_detection_topic.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_s3_policy.arn
}

resource "aws_lambda_function" "face_detection_lambda" {
  function_name = "face-detection-function"
  handler       = "index.lambda_handler"
  runtime       = "python3.8"
  role          = aws_iam_role.lambda_role.arn
  filename      = "lambda_function_payload.zip"
  source_code_hash = filebase64sha256("lambda_function_payload.zip")

  environment {
    variables = {
      S3_BUCKET = aws_s3_bucket.motion_images.id,
      SNS_TOPIC_ARN = aws_sns_topic.face_detection_topic.arn
    }
  }
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.motion_images.id
  
  lambda_function {
    lambda_function_arn = aws_lambda_function.face_detection_lambda.arn
    events              = ["s3:ObjectCreated:*"]
    filter_suffix       = ".jpg"
  }
  
  depends_on = [aws_lambda_permission.allow_s3_invoke]
}

resource "aws_lambda_permission" "allow_s3_invoke" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.face_detection_lambda.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.motion_images.arn
}

resource "aws_s3_bucket" "known_faces_bucket" {
  bucket = "iotmotionimagebucketallknown"
}

resource "aws_s3_bucket_public_access_block" "block_known_faces_access" {
  bucket = aws_s3_bucket.known_faces_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_object" "person1_folder" {
  bucket = aws_s3_bucket.known_faces_bucket.id
  key    = "person1/"
  acl    = "private"
}

resource "aws_iam_policy" "rekognition_known_faces_policy" {
  name = "rekognition_known_faces_policy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ],
        Resource = [
          aws_s3_bucket.known_faces_bucket.arn,
          "${aws_s3_bucket.known_faces_bucket.arn}/*"
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "rekognition:CreateCollection",
          "rekognition:IndexFaces",
          "rekognition:SearchFaces",
          "rekognition:SearchFacesByImage",
          "rekognition:ListFaces"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_rekognition_policy" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.rekognition_known_faces_policy.arn
}

# Create SNS Topic
resource "aws_sns_topic" "face_detection_topic" {
  name = "face-detection-topic"
}

# Subscribe email addresses to the SNS Topic
resource "aws_sns_topic_subscription" "kliment_subscription" {
  topic_arn = aws_sns_topic.face_detection_topic.arn
  protocol  = "email"
  endpoint  = "klimentcakar@gmail.com"
}

resource "aws_sns_topic_subscription" "valentin_subscription" {
  topic_arn = aws_sns_topic.face_detection_topic.arn
  protocol  = "email"
  endpoint  = "valentin.cvetanoski@isvma.uist.edu.mk"
}
