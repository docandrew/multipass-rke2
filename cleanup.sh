echo "Deleting VMs"
multipass delete serv1 node1 target0 target1

echo "Deleting bridge network enterprise0"
sudo ip link delete enterprise0

echo "Removing created files"
rm -f kubeconfig.yaml
rm -f node-token
rm -f rke2config.yaml
