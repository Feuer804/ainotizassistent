#!/bin/bash

#
#  build_app.sh
#  AINotizassistent - Automated Build Script
#
#  Automatisierte Erstellung von macOS Apps mit Code Signing
#

set -e

# Configuration
APP_NAME="${APP_NAME:-AINotizassistent}"
BUNDLE_ID="${BUNDLE_ID:-com.yourcompany.AINotizassistent}"
TEAM_ID="${TEAM_ID:-YOUR_TEAM_ID}"
SCHEME="${SCHEME:-AINotizassistent}"
CONFIGURATION="${CONFIGURATION:-Release}"
SOURCE_DIR="${SOURCE_DIR:-/workspace}"
OUTPUT_DIR="${OUTPUT_DIR:-/workspace/Build}"
XCODE_PROJECT="${XCODE_PROJECT:-$SOURCE_DIR/AINotizassistent/AINotizassistent.xcodeproj}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Usage information
usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Build Options:
    -h, --help          Show this help message
    -c, --configuration Configuration to build (Debug|Release)
    -s, --scheme        Xcode scheme to build
    -o, --output        Output directory for build artifacts
    -t, --team-id       Apple Developer Team ID
    --clean             Clean build directory before building
    --archive           Create Xcode archive
    --sign              Enable code signing
    --notarize          Enable app notarization
    --distribution      Create distribution packages

Examples:
    $0 --configuration Release --sign --distribution
    $0 --clean --archive --team-id YOUR_TEAM_ID
    $0 --scheme AINotizassistent --notarize

EOF
}

# Parse command line arguments
CLEAN_BUILD=false
CREATE_ARCHIVE=false
ENABLE_SIGNING=false
ENABLE_NOTARIZATION=false
CREATE_DISTRIBUTION=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage
            exit 0
            ;;
        -c|--configuration)
            CONFIGURATION="$2"
            shift 2
            ;;
        -s|--scheme)
            SCHEME="$2"
            shift 2
            ;;
        -o|--output)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        -t|--team-id)
            TEAM_ID="$2"
            shift 2
            ;;
        --clean)
            CLEAN_BUILD=true
            shift
            ;;
        --archive)
            CREATE_ARCHIVE=true
            shift
            ;;
        --sign)
            ENABLE_SIGNING=true
            shift
            ;;
        --notarize)
            ENABLE_NOTARIZATION=true
            ENABLE_SIGNING=true
            shift
            ;;
        --distribution)
            CREATE_DISTRIBUTION=true
            ENABLE_SIGNING=true
            shift
            ;;
        *)
            log_error "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Validate requirements
validate_requirements() {
    log_info "Validating build requirements..."
    
    # Check if Xcode is installed
    if ! command -v xcodebuild &> /dev/null; then
        log_error "xcodebuild not found. Please install Xcode."
        exit 1
    fi
    
    # Check if project exists
    if [ ! -d "$XCODE_PROJECT" ]; then
        log_error "Xcode project not found at: $XCODE_PROJECT"
        exit 1
    fi
    
    # Check if team ID is provided for signing
    if [ "$ENABLE_SIGNING" = true ] && [ -z "$TEAM_ID" ]; then
        log_error "Team ID is required for code signing. Use -t or --team-id option."
        exit 1
    fi
    
    log_success "Requirements validated"
}

# Clean build directory
clean_build_directory() {
    if [ "$CLEAN_BUILD" = true ]; then
        log_info "Cleaning build directory..."
        rm -rf "$OUTPUT_DIR"
        mkdir -p "$OUTPUT_DIR"
    fi
}

