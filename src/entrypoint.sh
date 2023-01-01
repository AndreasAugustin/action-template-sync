#! /usr/bin/env bash
set -e
# set -u
set -x

# shellcheck source=src/sync_common.sh
source sync_common.sh

if [[ -z "${GITHUB_TOKEN}" && -z "${SOURCE_REPO_GITHUB_TOKEN}" ]]; then
# TODO
    err "Missing input 'github_token: \${{ secrets.GITHUB_TOKEN }}'.";
    exit 1;
fi

# if [[ -z "${SOURCE_REPO_GITHUB_TOKEN}" ]]; then
#   debug "Missing input 'source_repo_github_token: \${{ input.source_repo_github_token }}'. Using github_token as default."
#   SOURCE_REPO_GITHUB_TOKEN="${GITHUB_TOKEN}"
# fi

if [[ -z "${SOURCE_REPO_PATH}" ]]; then
  err "Missing input 'source_repo_path: \${{ input.source_repo_path }}'.";
  exit 1
fi

SOURCE_REPO_HOSTNAME="${HOSTNAME:-github.com}"

# In case of ssh template repository this will be overwritten
SOURCE_REPO_PREFIX="https://${SOURCE_REPO_HOSTNAME}/"

function ssh_setup() {
  echo "::group::ssh setup"

  info "prepare ssh"
  SRC_SSH_FILE_DIR="/tmp/.ssh"
  SRC_SSH_PRIVATEKEY_FILE_NAME="id_rsa_actions_template_sync"
  export SRC_SSH_PRIVATEKEY_ABS_PATH="${SRC_SSH_FILE_DIR}/${SRC_SSH_PRIVATEKEY_FILE_NAME}"
  debug "We are using SSH within a private source repo"
  mkdir -p "${SRC_SSH_FILE_DIR}"
  # use cat <<< instead of echo to swallow output of the private key
  cat <<< "${SSH_PRIVATE_KEY_SRC}" | sed 's/\\n/\n/g' > "${SRC_SSH_PRIVATEKEY_ABS_PATH}"
  chmod 600 "${SRC_SSH_PRIVATEKEY_ABS_PATH}"
  SOURCE_REPO_PREFIX="git@${SOURCE_REPO_HOSTNAME}:"

  echo "::endgroup::"
}

# Forward to /dev/null to swallow the output of the private key
if [[ -n "${SSH_PRIVATE_KEY_SRC}" ]] &>/dev/null; then
  ssh_setup
fi

export SOURCE_REPO="${SOURCE_REPO_PREFIX}${SOURCE_REPO_PATH}"

function git_init() {
  echo "::group::git init"
  info "set git global configuration"

  git config --global user.email "github-action@actions-template-sync.noreply.${SOURCE_REPO_HOSTNAME}"
  git config --global user.name "${GITHUB_ACTOR}"
  git config --global pull.rebase false
  git config --global --add safe.directory /github/workspace
  git lfs install

  if [[ -n "${SOURCE_REPO_GITHUB_TOKEN}" ]]; then
      if [[ -z "${GITHUB_TOKEN}" ]]; then
        export GITHUB_TOKEN_BK="${GITHUB_TOKEN}"
        unset GITHUB_TOKEN
      fi

    gh auth login --git-protocol "https" --hostname "${SOURCE_REPO_HOSTNAME}" --with-token <<< "${SOURCE_REPO_GITHUB_TOKEN}"
    gh auth setup-git --hostname "${SOURCE_REPO_HOSTNAME}"
    # git config --global "credential.https://${SOURCE_REPO_HOSTNAME}.helper" "!gh auth git-credential"
    gh auth status
  fi
  echo "::endgroup::"
}

git_init

# shellcheck source=src/sync_template.sh
source sync_template.sh
