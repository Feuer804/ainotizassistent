//
//  GlassTextField.swift
//  SwiftUIApp
//
//  Input-Felder mit frosted glass styling
//

import SwiftUI

// MARK: - Text Field Configuration
public struct GlassTextFieldConfiguration {
    let cornerRadius: CGFloat
    let padding: CGFloat
    let backgroundOpacity: CGFloat
    let borderOpacity: CGFloat
    let focusRingOpacity: CGFloat
    let shadowRadius: CGFloat
    let isSecure: Bool
    
    public init(
        cornerRadius: CGFloat = 16,
        padding: CGFloat = 16,
        backgroundOpacity: CGFloat = 0.1,
        borderOpacity: CGFloat = 0.3,
        focusRingOpacity: CGFloat = 0.4,
        shadowRadius: CGFloat = 15,
        isSecure: Bool = false
    ) {
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.backgroundOpacity = backgroundOpacity
        self.borderOpacity = borderOpacity
        self.focusRingOpacity = focusRingOpacity
        self.shadowRadius = shadowRadius
        self.isSecure = isSecure
    }
}

// MARK: - Main Glass Text Field
public struct GlassTextField<Content: View>: View {
    private let configuration: GlassTextFieldConfiguration
    private let placeholder: String
    private let icon: String?
    private let accentColor: Color
    private let isEnabled: Bool
    private let content: () -> Content
    @Binding private var text: String
    @FocusState private var isFocused: Bool
    
    public init(
        text: Binding<String>,
        placeholder: String,
        icon: String? = nil,
        accentColor: Color = .blue,
        isEnabled: Bool = true,
        configuration: GlassTextFieldConfiguration = GlassTextFieldConfiguration(),
        @ViewBuilder content: @escaping () -> Content = { EmptyView() }
    ) {
        self._text = text
        self.placeholder = placeholder
        self.icon = icon
        self.accentColor = accentColor
        self.isEnabled = isEnabled
        self.configuration = configuration
        self.content = content
    }
    
    public var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                // Icon
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(
                            isFocused ? accentColor.opacity(0.8) : .secondary
                        )
                        .frame(width: 20, height: 20)
                }
                
                // Text Content
                content()
                    .disabled(!isEnabled)
                
                Spacer()
            }
            .padding(configuration.padding)
            .background(
                RoundedRectangle(cornerRadius: configuration.cornerRadius)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(configuration.backgroundOpacity),
                                Color.white.opacity(configuration.backgroundOpacity * 0.5)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .background(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: configuration.cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [
                                isFocused 
                                    ? accentColor.opacity(configuration.focusRingOpacity)
                                    : Color.white.opacity(configuration.borderOpacity),
                                isFocused
                                    ? accentColor.opacity(configuration.focusRingOpacity * 0.5)
                                    : Color.white.opacity(configuration.borderOpacity * 0.5)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: isFocused ? 2 : 1
                    )
            )
            .shadow(
                color: isFocused 
                    ? accentColor.opacity(0.3)
                    : Color.black.opacity(0.1),
                radius: isFocused 
                    ? configuration.shadowRadius
                    : configuration.shadowRadius / 2,
                x: 0,
                y: isFocused 
                    ? configuration.shadowRadius / 3
                    : configuration.shadowRadius / 4
            )
            .scaleEffect(isEnabled ? 1.0 : 0.98)
            .animation(.easeOut(duration: 0.2), value: isFocused)
            .animation(.easeOut(duration: 0.2), value: isEnabled)
        }
    }
}

// MARK: - Specialized Text Field Types
public struct GlassSecureTextField: View {
    @Binding private var text: String
    @Binding private var isVisible: Bool
    private let placeholder: String
    private let accentColor: Color
    private let configuration: GlassTextFieldConfiguration
    @FocusState private var isFocused: Bool
    
    public init(
        text: Binding<String>,
        placeholder: String = "",
        accentColor: Color = .blue,
        configuration: GlassTextFieldConfiguration = GlassTextFieldConfiguration(isSecure: true)
    ) {
        self._text = text
        self._isVisible = .constant(false)
        self.placeholder = placeholder
        self.accentColor = accentColor
        self.configuration = configuration
    }
    
    public var body: some View {
        GlassTextField(
            text: $text,
            placeholder: placeholder,
            accentColor: accentColor,
            configuration: configuration
        ) {
            Group {
                if isVisible {
                    TextField(placeholder, text: $text)
                        .textContentType(.password)
                } else {
                    SecureField(placeholder, text: $text)
                        .textContentType(.password)
                }
            }
            .focused($isFocused)
            .font(.body)
            .foregroundColor(.primary)
        }
        .overlay(alignment: .trailing) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isVisible.toggle()
                }
            } label: {
                Image(systemName: isVisible ? "eye.slash" : "eye")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
                    .padding(.trailing, configuration.padding)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}

public struct GlassSearchField: View {
    @Binding private var text: String
    private let placeholder: String
    private let accentColor: Color
    private let onSearch: (() -> Void)?
    @FocusState private var isFocused: Bool
    
    public init(
        text: Binding<String>,
        placeholder: String = "Suchen...",
        accentColor: Color = .blue,
        onSearch: (() -> Void)? = nil
    ) {
        self._text = text
        self.placeholder = placeholder
        self.accentColor = accentColor
        self.onSearch = onSearch
    }
    
