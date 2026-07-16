#!/usr/bin/env bash

aim_create_desktop_entry() {
    local icon_value="${APP_ID}"
    [[ -f "${ICON_PATH}" ]] && icon_value="${ICON_PATH}"

    cat > "${DESKTOP_PATH}" <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=${APP_NAME}
Comment=${COMMENT}
Exec=${WRAPPER_PATH} %F
Terminal=false
Categories=${CATEGORY}
StartupNotify=true
Icon=${icon_value}
TryExec=${WRAPPER_PATH}
EOF

    chmod +x "${DESKTOP_PATH}"
}
