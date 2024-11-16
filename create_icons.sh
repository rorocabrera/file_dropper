#!/bin/bash

echo "🧹 Cleaning project..."
flutter clean

echo "📦 Getting dependencies..."
flutter pub get

echo "🏗️ Building macOS app..."
flutter build macos

echo "📝 Signing app..."
codesign --force --deep --sign - "build/macos/Build/Products/Release/file_merger.app"

echo "✅ Build complete! You can find your app in build/macos/Build/Products/Release/"