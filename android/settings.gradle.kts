// Remove conflicting ANDROID_PREFS_ROOT environment variable to prevent AndroidLocationsException
try {
    val env = System.getenv()
    val field = env.javaClass.getDeclaredField("m")
    field.isAccessible = true
    @Suppress("UNCHECKED_CAST")
    val map = field.get(env) as MutableMap<String, String>
    map.remove("ANDROID_PREFS_ROOT")
} catch (e: Throwable) {
    try {
        val env = System.getenv()
        val field = env.javaClass.getDeclaredField("theEnvironment")
        field.isAccessible = true
        @Suppress("UNCHECKED_CAST")
        val map = field.get(env) as MutableMap<String, String>
        map.remove("ANDROID_PREFS_ROOT")
    } catch (e2: Throwable) {
        // Ignore
    }
}

pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.9.1" apply false
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
    id("com.google.gms.google-services") version "4.5.0" apply false
}

include(":app")
