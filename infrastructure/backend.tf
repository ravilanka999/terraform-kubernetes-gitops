terraform {
  backend "s3" {
    # NOTE: You MUST create this S3 bucket before running terraform init
    # Recommended naming: terraform-state-<aws_account_id>-<region>
    bucket    = "terraform-state-gitops-demo-ap-southeast-2"
    key       = "infrastructure/terraform.tfstate"
    region    = "ap-southeast-2"
    encrypt   = true
    use_lockfile = true
  }
}

# Local fallback backend (for testing without S3)
# Uncomment below to use local backend instead
# terraform {
#   backend "local" {
#     path = "terraform.tfstate"
#   }
# }
