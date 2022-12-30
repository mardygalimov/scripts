#!/bin/bash
################################################################################
#                                                                              #
#                       Выгрузка логов с ВЭБ серверов                          #
#                       mailto:mardygalimov@gmail.com                          #
#                                                                 <2022.12.30> #
################################################################################
#                                                                              #
# Source:                                                                      #
#                                                                              #
################################################################################
#$1 - указывать параметром имя без домена
export PATH="$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin"

{
echo "$(date) - $(hostname) - START"

/bin/mount -vv //$1.<домен>.ru/LogFiles /log -t cifs -o credentials=/etc/smb_cred,vers=3.0,noperm,noexec

/bin/rsync -avr /log/ /logs/$1/

/bin/umount -vv /log

echo "$(date) - $(hostname) - END"
} &>>/data/logs/transfer.log
