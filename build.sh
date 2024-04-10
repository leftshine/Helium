#!/bin/sh

if [[ $* == *--scriptdebug* ]]; then
    set -x
fi
set -e

# This script is used to build the Helium app and create a tipa file with Xcode.
if [ $# -lt 1 ]; then
    echo "Usage: $0 <version> [--debug]"
    exit 1
fi

VERSION=$1
shift

# Check if --debug option is provided
if [[ "$*" == *--debug* ]]; then
    CONFIGURATION="Debug"
else
    CONFIGURATION="Release"
fi

if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
fi

# Strip leading "v" from version if present
VERSION=${VERSION#v}

#replace env
sed -i '' "s#{SENTRY_DSN}#$SENTRY_DSN#g" Helium/objc/headers/Const.h
sed -i '' "s#{SENTRY_ENV}#$CONFIGURATION#g" Helium/objc/headers/Const.h

# Build using Xcode
xcodebuild clean archive \
-scheme Helium \
-workspace Helium.xcworkspace \
-sdk iphoneos \
-destination 'generic/platform=iOS' \
-archivePath Helium \
-configuration $CONFIGURATION \
CODE_SIGNING_ALLOWED=NO | xcpretty

cp Helium/supports/Helium.entitlements Helium.xcarchive/Products
cd Helium.xcarchive/Products/Applications
codesign --remove-signature Helium.app
cd -
cd Helium.xcarchive/Products
mv Applications Payload
ldid -SHelium.entitlements Payload/Helium.app
chmod 0644 Payload/Helium.app/Info.plist
zip -qr Helium.tipa Payload
cd -
mkdir -p packages
mv Helium.xcarchive/Products/Helium.tipa packages/Helium_v$VERSION.tipa
