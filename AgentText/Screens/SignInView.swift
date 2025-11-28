import SwiftUI

struct SignInView: View {
    let onSignIn: () -> Void
    let onShowLogin: () -> Void
    
    @State private var password = ""
    @State private var macUsername = ""
    @State private var email = ""
    @State private var isHoveredButton = false
    @FocusState private var focusedField: Field?
    
    init(onSignIn: @escaping () -> Void = {}, onShowLogin: @escaping () -> Void = {}) {
        self.onSignIn = onSignIn
        self.onShowLogin = onShowLogin
    }
    
    enum Field {
        case email, password
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
        !password.isEmpty && isEmailFieldValid
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
                        Text("Sign in to your account")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.white, Color(white: 0.85)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        
                        Text("Welcome back! Please enter your details to continue.")
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
                    .onSubmit { focusedField = .password }
                    
                    // Password field
                    ModernTextField(
                        title: "PASSWORD",
                        placeholder: "Enter your password",
                        text: $password,
                        isSecure: true,
                        isFocused: focusedField == .password
                    )
                    .focused($focusedField, equals: .password)
                    .onSubmit { handleSignIn() }
                }
                .padding(.horizontal, 36)
                .padding(.bottom, 36)
                
                // Sign in button with glow
                Button(action: handleSignIn) {
                    HStack(spacing: 12) {
                        Text("Sign in")
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
                
                // Sign up link
                HStack(spacing: 6) {
                    Text("Don't have an account?")
                        .font(.system(size: 14))
                        .foregroundColor(Color(white: 0.5))
                    Button("Create account") {
                        onShowLogin()
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
    
    private func handleSignIn() {
        print("🔵 [SIGN IN] Starting sign in...")
        print("   - Mac Username: \(macUsername)")
        print("   - Email: \(email)")
        print("   - Email Valid: \(isEmailFieldValid)")
        
        guard isEmailFieldValid else {
            print("❌ [SIGN IN] Invalid email format")
            return
        }
        
        Task {
            do {
                print("   - Using email for Firebase: \(email)")
                
                // Sign in with Firebase
                print("   - Calling AuthManager.signIn...")
                try await AuthManager.shared.signIn(email: email, password: password)
                
                print("✅ [SIGN IN] Success! User signed in: \(macUsername)")
                
                // Store locally for quick access
                UserDefaults.standard.set(macUsername, forKey: "userMacUsername")
                UserDefaults.standard.set(true, forKey: "userLoggedIn")
                
                // Notify parent view
                await MainActor.run {
                    onSignIn()
                }
            } catch {
                print("❌ [SIGN IN] Error signing in:")
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

#Preview {
    SignInView(onSignIn: {})
}

