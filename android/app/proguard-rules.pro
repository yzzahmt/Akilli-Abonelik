# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Flutter R8 / ProGuard
-dontwarn io.flutter.embedding.engine.deferredcomponents.**
-keep class io.flutter.embedding.engine.deferredcomponents.** { *; }

# AdMob / Google Mobile Ads
-keep public class com.google.android.gms.ads.** {
   public *;
}
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Sqflite / SQLite
-keep class net.sqlcipher.** { *; }
-keep class org.sqlite.** { *; }

# Google Play Core (Fixes R8 missing classes error)
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# RevenueCat / purchases_flutter v10+
-keep class com.revenuecat.purchases.** { *; }
-keepclassmembers class com.revenuecat.purchases.** { *; }

# Google Play Billing Library (in_app_purchase)
-keep class com.android.billingclient.api.** { *; }
-keep class com.android.vending.billing.** { *; }
-dontwarn com.revenuecat.**
-keep class com.revenuecat.purchases_flutter.** { *; }
-keepclassmembers class com.revenuecat.purchases_flutter.** { *; }

# home_widget
-keep class es.antonborri.home_widget.** { *; }
-keepclassmembers class es.antonborri.home_widget.** { *; }

# Glance (home_widget dependency)
-keep class androidx.glance.** { *; }
-keep class androidx.glance.appwidget.** { *; }
-dontwarn androidx.glance.**

# flutter_local_notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keepclassmembers class com.dexterous.flutterlocalnotifications.** { *; }

# share_plus
-keep class dev.fluttercommunity.plus.share.** { *; }

# file_picker
-keep class com.mr.flutter.plugin.filepicker.** { *; }

# package_info_plus
-keep class dev.fluttercommunity.plus.packageinfo.** { *; }

# url_launcher
-keep class io.flutter.plugins.urllauncher.** { *; }

# permission_handler
-keep class com.baseflow.permissionhandler.** { *; }

# google_fonts
-keep class com.google.android.gms.fonts.** { *; }

# flutter_riverpod
-keep class hooks.riverpod.** { *; }
-keep class riverpod.** { *; }
-keepclassmembers class * extends riverpod.Notifier { *; }

# Kotlin Coroutines
-keepnames class kotlinx.coroutines.internal.MainDispatcherFactory {}
-keepnames class kotlinx.coroutines.CoroutineExceptionHandler {}
-keepclassmembernames class kotlinx.** {
    volatile <fields>;
}
-dontwarn kotlinx.coroutines.**

# Kotlin Serialization
-keepattributes *Annotation*, InnerClasses
-dontnote kotlinx.serialization.AnnotationsKt

# Keep annotations
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-keepattributes Signature
-keepattributes Exceptions

# Prevent obfuscation of crash reporting
-keepattributes LineNumberTable,SourceFile
-renamesourcefileattribute SourceFile

# Fix potential crash-causing obfuscation
-keepattributes InnerClasses,EnclosingMethod,Signature
-keep class * implements java.io.Serializable { *; }
