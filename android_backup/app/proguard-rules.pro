# Keep generic Google Auth classes
-keep class com.google.android.gms.auth.** { *; }
-keep class com.google.android.gms.common.** { *; }
-keep class com.google.android.gms.tasks.** { *; }

# Specific missing classes from your logs
-keep class com.google.android.gms.auth.api.credentials.** { *; }
-keep class com.google.android.gms.auth.api.credentials.Credential { *; }
-keep class com.google.android.gms.auth.api.credentials.HintRequest { *; }
-keep class com.google.android.gms.auth.api.credentials.CredentialsOptions { *; }

# Smart Auth package
-keep class fman.ge.smart_auth.** { *; }
-dontwarn fman.ge.smart_auth.**