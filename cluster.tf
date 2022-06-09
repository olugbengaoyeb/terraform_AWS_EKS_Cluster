#--------------------------#
#--------------------------#
#eks cluster Definition
#--------------------------#
#--------------------------#


resource "aws_eks_cluster" "narutoeks" {
  name     = "narutoeksclusterdemo"
  role_arn = aws_iam_role.eksnarutorole.arn

  vpc_config {
    subnet_ids = ["subnet-0a5c412db25d3a8dd", "subnet-0db4fac0ef714b2f8"]
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Cluster handling.
  # Otherwise, EKS will not be able to properly delete EKS managed EC2 infrastructure such as Security Groups.
  depends_on = [
    aws_iam_role_policy_attachment.narutoeksrole-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.narutoeksrole-AmazonEKSVPCResourceController,
  ]
}

output "endpoint" {
  value = aws_eks_cluster.narutoeks.endpoint
}

output "kubeconfig-certificate-authority-data" {
  value = aws_eks_cluster.narutoeks.certificate_authority[0].data
}




#--------------------------#
#--------------------------#
#IAM Role For Eks Cluster
#--------------------------#
#--------------------------#


resource "aws_iam_role" "eksnarutorole" {
  name = "eksnaruto-cluster-role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "narutoeksrole-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eksnarutorole.name
}



# Optionally, enable Security Groups for Pods
# Reference: https://docs.aws.amazon.com/eks/latest/userguide/security-groups-for-pods.html


resource "aws_iam_role_policy_attachment" "narutoeksrole-AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eksnarutorole.name
}


#-------------------------------------#
#-------------------------------------#
#Enabling IAM Role For Service Account
#-------------------------------------#
#-------------------------------------#

data "tls_certificate" "narutoekstls" {
  url = aws_eks_cluster.narutoeks.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "narutoeksopidc" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.narutoekstls.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.narutoeks.identity[0].oidc[0].issuer
}

data "aws_iam_policy_document" "narutoeksdoc_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.narutoeksopidc.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:aws-node"]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.narutoeksopidc.arn]
      type        = "Federated"
    }
  }
}
