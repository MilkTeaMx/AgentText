import SwiftUI

struct SignInView: View {
    let onSignIn: () -> Void
    let onShowLogin: () -> Void
    
    @State private var password = ""
    @State private var macUsername = ""
    @State private var email = ""
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
    
    var body: some View {
        ZStack {
            // Dark background
            Color(red: 0.1, green: 0.1, blue: 0.12)
                .ignoresSafeArea()
            
            // Main card with luminescent outline
            LuminescentCard {
                VStack(spacing: 0) {
                // Header with logo
                VStack(spacing: 16) {
                    LogoView()
                    
                    VStack(spacing: 8) {
                        Text("Sign in to your account")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Welcome back! Please enter your details to continue.")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.top, 40)
                .padding(.bottom, 32)
                
                // Mac Username display
                if !macUsername.isEmpty {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                        Text(macUsername)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                    )
                    .padding(.horizontal, 32)
                    .padding(.bottom, 24)
                }
                
                // Separator
                HStack {
                    Rectangle()
                        .fill(Color.white.opacity(0.2))
                        .frame(height: 1)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 24)
                
                // Form fields
                VStack(spacing: 16) {
                    // Email field (always show - required for Firebase)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                        TextField("Enter your email", text: $email)
                            .textFieldStyle(.plain)
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.white.opacity(0.05))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(focusedField == .email ? Color.white.opacity(0.3) : Color.white.opacity(0.1), lineWidth: 1)
                                    )
                            )
                            .foregroundColor(.white)
                            .focused($focusedField, equals: .email)
                            .onSubmit {
                                focusedField = .password
                            }
                    }
                    
                    // Password field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Password")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                        SecureField("Enter your password", text: $password)
                            .textFieldStyle(.plain)
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.white.opacity(0.05))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(focusedField == .password ? Color.white.opacity(0.3) : Color.white.opacity(0.1), lineWidth: 1)
                                    )
                            )
                            .foregroundColor(.white)
                            .focused($focusedField, equals: .password)
                            .onSubmit {
                                handleSignIn()
                            }
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
                
                // Sign in button
                Button(action: handleSignIn) {
                    HStack(spacing: 12) {
                        Text("Sign in")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white.opacity(0.9))
                        Spacer()
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .padding(.horizontal, 20)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(red: 0.2, green: 0.2, blue: 0.22))
                    )
                }
                .buttonStyle(.plain)
                .disabled(password.isEmpty || !isEmailFieldValid)
                .opacity(password.isEmpty || !isEmailFieldValid ? 0.5 : 1.0)
                .padding(.horizontal, 32)
                .padding(.bottom, 24)
                
                // Sign up link
                HStack {
                    Text("Don't have an account?")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                    Button("Create account") {
                        onShowLogin()
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                }
                .padding(.bottom, 40)
                }
                .frame(width: 480)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(red: 0.15, green: 0.15, blue: 0.18))
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

