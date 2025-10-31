#!/bin/bash

#
#  sign_and_notarize.sh
//  AINotizassistent - Code Signing and Notarization Script
//
//  Spezialisierte Skripte für Code Signing und App Notarization
//

set -e

# Configuration
APP_PATH="${1:-/workspace/Build/Release/AINotizassistent.app}"
TEAM_ID="${TEAM_ID:-YOUR_TEAM_ID}"
BUNDLE_ID="${BUNDLE_ID:-com.yourcompany.AINotizassistent}"
NOTARIZATION_PROFILE="${NOTARIZATION_PROFILE:-NOTARIZATION_PROFILE}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

# Usage
usage() {
    cat << EOF
Usage: $0 [APP_PATH] [OPTIONS]

Code Signing and Notarization Script

Arguments:
    APP_PATH              Path to the app bundle (default: /workspace/Build/Release/AINotizassistent.app)

Options:
    -h, --help            Show this help message
    -t, --team-id         Apple Developer Team ID
    -b, --bundle-id       App Bundle Identifier
    -p, --profile         Notarization profile name
    --sign-only           Only sign the app (skip notarization)
    --notarize-only       Only notarize the app (assumes already signed)
    --verify              Verify existing signature and notarization
    --strip-signature     Strip existing signature before resigning
    --create-dmg          Create DMG after signing/notarization
    --validate-app-store  Validate for App Store submission

Examples:
    $0                                    # Sign and notarize default app
    $0 /path/to/app.app --sign-only       # Only sign the app
    $0 --notarize-only                    # Only notarize (app already signed)
    $0 --create-dmg                       # Create DMG after signing

EOF
}

# Parse arguments
SIGN_ONLY=false
NOTARIZE_ONLY=false
VERIFY_ONLY=false
STRIP_SIGNATURE=false
CREATE_DMG=false
VALIDATE_APP_STORE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage
            exit 0
            ;;
        -t|--team-id)
            TEAM_ID="$2"
            shift 2
            ;;
        -b|--bundle-id)
            BUNDLE_ID="$2"
            shift 2
            ;;
        -p|--profile)
            NOTARIZATION_PROFILE="$2"
            shift 2
            ;;
        --sign-only)
            SIGN_ONLY=true
            shift
            ;;
        --notarize-only)
            NOTARIZE_ONLY=true
            shift
            ;;
        --verify)
            VERIFY_ONLY=true
            shift
            ;;
        --strip-signature)
            STRIP_SIGNATURE=true
            shift
            ;;
        --create-dmg)
            CREATE_DMG=true
            shift
            ;;
        --validate-app-store)
            VALIDATE_APP_STORE=true
            shift
            ;;
        -*)
            if [[ -n "${1:-}" ]] && [[ "${1:-}" != -* ]]; then
                APP_PATH="$1"
                shift
            else
                log_error "Unknown option: $1"
                usage
                exit 1
            fi
            ;;
        *)
            if [[ -z "${app_path_set:-}" ]]; then
                APP_PATH="$1"
                app_path_set=true
                shift
            else
                log_error "Multiple app paths specified"
                usage
                exit 1
            fi
            ;;
    esac
done

# Validate app path
validate_app_path() {
    if [ ! -d "$APP_PATH" ]; then
        log_error "App bundle not found: $APP_PATH"
        exit 1
    fi
    
    log_info "Target app: $APP_PATH"
}

# Check signing requirements
check_signing_requirements() {
    log_info "Checking signing requirements..."
    
    # Check for signing identities
    if ! security find-identity -v -p codesigning | grep -q "Developer ID Application"; then
        log_error "No Developer ID Application signing identity found"
        log_info "Available identities:"
        security find-identity -v -p codesigning
        exit 1
    fi
    
    # Find signing identity for team
    SIGNING_IDENTITY=$(security find-identity -v -p codesigning | grep "Developer ID Application" | grep "$TEAM_ID" | head -1 | sed 's/.*"\(.*\)"/\1/')
    
    if [ -z "$SIGNING_IDENTITY" ]; then
        log_error "No matching signing identity found for team: $TEAM_ID"
        log_info "Available Developer ID identities:"
        security find-identity -v -p codesigning | grep "Developer ID Application"
        exit 1
    fi
    
    log_success "Found signing identity: $SIGNING_IDENTITY"
}

# Strip existing signature
strip_signature() {
    if [ "$STRIP_SIGNATURE" = true ]; then
        log_info "Stripping existing signature..."
        codesign --remove-signature "$APP_PATH"
        
        # Strip nested binaries
        find "$APP_PATH" -type f -exec codesign --remove-signature {} \; 2>/dev/null || true
        
        log_success "Signature stripped"
    fi
}

