<!-- markdown-toc start - Don't edit this section. Run M-x markdown-toc-refresh-toc -->
**Table of Contents**

- [Mastodon on Digital Ocean](#mastodon-on-digital-ocean)
    - [Prerequisities](#prerequisities)
        - [Terraform](#terraform)
        - [Get a Digital Ocean account](#get-a-digital-ocean-account)
        - [Get an SMTP account](#get-an-smtp-account)
        - [A domain](#a-domain)
        - [SSH Keys](#ssh-keys)
    - [Deployment](#deployment)
    - [Maintenance](#maintenance)
        - [Replacing the droplet.](#replacing-the-droplet)
        - [Running with a Salt Master](#running-with-a-salt-master)

<!-- markdown-toc end -->
# Mastodon on Digital Ocean

A budget Mastodon installation that still strives to be productionised and fault-tolerant.

## Prerequisities

### Terraform

You'll need [terraform installed][tf].

[tf]: https://www.terraform.io/intro/getting-started/install.html

### Get a Digital Ocean account

Sign up for a [Digital Ocean][do] account.
Create a [personal access token][token]

[do]: https://cloud.digitalocean.com/registrations/new
[token]: https://cloud.digitalocean.com/account/api/tokens

### Get an SMTP account

I used [Mailgun][mailgun], but any provider will work.
You'll need the server, port, login, and password.

### A domain

You'll need a domain with DNS you control.

### SSH Keys

There needs to be a private key, unencrypted, at `~/.ssh/id_rsa` and a corresponding public key at `~/.ssh/id_rsa.pub`

## Deployment

1. install all required Terraform modules:

```shell
terraform init terraform/
```

2. Fill out your details into `terraform.tfvars` in the root of the repository:

```
digital_ocean_token = "< digital ocean token>"
mastodon_domain = "mycool.example"
letsencrypt_email = "<your email address, needed by letsencrypt>"
smtp_login = "<smtp login>"
smtp_password = "<smtp password>"
```


3. Then, create a terraform plan to create the floating IP:

```shell
terraform plan -target digitalocean_floating_ip.ip -out tf.plan terraform/
```

4. If everything looks good, go ahead and and execute the plan:

```shell
terraform apply tf.plan
```

5. That should give you a stable IP address.
create an A record on your domain pointing to that IP.

6. Let terraform plan out the rest of the infrastrucutre:

```
terraform plan -out tf.plan terraform/
```

7. Apply the changes:

```
terraform apply tf.plan
```

8. Wait 5-10 minutes for all the infrastructure to come up. Don't let your computer go to sleep.

## Maintenance

### Replacing the droplet.

Updating the salt files won't trigger a replacemet on its own.
Instead, you can taint the droplet to trigger a replace:

```
terraform taint digitalocean_droplet.mastodon terraform/
```

Then plan and apply infrastructure changes as usual.

### Running with a Salt Master

The script provinions the Droplet to work with masterless saltstack, but it can also use a local master.

1. [Set up a master][master] locally.

[master]: https://docs.saltstack.com/en/latest/ref/configuration/master.html

2. SSH into the droplet:

```shell
ssh -R 4505:localhost:4505 -R 4506:localhost:4506 Eroot@<floating ip>
```

the -R commands open remote ports to the local machine, so the droplet doesn't need to access

3. On the droplet, edit `/etc/salt/minion` to point at at the localhost for master:

```yaml
# Set the location of the salt master server. If the master server cannot be
# resolved, then the minion will fail to start.
master: localhost
```

4. Restart the salt minion daemon:

```shell
systemctl restart salt-minion
```

5. On the local host, accept the minion's key:

```
salt-key -a mastodon
```

6. Edit `/etc/salt/master` to point at the appropriate directories:

```yaml
pillar_roots:
  base:
    - /home/<user>/do_mastodon/salt/pillar

file_roots:
  base:
    - /home/<user>/do_mastodon/salt
```

7. Apply the salt state:

```shell
salt mastodon state.apply
```

You can do this as much as you want, to update the Mastodon instance without the downtime incurred by destroy-and-replace.
