
<h3>This set of scripts had successfully evolutioned into <a href="https://github.com/LuigiVampa92/SkyForge">SkyForge</a> - an Intellij Idea / Android Studio IDE plugin, that does everything this repo intended to do, but with much better UX, and through GUI approach. The plugin can be installed at Android Studio <kbd>Settings</kbd> -> <kbd>Plugins</kbd> -> type <kbd>SkyForge</kbd> into search bar and hit "Install" button. The source code and all the configuration and usage instructions are available at the link above.</h3>


# Therefore this repository had been deprecated and no longer used. Please use [SkyForge](https://github.com/LuigiVampa92/SkyForge) instead.

<br/>
<br/>
<br/>
<br/>
<br/>
<br/>
<br/>

# RemoteAndroidBuilds
A set of scripts that will help you move building process of your heavy android projects in Android Studio from a local computer to a remote server

I had made a post about it. You can read it [here](https://habr.com/ru/post/700744/)

# How to use it?

Download all files and put them into the root directory of your android project

The main configuration file is `remote_android_config.properties`, you should set all your values there.

In your android project root directory add exception line `remote_android_*` to `.gitignore` file, to make sure you will not push there scripts in git remote repository


## Local machine requirements:
I have prepared these scripts on MacOS, but they should also work on linux if you will not set `nexus.proxy.required=true`. No option for Windows for now, sorry

## Remote machine requirements:
These scripts are made to work on ubuntu. I used and tested them on ubuntu-20.04.5-server as a remote build machine. You can get a fresh VPS instance or create a new virtual box VM just for the test (if you create virtualbox vm, make sure to add correct port forwardings in virtual box settings and also manually set PermitRootLogin yes and PasswordAuthentication yes in /etc/ssh/sshd_config).

# Setup a fresh ubuntu server instance:
Make sure you have server's IP address, port (by default it is 22) and root password.

Open `remote_android_config.properties` and edit these two parameters according to your values: `server.ssh.ip`, `server.ssh.port`

Run sequentially:

`./remote_android_local_prepare.sh`  -  to generate new keypair and create ssh alias on a local machine
`./remote_android_server_prepare.sh`  -  to setup ssh server on a remote machine fast and secure. you will be prompted to enter root password twice - first to upload the setup script to a remote machine, second - to execute that script
`./remote_android_server_setup.sh`  -  to download and install all the necessary dependencies to run android builds

You're done. Now you can run:

`./remote_android_build_on.sh`  -  to enable remote build mode and make heavy builds on the remote server instead of local machine
`./remote_android_build_off.sh`  -  to disable remote build mode and return to normal local builds

# Setup an existing ubuntu server:

Open `remote_android_config.properties` and edit these parameters:

```
server.ssh.alias=android_builds_server
server.ssh.set.user.name=builder
server.ssh.set.user.password=builder
server.ssh.set.port=34567
server.ssh.set.key="~/.ssh/id_ed25519_android_builds_server"
```
Insert your values there, then run:

`./remote_android_server_setup.sh`  -  to download and install all the necessary dependencies to run android builds

You're done. Now you can run:

`./remote_android_build_on.sh`  -  to enable remote build mode and make heavy builds on the remote server instead of local machine
`./remote_android_build_off.sh`  -  to disable remote build mode and return to normal local builds
