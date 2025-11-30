# Google OAuth Troubleshooting Checklist

Use this checklist to diagnose and fix Google OAuth issues.

## 🔍 Pre-Flight Checklist

Before testing, verify all these items:

### Google Cloud Console Configuration

- [ ] OAuth client type is "Desktop app" (NOT iOS or Web)
- [ ] Client ID: `33481136950-dj9epm8f78ltl86a0soi0k1cc2ls0ul4.apps.googleusercontent.com`
- [ ] Authorized redirect URI includes: `http://localhost:8080` (exactly, no trailing slash)
- [ ] Test user `niravjais@gmail.com` is added to OAuth consent screen
- [ ] Google Calendar API is enabled for the project
- [ ] Waited 30-60 seconds after saving changes

**Verify redirect URI:**
1. Go to: https://console.cloud.google.com/apis/credentials
2. Click client ID: `33481136950-dj9epm8f78ltl86a0soi0k1cc2ls0ul4`
3. Scroll to "Authorized redirect URIs"
4. Confirm `http://localhost:8080` is listed

### Code Configuration

- [ ] `GoogleOAuthManager.swift` has correct `clientId`
- [ ] `GoogleOAuthManager.swift` has `redirectUri = "http://localhost:8080"`
- [ ] No typos or extra spaces in client ID or redirect URI

### Firebase Configuration

- [ ] User is signed in to Firebase Auth
- [ ] Firestore security rules allow updating `googleOAuth` field
- [ ] Firebase project is properly configured in Xcode

## 📊 Common Error Messages and Solutions

### Error: "redirect_uri_mismatch"

**What you'll see:**
```
Error 400: redirect_uri_mismatch
```

**Cause:** Google Console redirect URI doesn't match code

**Fix:**
1. Double-check Google Console has `http://localhost:8080` (exact match)
2. No typos, no trailing slash, no extra spaces
3. Wait 60 seconds after saving
4. Try again

### Error: "access_denied"

**What you'll see:**
```
Error 403: access_denied
```

**Cause:** User not in test users list

**Fix:**
1. Go to: https://console.cloud.google.com/apis/credentials/consent
2. Scroll to "Test users"
3. Click "ADD USERS"
4. Add: `niravjais@gmail.com`
5. Save and try again

### Error: "invalid_client"

**What you'll see:**
```
Error 401: invalid_client
```

**Cause:** Client ID is incorrect

**Fix:**
1. Verify client ID in Google Console matches code
2. Make sure you're using Desktop app client ID
3. No spaces or typos in `GoogleOAuthManager.swift`

### Error: "Safari Can't Connect to the Server"

**What you'll see:**
- OAuth flow completes
- Safari shows "Can't connect to localhost:8080"
- App doesn't receive callback

**This is EXPECTED behavior:**
- Safari tries to load `http://localhost:8080?code=...`
- There's no server running on port 8080 (that's fine!)
- `ASWebAuthenticationSession` should intercept before Safari loads it

**If the app doesn't receive the callback:**
1. Check Xcode console for `[GoogleOAuth] Callback URL received` log
2. Verify callback scheme is `"http"` in code (line 82)
3. Make sure `ASWebAuthenticationSession` is configured correctly

### Error: "The provided scheme is not valid"

**What you'll see:**
```
NSInvalidArgumentException: The provided scheme is not valid.
A scheme should not include special characters such as ':' or '/'
```

**Cause:** Callback scheme has special characters

**Fix:**
✅ Already fixed! Code uses `let callbackScheme = "http"` without special chars

### Error: Token exchange fails

**What you'll see in Xcode console:**
```
[GoogleOAuth] Token exchange failed: ...
```

**Debugging steps:**
1. Check Xcode console for the full error message
2. Verify authorization code was extracted: `[GoogleOAuth] Authorization code extracted successfully`
3. Check network response in console
4. Common causes:
   - Authorization code already used (try fresh OAuth flow)
   - Network connectivity issues
   - Incorrect redirect_uri in token exchange (must match auth request)

