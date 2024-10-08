#Create IAM role for EBS CSI driver
data "aws_iam_policy_document" "ebs_csi_trust_policy" {

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

resource "aws_iam_role" "ebs_csi_trust_role" {
  name               = "${var.env}-ebs-csi-controller"
  assume_role_policy = data.aws_iam_policy_document.ebs_csi_trust_policy.json
}

#access to kms
data "aws_iam_policy_document" "access_eks_kms_policy" {
  statement {
    sid     = "LegionAccessEKSKMS"
    effect  = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
      "kms:CreateGrant",
      "kms:ListGrants",
      "kms:RevokeGrant"
    ]
    resources = [aws_kms_key.eks_kms_key.arn]
  }
}


# resource "aws_iam_policy" "ssm-access" {
#   name        = "ssm-access"
#   policy      = jsonencode({
#     "Version": "2012-10-17",
#     "Statement": [
#         {
#             "Effect": "Allow",
#             "Action": "ssm:GetParameter",
#             "Resource": [
#                 "arn:aws:ssm:us-east-1:623045223656:parameter/GITHUB_API_KEY",
#                 "arn:aws:ssm:us-east-1:623045223656:parameter/DOJO_URL",
#                 "arn:aws:ssm:us-east-1:623045223656:parameter/DOJO_API_KEY",
#                 "arn:aws:ssm:us-east-1:623045223656:parameter/JIRA_API_KEY",
#                 "arn:aws:ssm:us-east-1:623045223656:parameter/JIRA_URL",
#                 "arn:aws:ssm:us-east-1:623045223656:parameter/JIRA_USER"
#             ]
#         }
#     ]
# })
# }



resource "aws_iam_policy" "access_eks_kms_access" {
  name        = "${var.env}-eks-kms-access"
  path        = "/"
  description = "For KMS access"
  policy      = data.aws_iam_policy_document.access_eks_kms_policy.json
}

#access to assume role
data "aws_iam_policy_document" "access_eks_kmsassume_policy" {
  statement {
    sid       = "AccessEKSAssumeRoleKMS"
    effect    = "Allow"
    actions   = ["sts:AssumeRole"]
    resources = [aws_iam_role.ebs_csi_trust_role.arn]
  }
}

resource "aws_iam_policy" "access_eks_kmsassume" {
  name        = "${var.env}-eks-kmsassume"
  path        = "/"
  description = "For KMS assume"
  policy      = data.aws_iam_policy_document.access_eks_kmsassume_policy.json
}

#attach policies to role
resource "aws_iam_role_policy_attachment" "eks_access_kms_policy" {
  policy_arn = aws_iam_policy.access_eks_kms_access.arn
  role       = aws_iam_role.ebs_csi_trust_role.name
}


resource "aws_iam_role_policy_attachment" "eks_access_kms_assume_policy" {
  policy_arn = aws_iam_policy.access_eks_kmsassume.arn
  role       = aws_iam_role.ebs_csi_trust_role.name
}

resource "aws_iam_role_policy_attachment" "eks_access_ebscsi" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.ebs_csi_trust_role.name
}

#Setup IAM role and IAM profile for Bastion access to EKS
#eks manage role
resource "aws_iam_role" "eks-manage-role" {
  name               = "eks-manage-role-${var.env}"
  assume_role_policy = data.aws_iam_policy_document.eks-policy-assume-role.json
}

data "aws_iam_policy_document" "eks-policy-assume-role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}  
  
data "aws_iam_policy_document" "eks-policy-get-token" {
  statement {
    actions   = ["eks:DescribeCluster", "eks:ListClusters"]
    resources = [module.eks.cluster_arn]
  }
}  
  
resource "aws_iam_policy" "eks-manage-policy" {
  name        = "eks-manage-policy-${var.env}"
  path        = "/"
  policy      = data.aws_iam_policy_document.eks-policy-get-token.json
}

#attach policy to eks manage role
resource "aws_iam_role_policy_attachment" "eks-manage-attach" {
  policy_arn = aws_iam_policy.eks-manage-policy.arn
  role       = aws_iam_role.eks-manage-role.name
}

#create profile
resource "aws_iam_instance_profile" "eks-manage-profile" {
  name = "eks-manage-profile-${var.env}"
  role = aws_iam_role.eks-manage-role.name
}

#For pods s3 accessing
data "aws_iam_policy_document" "s3-policy" {

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
  name               = "eks-${var.env}-s3"
  assume_role_policy = data.aws_iam_policy_document.s3-policy.json
}

#============= (eksuser)IAM User with Full EKS Access ==============## 

resource "aws_iam_user" "eksuser" {
  name = "eksuser"
}  

resource "aws_iam_user_policy_attachment" "attach_EKS_Access_policy" {
  user       = aws_iam_user.eksuser.name
  policy_arn = aws_iam_policy.EKS-Access.arn 
}

