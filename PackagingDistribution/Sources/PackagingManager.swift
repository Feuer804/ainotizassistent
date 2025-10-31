//
//  PackagingManager.swift
//  AINotizassistent - Packaging & Distribution System
//
//  Hauptklasse für App-Packaging und Distribution
//

import Foundation
import PackageDescription
import ShellOut
import CryptoKit

/// Hauptklassen für umfassendes App-Packaging
class PackagingManager {
    
    // MARK: - Properties
    
    private let appName: String
    private let bundleIdentifier: String
    private let version: String
    private let buildNumber: String
    private let sourcePath: String
    private let outputPath: String
    
    // MARK: - Initialization
    
    init(appName: String, bundleIdentifier: String, sourcePath: String, outputPath: String) {
        self.appName = appName
        self.bundleIdentifier = bundleIdentifier
        self.sourcePath = sourcePath
        self.outputPath = outputPath
        
        // Extract version from Info.plist
        if let versionInfo = Self.extractVersionInfo(from: "\(sourcePath)/Info.plist") {
            self.version = versionInfo.version
            self.buildNumber = versionInfo.buildNumber
        } else {
            self.version = "1.0.0"
            self.buildNumber = "1"
        }
    }
    
    // MARK: - Main Packaging Methods
    
    /// Führt den kompletten Packaging-Prozess aus
    func performCompletePackaging() async throws {
        print("🚀 Starte App-Packaging für \(appName)")
        
        try await cleanupBuildArtifacts()
        try await configureProject()
        try await buildApp()
        try await createDistributables()
        try await signApp()
        try await notarizeApp()
        try await createInstallationPackages()
        
        print("✅ Packaging erfolgreich abgeschlossen!")
    }
    
    /// App für App Store Submission vorbereiten
    func prepareAppStoreSubmission() async throws {
        print("📱 Vorbereitung für App Store Submission...")
        
        try await validateAppStoreRequirements()
        try await createAppStoreArchive()
        try await generateAppStoreAssets()
        
        print("✅ App Store Submission vorbereitet!")
    }
    
    /// App für direkte Distribution vorbereiten
    func prepareDirectDistribution() async throws {
        print("🔗 Vorbereitung für direkte Distribution...")
        
        try await validateDeveloperIDRequirements()
        try await createDirectDistributionPackages()
        
        print("✅ Direkte Distribution vorbereitet!")
    }
    
    // MARK: - Build Configuration
    
    private func configureProject() async throws {
        print("⚙️ Konfiguriere Xcode-Projekt...")
        
        let configurationScript = """
        #!/bin/bash
        
        # Build Settings Optimization
        xcodebuild -project \(sourcePath)/\(appName).xcodeproj \\
            -scheme \(appName) \\
            -configuration Release \\
            ONLY_ACTIVE_ARCH=NO \\
            ARCHS=x86_64 \\
            VALIDATE_PRODUCT=YES \\
            CLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF=YES \\
            CLANG_WARN_OBJC_LITERAL_CONVERSION=YES \\
            CLANG_WARN_OBJC_ROOT_CLASS=YES \\
            CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER=YES \\
            CLANG_WARN_RANGE_LOOP_ANALYSIS=YES \\
            CLANG_WARN_STRICT_PROTOTYPES=YES \\
            CLANG_WARN_SUSPICIOUS_MOVE=YES \\
            CLANG_WARN_UNREACHABLE_CODE=YES \\
            CLANG_WARN__DUPLICATE_METHOD_MATCH=YES \\
            CLANG_ANALYZER_LOCALIZABILITY_NONLOCALIZED=YES \\
            CLANG_ANALYZER_NUMBER_OBJECT_CONVERSION=YES \\
            GCC_C_LANGUAGE_STANDARD=gnu17 \\
            GCC_ENABLE_CPP_EXCEPTIONS=YES \\
            GCC_ENABLE_CPP_RTTI=YES \\
            GCC_NO_COMMON_BLOCKS=YES \\
            GCC_PREPROCESSOR_DEFINITIONS=("PRODUCT_NAME=\\(appName)\\" "PRODUCT_BUNDLE_IDENTIFIER=\\(bundleIdentifier)\\" "PRODUCT_VERSION=\\(version)\\" "PRODUCT_BUILD=\\(buildNumber)\\" DEBUG=\\(DEBUG\\)) \\
            GCC_WARN_64_TO_32_BIT_CONVERSION=YES \\
            GCC_WARN_ABOUT_RETURN_TYPE=YES \\
            GCC_WARN_UNDECLARED_SELECTOR=YES \\
            GCC_WARN_UNINITIALIZED_AUTOS=YES \\
            GCC_WARN_UNUSED_FUNCTION=YES \\
            GCC_WARN_UNUSED_VARIABLE=YES \\
            MACOSX_DEPLOYMENT_TARGET=11.0 \\
            MTL_ENABLE_DEBUG_INFO=NO \\
            OTHER_CPLUSPLUSFLAGS="-D_GLIBCXX_USE_CXX11_ABI=1" \\
            SDKROOT=macosx \\
            SWIFT_ACTIVE_COMPILATION_CONDITIONS="\\\(PRODUCT_NAME\\\\)\\" \\
            SWIFT_OPTIMIZATION_LEVEL="-O" \\
            SWIFT_COMPILATION_MODE=wholemodule \\
            SWIFT_WARN_AS_ERROR=YES
        """
        
        try FileManager.default.createFile(
            atPath: "\(outputPath)/Scripts/configure_xcode.sh",
            contents: configurationScript.data(using: .utf8)
        )
        
        try await executeShellScript("\(outputPath)/Scripts/configure_xcode.sh")
    }
    
