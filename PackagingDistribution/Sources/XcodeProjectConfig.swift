//
//  XcodeProjectConfig.swift
//  AINotizassistent - Xcode Project Configuration
//
//  Automatisierte Xcode Projekt-Konfiguration
//

import Foundation

/// Verwaltet Xcode Projekt-Konfiguration
class XcodeProjectConfig {
    
    // MARK: - Build Settings
    
    struct BuildSettings {
        // Optimization
        static let swiftOptimization = "-O"
        static let swiftCompilationMode = "wholemodule"
        static let enableBitcode = "NO"
        static let stripSwiftSymbols = "YES"
        static let deadStrip = "YES"
        
        // Architecture
        static let architectures = "x86_64 arm64"
        static let onlyActiveArch = "NO"
        static let validArchs = "x86_64 arm64"
        
        // Code Signing
        static let codeSignStyle = "Automatic"
        static let developmentTeam = "$(DEVELOPMENT_TEAM_ID)"
        static let provisioningStyle = "Automatic"
        static let enableUserSelections = "YES"
        
        // Warnings
        static let warningLevel = "All"
        static let treatWarningsAsErrors = "YES"
        static let otherWarningFlags = [
            "-Weverything",
            "-Wno-padded",
            "-Wno-unsafe-buffer-usage",
            "-Wno-import",
            "-Wno-c++98-compat-pedantic",
            "-Wno-c++98-compat",
            "-Wno-unknown-warning-option",
            "-Wno-reserved-id-macro",
            "-Wno-documentation-unknown-command"
        ]
        
        // Mac Catalyst
        static let macCatalystBundleIdentifier = "$(PRODUCT_BUNDLE_IDENTIFIER).mac"
        static let macCatalystAppCategory = "$(APP_CATEGORY)"
        static let macCatalystDeploymentTarget = "11.0"
        
        // Info.plist
        static let infoPlistPreprocessor = "GCC_PREPROCESSOR_DEFINITIONS"
        static let infoPlistBuildSetting = "INFOPLIST_FILE"
    }
    
    // MARK: - Code Signing Configuration
    
    struct CodeSigning {
        static let entitlements = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>com.apple.security.app-sandbox</key>
            <true/>
            <key>com.apple.security.network.client</key>
            <true/>
            <key>com.apple.security.network.server</key>
            <true/>
            <key>com.apple.security.files.user-selected.read-write</key>
            <true/>
            <key>com.apple.security.files.downloads.read-write</key>
            <true/>
            <key>com.apple.security.personal-information.addressbook</key>
            <true/>
            <key>com.apple.security.personal-information.calendars</key>
            <true/>
            <key>com.apple.security.personal-information.location</key>
            <true/>
            <key>com.apple.security.personal-information.reminders</key>
            <true/>
            <key>com.apple.security.files.appleevents.read</key>
            <true/>
            <key>com.apple.security.automation.apple-events</key>
            <true/>
        </dict>
        </plist>
        """
        
        static let hardenedRuntimeEntitlements = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>com.apple.security.app-sandbox</key>
            <false/>
            <key>com.apple.security.network.client</key>
            <true/>
            <key>com.apple.security.network.server</key>
            <true/>
            <key>com.apple.security.files.user-selected.read-write</key>
            <true/>
            <key>com.apple.security.cs.allow-jit</key>
            <true/>
            <key>com.apple.security.cs.allow-unsigned-executable-memory</key>
            <true/>
            <key>com.apple.security.cs.allow-dyld-environment-variables</key>
            <true/>
            <key>com.apple.security.cs.disable-library-validation</key>
            <true/>
            <key>com.apple.security.cs.debugger</key>
            <true/>
        </dict>
        </plist>
        """
    }
    
    // MARK: - Info.plist Optimization
    
    struct InfoPlist {
        static let requiredProperties = [
            "CFBundleDisplayName": "$(PRODUCT_NAME)",
            "CFBundleIdentifier": "$(PRODUCT_BUNDLE_IDENTIFIER)",
            "CFBundleVersion": "$(CURRENT_PROJECT_VERSION)",
            "CFBundleShortVersionString": "$(MARKETING_VERSION)",
            "CFBundlePackageType": "APPL",
            "CFBundleSignature": "????",
            "LSMinimumSystemVersion": "10.15",
            "NSHumanReadableCopyright": "Copyright © $(YEAR) $(ORGANIZATIONNAME). All rights reserved.",
            "LSApplicationCategoryType": "public.app-category.productivity",
            "NSSupportsAutomaticGraphicsSwitching": "true",
            "NSHighResolutionCapable": "true",
            "CFBundleIconFile": "$(APP_ICON_NAME)",
            "CFBundleIconName": "$(APP_ICON_NAME)"
        ]
        
