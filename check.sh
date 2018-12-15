#!/bin/bash

# Configs
FQDN="$1"
TIP="127.0.0.1"
TDNS="60053"
TDIR="60080"
TOR="60443"
TSOCKS="9050"
LOGDIR="./logs"
TCONF="./tmptorrc"

# Functions
function err_exception () {
 cat <<EOF > ${LOGDIR}/${UTIME}
ERR,${ERRSTR}
EOF
}

function termination () {
  cat <<EOF > ${LOGDIR}/${UTIME}
UTIME,${UTIME}
DATE,${DATE}
DIG,${DIG}
MYIP,${MYIP}
EOF

  rm ${TCONF}
}

function init () {
  if [ ! -d ${LOGDIR} ]; then
    mkdir ${LOGDIR}
  fi
  cat << EOF > ${TCONF}
DNSPort ${TIP}:${TDNS}
ORPort ${TIP}:${TOR}
DirPort ${TIP}:${TDIR}
SOCKSPort ${TIP}:${TSOCKS}
ExitPolicy reject *:*
EOF

}

function main () {
  init

  UTIME=`date +%s`
  DATE=`date`
  STDOUT=${LOGDIR}/${UTIME}_stdout
  STDERR=${LOGDIR}/${UTIME}_stderr

  tor -f ${TCONF} 1>${STDOUT} 2>${STDERR} &
  PID="$!"
  ps ${PID} >& /dev/null
  if [ ! $? = 0 ]; then
    ERRSTR="tor start error"
    err_exception
    return 1
  fi

  sleep 10

  if [ "$?" = 0 ]; then
    DIG=`dig @${TIP} -p ${TDNS} ${FQDN} 2>/dev/null | grep "^${FQDN}"`
    MYIP=`torsocks -a ${TIP} -p ${TSOCKS} curl ifconfig.io 2>/dev/null`
  fi

  kill "${PID}"
  if [ ! "$?" = 0 ]; then
    ERRSTR="tor end error pid:${PID}"
    err_exception
    return 1
  fi

  termination

  rm ${STDOUT}
  rm ${STDERR}
  
  return 0
}


# Main Procedure
main
