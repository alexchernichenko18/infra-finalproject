resource "kubernetes_storage_class_v1" "ebs_sc" {
  metadata {
    name = "ebs-sc"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }

  storage_provisioner = "ebs.csi.aws.com"

  reclaim_policy       = "Delete"
  volume_binding_mode  = "WaitForFirstConsumer"

  parameters = {
    type = "gp3"
  }
}
resource "kubernetes_namespace" "jenkins" {
  metadata {
    name = "jenkins"
  }
}


resource "kubernetes_service_account" "jenkins_sa" {
  metadata {
    name      = "jenkins-sa"
    namespace = "jenkins"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.jenkins_kaniko_role.arn
    }
  }
  depends_on = [kubernetes_namespace.jenkins]
}

# Data block для assume role політики Jenkins Kaniko
data "aws_iam_policy_document" "jenkins_kaniko_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }
    condition {
      test     = "StringEquals"
      variable = "${replace(var.oidc_provider_url, "https://", "")}:sub"
      values   = ["system:serviceaccount:jenkins:jenkins-sa"]
    }
  }
}

resource "aws_iam_role" "jenkins_kaniko_role" {
  name               = "${var.cluster_name}-jenkins-kaniko-role"
  assume_role_policy = data.aws_iam_policy_document.jenkins_kaniko_assume_role.json
}

# Data block для ECR політики Jenkins
data "aws_iam_policy_document" "jenkins_ecr" {
  statement {
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:PutImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:DescribeRepositories",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "jenkins_ecr_policy" {
  name   = "${var.cluster_name}-jenkins-kaniko-ecr-policy"
  role   = aws_iam_role.jenkins_kaniko_role.id
  policy = data.aws_iam_policy_document.jenkins_ecr.json
}



resource "helm_release" "jenkins" {
  name             = "jenkins"
  namespace        = "jenkins"
  repository       = "https://charts.jenkins.io"
  chart            = "jenkins"
  version          = "5.8.27"
  create_namespace = false

  values = [
    file("${path.module}/values.yaml")
  ]
}