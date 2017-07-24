# Setup encrypted Timemachine Backup through CLI

This bash script activates encrypted Timemachine backups on MacOS to automate the rollout process with any tool you prefer. Currently it is not easily possible to setup encrypted Timemachine backups through CLI. The tool tmutil only supports unencrypted backups.

The script `setup-encrypted-timemachine.sh` helps you to create an encrypted Sparsebundle, copy it to your NAS Storage. It also tells your Timemachine the destination and add the passwords in the System Keychain which is used by Timemachine.

In this default setup it  uses the AFP (Apple Filetransfer Protocol) for it. It is possible to use the script with Timecapsules or Netatalk fileshares. If you activate unsupported Network Volumes it should also be possible to use it with Samba Shares. The command to activate unsupported Network Shares is:
```
sudo defaults write com.apple.systempreferences TMShowUnsupportedNetworkVolumes 1
```

## Requirements

The script need to be run as root. Otherwise it doesn't work.

## Installation

Before you start you need to change the following variables to your credentials:
```bash
# Variables
USER="NAS_USERNAME"
USERNAME="SYSTEM_USERNAME"
VOLPASSWORD="PASSWORD"
ENCRYPTIONPASSWORD="PASSWORD"
VOLUME_NAME="Timemachine"
NAS_IP="123.123.123.123"
 ```

If it is needed to remove the old Timemachine destination, please uncomment (remove `#`) these lines
```bash
# Check if there is already a Timemachine Backup configured and remove it
#BACKUPID=`tmutil destinationinfo|grep ID|awk '{print $3}'`
#if [ ! -z "$BACKUPID" ]
#then
#    echo "There is already a backup configured, removing..."
#    tmutil removedestination $BACKUPID
#fi
```

If you need to check and delete old Sparsebundles on NAS and local you need to uncomment (remove `#`) the following lines
```bash
# check if there is already an old existing Sparsebundle and remove it
#if [ -d /Volumes/$VOLUME_NAME/$IMAGENAME ]
#then
#  echo "Delete OLD Sparsebundle"
#  rm -rf /Volumes/$VOLUME_NAME/$IMAGENAME
#fi
```

If you need to use unsupported network shares, it is also needed to customize the mount options in line 33. 

After customization the script should work and you can run it with
```bash
sudo /path/to/setup-encrypted-timemachine.sh
```

## Known issues

The GUI doesn't show correctly, that the backup is encrypted. Sometimes it works sometimes not and seem to be related to the "disk image password" in the keychain. I didn't find any solution for it. As a workaround you can check with the hdiutil command if the Sparsebundle is encrypted correctly:
```
hdiutil isencrypted -plist /Volumes/Timemachine/$HOSTNAME.sparsebundle
```

## Contribute

Please feel free to open pull requests. Any ideas for improvements are welcome.

## License

Apache 2.0