resource "aws_iam_policy" "EKS-Access" {
  name        = "EKS-Access"
  policy      = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": "eks:*",
            "Resource": "*"
        }
    ]
})
}

#============= (eks-role)IAM Role with Full EKS Access ==============## 
resource "aws_iam_role" "eks-role" {
  name               = "eks-role-${var.env}"
  assume_role_policy = data.aws_iam_policy_document.eks-policy-assume-role.json
}


resource "aws_iam_role_policy_attachment" "attach_ViewOnlyAccess_policy" {
  role       = aws_iam_role.eks-role.name
  policy_arn = "arn:aws:iam::aws:policy/job-function/ViewOnlyAccess"
}

#============= (eksuser)IAM User with Full EKS Access ==============## 



#============= (scan-account)Service Account IAM Role ==============#
resource "aws_iam_role" "eks-access-s3-2" {
  name               = "eks-${var.env}-s3-2"
  assume_role_policy = data.aws_iam_policy_document.s3-policy-2.json
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


data "aws_iam_policy_document" "policy" {
  statement {
    effect = "Allow"

    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject",
    ]

    resources = [
      aws_s3_bucket.s3-tools-results-5439283.arn,
      "${aws_s3_bucket.s3-tools-results-5439283.arn}/*",
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "ssm:GetParameter",
    ]

    resources = [
      "arn:aws:ssm:us-east-1:623045223656:parameter/GITHUB_TOKEN",
      "arn:aws:ssm:us-east-1:623045223656:parameter/DOJO_IMPORT_URL",
      "arn:aws:ssm:us-east-1:623045223656:parameter/DOJO_API_KEY",
      "arn:aws:ssm:us-east-1:623045223656:parameter/JIRA_API_KEY",
      "arn:aws:ssm:us-east-1:623045223656:parameter/JIRA_URL",
      "arn:aws:ssm:us-east-1:623045223656:parameter/JIRA_USER",
      "arn:aws:ssm:us-east-1:623045223656:parameter/eksuser_token",
      "arn:aws:ssm:us-east-1:623045223656:parameter/cluster_certificate_authority_data",
      "arn:aws:ssm:us-east-1:623045223656:parameter/EKS_SERVER_URL"
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "ssm:DescribeParameters",
    ]

    resources = [
      "*",
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "kms:Decrypt",
    ]

    resources = [
      "arn:aws:kms:us-east-1:623045223656:key/aws/ssm",
    ]
  }
}

resource "aws_iam_policy" "policy" {
  name        = "test-policy"
  description = "A test policy"
  policy      = data.aws_iam_policy_document.policy.json
}


resource "aws_iam_role_policy_attachment" "test-attach" {
  role       = aws_iam_role.eks-access-s3-2.name
  policy_arn = aws_iam_policy.policy.arn
}

resource "aws_iam_role_policy_attachment" "attach_ViewOnlyAccess_policy-2" {
  role       = aws_iam_role.eks-access-s3-2.name
  policy_arn = "arn:aws:iam::aws:policy/job-function/ViewOnlyAccess"
}
     
data "aws_iam_policy_document" "policy-jira-parameter" {
  statement {
    effect = "Allow"

    actions = [
      "ssm:GetParameter*",
      "ssm:GetParameters",
    ]

    resources = [
      "arn:aws:ssm:us-east-1:623045223656:parameter/JIRA_API_KEY",
      "arn:aws:ssm:us-east-1:623045223656:parameter/JIRA_URL",
      "arn:aws:ssm:us-east-1:623045223656:parameter/JIRA_USER"
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "kms:Decrypt",
    ]

    resources = [
      "arn:aws:kms:us-east-1:623045223656:key/aws/ssm",
    ]
  }
}

resource "aws_iam_policy" "policy-jira" {
  name        = "jira-perms"
  description = "jira permissions"
  policy      = data.aws_iam_policy_document.policy-jira-parameter.json
}


data "aws_iam_policy_document" "policy-workernode" {
  statement {
    effect = "Allow"

    actions = [
      "ssm:GetParameter"
    ]

    resources = [
      "arn:aws:ssm:us-east-1:623045223656:parameter/eksuser_token",
      "arn:aws:ssm:us-east-1:623045223656:parameter/cluster_certificate_authority_data",
      "arn:aws:ssm:us-east-1:623045223656:parameter/EKS_SERVER_URL"
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "kms:Decrypt",
    ]

    resources = [
      "arn:aws:kms:us-east-1:623045223656:key/aws/ssm",
    ]
  }
}

resource "aws_iam_policy" "policy-workernode" {
  name        = "workernode"
  description = "A workernode policy"
  policy      = data.aws_iam_policy_document.policy-workernode.json
}