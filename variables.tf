// Digital ocean
variable "digital_ocean_token"{}

variable "digital_ocean_region" {
  default = "nyc1"
}

variable "droplet_size" {
  default = "2gb"
}

variable "droplet_image" {
  default = "ubuntu-18-04-x64"
}

variable "volume_size" {
  default = 10
}

// Tag versions for docker images
variable "redis_version" {
  default = "4.0-alpine"
}

variable "postgres_version" {
  default = "10.5-alpine"
}

variable "mastodon_version" {
  default = "v2.5.0"
}

variable "nginx_version" {
  default = "1.15-alpine"
}

// user configuration
variable "mastodon_domain" {}
