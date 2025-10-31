//
//  GlassModalView.swift
//  SwiftUIApp
//
//  Modal-Dialoge mit Glass-Overlay
//

import SwiftUI

// MARK: - Modal Configuration
public struct GlassModalConfiguration {
    let cornerRadius: CGFloat
    let padding: CGFloat
    let backgroundOpacity: CGFloat
    let overlayOpacity: CGFloat
    let shadowRadius: CGFloat
    let animationDuration: Double
    
    public init(
        cornerRadius: CGFloat = 24,
        padding: CGFloat = 24,
        backgroundOpacity: CGFloat = 0.15,
        overlayOpacity: CGFloat = 0.5,
        shadowRadius: CGFloat = 25,
        animationDuration: Double = 0.3
    ) {
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.backgroundOpacity = backgroundOpacity
        self.overlayOpacity = overlayOpacity
        self.shadowRadius = shadowRadius
        self.animationDuration = animationDuration
    }
}

// MARK: - Modal State Manager
public class GlassModalState: ObservableObject {
    @Published var isPresented: Bool = false
    @Published var modalType: GlassModalType = .custom
    
    public init() {}
    
    public func present(_ type: GlassModalType) {
        modalType = type
        withAnimation(.easeOut(duration: 0.3)) {
            isPresented = true
        }
    }
    
    public func dismiss() {
        withAnimation(.easeIn(duration: 0.3)) {
            isPresented = false
        }
    }
}

// MARK: - Modal Types
public enum GlassModalType {
    case alert(title: String, message: String, primaryButton: String, secondaryButton: String? = nil)
    case confirmation(title: String, message: String, actions: [GlassModalAction])
    case custom
    
    var title: String? {
        switch self {
        case .alert(let title, _, _, _): return title
        case .confirmation(let title, _, _): return title
        case .custom: return nil
        }
    }
    
    var message: String? {
        switch self {
        case .alert(_, let message, _, _): return message
        case .confirmation(_, let message, _): return message
        case .custom: return nil
        }
    }
}

// MARK: - Modal Action
public struct GlassModalAction {
    let title: String
    let style: GlassModalActionStyle
    let action: () -> Void
    
    public init(
        title: String,
        style: GlassModalActionStyle = .primary,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.style = style
        self.action = action
    }
}

public enum GlassModalActionStyle {
    case primary
    case secondary
    case destructive
    case neutral
}

// MARK: - Main Glass Modal View
public struct GlassModalView<Content: View>: View {
    private let configuration: GlassModalConfiguration
    private let content: () -> Content
    @Binding private var isPresented: Bool
    @State private var opacity: Double = 0
    @State private var scale: CGFloat = 0.8
    @State private var offsetY: CGFloat = 50
    
    public init(
        isPresented: Binding<Bool>,
        configuration: GlassModalConfiguration = GlassModalConfiguration(),
        @ViewBuilder content: @escaping () -> Content
    ) {
        self._isPresented = isPresented
        self.configuration = configuration
        self.content = content
    }
    
    public var body: some View {
        if isPresented {
            ZStack {
                // Glass Overlay
                Color.black.opacity(configuration.overlayOpacity)
                    .ignoresSafeArea()
                    .onTapGesture {
                        dismiss()
                    }
                    .opacity(opacity)
                
                // Modal Content
                VStack {
                    Spacer()
                    
                    VStack(spacing: 0) {
                        content()
                    }
                    .padding(configuration.padding)
                    .background(
                        RoundedRectangle(cornerRadius: configuration.cornerRadius)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(configuration.backgroundOpacity),
                                        Color.white.opacity(configuration.backgroundOpacity * 0.7)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .background(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: configuration.cornerRadius)
                                    .stroke(
                                        LinearGradient(
                                            colors: [
                                                Color.white.opacity(0.6),
                                                Color.white.opacity(0.3)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: configuration.cornerRadius))
                    .shadow(
                        color: Color.black.opacity(0.2),
                        radius: configuration.shadowRadius,
                        x: 0,
                        y: configuration.shadowRadius / 2
                    )
                    .scaleEffect(scale)
                    .offset(y: offsetY)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                if value.translation.height > 0 {
                                    offsetY = value.translation.height
                                }
                            }
                            .onEnded { value in
                                if value.translation.height > 100 {
                                    dismiss()
                                } else {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                        offsetY = 0
                                    }
                                }
                            }
                    )
                    
                    Spacer()
                        .frame(height: 50)
                }
            }
            .onAppear {
                withAnimation(.easeOut(duration: configuration.animationDuration)) {
                    opacity = 1
                    scale = 1
                    offsetY = 0
                }
            }
        }
    }
    
    private func dismiss() {
        withAnimation(.easeIn(duration: configuration.animationDuration)) {
            opacity = 0
            scale = 0.8
            offsetY = 50
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + configuration.animationDuration) {
            isPresented = false
        }
    }
}