    // MARK: - Code Signing
    
    private func signApp() async throws {
        print("🔐 Code Signing...")
        
        // Developer ID Signing
        try await signWithDeveloperID()
        
        // Entitlements verification
        try await verifyEntitlements()
    }
    
    private func signWithDeveloperID() async throws {
        let signingScript = """
        #!/bin/bash
        
        # Developer ID Signing
        APP_PATH="\(outputPath)/Build/Release/\(appName).app"
        BUNDLE_ID="\(bundleIdentifier)"
        TEAM_ID=$(security find-identity -v -p codesigning | grep "Developer ID Application:" | head -1 | awk '{print $2}' | cut -d'=' -f2 | tr -d '"')
        
        echo "Signing with Developer ID..."
        xcodebuild -project \(sourcePath)/\(appName).xcodeproj \\
            -scheme \(appName) \\
            -configuration Release \\
            CODE_SIGN_STYLE=Automatic \\
            DEVELOPMENT_TEAM=$TEAM_ID \\
            CODE_SIGN_IDENTITY="Developer ID Application: $TEAM_ID" \\
            PRODUCT_BUNDLE_IDENTIFIER=$BUNDLE_ID \\
            CODE_SIGN_ENTITLEMENTS="\(sourcePath)/\(appName)/\(appName).entitlements" \\
            CODE_SIGN_SPECS="\(sourcePath)/\(appName)/\(appName).codesign"
        
        # Verify signature
        codesign -v --verbose=4 "$APP_PATH"
        spctl -t exec -vv "$APP_PATH"
        """
        
        try FileManager.default.createFile(
            atPath: "\(outputPath)/Scripts/sign_app.sh",
            contents: signingScript.data(using: .utf8)
        )
        
        try await executeShellScript("\(outputPath)/Scripts/sign_app.sh")
    }
    
    // MARK: - Notarization
    
    private func notarizeApp() async throws {
        print("📋 Notarization...")
        
        let notarizationScript = """
        #!/bin/bash
        
        # Notarization für Mac App Store Compliance
        APP_PATH="\(outputPath)/Build/Release/\(appName).app"
        APP_ZIP="$APP_PATH.zip"
        APP_DMG="$APP_PATH.dmg"
        
        # Create ZIP for notarization
        cd \(outputPath)/Build/Release
        zip -r \(appName).app.zip \(appName).app
        
        # Submit for notarization
        echo "Submitting for notarization..."
        xcrun notarytool submit \(appName).app.zip \\
            --keychain-profile "NOTARIZATION_PROFILE" \\
            --wait
        
        # Staple the notarization
        xcrun stapler staple \(appName).app
        
        # Create DMG for distribution
        createDMG
        """
        
        try FileManager.default.createFile(
            atPath: "\(outputPath)/Scripts/notarize_app.sh",
            contents: notarizationScript.data(using: .utf8)
        )
        
        try await executeShellScript("\(outputPath)/Scripts/notarize_app.sh")
    }
    
    // MARK: - Installation Packages
    
    private func createInstallationPackages() async throws {
        print("📦 Erstelle Installations-Pakete...")
        
        try await createPKGInstaller()
        try await createDMG()
        try await createZIPArchive()
        try await createCodeSigningVerification()
    }
    
