output "ses_username" {
  value = var.pgp_key == null ? aws_iam_access_key.ses-smtp[0].id : aws_iam_access_key.ses-smtp-encrypted[0].id
}
output "ses_password" {
  value = var.pgp_key == null ? aws_iam_access_key.ses-smtp[0].ses_smtp_password_v4 : aws_iam_access_key.ses-smtp-encrypted[0].ses_smtp_password_v4
}