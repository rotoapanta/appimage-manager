#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="${HOME}/.local/share/appimage-manager"
BIN="${HOME}/.local/bin/appimage-manager"

mkdir -p "${DEST}" "${HOME}/.local/bin"
rm -rf "${DEST:?}"/*
cp -R "${PROJECT_ROOT}/bin" "${PROJECT_ROOT}/lib" "${PROJECT_ROOT}/templates" "${DEST}/"

cat > "${BIN}" <<EOF
#!/usr/bin/env bash
export APPIMAGE_MANAGER_ROOT="${DEST}"
exec "${DEST}/bin/appimage-manager" "\$@"
EOF

chmod +x "${BIN}" "${DEST}/bin/appimage-manager"

echo "AppImage Manager instalado."
echo "Comando: appimage-manager"
echo
echo 'Si no se reconoce, añade a ~/.bashrc:'
echo 'export PATH="$HOME/.local/bin:$PATH"'
