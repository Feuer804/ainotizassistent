# Glass SwiftUI-Komponenten

Eine umfassende Sammlung von erweiterten SwiftUI-Komponenten für modernes Glass-Design mit Blur-Effekten, Glow-Effekten und flüssigen Animationen.

## 🛠️ Komponenten

### 1. GlassButtonStyle.swift
**Button-Komponenten mit Glass-Morphism-Effekten**

#### Features:
- **Basic GlassButtonStyle**: Standard Glass-Buttons mit anpassbaren Parametern
- **PrimaryGlassButtonStyle**: Primäre Buttons mit stärkerer Farbgebung
- **GlassIconButtonStyle**: Runde Icon-Buttons
- Glow-Effekte mit konfigurierbarer Intensität
- Active/Pressed-States mit Skalen-Animationen
- Dark/Light Mode kompatibel

#### Verwendung:
```swift
Button("Primär") {
    // Action
}
.buttonStyle(PrimaryGlassButtonStyle())

Button {
    // Action
} label: {
    Label("Standard Glass", systemImage: "star.fill")
}
.buttonStyle(GlassButtonStyle(glowColor: .purple))

Button {
    // Action
} label: {
    Image(systemName: "heart.fill")
}
.buttonStyle(GlassIconButtonStyle())
```

### 2. GlassCardView.swift
**Wiederverwendbare Card-Komponente mit Blur-Effekten**

#### Features:
- **GlassCardView**: Basis Card-Komponente
- **GlassInfoCard**: Info-Karten mit dismissible Option
- **GlassStatsCard**: Statistik-Karten mit Akzentfarbe
- **GlassChartCard**: Chart/Karten-Container
- **GlassCardGrid**: Grid-Layout für Cards
- Responsive Design mit Grid-Elementen

#### Verwendung:
```swift
GlassCardView {
    VStack {
        Text("Card Inhalt")
        // ... weitere Inhalte
    }
}

GlassInfoCard(accentColor: .green, isDismissible: true) {
    VStack {
        Text("Erfolgreich!")
        Text("Operation abgeschlossen")
    }
}

GlassStatsCard(title: "Heute", accentColor: .blue) {
    // Statistik-Inhalt
}

GlassCardGrid {
    // Grid-Inhalte
}
```

### 3. GlassTabView.swift
**Animierte Tab Bar mit Glass-Effekt**

#### Features:
- **GlassTabView**: Vollständige Tab-Bar mit Animation
- **CompactGlassTabView**: Kompakte Version für iPhone
- Glühende Auswahl-Indikatoren
- Badge-Support für Tab-Indikatoren
- Responsive Layout
- Smooth Transitions zwischen Tabs

#### Verwendung:
```swift
let tabs = [
    GlassTabItem(title: "Start", systemImage: "house", color: .blue, badge: 2),
    GlassTabItem(title: "Suche", systemImage: "magnifyingglass", color: .green),
    GlassTabItem(title: "Favoriten", systemImage: "heart", color: .red)
]

GlassTabView(tabs: tabs, selectedTab: 0) { selectedIndex in
    // Tab-Content
}
```

### 4. GlassTextField.swift
**Input-Felder mit frosted glass styling**

#### Features:
- **GlassTextField**: Basis Text-Input mit Glass-Effekt
- **GlassSecureTextField**: Passwort-Input mit Sichtbarkeits-Toggle
- **GlassSearchField**: Such-Input mit Clear-Button
- **GlassMultiLineTextField**: Mehrzeiliger Text-Input
- **GlassFormContainer**: Container für Formular-Gruppen
- Input-Validation mit Error/Success Anzeigen

#### Verwendung:
```swift
@State private var email = ""
@State private var password = ""
@State private var searchText = ""

GlassTextField(
    text: $email,
    placeholder: "E-Mail-Adresse",
    icon: "envelope",
    accentColor: .blue
)

GlassSecureTextField(
    text: $password,
    placeholder: "Passwort",
    accentColor: .purple
)

GlassSearchField(text: $searchText) {
    // Such-Aktion
}

if showError {
    GlassInputError(message: "E-Mail ist ungültig")
}
```

