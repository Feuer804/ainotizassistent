//
//  macOSUIAdaptation.swift
//  UI Adaptation for Different macOS Versions
//

import SwiftUI
import AppKit

// MARK: - UI Adaptation Manager
public class macOSUIAdaptationManager: ObservableObject {
    
    public static let shared = macOSUIAdaptationManager()
    
    private init() {}
    
    // MARK: - Public API
    
    /// Get adapted button style based on macOS version
    public func getButtonStyle() -> some ButtonStyle {
        let version = CompatibilityManager.shared.version ?? .catalina
        
        if version >= .sonoma {
            return GlassButtonStyle()
        } else if version >= .bigSur {
            return ModernButtonStyle()
        } else {
            return ClassicButtonStyle()
        }
    }
    
    /// Get adapted text field style
    public func getTextFieldStyle() -> some TextFieldStyle {
        let version = CompatibilityManager.shared.version ?? .catalina
        
        if version >= .bigSur {
            return ModernTextFieldStyle()
        } else {
            return ClassicTextFieldStyle()
        }
    }
    
    /// Get adapted card style
    public func getCardStyle() -> some ViewModifier {
        let version = CompatibilityManager.shared.version ?? .catalina
        
        if version >= .sonoma {
            return GlassCardModifier()
        } else if version >= .bigSur {
            return ModernCardModifier()
        } else {
            return ClassicCardModifier()
        }
    }
    
    /// Get adapted navigation style
    public func getNavigationStyle() -> some View {
        let version = CompatibilityManager.shared.version ?? .catalina
        
        return NavigationView {
            EmptyView()
                .navigationTitle("App")
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    /// Get system color scheme preference
    public func getColorScheme() -> ColorScheme? {
        return nil // Use system default
    }
    
    /// Check if glass effects should be used
    public func shouldUseGlassEffects() -> Bool {
        return CompatibilityManager.shared.shouldUseGlassEffects()
    }
    
    /// Get material for backgrounds
    public func getBackgroundMaterial() -> BackgroundMaterial {
        if shouldUseGlassEffects() {
            if #available(macOS 14.0, *) {
                return .regular
            } else {
                return .systemUltraThin
            }
        } else {
            return .none
        }
    }
}

// MARK: - Button Styles
struct GlassButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                    )
            )
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(.ultraThinMaterial)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct ModernButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.controlBackgroundColor)
                    .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

struct ClassicButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.controlBackgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
    }
}

// MARK: - TextField Styles
struct ModernTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .textFieldStyle(.roundedBorder)
            .controlSize(.regular)
    }
}

struct ClassicTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .textFieldStyle(.squareBorder)
            .controlSize(.regular)
    }
}

// MARK: - Card Modifiers
struct GlassCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                    )
            )
    }
}

struct ModernCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.controlBackgroundColor)
                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
            )
    }
}

struct ClassicCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.controlBackgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                    )
            )
    }
}

// MARK: - SF Symbols Adaptation
public struct SFSymbolsAdaptation {
    
    /// Get appropriate SF Symbol for feature based on macOS version
    public static func getSymbol(for feature: FeatureSupport) -> String {
        let version = CompatibilityManager.shared.version ?? .catalina
        
        switch feature {
        case .shortcutsIntegration:
            return version >= .bigSur ? "link" : "applecript"
            
        case .glassEffects:
            return version >= .sonoma ? "diamond.fill" : "square"
            
        case .enhancedVoice:
            return version >= .monterey ? "mic.circle.fill" : "mic"
            
        case .modernUI:
            return version >= .bigSur ? "sparkles" : "circle"
            
        default:
            return "checkmark.circle"
        }
    }
    
    /// Check if SF Symbol 4.0+ features are available
    public static func supportsSF4() -> Bool {
        return CompatibilityManager.shared.version ?? .catalina >= .bigSur
    }
    
    /// Get symbol palette for current macOS version
    public static func getSymbolPalette() -> [String: String] {
        let version = CompatibilityManager.shared.version ?? .catalina
        
        var palette: [String: String] = [:]
        
        if supportsSF4() {
            palette["primary"] = "link"
            palette["secondary"] = "circle.fill"
            palette["accent"] = "star.fill"
        } else {
            palette["primary"] = "check"
            palette["secondary"] = "circle"
            palette["accent"] = "star"
        }
        
        return palette
    }
}

// MARK: - Color Adaptation
public struct ColorAdaptation {
    
