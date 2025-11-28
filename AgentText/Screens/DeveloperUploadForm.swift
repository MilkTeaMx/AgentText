import SwiftUI
import FirebaseAuth

struct DeveloperUploadForm: View {
    @EnvironmentObject var authManager: AuthManager
    var onAgentCreated: (() -> Void)? = nil
    
    @State private var agentName = ""
    @State private var description = ""
    @State private var logic = ""
    @State private var isSubmitting = false
    @State private var showSuccess = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isHoveredSubmit = false
    
    @FocusState private var focusedField: Field?
    
    enum Field {
        case agentName, description, logic
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                // Header
                VStack(alignment: .leading, spacing: 10) {
                    Text("Publish Agent")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, Color(white: 0.85)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    
                    Text("Submit your agent to the AgentText Marketplace")
                        .font(.system(size: 14))
                        .foregroundColor(Color(white: 0.5))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Form fields
                VStack(spacing: 24) {
                    // Agent Name
                    VStack(alignment: .leading, spacing: 10) {
                        Text("AGENT NAME")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Color(white: 0.45))
                            .tracking(1.2)
                        TextField("Enter agent name", text: $agentName)
                            .textFieldStyle(.plain)
                            .font(.system(size: 15))
                            .foregroundColor(.white)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 16)
                            .background(
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white.opacity(0.03))
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(focusedField == .agentName ? Color.white.opacity(0.35) : Color.white.opacity(0.08), lineWidth: 1)
                                }
                            )
                            .shadow(color: focusedField == .agentName ? Color.white.opacity(0.08) : .clear, radius: 12)
                            .focused($focusedField, equals: .agentName)
                            .onSubmit {
                                focusedField = .description
                            }
                        
