#!/bin/bash

NAT_IP="$(ip -f inet addr show virbr0 | awk '/inet / {print $2}' | cut -d '/' -f 1)" ;
NAT_PORT="2222" ;

CLOUDUSER="$USER" ;
CLOUDUSER_SSH_KEY=".ssh/clouduser-key" ;

_ssh() {
	ssh \
		-i $CLOUDUSER_SSH_KEY \
		-p $NAT_PORT \
		-o StrictHostKeyChecking=no \
		-o UserKnownHostsFile=/dev/null \
		${CLOUDUSER}@${NAT_IP} ;
}

_console() {
	virsh \
		-c qemu:///session \
		console inception-of-things ; # $VM_NAME ;
}

## main

if test -n "$1"
then
	_console
else
	_ssh
fi
