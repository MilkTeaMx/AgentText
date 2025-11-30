import SwiftUI

// MARK: - Design Constants
struct AppColors {
    // Base colors
    static let background = Color.black
    static let cardBackground = Color(white: 0.06)
    static let cardBackgroundLight = Color(white: 0.08)
    static let surfaceBackground = Color(white: 0.04)
    
    // Text colors
    static let textPrimary = Color.white
    static let textSecondary = Color(white: 0.6)
    static let textTertiary = Color(white: 0.4)
    
    // Accent colors
    static let glowWhite = Color.white
    static let glowSoft = Color(white: 0.9)
    
    // Glass colors
    static let glassFill = Color.white.opacity(0.03)
    static let glassBorder = Color.white.opacity(0.08)
    static let glassHighlight = Color.white.opacity(0.15)
}

// MARK: - Liquid Glass Card
struct GlassCard<Content: View>: View {
    let content: Content
    var cornerRadius: CGFloat = 24
    var glowIntensity: CGFloat = 0.3
    var padding: CGFloat = 24
    @State private var isHovered = false
    @State private var isVisible = false
    
    init(cornerRadius: CGFloat = 24, glowIntensity: CGFloat = 0.3, padding: CGFloat = 24, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.cornerRadius = cornerRadius
        self.glowIntensity = glowIntensity
        self.padding = padding
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(
                ZStack {
                    // Outer glow layer
                    RoundedRectangle(cornerRadius: cornerRadius + 8)
                        .fill(Color.white.opacity(0.02))
                        .blur(radius: 30)
                        .padding(-20)
                        .opacity(isHovered ? 0.6 : 0.3)
                    
                    // Main glass background
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(
                            .ultraThinMaterial
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .fill(AppColors.glassFill)
                        )
                    
                    // Inner glow gradient
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(isHovered ? 0.08 : 0.04),
                                    Color.clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    
                    // Glass border with glow
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(isHovered ? 0.25 : 0.12),
                                    Color.white.opacity(isHovered ? 0.08 : 0.04),
                                    Color.white.opacity(isHovered ? 0.15 : 0.08)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
            )
            .shadow(color: Color.white.opacity(glowIntensity * (isHovered ? 0.15 : 0.08)), radius: isHovered ? 40 : 20, x: 0, y: 0)
            .scaleEffect(isVisible ? 1 : 0.96)
            .opacity(isVisible ? 1 : 0)
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.2)) {
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

// MARK: - Glowing Button
struct GlowingButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    var isLoading: Bool = false
    var isDisabled: Bool = false
    var style: ButtonStyle = .primary
    
    enum ButtonStyle {
        case primary
        case secondary
        case ghost
    }
    
    @State private var isHovered = false
    @State private var isPressed = false
    
    init(_ title: String, icon: String? = nil, isLoading: Bool = false, isDisabled: Bool = false, style: ButtonStyle = .primary, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.style = style
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                        .tint(.white)
                        .frame(width: 16, height: 16)
                        .scaleEffect(0.8)
                } else if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                }
                
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                
                Spacer()
                
                if !isLoading && style == .primary {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 12, weight: .semibold))
                        .offset(x: isHovered ? 4 : 0)
                }
            }
            .foregroundColor(foregroundColor)
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                ZStack {
                    // Base background
                    RoundedRectangle(cornerRadius: 14)
                        .fill(backgroundColor)
                    
                    // Glow effect for primary
                    if style == .primary {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.white.opacity(isHovered ? 0.15 : 0.05))
                    }
                    
                    // Border
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(borderColor, lineWidth: 1)
                }
            )
            .shadow(color: style == .primary ? Color.white.opacity(isHovered ? 0.2 : 0.1) : .clear, radius: isHovered ? 20 : 10)
            .scaleEffect(isPressed ? 0.98 : 1)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled || isLoading)
        .opacity(isDisabled ? 0.5 : 1)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = false
                    }
                }
        )
    }
    
    private var backgroundColor: Color {
        switch style {
        case .primary:
            return Color.white.opacity(0.1)
        case .secondary:
            return Color.white.opacity(0.05)
        case .ghost:
            return Color.clear
        }
    }
    
    private var foregroundColor: Color {
        switch style {
        case .primary:
            return .white
        case .secondary:
            return Color(white: 0.8)
        case .ghost:
            return Color(white: 0.7)
        }
    }
    
    private var borderColor: Color {
        switch style {
        case .primary:
            return Color.white.opacity(isHovered ? 0.3 : 0.15)
        case .secondary:
            return Color.white.opacity(isHovered ? 0.15 : 0.08)
        case .ghost:
            return Color.clear
        }
    }
}

