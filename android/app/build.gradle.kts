import java.util.Properties
import java.io.FileInputStream

// Load release signing credentials from the gitignored key.properties file.
// This file must NOT be committed to version control.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "frnd.buzz"
    compileSdk = 37
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String? ?: error("keyAlias missing in key.properties")
            keyPassword = keystoreProperties["keyPassword"] as String? ?: error("keyPassword missing in key.properties")
            storeFile = keystoreProperties["storeFile"]?.let { file(it as String) }
                ?: error("storeFile missing in key.properties")
            storePassword = keystoreProperties["storePassword"] as String? ?: error("storePassword missing in key.properties")
        }
    }

    defaultConfig {
        applicationId = "frnd.buzz"
        // See: https://flutter.dev/to/review-gradle-config
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Use the release keystore defined above for all distribution builds.
            // NEVER revert this to signingConfigs.getByName("debug").
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }

    applicationVariants.all {
        val variantName = name
        outputs.all {
            if (this is com.android.build.gradle.internal.api.BaseVariantOutputImpl) {
                outputFileName = if (variantName == "release") "frnd-buzz.apk" else "frnd-buzz-${variantName}.apk"
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

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    // Firebase BoM is intentionally NOT included here.
    // Flutter's Firebase plugins (firebase_core, cloud_firestore, firebase_messaging)
    // manage their own compatible native Android SDK versions via pub.dev.
    // Adding a separate BoM causes version conflicts and NoSuchMethodError crashes.
}
