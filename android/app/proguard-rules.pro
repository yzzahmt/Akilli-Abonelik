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
