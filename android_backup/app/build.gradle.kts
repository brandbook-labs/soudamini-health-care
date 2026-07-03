import java.util.Properties
import java.io.FileInputStream

// ... plugins block stays at the top ...

android {
    namespace = "website.jivan.jivanapp" // CHECK THIS: Match your package name!
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    // 1. Load the key.properties file
    val keystoreProperties = Properties()
    val keystorePropertiesFile = rootProject.file("key.properties")
    if (keystorePropertiesFile.exists()) {
        keystoreProperties.load(FileInputStream(keystorePropertiesFile))
    }

    defaultConfig {
        applicationId = "website.jivan.jivanapp" // CHECK THIS: Match your package name!
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // 2. Define the Signing Configs
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

    // 3. Use the config in Build Types
    buildTypes {
        release {
            // This links to the config created above
            signingConfig = signingConfigs.getByName("release")
            
            // Disable shrinking to fix the R8 errors
            isMinifyEnabled = false 
            isShrinkResources = false
            
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}