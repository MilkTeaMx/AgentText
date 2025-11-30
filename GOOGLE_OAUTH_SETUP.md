# Google OAuth 2.0 Setup Guide

This guide will walk you through setting up Google OAuth 2.0 for Calendar access in your AgentText app.

## 🚀 Quick Start - Complete These Steps Now

**Your configuration is almost complete! Just one step remaining:**

### ⚠️ REQUIRED: Update Google Cloud Console

1. Go to: https://console.cloud.google.com/apis/credentials
2. Find and click your OAuth client ID: `33481136950-dj9epm8f78ltl86a0soi0k1cc2ls0ul4`
3. Under "Authorized redirect URIs", click "ADD URI"
4. Enter: `http://localhost:8080`
5. Click "Save"
6. **Wait 30-60 seconds** for changes to propagate
7. Test the "Connect Google Calendar" button in your app

### ✅ Already Configured

- ✅ Client ID: `33481136950-dj9epm8f78ltl86a0soi0k1cc2ls0ul4.apps.googleusercontent.com`
- ✅ Redirect URI in code: `http://localhost:8080`
- ✅ Test user added: `niravjais@gmail.com`
- ✅ Swift OAuth implementation complete
- ✅ Firestore integration ready

---

## Overview

The implementation uses:
- **Frontend (Swift)**: Handles the complete OAuth flow using `ASWebAuthenticationSession`
- **Firebase Firestore**: Securely stores access tokens and refresh tokens
- **Automatic Token Refresh**: Tokens are automatically refreshed when expired

## Security Features

✅ **Client Secret Protection**: Uses OAuth 2.0 for public clients (no client secret exposed)
✅ **Secure Token Storage**: Tokens stored in Firebase Firestore with proper security rules
✅ **Automatic Refresh**: Access tokens automatically refreshed using refresh tokens
✅ **Token Revocation**: Users can disconnect and revoke access at any time

## Setup Instructions

### Step 1: Google Cloud Console Configuration

1. **Go to Google Cloud Console**
   - Visit: https://console.cloud.google.com/

2. **Create or Select a Project**
   - Click "Select a project" at the top
   - Create a new project or select an existing one

3. **Enable Google Calendar API**
   - Go to "APIs & Services" > "Library"
   - Search for "Google Calendar API"
   - Click "Enable"

4. **Configure OAuth Consent Screen**
   - Go to "APIs & Services" > "OAuth consent screen"
   - Select "External" (or "Internal" if using Google Workspace)
   - Fill in required fields:
     - **App name**: AgentText
     - **User support email**: Your email
     - **Developer contact email**: Your email
   - Click "Save and Continue"

5. **Add Scopes**
   - Click "Add or Remove Scopes"
   - Add the following scope:
     - `https://www.googleapis.com/auth/calendar`
   - Click "Update" then "Save and Continue"

6. **Add Test Users** (for development)
   - Click "Add Users"
   - Add your Google account email
   - Click "Save and Continue"

7. **Create OAuth 2.0 Client ID**
   - Go to "APIs & Services" > "Credentials"
   - Click "Create Credentials" > "OAuth 2.0 Client ID"
   - Select "Desktop app" as application type (NOT iOS or Web)
   - **Name**: AgentText Desktop
   - Click "Create"

8. **Configure Authorized Redirect URIs**
   - After creating the client, click on it to edit
   - Under "Authorized redirect URIs", click "ADD URI"
   - Add: `http://localhost:8080`
   - Click "Save"
   - **IMPORTANT**: Wait 30-60 seconds for changes to propagate

9. **Copy Client ID**
   - Copy the generated Client ID (looks like: `123456789-abcdefg.apps.googleusercontent.com`)
   - You'll need this for Step 2 (already configured: `33481136950-dj9epm8f78ltl86a0soi0k1cc2ls0ul4.apps.googleusercontent.com`)

### Step 2: Swift Code Configuration

