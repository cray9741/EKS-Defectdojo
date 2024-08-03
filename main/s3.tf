resource "aws_s3_bucket" "s3-tools-results-5439283" {
  bucket = var.bucket_name  # Change to a globally unique name
  acl    = "private"
  depends_on = [aws_iam_role.eks-access-s3]

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "aws:kms"
      }
    }
  }

  tags = {
    Name        = var.bucket_name
  }
}

resource "aws_s3_bucket_public_access_block" "block" {
  bucket = aws_s3_bucket.s3-tools-results-5439283.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
  depends_on = [aws_iam_role.eks-access-s3]
}

# Attach a Policy to the Bucket to Grant the User GetObject and ListBucket Permissions
# resource "aws_s3_bucket_policy" "bucket_policy" {
#   bucket = aws_s3_bucket.s3-tools-results-5439283.id
#   policy = data.aws_iam_policy_document.bucket_policy.json
#   depends_on = [aws_iam_role.eks-access-s3]
# }

# data "aws_iam_policy_document" "bucket_policy" {
#   statement {
#     actions = [
#       "s3:GetObject"
#     ]
#     resources = [
#       aws_s3_bucket.s3-tools-results-5439283.arn,
#       "${aws_s3_bucket.s3-tools-results-5439283.arn}/*"

#     ]
#     principals {
#       type        = "AWS"
#       identifiers = [aws_iam_role.eks-access-s3.arn]
#     }
#   }

#   statement {
#     actions = [
#       "s3:ListBucket"
#     ]
#     resources = ["*"]
    
#     principals {
#       type        = "AWS"
#       identifiers = [aws_iam_role.eks-access-s3.arn]
#     }
#   }
#   depends_on = [aws_iam_role.eks-access-s3]
# }