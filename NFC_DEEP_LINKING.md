# Deep Linking con NFC Tags

## Configuración Implementada

### URL Scheme: `ogl://`

La aplicación ahora soporta deep linking mediante el esquema de URL `ogl://` para abrir cartas específicas mediante tags NFC.

## Formato de URL

```
ogl://card?id=<TAG_ID>
```

Donde `<TAG_ID>` es el identificador único que configures en el campo "Tag ID" de cada carta.

## Ejemplos

- `ogl://card?id=1` - Abre la carta con tagId = "1" (Charizard en los datos de ejemplo)
- `ogl://card?id=2` - Abre la carta con tagId = "2" (Umbreon VMAX)
- `ogl://card?id=celebi-001` - Abre la carta con tagId = "celebi-001"

## Configuración de Cartas

1. Abre la app y edita una carta
2. Ve a la sección "Tag NFC"
3. Ingresa un ID único (ejemplo: "1", "2", "celebi-001")
4. La app mostrará la URL completa: `ogl://card?id=<tu_id>`

## Configuración de Tags NFC

Para programar un tag NFC con iOS/iPhone:

1. **Descarga una app de escritura NFC**:
   - NFC Tools (gratuita)
   - NFC TagWriter
   - Shortcuts (app nativa de Apple)

2. **Programa el tag**:
   - Abre la app de NFC
   - Selecciona "Escribir"
   - Elige "URL/URI"
   - Ingresa: `ogl://card?id=1` (reemplaza "1" con tu ID)
   - Acerca el tag NFC al iPhone para escribirlo

3. **Probar el tag**:
   - Acerca el tag NFC al iPhone
   - iOS detectará automáticamente la URL
   - Mostrará una notificación para abrir con "Prices"
   - La app se abrirá y mostrará la carta correspondiente

## Prueba en Desarrollo (macOS)

Usa el script incluido para probar:

```bash
# Probar con carta ID 1
./test-deeplink.sh 1

# Probar con carta ID 2
./test-deeplink.sh 2

# Probar con ID personalizado
./test-deeplink.sh celebi-001
```

O directamente desde la terminal:

```bash
open "ogl://card?id=1"
```

## Estructura Técnica

### Archivos Modificados

1. **Carta.swift** - Agregado campo `tagId: String?`
2. **CartaEditView.swift** - Sección "Tag NFC" para ingresar el ID
3. **PricesApp.swift** - Manejo de deep links con `onOpenURL`
4. **ContentView.swift** - Búsqueda y presentación de carta por tagId
5. **Info.plist** - Configuración del URL scheme `ogl://`
6. **SampleData.swift** - Datos de ejemplo con tagIds

### Flujo de Funcionamiento

1. iOS/macOS detecta URL con esquema `ogl://`
2. Abre la app Prices
3. `PricesApp.handleDeepLink()` procesa la URL
4. Extrae el parámetro `id` de la query string
5. Pasa el ID a `ContentView` via Binding
6. `ContentView.handleDeepLink()` busca la carta con ese `tagId`
7. Si se encuentra, abre `CartaDetailView` en modal

### Logs de Debug

La app imprime logs útiles en consola:

```
🔗 [DeepLink] URL recibida: ogl://card?id=1
✅ [DeepLink] Card ID encontrado: 1
🔍 [ContentView] Buscando carta con tagId: 1
✅ [ContentView] Carta encontrada: Charizard
```

## Casos de Uso

### 1. Colección Física
- Pega tags NFC en tus cartas físicas
- Al escanear, ves instantáneamente precio, variantes y detalles

### 2. Inventario
- Usa tags NFC en cajas/binders
- Escanea para ver qué cartas contienen

### 3. Ventas
- Muestra información rápida a compradores
- Escanea para mostrar precio actualizado

### 4. Eventos/Torneos
- Escaneo rápido de decks
- Verificación de precios en tiempo real

## Notas

- Los tags NFC deben ser NDEF compatibles
- El ID puede ser cualquier string (números, letras, guiones)
- Asegúrate de que los IDs sean únicos por carta
- En iOS, la detección NFC funciona en background (iOS 13+)
