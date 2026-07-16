#!/usr/bin/env bash

aim_needs_no_sandbox() {
    case "${NO_SANDBOX}" in
        true) return 0 ;;
        false) return 1 ;;
        auto)
            strings "${APPIMAGE_PATH}" 2>/dev/null | grep -qiE 'electron|chromium'
            return $?
            ;;
        *) return 1 ;;
    esac
}

aim_create_wrapper() {
    local sandbox_arg=""
    aim_needs_no_sandbox && sandbox_arg=' --no-sandbox'

    cat > "${WRAPPER_PATH}" <<EOF
#!/usr/bin/env bash
exec "${APPIMAGE_PATH}"${sandbox_arg} "\$@"
EOF

    chmod +x "${WRAPPER_PATH}"
}
