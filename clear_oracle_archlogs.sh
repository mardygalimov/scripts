#!/bin/bash
################################################################################
#                                                                              #
#                  Скрипт удаления архивных логов через rman                   #
#                    mailto:mardygalimov@gmail.com.                            #
#                                                                 <2022.04.15> #
################################################################################
# 
# Additional description: 
# Requirements:
# TODO:
 
export PATH="$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin"

CLEAR_LOG_FILE=/var/tmp/del_rman_alogs.log
EXL_DB="\-MGMTDB|ASM|APX|ipmon"

# Count Instance Numbers
INS_COUNT=$(pgrep -fa pmon | grep -Ecv ${EXL_DB})

# Exit if No DBs are running:
if [ "$INS_COUNT" -eq 0 ]; then
  echo "No Database Running">> $CLEAR_LOG_FILE
  exit
fi

export ORACLE_BASE=''
# Loop for every Oracle Home in ORATAB file from /etc/oratab for a database
# Getting ORACLE_SID and ORACLE_HOME
for DBNAME in $(pgrep -af [o]ra_pmon |\
                grep -Ev ${EXL_DB}|awk '{print $NF}' |\
                sed -e 's/ora_pmon_//g' |\
                grep -v "s///g"); do
  ORACLE_SID=$(pgrep -af [o]ra_pmon |\
                grep -i "${DBNAME^^}" |\
                grep -Ev ${EXL_DB} |\
                awk '{print $NF}' |\
                sed -e 's/ora_pmon_//g' |\
                grep -v "s///g")
  ORACLE_HOME=$(grep "^${DBNAME}:" /etc/oratab |\
                cut -d: -f2 -s)

  for pid in $(pgrep -af pmon |\
               grep "${ORACLE_SID}" |\
               grep -Ev ${EXL_DB} |\
               grep -v "\-MGMTDB" |\
              awk '{print $1}'); do
    ORA_USER=$(ps -o user= -p "$pid")
  done

  USR_ORA_HOME=$(grep -i "^${ORA_USER}:" /etc/passwd | cut -f6 -d ':' | tail -1)

  # Getting ORACLE_BASE:
  if [ ! -d "${ORACLE_BASE}" ]; then
    ORACLE_BASE=$(grep ^ORACLE_BASE "${ORACLE_HOME}"/install/envVars.properties |\
                  tail -1 |\
                  awk '{print $NF}' |\
                  sed -e 's/ORACLE_BASE=//g')
    export ORACLE_BASE
  fi

  if [ ! -d "${ORACLE_BASE}" ]; then
    ORACLE_BASE=$(grep -h 'ORACLE_BASE=\/' "${USR_ORA_HOME}"/.bash* "${USR_ORA_HOME}"/.*profile |\
                  perl -lpe'$_ = reverse' |\
                  cut -f1 -d'=' |\
                  perl -lpe'$_ = reverse' |\
                  tail -1)
    export ORACLE_BASE
  fi

# Set Operating System Environment Variables
export ORACLE_SID
export ORACLE_HOME

#=================#
RMAN_LOG_FILE=$CLEAR_LOG_FILE
{
echo Script "$0" 
echo ==== started on "$(date)" for "$ORACLE_SID" period time "sysdate-$1"====
echo ""
} >> $RMAN_LOG_FILE

export RMAN=$ORACLE_HOME/bin/rman

$RMAN target / nocatalog  msglog $RMAN_LOG_FILE append  <<EOF

# -----------------------------------------------------------------
# RMAN command section
# -----------------------------------------------------------------

RUN {
delete noprompt archivelog all completed before 'sysdate-$1';
}
EOF


done
