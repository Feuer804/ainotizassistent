# Window-Management System mit Animationen

Ein vollständiges Window-Management System für macOS Status Bar Apps mit popup-ähnlichen Animationen, Blur-Effekten und erweiterten Window-Funktionen.

## 🎯 Features

### ✅ Window-Management
- **Popup-Fenster** mit Glass-Effekt und Blur-Hintergrund
- **Custom NSWindowSubclass** mit modernem macOS Design
- **Window opening/closing Animationen** (scale, fade, bounce, slide)
- **Intelligente Window-Positionierung** und Größenmanagement
- **Multi-window support** mit Z-Index Management
- **Detachable popup windows** mit Drag-Funktionalität
- **ESC Closing** für alle Window-Typen

### ✅ Animation System
- **Core Animation Integration** mit NSAnimationContext
- **Erweiterte Animationstypen**:
  - Scale-Up/Down Animationen
  - Slide-Up/Down Animationen
  - Bounce-Effekte mit physikalischen Eigenschaften
  - Fade In/Out Transitionen
  - Slide from Left/Right Animationen
- **Custom Animation Helper** mit:
  - Blur-Effekte mit CIFilter
  - Glow-Effekte mit Core Animation
  - Shake-Animationen für Feedback
  - Pulse-Animationen (kontinuierlich)
  - Rotation-Animationen
  - Crossfade-Transitionen

### ✅ Window-Positionierung
- **Flexible Positionierungsoptionen**:
  - Top/Bottom/Left/Right Center
  - Alle Ecken-Positionen
  - Relative Positionierung zum Status Item
  - Screen-bewusste Positionierung
- **Multi-Window Layouts**:
  - Grid-Organisation
  - Vertikale Stapelung
  - Kaskade-Layout
- **Z-Index Management** mit automatischer Layer-Verwaltung

### ✅ Erweiterte Features
- **Keyboard Shortcuts** für alle Funktionen
- **Dark/Light Mode Support** mit automatischen Material-Anpassungen
- **Reserved Area Management** für kollisionsfreie Positionierung
- **Window State Management** (attached/detached)
- **Responsive Design** für verschiedene Bildschirmauflösungen

## 🏗️ Architektur

### Hauptkomponenten

#### 1. `WindowManager.swift` 
**Zentrale Verwaltung aller Fenster**
- Singleton-Pattern für globalen Zugriff
- Window-Lifecycle Management
- Event-Handling für ESC-Tasten
- Delegate-Pattern für Status-Updates
- Animation-Queue für mehrere gleichzeitige Operationen

```swift
// Beispiel: Window öffnen
WindowManager.shared.openPopupWindow(
    with: viewController,
    animation: .bounce,
    size: CGSize(width: 400, height: 300),
    shouldCloseOnEsc: true
)
```

#### 2. `PopupWindow.swift`
**Custom NSWindow mit modernem Design**
- NSVisualEffectView Integration für Blur-Effekte
- Automatische abgerundete Ecken mit Mask
- Theme-Aware Material-Support (.light/.dark/.underWindowBackground)
- Erweiterte Shadow-Konfiguration
- macOS-spezifische Window-Eigenschaften

```swift
// Beispiel: Blur aktivieren
popupWindow.setBlurEnabled(true)
popupWindow.setMaterial(.underWindowBackground)
```

#### 3. `AnimatedWindowController.swift`
**NSWindowController mit Animationen**
- Erweiterte NSWindowController-Funktionalität
- Sechs verschiedene Animationstypen
- Physikalisch korrekte Animation-Timing-Funktionen
- Chained Animations für komplexe Effekte
- Detachable Window Support

#### 4. `DetachableWindowController.swift`
**Erweiterte Window-Funktionalität**
- Drag & Drop für Window-Positionierung
- Automatic Detachment bei Überschreitung einer Distanz
- Re-attachment-Funktionalität
- Window State Management (attached/detached)
- Custom Drag Areas mit NSView Subclasses

#### 5. `WindowPositionManager.swift`
**Intelligente Window-Positionierung**
- Acht Positionierungsoptionen
- Multi-Screen Support
- Collision Detection mit reserved Areas
- Z-Index Registry
- Grid/Stack/Cascade Layouts

