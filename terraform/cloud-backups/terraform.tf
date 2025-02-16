terraform {
  backend "s3" {
    bucket = "terraform-state" # Name of the S3 bucket
    endpoints = {
      s3 = "https://s3.home399.thiagoalmeida.xyz" # Minio endpoint

    }
    key = "cloud-backups/terraform.tfstate" # Name of the tfstate file

    access_key = "" # on ./state.config
    secret_key = ""

    region                      = "main" # Region validation will be skipped
    skip_credentials_validation = true   # Skip AWS related checks and validations
    skip_requesting_account_id  = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    use_path_style              = true # Enable path-style S3 URLs (https://<HOST>/<BUCKET> https://developer.hashicorp.com/terraform/language/settings/backends/s3#use_path_style
  }
}

