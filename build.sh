#!/bin/bash

# Pomodoro Timer Build Script
echo "🍅 Building Pomodoro Timer..."

# Check if Xcode is installed
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ Xcode is not installed or not in PATH"
    echo "Please install Xcode from the App Store"
    exit 1
fi

# Check if we're in the right directory
if [ ! -f "PomodoroTimer.xcodeproj/project.pbxproj" ]; then
    echo "❌ PomodoroTimer.xcodeproj not found"
    echo "Please run this script from the pomodoro directory"
    exit 1
fi

# Build the project
echo "🔨 Building project..."
xcodebuild -project PomodoroTimer.xcodeproj -scheme PomodoroTimer -configuration Release build

if [ $? -eq 0 ]; then
    echo "✅ Build successful!"
    echo ""
    echo "🎉 Pomodoro Timer has been built successfully!"
    echo ""
    echo "To run the app:"
    echo "1. Open Xcode"
    echo "2. Open PomodoroTimer.xcodeproj"
    echo "3. Click the Run button (⌘R)"
    echo ""
    echo "The app will appear in your menu bar with a 🍅 icon"
    echo ""
    echo "Keyboard shortcuts:"
    echo "  ⌘⇧Space - Start/Pause timer"
    echo "  ⌘⇧R - Reset timer"
else
    echo "❌ Build failed!"
    echo "Please check the error messages above"
    exit 1
fi 