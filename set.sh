#!/bin/bash

VM_NAME="inception-of-things"
RAM=4096
VCPUS=4
ISO_VARIANT="debian-13-genericcloud-amd64.qcow2"
ISO_URL="https://cloud.debian.org/images/cloud/trixie/latest/${ISO_VARIANT}"
ISO_PATH="${HOME:?}/goinfre"
BASE_IMG="$ISO_PATH/$ISO_VARIANT"
VM_IMG="$ISO_PATH/$VM_NAME.qcow2"

VIRSH_DEFAULT_CONNECT_URI="qemu:///session"
LIBVIRT_DEFAULT_URI="qemu:///session"


# Script start

## Download debian cloud-base image
if ! test -f $ISO_PATH/$ISO_VARIANT
then
	wget \
		--continue \
		--directory-prefix="$ISO_PATH" \
		"$ISO_URL" ;
fi

## Clone base image and set size (expand)
qemu-img create -f qcow2 -F qcow2 -b "$BASE_IMG" "$VM_IMG" 16G ;

## Provision and start the VM via virt-install
virt-install --name "$VM_NAME" \
  --ram "$RAM" \
  --vcpus "$VCPUS" \
  --disk path="$VM_IMG",bus=virtio \
  --cloud-init "user-data=cloud-init/user-data,meta-data=cloud-init/meta-data" \
  --os-variant debian13 \
  --boot uefi \
  --tpm none \
  --import \
  --graphics none \
  --noautoconsole ;

## NAT port forward
virsh \
	qemu-monitor-command $VM_NAME \
	--hmp \
	--cmd 'hostfwd_add ::2222-:22' ;
