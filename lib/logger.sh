#!/usr/bin/env bash

aim_log_init() {
    mkdir -p "${AIM_STATE_DIR}"
}

aim_log() {
    local level="$1"
    shift
    aim_log_init
    printf '[%s] [%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "${level}" "$*" \
        | tee -a "${AIM_LOG_FILE}"
}

aim_info() { aim_log "INFO" "$@"; }
aim_warn() { aim_log "WARN" "$@" >&2; }
aim_error() { aim_log "ERROR" "$@" >&2; }

aim_die() {
    aim_error "$@"
    exit 1
}
