#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="${HOME}/.local/share/appimage-manager"
BIN="${HOME}/.local/bin/appimage-manager"

mkdir -p "${DEST}" "${HOME}/.local/bin"

rm -rf "${DEST:?}"/*

cp -R \
    "${PROJECT_ROOT}/bin" \
    "${PROJECT_ROOT}/lib" \
    "${DEST}/"

if [[ -d "${PROJECT_ROOT}/templates" ]]; then
    cp -R "${PROJECT_ROOT}/templates" "${DEST}/"
fi

cat > "${BIN}" <<EOF
#!/usr/bin/env bash
export APPIMAGE_MANAGER_ROOT="${DEST}"
exec "${DEST}/bin/appimage-manager" "\$@"
EOF

chmod +x "${BIN}"
chmod +x "${DEST}/bin/appimage-manager"

echo
echo "AppImage Manager instalado correctamente."
echo
echo "Comando disponible:"
echo "  appimage-manager"
echo
echo "Verifica con:"
echo "  appimage-manager --version"
echo

if [[ ":${PATH}:" != *":${HOME}/.local/bin:"* ]]; then
    echo "Aviso: ~/.local/bin no está incluido en PATH."
    echo
    echo "Ejecuta:"
    echo '  echo '\''export PATH="$HOME/.local/bin:$PATH"'\'' >> ~/.bashrc'
    echo "  source ~/.bashrc"
    echo
fi
