# Vi's Sysupdate Components

Sysupdate components for apps that are not yet available as a flatpak.

# What?

Components are sysexts that update independently from your base system, they are mostly static (they do not depend on a specific base system). </br>
SELinux is not supported, all other x64 glibc OS with systemd >=259.9 are supported. </br>
Made for elementaryOS and GnomeOS

# Download a components

Switch to a root shell
```
run0
```

Download the sysupdate configuration file
```
APP=nordvpn # app name here, ex: nordvpn
mkdir -p /etc/sysupdate.$APP.d
curl -L -o /etc/sysupdate.$APP.d/$APP.transfer \
  https://github.com/jumpyvi/components/releases/latest/download/$APP.transfer
```

Download the component

```
# Check if it is detected correctly
systemd-sysupdate components

# Download
systemd-sysupdate --component={APP_NAME} update

# Refresh
systemd-sysext refresh
```

# Enable auto-updates
> Update will be done weekly by default
```
GIT_REPO=https://raw.githubusercontent.com/jumpyvi/components/refs/heads/master/systemd
sudo curl -fsSL -o /etc/systemd/system/sysupdate-components.service $GIT_REPO/sysupdate-components.service
sudo curl -fsSL -o /etc/systemd/system/sysupdate-components.timer $GIT_REPO/sysupdate-components.timer
sudo systemctl daemon-reload
sudo systemctl enable --now sysupdate-components.timer
```

# App list

## NordVPN

> https://github.com/NordSecurity/nordvpn-linux

`nordvpn`

Extracted from the official debian "trixie" builds. </br>

Requires a sysusers+tmpfiles refresh, adding yourself to the `nordvpn` user group and enabling `nordvpnd` </br>
Does not support login in with the GUI or interactive browser callback, login with a token from the cli (`nordvpn login --token=xxx`) </br>
Login in from the cli, will log you in the gui too.

Includes:
- NordVPN CLI
- NordVPN systemd daemon
- NordVPN GUI


## VSCode

> https://code.visualstudio.com/

`vscode`

Extracted from the official tar.gz, with fixed setuid. </br>
Includes .desktop and .svg that the tar doesn't provide.


## XPpen

> https://www.xp-pen.com/download/deco-mini7w-v2.html

`xppen`

Requires a tmpfiles refresh

Extracted from the tar.gz on the website. </br>

Should work on most xppen tablets (only deco mini 7 is tested) </br>

Manually updated, open a PR if out of date
