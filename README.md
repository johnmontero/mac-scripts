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

## Ejecución automática (launchd)

El script `clean-old-screenshots.sh` se ejecuta a diario mediante un
`LaunchAgent` de macOS.

- Definición versionada: `launchd/com.johnmontero.clean-old-screenshots.plist`
- Programación: todos los días a las 09:00.
- Log de ejecución: `~/Library/Logs/clean-old-screenshots.log`

Instalación / actualización:

```sh
cp launchd/com.johnmontero.clean-old-screenshots.plist ~/Library/LaunchAgents/
launchctl unload ~/Library/LaunchAgents/com.johnmontero.clean-old-screenshots.plist 2>/dev/null
launchctl load ~/Library/LaunchAgents/com.johnmontero.clean-old-screenshots.plist
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
