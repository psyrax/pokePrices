#!/bin/bash

# Tamaños necesarios para iOS
sizes=(20 29 40 58 60 76 80 87 120 152 167 180 1024)

for size in "${sizes[@]}"; do
    sips -z $size $size icon_1024.png --out "Prices/Assets.xcassets/AppIcon.appiconset/icon_${size}.png" > /dev/null 2>&1
    echo "✅ Generado: icon_${size}.png"
done

echo "🎨 Todos los iconos generados"
