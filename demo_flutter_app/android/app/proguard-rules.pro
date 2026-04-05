# ProGuard rules for Supabase/Postgrest/Flutter
# Keep model classes (adjust package/class names as needed)
-keep class io.supabase.** { *; }
-keep class io.postgrest.** { *; }
-keep class com.supabase.** { *; }
-keep class com.postgrest.** { *; }
-keep class org.json.** { *; }
-keep class kotlinx.serialization.** { *; }
-keep class kotlin.** { *; }
-keep class dart.** { *; }
# Keep all Flutter plugin registrant classes
-keep class io.flutter.plugins.** { *; }
# Keep all Dart model classes (if using codegen)
-keep class *.models.** { *; }
# Add more rules as needed for your models/libraries
