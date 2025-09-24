# IAhorro

IAhorro es una aplicación iOS construida con SwiftUI que digitaliza boletas y facturas usando IA para clasificar gastos personales. Esta versión incluye:

- Captura de boletas desde archivos, biblioteca de fotos o cámara.
- Procesamiento asistido por OpenAI (con modo sin conexión) para extraer metadatos, palabras clave y categorías.
- Almacenamiento local cifrable mediante el gestor de archivos del dispositivo.
- Resúmenes de gastos por categoría, palabras clave destacadas y respuestas conversacionales.

## Requisitos

- Xcode 15 o superior.
- iOS 17 como destino mínimo.
- Configura las claves de OpenAI en `Info.plist` (`OPENAI_API_KEY` y opcionalmente `OPENAI_ORG_ID`) para habilitar el análisis avanzado. Sin clave la app usará un modo local degradado.

## Configuración

1. Abre `IAhorro.xcodeproj` en Xcode.
2. Reemplaza los valores de API en el esquema si deseas usar OpenAI.
3. Ejecuta las pruebas con `Cmd + U`.

## Pruebas

Se incluyen pruebas unitarias para el servicio de procesamiento de boletas y el almacenamiento local. Ejecuta:

```bash
xcodebuild test -scheme IAhorro -destination 'platform=iOS Simulator,name=iPhone 15'
```

## Seguridad

- Los archivos se almacenan en `Application Support/Receipts` y pueden sincronizarse con iCloud si se habilita en el proyecto.
- No se envían datos a OpenAI si no se proporcionan credenciales.

## Licencia

MIT
