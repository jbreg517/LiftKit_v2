import SwiftUI
import SwiftData
import AuthenticationServices
import CryptoKit

struct LoginView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme

    @State private var displayName: String = ""
    @State private var isSigningIn = false
    @State private var errorMessage: String? = nil

    var body: some View {
        NavigationStack {
            VStack(spacing: LKSpacing.xl) {
                Spacer()

                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(LKColors.Hex.accent)

                Text("LiftKit")
                    .font(.system(size: 34, weight: .heavy))
                    .foregroundStyle(LKColors.Hex.textPrimary)

                Text("Activate premium to unlock the calendar, more workout plans, and more.")
                    .font(LKFont.body)
                    .foregroundStyle(LKColors.Hex.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, LKSpacing.xl)

                Spacer()

                VStack(spacing: LKSpacing.md) {
                    TextField("Your name (optional)", text: $displayName)
                        .font(LKFont.body)
                        .foregroundStyle(LKColors.Hex.textPrimary)
                        .padding(LKSpacing.md)
                        .background(LKColors.Hex.surface)
                        .clipShape(RoundedRectangle(cornerRadius: LKRadius.medium))
                        .padding(.horizontal, LKSpacing.lg)

                    if let err = errorMessage {
                        Text(err).font(LKFont.caption).foregroundStyle(LKColors.Hex.danger)
                            .padding(.horizontal, LKSpacing.lg)
                    }

                    SignInWithAppleButton(.signIn) { request in
                        request.requestedScopes = [.fullName, .email]
                    } onCompletion: { result in
                        handleAppleSignIn(result: result)
                    }
                    .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                    .frame(height: 52)
                    .clipShape(RoundedRectangle(cornerRadius: LKRadius.medium))
                    .padding(.horizontal, LKSpacing.lg)
                    .accessibilityLabel("Sign in with Apple")

                    Button {
                        signInWithGoogle()
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "g.circle.fill").font(.title3)
                            Text("Sign in with Google").font(.system(size: 17, weight: .semibold))
                        }
                        .foregroundStyle(LKColors.Hex.textPrimary)
                        .frame(maxWidth: .infinity).frame(height: 52)
                        .background(LKColors.Hex.surface)
                        .clipShape(RoundedRectangle(cornerRadius: LKRadius.medium))
                        .overlay(RoundedRectangle(cornerRadius: LKRadius.medium)
                            .strokeBorder(LKColors.Hex.surfaceElevated, lineWidth: 1))
                    }
                    .padding(.horizontal, LKSpacing.lg)
                    .accessibilityLabel("Sign in with Google")

                    Button {
                        activatePremiumLocally()
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "crown.fill").font(.title3)
                            Text("Activate Premium").font(.system(size: 17, weight: .semibold))
                        }
                        .foregroundStyle(LKColors.Hex.background)
                        .frame(maxWidth: .infinity).frame(height: 52)
                        .background(LKColors.Hex.accent)
                        .clipShape(RoundedRectangle(cornerRadius: LKRadius.medium))
                    }
                    .padding(.horizontal, LKSpacing.lg)
                }

                Button { dismiss() } label: {
                    Text("Continue without signing in")
                        .font(LKFont.body).foregroundStyle(LKColors.Hex.textMuted)
                }
                .padding(.bottom, LKSpacing.xl)
            }
            .background(LKColors.Hex.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark").foregroundStyle(LKColors.Hex.textSecondary)
                    }
                }
            }
        }
    }

    // MARK: - Apple Sign-In

    private func handleAppleSignIn(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let auth):
            guard let credential = auth.credential as? ASAuthorizationAppleIDCredential else { return }
            let userId = credential.user
            let name = displayName.isEmpty
                ? [credential.fullName?.givenName, credential.fullName?.familyName]
                    .compactMap { $0 }.joined(separator: " ")
                : displayName
            let email = credential.email
            saveProfile(displayName: name.isEmpty ? nil : name, email: email,
                        authProvider: "apple", externalId: userId)
        case .failure(let error):
            if (error as NSError).code != ASAuthorizationError.canceled.rawValue {
                errorMessage = "Sign in failed: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Google Sign-In (Authorization Code + PKCE)
    //
    // Setup steps (one-time, ~5 minutes):
    //   1. Go to console.cloud.google.com → APIs & Services → Credentials
    //   2. Create project (or select existing), enable "People API"
    //   3. Create OAuth Client ID → Application type: iOS
    //      Bundle ID: com.liftkit.app
    //   4. Copy the client ID (format: XXXXXXXXXX-xxxx.apps.googleusercontent.com)
    //   5. Paste it below and in Info.plist CFBundleURLSchemes as the reversed ID:
    //      com.googleusercontent.apps.XXXXXXXXXX-xxxx
    //
    // No client secret is needed — PKCE handles security for native apps.

    private let googleClientId = "YOUR_CLIENT_ID.apps.googleusercontent.com"

    private func signInWithGoogle() {
        guard googleClientId != "YOUR_CLIENT_ID.apps.googleusercontent.com" else {
            errorMessage = "Google Sign-In not configured. See LoginView.swift setup steps."
            return
        }

        let reversed = googleClientId.components(separatedBy: ".apps.googleusercontent.com")[0]
        let redirectScheme = "com.googleusercontent.apps.\(reversed)"
        let redirectUri = "\(redirectScheme):/oauth2redirect"
        let codeVerifier  = generatePKCEVerifier()
        let codeChallenge = generatePKCEChallenge(from: codeVerifier)

        var components = URLComponents(string: "https://accounts.google.com/o/oauth2/v2/auth")!
        components.queryItems = [
            URLQueryItem(name: "client_id",             value: googleClientId),
            URLQueryItem(name: "redirect_uri",          value: redirectUri),
            URLQueryItem(name: "response_type",         value: "code"),
            URLQueryItem(name: "scope",                 value: "openid profile email"),
            URLQueryItem(name: "code_challenge",        value: codeChallenge),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
        ]
        guard let authURL = components.url else { return }

        let session = ASWebAuthenticationSession(url: authURL, callbackURLScheme: redirectScheme) { [self] callbackURL, error in
            guard error == nil, let url = callbackURL else {
                if let err = error,
                   (err as NSError).code != ASWebAuthenticationSessionError.canceledLogin.rawValue {
                    DispatchQueue.main.async { errorMessage = "Google sign-in failed" }
                }
                return
            }
            guard let code = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                .queryItems?.first(where: { $0.name == "code" })?.value else { return }
            exchangeGoogleCode(code, verifier: codeVerifier, redirectUri: redirectUri, clientId: googleClientId)
        }
        session.prefersEphemeralWebBrowserSession = true
        session.start()
    }

    private func exchangeGoogleCode(_ code: String, verifier: String, redirectUri: String, clientId: String) {
        guard let url = URL(string: "https://oauth2.googleapis.com/token") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        let body = ["code": code, "client_id": clientId, "redirect_uri": redirectUri,
                    "grant_type": "authorization_code", "code_verifier": verifier]
            .map { "\($0.key)=\($0.value)" }.joined(separator: "&")
        request.httpBody = body.data(using: .utf8)
        URLSession.shared.dataTask(with: request) { data, _, _ in
            guard let data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let accessToken = json["access_token"] as? String else { return }
            fetchGoogleUserInfo(accessToken: accessToken)
        }.resume()
    }

    private func fetchGoogleUserInfo(accessToken: String) {
        guard let url = URL(string: "https://www.googleapis.com/oauth2/v2/userinfo") else { return }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: request) { data, _, _ in
            guard let data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }
            let name  = json["name"]  as? String
            let email = json["email"] as? String
            let id    = json["id"]    as? String ?? accessToken.prefix(20).description
            DispatchQueue.main.async {
                saveProfile(displayName: name, email: email, authProvider: "google", externalId: id)
            }
        }.resume()
    }

    // MARK: - PKCE

    private func generatePKCEVerifier() -> String {
        var bytes = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return Data(bytes).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    private func generatePKCEChallenge(from verifier: String) -> String {
        let hashed = SHA256.hash(data: Data(verifier.utf8))
        return Data(hashed).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    // MARK: - Local Premium

    private func activatePremiumLocally() {
        let name = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        saveProfile(displayName: name.isEmpty ? nil : name, email: nil,
                    authProvider: "local", externalId: nil)
    }

    private func saveProfile(displayName: String?, email: String?, authProvider: String, externalId: String? = nil) {
        let descriptor = FetchDescriptor<UserProfile>()
        let existing = (try? modelContext.fetch(descriptor))?.first
        if let profile = existing {
            if let n = displayName, !n.isEmpty { profile.displayName = n }
            if let e = email { profile.email = e }
            profile.authProvider = authProvider
            profile.isPremium = true
        } else {
            let profile = UserProfile(displayName: displayName, email: email,
                                      authProvider: authProvider, isPremium: true)
            modelContext.insert(profile)
        }
        try? modelContext.save()
        dismiss()
    }
}