✅ **ALREADY CONFIGURED** - No changes needed!

The Swift code is already configured with:
- Client ID: `33481136950-dj9epm8f78ltl86a0soi0k1cc2ls0ul4.apps.googleusercontent.com`
- Redirect URI: `http://localhost:8080`

Located in: [GoogleOAuthManager.swift:19-23](AgentText/Services/GoogleOAuthManager.swift#L19-L23)

### Step 3: Xcode URL Scheme

❌ **NOT REQUIRED** for localhost redirect URIs

Custom URL schemes are not needed when using `http://localhost` redirect URIs. The `ASWebAuthenticationSession` will automatically intercept localhost callbacks.

### Step 4: Update Firestore Security Rules

Update your Firestore security rules to allow users to store OAuth tokens:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      // Allow users to read and write their own data
      allow read, write: if request.auth != null && request.auth.uid == userId;

      // Specifically allow updating googleOAuth field
      allow update: if request.auth != null
                    && request.auth.uid == userId
                    && request.resource.data.keys().hasOnly(['googleOAuth']);
    }
  }
}
```

**Important Security Notes**:
- Only authenticated users can access their own data
- OAuth tokens are stored under `users/{userId}/googleOAuth`
- Tokens are encrypted in transit (HTTPS) and at rest (Firebase)

### Step 5: Test the Integration

**NEXT STEPS TO COMPLETE:**

1. **Update Google Cloud Console**
   - Go to: https://console.cloud.google.com/apis/credentials
   - Click on your Desktop app OAuth client: `33481136950-dj9epm8f78ltl86a0soi0k1cc2ls0ul4`
   - Under "Authorized redirect URIs", add: `http://localhost:8080`
   - Click "Save"
   - **Wait 30-60 seconds** for Google to propagate the changes

2. **Ensure you're added as a test user**
   - Go to "APIs & Services" > "OAuth consent screen"
   - Under "Test users", verify `niravjais@gmail.com` is added
   - If not, add it now

3. **Build and run your app**
   - In Xcode, build and run AgentText
   - Navigate to the Profile tab
   - Click "Connect Google Calendar"

4. **Expected OAuth flow**:
   - ✅ Google OAuth consent screen opens in Safari
   - ✅ Sign in with `niravjais@gmail.com`
   - ✅ Grant calendar access
   - ✅ Safari redirects to `http://localhost:8080?code=...`
   - ✅ ASWebAuthenticationSession intercepts the redirect
   - ✅ Code is exchanged for tokens
   - ✅ Tokens are saved to Firestore
   - ✅ Success message appears in the app

5. **Verify tokens are stored in Firestore**:
   - Go to Firebase Console > Firestore: https://console.firebase.google.com/
   - Navigate to: `users/{your-user-id}`
   - You should see a `googleOAuth` field with:
     - `accessToken`: "ya29.a0A..."
     - `refreshToken`: "1//0g..."
     - `expiresAt`: Timestamp
     - `scope`: "https://www.googleapis.com/auth/calendar"
     - `tokenType`: "Bearer"

6. **Check Xcode console for logs**:
   - You should see detailed OAuth flow logs like:
   ```
   [GoogleOAuth] Starting authentication flow
   [GoogleOAuth] Client ID: 33481136950-...
   [GoogleOAuth] Redirect URI: http://localhost:8080
   [GoogleOAuth] Authorization URL: https://accounts.google.com/...
   [GoogleOAuth] Callback URL received: http://localhost:8080?code=...
   [GoogleOAuth] Authorization code extracted successfully
   [GoogleOAuth] Token exchange successful
   ✅ [GoogleOAuth] Tokens saved to Firestore successfully
   ```

## Using the Google Calendar API

### Fetch Upcoming Events

