resource "aws_s3_bucket" "scripts" {
  region = "${var.region}"
  bucket = "${var.name}"

  acl = "private"

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = "${aws_kms_key.key_script.arn}"
        sse_algorithm     = "aws:kms"
      }
    }
  }

  tags = "${merge(
    map(
      "Name", "${var.name}",
      "Description", "Terraform to store scripts"
    ),
    var.tags
  )}"
}

resource "aws_kms_key" "key_script" {
  description             = "This key is used to encrypt bucket objects"
  deletion_window_in_days = 10
}


resource "aws_s3_bucket_object" "bucket" {
  bucket = "${aws_s3_bucket.scripts.id}"
  key = "scripts"
  source = "/files/script"
  etag = "${md5(file("/files/script"))}"
  
  depends_on = ["aws_s3_bucket.scripts"]
}

resource "null_resource" "upload_folder" {
  provisioner "local-exec" {
    command = "aws s3 sync /scripts/ s3://${aws_s3_bucket.scripts.id}"
  }
  depends_on = ["aws_s3_bucket.scripts"]
}
