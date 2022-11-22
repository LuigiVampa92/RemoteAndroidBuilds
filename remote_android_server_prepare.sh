#!/bin/bash

# --- REMOTE ANDROID BUILDS ---
#
# This script sets up remote host that you have root access to:
# - creates dedicated user in system for android builds
# - sets up /etc/ssh/sshd_config for user access only with a public key
#
# USE this script if you have a root ssh access to some host (for instance - a VPS and its credentials you just obtained)
# DO NOT USE this script if you have set all the values manually in remote_android_config.properties or had setup ssh user access already
#
# This script should be called AFTER [ remote_android_local_prepare.sh ] that creates ssh keys and ssh config for future connections
# This script should be called BEFORE [ remote_android_server_setup.sh ] that prepares the environment and dependencies for android builds
#
# You should execute this script only once for a remote host instance
# Once this script has been executed the root ssh access to a remote host will be closed and you will have to use a keypair for it
#
# During an execution you will be prompted twice to enter root password of the remote host:
# - to transfer setup script
# - to execute setup script

SSH_ROOT_IP=`cat remote_android_config.properties | grep "server.ssh.ip=" | cut -d'=' -f2 | sed 's/\"//g'`
if [ -z $SSH_ROOT_IP ]; then
  echo 'Error: mandatory parameter [server.ssh.ip] is not set'
  exit 1
fi

SSH_ROOT_PORT=`cat remote_android_config.properties | grep "server.ssh.port=" | cut -d'=' -f2 | sed 's/\"//g'`
if [ -z $SSH_ROOT_PORT ]; then
  echo 'Error: mandatory parameter [server.ssh.port] is not set'
  exit 1
fi

SET_REMOTE_USER=`cat remote_android_config.properties | grep "server.ssh.set.user.name=" | cut -d'=' -f2 | sed 's/\"//g'`
if [ -z $SET_REMOTE_USER ]; then
  echo 'Error: mandatory parameter [server.ssh.set.user.name] is not set'
  exit 1
fi

SET_REMOTE_PASSWORD=`cat remote_android_config.properties | grep "server.ssh.set.user.password=" | cut -d'=' -f2 | sed 's/\"//g'`
if [ -z $SET_REMOTE_PASSWORD ]; then
  echo 'Error: mandatory parameter [server.ssh.set.user.password] is not set'
  exit 1
fi

SET_SSH_PORT=`cat remote_android_config.properties | grep "server.ssh.set.port=" | cut -d'=' -f2 | sed 's/\"//g'`
if [ -z $SET_SSH_PORT ]; then
  echo 'Error: mandatory parameter [server.ssh.set.port] is not set'
  exit 1
fi

SET_SSH_IDENTITY_FILE=`cat remote_android_config.properties | grep "server.ssh.set.key=" | cut -d'=' -f2 | sed 's/\"//g'`
if [ -z $SET_SSH_IDENTITY_FILE ]; then
  echo 'Error: mandatory parameter [server.ssh.set.key] is not set'
  exit 1
fi

DIR_USER=`realpath ~`
FULL_PATH_TO_PRIVATE_KEY=`echo "$SET_SSH_IDENTITY_FILE" | sed "s+~+$DIR_USER+g"`
FULL_PATH_TO_PUBLIC_KEY=`echo "$SET_SSH_IDENTITY_FILE.pub" | sed "s+~+$DIR_USER+g"`
if [[ ! -f $FULL_PATH_TO_PRIVATE_KEY || ! -f $FULL_PATH_TO_PUBLIC_KEY ]]; then
  echo "Error: ssh key file is not found"
  exit 1
fi
SET_SSH_PUBLIC_KEY=`cat $FULL_PATH_TO_PUBLIC_KEY`

TMP_FILE=remote_android_file.tmp
TARGET_FILE=remote_android_server_prepare.config
REMOTE_TARGET_FILE=remote_android_server_prepare.sh

sed "s/^.*SSH_SET_USER_NAME=.*$/SSH_SET_USER_NAME=\"$SET_REMOTE_USER\"/" $TARGET_FILE > $TMP_FILE
rm $TARGET_FILE
mv $TMP_FILE $TARGET_FILE
sed "s/^.*SSH_SET_USER_PASSWORD=.*$/SSH_SET_USER_PASSWORD=\"$SET_REMOTE_PASSWORD\"/" $TARGET_FILE > $TMP_FILE
rm $TARGET_FILE
mv $TMP_FILE $TARGET_FILE
sed "s/^.*SSH_SET_PORT=.*$/SSH_SET_PORT=\"$SET_SSH_PORT\"/" $TARGET_FILE > $TMP_FILE
rm $TARGET_FILE
mv $TMP_FILE $TARGET_FILE
sed "s~^.*SSH_SET_PUBLIC_KEY=.*$~SSH_SET_PUBLIC_KEY=\"$SET_SSH_PUBLIC_KEY\"~" $TARGET_FILE > $TMP_FILE
rm $TARGET_FILE
mv $TMP_FILE $TARGET_FILE

echo "Enter root password to transfer initial setup script to remote host:"
scp -o "StrictHostKeyChecking=no" -P $SSH_ROOT_PORT ./$TARGET_FILE root@$SSH_ROOT_IP:~/$REMOTE_TARGET_FILE
echo "Enter root password to perform initial setup on remote host:"
ssh -o "StrictHostKeyChecking=no" -tt -p $SSH_ROOT_PORT root@$SSH_ROOT_IP "bash ~/$REMOTE_TARGET_FILE"