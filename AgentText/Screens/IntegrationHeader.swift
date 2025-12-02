import SwiftUI

struct IntegrationHeader: View {
    var body: some View {
        HStack {
            headerContent
            Spacer()
        }
        .padding(28)
        .background(Color(white: 0.04))
    }
    
    private var headerContent: some View {
        VStack(alignment: .leading, spacing: 4) {
            title
            subtitle
        }
    }
    
    private var title: some View {
        Text("Integrations")
            .font(.system(size: 28, weight: .bold))
            .foregroundStyle(
                LinearGradient(
                    colors: [.white, Color(white: 0.85)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
    }
    
    private var subtitle: some View {
        Text("Configure your API keys for agent integrations")
            .font(.system(size: 13))
            .foregroundColor(Color(white: 0.5))
    }
}

