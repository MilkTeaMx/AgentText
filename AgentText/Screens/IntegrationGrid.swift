import SwiftUI

struct IntegrationGrid: View {
    let integrations: [Integration]
    let onIntegrationTap: (Integration) -> Void
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                gridTitle
                gridContent
            }
            .padding(.horizontal, 28)
            .padding(.top, 28)
            .padding(.bottom, 28)
        }
    }
    
    private var gridTitle: some View {
        Text("Available Integrations")
            .font(.system(size: 18, weight: .semibold))
            .foregroundColor(.white)
    }
    
    private var gridContent: some View {
        LazyVGrid(columns: gridColumns, spacing: 20) {
            ForEach(integrations) { integration in
                IntegrationTile(integration: integration) {
                    onIntegrationTap(integration)
                }
            }
        }
    }
    
    private var gridColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: 20),
            GridItem(.flexible(), spacing: 20),
            GridItem(.flexible(), spacing: 20)
        ]
    }
}