                        // Preview text showing user call format
                        if !agentName.trimmingCharacters(in: .whitespaces).isEmpty {
                            let previewName = agentName.replacingOccurrences(of: " ", with: "_")
                            HStack(spacing: 6) {
                                Image(systemName: "at")
                                    .font(.system(size: 10))
                                Text("User call: @\(previewName)")
                                    .font(.system(size: 11, design: .monospaced))
                            }
                            .foregroundColor(Color(red: 0.2, green: 0.8, blue: 0.4))
                            .padding(.top, 4)
                            .transition(.opacity)
                        }
                    }
                    
                    // Description
                    VStack(alignment: .leading, spacing: 10) {
                        Text("DESCRIPTION")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Color(white: 0.45))
                            .tracking(1.2)
                        TextEditor(text: $description)
                            .frame(minHeight: 100)
                            .font(.system(size: 15))
                            .foregroundColor(.white)
                            .padding(14)
                            .background(
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white.opacity(0.03))
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(focusedField == .description ? Color.white.opacity(0.35) : Color.white.opacity(0.08), lineWidth: 1)
                                }
                            )
                            .shadow(color: focusedField == .description ? Color.white.opacity(0.08) : .clear, radius: 12)
                            .focused($focusedField, equals: .description)
                            .scrollContentBackground(.hidden)
                    }
                    
                    // Logic
                    VStack(alignment: .leading, spacing: 10) {
                        Text("LOGIC (CODE)")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Color(white: 0.45))
                            .tracking(1.2)
                        TextEditor(text: $logic)
                            .frame(minHeight: 200)
                            .padding(14)
                            .background(
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white.opacity(0.03))
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(focusedField == .logic ? Color.white.opacity(0.35) : Color.white.opacity(0.08), lineWidth: 1)
                                }
                            )
                            .shadow(color: focusedField == .logic ? Color.white.opacity(0.08) : .clear, radius: 12)
                            .foregroundColor(.white)
                            .focused($focusedField, equals: .logic)
                            .scrollContentBackground(.hidden)
                            .font(.system(.body, design: .monospaced))
                    }
                }
                
                // Submit button with glow
                Button(action: handleSubmit) {
                    HStack(spacing: 12) {
                        if isSubmitting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "paperplane.fill")
                                .font(.system(size: 14))
                            Text("Publish Agent")
                                .font(.system(size: 16, weight: .semibold))
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        ZStack {
                            RoundedRectangle(cornerRadius: 14)
                                .fill(isFormValid && !isSubmitting ? Color.white.opacity(isHoveredSubmit ? 0.15 : 0.08) : Color.white.opacity(0.03))
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(isFormValid && !isSubmitting ? (isHoveredSubmit ? 0.4 : 0.2) : 0.08),
                                            Color.white.opacity(isFormValid && !isSubmitting ? (isHoveredSubmit ? 0.15 : 0.08) : 0.04)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        }
                    )
                    .shadow(color: isFormValid && !isSubmitting ? Color.white.opacity(isHoveredSubmit ? 0.2 : 0.1) : .clear, radius: isHoveredSubmit ? 25 : 15)
                }
                .buttonStyle(.plain)
                .disabled(!isFormValid || isSubmitting)
                .opacity(isFormValid && !isSubmitting ? 1.0 : 0.5)
                .onHover { hovering in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isHoveredSubmit = hovering
                    }
                }
                
                // Success/Error messages
                if showSuccess {
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Color(red: 0.2, green: 0.8, blue: 0.4))
                        Text("Agent published successfully!")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color(red: 0.2, green: 0.8, blue: 0.4))
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(red: 0.2, green: 0.8, blue: 0.4).opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(red: 0.2, green: 0.8, blue: 0.4).opacity(0.2), lineWidth: 1)
                            )
                    )
                }
                
                if showError {
                    HStack(spacing: 10) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundColor(Color(red: 1.0, green: 0.3, blue: 0.3))
                        Text(errorMessage)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color(red: 1.0, green: 0.3, blue: 0.3))
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(red: 1.0, green: 0.3, blue: 0.3).opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(red: 1.0, green: 0.3, blue: 0.3).opacity(0.2), lineWidth: 1)
                            )
                    )
                }
            }
            .padding(32)
        }
        .background(Color.black)
    }
    
    private var isFormValid: Bool {
        !agentName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !description.trimmingCharacters(in: .whitespaces).isEmpty &&
        !logic.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    private func handleSubmit() {
        guard isFormValid else { return }
        
        guard let currentUser = Auth.auth().currentUser else {
            showError(message: "You must be logged in to publish an agent")
            return
        }
        
        guard let userData = authManager.userData,
              let firstName = userData["firstName"] as? String,
              let lastName = userData["lastName"] as? String else {
            showError(message: "Could not retrieve developer information")
            return
        }
        
        let developerId = currentUser.uid
        let developerName = "\(firstName) \(lastName)"
        let trimmedAgentName = agentName.trimmingCharacters(in: .whitespaces)
        let trimmedDescription = description.trimmingCharacters(in: .whitespaces)
        let trimmedLogic = logic.trimmingCharacters(in: .whitespaces)
        
        isSubmitting = true
        showSuccess = false
        showError = false
        
        Task {
            do {
                try await FirebaseService.shared.createAgent(
                    agentName: trimmedAgentName,
                    description: trimmedDescription,
                    logic: trimmedLogic,
                    developerId: developerId,
                    developerName: developerName
                )
                
                await MainActor.run {
                    isSubmitting = false
                    showSuccess = true
                    showError = false
                    
                    // Notify parent that agent was created
                    onAgentCreated?()
                    
                    // Clear form after success
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        agentName = ""
                        description = ""
                        logic = ""
                        showSuccess = false
                    }
                }
            } catch let error as NSError {
                // Print detailed error information
                print("❌ [DeveloperUploadForm] Error submitting agent:")
                print("   - Error Domain: \(error.domain)")
                print("   - Error Code: \(error.code)")
                print("   - Localized Description: \(error.localizedDescription)")
                print("   - User Info: \(error.userInfo)")
                
                if let underlyingError = error.userInfo[NSUnderlyingErrorKey] as? NSError {
                    print("   - Underlying Error Domain: \(underlyingError.domain)")
                    print("   - Underlying Error Code: \(underlyingError.code)")
                    print("   - Underlying Error Description: \(underlyingError.localizedDescription)")
                    print("   - Underlying Error User Info: \(underlyingError.userInfo)")
                }
                
                // Check for Firestore permission errors
                var errorMessage = error.localizedDescription
                if error.domain == "FIRFirestoreErrorDomain" || 
                   (error.userInfo[NSUnderlyingErrorKey] as? NSError)?.domain == "FIRFirestoreErrorDomain" {
                    errorMessage = "Permission denied. Please check Firestore security rules allow writes to 'agents' collection."
                }
                
                await MainActor.run {
                    isSubmitting = false
                    showError(message: errorMessage)
                }
            } catch {
                print("❌ [DeveloperUploadForm] Unknown error: \(error)")
                await MainActor.run {
                    isSubmitting = false
                    showError(message: "An unexpected error occurred: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func showError(message: String) {
        errorMessage = message
        showError = true
        showSuccess = false
    }
}

#Preview {
    DeveloperUploadForm()
        .environmentObject(AuthManager.shared)
        .frame(width: 800, height: 600)
}

