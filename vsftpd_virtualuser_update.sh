#!/bin/sh
# Chroot FTP with Virtual Users - Update ftp virtual user information.
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
# Initialize some variables
#
HOMEDIR=/var/ftp/virtual_users
FTPCONF=/etc/vsftpd
SHELL=/sbin/nologin
CHMOD=750
SELCONTEXT=public_content_rw_t
ACCOUNTSDB_TMP=$FTPCONF/accounts.tmp
ACCOUNTSDB_DB=$FTPCONF/accounts.db

if [ -f $FTPCONF/accounts.tmp ];then
    ACCOUNTDB_TOTALLINES=`grep '.' -c $FTPCONF/accounts.tmp`
else
    ACCOUNTDB_TOTALLINES=0
fi

function checkUser_Existence () {
    C=1;

    if [ "$ACCOUNTDB_TOTALLINES" != "0" ];then
        while [ $C -lt $ACCOUNTDB_TOTALLINES ]; do
            VALIDUSER=`sed -n -e "$C p" $FTPCONF/accounts.tmp`
            if [ "$USERNAME" == "$VALIDUSER" ];then
                USERNAMEOK=YES
                break;
            else
                USERNAMEOK=NO
           fi
           let C=$C+2;
        done 
    fi
}

function getUsername () {

    printf " Enter Username (lowercase)      : "
    read USERNAME

    checkUser_Existence;

    if [ "$USERNAMEOK" == "NO" ];then
        echo "  --> Invalid ftp virtual user. Try another username."
        getUsername;
    fi

}

#
# Add some presentation :)
#
clear;
echo ' vsftpd 2.0.5 -> Virtual Users -> Update User';
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
# Get user information
#
getUsername;
printf " Enter Password (case sensitive) : "
read PASSWORD
printf " Enter Comment(user's full name) : "
read FULLNAME
printf " Account disabled ? (y/N)        : "
read USERSTATUS
echo " Home directory location         : ${HOMEDIR}/$USERNAME " 
echo " Home directory permissions      : $USERNAME.$USERNAME | 750 | public_content_rw_t"
echo " Login Shell                     : $SHELL "

#
# Create specific user configuration, based on 
# vsftpd_virtualuser_config.tpl file.
#
# ... Do not change it in this script.

#
# Update denied_users file
#
if [ "$USERSTATUS" == "y" ];then
	echo $USERNAME >> $FTPCONF/denied_users	
else
	sed -i -r -e "/^$USERNAME$/ d" $FTPCONF/denied_users
fi

#
# Update accounts.db file.
#
sed -i -e "/$USERNAME/,+1 d" $ACCOUNTSDB_TMP
echo $USERNAME >> $ACCOUNTSDB_TMP; 
echo $PASSWORD >> $ACCOUNTSDB_TMP;
rm -f $ACCOUNTSDB_DB
db_load -T -t hash -f $ACCOUNTSDB_TMP $ACCOUNTSDB_DB

#
# Set Permissions
#
/bin/chmod 600 $ACCOUNTSDB_DB
/bin/chmod -R $CHMOD $HOMEDIR/$USERNAME
/usr/bin/chcon -R -t public_content_rw_t $HOMEDIR/$USERNAME

#
# Update user information
#
/usr/bin/chfn -f "$FULLNAME" $USERNAME 1>/dev/null

# Restart vsftpd after user addition.
echo '-------------------------------------------------------------------'
/sbin/service vsftpd reload
echo '-------------------------------------------------------------------'
