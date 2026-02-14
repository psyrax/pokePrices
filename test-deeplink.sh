#!/bin/bash
# Script para probar deep links NFC
# Uso: ./test-deeplink.sh [card_id]
# Ejemplo: ./test-deeplink.sh 1

CARD_ID=${1:-1}
URL="ogl://card?id=$CARD_ID"

echo "🔗 Abriendo deep link: $URL"
open "$URL"
