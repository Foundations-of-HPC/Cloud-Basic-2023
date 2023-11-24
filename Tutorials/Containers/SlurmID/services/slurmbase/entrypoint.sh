#!/bin/bash

# Exit on any error. More complex logics could be implemented in future
# (see https://stackoverflow.com/questions/4381618/exit-a-script-on-error)
set -e

echo ""
echo "[INFO] Executing entrypoint..."

#---------------------
#  Prestartup scripts
#---------------------

if [ "x$SAFEMODE" == "xFalse" ]; then
    echo "[INFO] Executing  prestartup scripts (parents + current):"
    python /prestartup.py
else
    echo "[INFO] Not executing prestartup scripts as we are in safemode"
fi


#---------------------
#   Save env
#---------------------
echo "[INFO] Dumping env"

# Save env vars for later usage (e.g. ssh)

env | \
while read env_var; do
  if [[ $env_var == HOME\=* ]]; then
      : # Skip HOME var
  elif [[ $env_var == PWD\=* ]]; then
      : # Skip PWD var
  else
      echo "export $env_var" >> /env.sh
  fi
done

#---------------------
#  Entrypoint command
#---------------------
# Start!


if [[ "x$@" == "x" ]] ; then
    ENTRYPOINT_COMMAND="supervisord"
else
    ENTRYPOINT_COMMAND=$@
fi

echo -n "[INFO] Executing Docker entrypoint command: "
echo $ENTRYPOINT_COMMAND
exec "$ENTRYPOINT_COMMAND"
