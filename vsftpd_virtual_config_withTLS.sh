#!/bin/sh
# Chroot FTP with Virtual Users - Installation (with TLS support)
#
# Version 1.0
#       August 1, 2005
#       Fire Eater <LinuxRockz@gmail.com>
#
# Version 1.1
#       December 14, 2008
#       Alain Reguera Delgado <alain.reguera@gmail.com>
#
# Released under the GPL License- http://www.fsf.org/licensing/licenses/gpl.txt

#
# Initialization
#
IP_Address="`( /sbin/ifconfig | head -2 | tail -1 | awk '{ print $2; }' | tr --delete [a-z]:)`"
LOCALPATH=`pwd`

#
# Add some presentation :)
#
clear;
echo " vsftpd 2.0.5 -> Virtual Users -> Configuration"
echo '-------------------------------------------------------------------'

#
# Check dependencies
#
PACKISMISSING=""
PACKDEPENDENCIES="vsftpd db4-utils"
for i in `echo $PACKDEPENDENCIES`; do
    /bin/rpm -q $i > /dev/null
    if [ "$?" != "0" ];then
        PACKISMISSING="$PACKISMISSING $i"
    fi
done
if [ "$PACKISMISSING" != "" ];then
    echo " ATTENTION: The following package(s) are needed by this script:"
    for i in `echo $PACKISMISSING`; do
        echo "             - $i"
    done
    echo '-------------------------------------------------------------------'
    exit;
fi

#
# Move into pki and create vsftpd certificate.
#
echo ''
echo ' Creating Vsftpd RSA certificate ...'
echo ''

cd /etc/pki/tls/certs/
if [ -f vsftpd.pem ];then
	rm vsftpd.pem
fi
make vsftpd.pem

#
# Set up vsftpd configuration
#
echo '' 
printf ' Setting up Vsftpd with non-system user logins and TLS support ... '

mv  /etc/vsftpd/vsftpd.conf /etc/vsftpd/vsftpd.conf.orig
cat <<EOFVSFTPD> /etc/vsftpd/vsftpd.conf
anon_world_readable_only=NO
anonymous_enable=NO
chroot_local_user=YES
guest_enable=NO
guest_username=ftp
hide_ids=YES
listen=YES
listen_address=$IP_Address
local_enable=YES
max_clients=100
max_per_ip=2
nopriv_user=ftp
pam_service_name=ftp
pasv_max_port=65535
pasv_min_port=64000
session_support=NO
use_localtime=YES
user_config_dir=/etc/vsftpd/users
userlist_enable=YES
userlist_file=/etc/vsftpd/denied_users
xferlog_enable=YES
anon_umask=027
local_umask=027
async_abor_enable=YES
connect_from_port_20=YES
dirlist_enable=NO
download_enable=NO
#
# TLS Configuration
#
ssl_enable=YES
allow_anon_ssl=NO
force_local_data_ssl=NO
force_local_logins_ssl=YES
ssl_tlsv1=YES
ssl_sslv2=NO
ssl_sslv3=NO
rsa_cert_file=/etc/pki/tls/certs/vsftpd.pem
EOFVSFTPD

#
# Users
#
if [ ! -d /etc/vsftpd/users ]; then
mkdir /etc/vsftpd/users
fi
cat /etc/passwd | cut -d ":" -f 1 | sort > /etc/vsftpd/denied_users; 
chmod 644 /etc/vsftpd/denied_users
printf "Done.\n"

#
# PAM
#
printf ' Setting up PAM ... '
cat <<EOFPAMFTP> /etc/pam.d/ftp
auth    required pam_userdb.so db=/etc/vsftpd/accounts
account required pam_userdb.so db=/etc/vsftpd/accounts
EOFPAMFTP
printf "Done.\n"

#
# SELinux
#
printf ' Setting up SELinux Boolean (allow_ftpd_anon_write 1) ... '
/usr/sbin/setsebool -P allow_ftpd_anon_write 1
printf "Done.\n"

#
# Add first ftp virtual user
#
${LOCALPATH}/vsftpd_virtualuser_add.sh
