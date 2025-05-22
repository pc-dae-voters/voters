#!/usr/bin/env bash

# Utility run the spring app
# Version: 1.0
# Author: Paul Carlton (mailto:paul.carlton@dae.mn)

set -euo pipefail

if [[ "$OSTYPE" == "darwin"* ]]; then
  stty -echoctl
fi

function is_running() {
  set +e
  kill -0 $(cat /tmp/spring.pid) 2>/dev/null
  running=$?
  set -e
  if [ "$running" == "0" ]; then
    echo "spring application ${1:-already} running, process id: $(cat /tmp/spring.pid), kill -15 $(cat /tmp/spring.pid) to terminate."
    if [ -z "${1:-}" ]; then
      exit 0
    fi
  fi
}

function cleanup() {
  if [[ -z "${client_call:-}" && -e /tmp/spring.pid ]]; then
    echo "" >&2
    echo "--------------------------------------------------------------------------------------------" <&2
    is_running still
    exit 0
  fi
}

trap cleanup SIGINT

function usage()
{
    echo "usage ${0} [--debug] [--ppe] [--client]" >&2
    echo "This script runs the spring application that can be used to access Contact API" >&2
    echo "The '--ppe' option sets the TOKEN_URL and CONTACT_API_URL environmental variables to PPE endpoints," >&2
    echo "if the '--ppe' option is not specified then the user's TOKEN_URL and CONTACT_API_URL environmental variable" >&2
    echo "values will be used to select the endpoint URLs. If these variables are not set the production endpoints will be used" >&2
    echo "The '--client' option is designed for use when running this script from the client application," >&2
    echo "it supresses the tailing of the log so the client run.sh script can progress." >&2
}

function args() {
  arg_list=( "$@" )
  arg_count=${#arg_list[@]}
  arg_index=0
  client_call=""
  export TOKEN_URL="${TOKEN_URL:-https://api.tesco.com/identity/v4/issue-token/token}"
  export CONTACT_API_URL="${CONTACT_API_URL:-https://api.tesco.com/contact}"

  while (( arg_index < arg_count )); do
    case "${arg_list[${arg_index}]}" in
               "-h") usage; exit 0;;
             "--debug") set -x;;
             "--client") client_call=true;;
             "--ppe") export TOKEN_URL="https://api-ppe.tesco.com/identity/v4/issue-token/token";\
                      export CONTACT_API_URL="https://api-ppe.tesco.com/contact";;
           "--help") usage; exit 0;;
               "-?") usage; exit 0;;
        *) ;;
    esac
    (( arg_index+=1 ))
  done
}

export SCRIPT_DIR=$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
export BASE_DIR=$(git rev-parse --show-toplevel)

args "$@"

pushd $SCRIPT_DIR >/dev/null

is_running

if [[ -z "${CLIENT_ID:-}" || -z "${CLIENT_SECRET:-}" ]]; then
  echo "CLIENT_ID and CLIENT_SECRET environmental variables must be set to run the spring application" >&2
  if [ -z "$client_call" ]; then
    exit 1
  else
    exit 0
  fi
fi

nohup ../mvnw spring-boot:run >/tmp/spring.log 2>&1 &
if [ -n "$client_call" ]; then
  echo "Spring application running in background, output being written to /tmp/spring.log, kill $! to terminate" >&2
  sleep 2
fi
popd >/dev/null
echo $! > /tmp/spring.pid
if [ -z "$client_call" ]; then
  echo "Tailing log, control C at any time to terminate without stopping application" >&2
  sleep 2
  tail -f /tmp/spring.log
fi
