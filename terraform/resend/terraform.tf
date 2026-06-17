terraform {
  backend "s3" {
    bucket = "terraform-state"
    endpoints = {
      s3 = "https://s3.home399.thiagoalmeida.xyz"
    }
    key                         = "resend/terraform.tfstate"
    access_key                  = ""
    secret_key                  = ""
    region                      = "us-east-1"
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    use_path_style              = true
  }
}