        static let optionalProperties = [
            "ITSAppUsesNonExemptEncryption": "false",
            "NSLocationUsageDescription": "This app uses location for enhanced functionality",
            "NSCalendarsUsageDescription": "This app accesses calendars to create meeting reminders",
            "NSContactsUsageDescription": "This app accesses contacts to integrate with your address book",
            "NSRemindersUsageDescription": "This app accesses reminders to manage your tasks",
            "NSAppleEventsUsageDescription": "This app uses Apple Events to integrate with other applications",
            "CFBundleURLTypes": [
                [
                    "CFBundleURLName": "com.yourcompany.AINotizassistent",
                    "CFBundleURLSchemes": ["AINotizassistent"]
                ]
            ],
            "UTExportedTypeDeclarations": [
                [
                    "UTTypeIdentifier": "com.yourcompany.AINotizassistent.note",
                    "UTTypeDescription": "AI Notizassistent Note",
                    "UTTypeConformsTo": ["public.text", "public.plain-text"],
                    "UTTypeTagSpecification": [
                        "public.filename-extension": ["ainote"]
                    ]
                ]
            ]
        ]
        
        // Generate optimized Info.plist
        static func generateInfoPlist(includeOptional: Bool = true) -> [String: Any] {
            var plist = requiredProperties
            
            if includeOptional {
                plist.merge(optionalProperties) { _, new in new }
            }
            
            // Add Sparkle configuration if needed
            if includeSparkle {
                plist["SUEnableAutomaticChecks"] = "true"
                plist["SUScheduledCheckInterval"] = "86400"
                plist["SUFeedURL"] = "$(SPARKLE_FEED_URL)"
                plist["SUSignUpdateURL"] = "$(SPARKLE_PUBLIC_KEY)"
            }
            
            return plist
        }
        
        private static let includeSparkle = true
    }
    
    // MARK: - Project Template Generation
    
