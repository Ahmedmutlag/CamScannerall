package com.ahmedmutlag.camscannerall

import io.flutter.embedding.android.FlutterFragmentActivity

// Extends FlutterFragmentActivity (not plain FlutterActivity) because the
// local_auth plugin's biometric prompt is an androidx Fragment dialog and
// silently fails to show on a non-FragmentActivity host.
class MainActivity : FlutterFragmentActivity()