### 5. GlassProgressView.swift
**Ladebalken mit Glass-Hintergrund**

#### Features:
- **GlassProgressView**: Linearer Fortschrittsbalken
- **GlassCircularProgressView**: Kreisförmiger Fortschrittsanzeiger
- **GlassMultiStepProgress**: Mehrstufiger Fortschrittsindikator
- **GlassLoadingIndicator**: Loading-Spinner
- **GlassProgressWithStatus**: Fortschrittsanzeige mit Status
- Animierte Übergänge und Glow-Effekte

#### Verwendung:
```swift
@State private var progress: CGFloat = 0.7

GlassProgressView(
    progress: progress,
    accentColor: .blue,
    showPercentage: true
)

GlassCircularProgressView(
    progress: 0.7,
    centerContent: {
        VStack {
            GlassLoadingIndicator()
            Text("Laden")
        }
    }
)

GlassMultiStepProgress(
    steps: ["Start", "Daten", "Bestätigung"],
    currentStep: 1
)

GlassProgressWithStatus(
    title: "Upload",
    subtitle: "Datei wird hochgeladen...",
    progress: progress
)
```

### 6. GlassModalView.swift
**Modal-Dialoge mit Glass-Overlay**

#### Features:
- **GlassModalView**: Basis Modal-Container
- **GlassAlertModal**: Alert-Dialoge
- **GlassConfirmationModal**: Bestätigungs-Dialoge mit Aktionen
- **GlassSheetModal**: Bottom-Sheet Modal
- **GlassToast**: Toast-Notification
- Drag-to-dismiss für Sheet-Modalen
- Glass-Overlay mit Blur-Effekt

#### Verwendung:
```swift
@StateObject private var modalState = GlassModalState()

// In der View
GlassModalManager {
    // Haupt-Content
    
    Button("Alert zeigen") {
        modalState.present(.alert(
            title: "Warnung",
            message: "Dies ist eine wichtige Nachricht.",
            primaryButton: "OK",
            secondaryButton: "Abbrechen"
        ))
    }
}

// Sheet Modal
GlassSheetModal(isPresented: $showSheet) {
    VStack {
        Text("Bottom Sheet")
        // Sheet-Inhalt
    }
}

// Toast Notification
GlassToast(
    message: "Erfolgreich gespeichert!",
    icon: "checkmark.circle.fill",
    isPresented: $showToast
)
```

### 7. GlassNavigationStack.swift
**Navigation mit Glass-Transitions**

#### Features:
- **GlassNavigationBar**: Custom Navigation Bar
- **GlassNavigationStack**: Navigation Stack mit Glass-Effekten
- **GlassDetailView**: Detail-Ansichten mit Back-Navigation
- **GlassListView**: Listen-Navigation mit Such-Funktion
- **GlassTabNavigation**: Tab-basierte Navigation
- Smooth Transitions zwischen Views

#### Verwendung:
```swift
@State private var showDetail = false

GlassNavigationStack {
    ScrollView {
        // Content
    }
    .glassNavigationTitle("Meine App")
    .glassNavigationTint(.blue)
    .navigationDestination(isPresented: $showDetail) {
        GlassDetailView(
            title: "Detail",
            tintColor: .blue
        ) {
            // Detail-Content
        }
    }
}

GlassListView(
    title: "Kategorien",
    items: items
) { item in
    Text(item.title)
    // Item-Content
}
```

### 8. GlassAnimatableData.swift
**Animierte Arrays und Collections**

#### Features:
- **GlassAnimatableArray**: Animierte Array-Verwaltung
- **GlassAnimatableList**: Liste mit gestaffelten Animationen
- **GlassAnimatableGrid**: Grid mit Animations-Effekten
- **GlassStaggeredCollection**: Gestaffelte Item-Animationen
- **GlassAnimatedCounter**: Animierter Zahlen-Counter
- **GlassLoadingAnimation**: Loading-Animation
- View-Modifier für Fade/Slide-Transitionen

