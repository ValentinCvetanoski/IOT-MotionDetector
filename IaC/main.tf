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
