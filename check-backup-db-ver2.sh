#!/bin/bash

#Bien moi truong
##########################################################
TOKEN="6112203391:AAEuDTYX3KQRNuoLKuJ0NAtpRoamdHIQQkA"
CHAT_ID="-957135587"
URL="https://api.telegram.org/bot${TOKEN}/sendMessage"
DB_NAME="produce";
hostname=$(hostname)
myip=$(hostname -I | awk '{print $1}')
host_ip=$myip
hostname_server=$hostname
os_systems=$(grep "PRETTY_NAME" /etc/os-release | awk -F= '{ print $2 }' | tr -d '"')
path_backup='/var/lib/pgsql/9.6/backups/produce'
export DATE=`date +%Y_%m_%d_%H_%M`


cd $path_backup


ERROR="
==[BACKUP-ERROR]==
Server: ${hostname_server}
Database: ${DB_NAME}
Address IP : ${host_ip} / 24
Content: Backup backup du lieu khong thanh cong !
--------
Nguyen nhan: Backup DB backup bi ngat giua chung, quyen truy cap sai, hoac khong co db
"

SUCCESS="
==[BACKUP-SUCCESS]==
Server: ${hostname_server}
Database: ${DB_NAME}
Address IP : ${host_ip} / 24
Nguyen nhan: Backup Dump thanh cong databases !
"


alertTelegramSuccess(){
wget -qO- --post-data="chat_id=$CHAT_ID&text=$SUCCESS&parse_mode=HTML" "$URL"
}

alertTelegramError(){
wget -qO- --post-data="chat_id=$CHAT_ID&text=$ERROR&parse_mode=HTML" "$URL"
}


sendSuccessServer(){
capacityFile=$(du -sh ${DB_NAME}_$DATE.dump | awk '{print $1}')

wget --header="Content-Type: application/json" \
--post-data='{"ipServer": "'"$host_ip"'",
    "hostname": "'"$hostname_server"'",
    "osSystems": "'"$os_systems"'",
    "nameDatabase": "'"$DB_NAME"'",
    "pathBackup": "'"$path_backup"'",
    "status": "backup",
    "capacityFile": "'"$capacityFile"'"
    }' \
-O /dev/null \
http://10.0.0.210:5000/api/databases/info

}
sendErrorServer(){
capacityFile=$(du -sh ${DB_NAME}_$DATE.dump | awk '{print $1}')

wget --header="Content-Type: application/json" \
--post-data='{"ipServer": "'"$host_ip"'",
    "hostname": "'"$hostname_server"'",
    "osSystems": "'"$os_systems"'",
    "nameDatabase": "'"$DB_NAME"'",
    "pathBackup": "'"$path_backup"'",
    "status": "error",
    "capacityFile": "'"$capacityFile"'"
    }' \
http://10.0.0.210:5000/api/databases/info

}


pg_dump -U postgres -d $DB_NAME --exclude-table-data=adempiere.ad_changelog -Fc -f ${DB_NAME}_${DATE}.dump
#pg_dump $DB_NAME > ${DB_NAME}_$DATE.sql
case $? in
  1)
   alertTelegramError
   sendErrorServer
   exit 0
   ;;
  0)
   alertTelegramSuccess
   sendSuccessServer
   exit 0
   ;;
  *)
   alertTelegramError
   echo 'No content'
   ;;
esac
