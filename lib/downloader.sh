#!/usr/bin/env bash

aim_download() {
    local url="$1"
    local destination="$2"

    [[ -n "${url}" ]] || aim_die "La URL no puede estar vacía."
    aim_info "Descargando AppImage desde ${url}"

    if command -v wget >/dev/null 2>&1; then
        wget --show-progress -O "${destination}" "${url}"
    else
        curl -fL --progress-bar "${url}" -o "${destination}"
    fi
}