# Build the app
build_app() {
    log_info "Building $APP_NAME ($CONFIGURATION)..."
    
    BUILD_DIR="$OUTPUT_DIR/$CONFIGURATION"
    APP_PATH="$BUILD_DIR/$APP_NAME.app"
    
    # Base xcodebuild command
    XCODEBUILD_CMD="xcodebuild \
        -project '$XCODE_PROJECT' \
        -scheme '$SCHEME' \
        -configuration '$CONFIGURATION' \
        -derivedDataPath '$OUTPUT_DIR/DerivedData' \
        CODE_SIGN_STYLE=Automatic \
        DEVELOPMENT_TEAM='$TEAM_ID' \
        PRODUCT_BUNDLE_IDENTIFIER='$BUNDLE_ID' \
        SWIFT_COMPILATION_MODE=wholemodule \
        SWIFT_OPTIMIZATION_LEVEL='-O' \
        ONLY_ACTIVE_ARCH=NO \
        ARCHS='x86_64 arm64' \
        VALIDATE_PRODUCT=YES"
    
    # Add signing configuration if enabled
    if [ "$ENABLE_SIGNING" = true ]; then
        SIGNING_IDENTITY="Developer ID Application: $TEAM_ID"
        XCODEBUILD_CMD="$XCODEBUILD_CMD \
            CODE_SIGN_IDENTITY='$SIGNING_IDENTITY'"
        
        # Add entitlements if they exist
        ENTITLEMENTS_FILE="$SOURCE_DIR/AINotizassistent/$APP_NAME/$APP_NAME.entitlements"
        if [ -f "$ENTITLEMENTS_FILE" ]; then
            XCODEBUILD_CMD="$XCODEBUILD_CMD \
                CODE_SIGN_ENTITLEMENTS='$ENTITLEMENTS_FILE'"
        fi
    fi
    
    # Execute build
    log_info "Executing: $XCODEBUILD_CMD"
    eval "$XCODEBUILD_CMD"
    
    if [ $? -eq 0 ]; then
        log_success "Build completed successfully"
        log_info "App built at: $APP_PATH"
    else
        log_error "Build failed"
        exit 1
    fi
    
    # Verify build
    if [ ! -d "$APP_PATH" ]; then
        log_error "App bundle not found at expected location: $APP_PATH"
        exit 1
    fi
    
    echo "APP_PATH=$APP_PATH" > "$OUTPUT_DIR/build_env.sh"
    echo "BUILD_DIR=$BUILD_DIR" >> "$OUTPUT_DIR/build_env.sh"
    echo "CONFIGURATION=$CONFIGURATION" >> "$OUTPUT_DIR/build_env.sh"
}

# Create Xcode archive
create_archive() {
    if [ "$CREATE_ARCHIVE" = false ]; then
        return 0
    fi
    
    log_info "Creating Xcode archive..."
    
    ARCHIVE_PATH="$OUTPUT_DIR/$APP_NAME.xcarchive"
    
    xcodebuild archive \
        -project "$XCODE_PROJECT" \
        -scheme "$SCHEME" \
        -archivePath "$ARCHIVE_PATH" \
        CODE_SIGN_STYLE=Automatic \
        DEVELOPMENT_TEAM="$TEAM_ID" \
        PRODUCT_BUNDLE_IDENTIFIER="$BUNDLE_ID"
    
    if [ $? -eq 0 ]; then
        log_success "Archive created: $ARCHIVE_PATH"
    else
        log_error "Archive creation failed"
        exit 1
    fi
    
    # Export archive for App Store or Ad Hoc
    export_archive
}

# Export archive
export_archive() {
    log_info "Exporting archive..."
    
    EXPORT_PATH="$OUTPUT_DIR/Export"
    mkdir -p "$EXPORT_PATH"
    
    # Create exportOptions.plist
    EXPORT_OPTIONS_PLIST="$OUTPUT_DIR/exportOptions.plist"
    cat > "$EXPORT_OPTIONS_PLIST" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>developer-id</string>
    <key>teamID</key>
    <string>$TEAM_ID</string>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
    <key>compileBitcode</key>
    <false/>
</dict>
</plist>
EOF
    
    xcodebuild -exportArchive \
        -archivePath "$OUTPUT_DIR/$APP_NAME.xcarchive" \
        -exportPath "$EXPORT_PATH" \
        -exportOptionsPlist "$EXPORT_OPTIONS_PLIST"
    
    if [ $? -eq 0 ]; then
        log_success "Archive exported to: $EXPORT_PATH"
    else
        log_error "Archive export failed"
        exit 1
    fi
}

# Sign app
sign_app() {
    if [ "$ENABLE_SIGNING" = false ]; then
        return 0
    fi
    
    log_info "Signing app..."
    
    source "$OUTPUT_DIR/build_env.sh"
    
    # Verify signing identity
    SIGNING_IDENTITY="Developer ID Application: $TEAM_ID"
    if ! security find-identity -v -p codesigning | grep -q "$SIGNING_IDENTITY"; then
        log_error "Signing identity not found: $SIGNING_IDENTITY"
        log_info "Available identities:"
        security find-identity -v -p codesigning
        exit 1
    fi
    
    # Sign the app
    codesign --force --sign "$SIGNING_IDENTITY" "$APP_PATH"
    
    # Verify signature
    codesign --verify --verbose=4 "$APP_PATH"
    spctl -t exec -vv "$APP_PATH"
    
    log_success "App signed successfully"
}

