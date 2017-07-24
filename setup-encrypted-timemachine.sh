#!/usr/bin/env -i /bin/bash

# Compatibility for tools which don't set PATH correctly
PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH

# Variables
USER="NAS_USERNAME"
USERNAME="SYSTEM_USERNAME"
VOLPASSWORD="PASSWORD"
ENCRYPTIONPASSWORD="PASSWORD"
VOLUME_NAME="Timemachine"
NAS_IP="123.123.123.123"

HOSTNAME=`hostname -s`
IMAGENAME="$HOSTNAME.sparsebundle"
UUID=`/usr/sbin/system_profiler SPHardwareDataType | awk '/UUID/ { print $3; }'`
UUIDLOW=`echo $UUID|awk '{print tolower($0)}'`

echo "Hostname: $HOSTNAME"
echo "Device UUID: $UUID"

# Check if there is already a Timemachine Backup configured and remove it
#BACKUPID=`tmutil destinationinfo|grep ID|awk '{print $3}'`
#if [ ! -z "$BACKUPID" ]
#then
#    echo "There is already a backup configured, removing..."
#    tmutil removedestination $BACKUPID
#fi

# Mount timecapsule / NAS Volume
echo "Mount Backupdestination"
mkdir /Volumes/Timemachine
/sbin/mount -t afp afp://$USER:$VOLPASSWORD@$NAS_IP/$VOLUME_NAME /Volumes/$VOLUME_NAME/

# Check if mount worked
CHECK_MOUNT=`/sbin/mount |grep $VOLUME_NAME|awk '{print $3}'`
echo $CHECK_MOUNT
if [ -z $CHECK_MOUNT ]
then
  echo "Mount failed"
  exit 1
fi

# Check and remove old existing Sparsebundle
echo "Create Sparsebundle"
cd /tmp
if [ -d $IMAGENAME ]
then
  echo "Delete existing Image"
  rm -rf $IMAGENAME
fi

# create new Sparsebundle
echo -n "$ENCRYPTIONPASSWORD" |hdiutil create -size 300g -type SPARSEBUNDLE -encryption AES-256 -stdinpass -nospotlight -volname $HOSTNAME -fs "Case-sensitive Journaled HFS+" -verbose $HOSTNAME

# Write configuration with device uuid for timemachine
cat << EOF >$IMAGENAME/com.apple.TimeMachine.MachineID.plist
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
 "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>com.apple.backupd.HostUUID</key>
	<string>$UUID</string>
</dict>
</plist>
EOF

chown -R $USER:staff $IMAGENAME

# check if there is already an old existing Sparsebundle and remove it
#if [ -d /Volumes/$VOLUME_NAME/$IMAGENAME ]
#then
#  echo "Delete OLD Sparsebundle"
#  rm -rf /Volumes/$VOLUME_NAME/$IMAGENAME
#fi

# move new Sparsebundle to nas / timecapsule
echo "move Sparsebundle to timecapsule"
mv $IMAGENAME /Volumes/$VOLUME_NAME

# Get disk UUID from sparsebundle
DISKUUID=`hdiutil isencrypted -plist /Volumes/Timemachine/${IMAGENAME} 2>&1 | grep 'uuid' -1|grep string|awk 'BEGIN {FS=">"} {print $2}'|awk 'BEGIN {FS="<"} {print $1}'`
echo "Disk UUID: $DISKUUID"

# resize Sparsebundle if needed
#echo -n "$ENCRYPTIONPASSWORD" |hdiutil resize -stdinpass -size 300g /Volumes/Timemachine/$HOSTNAME.sparsebundle

echo "umount timecapsule"
/sbin/umount /Volumes/$VOLUME_NAME
sleep 3
CHECK_MOUNT=`mount|grep $VOLUME_NAME|awk '{print $3}'`
if [ -z $CHECK_MOUNT ] && [ -d /Volumes/$VOLUME_NAME ]
then
  echo "Delete old Mountpoint (Cleanup)"
  rm -rfv /Volumes/$VOLUME_NAME
fi

# Add destination for timemachine
echo "Set Destitnation for Timemachine"
tmutil setdestination afp://$USER:$VOLPASSWORD@$NAS_IP/$VOLUME_NAME

NEWBACKUPID=`tmutil destinationinfo|grep ID|awk '{print $3}'`

# Add Passwords for sparsebundle to keychain
/usr/bin/sudo -i -u $USERNAME /usr/bin/security add-generic-password -U -a "localdevice$UUID-AuthToken" -s "com.apple.ids" -l "com.apple.ids: localdevice$UUIDLOW-AuthToken" -A -w "$ENCRYPTIONPASSWORD"
/usr/bin/security add-generic-password -a "$DISKUUID" -s "$UUID.sparsebundle" -D "disk image password" -A -w "$ENCRYPTIONPASSWORD" /Library/Keychains/System.keychain
/usr/bin/security add-generic-password -a "$DISKUUID" -s "$UUID.sparsebundle" -D "Image-Passwort" -A -w "$ENCRYPTIONPASSWORD" /Library/Keychains/System.keychain
/usr/bin/security add-generic-password -U -a "$DISKUUID" -s "$IMAGENAME" -A -w "$ENCRYPTIONPASSWORD" /Library/Keychains/System.keychain
/usr/bin/security add-generic-password -a $NEWBACKUPID -s "Time Machine" -A -w $ENCRYPTIONPASSWORD /Library/Keychains/System.keychain

# activate backup
echo "activating Backup"
tmutil enable

# start backup
echo "Start Backup"
tmutil startbackup

