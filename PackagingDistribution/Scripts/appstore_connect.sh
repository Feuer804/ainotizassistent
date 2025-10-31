#!/bin/bash

#
#  appstore_connect.sh
//  AINotizassistent - App Store Connect Integration Script
//
//  Automatisierte App Store Connect Integration und Submission
//

set -e

# Configuration
APP_NAME="${APP_NAME:-AINotizassistent}"
BUNDLE_ID="${BUNDLE_ID:-com.yourcompany.AINotizassistent}"
APPLE_ID="${APPLE_ID:-your-apple-id@example.com}"
TEAM_ID="${TEAM_ID:-YOUR_TEAM_ID}"
VERSION_NUMBER="${VERSION_NUMBER:-1.0.0}"
BUILD_NUMBER="${BUILD_NUMBER:-1}"

# API Configuration
ASC_API_KEY_ID="${ASC_API_KEY_ID:-YOUR_KEY_ID}"
ASC_API_ISSUER_ID="${ASC_API_ISSUER_ID:-YOUR_ISSUER_ID}"
ASC_PRIVATE_KEY_PATH="${ASC_PRIVATE_KEY_PATH:-/path/to/AuthKey_XXXXXXXXXX.p8}"

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
Usage: $0 [COMMAND] [OPTIONS]

App Store Connect Integration and Submission

Commands:
    create-app               Create new app in App Store Connect
    update-metadata          Update app metadata
    upload-screenshots       Upload app screenshots
    upload-build            Upload build for review
    submit-for-review       Submit app for App Store review
    create-release          Create release for specific version
    get-status              Get app status
    list-apps              List all apps
    download-reports       Download sales and usage reports
    check-review-status    Check review status

Options:
    -h, --help              Show this help message
    -a, --app-id            App Store Connect App ID
    -v, --version           Version number (default: $VERSION_NUMBER)
    -b, --build-number      Build number (default: $BUILD_NUMBER)
    -p, --path              Path to archive or build
    -c, --category          App category (e.g., productivity, entertainment)
    -r, --rating            Content rating (e.g., 4+, 9+, 12+, 17+)
    --title                 App title
    --subtitle              App subtitle
    --description           App description
    --keywords              Keywords (comma-separated)
    --changelog             Changelog/Release notes
    --whats-new             What's new in this version
    --support-url           Support URL
    --privacy-policy-url    Privacy policy URL
    --marketing-url         Marketing URL

Examples:
    $0 create-app --title "AI Notizassistent" --category productivity
    $0 upload-screenshots -a 123456789 --path ./screenshots/
    $0 submit-for-review -a 123456789 --changelog "Initial release"
    $0 create-release -a 123456789 -v 1.0.0 --path ./archive.xcarchive

EOF
}

# Validate requirements
validate_requirements() {
    log_info "Validating requirements..."
    
    # Check if jq is installed
    if ! command -v jq &> /dev/null; then
        log_error "jq is required but not installed"
        exit 1
    fi
    
    # Check if xcrun is available
    if ! command -v xcrun &> /dev/null; then
        log_error "xcrun not found. Please install Xcode."
        exit 1
    fi
    
    # Check API credentials
    if [ -z "$ASC_API_KEY_ID" ] || [ -z "$ASC_API_ISSUER_ID" ] || [ ! -f "$ASC_PRIVATE_KEY_PATH" ]; then
        log_error "App Store Connect API credentials not configured"
        log_info "Required environment variables:"
        log_info "  ASC_API_KEY_ID"
        log_info "  ASC_API_ISSUER_ID" 
        log_info "  ASC_PRIVATE_KEY_PATH (path to .p8 private key)"
        exit 1
    fi
    
    log_success "Requirements validated"
}

# Get authentication token
get_auth_token() {
    log_info "Getting authentication token..."
    
    TOKEN_RESPONSE=$(xcrun altool --validate \
        -t ios \
        -f "$BUNDLE_ID" \
        -u "$APPLE_ID" \
        -p "@keychain:AC_PASSWORD" \
        -v \
        2>&1 || true)
    
    # Extract token from response (simplified)
    TOKEN=$(echo "$TOKEN_RESPONSE" | grep -o 'token: [a-zA-Z0-9_-]*' | cut -d' ' -f2)
    
    if [ -z "$TOKEN" ]; then
        log_error "Failed to get authentication token"
        log_info "Please ensure you're logged in with:"
        log_info "xcrun altool --validate -t ios -f $BUNDLE_ID -u $APPLE_ID -p YOUR_PASSWORD -v"
        exit 1
    fi
    
    log_success "Authentication token obtained"
}

