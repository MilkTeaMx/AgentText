import SwiftUI

struct LuminescentCard<Content: View>: View {
    let content: Content
    @State private var isVisible = false
    @State private var isHovered = false
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .background(
                ZStack {
                    // Outer glow - pure white
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.15))
                        .blur(radius: 40)
                        .padding(-30)
                        .opacity(isVisible ? (isHovered ? 0.5 : 0.3) : 0)
                    
                    // Middle glow - soft white
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.1))
                        .blur(radius: 20)
                        .padding(-15)
                        .opacity(isVisible ? (isHovered ? 0.6 : 0.4) : 0)
                    
                    // Inner subtle glow
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.05))
                        .blur(radius: 10)
                        .padding(-5)
                        .opacity(isVisible ? 0.5 : 0)
                }
            )
            .overlay(
                // Glass border with white glow
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(isHovered ? 0.4 : 0.25),
                                Color.white.opacity(isHovered ? 0.15 : 0.08),
                                Color.white.opacity(isHovered ? 0.3 : 0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
                    .opacity(isVisible ? 1.0 : 0)
            )
            .shadow(color: Color.white.opacity(isHovered ? 0.15 : 0.08), radius: isHovered ? 30 : 15, x: 0, y: 0)
            .opacity(isVisible ? 1.0 : 0)
            .scaleEffect(isVisible ? 1.0 : 0.96)
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.3)) {
                    isHovered = hovering
                }
            }
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    isVisible = true
                }
            }
    }
}

#Preview {
    ZStack {
        Color.black
        LuminescentCard {
            VStack {
                Text("Test Card")
                    .foregroundColor(.white)
                    .padding()
            }
            .frame(width: 300, height: 200)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(white: 0.06))
            )
        }
    }
}

