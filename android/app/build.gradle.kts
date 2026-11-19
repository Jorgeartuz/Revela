plugins {
    id("com.android.application")

    id("dev.flutter.flutter-gradle-plugin")
}

val archivoFirma = providers.environmentVariable("REVELA_KEYSTORE_PATH").orNull
val claveAlmacen = providers.environmentVariable("REVELA_KEYSTORE_PASSWORD").orNull
val aliasFirma = providers.environmentVariable("REVELA_KEY_ALIAS").orNull
val claveFirma = providers.environmentVariable("REVELA_KEY_PASSWORD").orNull
val firmaConfigurada = listOf(archivoFirma, claveAlmacen, aliasFirma, claveFirma).all { !it.isNullOrBlank() }

android {
    namespace = "co.edu.cecar.revela"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {

        applicationId = "co.edu.cecar.revela"

        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion

        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (firmaConfigurada) {
            create("release") {
                storeFile = file(archivoFirma!!)
                storePassword = claveAlmacen
                keyAlias = aliasFirma
                keyPassword = claveFirma
            }
        }
    }

    buildTypes {
        release {

            signingConfig = signingConfigs.findByName("release")
        }
    }
}

tasks.configureEach {
    if (name == "packageRelease" || name == "signReleaseBundle") {
        doFirst {
            if (!firmaConfigurada) {
                throw GradleException("Configura REVELA_KEYSTORE_PATH, REVELA_KEYSTORE_PASSWORD, REVELA_KEY_ALIAS y REVELA_KEY_PASSWORD para generar una versión de publicación.")
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
