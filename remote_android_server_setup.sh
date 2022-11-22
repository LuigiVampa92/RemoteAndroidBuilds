#!/bin/bash

# --- REMOTE ANDROID BUILDS ---
#
# This script prepares remote host for building android projects, ensures you have all environment values, tools and dependencies:
# - JDK
# - Android SDK commandline-tools
# - Android SDK Manager
# - Platform of target version for your project, platform-tools, buildTools etc
#
# USE this script when you have a configured ssh access to a remote host but haven't yet installed the dependencies to perform android builds
#
# This script should be called AFTER you have prepared a remote host and system user for android builds and inserted the values in [ remote_android_config.preperties ]
# OR AFTER you executed [ remote_android_server_prepare.sh ] that does all of this for you if you have a fresh VPS with root access
#
# This script should be called BEFORE [ remote_android_build_on.sh ] that turns on building android project on remote host
#
# You MUST RERUN this script every time you add new sdkmanager dependencies for your android project (like different platform version or build-tools version)

TMP_FILE=remote_android_file.tmp
TARGET_FILE=remote_android_server_setup.config
REMOTE_TARGET_FILE=remote_android_server_setup.sh
ANDROID_SDK_DEPENDENCIES="\"`cat remote_android_config.properties | grep "server.sdk.dependencies=" | cut -d'=' -f2 | sed 's/\"//g' | sed -e 's/|/" "/g'`\""
if [ -z "$ANDROID_SDK_DEPENDENCIES" ]; then
  echo 'Error: mandatory parameter [server.sdk.dependencies] is not set'
  exit 1
fi
SERVER_SSH_ALIAS=`cat remote_android_config.properties | grep "server.ssh.alias=" | cut -d'=' -f2 | sed 's/\"//g'`
if [ -z $SERVER_SSH_ALIAS ]; then
  echo 'Error: mandatory parameter [server.ssh.alias] is not set'
  exit 1
fi
REMOTE_USER_PASSWORD=`cat remote_android_config.properties | grep "server.ssh.set.user.password=" | cut -d'=' -f2 | sed 's/\"//g'`
if [ -z $REMOTE_USER_PASSWORD ]; then
  echo 'Error: mandatory parameter [server.ssh.set.user.password] is not set'
  exit 1
fi
sed "s/^.*declare -a ANDROID_SDK_DEPENDENCIES=.*$/declare -a ANDROID_SDK_DEPENDENCIES=($ANDROID_SDK_DEPENDENCIES)/" $TARGET_FILE > $TMP_FILE
rm $TARGET_FILE
mv $TMP_FILE $TARGET_FILE
scp -o "StrictHostKeyChecking=no" ./$TARGET_FILE $SERVER_SSH_ALIAS:~/$REMOTE_TARGET_FILE ; ssh $SERVER_SSH_ALIAS "chmod +x ~/$REMOTE_TARGET_FILE" ; echo $REMOTE_USER_PASSWORD | ssh -tt $SERVER_SSH_ALIAS "bash ~/$REMOTE_TARGET_FILE"
