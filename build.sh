#!/bin/sh

# This script is used to build the Helium app and create a tipa file with Xcode.
if [ $# -ne 1 ]; then
    echo "Usage: $0 <version>"
    exit 1
fi

VERSION=$1

# Strip leading "v" from version if present
VERSION=${VERSION#v}

# Build using Xcode
xcodebuild clean archive \
-scheme Helium \
-project Helium.xcodeproj \
-sdk iphoneos \
-destination 'generic/platform=iOS' \
-archivePath Helium \
-configuration Debug \
CODE_SIGNING_ALLOWED=NO | xcpretty

#chmod 0644 Resources/Info.plist
#chmod 0644 supports/Sandbox-Info.plist
cp Helium/supports/entitlements.plist Helium.xcarchive/Products
cd Helium.xcarchive/Products/Applications
codesign --remove-signature Helium.app
cd -
cd Helium.xcarchive/Products
mv Applications Payload
ldid -Sentitlements.plist Payload/Helium.app
chmod 0644 Payload/Helium.app/Info.plist
zip -qr Helium.tipa Payload
cd -
mkdir -p packages
mv Helium.xcarchive/Products/Helium.tipa packages/Helium_v$VERSION.tipa
