#

######
# CONFIG
ROOTPWD="1234"
USERNAME="cubie"
USERPASS="1234"

###########################
#Main Section
###########################
if [[ $EUID -ne 0 ]]; then
   echo "You must be a root user" 2>&1
   exit 1
fi

useradd -m -U -d /home/$USERNAME -s /bin/bash $USERNAME
# set User password to 1234
(echo $USERPASS;echo $USERPASS;) | passwd $USERNAME
# Do NOT force password change upon first login as it will prevent autologin :(

adduser $USERNAME sudo

DEST_LANG="en_US"
DEST_LANGUAGE="en"
echo -e $DEST_LANG'.UTF-8 UTF-8\n' >> /etc/locale.gen
echo -e 'fr_FR.UTF-8 UTF-8\n' >> /etc/locale.gen
echo -e 'LANG="'$DEST_LANG'.UTF-8"\nLANGUAGE="'$DEST_LANG':'$DEST_LANGUAGE'"\n' > /etc/default/locale
dpkg-reconfigure -f noninteractive locales
update-locale

# Setup apt-sources
sourcesFile="/etc/apt/sources.list"
rm $sourcesFile
touch $sourcesFile
#Get all info running : sudo netselect-apt -a armhf -n -s -c fr jessie
# Or : sudo netselect-apt -a armhf -n -s -c fr wheezy
#Edit output file to add wheezy updates and uncomment security + backports
#Jessie
echo "# Debian packages for Jessie" >> $sourcesFile
echo "deb http://debian.mirrors.ovh.net/debian/ jessie main contrib non-free" >> $sourcesFile
echo "deb http://debian.mirrors.ovh.net/debian/ jessie-updates main contrib non-free" >> $sourcesFile
echo "#Security updates for stable" >> $sourcesFile
echo "deb http://security.debian.org/ stable/updates main contrib non-free" >> $sourcesFile
echo "deb http://ftp.debian.org/debian/ jessie-backports main contrib non-free" >> $sourcesFile
# Wheezy
echo "# Debian packages for wheezy" >> $sourcesFile                                                                                            
echo "deb http://debian.mirrors.ovh.net/debian/ wheezy main contrib non-free" >> $sourcesFile
echo "deb http://debian.mirrors.ovh.net/debian/ wheezy-updates main contrib non-free" >> $sourcesFile
echo "#Security updates for stable" >> $sourcesFile
echo "deb http://security.debian.org/ stable/updates main contrib non-free" >> $sourcesFile
echo "deb http://ftp.debian.org/debian/ wheezy-backports main contrib non-free" >> $sourcesFile


apt-get update


#Change Timezones
echo "Europe/Paris" > /etc/timezone
dpkg-reconfigure -f noninteractive tzdata

#UnusedTo configure keyboard :
#apt-get install console-data

# Install packages
#Put all packages here :)
INSTPKG="hdparm hddtemp console-setup console-data netselect-apt"
INSTPKG+=" bash-completion parted cpufrequtils unzip mosh"
INSTPKG+=" vim tmux htop sudo locate tree ncdu toilet figlet git mosh"
INSTPKG+=" xorg ttf-mscorefonts-installer openbox xterm xinit obconf xscreensaver xscreensaver-gl menu obmenu"
INSTPKG+=" lightdm iceweasel x11vnc"
echo $INSTPKG
apt-get -y upgrade
export DEBIAN_FRONTEND=noninteractive; apt-get -y install $INSTPKG

#For wheezy only 
export DEBIAN_FRONTEND=noninteractive; apt-get -y install -t wheezy-backports $INSTPKG

#Disable Sshd root login
#sed -e "s/PermitRootLogin no/PermitRootLogin yes/g" -i /etc/ssh/sshd_config

# Overclock - DANGER
#sudo sed -i "s/echo -n 1100000/echo -n 1008000/g" /etc/init.d/cpufrequtils

# Install RAMLOG - No ramlog in Jessie
#dpkg -i /tmp/ramlog_2.0.0_all.deb
#if ! grep -q "TMPFS_RAMFS_SIZE=256m" /etc/default/ramlog; then
#    sed -e 's/TMPFS_RAMFS_SIZE=/TMPFS_RAMFS_SIZE=256m/g' -i /etc/default/ramlog
#    sed -e 's/# Required-Start:    $remote_fs $time/# Required-Start:    $remote_fs $time ramlog/g' -i /etc/init.d/rsyslog
#    sed -e 's/# Required-Stop:     umountnfs $time/# Required-Stop:     umountnfs $time ramlog/g' -i /etc/init.d/rsyslog
#fi
#rm /tmp/ramlog_2.0.0_all.deb
#insserv

# Cleanup APT
apt-get -y clean

# set root password to 1234
(echo $ROOTPWD;echo $ROOTPWD;) | passwd root
# force password change upon first login
chage -d 0 root


#Configure Xserver autostart
dpkg-reconfigure keyboard-configuration
adduser $USERNAME video
if ! grep -q $USERNAME /etc/lightdm/lightdm.conf; then
    sed -i "s/#autologin-user=/autologin-user=$USERNAME/g" /etc/lightdm/lightdm.conf
    sed -i "s/#autologin-user-timeout=0/autologin-user-timeout=0/g" /etc/lightdm/lightdm.conf
fi

#To enable connexion using crontab on DISPLAY :0.0
sed -i "s/xserver-allow-tcp=false/xserver-allow-tcp=true/g" /etc/lightdm/lightdm.conf

mkdir -p /home/$USERNAME/.config/openbox
echo "xhost +localhost &" > /home/$USERNAME/.config/openbox/autostart
echo "setxkbmap fr &" >> /home/$USERNAME/.config/openbox/autostart
echo "xterm -e '/sbin/ifconfig eth0 && read a' &" >> /home/$USERNAME/.config/openbox/autostart
echo "xset -dpms &" >> /home/$USERNAME/.config/openbox/autostart                                                                                                                                   
echo "xset s noblank;xset s 0 0;xset s off" >> /home/$USERNAME/.config/openbox/autostart

chown -R $USERNAME:$USERNAME /home/$USERNAME/.config/openbox/autostart
chmod 755 /home/$USERNAME/.config/openbox/autostart



#Setup tmpfs for firefox profiles - All profiles will be in RAMDISK
mkdir -p /home/$USERNAME/.mozilla/firefox/
chown -R $USERNAME:$USERNAME /home/cubie/.mozilla/firefox

mkdir -p /media/ramdrive
if ! grep -q ramdrive /etc/fstab
then
   echo "adding line to fstab"
   echo 'ramdrive /media/ramdrive tmpfs size=225M,user,auto,exec,rw 0 0' | tee -a /etc/fstab
   mount -a
fi


#Screensaver & Screen blanking stuff
#export DISPLAY=":0.0"
#xset -dpms
xset s noblank;xset s 0 0;xset s off
#xset + dpms
#A inverser pour les xset s
#xset s activate
#xset s reset
#xset dpms force on off suspend standby

#For Cubie2 Jessie
#Config
export DISPLAY=":0.0"
xhost +localhost &
xset s off
xset -dpms
#Turn Off
xset dpms force off
#Turn On
reboot 


#For rpi2 (some commands need root others don't)
#https://www.freshrelevance.com/blog/server-monitoring-with-a-raspberry-pi-and-graphite
#config
export DISPLAY=":0.0"
xhost +localhost &
xset s off
xset -dpms
#Turn off 
tvservice --off > /dev/null
#Turn on
tvservice --preferred > /dev/null
fbset -depth 8; fbset -depth 16; xrefresh
