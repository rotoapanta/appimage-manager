#!/usr/bin/env bash

aim_help() {
    cat <<'EOF'
AppImage Manager 2.0.1

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
  --from-file RUTA          Instalar desde un archivo AppImage local
  --from-url URL            Descargar e instalar desde una URL

Metadatos opcionales:
  --name NOMBRE             Nombre visible de la aplicación
  --id APP-ID               Identificador interno
  --command COMANDO         Comando para ejecutar la aplicación
  --comment TEXTO           Descripción para el menú
  --category CATEGORÍA      Categoría del menú de aplicaciones
  --no-sandbox              Ejecutar con --no-sandbox
  --with-sandbox            Ejecutar sin añadir --no-sandbox
  --force                   Reemplazar una instalación existente
  --non-interactive         Ejecutar sin preguntas

Ejemplos:

  appimage-manager --install \
    --from-file "$HOME/Descargas/kicad.AppImage" \
    --name "KiCad" \
    --id kicad \
    --command kicad \
    --comment "Diseño electrónico, esquemáticos y PCB" \
    --category "Development;Electronics;"

  appimage-manager --update \
    --id kicad \
    --from-file "$HOME/Descargas/kicad-nuevo.AppImage"

  appimage-manager --remove kicad

  appimage-manager --list

  appimage-manager --info kicad
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

    if [[ -z "${APP_ID}" ]]; then
        APP_ID="$(aim_sanitize_id "${APP_NAME}")"
    else
        APP_ID="$(aim_sanitize_id "${APP_ID}")"
    fi

    if [[ -z "${COMMAND_NAME}" ]]; then
        COMMAND_NAME="${APP_ID}"
    else
        COMMAND_NAME="$(aim_sanitize_id "${COMMAND_NAME}")"
    fi

    if [[ -z "${COMMENT}" ]]; then
        COMMENT="Aplicación instalada mediante AppImage Manager"
    fi

    if [[ "${CATEGORY}" != *";" ]]; then
        CATEGORY="${CATEGORY};"
    fi

    aim_set_paths
}

aim_clean_incomplete_installation() {
    # Una instalación válida debe contener al menos metadata.env y el AppImage.
    if [[ -d "${APP_INSTALL_DIR}" ]] \
        && { [[ ! -f "${METADATA_PATH}" ]] || [[ ! -f "${APPIMAGE_PATH}" ]]; }; then

        aim_warn "Se encontró una instalación incompleta de ${APP_ID}."
        aim_warn "Limpiando archivos residuales antes de continuar."

        rm -rf "${APP_INSTALL_DIR}"
        rm -f "${WRAPPER_PATH}"
        rm -f "${DESKTOP_PATH}"
        rm -f "${ICON_PATH}"

        aim_refresh_desktop
    fi
}

