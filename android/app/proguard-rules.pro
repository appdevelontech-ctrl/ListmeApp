# Razorpay SDK
-keep class com.razorpay.** { *; }
-dontwarn com.razorpay.**

# Flutter plugins
-keep class io.flutter.plugins.** { *; }
-keep class com.google.firebase.** { *; }

# Socket.IO (Required)
-keep class io.socket.** { *; }
-dontwarn io.socket.**

# JSON (Optional)
-keep class org.json.** { *; }
-dontwarn org.json.**

# Preserve annotations and signatures
-keepattributes Signature
-keepattributes *Annotation*

# Keep custom annotations (if any)
-keep class proguard.annotation.Keep { *; }
-keep class proguard.annotation.KeepClassMembers { *; }
