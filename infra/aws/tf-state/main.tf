module "backup_bucket" {
  source        = "../modules/s3"
  name          = var.bucket_name
  force_destroy = true
}

module "terraform_lock" {
  source = "../modules/dynamodb"
  name   = "${var.lockdb_name}"
}

output "bucket_arn" {
  value = module.backup_bucket.arn
}