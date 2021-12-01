locals {
  ses_domain = data.aws_route53_zone.this
}

data "aws_route53_zone" "this" {
  name         = var.ses_domain
  private_zone = false
}

data "aws_region" "current" {}

resource "aws_ses_domain_identity" "this" {
  domain = local.ses_domain.name
}

resource "aws_route53_record" "this" {
  count   = var.verify_domain && var.use_txt_record_verification ? 1 : 0
  zone_id = local.ses_domain.zone_id
  name    = "_amazonses.${aws_ses_domain_identity.this.id}"
  type    = "TXT"
  ttl     = "600"
  records = [aws_ses_domain_identity.this.verification_token]
}

resource "aws_ses_domain_identity_verification" "this" {
  count  = var.wait_ses_validation ? 1 : 0
  domain = aws_ses_domain_identity.this.id
}

resource "aws_ses_domain_dkim" "this" {
  domain = aws_ses_domain_identity.this.domain
}

resource "aws_route53_record" "verification" {
  count   = var.verify_domain ? 3 : 0
  zone_id = local.ses_domain.zone_id
  name    = "${element(aws_ses_domain_dkim.this.dkim_tokens, count.index)}._domainkey.${aws_ses_domain_identity.this.domain}"
  type    = "CNAME"
  ttl     = "600"
  records = ["${element(aws_ses_domain_dkim.this.dkim_tokens, count.index)}.dkim.amazonses.com"]
}

resource "aws_ses_domain_mail_from" "this" {
  domain           = aws_ses_domain_identity.this.domain
  mail_from_domain = "bounce.${aws_ses_domain_identity.this.domain}"
}

resource "aws_route53_record" "mail_from_mx" {
  count   = var.create_mail_from_records ? 1 : 0
  zone_id = local.ses_domain.zone_id
  name    = aws_ses_domain_mail_from.this.mail_from_domain
  type    = "MX"
  ttl     = "600"
  records = ["10 feedback-smtp.${data.aws_region.current.name}.amazonses.com"]
}

#TXT record for SPF
resource "aws_route53_record" "mail_from_txt" {
  count   = var.create_mail_from_records ? 1 : 0
  zone_id = local.ses_domain.zone_id
  name    = aws_ses_domain_mail_from.this.mail_from_domain
  type    = "TXT"
  ttl     = "600"
  records = ["v=spf1 include:amazonses.com -all"]
}

#SMTP user
resource "aws_iam_user" "ses-smtp" {
  name = "${var.tag_prefix}-ses-smtp-user"

  tags = merge(var.common_tags, { Name = "${var.ses_domain} smtp user" })
}

resource "aws_iam_user_policy" "ses-smtp" {
  name   = "AmazonSesSendingAccess"
  user   = aws_iam_user.ses-smtp.name
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ses:SendEmail",
                "ses:SendRawEmail"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_access_key" "ses-smtp-encrypted" {
  count   = var.pgp_key == null ? 0 : 1
  user    = aws_iam_user.ses-smtp.name
  pgp_key = var.pgp_key
}

resource "aws_iam_access_key" "ses-smtp" {
  count   = var.pgp_key == null ? 1 : 0
  user    = aws_iam_user.ses-smtp.name
  pgp_key = var.pgp_key
}