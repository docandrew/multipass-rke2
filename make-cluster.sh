
# echo "Setting up bridge network enterprise0"
# sudo ip link add enterprise0 type bridge

# echo "Making enterprise network act as a span port (hub)"
# sudo brctl stp enterprise0 off
# sudo brctl setageing enterprise0 0
# sudo brctl setfd enterprise0 0

# echo "Making enterprise0 active"
# sudo ip link set enterprise0 up

# echo "Launching target nodes attached to enterprise network"
# multipass launch --name target0 --network name=enterprise0
# multipass launch --name target1 --network name=enterprise0
# echo "Setting addresses on enterprise network interfaces"
# multipass exec target0 -- bash -c "sudo ip addr add 192.168.1.100/24 dev enp6s0"
# multipass exec target1 -- bash -c "sudo ip addr add 192.168.1.101/24 dev enp6s0"

echo "Launching RKE2 server node"
multipass launch --name serv1 --cpus 6 --memory 8G --disk 30G --cloud-init ./cloud-config-server.yaml

echo "Launching RKE2 agent connected to enterprise network"
multipass launch --name node1 --cpus 6 --memory 8G --disk 30G --cloud-init ./cloud-config-agent.yaml --network name=enterprise0

echo "Renaming additional interface on agent to capture0"
multipass exec node1 -- bash -c "sudo ip link set enp6s0 down"
multipass exec node1 -- bash -c "sudo ip link set enp6s0 name capture0"
multipass exec node1 -- bash -c "sudo ip link set capture0 up"

echo "Fetching RKE2 registration token from server"
multipass exec serv1 -- bash -c "sudo cat /var/lib/rancher/rke2/server/node-token" > node-token

echo "Generating config.yaml for joining additional nodes"
cat > rke2config.yaml <<EOF
server: https://serv1:9345
token: $(cat node-token)
EOF

echo "Writing token to agent"
multipass transfer rke2config.yaml node1:rke2config.yaml
multipass exec node1 -- bash -c "sudo mv rke2config.yaml /etc/rancher/rke2/config.yaml"

echo "Starting RKE2 on agent"
multipass exec node1 -- bash -c "sudo systemctl start rke2-agent.service"

echo "Fetching RKE2 kubeconfig"
multipass exec serv1 -- bash -c "sudo cat /etc/rancher/rke2/rke2.yaml" > kubeconfig.yaml

echo "Modifying kubeconfig to use VM address"
SERV1IP=$(multipass info serv1 | grep IPv4 | awk '{print $2}')

sed -i "s/127.0.0.1/${SERV1IP}/g" kubeconfig.yaml

echo "Kubeconfig written to kubeconfig.yaml"
echo "-------------------------------------"
echo "Next Steps:"
echo "You can run 'export KUBECONFIG=$(pwd)/kubeconfig.yaml' to use this kubeconfig"
echo "directly from this host."
echo ""
echo "If you want to connect to this cluster from outside this host, you can do"
echo "an SSH tunnel and change the kubeconfig to use localhost instead of the VM IP"
echo ""
echo "Example (run this on the machine you are connecting from):"
echo "ssh -L 12345:${SERV1IP}:6443 ${USER}@${HOSTNAME}"
echo "Then change the server address in kubeconfig.yaml to:"
echo "..."
echo "server: https://localhost:12345"
echo "..."
