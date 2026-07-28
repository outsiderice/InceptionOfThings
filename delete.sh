#!/bin/bash

VM_NAME="inception-of-things"
VIRSH_DEFAULT_CONNECT_URI="qemu:///session"
LIBVIRT_DEFAULT_URI="qemu:///session"

virsh destroy $VM_NAME
virsh undefine $VM_NAME --nvram --remove-all-storage
