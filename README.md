# Jumpy Components

Sysupdate components for apps that are not yet available as a flatpak.

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
systemd-sysupdate --component=nordvpn update

# Refresh
systemd-sysext refresh
```


# App list

## NordVPN


## VSCode