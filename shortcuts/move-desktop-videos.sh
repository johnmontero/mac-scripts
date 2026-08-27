#!/bin/zsh
#
# Move Desktop Videos
# Mueve los videos sueltos del Escritorio (~/Desktop), incluidas las
# grabaciones de pantalla, a ~/Movies/Desktop/AÑO/MES/ segun la fecha de
# modificacion de cada archivo.
#
# - Solo archivos sueltos del nivel superior del Escritorio (no subcarpetas).
# - Solo formatos de video (mov, mp4, m4v, m4p, avi, mkv).
# - Maneja colisiones de nombre agregando un sufijo (1), (2), etc.
#
# Uso:
#   ./move-desktop-videos.sh              # mueve todos los videos
#   DRY_RUN=1 ./move-desktop-videos.sh    # solo muestra un resumen, no mueve
#   MIN_DIAS=1 ./move-desktop-videos.sh   # solo videos con mas de 1 dia
#
# Se puede incrustar en la app Atajos con "Ejecutar script de shell".

set -euo pipefail

ORIGEN="$HOME/Desktop"
DESTINO_BASE="$HOME/Movies/Desktop"
DRY_RUN="${DRY_RUN:-0}"
MIN_DIAS="${MIN_DIAS:-0}"   # 0 = sin filtro; N = solo archivos con >N dias

# Extensiones de video a considerar (sin distinguir mayusculas/minusculas).
EXTENSIONES=(mov mp4 m4v m4p avi mkv)

if [[ ! -d "$ORIGEN" ]]; then
  echo "La carpeta de origen no existe: $ORIGEN"
  exit 0
fi

# Filtro opcional de antiguedad. MIN_DIAS=1 => -mtime +0 (mas de ~1 dia).
mtime_arg=()
if (( MIN_DIAS > 0 )); then
  mtime_arg=(-mtime +$((MIN_DIAS - 1)))
fi

# Construye los argumentos -iname '*.ext' -o ... para find (sin -o sobrante).
find_args=()
for ext in "${EXTENSIONES[@]}"; do
  if (( ${#find_args} > 0 )); then
    find_args+=(-o)
  fi
  find_args+=(-iname "*.${ext}")
done

typeset -A resumen   # conteo por AÑO/MES (para el modo simulacion)
movidos=0

while IFS= read -r -d '' archivo; do
  aniomes="$(stat -f '%Sm' -t '%Y/%m' "$archivo")"
  destino_dir="$DESTINO_BASE/$aniomes"

  if [[ "$DRY_RUN" == "1" ]]; then
    resumen[$aniomes]=$(( ${resumen[$aniomes]:-0} + 1 ))
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
  movidos=$((movidos + 1))
done < <(find "$ORIGEN" -maxdepth 1 -type f "${mtime_arg[@]}" \( "${find_args[@]}" \) -print0)

if [[ "$DRY_RUN" == "1" ]]; then
  echo "== Simulacion: videos que se moverian a $DESTINO_BASE =="
  for k in ${(ok)resumen}; do
    echo "  $k : ${resumen[$k]}"
  done
  echo "Total: $movidos"
else
  echo "Listo. Videos movidos: $movidos  ->  $DESTINO_BASE/AÑO/MES"
fi
