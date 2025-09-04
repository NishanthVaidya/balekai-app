#!/bin/bash

echo "🚀 Starting comprehensive build process for Balekai..."

# Clean previous builds
echo "🧹 Cleaning previous builds..."
mvn clean

# Compile and package
echo "🔨 Compiling and packaging..."
mvn compile package -DskipTests

# Verify the JAR was created
if [ ! -f "target/kardo-1.0-SNAPSHOT.jar" ]; then
    echo "❌ JAR file not found! Build failed."
    exit 1
fi

# Verify Firebase config exists in target/classes
if [ ! -f "target/classes/firebase-service-account.json" ]; then
    echo "❌ Firebase config not found in target/classes! Build failed."
    exit 1
fi

echo "✅ Build completed successfully!"
echo "📦 JAR file: target/kardo-1.0-SNAPSHOT.jar"
echo "🔥 Firebase config: target/classes/firebase-service-account.json"
echo ""
echo "🐳 Ready for Docker build!"
echo "Run: docker build -t balekai ."
