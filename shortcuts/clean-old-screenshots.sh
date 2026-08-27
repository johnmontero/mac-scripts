#!/bin/zsh
#
# Limpiar Capturas Antiguas
# Elimina las capturas de ~/Pictures/Screenshots/Temp con más de N días
# de antiguedad (por fecha de modificacion).
#
# Por seguridad, por defecto los archivos se envian a la PAPELERA
# (recuperables). Para borrado permanente, usa la variable PERMANENTE=1.
#
# Uso:
#   ./limpiar-capturas-antiguas.sh              # a la Papelera, umbral 7 dias
#   DIAS=14 ./limpiar-capturas-antiguas.sh      # cambia el umbral de dias
#   DRY_RUN=1 ./limpiar-capturas-antiguas.sh    # solo muestra, no borra
#   PERMANENTE=1 ./limpiar-capturas-antiguas.sh # borrado permanente (rm)
#
# Se puede incrustar en la app Atajos con "Ejecutar script de shell".

set -euo pipefail

# --- Configuracion (ajustable por variables de entorno) ---
DIAS="${DIAS:-7}"                 # antiguedad minima en dias
ORIGEN="$HOME/Pictures/Screenshots/Temp"
DRY_RUN="${DRY_RUN:-0}"           # 1 = solo simular
PERMANENTE="${PERMANENTE:-0}"     # 1 = borrar con rm en vez de Papelera

# Solo se eliminan IMAGENES. Los videos/grabaciones nunca se tocan aqui.
EXTENSIONES=(png jpg jpeg gif heic webp tiff bmp)
find_ext_args=()
for ext in "${EXTENSIONES[@]}"; do
  if (( ${#find_ext_args} > 0 )); then
    find_ext_args+=(-o)
  fi
  find_ext_args+=(-iname "*.${ext}")
done

# Envia un archivo a la Papelera usando Finder (conserva "devolver").
enviar_a_papelera() {
  local ruta="$1"
  osascript -e "tell application \"Finder\" to delete (POSIX file \"$ruta\")" >/dev/null
}

if [[ ! -d "$ORIGEN" ]]; then
  echo "La carpeta de origen no existe: $ORIGEN"
  exit 0
fi

eliminados=0

# find con -mtime +N selecciona archivos con mas de N*24h de antiguedad.
# -print0 / read -d '' maneja nombres con espacios de forma segura.
while IFS= read -r -d '' archivo; do
  if [[ "$DRY_RUN" == "1" ]]; then
    echo "[simulacion] se eliminaria: ${archivo:t}"
  elif [[ "$PERMANENTE" == "1" ]]; then
    rm -f -- "$archivo"
    echo "Borrado permanente: ${archivo:t}"
  else
    enviar_a_papelera "$archivo"
    echo "Enviado a la Papelera: ${archivo:t}"
  fi
  eliminados=$((eliminados + 1))
done < <(find "$ORIGEN" -type f -mtime +"$DIAS" \( "${find_ext_args[@]}" \) -print0)

if [[ "$DRY_RUN" == "1" ]]; then
  echo "Simulacion terminada. Coincidencias: $eliminados (umbral: >${DIAS} dias)"
else
  echo "Listo. Archivos eliminados: $eliminados (umbral: >${DIAS} dias)"
fi
