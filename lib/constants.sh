#!/usr/bin/env bash

readonly AIM_NAME="appimage-manager"
readonly AIM_VERSION="2.0.0"

readonly AIM_BASE_DIR="${HOME}/.local/opt/appimage-manager"
readonly AIM_BIN_DIR="${HOME}/.local/bin"
readonly AIM_DESKTOP_DIR="${HOME}/.local/share/applications"
readonly AIM_ICON_BASE_DIR="${HOME}/.local/share/icons/hicolor"
readonly AIM_ICON_DIR="${AIM_ICON_BASE_DIR}/256x256/apps"
readonly AIM_STATE_DIR="${HOME}/.local/state/appimage-manager"
readonly AIM_LOG_FILE="${AIM_STATE_DIR}/appimage-manager.log"
