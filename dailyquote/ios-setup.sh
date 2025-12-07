#!/bin/bash

# iOS Setup Script for Daily Wisdom React Native App
# This script helps set up the iOS project structure

set -e

echo "🚀 Setting up iOS project for Daily Wisdom..."

# Check if we're in the right directory
if [ ! -f "package.json" ]; then
    echo "❌ Error: package.json not found. Please run this script from the project root."
    exit 1
fi

# Check for CocoaPods
if ! command -v pod &> /dev/null; then
    echo "❌ CocoaPods is not installed. Installing..."
    sudo gem install cocoapods
fi

# Install npm dependencies
echo "📦 Installing npm dependencies..."
npm install

# Create iOS directory structure if it doesn't exist
if [ ! -d "ios" ]; then
    echo "📱 Creating iOS project structure..."
    mkdir -p ios
fi

# Install CocoaPods dependencies
echo "🍫 Installing CocoaPods dependencies..."
cd ios
pod install
cd ..

echo "✅ iOS setup complete!"
echo ""
echo "Next steps:"
echo "1. Open ios/DailyWisdom.xcworkspace in Xcode"
echo "2. Set your GEMINI_API_KEY in the environment or use react-native-config"
echo "3. Run: npm run ios"
echo ""
echo "For more details, see iOS_SETUP.md"

