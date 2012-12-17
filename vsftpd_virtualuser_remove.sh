#!/bin/sh
# Chroot FTP with Virtual Users - Remove ftp virtual user
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
HOMEDIR=/var/ftp/virtual_users
FTPCONF=/etc/vsftpd

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

function checkUser_Homedir () {

    # Verify User's Home Directory.
    if [ -d $HOMEDIR ];then
        for i in `ls $HOMEDIR/`; do
           VALIDUSER=$i
           if [ "$USERNAME" == "$VALIDUSER" ];then
               USERNAMEOK=YES
	       break;
	   else
	       USENAMEOK=NO
           fi
        done
    fi

}

function removeUser () {

    # Remove user from accounts.tmp
    printf " Updating $FTPCONF/accounts.tmp file ... ";
        sed -i -e "/$USERNAME/,+1 d" $FTPCONF/accounts.tmp
    printf "done. \n"

    # Remove user from account.db
    printf " Updating $FTPCONF/accounts.db file ... ";
        db_load -T -t hash -f  $FTPCONF/accounts.tmp $FTPCONF/accounts.db
    printf "done. \n"

    # Remove user from denied_users 
    printf " Updating $FTPCONF/denied_users file ... "
        sed -i -e "/$USERNAME/ d" $FTPCONF/denied_users
    printf " done.\n"
    
    # Remove user from /etc/passwd and /etc/group. Also 
    # remove related user information.
    printf " Removing user information from the system ... ";
        /usr/sbin/userdel -r $USERNAME
    printf "done. \n"

}

clear;
echo " vsftpd 2.0.5 -> Virtual Users -> Remove User"
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
# Non-interactive
#
if [ "$1" ];then

    for i in $1; do
    USERNAME=$i
    echo "Removing user $USERNAME: "
    checkUser_Existence;
    checkUser_Homedir;

    if [ "$USERNAMEOK" == "YES" ];then
    removeUser;
    echo '-------------------------------------------------------------------'
    /sbin/service vsftpd reload
    echo '-------------------------------------------------------------------'
    else
       echo "   ATTENTION : This user can't be removed. It is an invalid user."
       echo '-------------------------------------------------------------------'
    fi
    done

    exit;
fi

#
# Interactive
#
printf " Enter username (lowercase): "
read USERNAME

checkUser_Existence;
checkUser_Homedir;

if [ "$USERNAMEOK" == "YES" ];then

    echo ' ****************************************************************** '
    echo " * ATTENTION: All data related to the user $USERNAME will be removed."
    echo ' ****************************************************************** '
    printf ' Are you sure ? (N/y): '
    read CONFIRMATION

    if [ "$CONFIRMATION" != "y" ];then
        exit;
    fi
    removeUser;
    echo '-------------------------------------------------------------------'
    /sbin/service vsftpd reload
    echo '-------------------------------------------------------------------'

else
       echo "   ATTENTION : This user can't be removed. It is an invalid user."
       echo '-------------------------------------------------------------------'
fi
