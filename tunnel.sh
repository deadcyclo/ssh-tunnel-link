#!/bin/bash
set -e

TUNNEL_REGEXP="^\s*SSH_TUNNEL_([_A-Z]+)_([0-9]+)=([0-9]+):([^:]+):(.+)\s*$"
SSH_IDENTITY_FILE="${SSH_IDENTITY_FILE:-/keys/id_rsa}"
SSH_SERVER_KEEPALIVE_INTERVAL=${SSH_SERVER_KEEPALIVE_INTERVAL:-30}
SSH_PORT=${SSH_PORT:-2222}

# Ensure that autossh does not fail even if initial connection fails
export AUTOSSH_GATETIME=0

ssh_tunnel() {
    tunnel_name=$1
    local_port=$2
    remote_port=$3
    local_host=$4
    remote_host=$5

    sshtcommand="/usr/local/bin/autossh -M 0 -T -N"

    if [ "${SSH_DEBUG_LEVEL}" = "1" ]; then
	sshtcommand="${sshtcommand} -v"
    fi
    if [ "${SSH_DEBUG_LEVEL}" = "2" ]; then
	sshtcommand="${sshtcommand} -v -v"
    fi
    if [ "${SSH_DEBUG_LEVEL}" = "3" ]; then
	sshtcommand="${sshtcommand} -v -v -v"
    fi

     sshtcommand="${sshtcommand} -o StrictHostKeyChecking=no"
     sshtcommand="${sshtcommand} -o UserKnownHostsFile=/dev/null"
     sshtcommand="${sshtcommand} -o ServerAliveInterval=${SSH_SERVER_KEEPALIVE_INTERVAL}"
     sshtcommand="${sshtcommand} -o Port=${SSH_PORT}"
     sshtcommand="${sshtcommand} -o User=root"
     sshtcommand="${sshtcommand} -o PasswordAuthentication=no"
     sshtcommand="${sshtcommand} -o IdentityFile=\"${SSH_IDENTITY_FILE}\""
     sshtcommand="${sshtcommand} -L 0.0.0.0:${local_port}:${local_host}:${remote_port} ${remote_host}"
     echo "Creating tunnel ${tunnel_name} :${local_port} -> ${local_host}:${remote_port} ${remote_host}:${SSH_PORT}"
     if ${sshtcommand};then
	 echo "${tunnel_name} successful"
     else
	 echo "${tunnel_name} exited with code $?" >&2
     fi
}
     
pids=()

while IFS=$'\t' read -r tunnel_name local_port remote_port local_host remote_host ; do
    ssh_tunnel ${tunnel_name} ${local_port} ${remote_port} ${local_host} ${remote_host}
    pids+=($!)
done < <(env | grep -E "${TUNNEL_REGEXP}" | sed -E "s/^${TUNNEL_REGEXP}/\1\t\2\t\3\t\4\t\5/")

killprocs() {
    for pid in "${pids[@]}"; do
	echo "Killing tunnel proc $pid"
	kill $pid 2>/dev/null
    done
}

trap 'killprocs' EXIT

# Wait on processes and kill them all if any exited
while true; do
    for pid in "${pids[@]}"; do
	if ! kill -0 ${pid} 2>/dev/null; then
	    echo "Tunnel process ${pid} not running... exiting"
	    exit 1;
	fi
    done
    sleep 1
done
