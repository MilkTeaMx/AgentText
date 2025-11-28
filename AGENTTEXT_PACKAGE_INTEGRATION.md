# AgentText Python Package Integration - Complete Guide

This document explains how the [agenttext Python package](https://github.com/MilkTeaMx/agenttext_package) is integrated into your AgentText Mac app.

## Overview

The integration provides two ways to interact with iMessage:

1. **Python Scripts** (using agenttext package) - Full-featured, recommended
2. **Direct HTTP API** (using Swift URLSession) - Simpler, but limited features

## Architecture

```
┌────────────────────────────────────────┐
│   AgentText Mac App (SwiftUI)         │
│                                        │
│   ┌────────────────────────────────┐  │
│   │  AgentTextService.swift        │  │
│   │  - sendMessage()               │  │
│   │  - sendFile()                  │  │
│   │  - listMessages()              │  │
│   │  - listChats()                 │  │
│   │  - startWatcher()              │  │
│   └─────────┬──────────────────────┘  │
│             │ Executes Python Scripts │
│             ▼                          │
│   ┌────────────────────────────────┐  │
│   │  Python Scripts (.py files)    │  │
│   │  - send_message.py             │  │
│   │  - get_messages.py             │  │
│   │  - list_chats.py               │  │
│   │  - watcher.py                  │  │
│   └─────────┬──────────────────────┘  │
│             │ Uses agenttext package  │
└─────────────┼──────────────────────────┘
              │
              ▼
    ┌─────────────────────────┐
    │  agenttext Package      │
    │  (Python library)       │
    │  - AgentText client     │
    │  - messages API         │
    │  - chats API            │
    │  - watcher API          │
    └─────────┬───────────────┘
              │ HTTP Requests
              ▼
    ┌─────────────────────────┐
    │  API Server (Node.js)   │
    │  localhost:3000         │
    └─────────┬───────────────┘
              │ SQLite + AppleScript
              ▼
    ┌─────────────────────────┐
    │  macOS iMessage DB      │
    │  ~/Library/Messages/    │
    └─────────────────────────┘
```

## Components

### 1. Swift Service Layer

**File:** [AgentText/Services/AgentTextService.swift](AgentText/Services/AgentTextService.swift)

This is the main Swift interface for interacting with iMessage. It provides:

#### Messages API
```swift
// Send text message
func sendMessage(to: String, text: String) async throws -> MessageResult

// Send message with file attachments
func sendMessageWithFiles(to: String, text: String, files: [String]) async throws -> MessageResult

// Send single file
func sendFile(to: String, filePath: String, text: String?) async throws -> MessageResult

// Send batch messages
func sendBatch(jsonFilePath: String) async throws -> MessageResult

// List messages with filters
func listMessages(limit: Int, sender: String?, unreadOnly: Bool) async throws -> MessagesListResult

// Get unread messages
func getUnreadMessages() async throws -> UnreadResult
```

#### Chats API
```swift
// List chats
func listChats(limit: Int, type: String?) async throws -> ChatsListResult
```

#### Watcher API
```swift
// Start watching for new messages
func startWatcher(webhookURL: String?) async throws -> WatcherResult

// Stop watcher
func stopWatcher() async throws -> WatcherResult

// Get watcher status
func getWatcherStatus() async throws -> WatcherResult
```

#### Server Health
```swift
// Check if API server is running
func checkServerStatus() async -> Bool
```

### 2. Python Scripts

**Directory:** [AgentText/Scripts/](AgentText/Scripts/)

Each script uses the agenttext Python package to perform specific operations:

| Script | Purpose | AgentText API Used |
|--------|---------|-------------------|
| `send_message.py` | Send text messages (with optional files) | `client.messages.send()`, `client.messages.send_files()` |
| `send_file.py` | Send a single file | `client.messages.send_file()` |
| `batch_send.py` | Send multiple messages | `client.messages.send_batch()` |
| `get_messages.py` | List messages with filters | `client.messages.list()` |
| `get_unread.py` | Get unread messages | `client.messages.get_unread()` |
| `list_chats.py` | List chats | `client.chats.list()` |
| `watcher.py` | Manage message watcher | `client.watcher.start()`, `client.watcher.stop()`, `client.watcher.status()` |

All scripts:
- Accept command-line arguments
- Return JSON output
- Handle errors gracefully
- Support custom base URL

See [Scripts README](AgentText/Scripts/README.md) for detailed documentation.

### 3. Data Models

**Defined in:** [AgentText/Services/AgentTextService.swift](AgentText/Services/AgentTextService.swift)

```swift
// Message result from send operations
struct MessageResult: Codable {
    let success: Bool
    let message: String?
    let error: String?
    let result: AnyCodable?
}

// Messages list result
struct MessagesListResult: Codable {
    let success: Bool
    let messages: [Message]?
    let count: Int?
    let error: String?
}

// Unread messages result
struct UnreadResult: Codable {
    let success: Bool
    let unread: UnreadMessages?
    let error: String?
}

// Chats list result
struct ChatsListResult: Codable {
    let success: Bool
    let chats: [Chat]?
    let count: Int?
    let error: String?
}

// Watcher result
struct WatcherResult: Codable {
    let success: Bool
    let action: String?
    let message: String?
    let status: WatcherStatus?
    let error: String?
}

// Individual message
struct Message: Codable {
    let id: String?
    let text: String?
    let sender: String?
    let chatId: String?
    let date: String?
    let isFromMe: Bool?
    let isRead: Bool?
}

// Chat information
struct Chat: Codable {
    let chatId: String?
    let displayName: String?
    let isGroup: Bool?
    let lastMessageAt: String?
}
```

## Installation

### Step 1: Install the agenttext Python Package

See [INSTALL_AGENTTEXT_PACKAGE.md](INSTALL_AGENTTEXT_PACKAGE.md) for detailed instructions.

**Quick Install:**
```bash
# Clone the package
git clone https://github.com/MilkTeaMx/agenttext_package.git ~/agenttext_package

# Install in editable mode
pip3 install -e ~/agenttext_package

# Verify
python3 -c "from agenttext import AgentText; print('✅ Installed!')"
```

### Step 2: Start the API Server

The API server must be running for the Python scripts to work:

```bash
cd AgentText/APIServer
node api-server.ts
# or
bun run api-server.ts
```

The server runs on `http://localhost:3000`.

### Step 3: Test Python Scripts

```bash
# Send a test message
python3 AgentText/Scripts/send_message.py "+1234567890" "Test"

# Get messages
python3 AgentText/Scripts/get_messages.py --limit 5

# List chats
python3 AgentText/Scripts/list_chats.py
```

### Step 4: Use from Swift

```swift
let service = AgentTextService.shared

// Send a message
do {
    let result = try await service.sendMessage(
        to: "+1234567890",
        text: "Hello from Swift!"
    )
    if result.success {
        print("✅ Message sent!")
    }
} catch {
    print("Error: \(error)")
}
```

## Usage Examples

### Example 1: Send a Simple Message

**Swift:**
```swift
let service = AgentTextService.shared

let result = try await service.sendMessage(
    to: "+1234567890",
    text: "Hello from AgentText!"
)

if result.success {
    print("Message sent!")
} else {
    print("Error: \(result.error ?? "Unknown")")
}
```

**What happens:**
1. Swift calls `executePythonScript("send_message", ["+1234567890", "Hello from AgentText!"])`
2. `send_message.py` is executed with those arguments
3. Python script imports `from agenttext import AgentText`
4. Python calls `client.messages.send(to="+1234567890", content="Hello from AgentText!")`
5. agenttext package makes HTTP POST to `http://localhost:3000/send`
6. API server sends the iMessage
7. Python script returns JSON: `{"success": true, "message": "Message sent to +1234567890"}`
8. Swift parses JSON into `MessageResult` and returns to caller

### Example 2: Send a File

**Swift:**
```swift
let result = try await service.sendFile(
    to: "+1234567890",
    filePath: "/path/to/document.pdf",
    text: "Here's the document"
)
```

**Flow:**
```
Swift → send_file.py → agenttext.messages.send_file() → API Server → iMessage
```

### Example 3: Get Unread Messages

**Swift:**
```swift
let result = try await service.getUnreadMessages()

if result.success, let unread = result.unread {
    print("You have \(unread.total ?? 0) unread messages")
    print("From \(unread.senderCount ?? 0) senders")
}
```

**Flow:**
```
Swift → get_unread.py → agenttext.messages.get_unread() → API Server → iMessage DB
```

### Example 4: List Group Chats

**Swift:**
```swift
let result = try await service.listChats(limit: 20, type: "group")

if result.success, let chats = result.chats {
    for chat in chats {
        print("\(chat.displayName ?? "Unknown"): \(chat.chatId ?? "")")
    }
}
```

### Example 5: Watch for New Messages

**Swift:**
```swift
// Start watcher
let startResult = try await service.startWatcher()
print("Watcher started: \(startResult.success)")

// Check status
let statusResult = try await service.getWatcherStatus()
if let status = statusResult.status {
    print("Active: \(status.active ?? false)")
}

// Stop watcher
let stopResult = try await service.stopWatcher()
print("Watcher stopped: \(stopResult.success)")
```

## Error Handling

All methods can throw `AgentTextError`:

```swift
do {
    let result = try await service.sendMessage(to: "+1234567890", text: "Hi")

    if !result.success {
        // Check result.error for details
        print("Failed: \(result.error ?? "Unknown error")")
    }

} catch AgentTextError.pythonNotFound {
    print("Python not installed")
} catch AgentTextError.scriptNotFound {
    print("Script file not found in bundle")
} catch AgentTextError.packageNotInstalled {
    print("agenttext package not installed")
} catch AgentTextError.executionFailed(let message) {
    print("Execution failed: \(message)")
} catch {
    print("Unknown error: \(error)")
}
```

## Debugging

### Check if Python is available

```bash
which python3
# Should output: /usr/bin/python3
```

### Check if agenttext package is installed

```bash
pip3 list | grep agenttext
# Should show: agenttext (version)
```

### Check if API server is running

```bash
curl http://localhost:3000/health
# Should return: {"status":"ok","timestamp":"..."}
```

### Test Python script manually

```bash
python3 AgentText/Scripts/send_message.py "+1234567890" "Test"
```

### View Python script output in Swift

The Swift service captures stdout and stderr from Python scripts. Check the output for debugging:

```swift
let output = try await service.executePythonScript(
    scriptName: "send_message",
    arguments: ["+1234567890", "Test"]
)
print("Raw output: \(output)")
```

## Performance Considerations

### Script Execution Time

Each Python script invocation has overhead:
- Process spawn: ~50-100ms
- Python import: ~100-200ms
- Package initialization: ~50-100ms
- Total: ~200-400ms per call

For better performance on repeated calls, consider:
1. Using Direct HTTP API (bypasses Python)
2. Batching multiple messages
3. Keeping watcher running instead of polling

### Direct HTTP API Alternative

For simple operations, you can bypass Python:

```swift
// Using Python (slower but full-featured)
let result = try await service.sendMessage(to: "+1234567890", text: "Hi")

// Using Direct HTTP (faster but limited)
let json = try await service.sendMessageDirect(to: "+1234567890", text: "Hi")
```

## Limitations

1. **Python Required**: User must have Python 3 installed
2. **Package Installation**: User must install agenttext package
3. **API Server**: Must be running on localhost:3000
4. **Permissions**: Requires Full Disk Access for iMessage database
5. **macOS Only**: iMessage is macOS-specific

## Advantages

1. ✅ Full access to agenttext package features
2. ✅ Type-safe Swift interfaces
3. ✅ Proper error handling
4. ✅ Easy to extend with new features
5. ✅ Testable (scripts can be tested independently)
6. ✅ Well-documented API
7. ✅ Matches Python package API exactly

## Files Created

```
AgentText/
├── Services/
│   └── AgentTextService.swift          ✨ Complete Swift wrapper
├── Scripts/
│   ├── send_message.py                 ✨ Send messages
│   ├── send_file.py                    ✨ Send files
│   ├── batch_send.py                   ✨ Batch send
│   ├── get_messages.py                 ✨ List messages
│   ├── get_unread.py                   ✨ Get unread
│   ├── list_chats.py                   ✨ List chats
│   ├── watcher.py                      ✨ Manage watcher
│   ├── requirements.txt                ✨ Dependencies
│   └── README.md                       ✨ Scripts documentation
├── APIServer/                          (TypeScript API server)
├── INSTALL_AGENTTEXT_PACKAGE.md        ✨ Installation guide
├── AGENTTEXT_PACKAGE_INTEGRATION.md    ✨ This file
├── QUICK_START.md                      (Quick start guide)
├── SETUP_API.md                        (Detailed setup)
└── INTEGRATION_SUMMARY.md              (Overview)
```

## Next Steps

1. ✅ Python scripts created
2. ✅ Swift service wrapper complete
3. ✅ Documentation written
4. ☐ Install agenttext package (see [INSTALL_AGENTTEXT_PACKAGE.md](INSTALL_AGENTTEXT_PACKAGE.md))
5. ☐ Add files to Xcode project
6. ☐ Test integration
7. ☐ Build your features!

## Support

- **agenttext package**: https://github.com/MilkTeaMx/agenttext_package
- **API server**: https://github.com/niravjaiswal/agenttext_api
- **Python scripts**: [AgentText/Scripts/README.md](AgentText/Scripts/README.md)

---

**Ready to use the agenttext Python package in your Mac app!** 🎉