    /// Get primary color based on system version
    public static func getPrimaryColor() -> Color {
        let version = CompatibilityManager.shared.version ?? .catalina
        
        if version >= .bigSur {
            return Color.primary
        } else {
            return Color.black
        }
    }
    
    /// Get secondary color for current version
    public static func getSecondaryColor() -> Color {
        let version = CompatibilityManager.shared.version ?? .catalina
        
        if version >= .bigSur {
            return Color.secondary
        } else {
            return Color.gray
        }
    }
    
    /// Get background color for current version
    public static func getBackgroundColor() -> Color {
        let version = CompatibilityManager.shared.version ?? .catalina
        
        if version >= .bigSur {
            return Color(.controlBackgroundColor)
        } else {
            return Color(.controlBackgroundColor)
        }
    }
    
    /// Get accent color for current version
    public static func getAccentColor() -> Color {
        let version = CompatibilityManager.shared.version ?? .catalina
        
        if version >= .bigSur {
            return Color.accentColor
        } else {
            return Color.blue
        }
    }
}

// MARK: - Animation Adaptation
public struct AnimationAdaptation {
    
    /// Get animation timing for current version
    public static func getSpringAnimation() -> Animation {
        let version = CompatibilityManager.shared.version ?? .catalina
        
        if version >= .sonoma {
            return .spring(response: 0.4, dampingFraction: 0.8, blendDuration: 0.1)
        } else if version >= .bigSur {
            return .spring(response: 0.3, dampingFraction: 0.7)
        } else {
            return .easeInOut(duration: 0.2)
        }
    }
    
    /// Get transition animation for current version
    public static func getTransition() -> AnyTransition {
        let version = CompatibilityManager.shared.version ?? .catalina
        
        if version >= .sonoma {
            return AnyTransition.opacity
                .combined(with: .slide.combined(with: .scale))
        } else {
            return AnyTransition.opacity
        }
    }
    
    /// Check if enhanced animations are supported
    public static func supportsEnhancedAnimations() -> Bool {
        return CompatibilityManager.shared.version ?? .catalina >= .bigSur
    }
}

// MARK: - Window Management Adaptation
public struct WindowAdaptation {
    
    /// Get window style for current version
    public static func getWindowStyle() -> NSWindow.StyleMask {
        let version = CompatibilityManager.shared.version ?? .catalina
        
        var style: NSWindow.StyleMask = [.titled, .closable, .resizable]
        
        if version >= .ventura {
            style.insert(.fullSizeContentView)
        }
        
        return style
    }
    
    /// Get window title bar configuration
    public static func getTitleBarConfiguration() -> NSWindow.TitlebarSeparatorStyle {
        let version = CompatibilityManager.shared.version ?? .catalina
        
        if version >= .bigSur {
            return .shadow
        } else {
            return .automatic
        }
    }
}

// MARK: - View Modifiers
public struct VersionAwareViewModifier: ViewModifier {
    private let feature: FeatureSupport
    private let version: macOSVersion
    
    public init(feature: FeatureSupport, version: macOSVersion) {
        self.feature = feature
        self.version = version
    }
    
    public func body(content: Content) -> some View {
        let supported = CompatibilityManager.shared.supports(feature)
        let versionSupported = CompatibilityManager.shared.isVersionSupported(version)
        
        if supported && versionSupported {
            return AnyView(content)
        } else {
            return AnyView(
                content
                    .opacity(0.6)
                    .overlay(
                        Text("Nicht verfügbar")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    )
            )
        }
    }
}

// MARK: - Environment Values
extension EnvironmentValues {
    var macOSVersion: macOSVersion? {
        get { self[MacOSVersionKey.self] }
        set { self[MacOSVersionKey.self] = newValue }
    }
}

struct MacOSVersionKey: EnvironmentKey {
    static let defaultValue: macOSVersion? = CompatibilityManager.shared.version
}

// MARK: - Preview Providers
#if DEBUG
struct macOSUIAdaptation_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            Text("macOS UI Adaptation Preview")
            
            Button("Glass Button") {
                // Action
            }
            .buttonStyle(GlassButtonStyle())
            
            TextField("Enter text", text: .constant("Test"))
                .textFieldStyle(ModernTextFieldStyle())
            
            VStack {
                Text("Card Content")
                    .font(.headline)
                Text("This is a card preview")
                    .font(.subheadline)
            }
            .modifier(GlassCardModifier())
        }
        .padding()
        .frame(width: 400, height: 300)
    }
}
#endif