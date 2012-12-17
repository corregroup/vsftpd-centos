#!/bin/sh
# Chroot FTP with Virtual Users - Information about ftp virtual users
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
# Initializations
#
FTPCONF=/etc/vsftpd
HOMEDIR=/var/ftp/virtual_users
USERCOUNT=0
TOTALSIZE=0
COUNTER=1

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

# getUserInfo. This function retrives information related to ftp
# virtual user. If you want to see more information about an ftp
# virtual user, add it in this function.
#
function getUserInfo {

    echo "           User : $USERNAME"

    checkUser_Existence;
    checkUser_Homedir;

    if [ "$USERNAMEOK" == "YES" ];then
        SIZE=`du -sc $HOMEDIR/$USERNAME | head -n 1 | sed -r 's/\s.*$//' | cut -d' ' -f1`

        # Set if the username is DENIED or ACTIVE
        if [ `grep -w $USERNAME $FTPCONF/denied_users | head -n 1` ];then
	    	USERSTATUS=DISABLED
	    else
	        USERSTATUS=AVAILABLE
        fi

        echo "           Size : $SIZE"
        echo "     Commentary : `grep $USERNAME /etc/passwd | cut -d: -f5`"
        echo " Home directory : `grep $USERNAME /etc/passwd | cut -d: -f6`"
        echo "    Login Shell : `grep $USERNAME /etc/passwd | cut -d: -f7`"
        echo "  Accout Status : $USERSTATUS"

        let USERCOUNT=$USERCOUNT+1
        let TOTALSIZE=$TOTALSIZE+$SIZE

    else

        echo "      ATTENTION : Invalid ftp virtual user."

    fi

    echo "---------------------------------------------------------------"

}

# showTotals.
function showTotals {
    echo "    Total Users : $USERCOUNT"
    echo "Total Size Used : $TOTALSIZE"
}

#
# Some presentation :)
#
clear;
echo " vsftpd 2.0.5 -> Virtual Users -> Information "
echo "---------------------------------------------------------------"

#
# Interactive
#
if [ "$1" ];then

    for i in $1;do

        USERNAME=$i
        getUserInfo;

    done

showTotals;

exit;

fi

#
# Non-Interactive
#
while [ $COUNTER -lt $ACCOUNTDB_TOTALLINES ]; do

    USERNAME=`sed -n -e "$COUNTER p" $FTPCONF/accounts.tmp`

    getUserInfo;

    let COUNTER=$COUNTER+2;

done 

showTotals;