    /// Generiert Xcode Projekt-Konfiguration
    func generateProjectConfig(appName: String, bundleId: String, teamId: String) -> String {
        let config = """
        // !$*UTF8*$!
        {
        	archiveVersion = 1;
        	classes = {
        	};
        	objectVersion = 56;
        	objects = {
        
        /* Begin PBXBuildFile section */
        	A1000001 /* \(appName) in Sources */ = {isa = PBXBuildFile; fileRef = A1000000 /* \(appName) */; };
        /* End PBXBuildFile section */
        
        /* Begin PBXFileReference section */
        	A0FFFFFE /* \(appName).app */ = {isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = \(appName).app; sourceTree = BUILT_PRODUCTS_DIR; };
        	A1000000 /* \(appName) */ = {isa = PBXFileSource; fileEncoding = 4; lastKnownFileType = sourcecode.swift; path = \(appName); sourceTree = "<group>"; };
        /* End PBXFileReference section */
        
        /* Begin PBXFrameworksBuildPhase section */
        	A0FFFFF9 /* Frameworks */ = {
        	isa = PBXFrameworksBuildPhase;
        	buildActionMask = 2147483647;
        	files = (
        	);
        	runOnlyForDeploymentPostprocessing = 0;
        	};
        /* End PBXFrameworksBuildPhase section */
        
        /* Begin PBXGroup section */
        	A0FFFFF3 = {
        	isa = PBXGroup;
        	children = (
        		A1000002 /* \(appName) */,
        		A0FFFFF4 /* Products */,
        	);
        	sourceTree = "<group>";
        	};
        	A1000002 /* \(appName) */ = {
        	isa = PBXGroup;
        	children = (
        		A1000000 /* \(appName) */,
        	);
        	path = \(appName);
        	sourceTree = "<group>";
        	};
        	A0FFFFF4 /* Products */ = {
        	isa = PBXGroup;
        	children = (
        		A0FFFFFE /* \(appName).app */,
        	);
        	name = Products;
        	sourceTree = "<group>";
        	};
        /* End PBXGroup section */
        
        /* Begin PBXNativeTarget section */
        	A0FFFFFB /* \(appName) */ = {
        	isa = PBXNativeTarget;
        	buildConfigurationList = A1000008 /* Build configuration list for PBXNativeTarget "\(appName)" */;
        	buildPhases = (
        		A0FFFFF8 /* Sources */,
        		A0FFFFF9 /* Frameworks */,
        	);
        	buildRules = (
        	);
        	dependencies = (
        	);
        	name = \(appName);
        	productName = \(appName);
        	productReference = A0FFFFFE /* \(appName).app */;
        	productType = "com.apple.product-type.application";
        	};
        /* End PBXNativeTarget section */
        
        /* Begin PBXProject section */
        	A0FFFFF5 /* Project object */ = {
        	isa = PBXProject;
        	attributes = {
        		BuildIndependentTargetsInParallel = 1;
        		LastSwiftUpdateCheck = 1500;
        		LastUpgradeCheck = 1500;
        		TargetAttributes = {
        			A0FFFFFB = {
        				CreatedOnToolsVersion = 15.0;
        			};
        		};
        	};
        	buildConfigurationList = A0FFFFF8 /* Build configuration list for PBXProject "\(appName)" */;
        	compatibilityVersion = "Xcode 14.0";
        	developmentRegion = en;
        	hasScannedForEncodings = 0;
        	knownRegions = (
        		en,
        		Base,
        	);
        	mainGroup = A0FFFFF3;
        	productRefGroup = A0FFFFF4 /* Products */;
        	projectDirPath = "";
        	projectRoot = "";
        	targets = (
        		A0FFFFFB /* \(appName) */,
        	);
        	};
        /* End PBXProject section */
        
        /* Begin PBXSourcesBuildPhase section */
        	A0FFFFF8 /* Sources */ = {
        	isa = PBXSourcesBuildPhase;
        	buildActionMask = 2147483647;
        	files = (
        		A1000001 /* \(appName) in Sources */,
        	);
        	runOnlyForDeploymentPostprocessing = 0;
        	};
        /* End PBXSourcesBuildPhase section */
        
        /* Begin XCBuildConfiguration section */
        	A1000006 /* Debug */ = {
        	isa = XCBuildConfiguration;
        	buildSettings = {
        		ALWAYS_SEARCH_USER_PATHS = NO;
        		ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES;
        		CLANG_ANALYZER_NONNULL = YES;
        		CLANG_ANALYZER_NUMBER_OBJECT_CONVERSION = YES;
        		CLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
        		CLANG_ENABLE_MODULES = YES;
        		CLANG_ENABLE_OBJC_ARC = YES;
        		CLANG_ENABLE_OBJC_WEAK = YES;
        		CLANG_WARN_BLOCK_CAPTURE_AUTORELEASING = YES;
        		CLANG_WARN_BOOL_CONVERSION = YES;
        		CLANG_WARN_COMMA = YES;
        		CLANG_WARN_CONSTANT_CONVERSION = YES;
        		CLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS = YES;
        		CLANG_WARN_DIRECT_OBJC_ISA_USAGE = YES_ERROR;
        		CLANG_WARN_DOCUMENTATION_COMMENTS = YES;
        		CLANG_WARN_EMPTY_BODY = YES;
        		CLANG_WARN_ENUM_CONVERSION = YES;
        		CLANG_WARN_INFINITE_RECURSION = YES;
        		CLANG_WARN_INT_CONVERSION = YES;
        		CLANG_WARN_NON_LITERAL_NULL_CONVERSION = YES;
        		CLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF = YES;
        		CLANG_WARN_OBJC_LITERAL_CONVERSION = YES;
        		CLANG_WARN_OBJC_ROOT_CLASS = YES_ERROR;
        		CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER = YES;
        		CLANG_WARN_RANGE_LOOP_ANALYSIS = YES;
        		CLANG_WARN_STRICT_PROTOTYPES = YES;
        		CLANG_WARN_SUSPICIOUS_MOVE = YES;
        		CLANG_WARN_UNGUARDED_AVAILABILITY = YES_AGGRESSIVE;
        		CLANG_WARN_UNREACHABLE_CODE = YES;
        		CLANG_WARN__DUPLICATE_METHOD_MATCH = YES;
        		CODE_SIGN_IDENTITY = "Apple Development";
        		CODE_SIGN_STYLE = Automatic;
        		CURRENT_PROJECT_VERSION = 1;
        		DEVELOPMENT_ASSET_PATHS = "\"\(appName)/Preview Content\"";
        		DEVELOPMENT_TEAM = \(teamId);
        		ENABLE_PREVIEWS = YES;
        		GENERATE_INFOPLIST_FILE = YES;
        		INFOPLIST_FILE = \(appName)/Info.plist;
        		INFOPLIST_KEY_CFBundleDisplayName = "\(appName)";
        		INFOPLIST_KEY_LSApplicationCategoryType = "public.app-category.productivity";
        		INFOPLIST_KEY_NSHumanReadableCopyright = "Copyright © $(YEAR) $(ORGANIZATIONNAME). All rights reserved.";
        		INFOPLIST_KEY_NSHumanReadableCopyright = "Copyright © $(YEAR) $(ORGANIZATIONNAME). All rights reserved.";
        		IPHONEOS_DEPLOYMENT_TARGET = 17.0;
        		LD_RUNPATH_SEARCH_PATHS = (
        			"$(inherited)",
        			"@executable_path/Frameworks",
        		);
        		MARKETING_VERSION = 1.0;
        		PRODUCT_BUNDLE_IDENTIFIER = \(bundleId);
        		PRODUCT_NAME = "$(TARGET_NAME)";
        	};
        	name = Debug;
        	};
        	A1000007 /* Release */ = {
        	isa = XCBuildConfiguration;
        	buildSettings = {
        		ALWAYS_SEARCH_USER_PATHS = NO;
        		ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES;
        		CLANG_ANALYZER_NONNULL = YES;
        		CLANG_ANALYZER_NUMBER_OBJECT_CONVERSION = YES;
        		CLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
        		CLANG_ENABLE_MODULES = YES;
        		CLANG_ENABLE_OBJC_ARC = YES;
        		CLANG_ENABLE_OBJC_WEAK = YES;
        		CLANG_WARN_BLOCK_CAPTURE_AUTORELEASING = YES;
        		CLANG_WARN_BOOL_CONVERSION = YES;
        		CLANG_WARN_COMMA = YES;
        		CLANG_WARN_CONSTANT_CONVERSION = YES;
        		CLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS = YES;
        		CLANG_WARN_DIRECT_OBJC_ISA_USAGE = YES_ERROR;
        		CLANG_WARN_DOCUMENTATION_COMMENTS = YES;
        		CLANG_WARN_EMPTY_BODY = YES;
        		CLANG_WARN_ENUM_CONVERSION = YES;
        		CLANG_WARN_INFINITE_RECURSION = YES;
        		CLANG_WARN_INT_CONVERSION = YES;
        		CLANG_WARN_NON_LITERAL_NULL_CONVERSION = YES;
        		CLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF = YES;
        		CLANG_WARN_OBJC_LITERAL_CONVERSION = YES;
        		CLANG_WARN_OBJC_ROOT_CLASS = YES_ERROR;
        		CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER = YES;
        		CLANG_WARN_RANGE_LOOP_ANALYSIS = YES;
        		CLANG_WARN_STRICT_PROTOTYPES = YES;
        		CLANG_WARN_SUSPICIOUS_MOVE = YES;
        		CLANG_WARN_UNGUARDED_AVAILABILITY = YES_AGGRESSIVE;
        		CLANG_WARN_UNREACHABLE_CODE = YES;
        		CLANG_WARN__DUPLICATE_METHOD_MATCH = YES;
        		CODE_SIGN_IDENTITY = "Apple Distribution";
        		CODE_SIGN_STYLE = Automatic;
        		CURRENT_PROJECT_VERSION = 1;
        		DEVELOPMENT_ASSET_PATHS = "\"\(appName)/Preview Content\"";
        		DEVELOPMENT_TEAM = \(teamId);
        		ENABLE_PREVIEWS = YES;
        		GENERATE_INFOPLIST_FILE = YES;
        		INFOPLIST_FILE = \(appName)/Info.plist;
        		INFOPLIST_KEY_CFBundleDisplayName = "\(appName)";
        		INFOPLIST_KEY_LSApplicationCategoryType = "public.app-category.productivity";
        		INFOPLIST_KEY_NSHumanReadableCopyright = "Copyright © $(YEAR) $(ORGANIZATIONNAME). All rights reserved.";
        		IPHONEOS_DEPLOYMENT_TARGET = 17.0;
        		LD_RUNPATH_SEARCH_PATHS = (
        			"$(inherited)",
        			"@executable_path/Frameworks",
        		);
        		MARKETING_VERSION = 1.0;
        		PRODUCT_BUNDLE_IDENTIFIER = \(bundleId);
        		PRODUCT_NAME = "$(TARGET_NAME)";
        	};
        	name = Release;
        	};
        	A1000009 /* Debug */ = {
        	isa = XCBuildConfiguration;
        	buildSettings = {
        		ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES = YES;
        		CLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF = YES;
        		CLANG_WARN_OBJC_LITERAL_CONVERSION = YES;
        		CLANG_WARN_OBJC_ROOT_CLASS = YES_ERROR;
        		CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER = YES;
        		CLANG_WARN_RANGE_LOOP_ANALYSIS = YES;
        		CLANG_WARN_STRICT_PROTOTYPES = YES;
        		CLANG_WARN_SUSPICIOUS_MOVE = YES;
        		CLANG_WARN_UNREACHABLE_CODE = YES;
        		CLANG_WARN__DUPLICATE_METHOD_MATCH = YES;
        		CLANG_ANALYZER_LOCALIZABILITY_NONLOCALIZED = YES;
        		CLANG_ANALYZER_NUMBER_OBJECT_CONVERSION = YES;
        		CLANG_CXX_LANGUAGE_STANDARD = gnu17;
        		CLANG_ENABLE_CPP_EXCEPTIONS = YES;
        		CLANG_ENABLE_CPP_RTTI = YES;
        		CLANG_NO_COMMON_BLOCKS = YES;
        		CLANG_WARN_64_TO_32_BIT_CONVERSION = YES;
        		CLANG_WARN_ABOUT_RETURN_TYPE = YES;
        		CLANG_WARN_UNDECLARED_SELECTOR = YES;
        		CLANG_WARN_UNINITIALIZED_AUTOS = YES;
        		CLANG_WARN_UNUSED_FUNCTION = YES;
        		CLANG_WARN_UNUSED_VARIABLE = YES;
        		CODE_SIGN_ENTITLEMENTS = \(appName)/\(appName).entitlements;
        		CODE_SIGN_STYLE = Automatic;
        		COMBINE_HIDPI_IMAGES = YES;
        		DEBUG_INFORMATION_FORMAT = "dwarf";
        		DEVELOPMENT_TEAM = \(teamId);
        		ENABLE_HARDENED_RUNTIME = YES;
        		ENABLE_PREVIEWS = YES;
        		EXCLUDED_ARCHS = "";
        		FILE_LIST = "$(PROJECT_DIR)/\(appName).xcodeproj/GeneratedFiles/FileLists.txt";
        		GCC_C_LANGUAGE_STANDARD = gnu17;
        		GCC_DYNAMIC_NO_PIC = NO;
        		GCC_ENABLE_CPP_EXCEPTIONS = YES;
        		GCC_ENABLE_CPP_RTTI = YES;
        		GCC_ENABLE_OBJC_EXCEPTIONS = YES;
        		GCC_ENABLE_OBJC_GC = required;
        		GCC_NO_COMMON_BLOCKS = YES;
        		GCC_OPTIMIZATION_LEVEL = 0;
        		GCC_PREPROCESSOR_DEFINITIONS = (
        			"PRODUCT_NAME=\\\(appName\\\)",
        			"PRODUCT_BUNDLE_IDENTIFIER=\\\(bundleId\\\)",
        			"PRODUCT_VERSION=1.0.0",
        			"PRODUCT_BUILD=1",
        			DEBUG=1,
        		);
        		GCC_SYMBOLS_PRIVATE_EXTERN = NO;
        		GCC_WARN_64_TO_32_BIT_CONVERSION = YES;
        		GCC_WARN_ABOUT_RETURN_TYPE = YES;
        		GCC_WARN_UNDECLARED_SELECTOR = YES;
        		GCC_WARN_UNINITIALIZED_AUTOS = YES;
        		GCC_WARN_UNUSED_FUNCTION = YES;
        		GCC_WARN_UNUSED_VARIABLE = YES;
        		INFOPLIST_FILE = \(appName)/Info.plist;
        		INFOPLIST_KEY_CFBundleDisplayName = "\(appName)";
        		INFOPLIST_KEY_CFBundleExecutable = "$(EXECUTABLE_NAME)";
        		INFOPLIST_KEY_CFBundleIdentifier = "$(PRODUCT_BUNDLE_IDENTIFIER)";
        		INFOPLIST_KEY_CFBundleName = "$(PRODUCT_NAME)";
        		INFOPLIST_KEY_CFBundlePackageType = "APPL";
        		INFOPLIST_KEY_CFBundleShortVersionString = "$(MARKETING_VERSION)";
        		INFOPLIST_KEY_CFBundleVersion = "$(CURRENT_PROJECT_VERSION)";
        		INFOPLIST_KEY_LSApplicationCategoryType = "public.app-category.productivity";
        		INFOPLIST_KEY_LSMinimumSystemVersion = "10.15";
        		INFOPLIST_KEY_NSHumanReadableCopyright = "Copyright © $(YEAR) $(ORGANIZATIONNAME). All rights reserved.";
        		INFOPLIST_KEY_NSHighResolutionCapable = true;
				INFOPLIST_KEY_NSSupportsAutomaticGraphicsSwitching = true;
				IPHONEOS_DEPLOYMENT_TARGET = 17.0;
				LD = "$(LLVM_PROJECT_DIR)/usr/bin/ld";
				LDPLUSPLUS = "$(LLVM_PROJECT_DIR)/usr/bin/ld++";
				LD_DYLIB_INSTALL_NAME = "@executable_path/../Frameworks/$(DYLIB_INSTALL_NAME_BASE:s/^/lib//)";
				LD_GENERATE_MAP_FILE = NO;
				LD_MAP_FILE_PATH = "$(TARGET_TEMP_DIR)/$(PRODUCT_NAME)-$(CONFIGURATION)-LinkMap-$(CURRENT_ARCH).txt";
				LD_NO_PIE = NO;
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/../Frameworks",
				);
				LD_STRIP_STYLE = "all";
				LD_WARN_UNDECLARED_SELECTOR = NO;
				LD_ZERO_UNDEFINED = YES;
				LIBRARY_SEARCH_PATHS = (
					"\"$(SDKROOT)/usr/lib/swift\"",
					"\"$(TOOLCHAIN_DIR)/usr/lib/swift/$(PLATFORM_NAME)\"",
					"\"$(inherited)\"",
				);
				MACOSX_DEPLOYMENT_TARGET = 10.15;
				MARKETING_VERSION = 1.0;
				MTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;
				MTL_FAST_MATH = YES;
				ONLY_ACTIVE_ARCH = NO;
				OTHER_CPLUSPLUSFLAGS = "-D_GLIBCXX_USE_CXX11_ABI=1";
				PRODUCT_BUNDLE_IDENTIFIER = \(bundleId);
				PRODUCT_NAME = "$(TARGET_NAME)";
				PROVISIONING_PROFILE_SPECIFIER = "";
				SDKROOT = macosx;
				SWIFT_ACTIVE_COMPILATION_CONDITIONS = "\\\$(PRODUCT_NAME\\\\)\\\nDEBUG";
				SWIFT_COMPILATION_MODE = wholemodule;
				SWIFT_OPTIMIZATION_LEVEL = "-O";
				SWIFT_PRECOMPILE_BRIDGING_HEADER = YES;
				SWIFT_WARN_AS_ERROR = YES;
			};
			name = Debug;
		};
		A100000A /* Release */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES = YES;
				CLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF = YES;
				CLANG_WARN_OBJC_LITERAL_CONVERSION = YES;
				CLANG_WARN_OBJC_ROOT_CLASS = YES_ERROR;
				CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER = YES;
				CLANG_WARN_RANGE_LOOP_ANALYSIS = YES;
				CLANG_WARN_STRICT_PROTOTYPES = YES;
				CLANG_WARN_SUSPICIOUS_MOVE = YES;
				CLANG_WARN_UNREACHABLE_CODE = YES;
				CLANG_WARN__DUPLICATE_METHOD_MATCH = YES;
				CLANG_ANALYZER_LOCALIZABILITY_NONLOCALIZED = YES;
				CLANG_ANALYZER_NUMBER_OBJECT_CONVERSION = YES;
				CLANG_CXX_LANGUAGE_STANDARD = gnu17;
				CLANG_ENABLE_CPP_EXCEPTIONS = YES;
				CLANG_ENABLE_CPP_RTTI = YES;
				CLANG_NO_COMMON_BLOCKS = YES;
				CLANG_WARN_64_TO_32_BIT_CONVERSION = YES;
				CLANG_WARN_ABOUT_RETURN_TYPE = YES;
				CLANG_WARN_UNDECLARED_SELECTOR = YES;
				CLANG_WARN_UNINITIALIZED_AUTOS = YES;
				CLANG_WARN_UNUSED_FUNCTION = YES;
				CLANG_WARN_UNUSED_VARIABLE = YES;
				CODE_SIGN_ENTITLEMENTS = \(appName)/\(appName).entitlements;
				CODE_SIGN_STYLE = Automatic;
				COMBINE_HIDPI_IMAGES = YES;
				DEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
				DEVELOPMENT_TEAM = \(teamId);
				ENABLE_HARDENED_RUNTIME = YES;
				ENABLE_PREVIEWS = YES;
				EXCLUDED_ARCHS = "";
				FILE_LIST = "$(PROJECT_DIR)/\(appName).xcodeproj/GeneratedFiles/FileLists.txt";
				GCC_C_LANGUAGE_STANDARD = gnu17;
				GCC_DYNAMIC_NO_PIC = NO;
				GCC_ENABLE_CPP_EXCEPTIONS = YES;
				GCC_ENABLE_CPP_RTTI = YES;
				GCC_ENABLE_OBJC_EXCEPTIONS = YES;
				GCC_ENABLE_OBJC_GC = required;
				GCC_NO_COMMON_BLOCKS = YES;
				GCC_OPTIMIZATION_LEVEL = s;
				GCC_PREPROCESSOR_DEFINITIONS = (
					"PRODUCT_NAME=\\\(appName\\\)",
					"PRODUCT_BUNDLE_IDENTIFIER=\\\(bundleId\\\)",
					"PRODUCT_VERSION=1.0.0",
					"PRODUCT_BUILD=1",
				);
				GCC_SYMBOLS_PRIVATE_EXTERN = NO;
				GCC_WARN_64_TO_32_BIT_CONVERSION = YES;
				GCC_WARN_ABOUT_RETURN_TYPE = YES;
				GCC_WARN_UNDECLARED_SELECTOR = YES;
				GCC_WARN_UNINITIALIZED_AUTOS = YES;
				GCC_WARN_UNUSED_FUNCTION = YES;
				GCC_WARN_UNUSED_VARIABLE = YES;
				INFOPLIST_FILE = \(appName)/Info.plist;
				INFOPLIST_KEY_CFBundleDisplayName = "\(appName)";
				INFOPLIST_KEY_CFBundleExecutable = "$(EXECUTABLE_NAME)";
				INFOPLIST_KEY_CFBundleIdentifier = "$(PRODUCT_BUNDLE_IDENTIFIER)";
				INFOPLIST_KEY_CFBundleName = "$(PRODUCT_NAME)";
				INFOPLIST_KEY_CFBundlePackageType = "APPL";
				INFOPLIST_KEY_CFBundleShortVersionString = "$(MARKETING_VERSION)";
				INFOPLIST_KEY_CFBundleVersion = "$(CURRENT_PROJECT_VERSION)";
				INFOPLIST_KEY_LSApplicationCategoryType = "public.app-category.productivity";
				INFOPLIST_KEY_LSMinimumSystemVersion = "10.15";
				INFOPLIST_KEY_NSHumanReadableCopyright = "Copyright © $(YEAR) $(ORGANIZATIONNAME). All rights reserved.";
				INFOPLIST_KEY_NSHighResolutionCapable = true;
				INFOPLIST_KEY_NSSupportsAutomaticGraphicsSwitching = true;
				IPHONEOS_DEPLOYMENT_TARGET = 17.0;
				LD = "$(LLVM_PROJECT_DIR)/usr/bin/ld";
				LDPLUSPLUS = "$(LLVM_PROJECT_DIR)/usr/bin/ld++";
				LD_DYLIB_INSTALL_NAME = "@executable_path/../Frameworks/$(DYLIB_INSTALL_NAME_BASE:s/^/lib//)";
				LD_GENERATE_MAP_FILE = NO;
				LD_MAP_FILE_PATH = "$(TARGET_TEMP_DIR)/$(PRODUCT_NAME)-$(CONFIGURATION)-LinkMap-$(CURRENT_ARCH).txt";
				LD_NO_PIE = NO;
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/../Frameworks",
				);
				LD_STRIP_STYLE = "all";
				LD_WARN_UNDECLARED_SELECTOR = NO;
				LD_ZERO_UNDEFINED = YES;
				LIBRARY_SEARCH_PATHS = (
					"\"$(SDKROOT)/usr/lib/swift\"",
					"\"$(TOOLCHAIN_DIR)/usr/lib/swift/$(PLATFORM_NAME)\"",
					"\"$(inherited)\"",
				);
				MACOSX_DEPLOYMENT_TARGET = 10.15;
				MARKETING_VERSION = 1.0;
				MTL_ENABLE_DEBUG_INFO = NO;
				MTL_FAST_MATH = YES;
				ONLY_ACTIVE_ARCH = NO;
				OTHER_CPLUSPLUSFLAGS = "-D_GLIBCXX_USE_CXX11_ABI=1";
				PRODUCT_BUNDLE_IDENTIFIER = \(bundleId);
				PRODUCT_NAME = "$(TARGET_NAME)";
				PROVISIONING_PROFILE_SPECIFIER = "";
				SDKROOT = macosx;
				SWIFT_ACTIVE_COMPILATION_CONDITIONS = "\\\$(PRODUCT_NAME\\\\)\\\n";
				SWIFT_COMPILATION_MODE = wholemodule;
				SWIFT_OPTIMIZATION_LEVEL = "-O";
				SWIFT_PRECOMPILE_BRIDGING_HEADER = YES;
				SWIFT_WARN_AS_ERROR = YES;
				VALIDATE_PRODUCT = YES;
			};
			name = Release;
		};
		/* End XCBuildConfiguration section */
		
		/* Begin XCConfigurationList section */
		A0FFFFFC /* Build configuration list for PBXProject "\(appName)" */ = {
			isa = XCConfigurationList;
			buildConfigurations = (
				A1000006 /* Debug */,
				A1000007 /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		};
		A1000008 /* Build configuration list for PBXNativeTarget "\(appName)" */ = {
			isa = XCConfigurationList;
			buildConfigurations = (
				A1000009 /* Debug */,
				A100000A /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		};
		/* End XCConfigurationList section */
	};
	rootObject = A0FFFFF5 /* Project object */;
}
"""
        return config
    }
    
