#!/bin/zsh
#
# Move Desktop Images
# Mueve las imagenes sueltas del Escritorio (~/Desktop) a
# ~/Pictures/Desktop/AÑO/MES/ segun la fecha de modificacion de cada archivo.
#
# - Solo archivos sueltos del nivel superior del Escritorio (no subcarpetas).
# - Solo formatos de imagen (png, jpg, jpeg, gif, heic, webp, tiff, bmp).
# - Maneja colisiones de nombre agregando un sufijo (1), (2), etc.
#
# Uso:
#   ./move-desktop-images.sh              # mueve todas las imagenes
#   DRY_RUN=1 ./move-desktop-images.sh    # solo muestra un resumen, no mueve
#   MIN_DIAS=1 ./move-desktop-images.sh   # solo imagenes con mas de 1 dia
#
# Se puede incrustar en la app Atajos con "Ejecutar script de shell".

set -euo pipefail

ORIGEN="$HOME/Desktop"
DESTINO_BASE="$HOME/Pictures/Desktop"
DRY_RUN="${DRY_RUN:-0}"
MIN_DIAS="${MIN_DIAS:-0}"   # 0 = sin filtro; N = solo archivos con >N dias

# Extensiones de imagen a considerar (sin distinguir mayusculas/minusculas).
EXTENSIONES=(png jpg jpeg gif heic webp tiff bmp)

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
  # AÑO/MES a partir de la fecha de modificacion del archivo.
  aniomes="$(stat -f '%Sm' -t '%Y/%m' "$archivo")"
  destino_dir="$DESTINO_BASE/$aniomes"

  if [[ "$DRY_RUN" == "1" ]]; then
    resumen[$aniomes]=$(( ${resumen[$aniomes]:-0} + 1 ))
    movidos=$((movidos + 1))
    continue
  fi

  mkdir -p "$destino_dir"
  destino_final="$destino_dir/${archivo:t}"

  # Evita sobrescribir: agrega sufijo numerico si ya existe.
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
  echo "== Simulacion: imagenes que se moverian a $DESTINO_BASE =="
  for k in ${(ok)resumen}; do
    echo "  $k : ${resumen[$k]}"
  done
  echo "Total: $movidos"
else
  echo "Listo. Imagenes movidas: $movidos  ->  $DESTINO_BASE/AÑO/MES"
fi