# Notarize app
notarize_app() {
    if [ "$ENABLE_NOTARIZATION" = false ]; then
        return 0
    fi
    
    log_info "Starting notarization process..."
    
    source "$OUTPUT_DIR/build_env.sh"
    
    # Create ZIP for notarization
    APP_ZIP="$OUTPUT_DIR/$APP_NAME.zip"
    cd "$BUILD_DIR"
    zip -r "$APP_ZIP" "$APP_NAME.app"
    cd - > /dev/null
    
    # Check if notary tool profile is configured
    if ! xcrun notarytool list 2>/dev/null | grep -q "NOTARIZATION_PROFILE"; then
        log_warning "Notarization profile not found. Please configure with:"
        log_info "xcrun notarytool store-credentials NOTARIZATION_PROFILE"
        log_info "Make sure your Apple ID is logged in: xcrun notarytool log in"
        exit 1
    fi
    
    # Submit for notarization
    log_info "Submitting for notarization..."
    xcrun notarytool submit "$APP_ZIP" \
        --keychain-profile "NOTARIZATION_PROFILE" \
        --wait
    
    if [ $? -eq 0 ]; then
        log_success "Notarization completed successfully"
        
        # Staple the notarization
        xcrun stapler staple "$APP_PATH"
        log_success "Notarization stapled to app"
    else
        log_error "Notarization failed"
        exit 1
    fi
}

# Create distribution packages
create_distribution_packages() {
    if [ "$CREATE_DISTRIBUTION" = false ]; then
        return 0
    fi
    
    log_info "Creating distribution packages..."
    
    source "$OUTPUT_DIR/build_env.sh"
    
    # Create DMG
    create_dmg
    
    # Create PKG installer
    create_pkg_installer
    
    # Create ZIP archive
    create_zip_archive
    
    # Verify all packages
    verify_packages
}

# Create DMG
create_dmg() {
    log_info "Creating DMG..."
    
    DMG_NAME="$APP_NAME-v$CONFIGURATION"
    DMG_PATH="$OUTPUT_DIR/$DMG_NAME.dmg"
    DMG_BACKGROUND="$SOURCE_DIR/Resources/dmg_background.png"
    
    # Create temporary folder structure
    DMG_BUILD_DIR="/tmp/dmg_build_$$"
    mkdir -p "$DMG_BUILD_DIR"
    
    # Copy app bundle
    cp -R "$APP_PATH" "$DMG_BUILD_DIR/"
    
    # Copy shortcuts if they exist
    if [ -d "$SOURCE_DIR/Resources/shortcuts" ]; then
        cp -R "$SOURCE_DIR/Resources/shortcuts" "$DMG_BUILD_DIR/"
    fi
    
    # Set up custom background
    if [ -f "$DMG_BACKGROUND" ]; then
        mkdir -p "$DMG_BUILD_DIR/.background"
        cp "$DMG_BACKGROUND" "$DMG_BUILD_DIR/.background/"
    fi
    
    # Create Applications symlink
    ln -s "/Applications" "$DMG_BUILD_DIR/Applications"
    
    # Create DMG
    hdiutil create -srcfolder "$DMG_BUILD_DIR" \
        -volname "$APP_NAME" \
        -fs HFS+ \
        -fsargs "-c c=64,a=16,e=16" \
        -format UDZO \
        "$DMG_PATH"
    
    # Sign DMG
    codesign --sign "Developer ID Application: $TEAM_ID" "$DMG_PATH"
    
    # Cleanup
    rm -rf "$DMG_BUILD_DIR"
    
    log_success "DMG created: $DMG_PATH"
}

# Create PKG installer
create_pkg_installer() {
    log_info "Creating PKG installer..."
    
    PKG_NAME="$APP_NAME-$CONFIGURATION.pkg"
    PKG_PATH="$OUTPUT_DIR/$PKG_NAME"
    
    # Create PKG installer
    pkgbuild --root "$APP_PATH" \
        --identifier "$BUNDLE_ID" \
        --version "$CONFIGURATION" \
        --install-location "/Applications" \
        "$PKG_PATH"
    
    # Sign PKG installer
    productsign --sign "Developer ID Installer: $TEAM_ID" \
        "$PKG_PATH" \
        "$PKG_PATH.signed"
    
    # Notarize PKG installer
    xcrun notarytool submit "$PKG_PATH.signed" \
        --keychain-profile "NOTARIZATION_PROFILE" \
        --wait
    
    # Staple PKG installer
    xcrun stapler staple "$PKG_PATH.signed"
    
    # Replace unsigned version
    mv "$PKG_PATH.signed" "$PKG_PATH"
    
    log_success "PKG installer created: $PKG_PATH"
}

