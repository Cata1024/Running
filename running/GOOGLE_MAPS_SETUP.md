# Territory Run - Configuración de Google Maps

## 🗺️ Configurar Google Maps API

Para usar Google Maps en la aplicación, necesitas obtener una API Key de Google Cloud Platform.

### 1. Obtener Google Maps API Key

1. Ve a [Google Cloud Console](https://console.cloud.google.com/)
2. Crea un nuevo proyecto o selecciona uno existente
3. Habilita las siguientes APIs:
   - **Maps SDK for Android**
   - **Maps SDK for iOS**
   - **Geocoding API** (opcional, para futuras funciones)

4. Ve a "Credenciales" > "Crear credenciales" > "Clave de API"
5. Copia la API Key generada

### 2. Configurar la API Key en la aplicación

#### Android
Edita el archivo: `android/app/src/main/AndroidManifest.xml`

Reemplaza `YOUR_API_KEY_HERE` con tu API Key real:
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="TU_API_KEY_AQUI"/>
```

#### iOS
Edita el archivo: `ios/Runner/Info.plist`

Reemplaza `YOUR_API_KEY_HERE` con tu API Key real:
```xml
<key>GMSApiKey</key>
<string>TU_API_KEY_AQUI</string>
```

#### Código Dart (opcional)
Edita el archivo: `lib/core/constants.dart`

Reemplaza `YOUR_API_KEY_HERE` con tu API Key real:
```dart
static const String googleMapsApiKey = 'TU_API_KEY_AQUI';
```

### 3. Restricciones de Seguridad (Recomendado)

En Google Cloud Console, ve a tu API Key y configura restricciones:

**Para Android:**
- Tipo: "Aplicaciones para Android"
- Añadir: `com.example.running` (o tu package name)

**Para iOS:**
- Tipo: "Aplicaciones para iOS"
- Añadir el Bundle ID de tu app iOS

### 4. Instalar dependencias

Una vez configurado Flutter, ejecuta:
```bash
flutter pub get
```

### ⚠️ Importante
- **NO** subas tu API Key al control de versiones
- Considera usar variables de entorno para mayor seguridad
- Las API Keys tienen cuota gratuita, pero revisa los límites en Google Cloud

## 🚀 Ventajas de Google Maps

- ✅ **Mejor calidad de mapas** y imágenes satelitales
- ✅ **Más confiable** que OpenStreetMap
- ✅ **Mejor rendimiento** en dispositivos móviles
- ✅ **Integración nativa** con el ecosistema Google
- ✅ **Soporte oficial** de Google para Flutter
- ✅ **Funciones avanzadas**: Street View, Places API, etc.

## 📱 Funcionalidades incluidas

- 🗺️ Mapa interactivo con zoom y desplazamiento
- 📍 Marcadores personalizados para inicio y posición actual
- 🛣️ Polilíneas para mostrar la ruta de carrera
- 🧭 Botón "Mi ubicación" integrado
- 🎯 Detección automática de ubicación GPS