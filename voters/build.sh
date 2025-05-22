#!/usr/bin/env bash

# Utility building the java client
# Version: 1.0
# Author: Paul Carlton (mailto:paul.carlton@dae.mn)

set -euo pipefail

function usage()
{
    echo "usage ${0} [--debug]" >&2
    echo "This script will build and push the docker image" >&2
}

function args() {
  SERVICE_NAME="template-service"
  arg_list=( "$@" )
  arg_count=${#arg_list[@]}
  arg_index=0
  while (( arg_index < arg_count )); do
    case "${arg_list[${arg_index}]}" in
          "--debug") set -x;;
               "-h") usage; exit;;
           "--help") usage; exit;;
               "-?") usage; exit;;
        *) if [ "${arg_list[${arg_index}]:0:2}" == "--" ];then
               echo "invalid argument: ${arg_list[${arg_index}]}" >&2
               usage; exit
           fi;
           break;;
    esac
    (( arg_index+=1 ))
  done
}

args "$@"

export SCRIPT_DIR=$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
export BASE_DIR=$(git rev-parse --show-toplevel)

export PLATFORM=mac-arm64
if [[ "$OSTYPE" == "linux"* ]]; then
  PLATFORM=linux64
fi

export GITHUB_TOKEN=token
pushd $SCRIPT_DIR >/dev/null
../mvnw dependency:copy-dependencies verify package
popd >/dev/null
