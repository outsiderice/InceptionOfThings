#!/bin/bash

AMI_VARIANT="debian-13-genericcloud-amd64.qcow2"
AMI_URL="https://cloud.debian.org/images/cloud/trixie/latest/${AMI_VARIANT}"
AMI_PATH="${HOME:?}/goinfre/inception-of-things"
AMI_IMG="$AMI_PATH/$AMI_VARIANT"

VM_NAME="inception-of-things"
VM_RAM=4096
VM_VCPUS=4
VM_IMG="$AMI_PATH/$VM_NAME.qcow2"

VIRSH_DEFAULT_CONNECT_URI="qemu:///session"
LIBVIRT_DEFAULT_URI="qemu:///session"


# Download debian cloud-base image
#
if ! test -f $AMI_PATH/$AMI_VARIANT
then
	wget \
		--continue \
		--directory-prefix="$AMI_PATH" \
		"$AMI_URL" ;
fi

# Clone base image and set size (expand)
#
qemu-img \
	create \
	-f qcow2 \
	-F qcow2 \
	-b "$AMI_IMG" \
	"$VM_IMG" \
	16G ;

# Make sure a clouduser-key exists
#
if ! test -f .ssh/clouduser-key
then
	mkdir -p .ssh ;
	ssh-keygen -t ed25519 -N "" -q -C "" -f .ssh/clouduser-key ;
	# Proper should be: 
	# ssh-keygen -A -f clouduser-key
fi

# Generate user-data.yaml
#
cat << EOF > "$AMI_PATH/user-data.yaml"
#cloud-config
users:
  - name: $USER
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    lock_passwd: true
    ssh_authorized_keys:
      - $(cat .ssh/clouduser-key.pub)
EOF
cloud-init schema --config-file "$AMI_PATH/user-data.yaml" || exit 1 ;

# Generate meta-data.yaml
#
cat << EOF > "$AMI_PATH/meta-data.yaml"
local-hostname: $VM_NAME
EOF

# Provision and start the VM via virt-install
#
virt-install --name "$VM_NAME" \
  --ram "$VM_RAM" \
  --vcpus "$VM_VCPUS" \
  --disk path="$VM_IMG",bus=virtio \
  --cloud-init "user-data=$AMI_PATH/user-data.yaml,meta-data=$AMI_PATH/meta-data.yaml" \
  --os-variant debian13 \
  --boot uefi \
  --tpm none \
  --import \
  --graphics none \
  --noautoconsole ;

# NAT port forward
#
virsh \
	qemu-monitor-command $VM_NAME \
	--hmp \
	--cmd 'hostfwd_add ::2222-:22' ;
