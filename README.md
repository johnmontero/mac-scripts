# mac-scripts

Colección de scripts de automatización para macOS, pensados para usarse solos
desde la terminal o incrustados en la app **Atajos** (Shortcuts) mediante la
acción "Ejecutar script de shell".

## Estructura

```
mac-scripts/
├── shortcuts/   # scripts invocados desde la app Atajos
├── lib/         # utilidades compartidas (opcional)
└── README.md
```

## Scripts

### shortcuts/classify-screenshots.sh

Revisa la carpeta `~/Pictures/Screenshots/Temp` y mueve a
`~/Pictures/Screenshots/Permanent` cada archivo que tenga la etiqueta (tag) de
Finder **"Azul"**.

- Lee los tags con `mdls` (mismas etiquetas que ves en Finder).
- Crea la carpeta destino si no existe.
- Evita sobrescribir: si el nombre ya existe en destino, agrega un sufijo `(1)`, `(2)`, etc.

Uso directo:

```sh
~/development/tools/mac-scripts/shortcuts/classify-screenshots.sh
```

### shortcuts/clean-old-screenshots.sh

Elimina de `~/Pictures/Screenshots/Temp` las capturas con más de N días de
antigüedad (por fecha de modificación). Por defecto son 7 días.

- Solo actúa sobre **imágenes** (png, jpg, jpeg, gif, heic, webp, tiff, bmp);
  nunca toca videos ni grabaciones de pantalla.
- Por seguridad, envía los archivos a la **Papelera** (recuperables), no los
  borra de forma permanente.
- Configurable por variables de entorno:
  - `DIAS=14` cambia el umbral de días.
  - `DRY_RUN=1` solo muestra qué se eliminaría, sin borrar.
  - `PERMANENTE=1` borra de forma permanente con `rm` en vez de la Papelera.

Uso directo:

```sh
~/development/tools/mac-scripts/shortcuts/clean-old-screenshots.sh
DIAS=14 ~/development/tools/mac-scripts/shortcuts/clean-old-screenshots.sh
DRY_RUN=1 ~/development/tools/mac-scripts/shortcuts/clean-old-screenshots.sh
```

### shortcuts/move-desktop-images.sh

Mueve las imágenes sueltas del Escritorio (`~/Desktop`) a
`~/Pictures/Desktop/AÑO/MES/` según la fecha de modificación de cada archivo.

- Solo archivos del nivel superior del Escritorio (no entra en subcarpetas).
- Formatos: png, jpg, jpeg, gif, heic, webp, tiff, bmp.
- Maneja colisiones de nombre con sufijo `(1)`, `(2)`.
- `DRY_RUN=1` muestra un resumen por año/mes sin mover nada.
- `MIN_DIAS=N` archiva solo imágenes con más de N días (para no llevarse las
  recién puestas). Sin la variable, mueve todas.

```sh
DRY_RUN=1 ~/development/tools/mac-scripts/shortcuts/move-desktop-images.sh
MIN_DIAS=1 ~/development/tools/mac-scripts/shortcuts/move-desktop-images.sh
~/development/tools/mac-scripts/shortcuts/move-desktop-images.sh
```

### shortcuts/move-desktop-videos.sh

Igual que el anterior pero para videos (incluidas grabaciones de pantalla).
Mueve a `~/Movies/Desktop/AÑO/MES/`.

- Formatos: mov, mp4, m4v, m4p, avi, mkv.
- `DRY_RUN=1` muestra un resumen por año/mes sin mover nada.
- `MIN_DIAS=N` archiva solo videos con más de N días. Sin la variable, mueve todos.

```sh
DRY_RUN=1 ~/development/tools/mac-scripts/shortcuts/move-desktop-videos.sh
MIN_DIAS=1 ~/development/tools/mac-scripts/shortcuts/move-desktop-videos.sh
~/development/tools/mac-scripts/shortcuts/move-desktop-videos.sh
```

> Nota: las capturas y las grabaciones de pantalla comparten la misma ubicación
> de guardado (Cmd+Shift+5 → Opciones → Guardar en, o
> `defaults write com.apple.screencapture location <ruta>`). En este equipo está
> configurada en `~/Pictures/Screenshots/Temp`.

