import java.io.FileInputStream
import java.util.Properties

buildscript {
    // Development without Firebase must not resolve its optional build plugins.
    if (providers.gradleProperty("enableFirebase").orNull == "true") {
        repositories {
            google()
            mavenCentral()
        }
        dependencies {
            classpath("com.google.gms:google-services:4.5.0")
            classpath("com.google.firebase:firebase-crashlytics-gradle:3.0.7")
        }
    }
}

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Firebase is enabled only with an explicit build opt-in and a matching config.
val firebaseEnabled = providers.gradleProperty("enableFirebase").orNull == "true"
if (firebaseEnabled) {
    val configFile = file("google-services.json")
    require(configFile.exists()) { "Provide Gerehrah google-services.json before enabling Firebase." }
    val config = groovy.json.JsonSlurper().parse(configFile) as? Map<*, *>
    val clients = config?.get("client") as? List<*> ?: emptyList<Any?>()
    require(clients.any {
        val info = (it as? Map<*, *>)?.get("client_info") as? Map<*, *>
        val androidInfo = info?.get("android_client_info") as? Map<*, *>
        androidInfo?.get("package_name") == "com.damostudio.gerehrah"
    }) { "Firebase configuration must contain an Android client for com.damostudio.gerehrah." }
    apply(plugin = "com.google.gms.google-services")
    apply(plugin = "com.google.firebase.crashlytics")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseSigning = keystorePropertiesFile.exists()
if (hasReleaseSigning) {
    FileInputStream(keystorePropertiesFile).use(keystoreProperties::load)
}

android {
    namespace = "com.damostudio.gerehrah"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.damostudio.gerehrah"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            if (hasReleaseSigning) {
                signingConfig = signingConfigs.getByName("release")
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
