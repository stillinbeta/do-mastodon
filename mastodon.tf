provider "digitalocean" {
  token = "${var.digital_ocean_token}"
  version = "1.0.0"
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

  lifecycle {
    prevent_destroy = true
  }
}

resource "digitalocean_floating_ip" "ip" {
  region = "${var.digital_ocean_region}"

  lifecycle {
    prevent_destroy = true
  }

}

resource "digitalocean_floating_ip_assignment" "ip_assignment"{
  droplet_id = "${digitalocean_droplet.mastodon.id}"
  ip_address = "${digitalocean_floating_ip.ip.ip_address}"
}

data "template_file" "ansible_vars" {
  template = "${file("ansible.template")}"

  vars {
    redis_version = "${var.redis_version}"
    postgres_version = "${var.postgres_version}"
    mastodon_version = "${var.mastodon_version}"

    secret_key_base = "${random_string.secret_key_base.result}"
    otp_secret = "${random_string.otp_secret.result}"
    postgres_password = "${random_string.postgres_password.result}"

    smtp_server = "${var.smtp_server}"
    smtp_port = "${var.smtp_port}"
    smtp_login = "${var.smtp_login}"
    smtp_password = "${var.smtp_password}"

    mastodon_domain = "${var.mastodon_domain}"
    letsencrypt_email = "${var.letsencrypt_email}"
  }
}

resource "local_file" "ansible_vars" {
  content = "${data.template_file.ansible_vars.rendered}"
  filename = "salt/pillar/terraform_vars.jinja"
}

resource "digitalocean_droplet" "mastodon" {
  name = "mastodon"
  image = "${var.droplet_image}"
  region = "${var.digital_ocean_region}"
  size = "${var.droplet_size}"
  ipv6 = true
  ssh_keys = [ "${digitalocean_ssh_key.terraform_key.id}" ]
  volume_ids = [ "${digitalocean_volume.do_volume.id}" ]

  connection {
    type = "ssh"
    user = "root"
    private_key = "${file("~/.ssh/id_rsa")}"
  }

  depends_on = ["local_file.ansible_vars"]

  provisioner "salt-masterless" {
    local_state_tree = "./salt"
    remote_state_tree = "/srv/salt"
    disable_sudo = true

    local_pillar_roots = "./salt/pillar"
    remote_pillar_roots = "/srv/pillar"
  }

  lifecycle {
    create_before_destroy = true
  }
}

output "droplet_ip" {
  value = {
    floating = "${digitalocean_floating_ip.ip.ip_address}"
    ipv4 = "${digitalocean_droplet.mastodon.ipv4_address}"
    ipv6 = "${digitalocean_droplet.mastodon.ipv6_address}"
  }

}
