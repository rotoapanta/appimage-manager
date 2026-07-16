#!/usr/bin/env bash

aim_create_base_dirs() {
    mkdir -p \
        "${AIM_BASE_DIR}" \
        "${AIM_BIN_DIR}" \
        "${AIM_DESKTOP_DIR}" \
        "${AIM_ICON_DIR}" \
        "${AIM_STATE_DIR}"
}

aim_require_commands() {
    local missing=()
    local cmd

    for cmd in chmod cp mkdir find mktemp rm cat tee date head basename sed grep tr mv file; do
        command -v "${cmd}" >/dev/null 2>&1 || missing+=("${cmd}")
    done

    if ! command -v wget >/dev/null 2>&1 && ! command -v curl >/dev/null 2>&1; then
        missing+=("wget o curl")
    fi

    [[ ${#missing[@]} -eq 0 ]] || aim_die "Faltan dependencias: ${missing[*]}"
}

aim_sanitize_id() {
    local value="$1"

    value="$(printf '%s' "${value}" \
        | tr '[:upper:]' '[:lower:]' \
        | sed -E 's/[^a-z0-9._-]+/-/g; s/^-+//; s/-+$//; s/-+/-/g')"

    [[ -n "${value}" ]] || aim_die "No se pudo generar un identificador válido."
    printf '%s' "${value}"
}

aim_derive_name_from_file() {
    local name
    name="$(basename "$1")"
    name="${name%.AppImage}"
    name="${name%.appimage}"
    name="$(printf '%s' "${name}" \
        | sed -E 's/[-_](x86_64|amd64|aarch64|arm64).*//I; s/[-_][0-9]+([.][0-9A-Za-z]+)*.*$//')"
    [[ -n "${name}" ]] || name="AppImage Application"
    printf '%s' "${name}"
}

aim_refresh_desktop() {
    if command -v update-desktop-database >/dev/null 2>&1; then
        update-desktop-database "${AIM_DESKTOP_DIR}" >/dev/null 2>&1 || true
    fi

    if command -v gtk-update-icon-cache >/dev/null 2>&1; then
        gtk-update-icon-cache -f -t "${AIM_ICON_BASE_DIR}" >/dev/null 2>&1 || true
    fi
}

aim_ensure_path() {
    if [[ ":${PATH}:" != *":${AIM_BIN_DIR}:"* ]]; then
        aim_warn "${AIM_BIN_DIR} no está incluido en PATH."
        printf '\nAñade esta línea a ~/.bashrc:\n'
        printf 'export PATH="$HOME/.local/bin:$PATH"\n\n'
    fi
}