```swift
import SwiftUI

struct CalendarView: View {
    @State private var events: [CalendarEvent] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Loading events...")
            } else if let error = errorMessage {
                Text("Error: \(error)")
                    .foregroundColor(.red)
            } else {
                List(events, id: \.id) { event in
                    VStack(alignment: .leading) {
                        Text(event.summary ?? "No title")
                            .font(.headline)
                        if let start = event.start?.dateTime {
                            Text(start)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
            }

            Button("Fetch Events") {
                fetchEvents()
            }
        }
        .onAppear {
            fetchEvents()
        }
    }

    private func fetchEvents() {
        isLoading = true
        errorMessage = nil

        GoogleCalendarService.shared.fetchUpcomingEvents(maxResults: 10) { result in
            isLoading = false

            switch result {
            case .success(let fetchedEvents):
                events = fetchedEvents
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
    }
}
```

### Create a New Event

```swift
func createMeeting() {
    let newEvent = CalendarEvent(
        id: nil,
        summary: "Team Standup",
        description: "Daily sync meeting",
        start: CalendarEvent.EventDateTime(
            dateTime: "2024-03-15T09:00:00-08:00",
            timeZone: "America/Los_Angeles",
            date: nil
        ),
        end: CalendarEvent.EventDateTime(
            dateTime: "2024-03-15T09:30:00-08:00",
            timeZone: "America/Los_Angeles",
            date: nil
        ),
        location: "Zoom",
        status: nil,
        htmlLink: nil
    )

    GoogleCalendarService.shared.createEvent(newEvent) { result in
        switch result {
        case .success(let event):
            print("✅ Created event: \(event.summary ?? "Unknown")")
        case .failure(let error):
            print("❌ Error: \(error.localizedDescription)")
        }
    }
}
```

### Delete an Event

```swift
func deleteEvent(eventId: String) {
    GoogleCalendarService.shared.deleteEvent(eventId: eventId) { result in
        switch result {
        case .success:
            print("✅ Event deleted successfully")
        case .failure(let error):
            print("❌ Error: \(error.localizedDescription)")
        }
    }
}
```

### List All Calendars

```swift
func listCalendars() {
    GoogleCalendarService.shared.listCalendars { result in
        switch result {
        case .success(let calendars):
            for calendar in calendars {
                print("📅 \(calendar.summary ?? "Unknown calendar")")
                if calendar.primary == true {
                    print("   (Primary)")
                }
            }
        case .failure(let error):
            print("❌ Error: \(error.localizedDescription)")
        }
    }
}
```

## Token Management

### Automatic Token Refresh

Tokens are automatically refreshed when expired. The `GoogleOAuthManager` handles this transparently:

```swift
// This automatically refreshes the token if needed
GoogleCalendarService.shared.fetchUpcomingEvents { result in
    // Handle result
}
```

### Manual Token Refresh

If you need to manually check or refresh tokens:

```swift
GoogleOAuthManager.shared.getValidAccessToken { result in
    switch result {
    case .success(let accessToken):
        print("✅ Valid token: \(accessToken)")
    case .failure(let error):
        print("❌ Error: \(error.localizedDescription)")
        // User needs to re-authenticate
    }
}
```

### Disconnect Google Account

Users can disconnect their Google account from the Profile tab, or programmatically:

```swift
GoogleOAuthManager.shared.revokeAccess { result in
    switch result {
    case .success:
        print("✅ Access revoked successfully")
    case .failure(let error):
        print("❌ Error: \(error.localizedDescription)")
    }
}
```

## Troubleshooting

### Common Issues

#### 1. "Invalid redirect URI" or "redirect_uri_mismatch" error

**Problem**: The redirect URI doesn't match what's configured in Google Cloud Console.

**Solution**:
- Verify `http://localhost:8080` is added to Authorized redirect URIs in Google Console
- Make sure you're editing the Desktop app client (not iOS or Web)
- Wait 30-60 seconds after saving for Google to propagate changes
- Make sure there are no typos or extra spaces

#### 2. "Access blocked: Authorization Error"

