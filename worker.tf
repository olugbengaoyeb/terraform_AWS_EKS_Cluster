#--------------------------#
#--------------------------#
#Creating the Worker Node
#--------------------------#
#--------------------------#

resource "aws_eks_node_group" "narutoeksnode" {
  cluster_name    = aws_eks_cluster.narutoeks.id
  node_group_name = "narutoeksnode"
  node_role_arn   = aws_iam_role.narutoeksnoderole.arn
  subnet_ids      = ["subnet-0a5c412db25d3a8dd", "subnet-0db4fac0ef714b2f8"]

  scaling_config {
    desired_size = 3
    max_size     = 3
    min_size     = 3
  }

  update_config {
    max_unavailable = 3
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_iam_role_policy_attachment.narutoeksnode-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.narutoeksnode-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.narutoeksnode-AmazonEC2ContainerRegistryReadOnly,
  ]
}


#--------------------------#
#--------------------------#
#IAM Role for Eks Node Group
#--------------------------#
#--------------------------#

resource "aws_iam_role" "narutoeksnoderole" {
  name = "narutoeksnoderole"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "narutoeksnode-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.narutoeksnoderole.name
}

resource "aws_iam_role_policy_attachment" "narutoeksnode-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.narutoeksnoderole.name
}

resource "aws_iam_role_policy_attachment" "narutoeksnode-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.narutoeksnoderole.name
}
