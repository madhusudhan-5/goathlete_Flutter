import os
import time

for app in ["executive_app", "vendor_app"]:
    pubspec_path = f"goathlete_workspace/apps/{app}/pubspec.yaml"
    
    with open(pubspec_path, "r") as f:
        content = f.read()
        
    if "flutter_launcher_icons:" not in content:
        icon_config = """
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/images/logo.png"
  min_sdk_size: 21
"""
        with open(pubspec_path, "a") as f:
            f.write(icon_config)

    print(f"Updated {pubspec_path}")
