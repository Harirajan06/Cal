## Flutter Local Notifications ProGuard Rules

# Keep generic type information for Gson deserialization
-keepattributes Signature

# Keep Gson-related annotations
-keepattributes *Annotation*

# Keep Gson-specific classes
-keep class com.google.gson.** { *; }

# Keep Flutter Local Notifications plugin classes
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# Also keep the models if they are obfuscated
-keep class com.dexterous.flutterlocalnotifications.models.** { *; }
-keep class com.dexterous.flutterlocalnotifications.NotificationDetails { *; }
-keep class com.dexterous.flutterlocalnotifications.NotificationChannel { *; }

# Ensure GSON is correctly preserved
-keep class com.google.gson.reflect.TypeToken
-keep class * extends com.google.gson.reflect.TypeToken
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# Handle specific ProGuard warning about generic types
-dontwarn com.google.gson.**
