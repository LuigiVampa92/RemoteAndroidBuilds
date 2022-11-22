#!/bin/bash

# --- REMOTE ANDROID BUILDS ---
#
# This script TURNS ON remote android builds for your project and make them be executed on a remote server instead of local machine
#
# BEFORE using this script you should completely prepare a remote host for building android projects
# it can be done manually or with [ remote_android_server_setup.sh ] script
#
# You MUST explicitly call [ remote_android_build.off ] when you done working

ROOT_PROJECT_NAME=`pwd | grep -o '[^/]*$'`

SERVER_SSH_ALIAS=`cat remote_android_config.properties | grep "server.ssh.alias=" | cut -d'=' -f2 | sed 's/\"//g'`
if [ -z $SERVER_SSH_ALIAS ]; then
  echo 'Error: mandatory parameter [server.ssh.alias] is not set'
  exit 1
fi
REMOTE_USER=`cat remote_android_config.properties | grep "server.ssh.set.user.name=" | cut -d'=' -f2 | sed 's/\"//g'`
if [ -z $REMOTE_USER ]; then
  echo 'Error: mandatory parameter [server.ssh.set.user.name] is not set'
  exit 1
fi
NEXUS_PROXY_REQUIRED=`cat remote_android_config.properties | grep "nexus.proxy.required=" | cut -d'=' -f2 | sed 's/\"//g'`
if [ -z $NEXUS_PROXY_REQUIRED ]; then
  echo 'Error: mandatory parameter [nexus.proxy.required] is not set'
  exit 1
fi
NEXUS_PROXY_PORT=`cat remote_android_config.properties | grep "nexus.proxy.port=" | cut -d'=' -f2 | sed 's/\"//g'`
if [ -z $NEXUS_PROXY_PORT ]; then
  echo 'Error: mandatory parameter [nexus.proxy.port] is not set'
  exit 1
fi

ssh -q -o BatchMode=yes -o ConnectTimeout=5 $SERVER_SSH_ALIAS exit
if [ $? != "0" ]; then
    echo "Error: no connection to the server"
    exit 1
fi

ssh $SERVER_SSH_ALIAS "mkdir -p .mirakle/$ROOT_PROJECT_NAME ; echo sdk.dir=/home/$REMOTE_USER/Android/Sdk > /home/$REMOTE_USER/.mirakle/$ROOT_PROJECT_NAME/local.properties"

if [[ $NEXUS_PROXY_REQUIRED == true ]]; then
  brew services start nginx 1>/dev/null
  kill $(ps -ef | grep -v grep | grep $NEXUS_PROXY_PORT:localhost:$NEXUS_PROXY_PORT | awk '{print $2}') 2>/dev/null
  sleep 2
  ssh -f -N $SERVER_SSH_ALIAS -R $NEXUS_PROXY_PORT:localhost:$NEXUS_PROXY_PORT 2>/dev/null
fi

mkdir -p ~/.gradle/init.d
rm ~/.gradle/init.d/mirakle.gradle 2>/dev/null
cat <<EOF >> ~/.gradle/init.d/mirakle.gradle

def projectToBuildRemotely = "$ROOT_PROJECT_NAME"

initscript {
    repositories {
        mavenCentral()
    }
    dependencies {
        classpath 'io.github.adambl4:mirakle:1.6.0'
    }
}

apply plugin: Mirakle

rootProject {
    if (projectToBuildRemotely.equals(name)) {
        project.logger.lifecycle('Remote builds mode activated for this project. Going to start remote build now.')
        mirakle {
            host '$SERVER_SSH_ALIAS'
            remoteFolder ".mirakle"
            excludeCommon += ["*.DS_Store"]
            excludeCommon += ["*.hprof"]
            excludeCommon += [".idea"]
            excludeCommon += [".gradle"]
            excludeCommon += ["**/.git/"]
            excludeCommon += ["**/.gitignore"]
            excludeCommon += ["**/local.properties"]
            excludeCommon += ["**/backup_*.gradle"]
            excludeCommon += ["remote_android_*.sh"]
            excludeCommon += ["remote_android_*.properties"]
            excludeCommon += ["remote_android_*.config"]
            excludeLocal += ["**/build/"]
            excludeLocal += ["*.keystore"]
            excludeLocal += ["*.apk"]
            excludeRemote += ["**/src/"]
            excludeRemote += ["**/build/.transforms/**"]
            excludeRemote += ["**/build/kotlin/**"]
            excludeRemote += ["**/build/intermediates/**"]
            excludeRemote += ["**/build/tmp/**"]
            rsyncToRemoteArgs += ["-avAXEWSlHh"]
            rsyncToRemoteArgs += ["--info=progress2"]
            rsyncToRemoteArgs += ["--compress-level=9"]
            rsyncFromRemoteArgs += ["-avAXEWSlHh"]
            rsyncFromRemoteArgs += ["--info=progress2"]
            rsyncFromRemoteArgs += ["--compress-level=9"]
            fallback false
            downloadInParallel false
            downloadInterval 3000
            breakOnTasks = ["install", "package"]
        }
    } else {
        project.logger.lifecycle("Remote builds mode activated but for different project. Stop now.")
    }
}
EOF

echo "Remote build enabled"
