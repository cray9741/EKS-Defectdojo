# IAM User with Full EKS Access
resource "aws_iam_user" "eks_user" {
  name = "eksuser"
}

resource "aws_iam_user_policy" "eks_user_policy" {
  name   = "eks-user-policy"
  user   = aws_iam_user.eks_user.name
  policy = data.aws_iam_policy_document.eks_user_policy.json
}

data "aws_iam_policy_document" "eks_user_policy" {
  statement {
    actions   = ["eks:*"]
    resources = ["*"]
  }
}


#For pods s3 accessing
data "aws_iam_policy_document" "s3-policy-2" {

  statement {
    effect = "Allow"

    principals {
      type        = "Federated"
      identifiers = [module.eks.oidc_provider_arn]
    }

    actions = [
      "sts:AssumeRoleWithWebIdentity"
    ]

    condition {
      test     = "StringEquals"
      values   = ["sts.amazonaws.com"]
      variable = "${replace(module.eks.cluster_oidc_issuer_url, "https://", "")}:aud"
    }
  }
}

#IAM role for s3 accessing
resource "aws_iam_role" "eks-access-s3" {
  name               = "eks-${var.env}-s3-2"
  assume_role_policy = data.aws_iam_policy_document.s3-policy-2.json
}


data "aws_iam_policy_document" "policy" {
  statement {
    effect    = "Allow"

    actions   = [
        "s3:PutObject",
        "s3:GetObject",
        "s3:DeleteObject",
        ]

    resources = [
        aws_s3_bucket.s3-tools-results-5439283.arn,
        "${aws_s3_bucket.s3-tools-results-5439283.arn}/*",
         ]
  }
}




{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:GetObject",
                "s3:DeleteObject"
            ],
            "Resource": [
                ws_s3_bucket.s3-tools-results-5439283.arn,
                "arn:aws:s3:::#sec-tooling-backend-tools-results-87238225#",
                "arn:aws:s3:::#the-oidc-bucket-3092812#",
                "arn:aws:s3:::#the-oidc-bucket-3092812#/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket*"
            ],
            "Resource": [
                "*"
            ]
        }
    ]
}
resource "aws_iam_policy" "policy" {
  name        = "test-policy"
  description = "A test policy"
  policy      = data.aws_iam_policy_document.policy.json
}

resource "aws_iam_role_policy_attachment" "test-attach" {
  role       = aws_iam_role.role.name
  policy_arn = aws_iam_policy.policy.arn
}