#!/bin/bash

# --- REMOTE ANDROID BUILDS ---
#
# This script TURNS OFF remote android builds for your project and make them be executed locally again
#
# You MUST explicitly call this script when you done working

NEXUS_PROXY_REQUIRED=`cat remote_android_config.properties | grep "nexus.proxy.required=" | cut -d'=' -f2 | sed 's/\"//g'`
NEXUS_PROXY_PORT=`cat remote_android_config.properties | grep "nexus.proxy.port=" | cut -d'=' -f2 | sed 's/\"//g'`

rm ~/.gradle/init.d/mirakle.gradle 2>/dev/null

if [[ $NEXUS_PROXY_REQUIRED == true ]]; then
  kill $(ps -ef | grep -v grep | grep $NEXUS_PROXY_PORT:localhost:$NEXUS_PROXY_PORT | awk '{print $2}') 2>/dev/null
  brew services stop nginx 1>/dev/null
fi

echo "Remote build disabled"
