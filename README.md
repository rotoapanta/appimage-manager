# AppImage Manager

Gestor modular para instalar, actualizar, listar y eliminar **cualquier aplicación distribuida como AppImage**.

No instala paquetes `.deb`, `.rpm`, Flatpak, Snap ni programas compilados desde código fuente. Su alcance es cualquier programa que se distribuya como archivo `.AppImage`, por ejemplo:

- KiCad
- FreeCAD
- Arduino IDE
- PrusaSlicer
- OrcaSlicer
- Obsidian
- balenaEtcher
- aplicaciones Electron distribuidas como AppImage

## Instalación del gestor

```bash
unzip appimage-manager-professional.zip
cd appimage-manager-professional
chmod +x install.sh uninstall.sh bin/appimage-manager
./install.sh
```

Comprueba:

```bash
appimage-manager --version
```

## Instalar KiCad

```bash
appimage-manager --install \
  --from-file "$HOME/Descargas/kicad-10.0.4-x86_64.AppImage" \
  --name "KiCad" \
  --id kicad \
  --command kicad \
  --comment "Diseño electrónico, esquemáticos y PCB" \
  --category "Development;Electronics;"
```

Abrir:

```bash
kicad
```

Actualizar:

```bash
appimage-manager --update \
  --id kicad \
  --from-file "$HOME/Descargas/kicad-10.0.5-x86_64.AppImage"
```

Eliminar:

```bash
appimage-manager --remove kicad
```

## Operaciones generales

```bash
appimage-manager --list
appimage-manager --info kicad
appimage-manager --help
```

## Instalación desde URL

```bash
appimage-manager --install \
  --from-url "URL_DIRECTA_DEL_APPIMAGE" \
  --name "Nombre de la aplicación" \
  --id aplicacion \
  --command aplicacion
```

## Ubicaciones utilizadas

```text
~/.local/opt/appimage-manager/<app-id>/application.AppImage
~/.local/bin/<comando>
~/.local/share/applications/<app-id>.desktop
~/.local/share/icons/hicolor/256x256/apps/<app-id>.png
~/.local/state/appimage-manager/appimage-manager.log
```

## Arquitectura

El proyecto separa las responsabilidades en módulos:

- `commands.sh`: interfaz de comandos.
- `appimage.sh`: validación y extracción.
- `icon.sh`: detección e instalación del ícono.
- `desktop.sh`: acceso del menú.
- `wrapper.sh`: comando ejecutable.
- `metadata.sh`: registro de aplicaciones.
- `downloader.sh`: descarga desde URL.
- `logger.sh`: logs.
- `utils.sh`: utilidades comunes.

Consulta `docs/ARCHITECTURE.md`.
