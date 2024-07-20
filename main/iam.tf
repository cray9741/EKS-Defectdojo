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


  
  