    public var body: some View {
        GlassTextField(
            text: $text,
            placeholder: placeholder,
            icon: "magnifyingglass",
            accentColor: accentColor
        ) {
            TextField(placeholder, text: $text)
                .focused($isFocused)
                .font(.body)
                .foregroundColor(.primary)
                .onSubmit {
                    onSearch?()
                }
        }
        .overlay(alignment: .trailing) {
            if !text.isEmpty {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        text = ""
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                        .padding(.trailing, 16)
                }
                .buttonStyle(PlainButtonStyle())
                .transition(.scale.combined(with: .opacity))
            }
        }
    }
}

public struct GlassMultiLineTextField: View {
    @Binding private var text: String
    private let placeholder: String
    private let accentColor: Color
    private let minHeight: CGFloat
    private let maxHeight: CGFloat
    private let configuration: GlassTextFieldConfiguration
    @FocusState private var isFocused: Bool
    
    public init(
        text: Binding<String>,
        placeholder: String = "",
        accentColor: Color = .blue,
        minHeight: CGFloat = 100,
        maxHeight: CGFloat = 300,
        configuration: GlassTextFieldConfiguration = GlassTextFieldConfiguration()
    ) {
        self._text = text
        self.placeholder = placeholder
        self.accentColor = accentColor
        self.minHeight = minHeight
        self.maxHeight = maxHeight
        self.configuration = configuration
    }
    
    public var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            GlassTextField(
                text: $text,
                placeholder: placeholder,
                accentColor: accentColor,
                configuration: configuration
            ) {
                TextField(placeholder, text: $text, axis: .vertical)
                    .focused($isFocused)
                    .font(.body)
                    .foregroundColor(.primary)
                    .lineLimit(1...10)
                    .frame(minHeight: minHeight, maxHeight: maxHeight, alignment: .topLeading)
            }
            .frame(minHeight: minHeight, maxHeight: maxHeight)
        }
    }
}

// MARK: - Form Container with Glass Effect
public struct GlassFormContainer<Content: View>: View {
    private let title: String?
    private let subtitle: String?
    private let spacing: CGFloat
    private let content: () -> Content
    
    public init(
        title: String? = nil,
        subtitle: String? = nil,
        spacing: CGFloat = 20,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.spacing = spacing
        self.content = content
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            // Header
            if let title = title {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 4)
            }
            
            // Form Content
            content()
        }
    }
}

// MARK: - Input Validation Display
public struct GlassInputError: View {
    let message: String
    let accentColor: Color
    
    public init(message: String, accentColor: Color = .red) {
        self.message = message
        self.accentColor = accentColor
    }
    
    public var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.caption)
                .foregroundColor(accentColor)
            
            Text(message)
                .font(.caption)
                .foregroundColor(accentColor)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(accentColor.opacity(0.1))
                .background(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(accentColor.opacity(0.3), lineWidth: 1)
        )
        .transition(.opacity.combined(with: .scale))
    }
}

public struct GlassInputSuccess: View {
    let message: String
    let accentColor: Color = .green
    
    public init(message: String) {
        self.message = message
    }
    
    public var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.caption)
                .foregroundColor(accentColor)
            
            Text(message)
                .font(.caption)
                .foregroundColor(accentColor)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(accentColor.opacity(0.1))
                .background(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(accentColor.opacity(0.3), lineWidth: 1)
        )
        .transition(.opacity.combined(with: .scale))
    }
}

// MARK: - View Extension
extension View {
    public func glassFormField<Content: View>(
        _ title: String? = nil,
        subtitle: String? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if let title = title {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .padding(.horizontal, 4)
            }
            
            content()
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
            }
        }
    }
}

// MARK: - Preview
struct GlassTextField_Previews: PreviewProvider {
    @State static var searchText = ""
    @State static var secureText = ""
    @State static var emailText = ""
    @State static var descriptionText = ""
    @State static var showError = false
    @State static var showSuccess = false
    
    static var previews: some View {
        ZStack {
            LinearGradient(
                colors: [Color.blue.opacity(0.05), Color.purple.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 30) {
                    GlassFormContainer(title: "Login Details", spacing: 20) {
                        GlassTextField(
                            text: $emailText,
                            placeholder: "E-Mail-Adresse",
                            icon: "envelope",
                            accentColor: .blue
                        )
                        
                        GlassSecureTextField(
                            text: $secureText,
                            placeholder: "Passwort",
                            accentColor: .purple
                        )
                        
                        if showError {
                            GlassInputError(message: "E-Mail-Adresse ist ungültig")
                        }
                        
                        if showSuccess {
                            GlassInputSuccess(message: "Eingabe erfolgreich")
                        }
                    }
                    
                    GlassFormContainer(title: "Suche", spacing: 20) {
                        GlassSearchField(text: $searchText) {
                            print("Suche gestartet: \(searchText)")
                        }
                        
                        if !searchText.isEmpty {
                            Text("Suchergebnisse für: \(searchText)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 8)
                        }
                    }
                    
                    GlassFormContainer(title: "Beschreibung", spacing: 20) {
                        GlassMultiLineTextField(
                            text: $descriptionText,
                            placeholder: "Beschreiben Sie Ihr Anliegen...",
                            minHeight: 120
                        )
                    }
                    
                    HStack(spacing: 16) {
                        Button("Fehler anzeigen") {
                            withAnimation {
                                showError.toggle()
                                showSuccess = false
                            }
                        }
                        .buttonStyle(GlassButtonStyle())
                        
                        Button("Erfolg anzeigen") {
                            withAnimation {
                                showSuccess.toggle()
                                showError = false
                            }
                        }
                        .buttonStyle(GlassButtonStyle())
                    }
                }
                .padding()
            }
        }
    }
}