### shortcuts/move-temp-recordings.sh

Saca las grabaciones de pantalla (y otros videos) de
`~/Pictures/Screenshots/Temp` y las mueve a `~/Movies/Screen Recordings/AÑO/MES/`.

Contexto: en macOS las capturas y las grabaciones comparten la misma ubicación
de guardado, así que ambas nacen en `Temp`. Este script separa las grabaciones
a una carpeta permanente para que **no** las alcance la limpieza de 7 días
(que además ya solo borra imágenes).

- Formatos: mov, mp4, m4v, m4p, avi, mkv.
- `DRY_RUN=1` simula sin mover.

```sh
DRY_RUN=1 ~/development/tools/mac-scripts/shortcuts/move-temp-recordings.sh
~/development/tools/mac-scripts/shortcuts/move-temp-recordings.sh
```

## Ejecución automática (launchd)

Cinco `LaunchAgent` de macOS mantienen el orden a diario (en este orden):

- `launchd/com.johnmontero.classify-screenshots.plist` — mueve las capturas con
  tag **"Azul"** de `Temp` a `Permanent`. A las **08:50** (antes de la limpieza,
  para que lo marcado no se borre). Log: `~/Library/Logs/classify-screenshots.log`
- `launchd/com.johnmontero.move-temp-recordings.plist` — mueve grabaciones de
  `Temp` a `~/Movies/Screen Recordings/AÑO/MES`. A las **08:55**.
  Log: `~/Library/Logs/move-temp-recordings.log`
- `launchd/com.johnmontero.clean-old-screenshots.plist` — borra imágenes de más
  de 7 días de `Temp`. A las **09:00** (después del enrutado de grabaciones).
  Log: `~/Library/Logs/clean-old-screenshots.log`
- `launchd/com.johnmontero.archive-desktop-images.plist` — archiva imágenes del
  Escritorio (más de 1 día, vía `MIN_DIAS=1`) en `~/Pictures/Desktop/AÑO/MES`.
  A las **09:05**. Log: `~/Library/Logs/archive-desktop-images.log`
- `launchd/com.johnmontero.archive-desktop-videos.plist` — archiva videos del
  Escritorio (más de 1 día, vía `MIN_DIAS=1`) en `~/Movies/Desktop/AÑO/MES`.
  A las **09:07**. Log: `~/Library/Logs/archive-desktop-videos.log`

Instalación / actualización (repetir por cada plist):

```sh
for p in launchd/*.plist; do
  cp "$p" ~/Library/LaunchAgents/
  launchctl unload ~/Library/LaunchAgents/"${p:t}" 2>/dev/null
  launchctl load ~/Library/LaunchAgents/"${p:t}"
done
```

Comandos útiles:

```sh
launchctl list | grep clean-old-screenshots   # ver si está cargado
launchctl start com.johnmontero.clean-old-screenshots  # ejecutar ahora
launchctl unload ~/Library/LaunchAgents/com.johnmontero.clean-old-screenshots.plist  # desactivar
```

> Nota: la primera vez que el script tenga que enviar algo a la Papelera,
> macOS puede pedir permiso para controlar Finder (Ajustes del Sistema →
> Privacidad y seguridad → Automatización). Conviene ejecutarlo una vez de
> forma manual para conceder ese permiso.

## Cómo enlazar un script con la app Atajos

1. Abre Atajos y crea un atajo nuevo.
2. Agrega la acción **"Ejecutar script de shell"** (Run Shell Script).
   - Si no aparece: menú Atajos → Ajustes → Avanzado → activa
     "Permitir ejecutar scripts".
3. Configura:
   - Shell: `zsh`
   - Cuerpo: la ruta al script, entre comillas. Por ejemplo:
     ```
     "$HOME/development/tools/mac-scripts/shortcuts/classify-screenshots.sh"
     ```
4. Nombra el atajo (por ejemplo, `Clasificar Capturas`) y guarda.

> Nota: Atajos en macOS no expone las etiquetas de Finder en sus acciones de
> archivo (ni en "Detalles del archivo" ni en "Filtrar archivos"), por eso el
> filtrado por tag se resuelve dentro del script.

## Requisitos

- macOS con `zsh` (predeterminado) y las herramientas del sistema `mdls` / `mv`.
