#!/usr/bin/env bash

aim_help() {
    cat <<'EOF'
AppImage Manager 2.0.0

Uso:
  appimage-manager [acción] [opciones]

Acciones:
  --install                 Instalar una AppImage
  --update                  Actualizar una aplicación
  --remove APP-ID           Desinstalar una aplicación
  --list                    Listar aplicaciones instaladas
  --info APP-ID             Mostrar información
  --help                    Mostrar ayuda
  --version                 Mostrar versión

Fuente:
  --from-file RUTA
  --from-url URL

Metadatos opcionales:
  --name NOMBRE
  --id APP-ID
  --command COMANDO
  --comment TEXTO
  --category CATEGORÍA
  --no-sandbox
  --with-sandbox
  --force
  --non-interactive
EOF
}

aim_prepare_metadata() {
    if [[ -z "${APP_NAME}" ]]; then
        if [[ "${SOURCE_TYPE}" == "file" ]]; then
            APP_NAME="$(aim_derive_name_from_file "${SOURCE_VALUE}")"
        else
            APP_NAME="AppImage Application"
        fi
    fi

    APP_ID="$(aim_sanitize_id "${APP_ID:-${APP_NAME}}")"
    COMMAND_NAME="$(aim_sanitize_id "${COMMAND_NAME:-${APP_ID}}")"
    [[ -n "${COMMENT}" ]] || COMMENT="Aplicación instalada mediante AppImage Manager"
    [[ "${CATEGORY}" == *";" ]] || CATEGORY="${CATEGORY};"
    aim_set_paths
}

aim_install_or_update() {
    aim_require_commands
    aim_create_base_dirs

    if [[ "${ACTION}" == "update" ]]; then
        local requested_source_type="${SOURCE_TYPE}"
        local requested_source_value="${SOURCE_VALUE}"
        aim_load_metadata "$(aim_sanitize_id "${APP_ID}")"
        SOURCE_TYPE="${requested_source_type}"
        SOURCE_VALUE="${requested_source_value}"
    else
        aim_prepare_metadata
    fi

    [[ -n "${SOURCE_TYPE}" && -n "${SOURCE_VALUE}" ]] || aim_die "Debes indicar --from-file o --from-url."

    if [[ -d "${APP_INSTALL_DIR}" && "${ACTION}" == "install" && "${FORCE}" != true ]]; then
        aim_die "La aplicación ${APP_ID} ya existe. Usa --force o --update."
    fi

    mkdir -p "${APP_INSTALL_DIR}"
    local staged="${APP_INSTALL_DIR}/application.AppImage.new"
    rm -f "${staged}"

    aim_copy_source "${staged}"
    aim_validate_appimage "${staged}"
    mv -f "${staged}" "${APPIMAGE_PATH}"
    chmod +x "${APPIMAGE_PATH}"

    aim_install_icon
    aim_create_wrapper
    aim_create_desktop_entry
    aim_save_metadata
    aim_refresh_desktop
    aim_ensure_path

    aim_info "${APP_NAME} instalado correctamente."
    printf '\nNombre:   %s\nID:       %s\nComando:  %s\nAppImage: %s\n\n' \
        "${APP_NAME}" "${APP_ID}" "${COMMAND_NAME}" "${APPIMAGE_PATH}"
}

aim_remove() {
    aim_load_metadata "$(aim_sanitize_id "$1")"
    rm -f "${WRAPPER_PATH}" "${DESKTOP_PATH}" "${ICON_PATH}"
    rm -rf "${APP_INSTALL_DIR}"
    aim_refresh_desktop
    aim_info "Aplicación eliminada: ${APP_ID}"
    printf "Aplicación '%s' eliminada correctamente.\n" "${APP_NAME}"
}

aim_list() {
    aim_create_base_dirs
    local metadata found=false

    printf '%-24s %-30s %-20s\n' "APP-ID" "NOMBRE" "COMANDO"
    printf '%s\n' "----------------------------------------------------------------"

    shopt -s nullglob
    for metadata in "${AIM_BASE_DIR}"/*/metadata.env; do
        found=true
        (
            # shellcheck disable=SC1090
            source "${metadata}"
            printf '%-24s %-30s %-20s\n' \
                "${META_APP_ID}" "${META_APP_NAME}" "${META_COMMAND_NAME}"
        )
    done
    shopt -u nullglob

    [[ "${found}" == true ]] || printf "No hay aplicaciones administradas.\n"
}

aim_info_command() {
    aim_load_metadata "$(aim_sanitize_id "$1")"
    printf 'Nombre:      %s\nID:          %s\nComando:     %s\nCategoría:   %s\nComentario:  %s\nAppImage:    %s\nLanzador:    %s\nDesktop:     %s\nÍcono:       %s\n' \
        "${APP_NAME}" "${APP_ID}" "${COMMAND_NAME}" "${CATEGORY}" "${COMMENT}" \
        "${APPIMAGE_PATH}" "${WRAPPER_PATH}" "${DESKTOP_PATH}" "${ICON_PATH}"
}

aim_parse_args() {
    ACTION=""
    SOURCE_TYPE=""
    SOURCE_VALUE=""
    APP_NAME=""
    APP_ID=""
    COMMAND_NAME=""
    CATEGORY="Utility;"
    COMMENT=""
    NO_SANDBOX="auto"
    FORCE=false
    NON_INTERACTIVE=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --install) ACTION="install"; shift ;;
            --update) ACTION="update"; shift ;;
            --remove) ACTION="remove"; APP_ID="${2:-}"; shift 2 ;;
            --list) ACTION="list"; shift ;;
            --info) ACTION="info"; APP_ID="${2:-}"; shift 2 ;;
            --from-file) SOURCE_TYPE="file"; SOURCE_VALUE="${2:-}"; shift 2 ;;
            --from-url) SOURCE_TYPE="url"; SOURCE_VALUE="${2:-}"; shift 2 ;;
            --name) APP_NAME="${2:-}"; shift 2 ;;
            --id) APP_ID="${2:-}"; shift 2 ;;
            --command) COMMAND_NAME="${2:-}"; shift 2 ;;
            --comment) COMMENT="${2:-}"; shift 2 ;;
            --category) CATEGORY="${2:-}"; shift 2 ;;
            --no-sandbox) NO_SANDBOX=true; shift ;;
            --with-sandbox) NO_SANDBOX=false; shift ;;
            --force) FORCE=true; shift ;;
            --non-interactive) NON_INTERACTIVE=true; shift ;;
            --help|-h) aim_help; exit 0 ;;
            --version|-v) printf '%s %s\n' "${AIM_NAME}" "${AIM_VERSION}"; exit 0 ;;
            *) aim_die "Opción no válida: $1" ;;
        esac
    done
}

aim_main() {
    aim_parse_args "$@"

    case "${ACTION}" in
        install|update) aim_install_or_update ;;
        remove) [[ -n "${APP_ID}" ]] || aim_die "Falta APP-ID."; aim_remove "${APP_ID}" ;;
        list) aim_list ;;
        info) [[ -n "${APP_ID}" ]] || aim_die "Falta APP-ID."; aim_info_command "${APP_ID}" ;;
        "") aim_help ;;
        *) aim_die "Acción no válida." ;;
    esac
}
