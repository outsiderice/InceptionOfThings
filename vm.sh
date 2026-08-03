#!/bin/bash

# source config.sh

AMI_VARIANT="debian-13-genericcloud-amd64.qcow2"
AMI_URL="https://cloud.debian.org/images/cloud/trixie/latest/${AMI_VARIANT}"
AMI_PATH="${HOME:?}/goinfre/inception-of-things"
AMI_IMG="$AMI_PATH/$AMI_VARIANT"

VIRSH_DEFAULT_CONNECT_URI="qemu:///session"
LIBVIRT_DEFAULT_URI="qemu:///session"

VM_NAME="inception-of-things"
VM_RAM="4096"
VM_VCPUS="4"
VM_IMG="$AMI_PATH/$VM_NAME.qcow2"

SSH_DIR="$PWD/.ssh"

CLOUDUSER="$USER" ;
CLOUDUSER_SSH_KEY="$SSH_DIR/clouduser-key" ;
CLOUDUSER_KEY="clouduser-key"

vm_get_ami() {
	# Download debian cloud-init based Automated Machine Image (AMI)
	if ! test -f "$AMI_PATH/$AMI_VARIANT"; then
		wget \
			--continue \
			--directory-prefix="$AMI_PATH" \
			"$AMI_URL"
	fi
}

vm_generate_ssh() {
	# Make sure a "$1" ssh-key exists.
	# Argument is mandatory.
	local KEYNAME="${1:+$CLOUDUSER_KEY}"
	if ! test -d "$SSH_DIR"; then
		mkdir -p "$SSH_DIR"
	fi
	if ! test -f "$SSH_DIR/$KEYNAME"; then
		ssh-keygen -t ed25519 -N "" -q -C "" -f "$SSH_DIR/$KEYNAME"
		# Should be: 
		# ssh-keygen -A -f "$CLOUDUSER_KEY"
	fi
}



vm_generate_user_data() {
	# Generate user-data.yaml
	cat <<EOF > "$AMI_PATH/user-data.yaml"
#cloud-config
users:
  - name: $USER
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    lock_passwd: true
    ssh_authorized_keys:
      - $(cat .ssh/clouduser-key.pub)
ssh:
  emit_keys_to_console: false
package_update: true
package_upgrade: true
packages:
- tree
- vagrant
allow_public_ssh_keys: true
disable_root: true
disable_root_opts: no-port-forwarding,no-agent-forwarding,no-X11-forwarding
ssh_deletekeys: true
ssh_quiet_keygen: true
timezone: $(timedatectl show | grep -i timezone | cut -d '=' -f 2)
final_message: Wubba Lubba dub-dub!
EOF
cloud-init schema --config-file "$AMI_PATH/user-data.yaml" || exit 1
}

vm_generate_meta_data() {
	# Generate meta-data.yaml
	cat <<EOF > "$AMI_PATH/meta-data.yaml"
local-hostname: $VM_NAME
EOF
}

vm_install() {
	# Provision and start the VM via virt-install
	virt-install \
		--name "$VM_NAME" \
		--ram "$VM_RAM" \
		--vcpus "$VM_VCPUS" \
		--disk "path=$VM_IMG,bus=virtio" \
		--cloud-init "user-data=$AMI_PATH/user-data.yaml,meta-data=$AMI_PATH/meta-data.yaml" \
		--osinfo debian13 # TODO: no hardcoded value #--osinfo "detect=on,require=off" \
		--boot uefi \
		--tpm none \
		--import \
		--graphics none \
		--noautoconsole;
	# NAT port forward
	virsh \
		qemu-monitor-command $VM_NAME \
		--hmp \
		--cmd 'hostfwd_add ::2222-:22';
}

vm_launch() {
		vm_get_ami;
		vm_generate_ssh;
		vm_generate_user_data;
		vm_generate_meta_data;
		qemu-img create -f qcow2 -F qcow2 -b "$AMI_IMG" "$VM_IMG" 16G;
		vm_install;
}

vm_login() {
	NAT_IP="$(ip -f inet addr show virbr0 | awk '/inet / {print $2}' | cut -d '/' -f 1)" ;
	NAT_PORT="2222" ;

	case "$TYPE" in
		console)
			virsh console $VM_NAME
		;;
		ssh | *)
			ssh -i $CLOUDUSER_SSH_KEY -p $NAT_PORT \
			-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
			${CLOUDUSER}@${NAT_IP}
		;;
	esac
}

vm_delete() {
	virsh destroy $VM_NAME
	virsh undefine $VM_NAME --nvram --remove-all-storage
}


#### main

if [ $? -ne 0 ]; then
	echo 'Terminating...' >&2
	exit 1
fi

# Usage: ./vm.sh COMMAND...
# Commands are:
#  launch
#  login
#  delete

COMMAND="$1"
case "$COMMAND" in
	--launch) vm_launch ;;
	--login) vm_login ;;
	# --login [ssh | console]
	--delete) vm_delete "$VM_NAME" ;;
	# --delete [--force]
	*) vm_launch ;;
	# *) Default to:
	#		1) check if machine exists and is running
	#		if false -> launch.
	#		if true -> login
esac