#### 6. `WindowAnimationHelper.swift`
**Erweiterte Animation-Effekte**
- Core Animation Integration
- CIFilter Support für Blur-Effekte
- Glow-Effekte mit Shadow-Konfiguration
- Physikalische Simulation (Shake/Bounce)
- Timer-basierte Animationen (Pulse)

#### 7. `DemoPopupViewController.swift`
**Demonstration und Testing**
- Vollständig funktionsfähige Demo-UI
- Interaktive Animation-Tests
- Live-Effekt-Testing
- Keyboard Shortcuts für alle Features

## 🚀 Installation

### Voraussetzungen
- macOS 10.15+
- Xcode 12+
- Swift 5.3+

### Integration

1. **Alle Dateien zum Xcode-Projekt hinzufügen:**
   ```
   WindowManager.swift
   PopupWindow.swift
   AnimatedWindowController.swift
   DetachableWindowController.swift
   WindowPositionManager.swift
   WindowAnimationHelper.swift
   DemoPopupViewController.swift
   ```

2. **AppDelegate erweitern:**
   ```swift
   class AppDelegate: NSObject, NSApplicationDelegate, WindowManagerDelegate {
       func applicationDidFinishLaunching(_ aNotification: Notification) {
           WindowManager.shared.delegate = self
           // ...
       }
   }
   ```

3. **Status Bar Menu erweitern:**
   ```swift
   // In StatusBarController.createMenuItems()
   let demoPopupItem = NSMenuItem(
       title: "Demo Popup öffnen",
       action: #selector(showDemoPopup(_:)),
       keyEquivalent: "1"
   )
   ```

## 📖 Verwendung

### Grundlegende Window-Operationen

#### Popup-Window öffnen
```swift
let demoVC = DemoPopupViewController()
WindowManager.shared.openPopupWindow(
    with: demoVC,
    animation: .bounce,
    size: CGSize(width: 400, height: 300),
    shouldCloseOnEsc: true
)
```

#### Detachable Window
```swift
WindowManager.shared.showDetachablePopup(
    with: viewController,
    size: CGSize(width: 500, height: 400)
)
```

#### Alle Windows schließen
```swift
WindowManager.shared.closeAllWindows(animation: .fade)
```

### Animation-Effekte

#### Blur-Effekt
```swift
WindowAnimationHelper.shared.applyBlurEffect(
    to: window,
    intensity: 0.8
)
```

#### Glow-Effekt
```swift
WindowAnimationHelper.shared.applyGlowEffect(
    to: window,
    color: .systemBlue,
    radius: 20.0
)
```

#### Shake-Animation
```swift
WindowAnimationHelper.shared.shakeWindow(
    window,
    intensity: 10.0,
    duration: 0.5
)
```

#### Pulse-Animation
```swift
WindowAnimationHelper.shared.pulseWindow(
    window,
    scale: 1.05,
    duration: 1.0
)
```

### Window-Positionierung

#### Position setzen
```swift
WindowPositionManager.shared.positionWindow(
    window,
    at: .topCenter
)
```

#### Grid-Layout
```swift
let windows = [window1, window2, window3]
WindowPositionManager.shared.organizeWindowsInGrid(windows, columns: 2)
```

#### Vertical Stacking
```swift
WindowPositionManager.shared.stackWindowsVertically(windows, offset: 30)
```

## 🎮 Demo-Funktionen

### Status Bar Menu
1. **Demo Popup öffnen** (⌘1) - Öffnet ein popup-Window mit allen Animationen
2. **Detachable Window** (⌘2) - Öffnet ein verschiebbares Window
3. **Multi-Window Demo** (⌘3) - Öffnet mehrere Windows gleichzeitig
4. **Alle Windows schließen** (⌘W) - Schließt alle offenen Windows

### Demo Window Features
- **Animation Buttons** - Testen aller Animationstypen
- **Effect Buttons** - Testen aller visuellen Effekte
- **ESC Key** - Schließt das Window
- **Space Key** - Aktiviert Pulse-Animation
- **Enter Key** - Schließt das Window

### Keyboard Shortcuts
- **⌘1** - Demo Popup öffnen
- **⌘2** - Detachable Window öffnen
- **⌘3** - Multi-Window Demo
- **⌘W** - Alle Windows schließen
- **⌘⇧N** - Global Shortcut (falls konfiguriert)
- **ESC** - Window schließen (wenn enabled)
- **Space** - Pulse-Animation
- **Enter** - Window schließen

## 🎨 Anpassung

