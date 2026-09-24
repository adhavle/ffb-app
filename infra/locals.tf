locals {
  resource_tags = {
    repo    = "draftboard"
    version = "2026-08"
  }

  state_machine_arn = format(
    "arn:%s:states:%s:%s:stateMachine:%s",
    data.aws_partition.current.partition,
    data.aws_region.current.region,
    data.aws_caller_identity.current.account_id,
  var.step_function_name)
}
