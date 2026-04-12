#!/usr/bin/env bash

if [[ "${NO_COLOR:-0}" == "1" || ! -t 1 ]]; then
  C_RESET=""
  C_BOLD=""
  C_RED=""
  C_YELLOW=""
  C_GREEN=""
  C_BLUE=""
  C_CYAN=""
  C_GRAY=""
else
  C_RESET=$'\033[0m'
  C_BOLD=$'\033[1m'
  C_RED=$'\033[31m'
  C_YELLOW=$'\033[33m'
  C_GREEN=$'\033[32m'
  C_BLUE=$'\033[34m'
  C_CYAN=$'\033[36m'
  C_GRAY=$'\033[90m'
fi

_log_stamp() {
  date +"%H:%M:%S"
}

log_info() {
  printf "%s[%s INFO ]%s %s\n" "$C_BLUE" "$(_log_stamp)" "$C_RESET" "$*"
}

log_warn() {
  printf "%s[%s WARN ]%s %s\n" "$C_YELLOW" "$(_log_stamp)" "$C_RESET" "$*"
}

log_error() {
  printf "%s[%s ERROR]%s %s\n" "$C_RED" "$(_log_stamp)" "$C_RESET" "$*" >&2
}

log_debug() {
  if [[ "${DEBUG:-0}" == "1" ]]; then
    printf "%s[%s DEBUG]%s %s\n" "$C_GRAY" "$(_log_stamp)" "$C_RESET" "$*"
  fi
}

log_success() {
  printf "%s[%s  OK  ]%s %s\n" "$C_GREEN" "$(_log_stamp)" "$C_RESET" "$*"
}

log_section() {
  printf "\n%s%s== %s ==%s\n" "$C_CYAN" "$C_BOLD" "$*" "$C_RESET"
}