#### Verwendung:
```swift
@State private var listItems = GlassAnimatableArray<GlassCardAnimatableItem>()
@State private var gridItems = GlassGridAnimatableCollection<GlassCardAnimatableItem>()

var listView = GlassAnimatableList { item in
    GlassCardView {
        VStack {
            Text(item.title)
            if let icon = item.icon {
                Image(systemName: icon)
                    .foregroundColor(item.color)
            }
        }
    }
}

var gridView = GlassAnimatableGrid { item in
    GlassCardView {
        // Grid Item
    }
}

// Items hinzufügen
let newItem = GlassCardAnimatableItem(
    title: "Neuer Artikel",
    icon: "star.fill",
    color: .blue
)
listView.addItem(newItem)
gridView.addItem(newItem)

// Fade Transition
Text("Fade Animation")
    .glassFadeTransition(duration: 0.3)
```

## 🎨 Design-Prinzipien

### Glass-Morphism
- **Ultra-Thin Material**: Verwendung von `.ultraThinMaterial`
- **Gradient Overlays**: Mehrschichtige Gradient-Overlays
- **Border Effects**: Subtile Border mit Gradient-Effekten
- **Shadow Layers**: Mehrschichtige Schatten für Tiefe

### Animation System
- **Spring Physics**: Natürliche Feder-Animationen
- **Staggered Timing**: Gestaffelte Timing für Collections
- **Ease Curves**: Sanfte Übergänge mit `easeInOut`
- **Interactive Feedback**: Hover und Press-Effekte

### Responsive Design
- **Adaptive Layouts**: Funktionieren auf iPhone, iPad, Mac
- **Dynamic Type**: Unterstützung für Dynamic Type
- **Dark/Light Mode**: Automatische Anpassung
- **Safe Areas**: Respekt für Safe Areas

## 🔧 Konfiguration

### Farben
- Standard-Farbpalette mit Blau, Grün, Rot, Orange, Purple
- Anpassbare Akzentfarben für jede Komponente
- Dark/Light Mode automatisch unterstützt

### Animationen
- Standard-Dauer: 0.3-0.4 Sekunden
- Spring-Response: 0.5-0.6
- Damping: 0.8-0.9
- Verzögerungen für gestaffelte Effekte

### Layout
- Standard-Eckenradius: 16-20pt
- Padding: 16-20pt
- Spacing: 12-16pt
- Minimal-Height: 44pt für Touch-Targets

## 📱 Kompatibilität

### System Requirements
- iOS 15.0+
- macOS 12.0+
- Xcode 13.0+
- Swift 5.5+

### Geräte-Support
- iPhone (alle Größen)
- iPad (alle Größen)
- Mac Catalyst
- tvOS (ausgewählte Komponenten)

## 🚀 Integration

### Installation
1. Kopieren Sie alle `.swift` Dateien in Ihr Xcode-Projekt
2. Importieren Sie die benötigten Module in Ihre Views
3. Verwenden Sie die Komponenten wie in den Beispielen gezeigt

### Import
```swift
import SwiftUI
```

### Verwendung
Alle Komponenten sind als `public` deklariert und können direkt importiert werden.

## 💡 Tipps

### Performance
- Verwenden Sie `LazyVStack`/`LazyVGrid` für lange Listen
- Minimieren Sie Anzahl der aktiven Animationen
- Verwenden Sie `Equatable` conformance für bessere Performance

### Best Practices
- Verwenden Sie semantische Farben
- Behalten Sie konsistente Abstände
- Testen Sie in beiden Dark/Light Modes
- Berücksichtigen Sie Accessibility-Anforderungen

### Customization
- Alle Komponenten sind hochgradig anpassbar
- Verwenden Sie die Konfigurations-Structs
- Überschreiben Sie Styles für spezielle Anforderungen
- Kombinieren Sie Komponenten für komplexe UI

## 🔍 Beispiele

Schauen Sie sich die `Preview` Bereiche in jeder Datei an für vollständige Implementierungsbeispiele.

Alle Komponenten sind sofort einsatzbereit und können direkt in Ihre SwiftUI-Projekte integriert werden.