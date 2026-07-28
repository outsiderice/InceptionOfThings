#!/bin/bash

NAT_IP="$(ip -f inet addr show virbr0 | awk '/inet / {print $2}' | cut -d '/' -f 1)"
ssh -i $HOME/.ssh/intra_id_rsa -p 2222 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null debian@${NAT_IP}