aim_install_or_update() {
    aim_require_commands
    aim_create_base_dirs

    if [[ "${ACTION}" == "update" ]]; then
        local requested_source_type="${SOURCE_TYPE}"
        local requested_source_value="${SOURCE_VALUE}"
        local requested_id="${APP_ID}"

        [[ -n "${requested_id}" ]] \
            || aim_die "Para actualizar debes indicar --id APP-ID."

        [[ -n "${requested_source_type}" && -n "${requested_source_value}" ]] \
            || aim_die "Para actualizar debes indicar --from-file o --from-url."

        aim_load_metadata "$(aim_sanitize_id "${requested_id}")"

        SOURCE_TYPE="${requested_source_type}"
        SOURCE_VALUE="${requested_source_value}"

        aim_set_paths
    else
        aim_prepare_metadata
        aim_clean_incomplete_installation
    fi

    [[ -n "${SOURCE_TYPE}" && -n "${SOURCE_VALUE}" ]] \
        || aim_die "Debes indicar --from-file o --from-url."

    # Una aplicación solamente se considera instalada cuando tiene
    # metadata.env y application.AppImage.
    if [[ "${ACTION}" == "install" ]] \
        && [[ -f "${METADATA_PATH}" ]] \
        && [[ -f "${APPIMAGE_PATH}" ]] \
        && [[ "${FORCE}" != true ]]; then

        aim_die "La aplicación ${APP_ID} ya está instalada. Usa --force o --update."
    fi

    # Con --force se eliminan los archivos administrados anteriormente.
    if [[ "${ACTION}" == "install" && "${FORCE}" == true ]]; then
        aim_warn "Reemplazando la instalación existente de ${APP_ID}."

        rm -rf "${APP_INSTALL_DIR}"
        rm -f "${WRAPPER_PATH}"
        rm -f "${DESKTOP_PATH}"
        rm -f "${ICON_PATH}"
    fi

    mkdir -p "${APP_INSTALL_DIR}"

    local staged_appimage
    staged_appimage="${APP_INSTALL_DIR}/application.AppImage.new"

    rm -f "${staged_appimage}"

    aim_info "Preparando instalación de ${APP_NAME}."

    aim_copy_source "${staged_appimage}"
    aim_validate_appimage "${staged_appimage}"

    mv -f "${staged_appimage}" "${APPIMAGE_PATH}"
    chmod +x "${APPIMAGE_PATH}"

    # El ícono debe instalarse antes de generar el archivo .desktop.
    aim_install_icon
    aim_create_wrapper
    aim_create_desktop_entry
    aim_save_metadata
    aim_refresh_desktop
    aim_ensure_path

    if [[ "${ACTION}" == "update" ]]; then
        aim_info "${APP_NAME} actualizado correctamente."
        printf '\nAplicación actualizada correctamente.\n'
    else
        aim_info "${APP_NAME} instalado correctamente."
        printf '\nAplicación instalada correctamente.\n'
    fi

    printf '\n'
    printf 'Nombre:     %s\n' "${APP_NAME}"
    printf 'ID:         %s\n' "${APP_ID}"
    printf 'Comando:    %s\n' "${COMMAND_NAME}"
    printf 'AppImage:   %s\n' "${APPIMAGE_PATH}"
    printf 'Lanzador:   %s\n' "${WRAPPER_PATH}"
    printf 'Desktop:    %s\n' "${DESKTOP_PATH}"

    if [[ -f "${ICON_PATH}" ]]; then
        printf 'Ícono:      %s\n' "${ICON_PATH}"
    else
        printf 'Ícono:      no extraído\n'
    fi

    printf '\n'
}

aim_remove() {
    local requested_id="$1"

    [[ -n "${requested_id}" ]] \
        || aim_die "Debes indicar el APP-ID que deseas eliminar."

    requested_id="$(aim_sanitize_id "${requested_id}")"

    local app_directory
    local metadata_file

    app_directory="${AIM_BASE_DIR}/${requested_id}"
    metadata_file="${app_directory}/metadata.env"

    # Permite limpiar una carpeta residual aunque no exista metadata.env.
    if [[ -d "${app_directory}" && ! -f "${metadata_file}" ]]; then
        aim_warn "Se encontró una instalación incompleta de ${requested_id}."
        rm -rf "${app_directory}"
        aim_refresh_desktop

        printf "Los residuos de '%s' fueron eliminados.\n" "${requested_id}"
        return 0
    fi

    aim_load_metadata "${requested_id}"

    rm -f "${WRAPPER_PATH}"
    rm -f "${DESKTOP_PATH}"
    rm -f "${ICON_PATH}"
    rm -rf "${APP_INSTALL_DIR}"

    aim_refresh_desktop

    aim_info "Aplicación eliminada: ${APP_ID}"
    printf "Aplicación '%s' eliminada correctamente.\n" "${APP_NAME}"
}

