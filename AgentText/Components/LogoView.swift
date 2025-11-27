import SwiftUI

struct LogoView: View {
    var size: CGFloat = 64
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.1))
                .frame(width: size, height: size)
            
            // Envelope icon
            Image(systemName: "envelope.fill")
                .font(.system(size: size * 0.4))
                .foregroundColor(.white)
                .offset(y: size * 0.03)
            
            // Fedora hat (brim)
            Ellipse()
                .fill(Color.white)
                .frame(width: size * 0.5, height: size * 0.09)
                .offset(y: -size * 0.31)
            
            // Fedora hat (crown)
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.white)
                .frame(width: size * 0.28, height: size * 0.125)
                .offset(y: -size * 0.28)
        }
    }
}

#Preview {
    ZStack {
        Color.black
        LogoView()
    }
}

