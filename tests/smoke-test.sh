#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

"${ROOT}/bin/appimage-manager" --version
"${ROOT}/bin/appimage-manager" --help >/dev/null

echo "Prueba básica completada."