### Error: Tokens not saving to Firestore

**What you'll see:**
```
❌ [GoogleOAuth] Error saving tokens to Firestore: ...
```

**Debugging steps:**
1. Verify user is signed in: `Auth.auth().currentUser?.uid`
2. Check Firestore security rules allow updates
3. Verify Firebase is properly initialized
4. Check Firebase Console for error logs

## 🔧 Debugging Steps

### 1. Enable Detailed Logging

The code already has detailed logging. Check Xcode console for:

```
[GoogleOAuth] Starting authentication flow
[GoogleOAuth] Client ID: 33481136950-...
[GoogleOAuth] Redirect URI: http://localhost:8080
[GoogleOAuth] Authorization URL: https://accounts.google.com/...
[GoogleOAuth] Callback scheme: http
[GoogleOAuth] Callback URL received: http://localhost:8080?code=...
[GoogleOAuth] Authorization code extracted successfully
[GoogleOAuth] Exchanging code for tokens...
[GoogleOAuth] Token exchange successful
✅ [GoogleOAuth] Tokens saved to Firestore successfully
```

### 2. Test OAuth Flow Step by Step

1. **Click "Connect Google Calendar"**
   - Check console: `[GoogleOAuth] Starting authentication flow`
   - Should see: `[GoogleOAuth] Authentication session started`

2. **Google consent screen appears**
   - If not, check: Client ID configured, test user added
   - Sign in with `niravjais@gmail.com`

3. **Grant calendar access**
   - Click "Allow" or "Continue"
   - Browser redirects to `http://localhost:8080?code=...`

4. **Safari shows connection error**
   - This is EXPECTED
   - Check console: `[GoogleOAuth] Callback URL received`

5. **Code exchanges for tokens**
   - Check console: `[GoogleOAuth] Exchanging code for tokens...`
   - Should see: `[GoogleOAuth] Token exchange successful`

6. **Tokens save to Firestore**
   - Check console: `✅ [GoogleOAuth] Tokens saved to Firestore successfully`
   - Verify in Firebase Console

### 3. Verify Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      // Allow users to read and write their own data
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

### 4. Test Token Refresh

After successful authentication, test token refresh:

```swift
GoogleOAuthManager.shared.getValidAccessToken { result in
    switch result {
    case .success(let token):
        print("✅ Valid token: \(token)")
    case .failure(let error):
        print("❌ Token refresh failed: \(error)")
    }
}
```

## 🎯 Success Indicators

You'll know everything is working when:

1. ✅ "Connect Google Calendar" button clicked
2. ✅ Google consent screen appears in Safari
3. ✅ Sign in successful with test user
4. ✅ Calendar permission granted
5. ✅ Safari redirects to localhost (shows connection error - that's OK!)
6. ✅ Xcode console shows: `[GoogleOAuth] Token exchange successful`
7. ✅ Xcode console shows: `✅ [GoogleOAuth] Tokens saved to Firestore successfully`
8. ✅ Profile tab shows green "Connected" indicator
9. ✅ Firebase Console shows `googleOAuth` field in user document
10. ✅ Success message appears in app

## 📞 Need More Help?

If you're still experiencing issues:

1. **Copy all Xcode console logs** starting from `[GoogleOAuth] Starting authentication flow`
2. **Note the exact error message** you're seeing
3. **Check Google Cloud Console** audit logs for OAuth requests
4. **Verify all checklist items** above are completed
5. **Try the OAuth flow** in an incognito/private browser window

## 🔒 Security Reminders

- ✅ Never commit client secrets to code (we're using public client - no secret)
- ✅ Tokens stored securely in Firestore with proper security rules
- ✅ All API calls use HTTPS
- ✅ Access tokens auto-refresh when expired
- ✅ Users can revoke access anytime from Profile tab