aim_list() {
    aim_create_base_dirs

    local metadata_file
    local found=false

    printf '%-24s %-30s %-20s\n' \
        "APP-ID" \
        "NOMBRE" \
        "COMANDO"

    printf '%s\n' \
        "--------------------------------------------------------------------------"

    shopt -s nullglob

    for metadata_file in "${AIM_BASE_DIR}"/*/metadata.env; do
        if [[ ! -f "${metadata_file}" ]]; then
            continue
        fi

        (
            # shellcheck disable=SC1090
            source "${metadata_file}"

            local installed_appimage
            installed_appimage="$(
                dirname "${metadata_file}"
            )/application.AppImage"

            if [[ -f "${installed_appimage}" ]]; then
                printf '%-24s %-30s %-20s\n' \
                    "${META_APP_ID}" \
                    "${META_APP_NAME}" \
                    "${META_COMMAND_NAME}"
            fi
        )

        found=true
    done

    shopt -u nullglob

    if [[ "${found}" == false ]]; then
        printf "No hay aplicaciones administradas.\n"
    fi
}

aim_info_command() {
    local requested_id="$1"

    [[ -n "${requested_id}" ]] \
        || aim_die "Debes indicar el APP-ID."

    aim_load_metadata "$(aim_sanitize_id "${requested_id}")"

    printf '%s\n' \
        "----------------------------------------------------------------"

    printf 'Nombre:       %s\n' "${APP_NAME}"
    printf 'ID:           %s\n' "${APP_ID}"
    printf 'Comando:      %s\n' "${COMMAND_NAME}"
    printf 'Categoría:    %s\n' "${CATEGORY}"
    printf 'Comentario:   %s\n' "${COMMENT}"
    printf 'AppImage:     %s\n' "${APPIMAGE_PATH}"
    printf 'Lanzador:     %s\n' "${WRAPPER_PATH}"
    printf 'Desktop:      %s\n' "${DESKTOP_PATH}"
    printf 'Ícono:        %s\n' "${ICON_PATH}"

    if [[ -f "${APPIMAGE_PATH}" ]]; then
        printf 'Estado:       instalado\n'
    else
        printf 'Estado:       instalación incompleta\n'
    fi

    printf '%s\n' \
        "----------------------------------------------------------------"
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
            --install)
                ACTION="install"
                shift
                ;;

            --update)
                ACTION="update"
                shift
                ;;

            --remove)
                ACTION="remove"

                [[ $# -ge 2 ]] \
                    || aim_die "Falta APP-ID después de --remove."

                APP_ID="$2"
                shift 2
                ;;

            --list)
                ACTION="list"
                shift
                ;;

            --info)
                ACTION="info"

                [[ $# -ge 2 ]] \
                    || aim_die "Falta APP-ID después de --info."

                APP_ID="$2"
                shift 2
                ;;

            --from-file)
                [[ $# -ge 2 ]] \
                    || aim_die "Falta la ruta después de --from-file."

                SOURCE_TYPE="file"
                SOURCE_VALUE="$2"
                shift 2
                ;;

            --from-url)
                [[ $# -ge 2 ]] \
                    || aim_die "Falta la URL después de --from-url."

                SOURCE_TYPE="url"
                SOURCE_VALUE="$2"
                shift 2
                ;;

            --name)
                [[ $# -ge 2 ]] \
                    || aim_die "Falta el nombre después de --name."

                APP_NAME="$2"
                shift 2
                ;;

            --id)
                [[ $# -ge 2 ]] \
                    || aim_die "Falta el ID después de --id."

                APP_ID="$2"
                shift 2
                ;;

            --command)
                [[ $# -ge 2 ]] \
                    || aim_die "Falta el comando después de --command."

                COMMAND_NAME="$2"
                shift 2
                ;;

            --comment)
                [[ $# -ge 2 ]] \
                    || aim_die "Falta el comentario después de --comment."

                COMMENT="$2"
                shift 2
                ;;

            --category)
                [[ $# -ge 2 ]] \
                    || aim_die "Falta la categoría después de --category."

                CATEGORY="$2"
                shift 2
                ;;

            --no-sandbox)
                NO_SANDBOX=true
                shift
                ;;

            --with-sandbox)
                NO_SANDBOX=false
                shift
                ;;

            --force)
                FORCE=true
                shift
                ;;

            --non-interactive)
                NON_INTERACTIVE=true
                shift
                ;;

            --help|-h)
                aim_help
                exit 0
                ;;

            --version|-v)
                printf '%s %s\n' "${AIM_NAME}" "${AIM_VERSION}"
                exit 0
                ;;

            *)
                aim_die "Opción no válida: $1. Usa --help."
                ;;
        esac
    done
}

aim_main() {
    aim_parse_args "$@"

    case "${ACTION}" in
        install|update)
            aim_install_or_update
            ;;

        remove)
            aim_remove "${APP_ID}"
            ;;

        list)
            aim_list
            ;;

        info)
            aim_info_command "${APP_ID}"
            ;;

        "")
            aim_help
            ;;

        *)
            aim_die "Acción no válida."
            ;;
    esac
}
