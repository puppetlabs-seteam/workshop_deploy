#! /bin/bash
# call this script with 3 arguments: <amount of targets> <AWS region> <AWS user>
# example:
# sh ./scripts/generate_boltws_targets_inventory.sh 15 eu-west-3 kevin

if [ $# -eq 0 ]; then
  echo "No arguments supplied, must supply a count"
  exit 1
fi

[ -n $1 ] && [ $1 -eq $1 ] 2>/dev/null
if [ $? -ne 0 ]; then
  echo The supplied count is not a number
  exit 1
fi

export AWS_REGION=$2
export FACTER_aws_region=$2
export FACTER_user=$3

echo 
echo "Sleeping for 10 seconds..."
sleep 10

echo 
echo "Building Bolt inventory file at ~/inventory.yaml..."

echo "groups:
  - name: linux
    nodes:" > ~/inventory.yaml 

for i in $(seq 1 $1); do
  puppet resource ec2_instance "$3-awskit-boltws-linux-student$i" | grep public_ip_address | echo "      - $(awk '{split($0,a,"'\''"); print a[2]}')" >> ~/inventory.yaml
done

echo "    config:
      transport: ssh
      ssh:
        user: centos
        run-as: root
        private-key: ~/bolt_ws_key.pem
        host-key-check: false
  - name: windows
    nodes:" >> ~/inventory.yaml

for i in $(seq 1 $1); do
  puppet resource ec2_instance "$3-awskit-boltws-windows-student$i" | grep public_ip_address | echo "      - $(awk '{split($0,a,"'\''"); print a[2]}')" >> ~/inventory.yaml
done

echo "    config:
      transport: winrm
      winrm:
        user: Administrator
        password: BoltR0cks!
        ssl: false" >> ~/inventory.yaml

exit 0