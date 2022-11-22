#!/bin/bash

# --- REMOTE ANDROID BUILDS ---
#
# This script sets up local ssh configurations required to make remote android builds:
# - creates a new ed25519 keypair that will be used to access remote android builds server
# - creates a new .ssh/config record that will allow to connect to remote android builds server by alias
#
# USE this script if you haven't yet created ssh keypair dedicated to access remote android builds server
#
# This script should be called VERY FIRST, BEFORE [ remote_android_server_prepare.sh ] that sets up ssh configs on remote host
#
# You should execute this script only once on your local machine, if everything had been setup already, these steps will just be skipped

SET_SSH_IDENTITY_FILE=`cat remote_android_config.properties | grep "server.ssh.set.key=" | cut -d'=' -f2 | sed 's/\"//g'`
if [ -z $SET_SSH_IDENTITY_FILE ]; then
  echo 'Error: mandatory parameter [server.ssh.set.key] is not set'
  exit 1
fi
SERVER_SSH_ALIAS=`cat remote_android_config.properties | grep "server.ssh.alias=" | cut -d'=' -f2 | sed 's/\"//g'`
if [ -z $SERVER_SSH_ALIAS ]; then
  echo 'Error: mandatory parameter [server.ssh.alias] is not set'
  exit 1
fi
SERVER_SSH_IP=`cat remote_android_config.properties | grep "server.ssh.ip=" | cut -d'=' -f2 | sed 's/\"//g'`
if [ -z $SERVER_SSH_IP ]; then
  echo 'Error: mandatory parameter [server.ssh.ip] is not set'
  exit 1
fi
SERVER_SSH_ROOT_PORT=`cat remote_android_config.properties | grep "server.ssh.port=" | cut -d'=' -f2 | sed 's/\"//g'`
if [ -z $SERVER_SSH_ROOT_PORT ]; then
  echo 'Error: mandatory parameter [server.ssh.port] is not set'
  exit 1
fi
SERVER_SSH_PORT=`cat remote_android_config.properties | grep "server.ssh.set.port=" | cut -d'=' -f2 | sed 's/\"//g'`
if [ -z $SERVER_SSH_PORT ]; then
  echo 'Error: mandatory parameter [server.ssh.set.port] is not set'
  exit 1
fi
SET_REMOTE_USER=`cat remote_android_config.properties | grep "server.ssh.set.user.name=" | cut -d'=' -f2 | sed 's/\"//g'`
if [ -z $SET_REMOTE_USER ]; then
  echo 'Error: mandatory parameter [server.ssh.set.user.name] is not set'
  exit 1
fi

DIR_USER=`realpath ~`
DIR_SSH="$DIR_USER/.ssh"
FILE_SSH_CONFIG="$DIR_SSH/config"
FILE_SSH_KNOWN_HOSTS="$DIR_SSH/known_hosts"
if [ ! -d $DIR_SSH ]; then
  mkdir -p $DIR_SSH
  chmod 700 $DIR_SSH
fi
if [ ! -f $FILE_SSH_CONFIG ]; then
  touch $FILE_SSH_CONFIG
  chmod 644 $FILE_SSH_CONFIG
fi
if [ ! -f $FILE_SSH_KNOWN_HOSTS ]; then
  touch $FILE_SSH_KNOWN_HOSTS
  chmod 644 $FILE_SSH_KNOWN_HOSTS
fi

TMP_FILE=remote_android_file.tmp
TARGET_FILE=$FILE_SSH_CONFIG

FULL_PATH_TO_PRIVATE_KEY=`echo "$SET_SSH_IDENTITY_FILE" | sed "s+~+$DIR_USER+g"`
FULL_PATH_TO_PUBLIC_KEY=`echo "$SET_SSH_IDENTITY_FILE.pub" | sed "s+~+$DIR_USER+g"`

SSH_CONFIG_PATTERN_OPEN="##### REMOTE ANDROID BUILDS - $SERVER_SSH_ALIAS - START #####"
SSH_CONFIG_PATTERN_CLOSE="##### REMOTE ANDROID BUILDS - $SERVER_SSH_ALIAS - END #####"

if [[ ! -f $FULL_PATH_TO_PRIVATE_KEY || ! -f $FULL_PATH_TO_PUBLIC_KEY ]]; then
  rm $FULL_PATH_TO_PRIVATE_KEY 2>/dev/null
  rm $FULL_PATH_TO_PUBLIC_KEY 2>/dev/null

  echo "SSH keys are not found. Create new keys now."
  ssh-keygen -o -t ed25519 -f $FULL_PATH_TO_PRIVATE_KEY -C "key_for_android_build_server" -P ""

  sed -n -e "/$SSH_CONFIG_PATTERN_OPEN/{" -e 'p' -e ':a' -e 'N' -e "/$SSH_CONFIG_PATTERN_CLOSE/!ba" -e 's/.*\n//' -e '}' -e 'p' $TARGET_FILE > $TMP_FILE
  rm $TARGET_FILE ; mv $TMP_FILE $TARGET_FILE
  sed "s/$SSH_CONFIG_PATTERN_OPEN//g" $TARGET_FILE > $TMP_FILE
  rm $TARGET_FILE ; mv $TMP_FILE $TARGET_FILE
  sed "s/$SSH_CONFIG_PATTERN_CLOSE//g" $TARGET_FILE > $TMP_FILE
  rm $TARGET_FILE ; mv $TMP_FILE $TARGET_FILE

else
  echo "SSH keys already created."
fi

KNOWN_HOSTS_VALUE_FOR_CURRENT="$SERVER_SSH_IP"
if `cat $FILE_SSH_KNOWN_HOSTS | grep "$KNOWN_HOSTS_VALUE_FOR_CURRENT" 1>/dev/null`; then
  echo "Clear previous known host public key value for host"
  sed "s/^.*$KNOWN_HOSTS_VALUE_FOR_CURRENT.*$//" $FILE_SSH_KNOWN_HOSTS > $TMP_FILE
  rm $FILE_SSH_KNOWN_HOSTS ; mv $TMP_FILE $FILE_SSH_KNOWN_HOSTS
else
  echo "No previous known host public key value found"
fi

if `cat $TARGET_FILE | grep "$SSH_CONFIG_PATTERN_OPEN" 1>/dev/null`; then
  echo "SSH configs already set up"
else
  echo "No SSH configs set. Adding new record to $TARGET_FILE now"
  echo " " >> $TARGET_FILE
  echo " " >> $TARGET_FILE
  echo $SSH_CONFIG_PATTERN_OPEN >> $TARGET_FILE
  echo " " >> $TARGET_FILE
  echo "Host $SERVER_SSH_ALIAS" >> $TARGET_FILE
  echo "HostName $SERVER_SSH_IP" >> $TARGET_FILE
  echo "Port $SERVER_SSH_PORT" >> $TARGET_FILE
  echo "User $SET_REMOTE_USER" >> $TARGET_FILE
  echo "IdentityFile $SET_SSH_IDENTITY_FILE" >> $TARGET_FILE
  echo "IdentitiesOnly yes" >> $TARGET_FILE
  echo "Compression yes" >> $TARGET_FILE
  echo " " >> $TARGET_FILE
  echo $SSH_CONFIG_PATTERN_CLOSE >> $TARGET_FILE
  echo " " >> $TARGET_FILE
fi