    // MARK: - Entitements Generation
    
    /// Generiert Entitlements Datei
    func generateEntitlements(appName: String, bundleId: String) -> String {
        return CodeSigning.entitlements
    }
    
    // MARK: - Info.plist Generation
    
    /// Generiert Info.plist
    func generateInfoPlist(appName: String, includeOptional: Bool = true) -> [String: Any] {
        return InfoPlist.generateInfoPlist(includeOptional: includeOptional)
    }
    
    // MARK: - Build Script Integration
    
    /// Generiert Build Script
    func generateBuildScript(appName: String, buildConfig: String = "Release") -> String {
        return """
        #!/bin/bash
        
        # Build Script für \(appName)
        echo "Building \(appName) in \(buildConfig) configuration..."
        
        # Clean previous build
        xcodebuild clean -project \(appName).xcodeproj -scheme \(appName)
        
        # Build the app
        xcodebuild build \\
            -project \(appName).xcodeproj \\
            -scheme \(appName) \\
            -configuration \(buildConfig) \\
            -derivedDataPath Build/ \\
            CODE_SIGN_STYLE=Automatic \\
            DEVELOPMENT_TEAM=\$\(DEVELOPMENT_TEAM_ID\) \\
            PRODUCT_BUNDLE_IDENTIFIER=com.yourcompany.\(appName) \\
            SWIFT_COMPILATION_MODE=wholemodule \\
            SWIFT_OPTIMIZATION_LEVEL=-O \\
            ONLY_ACTIVE_ARCH=NO \\
            ARCHS=x86_64 \\
            VALIDATE_PRODUCT=YES
        
        # Check build status
        if [ $\? -eq 0 ]; then
            echo "✅ Build successful"
            echo "App location: Build/Products/\(buildConfig)/\(appName).app"
        else
            echo "❌ Build failed"
            exit 1
        fi
        """
    }
    
