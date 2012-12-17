#!/bin/sh
# Chroot FTP with Virtual Users - Add ftp virtual user
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
LOCALPATH=`pwd`
SHELL=/sbin/nologin
FTPCONF=/etc/vsftpd
HOMEDIR=/var/ftp/virtual_users

if [ -f $FTPCONF/accounts.tmp ];then
    ACCOUNTDB_TOTALLINES=`grep '.' -c $FTPCONF/accounts.tmp`
else
    ACCOUNTDB_TOTALLINES=0
fi

function checkNewUser_Existence () {
    C=1;

    if [ "$ACCOUNTDB_TOTALLINES" != "0" ];then
        while [ $C -lt $ACCOUNTDB_TOTALLINES ]; do
            VALIDUSER=`sed -n -e "$C p" $FTPCONF/accounts.tmp`
            if [ "$USERNAME" == "$VALIDUSER" ];then
                USERNAMEOK=NO
                break;
            else
                USERNAMEOK=YES
           fi
           let C=$C+2;
        done 
    fi
}

function checkNewUser_Availability () {

    if [ -f $FTPCONF/denied_users ];then
        if [ ! `grep -w $USERNAME $FTPCONF/denied_users` ];then
            USERNAMEOK=YES
	else
	    USERNAMEOK=NO
        fi
    
    else
        USERNAMEOK=NO
    fi
}

function checkNewUser_Homedir () {

    # Verify User's Home Directory.
    if [ -d $HOMEDIR ];then
        for i in `ls $HOMEDIR/`; do
           VALIDUSER=$i
           if [ "$USERNAME" == "$VALIDUSER" ];then
               USERNAMEOK=NO
	       break;
	   else
	       USENAMEOK=YES
           fi
        done
    fi
}

function getUsername () {

    printf " Enter Username (lowercase)      : "
    read USERNAME

    checkNewUser_Existence;
    checkNewUser_Availability;
    checkNewUser_Homedir;

    if [ "$USERNAMEOK" == "NO" ];then
        echo "  --> Invalid ftp virtual user. Try another username."
        getUsername;
    fi

}

#
# Add some presentation :)
#
clear;
echo " vsftpd 2.0.5 -> Virtual Users -> New User"
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
cp $LOCALPATH/vsftpd_virtualuser_config.tpl $LOCALPATH/vsftpd_virtualuser_config.tpl.1
sed -i -e "s/USERNAME/$USERNAME/g;" $LOCALPATH/vsftpd_virtualuser_config.tpl.1
cat $LOCALPATH/vsftpd_virtualuser_config.tpl.1 > $FTPCONF/users/$USERNAME
rm -f $LOCALPATH/vsftpd_virtualuser_config.tpl.1

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
echo $USERNAME >> $FTPCONF/accounts.tmp; 
echo $PASSWORD >> $FTPCONF/accounts.tmp;
rm -f $FTPCONF/accounts.db
db_load -T -t hash -f  $FTPCONF/accounts.tmp $FTPCONF/accounts.db

#
# Create ftp virtual user $HOMEDIR
#
if [ ! -d $HOMEDIR  ];then
    mkdir $HOMEDIR
fi

#
# Set user information
#
/usr/sbin/useradd -d "${HOMEDIR}/$USERNAME" -s "/sbin/nologin" -c "$FULLNAME" $USERNAME

#
# Set Permissions
#
/bin/chmod 600 $FTPCONF/accounts.db
/bin/chmod 750 $HOMEDIR/$USERNAME
/usr/bin/chcon -t public_content_rw_t $HOMEDIR/$USERNAME

# Restart vsftpd after user addition.
echo '-------------------------------------------------------------------'
/sbin/service vsftpd reload
echo '-------------------------------------------------------------------'
