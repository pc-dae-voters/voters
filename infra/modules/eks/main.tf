resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster.arn

  vpc_config {
    subnet_ids = concat(var.public_subnet_ids, var.private_subnet_ids)
  }

  depends_on = [aws_iam_role_policy_attachment.eks_cluster_policy]
  tags = merge({
    Name = var.cluster_name
  }, var.tags)
}

resource "aws_iam_role" "eks_cluster" {
  name = "${var.cluster_name}-cluster-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "eks.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
  tags = merge({
    Name = "${var.cluster_name}-cluster-role"
  }, var.tags)
}

resource "aws_iam_policy_attachment" "eks_cluster_policy" {
  name       = "${var.cluster_name}-cluster-policy-attachment"
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  roles      = [aws_iam_role.eks_cluster.name]
}

resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.cluster_name}-node-group"
  node_role_arn   = aws_iam_role.eks_node.arn
  subnet_ids      = var.private_subnet_ids

  scaling_config {
    desired_size = var.desired_capacity
    max_size     = var.max_capacity
    min_size     = var.min_capacity
  }

  instance_types = [var.instance_type]

  depends_on = [
    aws_eks_cluster.main,
    aws_iam_role_policy_attachment.eks_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.eks_container_registry_policy,
  ]
  tags = merge({
    Name = "${var.cluster_name}-node-group"
  }, var.tags)
}

resource "aws_iam_role" "eks_node" {
  name = "${var.cluster_name}-node-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
  tags = merge({
    Name = "${var.cluster_name}-node-role"
  }, var.tags)
}

resource "aws_iam_policy_attachment" "eks_node_policy" {
  name       = "${var.cluster_name}-node-policy-attachment"
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  roles      = [aws_iam_role.eks_node.name]
}

resource "aws_iam_policy_attachment" "eks_cni_policy" {
  name       = "${var.cluster_name}-cni-policy-attachment"
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSCNIPolicy"
  roles      = [aws_iam_role.eks_node.name]
}

resource "aws_iam_policy_attachment" "eks_container_registry_policy" {
  name       = "${var.cluster_name}-container-registry-policy-attachment"
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  roles      = [aws_iam_role.eks_node.name]
}
