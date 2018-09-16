provider "digitalocean" {
  token = "${var.digital_ocean_token}"
}

resource "digitalocean_ssh_key" "terraform_key" {
  name       = "terraform-managed key"
  public_key = "${file("~/.ssh/id_rsa.pub")}"
}

resource "digitalocean_volume" "do_volume" {
  name = "mastodon_files"
  region = "${var.digital_ocean_region}"
  size = "${var.volume_size}"
  initial_filesystem_type = "ext4"
  initial_filesystem_label = "mastodon_files"
}

resource "digitalocean_droplet" "mastodon" {
  name = "mastodon"
  image = "${var.droplet_image}"
  region = "${var.digital_ocean_region}"
  size = "${var.droplet_size}"
  ipv6 = true
  ssh_keys = [ "${digitalocean_ssh_key.terraform_key.id}" ]
  volume_ids = [ "${digitalocean_volume.do_volume.id}" ]
}

output "droplet_ip" {
  value = {
    ipv4 = "${digitalocean_droplet.mastodon.ipv4_address}"
    ipv6 = "${digitalocean_droplet.mastodon.ipv6_address}"
  }

}
