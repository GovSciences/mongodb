#!/bin/bash
set -m

setAdminPassword () {
  PASS=${MONGODB_PASS:-$(pwgen -s 12 1)}
  _word=$( [ ${MONGODB_PASS} ] && echo "preset" || echo "random" )

  RET=1
  while [[ RET -ne 0 ]]; do
    echo "=> Waiting for confirmation of MongoDB service startup"
    sleep 5
    mongo admin --eval "help" >/dev/null 2>&1
    RET=$?
  done

  echo "=> Creating an admin user with a ${_word} password in MongoDB"
  mongo admin --eval "db.createUser({user: 'admin', pwd: '$PASS', roles:[{role:'root',db:'admin'}]});"

  echo "=> Done!"
  touch /data/db/.mongodb_password_set

  echo "========================================================================"
  echo "You can now connect to this MongoDB server using:"
  echo ""
  echo "    mongo admin -u admin -p $PASS --host <host> --port <port>"
  echo ""
  echo "Please remember to change the above password as soon as possible!"
  echo "========================================================================"
}

mongodbStart () {
  CMD="mongod --httpinterface --rest --master"
  if [ "$AUTH" == "yes" ]; then
    CMD="$CMD --auth"
  fi

  if [ "$JOURNALING" == "no" ]; then
    CMD="$CMD --nojournal"
  fi

  if [ "$OPLOG_SIZE" != "" ]; then
    CMD="$CMD --oplogSize $OPLOG_SIZE"
  fi

  $CMD &

  if [ ! -f /data/db/.mongodb_password_set ]; then
    setAdminPassword
  fi

  fg
}

mongodbHelp () {
  echo "Available options:"
  echo "  mongodb       - Starts MongoDB with default options (default)"
  echo "  help          - Displays this help!"
  echo "  [command]     - Execute the specified linux command. e.g: bash"
}

case "$1" in
  mongodb)
    mongodbStart
    ;;
  help)
    mongodbHelp
    ;;
  *)
    if [ -x $1 ]; then
      $1
    else
      prog=$(which $1)
      if [ -n "${prog}" ] ; then
        shift 1
        $prog $@
      else
        mongodbHelp
      fi
    fi
    ;;
esac

exit 0
