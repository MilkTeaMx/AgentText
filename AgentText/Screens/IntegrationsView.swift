import SwiftUI
import FirebaseAuth

struct IntegrationsView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var selectedIntegration: Integration?
    @State private var integrationKeys: [String: String] = [:]
    @State private var isLoading = true

    var body: some View {
        VStack(spacing: 0) {
            IntegrationHeader()
            GlowingDivider(opacity: 0.1)
            contentView
        }
        .background(Color.black)
        .onAppear {
            loadIntegrationKeys()
        }
    }
    
    @ViewBuilder
    private var contentView: some View {
        if let selected = selectedIntegration {
            detailView(for: selected)
        } else {
            gridView
        }
    }
    
    private func detailView(for integration: Integration) -> some View {
        IntegrationDetailView(
            integration: integration,
            integrationInfo: getIntegrationInfo(for: integration),
            onBack: {
                selectedIntegration = nil
            }
        )
        .environmentObject(authManager)
    }
    
    @ViewBuilder
    private var gridView: some View {
        if isLoading {
            IntegrationLoadingView()
        } else {
            IntegrationGrid(
                integrations: Integration.defaultIntegrations,
                onIntegrationTap: { integration in
                    selectedIntegration = integration
                }
            )
        }
    }
    
    private func loadIntegrationKeys() {
        guard let userId = Auth.auth().currentUser?.uid else {
            isLoading = false
            return
        }

        Task {
            do {
                let userData = try await FirebaseService.shared.getUserData(uid: userId)
                let keys = userData?["integrationKeys"] as? [String: String] ?? [:]

                await MainActor.run {
                    integrationKeys = keys
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }
}

#Preview {
    IntegrationsView()
        .environmentObject(AuthManager.shared)
        .frame(width: 800, height: 600)
}
