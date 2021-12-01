# tf-oci-arm

Oracle Cloud has a generous Always-Free tier that includes
a 4 CPU, 24 GB RAM, 200 GB disk, arm64 vm.

Network limits are very very very generous.

Oracle Cloud also has managed terraform (called Stacks).

## this repo

This terraform + cloud-init project creates an Ampere VM with a public IP
that is fully firewalled on a [tailscale](https://tailscale.com) network.

The OS image is Ubuntu 20.04.

The cloud-init:
- Clears the default Oracle iptables (fine for development + iSCSI is no longer the default)
- Configures ufw to firewall all internet traffic
- Bootstraps Tailscale
- Configures SSH using your GitHub public keys (fetched from your username)
- Installs Docker

Unfortunately, while NAT gateways are Free, they are not available on Free accounts
that do not have a payment method, so I left out the private IP config.

## pre-reqs

- Oracle Cloud Account
- Tailscale Account
- GitHub Account /w SSH Keys configured

You don't need terraform installed locally, but you could do that.
We can use terraform from the Oracle Cloud UI.

## deploy

Clone the repo (or fork it):
```bash
git clone git@github.com:stealthybox/tf-oci-arm
cd tf-oci-arm
```

Create a secrets file (it's ignored in git)
```bash
cp secret.auto.tfvars.example secret.auto.tfvars
```

Update the secret values:
1. Update your `github_user` in the `secret.auto.tfvars` file
2. Create a Compartment for `tf-oci-arm`: https://cloud.oracle.com/identity/compartments  
   Copy the OCID of your new compartment  
   Update the config  
3. Create a Tailscale Auth Key: https://login.tailscale.com/admin/settings/authkeys  
   Copy the key  
   Update the config  

Now, create a Stack in Oracle Cloud: https://cloud.oracle.com/resourcemanager/stacks  
Upload your folder or zip it up first.  
(I have to use a zip personally, because WSL2 browser uploads are limited)

Copy your Compartment OCID into the field again.

Ack your values in the form.

Apply the Stack!

Hopefully it succeeds for you!  
It should if you made no changes to the cloud-init and your values are correct.

You should be able to `ssh oracle-arm` now from any machine with your private keys on your tailnet.

## sudo

Once you're SSH'd in congrats. You can access any port of oracle-arm over your tailnet IP.

You won't have sudo access though because your user doesn't have a password yet.  
You can load your passwordhash through cloud-init or setup, NOPASSWD sudo.  
For now, I've settled on abusing the docker group to get a root shell to call `passwd` when I setup my other stuff like my tools and shell config:
```bash
docker run -it --rm --pid host --privileged justincormack/nsenter1

passwd $(id -nu 1000)
exit

whoami
sudo whoami
```

## remote docker

Want to `docker run` arm64 containers remotely from your laptop?
Try out running NGINX or something:
```bash
GITHUB_USER=octocat

docker context create oracle-arm --docker "host=ssh://${GITHUB_USER}@oracle-arm"

DOCKER_CONTEXT=oracle-arm docker run --name nginx -d --rm -p 80:80 nginx

curl oracle-arm

DOCKER_CONTEXT=oracle-arm docker stop nginx
```
That's a private connection :)

## debugging

Very quickly after the terraform Stack succeeds, you should be able to SSH into your VM over tailscale.
If not, that's sad, and there's something wrong with your firewall config, or more likely, your tailscale key.
Maybe try minting a new tailscale key.

Alternatively, disable `ufw` in the cloud-init, re-create the VM, and SSH in via the public IP, so you can
try to deduce what's going wrong.

Maybe this is an area where using Oracle's managed firewall rules might make debugging easier since you could just
disable them from the UI.

## gotchas

If your Oracle Cloud Account is brand-new, you'll get free trial credits and
unlimited access to all API's for 30 days.
After that 30 days, if you don't add a billing method, your VM will be deleted
automatically, and you will lose your files.

You can re-create your VM with your new downgraded Free Account, and it will then
persist forever.

If you want to side-step this 30-day ticking time-bomb, you could probably just
add a credit card. Maybe you could even then remove it, but I can't test that theory.
I'm not sure if there's another way to invalidate the 30-day free credits other than
waiting.

I left the default shell as zsh, sorry.
Maybe you like this? Fork and delete if you like :)

## resources

This person's entire web log is lovely and they explain the iptables thing:
https://www.cflee.com/posts/oci-first-look-2/

Tailscale has some docs on using the Oracle Cloud firewall /w tailscale if you don't
want to use Ubuntu's `ufw`:
https://tailscale.com/kb/1149/cloud-oracle/

This article details some of the service limits:
https://virtualizationreview.com/articles/2021/09/14/using-oracle-cloud.aspx
