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
    
    @FocusState private var focusedField: Field?
    
    enum Field {
        case agentName, description, logic
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Publish Agent")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Submit your agent to the AgentText Marketplace")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Form fields
                VStack(spacing: 20) {
                    // Agent Name
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Agent Name *")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.gray)
                        TextField("Enter agent name", text: $agentName)
                            .textFieldStyle(.plain)
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.white.opacity(0.05))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(focusedField == .agentName ? Color.white.opacity(0.3) : Color.white.opacity(0.1), lineWidth: 1)
                                    )
                            )
                            .foregroundColor(.white)
                            .focused($focusedField, equals: .agentName)
                            .onSubmit {
                                focusedField = .description
                            }
                        
                        // Preview text showing user call format
                        if !agentName.trimmingCharacters(in: .whitespaces).isEmpty {
                            let previewName = agentName.replacingOccurrences(of: " ", with: "_")
                            Text("User call: @\(previewName)")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.green)
                                .padding(.top, 4)
                                .transition(.opacity)
                        }
                    }
                    
                    // Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description *")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.gray)
                        TextEditor(text: $description)
                            .frame(minHeight: 100)
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.white.opacity(0.05))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(focusedField == .description ? Color.white.opacity(0.3) : Color.white.opacity(0.1), lineWidth: 1)
                                    )
                            )
                            .foregroundColor(.white)
                            .focused($focusedField, equals: .description)
                            .scrollContentBackground(.hidden)
                    }
                    
                    // Logic
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Logic (Code) *")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.gray)
                        TextEditor(text: $logic)
                            .frame(minHeight: 200)
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.white.opacity(0.05))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(focusedField == .logic ? Color.white.opacity(0.3) : Color.white.opacity(0.1), lineWidth: 1)
                                    )
                            )
                            .foregroundColor(.white)
                            .focused($focusedField, equals: .logic)
                            .scrollContentBackground(.hidden)
                            .font(.system(.body, design: .monospaced))
                    }
                }
                
                // Submit button
                Button(action: handleSubmit) {
                    HStack(spacing: 12) {
                        if isSubmitting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Text("Publish Agent")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white.opacity(0.9))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isFormValid && !isSubmitting ? Color(red: 0.2, green: 0.2, blue: 0.22) : Color.gray.opacity(0.3))
                    )
                }
                .buttonStyle(.plain)
                .disabled(!isFormValid || isSubmitting)
                .opacity(isFormValid && !isSubmitting ? 1.0 : 0.5)
                
                // Success/Error messages
                if showSuccess {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Agent published successfully!")
                            .font(.system(size: 14))
                            .foregroundColor(.green)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.green.opacity(0.1))
                    )
                }
                
                if showError {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Text(errorMessage)
                            .font(.system(size: 14))
                            .foregroundColor(.red)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.red.opacity(0.1))
                    )
                }
            }
            .padding(32)
        }
        .background(Color(red: 0.1, green: 0.1, blue: 0.12))
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

