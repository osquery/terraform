resource "aws_s3_bucket" "bucket" {
  provider = aws.osquery-infra
  bucket = local.remote_state_bucket
  acl    = "private"
  #region = local.main_region

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  #logging {
  #  target_bucket = local.logging_bucket"
  #  target_prefix = "logs/osquery-terraform-state"
  #}

  versioning {
    enabled = true
  }

  lifecycle_rule {
    enabled = true

    noncurrent_version_transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    noncurrent_version_transition {
      days          = 60
      storage_class = "GLACIER"
    }

    noncurrent_version_expiration {
      days = 90
    }
  }
}

resource "aws_dynamodb_table" "lock_table" {
  provider = aws.osquery-infra

  name           = "osquery-terraform-state"
  hash_key       = "LockID"
  read_capacity  = 2
  write_capacity = 2
  attribute {
    name = "LockID"
    type = "S"
  }
}