// MARK: - Alert Modal
public struct GlassAlertModal: View {
    private let title: String
    private let message: String
    private let primaryButton: String
    private let secondaryButton: String?
    private let primaryAction: () -> Void
    private let secondaryAction: (() -> Void)?
    @Binding private var isPresented: Bool
    @State private var buttonScale: CGFloat = 1.0
    
    public init(
        title: String,
        message: String,
        primaryButton: String,
        secondaryButton: String? = nil,
        primaryAction: @escaping () -> Void,
        secondaryAction: (() -> Void)? = nil,
        isPresented: Binding<Bool>
    ) {
        self.title = title
        self.message = message
        self.primaryButton = primaryButton
        self.secondaryButton = secondaryButton
        self.primaryAction = primaryAction
        self.secondaryAction = secondaryAction
        self._isPresented = isPresented
    }
    
    public var body: some View {
        GlassModalView(isPresented: $isPresented) {
            VStack(spacing: 20) {
                // Header with Icon
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.orange)
                        .scaleEffect(buttonScale)
                    
                    Text(title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                }
                
                // Message
                Text(message)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button(primaryButton) {
                        withAnimation(.easeOut(duration: 0.2)) {
                            buttonScale = 0.95
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            primaryAction()
                            isPresented = false
                        }
                    }
                    .buttonStyle(GlassButtonStyle())
                    .frame(height: 50)
                    
                    if let secondaryButton = secondaryButton, let secondaryAction = secondaryAction {
                        Button(secondaryButton) {
                            secondaryAction()
                            isPresented = false
                        }
                        .buttonStyle(GlassButtonStyle(glowColor: .gray))
                        .frame(height: 50)
                    }
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                buttonScale = 1.0
            }
        }
    }
}

// MARK: - Confirmation Modal
public struct GlassConfirmationModal: View {
    private let title: String
    private let message: String
    private let actions: [GlassModalAction]
    @Binding private var isPresented: Bool
    @State private var animationOffset: CGFloat = 0
    
    public init(
        title: String,
        message: String,
        actions: [GlassModalAction],
        isPresented: Binding<Bool>
    ) {
        self.title = title
        self.message = message
        self.actions = actions
        self._isPresented = isPresented
    }
    
    public var body: some View {
        GlassModalView(isPresented: $isPresented) {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text(title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                }
                
                // Message
                Text(message)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                
                // Action Buttons
                VStack(spacing: 12) {
                    ForEach(Array(actions.enumerated()), id: \.0) { index, action in
                        Button(action.title) {
                            withAnimation(.easeOut(duration: 0.1)) {
                                animationOffset = 5
                            }
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                action.action()
                                isPresented = false
                            }
                        }
                        .buttonStyle(GlassButtonStyle(glowColor: colorForStyle(action.style)))
                        .frame(height: 50)
                        .offset(x: animationOffset)
                    }
                }
            }
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    animationOffset = 0
                }
            }
        }
    }
    
    private func colorForStyle(_ style: GlassModalActionStyle) -> Color {
        switch style {
        case .primary: return .blue
        case .secondary: return .gray
        case .destructive: return .red
        case .neutral: return .orange
        }
    }
}

// MARK: - Sheet Modal (Bottom Sheet Style)
public struct GlassSheetModal<Content: View>: View {
    private let configuration: GlassModalConfiguration
    private let content: () -> Content
    @Binding private var isPresented: Bool
    @State private var offsetY: CGFloat = 1000
    @State private var opacity: Double = 0
    
    public init(
        isPresented: Binding<Bool>,
        configuration: GlassModalConfiguration = GlassModalConfiguration(),
        @ViewBuilder content: @escaping () -> Content
    ) {
        self._isPresented = isPresented
        self.configuration = configuration
        self.content = content
    }
    
    public var body: some View {
        if isPresented {
            ZStack {
                // Glass Overlay
                Color.black.opacity(configuration.overlayOpacity)
                    .ignoresSafeArea()
                    .onTapGesture {
                        dismiss()
                    }
                    .opacity(opacity)
                
                // Sheet Content
                VStack(spacing: 0) {
                    Spacer()
                    
                    VStack(spacing: 16) {
                        // Handle
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.white.opacity(0.6))
                            .frame(width: 40, height: 4)
                            .padding(.top, 8)
                        
                        // Content
                        content()
                            .padding(.bottom, 20)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: configuration.cornerRadius)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(configuration.backgroundOpacity),
                                        Color.white.opacity(configuration.backgroundOpacity * 0.7)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .background(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: configuration.cornerRadius)
                                    .stroke(
                                        LinearGradient(
                                            colors: [
                                                Color.white.opacity(0.6),
                                                Color.white.opacity(0.3)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: configuration.cornerRadius))
                    .shadow(
                        color: Color.black.opacity(0.2),
                        radius: configuration.shadowRadius,
                        x: 0,
                        y: -configuration.shadowRadius / 2
                    )
                }
                .offset(y: offsetY)
            }
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    offsetY = 0
                    opacity = 1
                }
            }
        }
    }
    
    private func dismiss() {
        withAnimation(.easeOut(duration: configuration.animationDuration)) {
            offsetY = 1000
            opacity = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + configuration.animationDuration) {
            isPresented = false
        }
    }
}

