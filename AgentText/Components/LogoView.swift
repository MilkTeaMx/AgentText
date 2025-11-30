import SwiftUI

struct LogoView: View {
    var size: CGFloat = 64
    @State private var isVisible = false
    @State private var glowIntensity: CGFloat = 0.3
    
    var body: some View {
        ZStack {
            // Outer glow
            Circle()
                .fill(Color.white.opacity(0.1))
                .frame(width: size * 1.3, height: size * 1.3)
                .blur(radius: 20)
                .opacity(glowIntensity)
            
            // Main circle with glass effect
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.12),
                            Color.white.opacity(0.04)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.4),
                                    Color.white.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: Color.white.opacity(0.2), radius: 15)
            
            // Envelope icon with glow
            Image(systemName: "envelope.fill")
                .font(.system(size: size * 0.35, weight: .medium))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, Color(white: 0.85)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: Color.white.opacity(0.5), radius: 8)
                .offset(y: size * 0.02)
            
            // Fedora hat (brim) - with subtle glow
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [.white, Color(white: 0.9)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: size * 0.48, height: size * 0.08)
                .shadow(color: Color.white.opacity(0.6), radius: 4)
                .offset(y: -size * 0.32)
            
            // Fedora hat (crown) - with subtle glow
            RoundedRectangle(cornerRadius: 2)
                .fill(
                    LinearGradient(
                        colors: [.white, Color(white: 0.9)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: size * 0.26, height: size * 0.12)
                .shadow(color: Color.white.opacity(0.6), radius: 4)
                .offset(y: -size * 0.29)
        }
        .scaleEffect(isVisible ? 1 : 0.8)
        .opacity(isVisible ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                isVisible = true
            }
            // Subtle pulsing glow animation
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                glowIntensity = 0.5
            }
        }
    }
}

#Preview {
    ZStack {
        Color.black
        VStack(spacing: 40) {
            LogoView(size: 80)
            LogoView(size: 120)
        }
    }
}