# Sign the app
sign_app() {
    if [ "$NOTARIZE_ONLY" = true ]; then
        return 0
    fi
    
    log_info "Signing app..."
    
    # Determine entitlements file
    ENTITLEMENTS_PATH=$(find "$(dirname "$APP_PATH")" -name "*.entitlements" 2>/dev/null | head -1)
    
    if [ -n "$ENTITLEMENTS_PATH" ]; then
        log_info "Using entitlements: $ENTITLEMENTS_PATH"
    else
        log_warning "No entitlements file found, signing without entitlements"
    fi
    
    # Sign the app bundle
    if [ -n "$ENTITLEMENTS_PATH" ]; then
        codesign --force --verbose=4 \
            --sign "$SIGNING_IDENTITY" \
            --entitlements "$ENTITLEMENTS_PATH" \
            --options runtime \
            "$APP_PATH"
    else
        codesign --force --verbose=4 \
            --sign "$SIGNING_IDENTITY" \
            --options runtime \
            "$APP_PATH"
    fi
    
    if [ $? -eq 0 ]; then
        log_success "App signed successfully"
    else
        log_error "App signing failed"
        exit 1
    fi
}

# Verify signature
verify_signature() {
    log_info "Verifying signature..."
    
    # Verify app signature
    codesign --verify --verbose=4 "$APP_PATH"
    spctl -t exec -vv "$APP_PATH"
    
    # Check signing chain
    security verify-cert -c "$APP_PATH" -v
    
    # Verify nested binaries
    find "$APP_PATH" -type f -exec codesign --verify --verbose=1 {} \; 2>/dev/null
    
    log_success "Signature verification passed"
}

# Notarize the app
notarize_app() {
    if [ "$SIGN_ONLY" = true ]; then
        return 0
    fi
    
    log_info "Starting notarization process..."
    
    # Check if notarization profile exists
    if ! xcrun notarytool list 2>/dev/null | grep -q "$NOTARIZATION_PROFILE"; then
        log_error "Notarization profile not found: $NOTARIZATION_PROFILE"
        log_info "Available profiles:"
        xcrun notarytool list 2>/dev/null || echo "Run 'xcrun notarytool store-credentials PROFILE_NAME' to create one"
        exit 1
    fi
    
    # Check Apple ID login
    if ! xcrun notarytool list 2>/dev/null > /dev/null; then
        log_error "Not logged into Apple ID for notarization"
        log_info "Run: xcrun notarytool log in"
        exit 1
    fi
    
    # Create ZIP for notarization
    APP_DIR=$(dirname "$APP_PATH")
    APP_NAME=$(basename "$APP_PATH")
    ZIP_PATH="$APP_DIR/$APP_NAME.zip"
    
    log_info "Creating ZIP for notarization: $ZIP_PATH"
    cd "$APP_DIR"
    zip -r "$ZIP_PATH" "$APP_NAME"
    cd - > /dev/null
    
    # Submit for notarization
    log_info "Submitting for notarization..."
    log_info "This may take several minutes..."
    
    xcrun notarytool submit "$ZIP_PATH" \
        --keychain-profile "$NOTARIZATION_PROFILE" \
        --wait
    
    if [ $? -eq 0 ]; then
        log_success "Notarization completed successfully"
    else
        log_error "Notarization failed"
        log_info "Check notarization logs with:"
        log_info "xcrun notarytool log 1"
        exit 1
    fi
    
    # Staple notarization
    log_info "Stapling notarization to app..."
    xcrun stapler staple "$APP_PATH"
    
    if [ $? -eq 0 ]; then
        log_success "Notarization stapled successfully"
    else
        log_error "Failed to staple notarization"
        exit 1
    fi
}

# Verify notarization
verify_notarization() {
    if [ "$SIGN_ONLY" = true ]; then
        return 0
    fi
    
    log_info "Verifying notarization..."
    
    # Check notarization status
    spctl -a -t exec -vv "$APP_PATH"
    
    # Verify with Apple servers
    xcrun stapler validate "$APP_PATH"
    
    log_success "Notarization verification passed"
}

