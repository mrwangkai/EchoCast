//
//  OnboardingView.swift
//  EchoNotes
//
//  Instagram-style onboarding with countdown timers
//

import SwiftUI

struct OnboardingView: View {
    @State private var currentPage = 0
    @State private var progress: [CGFloat] = [0, 0, 0]
    @State private var timer: Timer?
    @Binding var isOnboardingComplete: Bool

    let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "waveform.badge.mic",
            title: "Capture Ideas\nInstantly",
            description: "Add timestamped notes while listening to podcasts. Never lose a great insight again.",
            color: Color.blue
        ),
        OnboardingPage(
            icon: "tag.fill",
            title: "Organize with\nSmart Tags",
            description: "Tag your notes to build a personal knowledge base. Find what you need, when you need it.",
            color: Color.orange
        ),
        OnboardingPage(
            icon: "arrow.triangle.2.circlepath",
            title: "Resume Where\nYou Left Off",
            description: "Automatically track your listening progress. Jump back into episodes right where you stopped.",
            color: Color.green
        )
    ]

    var body: some View {
        ZStack {
            // Background
            pages[currentPage].color
                .opacity(0.1)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress bars at top
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                // Background
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))

                                // Progress
                                Rectangle()
                                    .fill(Color.white)
                                    .frame(width: geometry.size.width * (index < currentPage ? 1 : (index == currentPage ? progress[currentPage] : 0)))
                            }
                        }
                        .frame(height: 3)
                        .cornerRadius(1.5)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 50)
                .padding(.bottom, 20)

                // Skip button (shown on first 2 pages only)
                HStack {
                    Spacer()
                    if currentPage < pages.count - 1 {
                        Button("Skip") {
                            completeOnboarding()
                        }
                        .foregroundColor(.gray)
                        .padding(.horizontal)
                    }
                }
                .frame(height: 20)
                .padding(.bottom, 40)

                Spacer()

                // Content
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        VStack(spacing: 30) {
                            Image(systemName: pages[index].icon)
                                .font(.system(size: 80))
                                .foregroundColor(pages[index].color)

                            Text(pages[index].title)
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .multilineTextAlignment(.center)
                                .lineLimit(2)

                            Text(pages[index].description)
                                .font(.system(size: 18))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .onChange(of: currentPage) { oldValue, newValue in
                    restartTimer()
                }

                Spacer()

                // Get Started button (only on last page)
                if currentPage == pages.count - 1 {
                    Button(action: completeOnboarding) {
                        Text("Get Started")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(pages[currentPage].color)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 50)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }

            // X button overlay (only on last page)
            if currentPage == pages.count - 1 {
                VStack {
                    HStack {
                        Spacer()
                        Button(action: completeOnboarding) {
                            Image(systemName: "xmark")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                                .padding(14)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                        }
                        .padding(.top, 60)
                        .padding(.trailing, 20)
                        .zIndex(999)
                    }
                    Spacer()
                }
                .allowsHitTesting(true)
            }
        }
        .gesture(
            DragGesture(minimumDistance: 50)
                .onEnded { value in
                    if value.translation.width < 0 && currentPage < pages.count - 1 {
                        // Swipe left - next page
                        withAnimation {
                            currentPage += 1
                        }
                    } else if value.translation.width > 0 && currentPage > 0 {
                        // Swipe right - previous page
                        withAnimation {
                            currentPage -= 1
                        }
                    }
                }
        )
        .onAppear {
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { _ in
            withAnimation(.linear) {
                if progress[currentPage] < 1.0 {
                    progress[currentPage] += 0.005 // 6 seconds per page
                } else {
                    // Move to next page or complete
                    if currentPage < pages.count - 1 {
                        currentPage += 1
                        progress[currentPage] = 0
                    } else {
                        stopTimer()
                    }
                }
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func restartTimer() {
        stopTimer()
        progress[currentPage] = 0
        startTimer()
    }

    private func completeOnboarding() {
        stopTimer()
        isOnboardingComplete = true
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
    }
}

struct OnboardingPage {
    let icon: String
    let title: String
    let description: String
    let color: Color
}

#Preview {
    OnboardingView(isOnboardingComplete: .constant(false))
}