### Eigene Animationen hinzufügen
```swift
// In AnimatedWindowController.swift
private func animateCustom(opening: Bool, completion: (() -> Void)?) {
    // Custom Animation Logic
    NSAnimationContext.runAnimationGroup({ context in
        context.duration = 0.5
        context.timingFunction = CAMediaTimingFunction(name: .easeOut)
        
        // Animation ausführen
    }, completionHandler: {
        completion?()
    })
}
```

### Eigene Positionierungslogik
```swift
// In WindowPositionManager.swift
private func calculateCustomPosition(for size: CGSize, screenRect: CGRect) -> NSRect {
    // Custom Positioning Logic
    return targetRect
}
```

### Theme-Anpassung
```swift
// Dark Mode aktivieren
popupWindow.applyDarkModeMaterial()

// Light Mode aktivieren  
popupWindow.applyLightModeMaterial()

// Modern macOS Style
popupWindow.applyModernMacOSStyle()
```

## 🔧 Erweiterte Konfiguration

### Window-Properties anpassen
```swift
// Animation-Dauer ändern
let controller = AnimatedWindowController()
controller.animationDuration = 0.5

// ESC-Handling konfigurieren
controller.shouldCloseOnEsc = true
controller.closeBehavior = .detached
```

### Z-Index Management
```swift
// Window nach vorne bringen
WindowPositionManager.shared.bringToFront(window)

// Z-Index manuell setzen
WindowPositionManager.shared.setZIndex(window, level: 2000)
```

### Reserved Areas
```swift
// Bereich für andere Windows reservieren
let reservedRect = CGRect(x: 100, y: 100, width: 200, height: 100)
WindowPositionManager.shared.reserveArea(reservedRect)
```

## 📊 Performance

### Optimierungen
- **Animation Queue** für gleichzeitige Operationen
- **Layer-based Rendering** für bessere Performance
- **Memory Management** mit weak references
- **Efficient Z-Index** Management
- **Lazy Loading** von Animation-Layern

### Empfohlene Limits
- Maximal 10 gleichzeitige Animationen
- Maximal 20 offene Windows
- Window-Größe: max 2000x1500 px
- Animation-Dauer: max 2.0 Sekunden

## 🐛 Troubleshooting

### Häufige Probleme

#### Window wird nicht angezeigt
- Prüfen ob `makeKeyAndOrderFront(nil)` aufgerufen wird
- Prüfen ob Z-Index nicht zu niedrig ist
- Prüfen ob Window auf sichtbarem Screen positioniert ist

#### Animation funktioniert nicht
- Prüfen ob `isAnimating` Flag korrekt gesetzt wird
- Prüfen ob `NSAnimationContext` korrekt verwendet wird
- Prüfen ob Timing-Function gültig ist

#### Blur-Effekt nicht sichtbar
- Prüfen ob macOS Version >= 10.14
- Prüfen ob `contentView` Layer-basiert ist
- Prüfen ob Material-Typ unterstützt wird

### Debug-Tools
```swift
// Debug-Output aktivieren
print("Window positions: \(WindowPositionManager.shared.getCurrentWindowPositions())")
print("Z-Indexes: \(WindowPositionManager.shared.getCurrentZIndexes())")
print("Open windows: \(WindowManager.shared.getOpenWindows())")
```

## 🔮 Zukünftige Erweiterungen

### Geplante Features
- **Touch Bar Integration** für Window-Controls
- **Haptic Feedback** für Window-Interaktionen
- **Advanced Gesture Support** (Pinch-to-Zoom, etc.)
- **Window-Recording** für Replay-Funktionen
- **Advanced Physics Engine** für realistischere Animationen
- **Custom Window Shapes** (rounded rectangles, circles, etc.)

### API-Erweiterungen
- **Async/Await Support** für Animation-Completion
- **Combine Integration** für reactive Window-Management
- **SwiftUI Support** für moderne UI-Integration
- **More Animation Presets** für häufige Use-Cases

## 📄 Lizenz

Dieses Window-Management System ist als Teil der StatusBarApp entwickelt und kann frei verwendet und angepasst werden.

## 🤝 Beitragen

Für Beiträge, Feature-Requests oder Bug-Reports bitte Issues im Projekt-Repository erstellen.

---

**Entwickelt für moderne macOS Applications mit ansprechenden Window-Animationen und intuitivem User Experience.**