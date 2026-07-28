#!/bin/bash

VM_NAME="inception-of-things"
RAM=4096
VCPUS=4
ISO_VARIANT="debian-13-genericcloud-amd64.qcow2"
ISO_URL="https://cloud.debian.org/images/cloud/trixie/latest/${ISO_VARIANT}"
ISO_PATH="${HOME:?}/goinfre"
BASE_IMG="$ISO_PATH/$ISO_VARIANT"
VM_IMG="$ISO_PATH/$VM_NAME.qcow2"
CONFIG_ISO="$ISO_PATH/${VM_NAME}-cidata.iso"

VIRSH_DEFAULT_CONNECT_URI="qemu:///session"
LIBVIRT_DEFAULT_URI="qemu:///session"

# Check cloud-localds is installed
if ! command -v cloud-localds
then
	printf "%s: %s\n" "$0" "Missing cloud-localds command." >&2
fi

# Download debian cloud-base image
if ! test -f $ISO_PATH/$ISO_VARIANT
then
	wget \
		--continue \
		--directory-prefix="$ISO_PATH" \
		"$ISO_URL"
fi

# Clone base image and set size (expand)
qemu-img create -f qcow2 -F qcow2 -b "$BASE_IMG" "$VM_IMG" 16G

# Generate the cloud-init ISO drive
cloud-localds "$CONFIG_ISO" user-data meta-data

# Provision and start the VM via virt-install
virt-install --name "$VM_NAME" \
  --ram "$RAM" \
  --vcpus "$VCPUS" \
  --disk path="$VM_IMG",bus=virtio \
  --disk path="$CONFIG_ISO",device=cdrom \
  --os-variant debian13 \
  --boot uefi \
  --tpm none \
  --import \
  --graphics none \
  --noautoconsole
  # --console pty,target_type=serial
  # --network network=default,model=virtio

virsh \
	qemu-monitor-command $VM_NAME \
	--hmp \
	--cmd 'hostfwd_add ::2222-:22'
