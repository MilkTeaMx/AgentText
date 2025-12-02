import SwiftUI

struct IntegrationLoadingView: View {
    var body: some View {
        Spacer()
        VStack(spacing: 16) {
            loadingIndicator
            loadingText
        }
        Spacer()
    }
    
    private var loadingIndicator: some View {
        ProgressView()
            .progressViewStyle(CircularProgressViewStyle(tint: .white))
            .scaleEffect(1.2)
    }
    
    private var loadingText: some View {
        Text("Loading integrations...")
            .font(.system(size: 14))
            .foregroundColor(Color(white: 0.5))
    }
}