**Problem**: The OAuth consent screen is not properly configured or app is not verified.

**Solution**:
- Add yourself as a test user in Google Cloud Console
- For production, submit your app for verification

#### 3. "Token has expired" errors

**Problem**: Refresh token is missing or invalid.

**Solution**:
- Make sure `access_type=offline` is set in the OAuth request (already configured)
- Make sure `prompt=consent` is set to force getting a refresh token
- User may need to re-authenticate

#### 4. Tokens not saving to Firestore

**Problem**: Firestore security rules blocking writes.

**Solution**:
- Check Firestore security rules (see Step 4)
- Verify user is authenticated
- Check Firebase console for error logs

#### 5. "Client ID not found" error

**Problem**: Client ID is incorrect or not properly configured.

**Solution**:
- Double-check the Client ID in `GoogleOAuthManager.swift`
- Verify it matches the one in Google Cloud Console
- Make sure you're using the iOS client ID, not web client ID

## Best Practices

### Security

1. **Never expose client secrets**: This implementation uses OAuth 2.0 for public clients (no secret needed)
2. **Use HTTPS**: All API calls use HTTPS automatically
3. **Store tokens securely**: Tokens are stored in Firestore with proper security rules
4. **Limit scope**: Only request the permissions you need (`calendar` scope)
5. **Token rotation**: Implement automatic token refresh (already done)

### User Experience

1. **Clear messaging**: Explain why you need calendar access
2. **Error handling**: Provide clear error messages to users
3. **Loading states**: Show progress indicators during OAuth flow
4. **Disconnect option**: Allow users to revoke access easily
5. **Re-authentication**: Handle expired refresh tokens gracefully

### Production Readiness

Before publishing to production:

1. **OAuth Consent Screen Verification**
   - Submit your app for verification in Google Cloud Console
   - This removes the "unverified app" warning

2. **Update Firestore Rules**
   - Add more granular security rules
   - Consider rate limiting

3. **Error Logging**
   - Add analytics/error tracking
   - Monitor token refresh failures

4. **Testing**
   - Test with multiple Google accounts
   - Test token expiration and refresh
   - Test revocation flow
   - Test offline scenarios

## API Reference

### GoogleOAuthManager

```swift
class GoogleOAuthManager {
    static let shared: GoogleOAuthManager

    @Published var isAuthenticated: Bool
    @Published var userEmail: String?

    func authenticate(completion: @escaping (Result<String, Error>) -> Void)
    func getValidAccessToken(completion: @escaping (Result<String, Error>) -> Void)
    func revokeAccess(completion: @escaping (Result<Void, Error>) -> Void)
}
```

### GoogleCalendarService

```swift
class GoogleCalendarService {
    static let shared: GoogleCalendarService

    func fetchUpcomingEvents(maxResults: Int, completion: @escaping (Result<[CalendarEvent], Error>) -> Void)
    func createEvent(_ event: CalendarEvent, completion: @escaping (Result<CalendarEvent, Error>) -> Void)
    func deleteEvent(eventId: String, completion: @escaping (Result<Void, Error>) -> Void)
    func listCalendars(completion: @escaping (Result<[Calendar], Error>) -> Void)
}
```

## Additional Resources

- [Google Calendar API Documentation](https://developers.google.com/calendar/api/v3/reference)
- [OAuth 2.0 for Mobile Apps](https://developers.google.com/identity/protocols/oauth2/native-app)
- [Firebase Security Rules](https://firebase.google.com/docs/firestore/security/get-started)
- [ASWebAuthenticationSession Documentation](https://developer.apple.com/documentation/authenticationservices/aswebauthenticationsession)

## Support

If you encounter issues:
1. Check the troubleshooting section above
2. Verify all setup steps were completed
3. Check Xcode console for error messages
4. Review Firebase logs for authentication errors
5. Verify Google Cloud Console configuration

## License

This implementation is part of AgentText and follows the same license.
