# 🏃 Territory Run

App de running con tracking GPS y conquista de territorio.

## 🚀 Características

- 📍 Tracking GPS en tiempo real
- 🗺️ Visualización de rutas en Google Maps
- 🔄 Detección automática de circuitos cerrados
- 📐 Cálculo de área conquistada
- 📊 Historial de carreras con filtros
- 🔥 Sincronización con Firebase/Firestore
- 🎨 UI moderna con Material 3

## 📋 Requisitos

- Flutter 3.24+
- Dart 3.5+
- Android SDK 36
- Java 21

## 🛠️ Setup

1. **Clonar el repositorio**
```bash
git clone <repo-url>
cd Running
```

2. **Instalar dependencias**
```bash
flutter pub get
```

3. **Configurar Firebase**
   - Crear proyecto en [Firebase Console](https://console.firebase.google.com)
   - Agregar app Android
   - Descargar `google-services.json` → `android/app/`
   - Habilitar Authentication (Email/Password)
   - Habilitar Firestore Database

4. **Configurar Google Maps**
   - Obtener API Key de [Google Cloud Console](https://console.cloud.google.com)
   - Crear archivo `.env` en la raíz:
   ```
   GOOGLE_MAPS_API_KEY=tu_api_key_aqui
   ```

5. **Ejecutar**
```bash
flutter run
```

## 📦 Generar APK

```bash
flutter build apk --release
```

APK generado en: `build/app/outputs/flutter-apk/app-release.apk`

## 📱 Uso

1. **Registrarse/Iniciar sesión**
2. **Tab "Correr"** → Iniciar tracking
3. **Correr** con GPS activado
4. **Detener** al finalizar
5. **Ver historial** de carreras

## 🏗️ Arquitectura

- **Presentation**: Screens + Widgets (UI)
- **Domain**: Models + Services (Lógica de negocio)
- **Data**: Providers (Estado con Riverpod)
- **Core**: Utilidades compartidas

Ver `ARCHITECTURE.md` para más detalles.

## 🔑 Permisos Necesarios

- Ubicación (GPS)
- Internet
- Almacenamiento (para compartir)

## 📚 Tecnologías

- Flutter/Dart
- Firebase (Auth + Firestore)
- Google Maps
- Geolocator
- Riverpod (State Management)

## 📄 Licencia

Proyecto educativo

---

**Desarrollado con ❤️ usando Flutter**
