# Detailed Comparison: Google Calendar vs Notion Integration

This document provides an in-depth comparison of how Google Calendar and Notion integrations work in AgentText, highlighting similarities, differences, and implementation details.

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Authentication Flow Comparison](#authentication-flow-comparison)
3. [Token Management](#token-management)
4. [API Service Layer](#api-service-layer)
5. [Firestore Storage](#firestore-storage)
6. [Step-by-Step Flow Diagrams](#step-by-step-flow-diagrams)
7. [Key Differences Summary](#key-differences-summary)

---

## Architecture Overview

Both integrations follow the same architectural pattern:

```
┌─────────────────────────────────────────────────────────┐
│                    User Interface                        │
│  (IntegrationsView, Connect Buttons, etc.)              │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│              OAuth Manager Layer                        │
│  ┌──────────────────┐    ┌──────────────────┐         │
│  │ GoogleOAuthMgr   │    │ NotionOAuthMgr   │         │
│  │ - authenticate() │    │ - authenticate() │         │
│  │ - getToken()     │    │ - getToken()     │         │
│  │ - refreshToken() │    │ - setToken()     │         │
│  └──────────────────┘    └──────────────────┘         │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│              API Service Layer                          │
│  ┌──────────────────┐    ┌──────────────────┐         │
│  │ GoogleCalendar   │    │ NotionService    │         │
│  │ Service          │    │                  │         │
│  │ - fetchEvents()  │    │ - retrievePage() │         │
│  │ - createEvent()  │    │ - createPage()  │         │
│  └──────────────────┘    └──────────────────┘         │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│              Firebase Firestore                         │
│  users/{userId}/                                        │
│    - googleOAuth: { tokens }                           │
│    - notionOAuth: { tokens }                           │
│    - integrationKeys: {                                │
│        google_calendar: "token",                       │
│        notion: "token"                                 │
│      }                                                  │
└─────────────────────────────────────────────────────────┘
```

---

## Authentication Flow Comparison

### Google Calendar OAuth 2.0 Flow

**Step-by-Step Process:**

1. **User Initiates Connection**
   ```swift
   GoogleOAuthManager.shared.authenticate { result in ... }
   ```

2. **Build Authorization URL**
   - Endpoint: `https://accounts.google.com/o/oauth2/v2/auth`
   - Parameters:
     - `client_id`: Google OAuth Client ID
     - `redirect_uri`: Custom URL scheme (e.g., `com.googleusercontent.apps.XXX:/oauth2redirect`)
     - `response_type`: `code`
     - `scope`: `https://www.googleapis.com/auth/calendar`
     - `access_type`: `offline` (to get refresh token)
     - `prompt`: `consent` (force consent screen)

3. **Open Browser (ASWebAuthenticationSession)**
   - Opens Safari with Google consent screen
   - User grants permissions
   - Google redirects to `redirect_uri` with authorization code

4. **Extract Authorization Code**
   - Parse callback URL: `com.googleusercontent.apps.XXX:/oauth2redirect?code=AUTH_CODE`
   - Extract `code` parameter

5. **Exchange Code for Tokens** ⚠️ **KEY DIFFERENCE**
   - **Endpoint**: `https://oauth2.googleapis.com/token`
   - **Method**: POST with form data
   - **Parameters**:
     - `code`: Authorization code
     - `client_id`: OAuth client ID
     - `redirect_uri`: Same as used in step 2
     - `grant_type`: `authorization_code`
   - **Response**: 
     ```json
     {
       "access_token": "ya29...",
       "expires_in": 3600,
       "refresh_token": "1//0g...",
       "token_type": "Bearer",
       "scope": "..."
     }
     ```
   - **Note**: Google allows client-side token exchange (no client secret required for public clients)

6. **Store Tokens**
   - Save to Firestore
   - Store in memory for quick access

### Notion OAuth 2.0 Flow

**Step-by-Step Process:**

1. **User Initiates Connection**
   ```swift
   NotionOAuthManager.shared.authenticate { result in ... }
   ```

2. **Build Authorization URL**
   - Endpoint: `https://api.notion.com/v1/oauth/authorize`
   - Parameters:
     - `client_id`: Notion OAuth Client ID
     - `redirect_uri`: Custom URL scheme (e.g., `com.agenttext.notion:/oauth2redirect`)
     - `response_type`: `code`
     - `owner`: `user` or `workspace`

3. **Open Browser (ASWebAuthenticationSession)**
   - Opens Safari with Notion consent screen
   - User grants permissions
   - Notion redirects to `redirect_uri` with authorization code

4. **Extract Authorization Code**
   - Parse callback URL: `com.agenttext.notion:/oauth2redirect?code=AUTH_CODE`
   - Extract `code` parameter

5. **Exchange Code for Tokens** ⚠️ **KEY DIFFERENCE**
   - **Endpoint**: `https://api.notion.com/v1/oauth/token`
   - **Method**: POST with JSON
   - **Authentication**: Basic Auth with `client_id:client_secret`
   - **Parameters**:
     ```json
     {
       "grant_type": "authorization_code",
       "code": "AUTH_CODE",
       "redirect_uri": "..."
     }
     ```
   - **Response**:
     ```json
     {
       "access_token": "secret_...",
       "token_type": "Bearer",
       "workspace_name": "...",
       "workspace_icon": "...",
       "bot_id": "..."
     }
     ```
   - **⚠️ CRITICAL**: Notion **REQUIRES** a client secret, which **MUST** be kept on a backend server
   - **Cannot be done client-side** - requires backend endpoint

6. **Store Tokens**
   - Save to Firestore
   - Store in memory for quick access

### Notion Alternative: Internal Integration Token

**Simpler Flow (No OAuth):**

1. **User Gets Token from Notion Dashboard**
   - Go to: https://www.notion.com/my-integrations
   - Create integration
   - Copy token (starts with `secret_`)

2. **User Enters Token in App**
   ```swift
   NotionOAuthManager.shared.setInternalIntegrationToken("secret_...") { result in ... }
   ```

3. **Validate and Store**
   - Validate format (must start with `secret_`)
   - Save directly to Firestore
   - No token exchange needed!

---

## Token Management

### Google Calendar Token Lifecycle

```
┌─────────────────────────────────────────────────────────┐
│  Initial Authentication                                 │
│  ┌──────────────────────────────────────────────────┐  │
│  │ 1. Get access_token (expires in 1 hour)          │  │
│  │ 2. Get refresh_token (never expires)              │  │
│  └──────────────────────────────────────────────────┘  │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│  Token Usage                                           │
│  ┌──────────────────────────────────────────────────┐  │
│  │ API Call → Check if access_token valid?         │  │
│  │   ├─ Yes → Use access_token                      │  │
│  │   └─ No → Refresh using refresh_token            │  │
│  └──────────────────────────────────────────────────┘  │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│  Auto-Refresh (Background)                             │
│  ┌──────────────────────────────────────────────────┐  │
│  │ refreshAccessToken()                             │  │
│  │   → POST to oauth2.googleapis.com/token         │  │
│  │   → Get new access_token                         │  │
│  │   → Update Firestore                             │  │
│  └──────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

**Key Features:**
- ✅ Access tokens expire (1 hour)
- ✅ Refresh tokens never expire (unless revoked)
- ✅ Automatic refresh before expiry
- ✅ Seamless user experience

### Notion Token Lifecycle

**OAuth 2.0 Tokens:**
```
┌─────────────────────────────────────────────────────────┐
│  Initial Authentication                                 │
│  ┌──────────────────────────────────────────────────┐  │
│  │ 1. Get access_token (expires in 1 hour)          │  │
│  │ 2. No refresh_token (Notion doesn't provide)     │  │
│  └──────────────────────────────────────────────────┘  │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│  Token Usage                                           │
│  ┌──────────────────────────────────────────────────┐  │
│  │ API Call → Check if access_token valid?         │  │
│  │   ├─ Yes → Use access_token                      │  │
│  │   └─ No → User must re-authenticate              │  │
│  └──────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

**Internal Integration Tokens:**
```
┌─────────────────────────────────────────────────────────┐
│  Token Setup                                            │
│  ┌──────────────────────────────────────────────────┐  │
│  │ 1. User gets token from Notion dashboard        │  │
│  │ 2. Token never expires                           │  │
│  │ 3. No refresh needed                             │  │
│  └──────────────────────────────────────────────────┘  │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│  Token Usage                                           │
│  ┌──────────────────────────────────────────────────┐  │
│  │ API Call → Use token directly                    │  │
│  │ (No expiry check needed)                         │  │
│  └──────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

**Key Features:**
- ⚠️ OAuth tokens expire (1 hour) with no refresh mechanism
- ✅ Internal tokens never expire
- ⚠️ OAuth requires re-authentication when expired
- ✅ Internal tokens work indefinitely

---

## API Service Layer

### Google Calendar Service

**Pattern:**
```swift
func fetchUpcomingEvents(completion: @escaping (Result<[CalendarEvent], Error>) -> Void) {
    // 1. Get valid access token (auto-refreshes if needed)
    oauthManager.getValidAccessToken { result in
        switch result {
        case .success(let accessToken):
            // 2. Make API call with token
            self.performFetchEvents(accessToken: accessToken, completion: completion)
        case .failure(let error):
            completion(.failure(error))
        }
    }
}

private func performFetchEvents(accessToken: String, ...) {
    var request = URLRequest(url: url)
    request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
    // ... make request
}
```

**API Endpoints:**
- Base URL: `https://www.googleapis.com/calendar/v3`
- Get Events: `GET /calendars/primary/events`
- Create Event: `POST /calendars/primary/events`
- Delete Event: `DELETE /calendars/primary/events/{eventId}`
- List Calendars: `GET /users/me/calendarList`

**Headers:**
- `Authorization: Bearer {access_token}`

### Notion Service

**Pattern:**
```swift
func retrievePage(pageId: String, completion: @escaping (Result<NotionPage, Error>) -> Void) {
    // 1. Get valid access token
    oauthManager.getValidAccessToken { result in
        switch result {
        case .success(let accessToken):
            // 2. Make API call with token
            self.performRetrievePage(accessToken: accessToken, pageId: pageId, completion: completion)
        case .failure(let error):
            completion(.failure(error))
        }
    }
}

private func performRetrievePage(accessToken: String, ...) {
    var request = URLRequest(url: url)
    request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
    request.setValue("2022-06-28", forHTTPHeaderField: "Notion-Version")
    // ... make request
}
```

**API Endpoints:**
- Base URL: `https://api.notion.com/v1`
- Get Page: `GET /pages/{pageId}`
- Create Page: `POST /pages`
- Update Page: `PATCH /pages/{pageId}`
- Query Database: `POST /databases/{databaseId}/query`

**Headers:**
- `Authorization: Bearer {access_token}`
- `Notion-Version: 2022-06-28` (required API version header)

---

## Firestore Storage

### Google Calendar Storage Structure

```json
{
  "users": {
    "{userId}": {
      "googleOAuth": {
        "accessToken": "ya29.a0AfH6SMC...",
        "refreshToken": "1//0gV...",
        "tokenType": "Bearer",
        "scope": "https://www.googleapis.com/auth/calendar",
        "expiresAt": "2024-01-01T12:00:00Z",
        "updatedAt": "2024-01-01T11:00:00Z"
      },
      "integrationKeys": {
        "google_calendar": "ya29.a0AfH6SMC..."
      }
    }
  }
}
```

### Notion Storage Structure

```json
{
  "users": {
    "{userId}": {
      "notionOAuth": {
        "accessToken": "secret_abc123...",
        "tokenType": "Bearer",
        "updatedAt": "2024-01-01T11:00:00Z"
        // Note: No expiresAt for internal tokens
      },
      "integrationKeys": {
        "notion": "secret_abc123..."
      }
    }
  }
}
```

**Key Points:**
- Both store tokens in `{service}OAuth` object
- Both also store in `integrationKeys.{service}` for agent access
- Google stores refresh token (Notion doesn't need it for internal tokens)
- Google stores expiry date (Notion internal tokens don't expire)

---

## Step-by-Step Flow Diagrams

### Google Calendar Complete Flow

```
User clicks "Connect Google Calendar"
         │
         ▼
┌────────────────────────┐
│ GoogleOAuthManager     │
│ .authenticate()        │
└──────────┬─────────────┘
           │
           ▼
┌────────────────────────┐
│ Build auth URL         │
│ - client_id            │
│ - redirect_uri         │
│ - scope: calendar      │
│ - access_type: offline │
└──────────┬─────────────┘
           │
           ▼
┌────────────────────────┐
│ Open Safari            │
│ ASWebAuthentication    │
│ Session                │
└──────────┬─────────────┘
           │
           ▼
┌────────────────────────┐
│ User grants permission │
│ Google redirects with  │
│ authorization code     │
└──────────┬─────────────┘
           │
           ▼
┌────────────────────────┐
│ Extract code from      │
│ callback URL           │
└──────────┬─────────────┘
           │
           ▼
┌────────────────────────┐
│ Exchange code for      │
│ tokens (CLIENT-SIDE)   │
│ POST oauth2.googleapis │
│ .com/token             │
└──────────┬─────────────┘
           │
           ▼
┌────────────────────────┐
│ Receive tokens:        │
│ - access_token         │
│ - refresh_token        │
│ - expires_in: 3600     │
└──────────┬─────────────┘
           │
           ▼
┌────────────────────────┐
│ Save to Firestore:     │
│ - googleOAuth          │
│ - integrationKeys      │
└──────────┬─────────────┘
           │
           ▼
┌────────────────────────┐
│ Ready to use!          │
│ GoogleCalendarService  │
│ can make API calls     │
└────────────────────────┘
```

### Notion OAuth 2.0 Flow

```
User clicks "Connect Notion"
         │
         ▼
┌────────────────────────┐
│ NotionOAuthManager     │
│ .authenticate()        │
└──────────┬─────────────┘
           │
           ▼
┌────────────────────────┐
│ Build auth URL         │
│ - client_id            │
│ - redirect_uri         │
│ - owner: user          │
└──────────┬─────────────┘
           │
           ▼
┌────────────────────────┐
│ Open Safari            │
│ ASWebAuthentication    │
│ Session                │
└──────────┬─────────────┘
           │
           ▼
┌────────────────────────┐
│ User grants permission │
│ Notion redirects with │
│ authorization code     │
└──────────┬─────────────┘
           │
           ▼
┌────────────────────────┐
│ Extract code from      │
│ callback URL           │
└──────────┬─────────────┘
           │
           ▼
┌────────────────────────┐
│ ⚠️ PROBLEM:             │
│ Need client_secret!    │
│ Cannot do client-side  │
└──────────┬─────────────┘
           │
           ▼
┌────────────────────────┐
│ Call BACKEND endpoint  │
│ POST /notion/oauth/    │
│ token                  │
│ (Backend has secret)   │
└──────────┬─────────────┘
           │
           ▼
┌────────────────────────┐
│ Backend exchanges code │
│ with Notion API        │
│ Returns access_token   │
└──────────┬─────────────┘
           │
           ▼
┌────────────────────────┐
│ Save to Firestore:     │
│ - notionOAuth          │
│ - integrationKeys      │
└──────────┬─────────────┘
           │
           ▼
┌────────────────────────┐
│ Ready to use!          │
│ NotionService can make │
│ API calls              │
└────────────────────────┘
```

### Notion Internal Token Flow (Simpler)

```
User gets token from Notion dashboard
         │
         ▼
┌────────────────────────┐
│ User enters token in  │
│ app UI                 │
└──────────┬─────────────┘
           │
           ▼
┌────────────────────────┐
│ NotionOAuthManager     │
│ .setInternalIntegration│
│ Token("secret_...")    │
└──────────┬─────────────┘
           │
           ▼
┌────────────────────────┐
│ Validate format        │
│ (must start with       │
│ "secret_")             │
└──────────┬─────────────┘
           │
           ▼
┌────────────────────────┐
│ Save to Firestore:     │
│ - notionOAuth          │
│ - integrationKeys      │
└──────────┬─────────────┘
           │
           ▼
┌────────────────────────┐
│ Ready to use!          │
│ No OAuth flow needed!  │
│ Token never expires    │
└────────────────────────┘
```

---

## Key Differences Summary

| Aspect | Google Calendar | Notion OAuth 2.0 | Notion Internal Token |
|--------|----------------|------------------|----------------------|
| **Setup Complexity** | Medium | High (needs backend) | Low |
| **OAuth Flow** | ✅ Full OAuth 2.0 | ✅ Full OAuth 2.0 | ❌ No OAuth |
| **Client-Side Token Exchange** | ✅ Yes (public client) | ❌ No (needs secret) | N/A |
| **Backend Required** | ❌ No | ✅ Yes | ❌ No |
| **Token Expiry** | ✅ Yes (1 hour) | ✅ Yes (1 hour) | ❌ Never expires |
| **Refresh Token** | ✅ Yes | ❌ No | N/A |
| **Auto-Refresh** | ✅ Yes | ❌ No | N/A |
| **User Experience** | Seamless | Requires re-auth | Seamless |
| **Token Format** | `ya29...` | `secret_...` | `secret_...` |
| **Storage Location** | Firestore | Firestore | Firestore |
| **Integration Key** | `google_calendar` | `notion` | `notion` |
| **API Version Header** | ❌ No | ✅ Yes (`Notion-Version`) | ✅ Yes |
| **Scopes** | Calendar-specific | Read/Update/Insert | Read/Update/Insert |
| **Best For** | Production apps | Public integrations | Personal/internal use |

---

## Recommendations

### Use Google Calendar OAuth When:
- ✅ You want a seamless user experience
- ✅ You need automatic token refresh
- ✅ You're building a production app
- ✅ You want users to authenticate once

### Use Notion OAuth 2.0 When:
- ✅ You're building a public integration
- ✅ You have a backend server
- ✅ You need workspace-level access
- ✅ You want proper OAuth security

### Use Notion Internal Token When:
- ✅ You want the simplest setup
- ✅ You don't have a backend server
- ✅ It's for personal/internal use
- ✅ You want tokens that never expire
- ✅ You're okay with manual token entry

---

## Code Examples

### Google Calendar Usage

```swift
// Connect
GoogleOAuthManager.shared.authenticate { result in
    switch result {
    case .success:
        print("✅ Connected!")
    case .failure(let error):
        print("❌ Error: \(error)")
    }
}

// Use
GoogleCalendarService.shared.fetchUpcomingEvents(maxResults: 10) { result in
    switch result {
    case .success(let events):
        print("Events: \(events)")
    case .failure(let error):
        print("Error: \(error)")
    }
}
```

### Notion Usage (Internal Token)

```swift
// Connect
NotionOAuthManager.shared.setInternalIntegrationToken("secret_abc123...") { result in
    switch result {
    case .success:
        print("✅ Connected!")
    case .failure(let error):
        print("❌ Error: \(error)")
    }
}

// Use
NotionService.shared.retrievePage(pageId: "abc-123") { result in
    switch result {
    case .success(let page):
        print("Page: \(page)")
    case .failure(let error):
        print("Error: \(error)")
    }
}
```

---

## Conclusion

Both integrations follow similar patterns but have key differences:

1. **Google Calendar** uses a complete OAuth 2.0 flow that can be done client-side
2. **Notion OAuth 2.0** requires a backend server for token exchange
3. **Notion Internal Token** is the simplest option with no OAuth flow

The architecture is consistent across both, making it easy to add more integrations following the same pattern.

