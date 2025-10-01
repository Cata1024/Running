import java.util.Properties
import com.android.build.gradle.LibraryExtension

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

// Patch: Fix isar_flutter_libs with AGP 8+ by removing package attr and setting namespace
subprojects {
    if (name == "isar_flutter_libs") {
        plugins.withId("com.android.library") {
            // Configure Android library extension
            val androidExt = extensions.getByType(LibraryExtension::class.java)
            // Asegura compileSdk alto para evitar errores como android:attr/lStar
            androidExt.compileSdk = 35
            // Use the original package name as namespace
            androidExt.namespace = "dev.isar.isar_flutter_libs"

            // Paths for original and patched manifests
            val originalManifest = file("src/main/AndroidManifest.xml")
            val outDirProvider = layout.buildDirectory.dir("patchedManifest")
            val outManifestProvider = outDirProvider.map { it.file("AndroidManifest.xml") }

            // Task to generate a patched manifest without the package attribute
            val patchIsarManifest = tasks.register("patchIsarManifest") {
                inputs.file(originalManifest)
                outputs.file(outManifestProvider)
                doLast {
                    val outFile = outManifestProvider.get().asFile
                    outFile.parentFile.mkdirs()
                    // Write a minimal, valid manifest without package attribute.
                    outFile.writeText(
                        """
                        <manifest xmlns:android="http://schemas.android.com/apk/res/android"/>
                        """.trimIndent()
                    )
                }
            }

            // Point the main sourceSet manifest to the patched file
            androidExt.sourceSets.getByName("main").manifest.srcFile(outManifestProvider.get().asFile)

            // Ensure patch runs before Android preBuild / process manifest tasks
            tasks.configureEach {
                if (name.startsWith("pre") && name.endsWith("Build") || name.contains("ProcessManifest")) {
                    dependsOn(patchIsarManifest)
                }
            }
        }
    }
}

// Asegura compileSdk=35 en TODAS las librerías Android del árbol (defensa adicional)
subprojects {
    plugins.withId("com.android.library") {
        val androidExt = extensions.getByType(LibraryExtension::class.java)
        if (androidExt.compileSdk == null || androidExt.compileSdk!! < 33) {
            androidExt.compileSdk = 35
        }
    }
}
