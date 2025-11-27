import SwiftUI

struct LuminescentCard<Content: View>: View {
    let content: Content
    @State private var isVisible = false
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .background(
                ZStack {
                    // Outer glow
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 1.0, green: 0.4, blue: 0.2).opacity(0.6),
                                    Color(red: 0.8, green: 0.2, blue: 0.6).opacity(0.6),
                                    Color(red: 0.4, green: 0.2, blue: 0.8).opacity(0.6)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .blur(radius: 20)
                        .padding(-20)
                        .opacity(isVisible ? 0.8 : 0)
                    
                    // Middle glow
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 1.0, green: 0.5, blue: 0.3).opacity(0.7),
                                    Color(red: 0.7, green: 0.3, blue: 0.7).opacity(0.7)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .blur(radius: 12)
                        .padding(-12)
                        .opacity(isVisible ? 0.7 : 0)
                }
            )
            .overlay(
                // Inner border glow
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color(red: 1.0, green: 0.6, blue: 0.4).opacity(1.0),
                                Color(red: 0.8, green: 0.4, blue: 0.8).opacity(1.0),
                                Color(red: 0.5, green: 0.3, blue: 1.0).opacity(1.0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
                    .opacity(isVisible ? 1.0 : 0)
            )
            .opacity(isVisible ? 1.0 : 0)
            .scaleEffect(isVisible ? 1.0 : 0.95)
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
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(red: 0.15, green: 0.15, blue: 0.18))
            )
        }
    }
}

