Nice — below is a single, ready-to-drop SwiftUI file that contains:

A 3-screen onboarding flow (swipeable) with animated hero and a final CTA that marks onboarding complete.

The Empty State screen (the one you’ll show after onboarding) with all the micro-animations (timestamp pulse, Siri ripple, waveform→text hero, staggered chips), primary CTA, and a secondary “browse” link.

Self-contained helper components: TimestampPulse, SiriRipple, WaveToText, StaggeredChips.

Small animation timeline and sensible defaults you can tune.

Copy the whole file into your Xcode project (SwiftUI lifecycle). The code uses @AppStorage("hasSeenOnboarding") so it will remember the onboarding state across launches — you can remove/change that quickly if you want a different persistence mechanism.

import SwiftUI

// MARK: - Entry / Demo ContentView
struct ContentView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false

    var body: some View {
        if hasSeenOnboarding {
            EmptyStateView()
        } else {
            OnboardingFlowView()
        }
    }
}

// MARK: - Onboarding Flow (3 screens)
struct OnboardingFlowView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false
    @State private var selection = 0

    var body: some View {
        VStack {
            TabView(selection: $selection) {
                OnboardScreenView(
                    title: "Turn listening into learning",
                    body: "EchoCast helps you capture ideas from podcasts you already love — so they stick.",
                    hero: AnyView(WaveToTextHeroMini())
                )
                .tag(0)

                OnboardScreenView(
                    title: "Two ways to take notes",
                    body: "Tap “+ Note” while an episode plays, or use Siri to record thoughts hands-free.",
                    hero: AnyView(TwoMethodHero())
                )
                .tag(1)

                OnboardScreenView(
                    title: "Build a library of insights",
                    body: "Every note is time-stamped, searchable, and linked back to the exact moment you heard it.",
                    hero: AnyView(StackedCardsHero())
                )
                .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeOut, value: selection)

            // page indicators
            HStack(spacing: 8) {
                ForEach(0..<3) { i in
                    Circle()
                        .frame(width: 8, height: 8)
                        .foregroundColor(i == selection ? Color.primary : Color.gray.opacity(0.35))
                        .scaleEffect(i == selection ? 1.05 : 1.0)
                }
            }
            .padding(.top, 12)

            // CTA row
            HStack {
                if selection < 2 {
                    Button(action: { selection += 1 }) {
                        Text("Next")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.primary.opacity(0.1))
                            .cornerRadius(12)
                    }
                } else {
                    Button(action: {
                        withAnimation {
                            hasSeenOnboarding = true
                        }
                    }) {
                        Text("Start Listening")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                }
            }
            .padding(.top, 16)
            .padding(.horizontal)
            .padding(.bottom, 24)
        }
        .edgesIgnoringSafeArea(.all)
    }
}

struct OnboardScreenView: View {
    let title: String
    let body: String
    let hero: AnyView

    var body: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 48)

            hero
                .frame(height: 160)
                .padding(.horizontal, 36)

            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Text(body)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 36)

            Spacer(minLength: 8)
        }
    }
}

// MARK: - Onboarding Hero Visuals (simple, coded)
struct WaveToTextHeroMini: View {
    var body: some View {
        WaveToText()
            .padding()
            .background(RoundedRectangle(cornerRadius: 16).fill(Color(UIColor.systemBackground)))
            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 6)
    }
}

struct TwoMethodHero: View {
    var body: some View {
        HStack(spacing: 20) {
            VStack(spacing: 12) {
                TimestampPulse(mini: true)
                    .frame(width: 64, height: 64)
                Text("Tap + Note")
                    .font(.caption)
            }

            VStack(spacing: 12) {
                SiriRipple(mini: true)
                    .frame(width: 64, height: 64)
                Text("Use Siri")
                    .font(.caption)
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(UIColor.systemBackground)))
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 6)
    }
}

struct StackedCardsHero: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(UIColor.systemGray6))
                .frame(height: 110)
                .offset(x: 8, y: 16)
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(UIColor.systemGray5))
                .frame(height: 110)
                .offset(x: -8, y: 8)
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(UIColor.systemBackground))
                .frame(height: 110)
                .overlay(
                    VStack(alignment: .leading, spacing: 8) {
                        Capsule().frame(width: 120, height: 8).foregroundColor(.gray.opacity(0.25))
                        Capsule().frame(width: 180, height: 8).foregroundColor(.gray.opacity(0.20))
                        Capsule().frame(width: 80, height: 8).foregroundColor(.gray.opacity(0.20))
                    }
                    .padding()
                )
        }
        .padding()
    }
}

// MARK: - Empty State Full Screen
struct EmptyStateView: View {
    @State private var heroAnimated = false
    @State private var chipsAppeared = false
    @State private var ctaVisible = false

