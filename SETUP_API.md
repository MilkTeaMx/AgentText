# AgentText API Integration Setup Guide

This guide explains how to set up the embedded iMessage API server and Python integration in your AgentText Mac app.

## Prerequisites

### 1. Install Bun (Recommended) or Node.js

**Option A: Bun (Faster and easier)**
```bash
curl -fsSL https://bun.sh/install | bash
```

**Option B: Node.js** (if you don't want to use Bun)
```bash
brew install node
```

### 2. Install API Server Dependencies

Navigate to the API server directory and install dependencies:

```bash
cd AgentText/APIServer
bun install
# or if using Node.js:
npm install
```

### 3. Install Python Dependencies

```bash
# Install the AgentText Python package
pip3 install agenttext

# Or install all requirements
pip3 install -r AgentText/Scripts/requirements.txt
```

### 4. Grant Full Disk Access

The API server needs Full Disk Access to read iMessage database:

1. Open **System Settings → Privacy & Security → Full Disk Access**
2. Click the **"+"** button
3. Add your IDE (Xcode, Cursor, VS Code) or Terminal

## Testing the Integration

### 1. Test the API Server Manually

From the project root:

```bash
cd AgentText/APIServer
bun run api-server.ts
# or
node api-server.ts
```

You should see:
```
🚀 iMessage API Server running on http://localhost:3000
📚 API Info: http://localhost:3000/info
❤️  Health Check: http://localhost:3000/health
```

Test it:
```bash
curl http://localhost:3000/health
```

### 2. Test Python Scripts Manually

```bash
# Send a test message
python3 AgentText/Scripts/send_message.py "+1234567890" "Hello from AgentText!"

# Get messages
python3 AgentText/Scripts/get_messages.py 10
```

### 3. Run from Mac App

Once everything is configured, your Mac app will:

1. **Automatically start the API server** using `APIServerManager`
2. **Call Python scripts** or **make direct HTTP requests** using `AgentTextService`

## Usage in Swift

### Start the API Server

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
                    do {
                        try await apiServerManager.startServer()
                    } catch {
                        print("Failed to start API server: \(error)")
                    }
                }
        }
    }
}
```

### Send a Message (Direct HTTP API)

```swift
let service = AgentTextService.shared

do {
    let result = try await service.sendMessageDirect(
        to: "+1234567890",
        text: "Hello from Swift!"
    )
    print("Message sent: \(result.message ?? "")")
} catch {
    print("Error: \(error)")
}
```

### Send a Message (via Python Script)

```swift
let service = AgentTextService.shared

do {
    let result = try await service.sendMessage(
        to: "+1234567890",
        text: "Hello via Python!"
    )
    if result.success {
        print("Success!")
    }
} catch {
    print("Error: \(error)")
}
```

### Get Unread Messages

```swift
let service = AgentTextService.shared

do {
    let unreadMessages = try await service.getUnreadMessagesDirect()
    print("Unread: \(unreadMessages)")
} catch {
    print("Error: \(error)")
}
```

## Architecture

```
AgentText Mac App
├── APIServerManager (Swift)
│   ├── Manages Node.js/Bun process
│   └── Starts/stops API server on localhost:3000
│
├── AgentTextService (Swift)
│   ├── Direct HTTP API calls (recommended)
│   └── Python script execution (alternative)
│
├── APIServer/ (TypeScript)
│   ├── api-server.ts (Express REST API)
│   ├── src/ (iMessage SDK)
│   └── package.json
│
└── Scripts/ (Python)
    ├── send_message.py
    ├── get_messages.py
    └── watch_messages.py
```

## API Endpoints

Once the server is running on `http://localhost:3000`:

### Messages
- `GET /messages` - Query messages
- `GET /messages/unread` - Get unread messages

### Send
- `POST /send` - Send a message
- `POST /send/batch` - Send multiple messages
- `POST /send/file` - Send a file
- `POST /send/files` - Send multiple files

### Chats
- `GET /chats` - List chats

### Watcher
- `POST /watcher/start` - Start message watcher
- `POST /watcher/stop` - Stop message watcher
- `GET /watcher/stream` - Stream messages via SSE

### Utility
- `GET /health` - Health check
- `GET /info` - API documentation

## Xcode Configuration

### Add Files to Xcode Project

1. Open your Xcode project
2. Add the following folders/files:
   - `AgentText/Services/APIServerManager.swift`
   - `AgentText/Services/AgentTextService.swift`
   - `AgentText/APIServer/` (entire folder)
   - `AgentText/Scripts/` (entire folder)

3. For **APIServer** and **Scripts** folders:
   - Select files in Xcode
   - In File Inspector → Target Membership
   - Check your app target
   - Select "Create folder references" (not "Create groups")

### Bundle Resources

The API server files and Python scripts will be bundled with your app and copied to:
```
AgentText.app/Contents/Resources/APIServer/
AgentText.app/Contents/Resources/Scripts/
```

## Troubleshooting

### API Server Won't Start

1. Check if Node.js or Bun is installed:
   ```bash
   which bun
   which node
   ```

2. Check console logs in `APIServerManager.serverOutput`

3. Make sure port 3000 is not already in use:
   ```bash
   lsof -i :3000
   ```

### Python Scripts Fail

1. Check Python installation:
   ```bash
   which python3
   python3 --version
   ```

2. Verify agenttext package is installed:
   ```bash
   pip3 list | grep agenttext
   ```

3. Install if missing:
   ```bash
   pip3 install agenttext
   ```

### Permission Errors

Make sure to grant Full Disk Access to your IDE/Terminal:
- System Settings → Privacy & Security → Full Disk Access
- Add Xcode, Terminal, or your preferred IDE

## Next Steps

1. **Install dependencies** (Bun/Node.js + Python packages)
2. **Add files to Xcode** project
3. **Update your App initialization** to start the API server
4. **Build and test** the integration

For more information on the API, see:
- [API README](AgentText/APIServer/API-README.md)
- [AgentText Python Package](https://github.com/MilkTeaMx/agenttext_package)
