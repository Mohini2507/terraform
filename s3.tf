#Creating S3 buckets
resource "aws_s3_bucket" "ui" {
  bucket          = "s3-codebuild-bucket-20092019-dev-ui-bucket" //Using - instead of _, because _ doesn't allow the bucket to be exposesd as website
  acl             = "private"

  tags = {
    Env         = "dev"
    Project     = "s3-codebuild-bucket-20092019"
    Name        = "s3-codebuild-bucket-20092019-dev-ui-bucket"
    Type        = "bucket"
    Component   = "ui"
  }
    website {
    index_document = "index.html"
    error_document = "error.html"

    routing_rules = <<EOF
  EOF
}
}

resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
  comment = "Assignment2 user"
}
resource "aws_cloudfront_distribution" "s3_distribution" {
  enabled = true
  price_class  = "PriceClass_200"
  http_version = "http1.1"

  origin {
    domain_name = "${aws_s3_bucket.ui.bucket}.s3.us-east-1.amazonaws.com"
    origin_id   = "S3-${aws_s3_bucket.ui.bucket}"

    s3_origin_config {
      origin_access_identity = "${aws_cloudfront_origin_access_identity.origin_access_identity.cloudfront_access_identity_path}"
  }
 }

  is_ipv6_enabled     = true
  comment             = "This is assignment 2 distribution!"

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${aws_s3_bucket.ui.bucket}"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
		 }
    }
        viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 60
    max_ttl                = 60
  }

  # Cache behavior with precedence 0
  ordered_cache_behavior {
    path_pattern     = "/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = "S3-${aws_s3_bucket.ui.bucket}"

    forwarded_values {
      query_string = false
      headers      = ["Origin"]

      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  # Restricts who is able to access this content
    restrictions {
        geo_restriction {
            # type of restriction, blacklist, whitelist or none
            restriction_type = "none"
        }
    }

  tags = {
    Environment = "dev"
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

}
data "aws_iam_policy_document" "s3_policy" {
    statement {
    actions   = ["s3:GetObject"]
	resources = ["${aws_s3_bucket.ui.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = ["${aws_cloudfront_origin_access_identity.origin_access_identity.iam_arn}"]
    }
   }
 }
 resource "aws_s3_bucket_policy" "example" {
  bucket = "${aws_s3_bucket.ui.id}"
  policy = "${data.aws_iam_policy_document.s3_policy.json}"
}
