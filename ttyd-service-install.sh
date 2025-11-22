#!/bin/bash

# AUTO-GENERATED FILE — DO NOT EDIT
#
# This script is produced by the build/generation process.  
# Any manual modifications will be overwritten when the file is
# regenerated and will NOT be reflected in the original source.
#
# To change this script, edit the corresponding source
# and regenerate it instead.

# Copyright (c) 2025 KimYoungNo
# Author: KimYoungNo
# License: MIT
# Version: 0.0.1

# Header ───────────────────────────────────────────────────────────────
clear
cat <<"EOF"

   __  __            __                           _         
  / /_/ /___  ______/ /     ________  ______   __(_)_______ 
 / __/ __/ / / / __  /_____/ ___/ _ \/ ___/ | / / / ___/ _ \
/ /_/ /_/ /_/ / /_/ /_____(__  )  __/ /   | |/ / / /__/  __/
\__/\__/\__, /\__,_/     /____/\___/_/    |___/_/\___/\___/ 
       /____/


EOF
# stdout Helpers ───────────────────────────────────────────────────────────────
RESET=$(  printf '\033[0m')
BOLD=$(   printf '\033[1m')
BLACK=$(  printf '\033[30m')
RED=$(    printf '\033[31m')
GREEN=$(  printf '\033[32m')
YELLOW=$( printf '\033[33m')
BLUE=$(   printf '\033[34m')
MAGENTA=$(printf '\033[35m')
CYAN=$(   printf '\033[36m')
WHITE=$(  printf '\033[37m')

INFO_HEADER="${BOLD}${CYAN}[i]"
WARN_HEADER="${BOLD}${YELLOW}⚠"
DONE_HEADER="${BOLD}${GREEN}✔"
ERROR_HEADER="${BOLD}${RED}✖"

function msg_info() { echo -e "${INFO_HEADER} $@ ${RESET}"; }
function msg_warn() { echo -e "${WARN_HEADER} $@ ${RESET}"; }
function msg_done() { echo -e "${DONE_HEADER} $@ ${RESET}"; }
function msg_error(){ echo -e "${ERROR_HEADER} $@ ${RESET}"; }

# Fallback Routine ───────────────────────────────────────────────────────────────
errlog=$(mktemp)
trap 'rm -f "$errlog"' EXIT

#exec 3>&2
#exec 2> >(tee -a "$errlog" >&1)

function fallback() {
  local rc=$1
  local cmd=${BASH_COMMAND}
  local file=${BASH_SOURCE[1]}
  local lineno=${BASH_LINENO[0]}
  {
    msg_error "${file}: ${lineno}: \"${cmd}\" exited with ${rc}"
#    echo -e   "└── traceback:"
#    sed  's/^/    /' "${errlog}"
#    echo -e   ""
  }
  exit "$rc"
}
set -Eeu
set -Eeuo errexit
set -Eeuo pipefail
trap 'fallback $?' ERR

# OS Detection ───────────────────────────────────────────────────────────────
if [[ -f "/etc/debian_version" ]]; then
  OS="DEBIAN"
fi

# System Path ───────────────────────────────────────────────────────────────
if [[ ${OS} == "DEBIAN" ]]; then
  SERVICE_DIR="/etc/systemd/system"
  CONFIG_DIR="/usr/local/share/ttyd-service"
fi
mkdir -p "${CONFIG_DIR}" >/dev/null 2>&1
# Dependencies Installation ───────────────────────────────────────────────────────────────
msg_info "Installing Dependencies..."
if [[ ${OS} == "DEBIAN" ]]; then
  apt update
  apt upgrade -y
  apt install -y build-essential cmake git libjson-c-dev libwebsockets-dev
fi
msg_done "Dependency Installation Complete"
echo -e  ""

# ttyd Installation ───────────────────────────────────────────────────────────────
if ! $(command -v ttyd 1>/dev/null 2>&1); then
  msg_info "Installing ttyd..."

  TEMP_SRC_DIR=$(mktemp -d)
  TEMP_BUILD_DIR="${TEMP_SRC_DIR}/build"

  git clone https://github.com/tsl0922/ttyd.git "${TEMP_SRC_DIR}"
  mkdir -p "${TEMP_BUILD_DIR}"
  cmake -S "${TEMP_SRC_DIR}" -B "${TEMP_BUILD_DIR}"
  cmake --build "${TEMP_BUILD_DIR}"
  cmake --install "${TEMP_BUILD_DIR}"
  rm -rf "${TEMP_SRC_DIR}"

  echo -e  ""
  msg_done "ttyd Installation Complete"
  echo -e  ""
fi

# ttyd Path ───────────────────────────────────────────────────────────────
TTYD_PATH=$(which ttyd)
msg_info "Found ttyd: ${TTYD_PATH}"
echo -e  ""

# Service Name ───────────────────────────────────────────────────────────────
DEFAULT_NAME="ttyd-service"
SERVICE_NAME=""
while systemctl list-unit-files --type=service --all \
      | grep "^${SERVICE_NAME}.service" 1>/dev/null 2>&1 || [[ -z "${SERVICE_NAME}" ]]; do
  if [[ -n "${SERVICE_NAME}" ]]; then
    overwrite=$( \
    whiptail \
	--title "Service Name Conflict" \
	--yesno "Service name is already in use. Will you overwrite current service?\n\
If you choose 'yes', the service will be removed in an instant and cannot be recovered." 10 70 \
3>&1 1>&2 2>&3)
    if $overwrite; then
      revoke_path=$(systemctl cat "${SERVICE_NAME}" | grep "^#")
      rm -f "/${revoke_path#*/}" 1>/dev/null 2>&1
      systemctl disable --now "${SERVICE_NAME}.service" 1>/dev/null 2>&1
      systemctl daemon-reload 1>/dev/null 2>&1
      break
    else
      whiptail  --nocancel \
	--title "Service Name Conflict" \
	--msgbox "Service name is already in use. Please change your service name." 10 60 \
