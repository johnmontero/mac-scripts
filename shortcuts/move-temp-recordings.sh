#!/bin/zsh
#
# Move Temp Recordings
# Saca las grabaciones de pantalla (y otros videos) de la carpeta temporal
# ~/Pictures/Screenshots/Temp y las mueve a una carpeta permanente
# ~/Movies/Screen Recordings/AÑO/MES/ segun su fecha de modificacion.
#
# Objetivo: como las capturas y las grabaciones comparten la misma ubicacion
# de guardado en macOS, este script separa las grabaciones para que NO las
# alcance la limpieza automatica de la carpeta Temp.
#
# - Solo formatos de video (mov, mp4, m4v, m4p, avi, mkv).
# - Maneja colisiones de nombre agregando un sufijo (1), (2), etc.
#
# Uso:
#   ./move-temp-recordings.sh
#   DRY_RUN=1 ./move-temp-recordings.sh   # solo muestra, no mueve
#
# Se puede incrustar en la app Atajos con "Ejecutar script de shell".

set -euo pipefail

ORIGEN="$HOME/Pictures/Screenshots/Temp"
DESTINO_BASE="$HOME/Movies/Screen Recordings"
DRY_RUN="${DRY_RUN:-0}"

EXTENSIONES=(mov mp4 m4v m4p avi mkv)

if [[ ! -d "$ORIGEN" ]]; then
  echo "La carpeta de origen no existe: $ORIGEN"
  exit 0
fi

# Construye los argumentos -iname '*.ext' -o ... para find (sin -o sobrante).
find_args=()
for ext in "${EXTENSIONES[@]}"; do
  if (( ${#find_args} > 0 )); then
    find_args+=(-o)
  fi
  find_args+=(-iname "*.${ext}")
done

movidos=0

while IFS= read -r -d '' archivo; do
  aniomes="$(stat -f '%Sm' -t '%Y/%m' "$archivo")"
  destino_dir="$DESTINO_BASE/$aniomes"

  if [[ "$DRY_RUN" == "1" ]]; then
    echo "[simulacion] se moveria: ${archivo:t}  ->  $destino_dir/"
    movidos=$((movidos + 1))
    continue
  fi

  mkdir -p "$destino_dir"
  destino_final="$destino_dir/${archivo:t}"

  if [[ -e "$destino_final" ]]; then
    base="${archivo:t:r}"
    ext="${archivo:t:e}"
    n=1
    while [[ -e "$destino_dir/${base} (${n}).${ext}" ]]; do
      n=$((n + 1))
    done
    destino_final="$destino_dir/${base} (${n}).${ext}"
  fi

  mv "$archivo" "$destino_final"
  echo "Movido: ${archivo:t}  ->  $destino_final"
  movidos=$((movidos + 1))
done < <(find "$ORIGEN" -maxdepth 1 -type f \( "${find_args[@]}" \) -print0)

if [[ "$DRY_RUN" == "1" ]]; then
  echo "Simulacion terminada. Grabaciones que se moverian: $movidos"
else
  echo "Listo. Grabaciones movidas: $movidos  ->  $DESTINO_BASE/AÑO/MES"
fi
