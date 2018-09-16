variable "digital_ocean_token"{}

variable "digital_ocean_region" {
  default = "nyc1"
}

variable "droplet_size" {
  default = "1gb"
}

variable "droplet_image" {
  default = "ubuntu-18-04-x64"
}

variable "volume_size" {
  default = 10
}
