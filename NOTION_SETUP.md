# Notion Integration Setup Guide

This guide will walk you through setting up Notion integration in your AgentText app, similar to how Google Calendar is set up.

## Overview

The Notion integration provides two authentication methods:

1. **Internal Integration Token** (Recommended - Simpler)
   - No OAuth flow required
   - Get a token from Notion's integration dashboard
   - Works immediately without backend server

2. **OAuth 2.0** (For public integrations)
   - Full OAuth flow similar to Google Calendar
   - Requires a backend server to exchange authorization code
   - More complex but better for public apps

## Quick Start - Internal Integration Token (Recommended)

This is the simplest way to get started with Notion.

### Step 1: Create Notion Integration

1. Go to: https://www.notion.com/my-integrations
2. Click **"+ New integration"**
3. Fill in:
   - **Name**: AgentText (or your preferred name)
   - **Associated workspace**: Select your workspace
   - **Type**: Internal
4. Click **"Submit"**
5. Copy the **Internal Integration Token** (starts with `secret_`)

### Step 2: Configure in App

1. Open `NotionOAuthManager.swift`
2. The code is already set up to use internal integration tokens
3. In your app UI, call:
   ```swift
   NotionOAuthManager.shared.setInternalIntegrationToken("secret_your_token_here") { result in
       switch result {
       case .success:
           print("✅ Notion connected!")
       case .failure(let error):
           print("❌ Error: \(error)")
       }
   }
   ```

### Step 3: Grant Access to Pages

1. In Notion, go to the page/database you want to access
2. Click the **"..."** menu (top right)
3. Select **"Add connections"**
4. Choose your integration
5. The integration can now access that page/database

### Step 4: Use Notion Service

```swift
// Retrieve a page
NotionService.shared.retrievePage(pageId: "your-page-id") { result in
    switch result {
    case .success(let page):
        print("Page: \(page)")
    case .failure(let error):
        print("Error: \(error)")
    }
}

// Query a database
NotionService.shared.queryDatabase(databaseId: "your-database-id") { result in
    switch result {
    case .success(let response):
        print("Results: \(response.results)")
    case .failure(let error):
        print("Error: \(error)")
    }
}
```

## OAuth 2.0 Setup (Advanced)

If you need OAuth 2.0 for a public integration:

### Step 1: Create OAuth Integration

1. Go to: https://developers.notion.com/docs/authorization
2. Follow Notion's OAuth 2.0 setup guide
3. Get your **Client ID** and **Client Secret**
4. Set up a **Redirect URI** (e.g., `com.agenttext.notion:/oauth2redirect`)

### Step 2: Configure in Code

1. Open `NotionOAuthManager.swift`
2. Update the `clientId`:
   ```swift
   private let clientId = "your-notion-client-id"
   ```
3. Update the `redirectUri` to match your registered redirect URI

### Step 3: Set Up Backend Server

**IMPORTANT**: Notion OAuth 2.0 requires a backend server to exchange the authorization code for tokens (because it needs the client secret).

You need to create a backend endpoint that:
1. Receives the authorization code from the client
2. Exchanges it with Notion's token endpoint using your client secret
3. Returns the access token to the client

Example backend endpoint (Node.js):
```javascript
app.post('/notion/oauth/token', async (req, res) => {
  const { code, redirect_uri } = req.body;
  
  const response = await fetch('https://api.notion.com/v1/oauth/token', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Basic ${Buffer.from(`${CLIENT_ID}:${CLIENT_SECRET}`).toString('base64')}`
    },
    body: JSON.stringify({
      grant_type: 'authorization_code',
      code,
      redirect_uri
    })
  });
  
  const tokens = await response.json();
  res.json(tokens);
});
```

Then update `exchangeCodeForTokens` in `NotionOAuthManager.swift` to call your backend.

## How It Works (Similar to Google Calendar)

### Architecture

1. **NotionOAuthManager** (Similar to `GoogleOAuthManager`)
   - Handles authentication flow
   - Stores tokens in Firestore
   - Provides `getValidAccessToken()` method
   - Saves tokens to `notionOAuth` and `integrationKeys.notion` in Firestore

2. **NotionService** (Similar to `GoogleCalendarService`)
   - Uses `NotionOAuthManager` to get access tokens
   - Makes API calls to Notion API
   - Handles pages, databases, queries, etc.

### Token Storage

Tokens are stored in Firestore under the user document:
```json
{
  "notionOAuth": {
    "accessToken": "secret_...",
    "tokenType": "Bearer",
    "updatedAt": "..."
  },
  "integrationKeys": {
    "notion": "secret_..."
  }
}
```

This allows agents to access Notion via `integrationKeys.notion` (same pattern as Google Calendar).

### Usage in Agents

When an agent needs to access Notion, it can use the token from `integrationKeys.notion`:

```swift
// In AgentInvocationService or similar
let notionToken = integrationKeys["notion"]
// Use token to make Notion API calls
```

## Comparison: Google Calendar vs Notion

| Feature | Google Calendar | Notion |
|---------|----------------|--------|
| OAuth Flow | ✅ Full OAuth 2.0 | ✅ OAuth 2.0 (requires backend) |
| Simple Token | ❌ | ✅ Internal Integration Token |
| Token Storage | Firestore | Firestore |
| Auto Refresh | ✅ Yes | ❌ Internal tokens don't expire |
| Integration Keys | `integrationKeys.google_calendar` | `integrationKeys.notion` |

## Next Steps

1. **Add UI for Notion Connection**
   - Add a button in `IntegrationsView.swift` to connect Notion
   - Show connection status
   - Allow users to enter internal integration token

2. **Add Notion to Agent Integrations**
   - Update agent creation UI to include Notion as an integration option
   - Agents can request `notion` in their `integrations` array

3. **Test Integration**
   - Create a test Notion page
   - Grant your integration access
   - Test retrieving/updating pages via the API

## Troubleshooting

### Error: "Invalid Notion token format"
- Make sure your token starts with `secret_`
- Internal integration tokens always start with `secret_`

### Error: "Notion Client ID not configured"
- For OAuth 2.0, update `clientId` in `NotionOAuthManager.swift`
- For internal tokens, use `setInternalIntegrationToken()` instead

### Error: "Backend required"
- OAuth 2.0 requires a backend server
- Use `setInternalIntegrationToken()` for a simpler setup without backend

### API Errors: 401 Unauthorized
- Check that your token is valid
- Make sure you've granted the integration access to the page/database
- Verify the token is saved correctly in Firestore

## Resources

- [Notion API Documentation](https://developers.notion.com/reference)
- [Notion OAuth 2.0 Guide](https://developers.notion.com/docs/authorization)
- [Notion Integrations Dashboard](https://www.notion.com/my-integrations)

