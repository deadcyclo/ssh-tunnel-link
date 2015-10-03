#!/bin/bash
set -e

SSH_HOST_KEY_FILE="${SSH_HOST_KEY_FILE:-/keys/host.pem}"
SSH_AUTHORIZED_KEY_FILE="${SSH_AUTHORIZED_KEY_FILE:-/keys/id_rsa.pub}"

if ! [ -f "${SSH_HOST_KEY_FILE}" ]; then
    mkdir -p "`dirname ${SSH_HOST_KEY_FILE}`"
    ssh-keygen -t rsa -b 4096 -f "${SSH_HOST_KEY_FILE}" -N '' -C ''
fi

sshdcommand="/usr/sbin/sshd -D"

if [ "${SSH_DEBUG_LEVEL}" = "1" ]; then
    sshdcommand="${sshdcommand} -d -e"
fi
if [ "${SSH_DEBUG_LEVEL}" = "2" ]; then
    sshdcommand="${sshdcommand} -d -d -e"
fi
if [ "${SSH_DEBUG_LEVEL}" = "3" ]; then
    sshdcommand="${sshdcommand} -d -d -d -e"
fi

sshdcommand="${sshdcommand} -f /etc/ssh/sshd_config"
sshdcommand="${sshdcommand} -h ${SSH_HOST_KEY_FILE}"
sshdcommand="${sshdcommand} -o AllowUsers=root"
sshdcommand="${sshdcommand} -o AuthorizedKeysFile=${SSH_AUTHORIZED_KEY_FILE}"
sshdcommand="${sshdcommand} -o ChallengeResponseAuthentication=no"
sshdcommand="${sshdcommand} -p 2222"

${sshdcommand}
