import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.brandbooks.soudamini"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.1.12297006"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    // --- 1. LOAD KEY PROPERTIES ---
    val keystoreProperties = Properties()
    val keystorePropertiesFile = rootProject.file("key.properties")
    val hasKeystore = keystorePropertiesFile.exists()
    
    if (hasKeystore) {
        keystoreProperties.load(FileInputStream(keystorePropertiesFile))
    }

    defaultConfig {
        applicationId = "com.brandbooks.soudamini"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // --- 2. DEFINE SIGNING CONFIG ---
    signingConfigs {
        if (hasKeystore) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // --- 3. APPLY SIGNING CONFIG ---
            if (hasKeystore) {
                // Play Store ପାଇଁ ଅରିଜିନାଲ୍ ସିଗ୍ନେଚର୍
                signingConfig = signingConfigs.getByName("release")
            } else {
                // 🚀 SENIOR TRICK: ଯଦି Keystore ନାହିଁ, ତେବେ ଲୋକାଲ୍ ଇନଷ୍ଟଲ୍ ପାଇଁ ଡିବଗ୍ କି ବ୍ୟବହାର କରନ୍ତୁ!
                signingConfig = signingConfigs.getByName("debug")
            }
            
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}