# Create new app
create_app() {
    log_info "Creating new app in App Store Connect..."
    
    # App metadata
    local app_title="${TITLE:-AI Notizassistent}"
    local app_subtitle="${SUBTITLE:-Intelligenter Notizassistent}"
    local app_description="${DESCRIPTION:-Ein intelligenter Notizassistent mit AI-Integration}"
    local app_category="${CATEGORY:-productivity}"
    local app_rating="${RATING:-4+}"
    
    # Create app via App Store Connect API
    local create_app_data=$(cat << EOF
{
    "type": "apps",
    "attributes": {
        "bundleId": "$BUNDLE_ID",
        "name": "$app_title",
        "subtitle": "$app_subtitle",
        "sku": "${SKU:-${BUNDLE_ID}-v${VERSION_NUMBER}}",
        "contentAdvisoryRating": "$app_rating",
        "primaryLocale": "de-DE",
        "version": "$VERSION_NUMBER",
        "appStoreVersions": [
            {
                "type": "appStoreVersions",
                "attributes": {
                    "versionString": "$VERSION_NUMBER",
                    "localizations": [
                        {
                            "locale": "de-DE",
                            "appStoreName": "$app_title",
                            "subtitle": "$app_subtitle",
                            "description": "$app_description",
                            "keywords": "${KEYWORDS:-notiz,assistent,ai}",
                            "release": {
                                "releaseType": "manual"
                            },
                            "whatsNew": "${WHATS_NEW:-Initial release}"
                        }
                    ]
                },
                "relationships": {
                    "app": {
                        "data": {
                            "type": "apps",
                            "id": "temp-id"
                        }
                    },
                    "build": {
                        "data": {
                            "type": "builds",
                            "id": "temp-build-id"
                        }
                    }
                }
            }
        ]
    },
    "relationships": {
        "primaryCategory": {
            "data": {
                "type": "categories",
                "id": "$app_category"
            }
        }
    }
}
EOF
)
    
    # This would be sent to App Store Connect API
    # For now, we'll log the command that would be used
    log_info "Would create app with data: $create_app_data"
    log_success "App creation command prepared"
}

# Update app metadata
update_metadata() {
    local app_id="$1"
    
    if [ -z "$app_id" ]; then
        log_error "App ID required for metadata update"
        exit 1
    fi
    
    log_info "Updating metadata for app: $app_id"
    
    # Prepare metadata updates
    local metadata_updates=$(cat << EOF
{
    "data": {
        "type": "appInfos",
        "attributes": {
            "status": "READY_FOR_REVIEW"
        }
    },
    "relationships": {
        "app": {
            "data": {
                "type": "apps",
                "id": "$app_id"
            }
        }
    }
}
EOF
)
    
    log_info "Metadata update prepared: $metadata_updates"
    log_success "Metadata update command prepared"
}