3>&1 1>&2 2>&3
    fi
  fi
  SERVICE_NAME=$( \
  whiptail  \
  --title "Service Name" \
  --inputbox "Enter your service name." 10 60 "${SERVICE_NAME:-$DEFAULT_NAME}" \
3>&1 1>&2 2>&3)
  if [[ -z "${SERVICE_NAME}" ]]; then
    whiptail  --nocancel \
	--title "Service Name Resolve" \
	--msgbox "Service name is blank. Default name is applied: ${DEFAULT_NAME}" 10 60 \
3>&1 1>&2 2>&3
    SERVICE_NAME="${DEFAULT_NAME}"
  fi
done

# Service Port ───────────────────────────────────────────────────────────────
DEFAULT_PORT=7681
SERVICE_PORT=""
while ss -l | grep ":${SERVICE_PORT}" 1>/dev/null 2>&1 || \
      [[ -z "${SERVICE_PORT}" ]]; do
  if [[ -n "${SERVICE_PORT}" ]]; then
    whiptail  --nocancel \
	--title "Service Port Conflict" \
	--msgbox "Port is busy. Please change your port." 10 60 \
3>&1 1>&2 2>&3
  fi
  SERVICE_PORT=$( \
  whiptail  \
	--title "Port Number" \
	--inputbox "Enter your port number." 10 60 "${SERVICE_PORT:-$DEFAULT_PORT}" \
3>&1 1>&2 2>&3)
  if [[ -z "${SERVICE_PORT}" ]]; then
    whiptail --nocancel \
	--title "Service Port Resolve" \
	--msgbox "Service port is blank. Default port is applied: ${DEFAULT_PORT}" 10 60 \
3>&1 1>&2 2>&3
    SERVICE_PORT="${DEFAULT_PORT}"
  fi
done

# Service File ───────────────────────────────────────────────────────────────
if [[ ${OS} == "DEBIAN" ]]; then
  DEFAULT_CWD="/usr/bin"
fi
SERVICE_CWD=$( \
whiptail  \
	--title "Service WorkingDirectory" \
	--inputbox "Write your path for service's working directory." 10 60 "${DEFAULT_CWD}" \
3>&1 1>&2 2>&3 3>&-)
SERVICE_CWD="${SERVICE_CWD:-$DEFAULT_CWD}"

DEFAULT_EXEC="${TTYD_PATH} -p ${SERVICE_PORT}"
SERVICE_EXEC=$( \
whiptail  \
	--title "Service ExecStart" \
	--inputbox "Write your commands for service's ExecStart.\n \
(check github for more detail: https://github.com/tsl0922/ttyd)" 10 80 "${DEFAULT_EXEC}" \
3>&1 1>&2 2>&3)
SERVICE_EXEC="${SERVICE_EXEC:-$DEFAULT_EXEC}"

# Service Path ───────────────────────────────────────────────────────────────
if [[ ${OS} == "DEBIAN" ]]; then
  SERVICE_PATH="${SERVICE_DIR}/${SERVICE_NAME}.service"
  CONFIG_PATH="${CONFIG_DIR}/${SERVICE_NAME}.cfg"
else
  fallback "Unsupported OS (${OS}). Installation Aborted."
fi

# Configurations Enumeration ───────────────────────────────────────────────────────────────
msg_info "ttyd-service configurations"
echo -e  "  - service name: ${BOLD}${SERVICE_NAME}${RESET}"
echo -e  "  - service file path: ${BOLD}${SERVICE_PATH}${RESET}"
echo -e  "  - service config path: ${BOLD}${CONFIG_PATH}${RESET}"
echo -e  ""
echo -e  "  - service ExecStart: ${BOLD}${SERVICE_EXEC}${RESET}"
echo -e  "  - service WorkingDirectory: ${BOLD}${SERVICE_CWD}${RESET}"
echo -e  ""

# Configuration File ───────────────────────────────────────────────────────────────
msg_info "Saving Configurations..."
if [[ ${OS} == "DEBIAN" ]]; then
  cat <<EOF >"${CONFIG_PATH}"
SERVICE_NAME=$SERVICE_NAME
SERVICE_PATH=$SERVICE_PATH
SERVICE_EXEC=$SERVICE_EXEC
SERVICE_CWD=$SERVICE_CWD
EOF
fi

msg_done "Configuration saved at: ${CONFIG_PATH}"
echo -e  ""

# Service Creation ───────────────────────────────────────────────────────────────
msg_info "Creating Service..."

if [[ ${OS} == "DEBIAN" ]]; then
  cat <<EOF >"${SERVICE_PATH}"
[Unit]
Description=$SERVICE_NAME
After=network.target

[Service]
User=root
ExecStart=$SERVICE_EXEC
WorkingDirectory=$SERVICE_CWD
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
  systemctl daemon-reload 1>/dev/null 2>&1
  systemctl enable --now "${SERVICE_NAME}.service" 1>/dev/null 2>&1
fi

msg_done "Service Created"
echo -e  ""

# Primary IP ───────────────────────────────────────────────────────────────
IFACE=$(ip -4 route | awk '/default/ {print $5; exit}')
IP=$(ip -4 addr show "$IFACE" | awk '/inet / {print $2}' | cut -d/ -f1 | head -n 1)
[[ -z "$IP" ]] && IP=$(hostname -I | awk '{print $1}')
[[ -z "$IP" ]] && IP="127.0.0.1"

echo -e "${SERVICE_NAME} is reachable at: ${BOLD}${MAGENTA}http://${IP}:${SERVICE_PORT}${RESET}"
echo -e ""
