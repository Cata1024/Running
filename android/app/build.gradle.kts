import java.util.Properties

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localPropertiesFile.inputStream().use { stream ->
        localProperties.load(stream)
    }
}

fun loadEnvMap(file: File): Map<String, String> {
    if (!file.exists()) return emptyMap()
    val map = mutableMapOf<String, String>()
    file.readLines(Charsets.UTF_8).forEach { rawLine ->
        val line = rawLine.trim()
        if (line.isEmpty() || line.startsWith("#")) return@forEach
        val separatorIndex = line.indexOf('=')
        if (separatorIndex <= 0) return@forEach
        val key = line.substring(0, separatorIndex).trim()
        val value = line.substring(separatorIndex + 1).trim()
        if (key.isNotEmpty()) {
            map[key] = value
        }
    }
    return map
}

val envFile = rootProject.file("../.env")
val envMap = loadEnvMap(envFile)

if (envMap.isEmpty()) {
    println("[Running] GOOGLE_MAPS_API_KEY not found in ${envFile.absolutePath} (file missing or empty).")
}

val googleMapsApiKey = localProperties.getProperty("googleMapsApiKey")
    ?: envMap["GOOGLE_MAPS_API_KEY"]
    ?: ""

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("keystore.properties")
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use { stream ->
        keystoreProperties.load(stream)
    }
}

android {
    namespace = "com.cata1024.running"
    // Plugins (geolocator, maps, etc.) requieren compilar con SDK 36
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

    compileOptions {
        // Actualiza a Java 21
        sourceCompatibility = JavaVersion.VERSION_21
        targetCompatibility = JavaVersion.VERSION_21
    }

    kotlinOptions {
        // Genera bytecode para JVM 21
        jvmTarget = JavaVersion.VERSION_21.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
    applicationId = "com.cata1024.running"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        check(googleMapsApiKey.isNotBlank()) {
            "GOOGLE_MAPS_API_KEY is missing. Provide it via local.properties or .env"
        }

        manifestPlaceholders["googleMapsApiKey"] = googleMapsApiKey
        manifestPlaceholders["applicationActivity"] = "com.cata1024.running.MainActivity"
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}

// Forzar toolchain de Kotlin/Java a JDK 21
kotlin {
    jvmToolchain(21)
}