# Upload screenshots
upload_screenshots() {
    local app_id="$1"
    local screenshot_path="$2"
    
    if [ -z "$app_id" ]; then
        log_error "App ID required for screenshot upload"
        exit 1
    fi
    
    if [ -z "$screenshot_path" ] || [ ! -d "$screenshot_path" ]; then
        log_error "Screenshot directory path required"
        exit 1
    fi
    
    log_info "Uploading screenshots for app: $app_id"
    log_info "Screenshot directory: $screenshot_path"
    
    # Process screenshots by size
    local screenshot_files=("$screenshot_path"/*.png "$screenshot_path"/*.jpg)
    
    for screenshot in "${screenshot_files[@]}"; do
        if [ -f "$screenshot" ]; then
            log_info "Processing screenshot: $(basename "$screenshot")"
            
            # Get screenshot dimensions
            local dimensions=$(identify -format "%wx%h" "$screenshot" 2>/dev/null || echo "unknown")
            log_info "Screenshot dimensions: $dimensions"
            
            # Upload screenshot (this would use the actual App Store Connect API)
            log_info "Would upload: $screenshot"
        fi
    done
    
    log_success "Screenshot upload commands prepared"
}

# Upload build
upload_build() {
    local app_id="$1"
    local build_path="$2"
    
    if [ -z "$app_id" ]; then
        log_error "App ID required for build upload"
        exit 1
    fi
    
    if [ -z "$build_path" ]; then
        log_error "Build path required"
        exit 1
    fi
    
    log_info "Uploading build for app: $app_id"
    log_info "Build path: $build_path"
    
    # Validate build
    if [ ! -d "$build_path" ] && [ ! -f "$build_path" ]; then
        log_error "Build path does not exist: $build_path"
        exit 1
    fi
    
    # Upload build using altool
    log_info "Uploading build via altool..."
    
    xcrun altool --upload-app \
        -f "$build_path" \
        -u "$APPLE_ID" \
        -p "@keychain:AC_PASSWORD" \
        -t ios \
        -v
    
    if [ $? -eq 0 ]; then
        log_success "Build uploaded successfully"
    else
        log_error "Build upload failed"
        exit 1
    fi
}

# Submit for review
submit_for_review() {
    local app_id="$1"
    local changelog="$2"
    
    if [ -z "$app_id" ]; then
        log_error "App ID required for review submission"
        exit 1
    fi
    
    log_info "Submitting app for review: $app_id"
    
    # Prepare review submission
    local review_data=$(cat << EOF
{
    "data": {
        "type": "appReviewSubmissions",
        "attributes": {
            "submittedBy": "$APPLE_ID",
            "submittedDate": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
            "reviewNotes": "$changelog"
        },
        "relationships": {
            "app": {
                "data": {
                    "type": "apps",
                    "id": "$app_id"
                }
            }
        }
    }
}
EOF
)
    
    log_info "Review submission prepared: $review_data"
    log_success "Review submission commands prepared"
}

# Create release
create_release() {
    local app_id="$1"
    local version="$2"
    local build_path="$3"
    
    if [ -z "$app_id" ]; then
        log_error "App ID required for release creation"
        exit 1
    fi
    
    if [ -z "$version" ]; then
        log_error "Version required for release creation"
        exit 1
    fi
    
    log_info "Creating release for app: $app_id, version: $version"
    
    # Create release data
    local release_data=$(cat << EOF
{
    "data": {
        "type": "appStoreVersions",
        "attributes": {
            "versionString": "$version",
            "releaseType": "manual",
            "earliestReleaseDate": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
            "usesIdfa": false,
            "contentRightsDeclaration": {
                "containsThirdPartyContent": false,
                "hasRightRightAndLeftDisplaysNoRights": false
            }
        },
        "relationships": {
            "app": {
                "data": {
                    "type": "apps",
                    "id": "$app_id"
                }
            }
        }
    }
}
EOF
)
    
    log_info "Release creation prepared: $release_data"
    log_success "Release creation commands prepared"
}

# Get app status
get_status() {
    local app_id="$1"
    
    if [ -z "$app_id" ]; then
        log_error "App ID required to get status"
        exit 1
    fi
    
    log_info "Getting status for app: $app_id"
    
    # Query App Store Connect API for app status
    log_info "Would query: https://api.appstoreconnect.apple.com/v1/apps/$app_id"
    log_success "Status query command prepared"
}

# List all apps
list_apps() {
    log_info "Listing all apps..."
    
    # Query App Store Connect API
    log_info "Would query: https://api.appstoreconnect.apple.com/v1/apps"
    log_success "App list command prepared"
}

# Download reports
download_reports() {
    local report_type="${1:-SALES}"
    local date_from="${2:-$(date -u -d "1 day ago" +"%Y-%m-%d")}"
    local date_to="${3:-$(date -u +"%Y-%m-%d")}"
    
    log_info "Downloading $report_type reports from $date_from to $date_to"
    
    # Download reports via API
    log_info "Would download reports for period: $date_from to $date_to"
    log_success "Report download commands prepared"
}

# Check review status
check_review_status() {
    local app_id="$1"
    
    if [ -z "$app_id" ]; then
        log_error "App ID required to check review status"
        exit 1
    fi
    
    log_info "Checking review status for app: $app_id"
    
    # Query review status
    log_info "Would query review status for: $app_id"
    log_success "Review status check command prepared"
}

# Generate App Store metadata templates
generate_metadata_templates() {
    log_info "Generating App Store metadata templates..."
    
    local template_dir="AppStoreMetadata"
    mkdir -p "$template_dir"
    
    # App metadata template
    cat > "$template_dir/app_metadata.json" << 'EOF'
{
    "app": {
        "name": "App Name",
        "subtitle": "App Subtitle",
        "description": "App description with detailed feature list",
        "keywords": "keyword1,keyword2,keyword3",
        "bundleId": "com.yourcompany.appname",
        "category": "productivity",
        "contentRating": "4+",
        "price": 0,
        "supportURL": "https://example.com/support",
        "marketingURL": "https://example.com/marketing",
        "privacyPolicyURL": "https://example.com/privacy"
    },
    "localization": {
        "de-DE": {
            "appStoreName": "App Name",
            "subtitle": "App Subtitle",
            "description": "Detailed description in German",
            "keywords": "keyword1,keyword2,keyword3",
            "whatsNew": "What's new in this version"
        },
        "en-US": {
            "appStoreName": "App Name",
            "subtitle": "App Subtitle", 
            "description": "Detailed description in English",
            "keywords": "keyword1,keyword2,keyword3",
            "whatsNew": "What's new in this version"
        }
    },
    "screenshots": {
        "6.7": [
            "screenshot1.png",
            "screenshot2.png",
            "screenshot3.png"
        ],
        "5.5": [
            "screenshot1.png",
            "screenshot2.png", 
            "screenshot3.png"
        ]
    },
    "review": {
        "changelog": "Release notes",
        "demoAccount": "Optional: Demo account credentials for review",
        "reviewNotes": "Additional notes for reviewers"
    }
}
EOF
    
    # Age rating template
    cat > "$template_dir/age_rating.json" << 'EOF'
{
    "contentAdvisoryRating": "4+",
    "objectionableContent": {
        "alcoholTobaccoOrDrugUseOrGambling": "none",
        "contests": "none",
        "gambling": "none",
        "horrorOrFearThemes": "none",
        "matureOrSuggestiveThemes": "none",
        "medicalOrTreatmentInformation": "none",
        "profanityOrCrudeHumor": "none",
        "sexualContentOrNudity": "none",
        "userGeneratedContent": "none",
        "violence": "none",
        "webBrowsing": "none"
    },
    "kidsAgeBand": "AGE_4_8",
    "primaryCategory": "PRODUCTIVITY",
    "secondaryCategories": []
}
EOF
    
    # Screenshot specifications
    cat > "$template_dir/screenshot_specs.json" << 'EOF'
{
    "iPhone": {
        "6.7": {
            "resolution": "1290 x 2796",
            "minimumResolution": "1284 x 2778",
            "format": "PNG or JPEG",
            "colorSpace": "sRGB or P3",
            "count": "3-10"
        },
        "6.5": {
            "resolution": "1242 x 2688",
            "minimumResolution": "1242 x 2208",
            "format": "PNG or JPEG",
            "colorSpace": "sRGB or P3",
            "count": "3-10"
        },
        "5.5": {
            "resolution": "1242 x 2208",
            "minimumResolution": "1080 x 1920",
            "format": "PNG or JPEG",
            "colorSpace": "sRGB",
            "count": "3-10"
        }
    },
    "iPad": {
        "pro_12.9": {
            "resolution": "2048 x 2732",
            "minimumResolution": "2048 x 2732",
            "format": "PNG or JPEG",
            "colorSpace": "sRGB or P3",
            "count": "3-10"
        },
        "pro_11": {
            "resolution": "1668 x 2388",
            "minimumResolution": "1668 x 2224",
            "format": "PNG or JPEG",
            "colorSpace": "sRGB or P3",
            "count": "3-10"
        }
    }
}
EOF
    
    log_success "Metadata templates generated in: $template_dir"
    log_info "Edit the templates with your app information"
}

# Main execution
main() {
    local command="$1"
    shift
    
    case "$command" in
        create-app)
            validate_requirements
            create_app "$@"
            ;;
        update-metadata)
            validate_requirements
            get_auth_token
            update_metadata "$@"
            ;;
        upload-screenshots)
            validate_requirements
            get_auth_token
            upload_screenshots "$@"
            ;;
        upload-build)
            validate_requirements
            get_auth_token
            upload_build "$@"
            ;;
        submit-for-review)
            validate_requirements
            get_auth_token
            submit_for_review "$@"
            ;;
        create-release)
            validate_requirements
            get_auth_token
            create_release "$@"
            ;;
        get-status)
            validate_requirements
            get_auth_token
            get_status "$@"
            ;;
        list-apps)
            validate_requirements
            get_auth_token
            list_apps
            ;;
        download-reports)
            validate_requirements
            get_auth_token
            download_reports "$@"
            ;;
        check-review-status)
            validate_requirements
            get_auth_token
            check_review_status "$@"
            ;;
        generate-templates)
            generate_metadata_templates
            ;;
        -h|--help|"")
            usage
            ;;
        *)
            log_error "Unknown command: $command"
            usage
            exit 1
            ;;
    esac
}

# Run main
main "$@"