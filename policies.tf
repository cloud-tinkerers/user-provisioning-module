data "aws_iam_policy_document" "require_mfa" {
  statement {
    sid = "AllowViewAccountInfo"
    actions = [
      "iam:ListUsers",
      "iam:ListMFADevices",
      "iam:GetAccountPasswordPolicy",
      "iam:GetAccountSummary"
    ]
    resources = ["*"]
  }
  statement {
    sid = "ManageMFA"
    actions = [
      "iam:ChangePassword",
      "iam:GetUser",
      "iam:GetLoginProfile",
      "iam:UpdateLoginProfile",
      "iam:CreateVirtualMFADevice",
      "iam:DeleteVirtualMFADevice",
      "iam:DeactivateMFADevice",
      "iam:EnableMFADevice",
      "iam:ListMFADevices",
      "iam:ResyncMFADevice"
    ]
    resources = [
      "arn:aws:iam::*:user/$${aws:username}",
      "arn:aws:iam::*:mfa/*"
      ]
  }
  statement {
    sid = "DenyAllExceptListedIfNoMFA"
    effect = "Deny"
    not_actions = [
      "iam:ListUsers",
      "iam:ChangePassword",
      "iam:GetUser",
      "iam:ListVirtualMFADevices",
      "iam:CreateVirtualMFADevice",
      "iam:DeleteVirtualMFADevice",
      "iam:DeactivateMFADevice",
      "iam:EnableMFADevice",
      "iam:ListMFADevices",
      "iam:ResyncMFADevice"
    ]
    resources = ["*"]
    condition {
      test = "Bool"
      variable = "aws:MultiFactorAuthPresent"
      values = ["false"]
    }
  }
}

data "aws_iam_policy_document" "access_keys" {
  statement {
    sid = "AllowPersonalAccessKeys"
    actions = [
      "iam:CreateAccessKey",
      "iam:ListAccessKeys",
      "iam:UpdateAccessKey",
      "iam:DeleteAccessKey"
    ]
    resources = [
      "arn:aws:iam::*:user/$${aws:username}"
    ]
  }
}

resource "aws_ssm_document" "custom_session_document" {
  name          = "SSMCustomSessionDocument"
  document_type = "Session"
  
  content = <<EOF
{
  "schemaVersion": "1.0",
  "description": "Custom Session Document",
  "sessionType":"Standard_Stream",
  "inputs": {
    "runAsEnabled": false,
    "runAsDefaultUser": "",
    "idleSessionTimeout": "60",
    "maxSessionDuration": "640",
    "shellProfile": {
        "linux": "exec /bin/bash"
    }
  }
}
EOF
}

data "aws_iam_policy_document" "ssm_user_policy" {
  statement {
    actions = [
        "ssm:StartSession",
        "ssm:SendCommand", 
        "ssm:DescribeSessions",
        "ssm:GetConnectionStatus",
        "ssm:DescribeInstanceInformation",
        "ssm:DescribeInstanceProperties",
        "ec2:DescribeInstances"
    ]
    resources = [
        "arn:aws:ec2:*:*:*",
        "${aws_ssm_document.custom_session_document.arn}"
        ]
    effect = "Allow"
  }
  statement {
    actions = [
        "ssm:TerminateSession",
        "ssm:ResumeSession"
    ]
    resources = ["arn:aws:ssm:*:*:session/$${aws:userid}-*"]
    effect = "Allow"
  }
  statement {
    actions = ["kms:GenerateDateKey"]
    resources = ["arn:aws:kms:*:*:key/$${aws:userid}-ssm-key"]
    effect = "Allow"
  }
}
resource "aws_iam_policy" "ssm_user_policy" {
  name        = "CustomSSMPolicy"
  description = "IAM policy for default SSM session document"
  policy      = data.aws_iam_policy_document.ssm_user_policy.json
}