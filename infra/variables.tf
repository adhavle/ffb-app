variable "terraform_state_s3" {
  type = string
  default = null
}

variable "step_function_name" {
  type    = string
  default = "token-refresh-workflow"
}
