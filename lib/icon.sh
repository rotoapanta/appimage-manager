#!/usr/bin/env bash

aim_install_icon() {
    local found_icon=""
    local app_name_id

    rm -f "${ICON_PATH}"
    app_name_id="$(aim_sanitize_id "${APP_NAME}")"

    if ! aim_extract_to_temp "${APPIMAGE_PATH}"; then
        aim_warn "No se pudo extraer el AppImage para obtener el ícono."
        return 0
    fi

    aim_read_desktop_metadata "${EXTRACT_ROOT}"

    if [[ -e "${EXTRACT_ROOT}/.DirIcon" ]]; then
        found_icon="${EXTRACT_ROOT}/.DirIcon"
    elif [[ -f "${EXTRACT_ROOT}/${APP_ID}.png" ]]; then
        found_icon="${EXTRACT_ROOT}/${APP_ID}.png"
    elif [[ -f "${EXTRACT_ROOT}/${app_name_id}.png" ]]; then
        found_icon="${EXTRACT_ROOT}/${app_name_id}.png"
    else
        found_icon="$(find "${EXTRACT_ROOT}" -maxdepth 1 -type f -iname "*.png" | head -n 1 || true)"
    fi

    if [[ -z "${found_icon}" ]]; then
        found_icon="$(
            find "${EXTRACT_ROOT}" -type f -iname "*.png" \
                | grep -Ei "/(${APP_ID}|${app_name_id})[^/]*\.png$" \
                | grep -Ei "/(512x512|256x256|128x128|64x64|apps)/" \
                | head -n 1 || true
        )"
    fi

    if [[ -z "${found_icon}" ]]; then
        found_icon="$(
            find "${EXTRACT_ROOT}" -type f -iname "*.svg" \
                | grep -Ei "/(${APP_ID}|${app_name_id})[^/]*\.svg$" \
                | head -n 1 || true
        )"
    fi

    if [[ -z "${found_icon}" ]]; then
        aim_warn "No se encontró un ícono apropiado."
        aim_cleanup_extract
        return 0
    fi

    case "${found_icon,,}" in
        *.png)
            cp -L "${found_icon}" "${ICON_PATH}"
            ;;
        *.svg)
            if command -v rsvg-convert >/dev/null 2>&1; then
                rsvg-convert -w 256 -h 256 "${found_icon}" -o "${ICON_PATH}"
            elif command -v convert >/dev/null 2>&1; then
                convert -background none -resize 256x256 "${found_icon}" "${ICON_PATH}"
            else
                aim_warn "Se encontró un SVG, pero falta librsvg2-bin o ImageMagick."
            fi
            ;;
        *)
            if file -L "${found_icon}" | grep -qi "PNG image"; then
                cp -L "${found_icon}" "${ICON_PATH}"
            else
                aim_warn "Formato de ícono no compatible: ${found_icon}"
            fi
            ;;
    esac

    [[ -f "${ICON_PATH}" ]] && aim_info "Ícono instalado en ${ICON_PATH}"
    aim_cleanup_extract
}
