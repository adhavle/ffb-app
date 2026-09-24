resource "aws_iam_role" "draftboard_lambdas_role" {
  name = "draftboard-lambdas-role"
  tags = local.resource_tags
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [{
      "Action" : "sts:AssumeRole",
      "Principal" : { "Service" : "lambda.amazonaws.com" },
      "Effect" : "Allow"
    }]
  })
}

resource "aws_iam_policy" "draftboard_lambdas_policy" {
  name        = "draftboard-role-policy"
  tags        = local.resource_tags
  path        = "/"
  description = "AWS IAM Policy for managing the draftboard lambdas role"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Resource" : "arn:aws:logs:*:*:*",
        "Effect" : "Allow"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath",
          "ssm:PutParameter",
          "ssm:DeleteParameter"
        ],
        "Resource" : "arn:aws:ssm:*:*:parameter/draftboard-ffl/*"
      },
      {
        "Effect" : "Allow",
        "Action" : ["states:StartExecution"]
        "Resource" : [aws_sfn_state_machine.token_refresh_workflow.arn]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "draftboard_role_policy_attach" {
  role       = aws_iam_role.draftboard_lambdas_role.name
  policy_arn = aws_iam_policy.draftboard_lambdas_policy.arn
}

resource "aws_iam_role" "draftboard_states_role" {
  name = "draftboard-states-role"
  tags = local.resource_tags
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [{
      "Action" : "sts:AssumeRole",
      "Principal" : { "Service" : "states.us-west-1.amazonaws.com" },
      "Effect" : "Allow"
    }]
  })
}

resource "aws_iam_policy" "draftboard_states_policy" {
  name        = "draftboard-states-policy"
  tags        = local.resource_tags
  path        = "/"
  description = "AWS IAM Policy for managing the draftboard step functions role"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [{
      "Effect" : "Allow",
      "Action" : ["lambda:InvokeFunction"],
      "Resource" : [aws_lambda_function.draftboard-lambda-token-refresh.arn]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "draftboard_states_policy_attach" {
  role       = aws_iam_role.draftboard_states_role.name
  policy_arn = aws_iam_policy.draftboard_states_policy.arn
}
