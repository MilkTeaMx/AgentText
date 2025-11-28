# Quick Start Guide

## 5-Minute Setup

### Step 1: Install Dependencies (2 minutes)

```bash
# Install Python package
pip3 install agenttext

# API server dependencies are already installed ✓
```

### Step 2: Grant Permissions (1 minute)

1. Open **System Settings**
2. Go to **Privacy & Security** → **Full Disk Access**
3. Click **"+"** and add **Xcode**

### Step 3: Add Files to Xcode (2 minutes)

1. Open `AgentText.xcodeproj`
2. In Project Navigator, right-click `AgentText` → **Add Files to "AgentText"**
3. Add these files (they're already in your filesystem):
   - `Services/APIServerManager.swift`
   - `Services/AgentTextService.swift`
   - `Screens/APITestView.swift`
   - `APIServer/` folder (choose "Create folder references")
   - `Scripts/` folder (choose "Create folder references")

4. Verify Target Membership:
   - Select each new file
   - Check "AgentText" in File Inspector → Target Membership

### Step 4: Update App Initialization (30 seconds)

Update `AgentText/AgentTextApp.swift`:

```swift
import SwiftUI

@main
struct AgentTextApp: App {
    @StateObject private var apiServerManager = APIServerManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(apiServerManager)
                .task {
                    try? await apiServerManager.startServer()
                }
        }
    }
}
```

### Step 5: Test It! (30 seconds)

Add a test button to any view:

```swift
NavigationLink("Test iMessage API") {
    APITestView()
}
```

Or temporarily set `APITestView` as your root view to test:

```swift
WindowGroup {
    APITestView()
        .environmentObject(apiServerManager)
}
```

## Usage Examples

### Send a Message

```swift
let service = AgentTextService.shared

try await service.sendMessageDirect(
    to: "+1234567890",
    text: "Hello from AgentText!"
)
```

### Get Unread Messages

```swift
let unread = try await service.getUnreadMessagesDirect()
print("Unread count: \(unread["total"])")
```

### Check Server Status

```swift
@EnvironmentObject var apiServerManager: APIServerManager

if apiServerManager.isRunning {
    Text("✅ Connected")
} else {
    Text("❌ Disconnected")
}
```

## Troubleshooting

### Server Won't Start?
- Check if Node.js is installed: `which node` (should show `/usr/local/bin/node`)
- Check server logs in `APITestView` → "Show Logs"

### Python Errors?
- Verify: `pip3 list | grep agenttext`
- Install if missing: `pip3 install agenttext`

### Permission Errors?
- Make sure Xcode has Full Disk Access
- Restart Xcode after granting permissions

## That's It!

You're ready to send iMessages from your Mac app. 🎉

For more details, see:
- [INTEGRATION_SUMMARY.md](INTEGRATION_SUMMARY.md) - Complete overview
- [SETUP_API.md](SETUP_API.md) - Detailed setup instructions
