Corrected Implementation Logic

To fix this, your ZStack needs to be very "clean." The footer should be anchored to the bottom and have a specific height, while the ScrollView should use safeAreaInset to avoid the "white blob" overlap.

struct EpisodePlayerView: View {
    @State private var selectedSegment = 0
    @Namespace var playerAnimation
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // LAYER 1: The Scrollable Content
            ScrollView {
                VStack(spacing: 24) {
                    // REMOVE the manual Spacer(70) here
                    
                    SegmentedPicker(selection: $selectedSegment)
                        .padding(.top, 20) // Use smaller padding
                    
                    // Dynamic Content
                    CurrentSegmentView(selectedSegment: selectedSegment)
                }
                // Use safeAreaInset instead of manual padding to prevent "blobs"
            }
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: 250) // Reserve space for the footer
            }

            // LAYER 2: The Fixed Footer (Section 3)
            VStack(spacing: 0) {
                PlayerControlDeck(selectedSegment: selectedSegment)
                    .liquidGlassFooter() // Use the hairline spec
            }
        }
        .ignoresSafeArea(edges: .bottom)
        // Ensure the sheet itself handles the grabber
        .presentationDragIndicator(.visible) 
    }
}

Issue,Fix,spec Reference
Double Grabber,Remove the manual Capsule() or Rectangle() at the top of your VStack.,Section 1
White Blob,Add .clipped() to your footer and ensure it has a defined background material.,Section 4
Dead Space,Reduce the Spacer(minLength: 70) to a standard .padding(.top).,Section 3

Refined Technical Specification: Liquid Glass Player (v2.0)

1. The "Double Grabber" Fix

Issue: The UI currently shows a manual gray bar and a system grabber. Fix: Remove any manual Capsule or Rectangle representing a grabber. Rely entirely on the native sheet presentation indicator.

// In the presenting view (where EpisodePlayerView is called)
.sheet(isPresented: $showFullPlayer) {
    EpisodePlayerView(...)
        .presentationDragIndicator(.visible) // Use native system grabber
}

2. The "White Blob" Fix: Liquid Glass Modifier

This updated modifier uses .clipped() and a specific contentShape to ensure the glass blur stays contained within the footer and doesn't "glow" into the artwork area.

struct LiquidGlassFooter: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.bottom, 40) // Extra padding for home indicator
            .background(.ultraThinMaterial)
            .overlay(alignment: .top) {
                // Sharper hairline to define the top boundary
                Rectangle()
                    .fill(Color.primary.opacity(0.12))
                    .frame(height: 0.33) 
            }
            .clipped() // FIX: Prevents the "white blob" blur bleed
            .contentShape(Rectangle()) 
            .glassEffect(.regular.interactive()) 
    }
}

extension View {
    func liquidGlassFooter() -> some View {
        self.modifier(LiquidGlassFooter())
    }
}

3. Corrected ZStack Structural Layout

The "dead space" at the top is caused by a Spacer(70). We will replace this with a .safeAreaInset strategy to ensure the mid-section content (like the artwork) is positioned correctly relative to the header and footer.

struct EpisodePlayerView: View {
    @State private var selectedSegment = 0
    @Namespace var playerAnimation

    var body: some View {
        ZStack(alignment: .bottom) {
            // LAYER 1: Mid-Section (Scrollable)
            ScrollView {
                VStack(spacing: 24) {
                    // Start content immediately; padding handles the header
                    SegmentedPicker(selection: $selectedSegment)
                        .padding(.top, 24) 
                    
                    switch selectedSegment {
                    case 0: ListeningSegmentView(namespace: playerAnimation)
                    case 1: NotesSegmentView()
                    case 2: InfoSegmentView()
                    default: EmptyView()
                    }
                }
            }
            // Use native insets instead of manual padding
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: 260) // Matches height of control deck
            }
            .scrollIndicators(.hidden)

            // LAYER 2: Persistent Footer (Fixed)
            PlayerControlDeck(selectedSegment: selectedSegment)
                .liquidGlassFooter() // Integrated fix for white blob
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

4. Final Implementation Checklist

Bug Spotted,Fix to Implement,Reference
Double Grabber,Delete manual Capsule() in EpisodePlayerView.,Section 1
White Blob,Apply .clipped() to the .ultraThinMaterial background.,Section 2
Offset Metadata,metadata should be strictly 2 lines (Title + Podcast).,Section 3
Alignment Shift,Use .safeAreaInset(edge: .bottom) on the ScrollView.,Section 3
