import SwiftUI

struct IntegrationTile: View {
    let integration: Integration
    let onTap: () -> Void
    @State private var isHovered = false
    @State private var imageLoadFailed = false
    
    var body: some View {
        VStack(spacing: 16) {
            integrationLogo
            integrationName
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .padding(.horizontal, 16)
        .background(tileBackground)
        .shadow(color: Color.white.opacity(isHovered ? 0.1 : 0), radius: 15)
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
        .onTapGesture {
            onTap()
        }
    }
    
    private var integrationLogo: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .frame(width: 80, height: 80)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
            
            if let logoURL = integration.logoURL, !imageLoadFailed {
                AsyncImage(url: URL(string: logoURL)) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.6)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 56, height: 56)
                    case .failure:
                        fallbackIcon
                            .onAppear {
                                imageLoadFailed = true
                            }
                    @unknown default:
                        fallbackIcon
                    }
                }
            } else {
                fallbackIcon
            }
        }
    }
    
    private var fallbackIcon: some View {
        Image(systemName: integration.iconName)
            .font(.system(size: 36, weight: .medium))
            .foregroundColor(Color.white.opacity(0.6))
    }
    
    private var integrationName: some View {
        Text(integration.name)
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(.white)
            .multilineTextAlignment(.center)
    }
    
    private var tileBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.white.opacity(isHovered ? 0.08 : 0.04))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(isHovered ? 0.15 : 0.08), lineWidth: 1)
            )
    }
}

