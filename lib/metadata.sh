#!/usr/bin/env bash

aim_set_paths() {
    APP_INSTALL_DIR="${AIM_BASE_DIR}/${APP_ID}"
    APPIMAGE_PATH="${APP_INSTALL_DIR}/application.AppImage"
    METADATA_PATH="${APP_INSTALL_DIR}/metadata.env"
    WRAPPER_PATH="${AIM_BIN_DIR}/${COMMAND_NAME}"
    DESKTOP_PATH="${AIM_DESKTOP_DIR}/${APP_ID}.desktop"
    ICON_PATH="${AIM_ICON_DIR}/${APP_ID}.png"
}

aim_save_metadata() {
    cat > "${METADATA_PATH}" <<EOF
META_APP_ID=$(printf '%q' "${APP_ID}")
META_APP_NAME=$(printf '%q' "${APP_NAME}")
META_COMMAND_NAME=$(printf '%q' "${COMMAND_NAME}")
META_CATEGORY=$(printf '%q' "${CATEGORY}")
META_COMMENT=$(printf '%q' "${COMMENT}")
META_NO_SANDBOX=$(printf '%q' "${NO_SANDBOX}")
META_SOURCE_TYPE=$(printf '%q' "${SOURCE_TYPE}")
META_SOURCE_VALUE=$(printf '%q' "${SOURCE_VALUE}")
META_INSTALLED_AT=$(printf '%q' "$(date '+%Y-%m-%d %H:%M:%S')")
EOF
}

aim_load_metadata() {
    local requested_id="$1"
    local metadata_file="${AIM_BASE_DIR}/${requested_id}/metadata.env"

    [[ -f "${metadata_file}" ]] || aim_die "No existe una aplicación instalada con ID: ${requested_id}"

    # shellcheck disable=SC1090
    source "${metadata_file}"

    APP_ID="${META_APP_ID}"
    APP_NAME="${META_APP_NAME}"
    COMMAND_NAME="${META_COMMAND_NAME}"
    CATEGORY="${META_CATEGORY}"
    COMMENT="${META_COMMENT}"
    NO_SANDBOX="${META_NO_SANDBOX}"
    aim_set_paths
}

aim_read_desktop_metadata() {
    local extract_root="$1"
    local desktop_file=""

    desktop_file="$(find "${extract_root}" -maxdepth 2 -type f -iname "*.desktop" | head -n 1 || true)"
    [[ -n "${desktop_file}" ]] || return 0

    local detected_name detected_comment detected_categories
    detected_name="$(grep -m1 '^Name=' "${desktop_file}" | cut -d= -f2- || true)"
    detected_comment="$(grep -m1 '^Comment=' "${desktop_file}" | cut -d= -f2- || true)"
    detected_categories="$(grep -m1 '^Categories=' "${desktop_file}" | cut -d= -f2- || true)"

    [[ -n "${APP_NAME}" ]] || APP_NAME="${detected_name}"
    [[ -n "${COMMENT}" ]] || COMMENT="${detected_comment}"
    [[ "${CATEGORY}" != "Utility;" || -z "${detected_categories}" ]] || CATEGORY="${detected_categories}"
}
