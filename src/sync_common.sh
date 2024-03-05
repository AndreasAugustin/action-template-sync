#!/usr/bin/env bash

set -e
# set -u
# set -x

#######################################
# write a message to STDERR.
# Arguments:
#   message to print.
#######################################
function err() {
  echo "::error::[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $*" >&2;
}

#######################################
# write a debug message.
# Arguments:
#   message to print.
#######################################
function debug() {
  echo "::debug::$*";
}

#######################################
# write a warn message.
# Arguments:
#   message to print.
#######################################
function warn() {
  echo "::warn::$*";
}

#######################################
# write a info message.
# Arguments:
#   message to print.
#######################################
function info() {
  echo "::info::$*";
}

#######################################
# Executes commands defined within yml file
# Arguments:
#   hook -> the hook to use
#
####################################3#
function cmd_from_yml_file() {
  local FILE_NAME="templatesync.yml"
  local HOOK=$1
  local YML_PATH=".hooks.${HOOK}.commands"

  if [ "$IS_ALLOW_HOOKS" != "true" ]; then
    debug "execute cmd hooks not enabled"
  else
    info "execute cmd hooks enabled"

    if ! [ -x "$(command -v yq)" ]; then
      err "yaml query yq is not installed. 'https://mikefarah.gitbook.io/yq/'";
      exit 1;
    fi
    # readarray cmd_Arr < <(yq "${YML_PATH} | .[]"  "${FILE_NAME}")
    readarray cmd_Arr < <(yq "${YML_PATH} | .[]=env(HOOKS)")

    for key in "${cmd_Arr[@]}"; do echo "${key}" | bash; done
  fi
}