    // MARK: - Project File Setup
    
    /// Erstellt komplettes Xcode Projekt
    func setupXcodeProject(appName: String, bundleId: String, teamId: String, sourcePath: String) throws {
        let projectFile = "\(sourcePath)/\(appName).xcodeproj"
        let projectDir = "\(sourcePath)/\(appName)"
        
        // Create project directory structure
        try FileManager.default.createDirectory(atPath: sourcePath, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(atPath: projectFile, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(atPath: projectDir, withIntermediateDirectories: true)
        
        // Generate project.pbxproj
        let projectConfig = generateProjectConfig(appName: appName, bundleId: bundleId, teamId: teamId)
        try projectConfig.write(toFile: "\(projectFile)/project.pbxproj", atomically: true, encoding: .utf8)
        
        // Generate entitlements
        let entitlements = generateEntitlements(appName: appName, bundleId: bundleId)
        try entitlements.write(toFile: "\(projectDir)/\(appName).entitlements", atomically: true, encoding: .utf8)
        
        // Generate Info.plist
        let infoPlist = generateInfoPlist(appName: appName, includeOptional: true)
        let plistData = try PropertyListSerialization.data(fromPropertyList: infoPlist, format: .xml, options: 0)
        try plistData.write(to: URL(fileURLWithPath: "\(projectDir)/Info.plist"))
        
        // Generate build script
        let buildScript = generateBuildScript(appName: appName)
        try buildScript.write(toFile: "\(sourcePath)/build.sh", atomically: true, encoding: .utf8)
        
        print("✅ Xcode project setup completed at: \(sourcePath)")
    }
}