    var body: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 40)

            // Hero: waveform -> text
            WaveToText()
                .frame(height: 120)
                .padding(.horizontal, 28)

            Text("Turn listening into notes")
                .font(.title3)
                .fontWeight(.semibold)
                .padding(.top, 6)

            Text("Capture time-stamped insights while you listen — or use Siri to save thoughts hands-free.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            // Two chips (staggered)
            VStack(spacing: 12) {
                StaggeredChips(appear: $chipsAppeared)
                    .padding(.top, 8)
            }
            .padding(.horizontal, 28)

            Spacer(minLength: 12)

            // Primary CTA
            Button(action: {
                // primary action - present add podcast flow
                print("Add your first podcast tapped")
            }) {
                Text("Add your first podcast")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .shadow(color: Color.accentColor.opacity(0.15), radius: 6, x: 0, y: 6)
            }
            .padding(.horizontal, 28)
            .opacity(ctaVisible ? 1 : 0)
            .offset(y: ctaVisible ? 0 : 8)
            .animation(.easeOut(duration: 0.3), value: ctaVisible)

            // Secondary text link
            Button(action: {
                // browse popular shows
                print("Browse tapped")
            }) {
                Text("Browse popular shows →")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 6)

            Spacer(minLength: 32)
        }
        .onAppear {
            runIntroTimeline()
        }
    }

    private func runIntroTimeline() {
        // Sequence: hero animates, chips appear, CTA appears, ambient loops start inside components
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            chipsAppeared = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            ctaVisible = true
        }
    }
}

// MARK: - Helper UI Components (TimestampPulse, SiriRipple, WaveToText, StaggeredChips)

struct TimestampPulse: View {
    var mini: Bool = false
    @State private var pulse = false

    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: mini ? 2 : 2)
                .foregroundColor(Color.primary.opacity(0.12))
                .scaleEffect(pulse ? 1.18 : 1.0)
                .opacity(pulse ? 0 : 0.25)
                .animation(
                    .interpolatingSpring(stiffness: 220, damping: 18)
                        .repeatForever(autoreverses: true)
                        .speed(1.0),
                    value: pulse
                )

            Circle()
                .fill(Color.primary.opacity(0.03))
                .frame(width: mini ? 36 : 56, height: mini ? 36 : 56)

            Image(systemName: "clock")
                .font(.system(size: mini ? 18 : 20, weight: .regular))
                .foregroundColor(.primary)
        }
        .onAppear {
            // small delay to avoid immediate "startle"
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                pulse = true
            }
        }
    }
}

struct SiriRipple: View {
    var mini: Bool = false
    @State private var animate = false

    var body: some View {
        ZStack {
            ForEach(0..<3) { i in
                Circle()
                    .stroke(lineWidth: 1.5)
                    .foregroundColor(Color.primary.opacity(0.12))
                    .scaleEffect(animate ? CGFloat(1.0 + 1.2 * Double(i)) : 1.0)
                    .opacity(animate ? 0.0 : 0.35)
                    .animation(
                        .easeOut(duration: 1.8)
                            .delay(Double(i) * 0.18)
                            .repeatForever(autoreverses: false),
                        value: animate
                    )
            }

            // small "waveform" - use system image as placeholder
            Image(systemName: "waveform.path.ecg")
                .font(.system(size: mini ? 18 : 22))
                .foregroundColor(.primary)
        }
        .onAppear {
            // stagger start so it feels ambient
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                animate = true
            }
        }
    }
}

struct WaveToText: View {
    @State private var showLines = false
    @State private var shiftLeft = false

    var body: some View {
        HStack(spacing: 14) {
            // Waveform icon with small animation
            Image(systemName: "waveform")
                .font(.system(size: 28, weight: .semibold))
                .opacity(showLines ? 0.8 : 1.0)
                .offset(x: shiftLeft ? -6 : 0)
                .animation(.easeOut(duration: 0.28), value: shiftLeft)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(0..<3) { i in
                    Capsule()
                        .frame(width: showLines ? CGFloat(90 + i * 28) : 0, height: 8)
                        .foregroundColor(Color.primary.opacity(0.12))
                        .opacity(showLines ? 1.0 : 0.0)
                        .animation(
                            .easeOut(duration: 0.25)
                                .delay(0.07 * Double(i)),
                            value: showLines
                        )
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .onAppear {
            // sequence: small equalizer -> slide & show lines
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                // simulate equalizer moment (we keep this simple)
                withAnimation(.easeOut(duration: 0.5)) {
                    shiftLeft = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                    showLines = true
                }
            }
        }
    }
}

struct StaggeredChips: View {
    @Binding var appear: Bool
    var body: some View {
        VStack(spacing: 12) {
            ChipView(icon: "clock", title: "Add Note at Timestamp", subtitle: "Tap \"+ Note\" during playback")
                .opacity(appear ? 1 : 0)
                .offset(y: appear ? 0 : 6)
                .animation(.easeOut(duration: 0.28).delay(0.03), value: appear)

            ChipView(icon: "mic", title: "Siri: “Add note to EchoCast”", subtitle: "Dictate notes without touching your phone")
                .opacity(appear ? 1 : 0)
                .offset(y: appear ? 0 : 6)
                .animation(.easeOut(duration: 0.28).delay(0.08), value: appear)
        }
    }
}

struct ChipView: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .frame(width: 34, height: 34)
                .background(Color.primary.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.body)
                Text(subtitle).font(.caption).foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(UIColor.systemGray6)))
    }
}

// MARK: - Previews
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ContentView()
                .preferredColorScheme(.light)

            EmptyStateView()
                .preferredColorScheme(.light)
                .previewDisplayName("Empty State")

            OnboardingFlowView()
                .preferredColorScheme(.light)
                .previewDisplayName("Onboarding")
        }
    }
}

