#!/usr/bin/env bash
set -Eeuo pipefail

rm -f "${HOME}/.local/bin/appimage-manager"
rm -rf "${HOME}/.local/share/appimage-manager"

echo "AppImage Manager fue eliminado."
echo "Las aplicaciones administradas permanecen instaladas."
echo "Para eliminarlas, usa --remove antes de desinstalar el gestor."
