
## Multipass RKE2
Generates a virtualized network for running RKE2 on multipass
nodes with additional nodes that can be used for passive traffic
sniffing. This is a work in progress.

## Prerequisites

You'll need multipass and lxd. Your machine will need to be set up with
the correct boot options for virtualization. 

On Ubuntu:

```shell
sudo snap install lxd
sudo lxd init

# go through lxd setup for your system.

sudo snap install multipass
sudo snap connect multipass:lxd lxd
sudo multipass set local.driver=lxd
```

## Troubleshooting
Restarting the multipass daemon may help if there are issues.
```shell
sudo snap restart multipass.multipassd
```
