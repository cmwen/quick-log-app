#!/bin/bash
# Quick Log App - Icon Setup Script
# This script helps set up the app icon once you have a source image

echo "📱 Quick Log - App Icon Setup"
echo "================================"
echo ""

# Check if flutter_launcher_icons is in pubspec.yaml
if ! grep -q "flutter_launcher_icons" pubspec.yaml; then
    echo "Adding flutter_launcher_icons to pubspec.yaml..."
    
    cat >> pubspec.yaml << 'EOF'

# Icon generation
flutter_launcher_icons:
  android: true
  ios: true
  web:
    generate: true
  image_path: "assets/icon/icon.png"
  adaptive_icon_background: "#2196F3"
  adaptive_icon_foreground: "assets/icon/foreground.png"
  
dev_dependencies:
  flutter_launcher_icons: ^0.13.1
EOF
    
    echo "✅ Added flutter_launcher_icons configuration"
fi

# Create assets directory
echo "Creating assets directory..."
mkdir -p assets/icon

echo ""
echo "📋 Next Steps:"
echo "=============="
echo ""
echo "1. Create your app icon (1024x1024 PNG):"
echo "   - See docs/APP_ICON_SPECIFICATION.md for design guidelines"
echo "   - Use an AI image generator or design tool"
echo "   - Make sure it follows Material Design principles"
echo ""
echo "2. Save your icon as: assets/icon/icon.png"
echo "   - Should be 1024x1024 pixels"
echo "   - PNG format with transparency"
echo ""
echo "3. (Optional) Create adaptive icon foreground:"
echo "   - Save as: assets/icon/foreground.png"
echo "   - For Android adaptive icons"
echo "   - Should contain only the icon elements (no background)"
echo ""
echo "4. Run the icon generator:"
echo "   flutter pub get"
echo "   flutter pub run flutter_launcher_icons"
echo ""
echo "5. The script will automatically generate:"
echo "   - Android launcher icons (all densities)"
echo "   - iOS app icons (all sizes)"
echo "   - Web icons (192x192 and 512x512)"
echo ""
echo "💡 Tips:"
echo "  - Use a simple, recognizable design"
echo "  - Test at small sizes (48x48) to ensure clarity"
echo "  - Use the blue color #2196F3 as primary"
echo "  - Include the tag/label symbol as the main element"
echo ""
echo "For icon design ideas, see: docs/APP_ICON_SPECIFICATION.md"
