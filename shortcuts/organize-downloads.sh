#!/bin/zsh
#
# Organize Downloads
# Ordena los archivos sueltos de ~/Downloads en subcarpetas por tipo.
#
# Categorias (nombres en ingles):
#   Documents   pdf, docx, doc, xlsx, xls, pptx, ppt, txt, md, csv,
#               pages, numbers, key, rtf
#   Images      png, jpg, jpeg, gif, heic, webp, svg, bmp, tiff
#   Video       mp4, mov, m4v, avi, mkv, webm
#   Archives    zip, tar, gz, tgz, bz2, rar, 7z
#   Installers  dmg, pkg, img, iso  (y cualquier archivo grande, ver BIG_MB)
#   Data        json, jsonl, xml, drawio, html, yaml, yml, sql
#   Other       todo lo demas
#
# Reglas:
#   - Solo archivos sueltos del nivel superior (no entra en subcarpetas).
#   - No mueve las subcarpetas existentes.
#   - Los archivos de BIG_MB o mas van a Installers (para agrupar los gigantes).
#   - Mueve, nunca borra. Maneja colisiones con sufijo (1), (2), etc.
#
# Uso:
#   DRY_RUN=1 ./organize-downloads.sh   # resumen por categoria, no mueve
#   ./organize-downloads.sh             # ordena de verdad
#   MIN_DIAS=7 ./organize-downloads.sh  # solo archivos con mas de 7 dias
#
# Se puede incrustar en la app Atajos con "Ejecutar script de shell".

set -euo pipefail

ORIGEN="$HOME/Downloads"
DRY_RUN="${DRY_RUN:-0}"
MIN_DIAS="${MIN_DIAS:-0}"          # 0 = sin filtro; N = solo archivos con >N dias
BIG_MB="${BIG_MB:-1024}"           # archivos de este tamano (MB) o mas -> Installers

# Categorias que este script gestiona (para no re-mover lo ya ordenado).
CATEGORIAS=(Documents Images Video Archives Installers Data Other)

if [[ ! -d "$ORIGEN" ]]; then
  echo "La carpeta de origen no existe: $ORIGEN"
  exit 0
fi

# Devuelve la categoria segun la extension (en minusculas).
categoria_por_ext() {
  case "$1" in
    pdf|docx|doc|xlsx|xls|pptx|ppt|txt|md|csv|pages|numbers|key|rtf) echo "Documents" ;;
    png|jpg|jpeg|gif|heic|webp|svg|bmp|tiff)                          echo "Images" ;;
    mp4|mov|m4v|avi|mkv|webm)                                         echo "Video" ;;
    zip|tar|gz|tgz|bz2|rar|7z)                                        echo "Archives" ;;
    dmg|pkg|img|iso)                                                  echo "Installers" ;;
    json|jsonl|xml|drawio|html|yaml|yml|sql)                          echo "Data" ;;
    *)                                                                echo "Other" ;;
  esac
}

big_bytes=$(( BIG_MB * 1024 * 1024 ))

# Filtro opcional de antiguedad.
mtime_arg=()
if (( MIN_DIAS > 0 )); then
  mtime_arg=(-mtime +$((MIN_DIAS - 1)))
fi

typeset -A cuenta   # conteo por categoria
typeset -A bytes    # bytes por categoria
movidos=0

while IFS= read -r -d '' archivo; do
  nombre="${archivo:t}"
  ext="${nombre:e:l}"                    # extension en minusculas
  tam=$(stat -f '%z' "$archivo")         # tamano en bytes

  # Sin extension util -> Other.
  if [[ "$ext" == "$nombre" || -z "$ext" ]]; then
    cat="Other"
  else
    cat="$(categoria_por_ext "$ext")"
  fi

  # Los archivos grandes van a Installers.
  if (( tam >= big_bytes )); then
    cat="Installers"
  fi

  if [[ "$DRY_RUN" == "1" ]]; then
    cuenta[$cat]=$(( ${cuenta[$cat]:-0} + 1 ))
    bytes[$cat]=$(( ${bytes[$cat]:-0} + tam ))
    movidos=$((movidos + 1))
    continue
  fi

  destino_dir="$ORIGEN/$cat"
  mkdir -p "$destino_dir"
  destino_final="$destino_dir/$nombre"

  if [[ -e "$destino_final" ]]; then
    base="${nombre:r}"
    e="${nombre:e}"
    n=1
    while [[ -e "$destino_dir/${base} (${n}).${e}" ]]; do
      n=$((n + 1))
    done
    destino_final="$destino_dir/${base} (${n}).${e}"
  fi

  mv "$archivo" "$destino_final"
  movidos=$((movidos + 1))
done < <(
  find "$ORIGEN" -maxdepth 1 -type f ! -name '.*' "${mtime_arg[@]}" -print0
)

if [[ "$DRY_RUN" == "1" ]]; then
  echo "== Simulacion: archivos sueltos que se ordenarian en $ORIGEN =="
  for c in "${CATEGORIAS[@]}"; do
    n=${cuenta[$c]:-0}
    (( n == 0 )) && continue
    mb=$(( ${bytes[$c]:-0} / 1024 / 1024 ))
    printf "  %-11s %4d archivos  (%d MB)\n" "$c" "$n" "$mb"
  done
  echo "Total: $movidos archivos"
else
  echo "Listo. Archivos ordenados: $movidos  ->  subcarpetas por tipo en $ORIGEN"
fi