# Create DMG
create_dmg() {
    if [ "$CREATE_DMG" = false ]; then
        return 0
    fi
    
    log_info "Creating DMG..."
    
    APP_NAME=$(basename "$APP_PATH" .app)
    DMG_NAME="${APP_NAME}-$(date +%Y%m%d-%H%M%S)"
    DMG_PATH="$(dirname "$APP_PATH")/$DMG_NAME.dmg"
    DMG_BACKGROUND="$(dirname "$APP_PATH")/../Resources/dmg_background.png"
    
    # Create temporary folder structure
    DMG_BUILD_DIR="/tmp/dmg_build_$$"
    mkdir -p "$DMG_BUILD_DIR"
    
    # Copy app bundle
    cp -R "$APP_PATH" "$DMG_BUILD_DIR/"
    
    # Create Applications symlink
    ln -s "/Applications" "$DMG_BUILD_DIR/Applications"
    
    # Set up custom background
    if [ -f "$DMG_BACKGROUND" ]; then
        mkdir -p "$DMG_BUILD_DIR/.background"
        cp "$DMG_BACKGROUND" "$DMG_BUILD_DIR/.background/"
    fi
    
    # Create DMG
    hdiutil create -srcfolder "$DMG_BUILD_DIR" \
        -volname "$APP_NAME" \
        -fs HFS+ \
        -format UDZO \
        "$DMG_PATH"
    
    # Sign DMG
    codesign --sign "Developer ID Application: $TEAM_ID" "$DMG_PATH"
    
    # Verify DMG
    spctl -t open --context context:primary-signature -vv "$DMG_PATH"
    
    # Cleanup
    rm -rf "$DMG_BUILD_DIR"
    
    log_success "DMG created: $DMG_PATH"
}

# App Store validation
validate_app_store() {
    if [ "$VALIDATE_APP_STORE" = false ]; then
        return 0
    fi
    
    log_info "Validating for App Store submission..."
    
    # Check for required metadata
    INFO_PLIST="$APP_PATH/Contents/Info.plist"
    
    if [ ! -f "$INFO_PLIST" ]; then
        log_error "Info.plist not found"
        exit 1
    fi
    
    # Validate bundle identifier
    BUNDLE_ID_FROM_PLIST=$(/usr/libexec/PlistBuddy -c "Print CFBundleIdentifier" "$INFO_PLIST" 2>/dev/null || echo "")
    
    if [ "$BUNDLE_ID_FROM_PLIST" != "$BUNDLE_ID" ]; then
        log_warning "Bundle ID mismatch: Info.plist=$BUNDLE_ID_FROM_PLIST, Expected=$BUNDLE_ID"
    fi
    
    # Check for hardcoded paths
    OTOOL_OUTPUT=$(find "$APP_PATH" -type f -name "*.dylib" -o -name "*.app" | xargs otool -L 2>/dev/null | grep "/usr/local" || true)
    
    if [ -n "$OTOOL_OUTPUT" ]; then
        log_warning "App may contain hardcoded paths"
        echo "$OTOOL_OUTPUT"
    fi
    
    # Check for App Store rejection reasons
    APP_STORE_ISSUES=""
    
    # Check for private frameworks
    if find "$APP_PATH" -name "*.framework" | grep -E "(Sparkle|ReactiveCocoa|FBSDK)" | grep -v "Apple" > /dev/null; then
        APP_STORE_ISSUES="$APP_STORE_ISSUES\n- Private frameworks detected"
    fi
    
    # Check for anti-debugging
    if strings "$APP_PATH/Contents/MacOS/$APP_NAME" | grep -E "(ptrace|DEBUG|Debug)" > /dev/null; then
        APP_STORE_ISSUES="$APP_STORE_ISSUES\n- Possible anti-debugging code detected"
    fi
    
    # Report issues
    if [ -n "$APP_STORE_ISSUES" ]; then
        log_warning "Potential App Store issues found:$APP_STORE_ISSUES"
    else
        log_success "App Store validation passed"
    fi
}

# Main execution
main() {
    log_info "Starting code signing and notarization process"
    log_info "App: $APP_PATH"
    log_info "Team ID: $TEAM_ID"
    log_info "Bundle ID: $BUNDLE_ID"
    
    validate_app_path
    
    if [ "$VERIFY_ONLY" = true ]; then
        verify_signature
        verify_notarization
        return 0
    fi
    
    check_signing_requirements
    strip_signature
    sign_app
    verify_signature
    
    if [ "$NOTARIZE_ONLY" = false ]; then
        notarize_app
        verify_notarization
    fi
    
    create_dmg
    validate_app_store
    
    log_success "Code signing and notarization completed successfully!"
    
    # Summary
    echo ""
    echo "=== Signing Summary ==="
    echo "App: $APP_PATH"
    echo "Signed: ✅"
    echo "Notarized: $([ "$SIGN_ONLY" = false ] && echo "✅" || echo "❌")"
    echo "DMG Created: $([ "$CREATE_DMG" = true ] && echo "✅" || echo "❌")"
    echo ""
}

# Handle interruption
cleanup() {
    log_error "Process interrupted"
    exit 1
}

trap cleanup INT TERM

# Run main
main "$@"