// MARK: - Toast Notification
public struct GlassToast: View {
    private let message: String
    private let icon: String?
    private let accentColor: Color
    private let duration: Double
    @Binding private var isPresented: Bool
    @State private var toastOffset: CGFloat = -100
    @State private var toastOpacity: Double = 0
    
    public init(
        message: String,
        icon: String? = nil,
        accentColor: Color = .blue,
        duration: Double = 3.0,
        isPresented: Binding<Bool>
    ) {
        self.message = message
        self.icon = icon
        self.accentColor = accentColor
        self.duration = duration
        self._isPresented = isPresented
    }
    
    public var body: some View {
        if isPresented {
            VStack {
                HStack(spacing: 12) {
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(.title3)
                            .foregroundColor(accentColor)
                    }
                    
                    Text(message)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.15),
                                    Color.white.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .background(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    accentColor.opacity(0.4),
                                    lineWidth: 1
                                )
                        )
                )
                .shadow(
                    color: accentColor.opacity(0.3),
                    radius: 10,
                    x: 0,
                    y: 2
                )
                .offset(y: toastOffset)
                .opacity(toastOpacity)
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .onAppear {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    toastOffset = 20
                    toastOpacity = 1
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                    hide()
                }
            }
        }
    }
    
    private func hide() {
        withAnimation(.easeOut(duration: 0.3)) {
            toastOffset = -100
            toastOpacity = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isPresented = false
        }
    }
}

// MARK: - Modal Manager View
public struct GlassModalManager<Content: View>: View {
    @StateObject private var modalState = GlassModalState()
    private let content: () -> Content
    
    public init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
    
    public var body: some View {
        ZStack {
            content()
                .environmentObject(modalState)
            
            // Modal Overlay
            if modalState.isPresented {
                switch modalState.modalType {
                case .alert(let title, let message, let primaryButton, let secondaryButton):
                    GlassAlertModal(
                        title: title,
                        message: message,
                        primaryButton: primaryButton,
                        secondaryButton: secondaryButton,
                        primaryAction: { modalState.dismiss() },
                        isPresented: $modalState.isPresented
                    )
                    
                case .confirmation(let title, let message, let actions):
                    GlassConfirmationModal(
                        title: title,
                        message: message,
                        actions: actions,
                        isPresented: $modalState.isPresented
                    )
                    
                case .custom:
                    EmptyView()
                }
            }
        }
    }
}

// MARK: - Preview
struct GlassModalView_Previews: PreviewProvider {
    @State private var showAlert = false
    @State private var showConfirmation = false
    @State private var showSheet = false
    @State private var showToast = false
    @StateObject private var modalState = GlassModalState()
    
    static var previews: some View {
        GlassModalManager {
            ZStack {
                LinearGradient(
                    colors: [Color.blue.opacity(0.05), Color.purple.opacity(0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Text("Glass Modal Demo")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding()
                    
                    Button("Alert anzeigen") {
                        modalState.present(.alert(
                            title: "Achtung",
                            message: "Dies ist eine wichtige Warnung.",
                            primaryButton: "Verstanden",
                            secondaryButton: "Abbrechen"
                        ))
                    }
                    .buttonStyle(GlassButtonStyle())
                    
                    Button("Bestätigung anzeigen") {
                        modalState.present(.confirmation(
                            title: " действие bestätigen",
                            message: "Möchten Sie diese Aktion wirklich ausführen?",
                            actions: [
                                GlassModalAction(title: "Ja", style: .primary) { print("Bestätigt") },
                                GlassModalAction(title: "Nein", style: .secondary) { print("Abgebrochen") },
                                GlassModalAction(title: "Später", style: .neutral) { print("Später") }
                            ]
                        ))
                    }
                    .buttonStyle(GlassButtonStyle())
                    
                    Button("Sheet anzeigen") {
                        showSheet = true
                    }
                    .buttonStyle(GlassButtonStyle())
                    
                    Button("Toast anzeigen") {
                        showToast = true
                    }
                    .buttonStyle(GlassButtonStyle())
                }
                .padding()
            }
        }
        .sheet(isPresented: $showSheet) {
            GlassSheetModal(isPresented: $showSheet) {
                VStack(spacing: 20) {
                    Text("Bottom Sheet")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Dies ist ein Glass-Bottom-Sheet mit anpassbarem Inhalt.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button("Schließen") {
                        showSheet = false
                    }
                    .buttonStyle(GlassButtonStyle())
                    .frame(height: 50)
                }
                .padding()
            }
        }
        .overlay(alignment: .top) {
            GlassToast(
                message: "Erfolgreich gespeichert!",
                icon: "checkmark.circle.fill",
                accentColor: .green,
                isPresented: $showToast
            )
        }
    }
}