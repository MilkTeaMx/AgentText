import SwiftUI

struct LoginView: View {
    let onLogin: () -> Void
    let onShowSignIn: () -> Void
    
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var password = ""
    @State private var macUsername = ""
    @State private var email = ""
    @State private var isHoveredButton = false
    @FocusState private var focusedField: Field?
    
    init(onLogin: @escaping () -> Void = {}, onShowSignIn: @escaping () -> Void = {}) {
        self.onLogin = onLogin
        self.onShowSignIn = onShowSignIn
    }
    
    enum Field {
        case email, firstName, lastName, password
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    private var isEmailFieldValid: Bool {
        isValidEmail(email)
    }
    
    private var isFormValid: Bool {
        !firstName.isEmpty && !lastName.isEmpty && !password.isEmpty && isEmailFieldValid
    }
    
    var body: some View {
        ZStack {
            // Animated dark background
            AnimatedBackground()
            
            // Main card with luminescent outline
            LuminescentCard {
                VStack(spacing: 0) {
                // Header with logo
                VStack(spacing: 20) {
                    LogoView(size: 72)
                    
                    VStack(spacing: 10) {
                        Text("Create your account")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.white, Color(white: 0.85)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        
                        Text("Welcome! Please fill in the details to get started.")
                            .font(.system(size: 14))
                            .foregroundColor(Color(white: 0.5))
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.top, 48)
                .padding(.bottom, 36)
                
                // Mac Username display
                if !macUsername.isEmpty {
                    HStack(spacing: 12) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.white, Color(white: 0.7)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        Text(macUsername)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.04))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                    )
                    .padding(.horizontal, 36)
                    .padding(.bottom, 28)
                }
                
                // Glowing Divider
                GlowingDivider()
                    .padding(.horizontal, 36)
                    .padding(.bottom, 28)
                
                // Form fields
                VStack(spacing: 20) {
                    // Email field
                    ModernTextField(
                        title: "EMAIL",
                        placeholder: "Enter your email",
                        text: $email,
                        isFocused: focusedField == .email
                    )
                    .focused($focusedField, equals: .email)
                    .onSubmit { focusedField = .firstName }
                    
                    // First Name and Last Name side by side
                    HStack(spacing: 16) {
                        ModernTextField(
                            title: "FIRST NAME",
                            placeholder: "First name",
                            text: $firstName,
                            isFocused: focusedField == .firstName
                        )
                        .focused($focusedField, equals: .firstName)
                        .onSubmit { focusedField = .lastName }
                        
                        ModernTextField(
                            title: "LAST NAME",
                            placeholder: "Last name",
                            text: $lastName,
                            isFocused: focusedField == .lastName
                        )
                        .focused($focusedField, equals: .lastName)
                        .onSubmit { focusedField = .password }
                    }
                    
                    // Password field
                    ModernTextField(
                        title: "PASSWORD",
                        placeholder: "Enter your password",
                        text: $password,
                        isSecure: true,
                        isFocused: focusedField == .password
                    )
                    .focused($focusedField, equals: .password)
                    .onSubmit { handleLogin() }
                }
                .padding(.horizontal, 36)
                .padding(.bottom, 36)
                
                // Continue button with glow
                Button(action: handleLogin) {
                    HStack(spacing: 12) {
                        Text("Continue")
                            .font(.system(size: 16, weight: .semibold))
                        Spacer()
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .semibold))
                            .offset(x: isHoveredButton ? 4 : 0)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        ZStack {
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.white.opacity(isHoveredButton ? 0.15 : 0.08))
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(isHoveredButton ? 0.4 : 0.2),
                                            Color.white.opacity(isHoveredButton ? 0.15 : 0.08)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        }
                    )
                    .shadow(color: Color.white.opacity(isHoveredButton ? 0.2 : 0.1), radius: isHoveredButton ? 25 : 15)
                }
                .buttonStyle(.plain)
                .disabled(!isFormValid)
                .opacity(isFormValid ? 1.0 : 0.5)
                .padding(.horizontal, 36)
                .padding(.bottom, 28)
                .onHover { hovering in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isHoveredButton = hovering
                    }
                }
                
                // Sign in link
                HStack(spacing: 6) {
                    Text("Already have an account?")
                        .font(.system(size: 14))
                        .foregroundColor(Color(white: 0.5))
                    Button("Sign in") {
                        onShowSignIn()
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .buttonStyle(.plain)
                }
                .padding(.bottom, 48)
                }
                .frame(width: 500)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color(white: 0.06))
                )
            }
        }
        .frame(minWidth: 600, minHeight: 700)
        .onAppear {
            loadMacUsername()
            focusedField = .email
        }
    }
    
    private func loadMacUsername() {
        // Get Mac username from system
        macUsername = getMacUsername() ?? ""
    }
    
    private func handleLogin() {
        print("🔵 [CREATE ACCOUNT] Starting account creation...")
        print("   - First Name: \(firstName)")
        print("   - Last Name: \(lastName)")
        print("   - Mac Username: \(macUsername)")
        print("   - Email: \(email)")
        print("   - Email Valid: \(isEmailFieldValid)")
        
        guard isEmailFieldValid else {
            print("❌ [CREATE ACCOUNT] Invalid email format")
            return
        }
        
        Task {
            do {
                print("   - Using email for Firebase: \(email)")
                
                // Create user account in Firebase
                print("   - Calling AuthManager.signUp...")
                try await AuthManager.shared.signUp(
                    email: email,
                    password: password,
                    macUsername: macUsername,
                    firstName: firstName,
                    lastName: lastName
                )
                
                print("✅ [CREATE ACCOUNT] Success! User created: \(firstName) \(lastName) (\(macUsername))")
                
                // Store locally for quick access
                UserDefaults.standard.set(firstName, forKey: "userFirstName")
                UserDefaults.standard.set(lastName, forKey: "userLastName")
                UserDefaults.standard.set(macUsername, forKey: "userMacUsername")
                UserDefaults.standard.set(true, forKey: "userLoggedIn")
                
                // Notify parent view
                await MainActor.run {
                    onLogin()
                }
            } catch {
                print("❌ [CREATE ACCOUNT] Error creating account:")
                print("   - Error: \(error)")
                print("   - Localized: \(error.localizedDescription)")
                if let nsError = error as NSError? {
                    print("   - Domain: \(nsError.domain)")
                    print("   - Code: \(nsError.code)")
                    print("   - UserInfo: \(nsError.userInfo)")
                }
            }
        }
    }
    
    private func getMacUsername() -> String? {
        // Get system username
        let username = NSUserName()
        if username != "root" && !username.isEmpty {
            return username
        }
        return nil
    }
}

// MARK: - Modern Text Field Component
struct ModernTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    var isFocused: Bool = false
    
    @State private var isHovered = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Color(white: 0.45))
                .tracking(1.2)
            
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
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.03))
                    
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            isFocused ? Color.white.opacity(0.35) : Color.white.opacity(isHovered ? 0.15 : 0.08),
                            lineWidth: 1
                        )
                }
            )
            .shadow(color: isFocused ? Color.white.opacity(0.08) : .clear, radius: 12)
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.2)) {
                    isHovered = hovering
                }
            }
        }
    }
}

#Preview {
    LoginView(onLogin: {}, onShowSignIn: {})
}

