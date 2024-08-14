// Users
resource "aws_iam_user" "engineers" {
  for_each = toset(var.engineers)
  name = each.value
}

resource "aws_iam_user" "read_only" {
  for_each = toset(var.read_only)
  name = each.value
}

// User group and user membership to engineers group
resource "aws_iam_group" "engineers" {
  name = "${var.client}-engineers"
}

resource "aws_iam_group_membership" "engineers" {
  name = "${var.client}-engineers"

  users = [
    for engineer in var.engineers : aws_iam_user.engineers[engineer].name
  ]

  group = aws_iam_group.engineers.name
}

// User group and user membership to read only group
resource "aws_iam_group" "read_only" {
  name = "${var.client}-read-only"
}

resource "aws_iam_group_membership" "read_only" {
  name = "${var.client}-read-only"

  users = [
    for user in var.read_only : aws_iam_user.read_only[user].name]
  
  group = aws_iam_group.read_only.name
}

// Read only setup
resource "aws_iam_group_policy_attachment" "readonly_group_attachment" {
  for_each = {
    "engineers" = aws_iam_group.engineers.name,
    "read_only" = aws_iam_group.read_only.name
  }
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
  group      = each.value
}

resource "aws_iam_group_policy_attachment" "iam_password_reset" {
    for_each = {
    "engineers" = aws_iam_group.engineers.name,
    "read_only" = aws_iam_group.read_only.name
  }
  policy_arn = "arn:aws:iam::aws:policy/IAMUserChangePassword"
  group      = each.value
}

// Useful policies
resource "aws_iam_policy" "access_keys" {
  name = "access-keys"
  path = "/"
  description = "Allows a user to create, list, update and delete their own access keys."
  policy = data.aws_iam_policy_document.access_keys.json
}

resource "aws_iam_group_policy_attachment" "access_keys" {
  policy_arn = aws_iam_policy.access_keys.arn
  group = aws_iam_group.engineers.name
}

resource "aws_iam_group_policy_attachment" "ssm_user_policy" {
  policy_arn = aws_iam_policy.ssm_user_policy.arn
  group = aws_iam_group.engineers.name
}

// Require MFA
resource "aws_iam_policy" "require_mfa" {
  name   = "require_mfa"
  path   = "/"
  policy = data.aws_iam_policy_document.require_mfa.json
}

resource "aws_iam_group_policy_attachment" "require_mfa" {
    for_each = {
    "engineers" = aws_iam_group.engineers.name,
    "read_only" = aws_iam_group.read_only.name
  }
  policy_arn = aws_iam_policy.require_mfa.arn
  group = each.value
}