# Create ZIP archive
create_zip_archive() {
    log_info "Creating ZIP archive..."
    
    ZIP_NAME="$APP_NAME-$CONFIGURATION.zip"
    ZIP_PATH="$OUTPUT_DIR/$ZIP_NAME"
    
    cd "$BUILD_DIR"
    zip -r "$ZIP_PATH" "$APP_NAME.app"
    cd - > /dev/null
    
    # Sign ZIP
    codesign --sign "Developer ID Application: $TEAM_ID" "$ZIP_PATH"
    
    log_success "ZIP archive created: $ZIP_PATH"
}

# Verify packages
verify_packages() {
    log_info "Verifying distribution packages..."
    
    # Verify DMG
    if [ -f "$OUTPUT_DIR/$APP_NAME-v$CONFIGURATION.dmg" ]; then
        spctl -t open --context context:primary-signature -vv "$OUTPUT_DIR/$APP_NAME-v$CONFIGURATION.dmg"
        log_success "DMG verification passed"
    fi
    
    # Verify PKG
    if [ -f "$OUTPUT_DIR/$APP_NAME-$CONFIGURATION.pkg" ]; then
        spctl -t open --context context:primary-signature -vv "$OUTPUT_DIR/$APP_NAME-$CONFIGURATION.pkg"
        log_success "PKG verification passed"
    fi
    
    # Verify ZIP
    if [ -f "$OUTPUT_DIR/$APP_NAME-$CONFIGURATION.zip" ]; then
        spctl -t open --context context:primary-signature -vv "$OUTPUT_DIR/$APP_NAME-$CONFIGURATION.zip"
        log_success "ZIP verification passed"
    fi
}

# Generate checksums
generate_checksums() {
    log_info "Generating checksums..."
    
    cd "$OUTPUT_DIR"
    
    for file in *.dmg *.pkg *.zip; do
        if [ -f "$file" ]; then
            shasum -a 256 "$file" > "$file.sha256"
            log_success "Generated checksum for $file"
        fi
    done
    
    cd - > /dev/null
}

# Create release notes
create_release_notes() {
    log_info "Creating release notes..."
    
    RELEASE_NOTES_PATH="$OUTPUT_DIR/ReleaseNotes.md"
    
    cat > "$RELEASE_NOTES_PATH" << EOF
# $APP_NAME v$CONFIGURATION Release Notes

## Build Information
- **Version**: $CONFIGURATION
- **Build Date**: $(date)
- **Bundle ID**: $BUNDLE_ID
- **Team ID**: $TEAM_ID

## Downloads
EOF

    # Add download links
    for file in *.dmg *.pkg *.zip; do
        if [ -f "$file" ]; then
            echo "- [$file](./$file) ($(du -h "$file" | cut -f1))" >> "$RELEASE_NOTES_PATH"
        fi
    done
    
    echo "" >> "$RELEASE_NOTES_PATH"
    echo "## Checksums" >> "$RELEASE_NOTES_PATH"
    
    for file in *.sha256; do
        if [ -f "$file" ]; then
            echo "### $file" >> "$RELEASE_NOTES_PATH"
            cat "$file" >> "$RELEASE_NOTES_PATH"
            echo "" >> "$RELEASE_NOTES_PATH"
        fi
    done
    
    log_success "Release notes created: $RELEASE_NOTES_PATH"
}

# Main execution
main() {
    log_info "Starting build process for $APP_NAME"
    log_info "Configuration: $CONFIGURATION"
    log_info "Scheme: $SCHEME"
    log_info "Output: $OUTPUT_DIR"
    
    validate_requirements
    clean_build_directory
    build_app
    create_archive
    sign_app
    notarize_app
    create_distribution_packages
    generate_checksums
    create_release_notes
    
    log_success "Build process completed successfully!"
    log_info "Build artifacts available in: $OUTPUT_DIR"
    
    # Summary
    echo ""
    echo "=== Build Summary ==="
    echo "App: $APP_NAME"
    echo "Configuration: $CONFIGURATION"
    echo "Output Directory: $OUTPUT_DIR"
    echo ""
    echo "Distribution Packages:"
    ls -la "$OUTPUT_DIR"/*.dmg "$OUTPUT_DIR"/*.pkg "$OUTPUT_DIR"/*.zip 2>/dev/null | tail -n +2 || echo "No distribution packages created"
}

# Run main function
main "$@"