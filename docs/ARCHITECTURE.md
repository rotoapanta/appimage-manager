# Arquitectura

## Objetivo

Administrar aplicaciones AppImage sin privilegios de administrador y sin mezclar la lógica de descarga, instalación, integración de escritorio y eliminación.

## Flujo de instalación

1. Validación de dependencias.
2. Copia o descarga del AppImage.
3. Validación del archivo ELF.
4. Extracción temporal.
5. Detección del directorio `AppDir` o `squashfs-root`.
6. Extracción del ícono.
7. Creación del wrapper.
8. Creación del archivo `.desktop`.
9. Registro de metadatos.
10. Actualización de cachés.

## Limitaciones

El gestor solo administra archivos AppImage. No sustituye a `apt`, `dnf`, `pacman`, Flatpak o Snap.
