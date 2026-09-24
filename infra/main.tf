# https://dev.to/aws-builders/provisioning-aws-infrastructure-using-terraform-and-github-actions-40ei
# https://meriemterki.medium.com/step-by-step-guide-to-setting-up-terraform-aws-cli-and-your-aws-environment-b8c2ffa60912

resource "aws_lambda_function" "draftboard-lambda-auth-request-url" {
  function_name    = "draftboard-lambda-auth-request-url"
  handler          = "draftboard-lambda-auth-request-url.lambda_handler"
  runtime          = "python3.14"
  role             = aws_iam_role.draftboard_lambdas_role.arn
  filename         = "src/draftboard-lambda-auth-request-url.zip"
  source_code_hash = filebase64sha256("src/draftboard-lambda-auth-request-url.zip")
  tags             = local.resource_tags
}

resource "aws_lambda_function" "draftboard-lambda-auth-callback" {
  function_name    = "draftboard-lambda-auth-callback"
  handler          = "callback-lambda::Draftboard.Function::CallbackHandler"
  runtime          = "dotnet10"
  timeout          = 60
  role             = aws_iam_role.draftboard_lambdas_role.arn
  filename         = "src/draftboard-lambda-auth-callback.zip"
  source_code_hash = filebase64sha256("src/draftboard-lambda-auth-callback.zip")
  environment {
    variables = {
      REFRESH_STATE_MACHINE_ARN = "${local.state_machine_arn}"
    }
  }
  tags = local.resource_tags
}

resource "aws_lambda_function" "draftboard-lambda-token-refresh" {
  function_name    = "draftboard-lambda-token-refresh"
  handler          = "TokenRefresher::Draftboard.MainFunction::TokenRefreshHandler"
  runtime          = "dotnet10"
  timeout          = 60
  role             = aws_iam_role.draftboard_lambdas_role.arn
  filename         = "src/draftboard-lambda-token-refresh.zip"
  source_code_hash = filebase64sha256("src/draftboard-lambda-token-refresh.zip")
  environment {
    variables = {
      REFRESH_STATE_MACHINE_ARN = "${local.state_machine_arn}"
    }
  }
  tags = local.resource_tags
}

resource "aws_sfn_state_machine" "token_refresh_workflow" {
  name     = var.step_function_name
  role_arn = aws_iam_role.draftboard_states_role.arn

  definition = jsonencode({
    Comment = "Token refresh flow"
    StartAt = "SetTimer"
    States = {
      SetTimer = {
        Type = "Pass"
        Assign = {
          wait_seconds = "{% $states.input.expires_in - 60 %}"
        }
        Next = "WaitForNearExpiry"
      }

      WaitForNearExpiry = {
        Type    = "Wait"
        Seconds = "{% $wait_seconds %}"
        Next    = "RefreshToken"
      }

      RefreshToken = {
        Type     = "Task"
        Resource = "arn:aws:states:::lambda:invoke"
        Arguments = {
          FunctionName = aws_lambda_function.draftboard-lambda-token-refresh.arn
        }
        End = true
      }
    }
    QueryLanguage  = "JSONata"
    TimeoutSeconds = 60
  })
}

check "validate-step-function-name" {
  assert {
    condition     = aws_sfn_state_machine.token_refresh_workflow.arn == local.state_machine_arn
    error_message = "${aws_sfn_state_machine.token_refresh_workflow.arn} did not match the expected ARN ${local.state_machine_arn}"
  }
}