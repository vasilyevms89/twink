import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localPropertiesFile.reader(Charsets.UTF_8).use { reader ->
        localProperties.load(reader)
    }
}

val storeFile = file("C:\\Users\\vasil\\StudioProjects\\Lumos_GT\\twink\\android\\app\\upload-keystore.jks")
val storePassword = localProperties.getProperty("storePassword")
val keyAlias = localProperties.getProperty("keyAlias")
val keyPassword = localProperties.getProperty("keyPassword")

android {
    namespace = "com.example.twink"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.twink"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            storeFile = file("upload-keystore.jks")
            storePassword = storePassword
            keyAlias = keyAlias
            keyPassword = keyPassword
            storePassword = storePassword ?: "" // password!
            keyAlias = keyAlias ?: "upload"
            keyPassword = keyPassword ?: "" // password!
        }
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            //signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = true // misha
            isShrinkResources = true // misha
            signingConfig = signingConfigs.getByName("release") //mishaf
        }
    }
}

flutter {
    source = "../.."
}
