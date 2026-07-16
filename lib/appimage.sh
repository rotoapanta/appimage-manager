#!/usr/bin/env bash

aim_copy_source() {
    local destination="$1"

    case "${SOURCE_TYPE}" in
        file)
            [[ -f "${SOURCE_VALUE}" ]] || aim_die "No se encontró el archivo: ${SOURCE_VALUE}"
            cp "${SOURCE_VALUE}" "${destination}"
            ;;
        url)
            aim_download "${SOURCE_VALUE}" "${destination}"
            ;;
        *)
            aim_die "Fuente inválida. Usa --from-file o --from-url."
            ;;
    esac
}

aim_validate_appimage() {
    local file_path="$1"

    [[ -s "${file_path}" ]] || aim_die "El archivo AppImage está vacío."
    chmod +x "${file_path}"

    if ! file "${file_path}" | grep -qiE 'ELF|AppImage'; then
        aim_warn "El archivo no parece ser una AppImage ELF convencional."
    fi
}

aim_extract_to_temp() {
    local image_path="$1"
    EXTRACT_TMP_DIR="$(mktemp -d)"

    (
        cd "${EXTRACT_TMP_DIR}"
        "${image_path}" --appimage-extract >/dev/null 2>&1
    ) || return 1

    if [[ -d "${EXTRACT_TMP_DIR}/AppDir" ]]; then
        EXTRACT_ROOT="${EXTRACT_TMP_DIR}/AppDir"
    elif [[ -d "${EXTRACT_TMP_DIR}/squashfs-root" ]]; then
        EXTRACT_ROOT="${EXTRACT_TMP_DIR}/squashfs-root"
    else
        return 1
    fi
}

aim_cleanup_extract() {
    [[ -z "${EXTRACT_TMP_DIR:-}" ]] || rm -rf "${EXTRACT_TMP_DIR}"
    EXTRACT_TMP_DIR=""
    EXTRACT_ROOT=""
}