    private func createPKGInstaller() async throws {
        let pkgScript = """
        #!/bin/bash
        
        # PKG Installer Creation
        APP_NAME="\(appName)"
        APP_PATH="$APP_PATH"
        VERSION="\(version)"
        BUILD_NUMBER="\(buildNumber)"
        
        # Create PKG installer
        pkgbuild --root "$APP_PATH" \\
            --identifier "\(bundleIdentifier)" \\
            --version "$VERSION.$BUILD_NUMBER" \\
            --install-location "/Applications" \\
            "\(outputPath)/Distribution/$APP_NAME-$VERSION.pkg"
        
        # Sign PKG installer
        productsign --sign "Developer ID Installer: $TEAM_ID" \\
            "\(outputPath)/Distribution/$APP_NAME-$VERSION.pkg" \\
            "\(outputPath)/Distribution/$APP_NAME-$VERSION-signed.pkg"
        
        # Notarize PKG installer
        xcrun notarytool submit "\(outputPath)/Distribution/$APP_NAME-$VERSION-signed.pkg" \\
            --keychain-profile "NOTARIZATION_PROFILE" \\
            --wait
        
        # Staple PKG installer
        xcrun stapler staple "\(outputPath)/Distribution/$APP_NAME-$VERSION-signed.pkg"
        """
        
        try FileManager.default.createFile(
            atPath: "\(outputPath)/Scripts/create_pkg.sh",
            contents: pkgScript.data(using: .utf8)
        )
    }
    
    private func createDMG() async throws {
        let dmgScript = """
        #!/bin/bash
        
        # Custom DMG Creation
        APP_NAME="\(appName)"
        APP_PATH="$APP_PATH"
        DMG_BACKGROUND="\(sourcePath)/Resources/dmg_background.png"
        DMG_NAME="$APP_NAME-v\(version)"
        DMG_PATH="\(outputPath)/Distribution/$DMG_NAME.dmg"
        
        # Create temporary folder structure
        mkdir -p "/tmp/dmg_build"
        cp -R "$APP_PATH" "/tmp/dmg_build/"
        cp -R "\(sourcePath)/Resources/shortcuts" "/tmp/dmg_build/"
        
        # Apply custom background and icons
        if [ -f "$DMG_BACKGROUND" ]; then
            # Setup custom background for DMG
            mkdir -p "/tmp/dmg_build/.background"
            cp "$DMG_BACKGROUND" "/tmp/dmg_build/.background/"
        fi
        
        # Create DMG
        hdiutil create -srcfolder "/tmp/dmg_build" \\
            -volname "$APP_NAME" \\
            -fs HFS+ \\
            -fsargs "-c c=64,a=16,e=16" \\
            -format UDZO \\
            "$DMG_PATH"
        
        # Sign DMG
        codesign --sign "Developer ID Application: $TEAM_ID" "$DMG_PATH"
        
        # Cleanup
        rm -rf "/tmp/dmg_build"
        
        echo "DMG created: $DMG_PATH"
        """
        
        try FileManager.default.createFile(
            atPath: "\(outputPath)/Scripts/create_dmg.sh",
            contents: dmgScript.data(using: .utf8)
        )
    }
    
    // MARK: - Utility Methods
    
    private static func extractVersionInfo(from plistPath: String) -> (version: String, buildNumber: String)? {
        guard let plistData = try? Data(contentsOf: URL(fileURLWithPath: plistPath)),
              let plist = try? PropertyListSerialization.propertyList(from: plistData, format: nil) as? [String: Any] else {
            return nil
        }
        
        let version = plist["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let buildNumber = plist["CFBundleVersion"] as? String ?? "1"
        
        return (version, buildNumber)
    }
    
    private func executeShellScript(_ scriptPath: String) async throws {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/bash")
        task.arguments = ["-c", scriptPath]
        task.currentDirectoryURL = URL(fileURLWithPath: outputPath)
        
        try task.run()
        task.waitUntilExit()
        
        if task.terminationStatus != 0 {
            throw PackagingError.shellScriptFailed(scriptPath)
        }
    }
    
    private func cleanupBuildArtifacts() async throws {
        try FileManager.default.removeItem(atPath: "\(outputPath)/Build")
        try FileManager.default.removeItem(atPath: "\(outputPath)/Distribution")
        
        try FileManager.default.createDirectory(atPath: "\(outputPath)/Build", withIntermediateDirectories: true)
        try FileManager.default.createDirectory(atPath: "\(outputPath)/Distribution", withIntermediateDirectories: true)
    }
}

// MARK: - Supporting Structures

extension PackagingManager {
    struct PackagingConfiguration {
        let appName: String
        let bundleIdentifier: String
        let version: String
        let buildNumber: String
        let teamID: String
        let signingIdentity: String
        let entitlementsPath: String
        let appIconPath: String
        let screenshotsPath: String
    }
    
    enum PackagingError: Error {
        case shellScriptFailed(String)
        case missingRequiredFile(String)
        case signingFailed
        case notarizationFailed
        case validationFailed(String)
    }
}