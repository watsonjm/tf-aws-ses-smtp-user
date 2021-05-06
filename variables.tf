variable "ses_domain" {
  type        = string
  description = "Domain to be used for SES SMTP user."
}
variable "wait_ses_validation" {
  type    = bool
  default = false
}
variable "tag_prefix" {
  type        = string
  default     = null
  description = "'Name' tag prefix, used for resource naming."
}
variable "common_tags" {
  type        = map(any)
  description = "map of tags"
}
variable "pgp_key" {
  type        = string
  default     = null
  description = "file contents of a pgp key to be used for SMTP user creation."
}
variable "verify_domain" {
  type        = bool
  default     = true
  description = "Set to false if DKIM and TXT records already exist for some reason"
}