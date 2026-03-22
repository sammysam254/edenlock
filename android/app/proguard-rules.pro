# Eden ProGuard Rules

# Keep Device Admin Receiver
-keep class ke.edenservices.eden.EdenDeviceAdminReceiver { *; }

# Keep all activities
-keep class ke.edenservices.eden.MainActivity { *; }
-keep class ke.edenservices.eden.LockoutActivity { *; }

# Keep Supabase client
-keep class ke.edenservices.eden.SupabaseClient { *; }

# Keep WorkManager
-keep class * extends androidx.work.Worker
-keep class * extends androidx.work.CoroutineWorker

# Kotlin Coroutines
-keepnames class kotlinx.coroutines.internal.MainDispatcherFactory {}
-keepnames class kotlinx.coroutines.CoroutineExceptionHandler {}
-keepclassmembernames class kotlinx.** {
    volatile <fields>;
}

# JSON parsing
-keepattributes *Annotation*
-keepclassmembers class * {
    @org.json.* <methods>;
}

# Keep line numbers for debugging
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile
