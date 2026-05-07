# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# AdMob
-keep public class com.google.android.gms.ads.** {
   public *;
}

# Sqflite
-keep class net.sqlcipher.** { *; }
-keep class org.sqlite.** { *; }

# Google Play Core (Fixes R8 missing classes error)
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# Flutter R8 / ProGuard
-dontwarn io.flutter.embedding.engine.deferredcomponents.**
-keep class io.flutter.embedding.engine.deferredcomponents.** { *; }
