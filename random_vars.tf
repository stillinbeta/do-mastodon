resource "random_string" "otp_secret" {
  length = 64
  special = false
}

resource "random_string" "secret_key_base" {
  length = 128
  special = false
  upper = false
}

resource "random_string" "postgres_password" {
  length = 64
  special = false
}
