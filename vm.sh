#!/bin/bash

PROJECT_NAME="inception-of-things"
PROJECT_DIR="${HOME:?}/goinfre/${PROJECT_NAME:?}"

VM_NAME="${PROJECT_NAME:?}"
VM_IMG="$PROJECT_DIR/$VM_NAME.qcow2"

# APT_CACHE_IMG="$PROJECT_DIR/apt-cache.qcow2"
SSH_DIR="$PWD/.ssh"

export VIRSH_DEFAULT_CONNECT_URI="qemu:///session"
export LIBVIRT_DEFAULT_URI="qemu:///session"

vm__get_ami() {
	# Download Automated Machine Image (AMI) if missing.
	local AMI_URL="https://cloud-images.ubuntu.com/resolute/current/resolute-server-cloudimg-amd64.img";
	local AMI_VARIANT="$(basename $AMI_URL)";
	local AMI_PATH="${PROJECT_DIR:?}";
	local AMI_IMG="$AMI_PATH/$AMI_VARIANT";
	
	if ! test -f "$AMI_PATH/$AMI_VARIANT"; then
		wget \
			--continue \
			--directory-prefix="$AMI_PATH" \
			"$AMI_URL"
	fi
	printf "%s" "$AMI_IMG";
}

vm__keyname() {
	# Generate base64 string.
	local KEYNAME=$(printf "%s--%s" "${1:?}" "${2:?}" | basenc --base64);
	
	printf "%s" "$KEYNAME";
}

vm__keygen() {
	# Generate ssh key.
	local DOMAIN=${1:-"$VM_NAME"};
	local USER=${2:-"$USER"};
	local KEY="${SSH_DIR:?}/$(vm__keyname $DOMAIN $USER)";
	
	if ! test -d "$(dirname $KEY)"; then
		mkdir -p "$(dirname $KEY)"
	fi
	if ! test -f "$KEY"; then
		ssh-keygen -t ed25519 -N "" -q -C "" -f "$KEY"
	fi
}

vm__cloudinit() {
	# Generate user-data and meta-data.
	local DOMAIN=${1:-"$VM_NAME"};
	local USER=${2:-"$USER"};
	local KEY="${SSH_DIR:?}/$(vm__keyname $DOMAIN $USER)";

# user-data.yaml
cat <<EOF > "${PROJECT_DIR}/user-data.yaml"
#cloud-config
users:
  - name: ${USER}
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    lock_passwd: true
    ssh_authorized_keys:
      - $(cat "${KEY}.pub")
  - name: ${USER}dev
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    lock_passwd: false
    plain_text_passwd: ${USER}
ssh:
  emit_keys_to_console: false
apt:
  conf: |
    APT::Install-Recommends "false";
    APT::Install-Suggests "false";
package_update: true
package_upgrade: true
packages:
- tree
- iptables
- dnsmasq
- bridge-utils
- qemu-system-x86
- qemu-utils
- libvirt-daemon-system
- libvirt-clients
- vagrant
- vagrant-libvirt
- nfs-kernel-server
allow_public_ssh_keys: true
disable_root: true
disable_root_opts: no-port-forwarding,no-agent-forwarding,no-X11-forwarding
ssh_deletekeys: true
ssh_quiet_keygen: true
runcmd:
  - usermod -aG libvirt,kvm ${USER}
  - systemctl disable --now dnsmasq
  - systemctl restart libvirt
final_message: Wubba Lubba dub-dub!
EOF

# meta-data.yaml
cat <<EOF > "${PROJECT_DIR}/meta-data.yaml"
local-hostname: ${VM_NAME}
EOF

}

vm__hostfwd() {
	# NAT port forward.
	local DOMAIN=${1:-"$VM_NAME"};
	local NAT_PORT="${2:-"2222"}";
	local GUEST_PORT="${3:-"22"}";
	
	virsh qemu-monitor-command $DOMAIN \
		--hmp \
		--cmd "hostfwd_add ::${NAT_PORT}-:${GUEST_PORT}";
}

vm__clone_ami() {
	local AMI="${1:-"$(vm__get_ami)"}";
	local DEST="${2:?}"
	local SIZE="${3:?}";

	qemu-img create -f qcow2 -F qcow2 -b "$AMI" "$DEST" "$SIZE";
}

vm_create() {
	# Get AMI, provision, configure and start the VM via virt-install.
	local DOMAIN=${1:-"$VM_NAME"};
	local VM_VCPUS="4";
	local VM_RAM="4096";
	
	vm__clone_ami "$(vm__get_ami)" "$VM_IMG" "16G";
	vm__keygen "$DOMAIN";
	vm__cloudinit;
	virt-install \
		--name "$VM_NAME" \
		--memory "$VM_RAM" \
		--vcpus "$VM_VCPUS" \
		--cpu "host-passthrough,cache.mode=passthrough" \
		--disk "path=$VM_IMG,bus=virtio,cache=none,io=native,discard=unmap" \
		--cloud-init "user-data=$PROJECT_DIR/user-data.yaml,meta-data=$PROJECT_DIR/meta-data.yaml" \
		--osinfo "ubuntu-lts-latest" \
		--boot "uefi" \
		--tpm "none" \
		--import \
		--graphics "none" \
		--noautoconsole;
	vm__hostfwd "$VM_NAME" "2222" "22";
}

vm_delete() {
	local DOMAIN=${1:-"$VM_NAME"};

	if test $(virsh list --all --name | grep -e $DOMAIN | wc -l) -ne 0; then
		virsh destroy $DOMAIN
		virsh undefine $DOMAIN --nvram
	fi
	if test -f "$VM_IMG"; then
		rm -v "$VM_IMG"
	fi
}

vm_ssh() {
	local DOMAIN=${1:-"$VM_NAME"};
	local USER=${2:-"$USER"};
	local KEY="${SSH_DIR:?}/$(vm__keyname $DOMAIN $USER)";
	local NAT_IP="$(virsh net-dumpxml default | sed -nE "s/.*<ip address='([^']+)'.*/\1/p")";
	local NAT_PORT="2222";

	ssh -i "$KEY" -p ${NAT_PORT:-"22"} \
		-o StrictHostKeyChecking=no \
		-o UserKnownHostsFile=/dev/null \
		${USER}@${NAT_IP:-"localhost"};
}

vm_console() {
	local DOMAIN=${1:-"$VM_NAME"};

	virsh console $DOMAIN;
}

vm_usage() {
	printf "Usage: %s [OPTIONS]... [VM_NAME]\n" "$0" >&2
	printf "COMMANDS:\n" >&2
	printf "  %s: %s\n" "create" "..." >&2
	printf "  %s: %s\n" "ssh" "..." >&2
	printf "  %s: %s\n" "console" "..." >&2
	printf "  %s: %s\n" "delete" "..." >&2
}

#### main

if test ${DEBUG:-"0"} != "0"; then
	set -x;
fi

if test $# -eq 0; then
	vm_usage;
	exit 1;
fi

case "$1" in
	'create')
		shift
		vm_create;
		;;
	'delete')
		shift
		vm_delete;
		;;
	'ssh')
		shift
		vm_ssh;
		;;
	'console')
		shift
		vm_console;
		;;
	'help'|''|'*')
		vm_usage;
		exit 1;
		;;
esac