// MARK: - Glowing Text Field
struct GlowingTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    @FocusState.Binding var isFocused: Bool
    
    @State private var isHovered = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(AppColors.textSecondary)
                .tracking(0.5)
            
            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                }
            }
            .textFieldStyle(.plain)
            .font(.system(size: 15))
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.03))
                    
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            isFocused ? Color.white.opacity(0.3) : Color.white.opacity(isHovered ? 0.12 : 0.06),
                            lineWidth: 1
                        )
                }
            )
            .shadow(color: isFocused ? Color.white.opacity(0.1) : .clear, radius: 15)
            .focused($isFocused)
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.2)) {
                    isHovered = hovering
                }
            }
        }
    }
}

// MARK: - Animated Background
struct AnimatedBackground: View {
    @State private var phase: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Base black
            Color.black
            
            // Subtle gradient orbs
            GeometryReader { geometry in
                ZStack {
                    // Top-left orb
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.white.opacity(0.03), Color.clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: geometry.size.width * 0.4
                            )
                        )
                        .frame(width: geometry.size.width * 0.8)
                        .offset(x: -geometry.size.width * 0.2, y: -geometry.size.height * 0.1)
                        .blur(radius: 60)
                    
                    // Bottom-right orb
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.white.opacity(0.02), Color.clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: geometry.size.width * 0.5
                            )
                        )
                        .frame(width: geometry.size.width * 0.9)
                        .offset(x: geometry.size.width * 0.3, y: geometry.size.height * 0.4)
                        .blur(radius: 80)
                    
                    // Subtle noise texture overlay
                    Rectangle()
                        .fill(Color.white.opacity(0.01))
                }
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Glowing Divider
struct GlowingDivider: View {
    var opacity: Double = 0.1
    
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0),
                        Color.white.opacity(opacity),
                        Color.white.opacity(0)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: 1)
    }
}

// MARK: - Status Indicator
struct StatusIndicator: View {
    let status: Status
    let text: String
    
    enum Status {
        case connected
        case connecting
        case disconnected
        case error
        
        var color: Color {
            switch self {
            case .connected: return Color(red: 0.2, green: 0.9, blue: 0.4)
            case .connecting: return Color(red: 1, green: 0.8, blue: 0.2)
            case .disconnected: return Color(white: 0.4)
            case .error: return Color(red: 1, green: 0.3, blue: 0.3)
            }
        }
    }
    
    @State private var isPulsing = false
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(status.color)
                .frame(width: 8, height: 8)
                .shadow(color: status.color.opacity(0.6), radius: isPulsing ? 6 : 3)
                .animation(
                    status == .connecting ?
                    Animation.easeInOut(duration: 1).repeatForever(autoreverses: true) :
                    .default,
                    value: isPulsing
                )
            
            Text(text)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(AppColors.textSecondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.05))
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
        .onAppear {
            if status == .connecting {
                isPulsing = true
            }
        }
    }
}

// MARK: - Glowing Icon Button
struct GlowingIconButton: View {
    let icon: String
    let action: () -> Void
    var size: CGFloat = 36
    
    @State private var isHovered = false
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size * 0.4, weight: .medium))
                .foregroundColor(.white.opacity(isHovered ? 1 : 0.7))
                .frame(width: size, height: size)
                .background(
                    Circle()
                        .fill(Color.white.opacity(isHovered ? 0.1 : 0.05))
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(isHovered ? 0.2 : 0.08), lineWidth: 1)
                        )
                )
                .shadow(color: Color.white.opacity(isHovered ? 0.15 : 0), radius: 10)
                .scaleEffect(isPressed ? 0.92 : 1)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = false
                    }
                }
        )
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        AnimatedBackground()
        
        VStack(spacing: 30) {
            GlassCard {
                VStack(spacing: 20) {
                    Text("Glass Card")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("With liquid glass effect")
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            .frame(width: 300)
            
            GlowingButton("Continue", icon: "arrow.right") {}
                .frame(width: 300)
            
            StatusIndicator(status: .connected, text: "Connected")
        }
        .padding(50)
    }
    .frame(width: 500, height: 600)
}
