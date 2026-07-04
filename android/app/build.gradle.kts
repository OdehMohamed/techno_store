import java.util.Properties

import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services") 
}

val keystoreProperties = Properties()

val keystorePropertiesFile = rootProject.file("key.properties")

if (keystorePropertiesFile.exists()) {

    keystoreProperties.load(FileInputStream(keystorePropertiesFile))

}

android {
    namespace = "com.mohamedodeh.technostore"
    compileSdk = 36

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    signingConfigs {

        create("release") {

            keyAlias = keystoreProperties["keyAlias"] as String

            keyPassword = keystoreProperties["keyPassword"] as String

            storeFile = keystoreProperties["storeFile"]?.let { file(it) }

            storePassword = keystoreProperties["storePassword"] as String

        }

    }

    defaultConfig {
        applicationId = "com.mohamedodeh.technostore"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

   buildTypes {

        release {

            signingConfig = signingConfigs.getByName("release")

        }

    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:32.7.0"))
    implementation("com.google.firebase:firebase-auth")
}
