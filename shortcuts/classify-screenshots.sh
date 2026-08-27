#!/bin/zsh
#
# Clasificar Capturas
# Mueve las capturas con la etiqueta (tag) "Azul" desde Temp a Permanent.
#
# Uso:
#   ./clasificar-capturas.sh
#
# También se puede incrustar en la app Atajos con la acción
# "Ejecutar script de shell".

set -euo pipefail

TAG="Azul"
ORIGEN="$HOME/Pictures/Screenshots/Temp"
DESTINO="$HOME/Pictures/Screenshots/Permanent"

# Asegura que la carpeta destino exista.
mkdir -p "$DESTINO"

movidos=0

# Recorre cada elemento de la carpeta de origen.
# 'setopt null_glob' evita errores si la carpeta está vacía.
setopt null_glob
for archivo in "$ORIGEN"/*; do
  # Solo procesa archivos regulares.
  [[ -f "$archivo" ]] || continue

  # Lee las etiquetas del archivo.
  etiquetas="$(mdls -name kMDItemUserTags "$archivo" 2>/dev/null)"

  # Si las etiquetas contienen "Azul", mueve el archivo.
  if print -r -- "$etiquetas" | grep -q -- "$TAG"; then
    destino_final="$DESTINO/$(basename "$archivo")"

    # Evita sobrescribir: si ya existe, agrega un sufijo numérico.
    if [[ -e "$destino_final" ]]; then
      base="${archivo:t:r}"
      ext="${archivo:t:e}"
      n=1
      while [[ -e "$DESTINO/${base} (${n}).${ext}" ]]; do
        n=$((n + 1))
      done
      destino_final="$DESTINO/${base} (${n}).${ext}"
    fi

    mv "$archivo" "$destino_final"
    echo "Movido: ${archivo:t}  ->  $destino_final"
    movidos=$((movidos + 1))
  fi
done

echo "Listo. Archivos movidos: $movidos"
