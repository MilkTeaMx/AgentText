# Python Scripts for AgentText Integration

This directory contains Python scripts that use the [agenttext Python package](https://github.com/MilkTeaMx/agenttext_package) to interact with iMessage via the AgentText API.

## Prerequisites

1. **API Server Running**: The AgentText API server must be running on `http://localhost:3000`
2. **AgentText Package**: Install the agenttext Python package (see [INSTALL_AGENTTEXT_PACKAGE.md](../../../INSTALL_AGENTTEXT_PACKAGE.md))

## Available Scripts

### 📤 Sending Messages

#### `send_message.py`
Send text messages to a recipient.

```bash
# Basic usage
python3 send_message.py "+1234567890" "Hello from AgentText!"

# With file attachments
python3 send_message.py "+1234567890" "Check these files" --files "/path/to/file1.pdf,/path/to/file2.jpg"
```

**Arguments:**
- `recipient` - Phone number (e.g., `+1234567890`) or email
- `message` - Message text
- `--files` - Comma-separated list of file paths (optional)
- `--base-url` - API server URL (default: `http://localhost:3000`)

#### `send_file.py`
Send a single file to a recipient.

```bash
# Send file with message
python3 send_file.py "+1234567890" "/path/to/document.pdf" --text "Here's the document"

# Send file without message
python3 send_file.py "+1234567890" "/path/to/image.jpg"
```

**Arguments:**
- `recipient` - Phone number or email
- `file_path` - Path to file
- `--text` - Optional message text
- `--base-url` - API server URL

#### `batch_send.py`
Send multiple messages from a JSON file.

```bash
python3 batch_send.py messages.json
```

**JSON Format:**
```json
[
  {"to": "+1234567890", "content": "Hello!"},
  {"to": "user@example.com", "content": "Hi there!"},
  {"to": "+0987654321", "content": "Test message"}
]
```

### 📥 Receiving Messages

#### `get_messages.py`
List messages with filters.

```bash
# Get last 10 messages
python3 get_messages.py

# Get last 50 messages
python3 get_messages.py --limit 50

# Get messages from specific sender
python3 get_messages.py --sender "+1234567890"

# Get only unread messages
python3 get_messages.py --unread-only

# Combine filters
python3 get_messages.py --limit 20 --sender "+1234567890" --unread-only
```

**Arguments:**
- `--limit` - Maximum number of messages (default: 10)
- `--sender` - Filter by sender phone/email
- `--unread-only` - Only return unread messages
- `--base-url` - API server URL

#### `get_unread.py`
Get unread messages grouped by sender.

```bash
python3 get_unread.py
```

**Output:**
```json
{
  "success": true,
  "unread": {
    "total": 15,
    "senderCount": 3,
    "groups": [...]
  }
}
```

### 💬 Managing Chats

#### `list_chats.py`
List all chats with filters.

```bash
# List all chats
python3 list_chats.py

# List group chats only
python3 list_chats.py --type group

# List direct messages only
python3 list_chats.py --type direct

# Limit results
python3 list_chats.py --limit 10
```

**Arguments:**
- `--limit` - Maximum number of chats (default: 20)
- `--type` - Filter by type: `group` or `direct`
- `--base-url` - API server URL

### 👁️ Watching Messages

#### `watcher.py`
Start, stop, or check status of the message watcher.

```bash
# Start watcher
python3 watcher.py start

# Start watcher with webhook
python3 watcher.py start --webhook-url "https://your-server.com/webhook"

# Stop watcher
python3 watcher.py stop

# Check watcher status
python3 watcher.py status
```

**Arguments:**
- `action` - Action to perform: `start`, `stop`, or `status`
- `--webhook-url` - Webhook URL for notifications (optional, only for `start`)
- `--base-url` - API server URL

## Usage from Swift

These scripts are called by the `AgentTextService` Swift class. Example:

```swift
let service = AgentTextService.shared

// Send a message
let result = try await service.sendMessage(to: "+1234567890", text: "Hello!")

// Get unread messages
let unread = try await service.getUnreadMessages()

// List chats
let chats = try await service.listChats(limit: 20)

// Start watcher
let watcherStatus = try await service.startWatcher()
```

## Error Handling

All scripts return JSON output with a `success` field:

**Success:**
```json
{
  "success": true,
  "message": "...",
  "data": {...}
}
```

**Error:**
```json
{
  "success": false,
  "error": "Error message here"
}
```

### Common Errors

1. **Package not installed:**
   ```json
   {
     "success": false,
     "error": "AgentText package not installed. Run: pip3 install -e /path/to/agenttext_package"
   }
   ```
   **Solution:** Install the agenttext package (see [INSTALL_AGENTTEXT_PACKAGE.md](../../../INSTALL_AGENTTEXT_PACKAGE.md))

2. **Connection error:**
   ```json
   {
     "success": false,
     "error": "Connection error: ... Make sure the API server is running on http://localhost:3000"
   }
   ```
   **Solution:** Start the API server first

3. **API error:**
   ```json
   {
     "success": false,
     "error": "API error: ..."
   }
   ```
   **Solution:** Check the error message for specific details

## Testing Scripts Manually

You can test scripts manually from the command line:

```bash
# Navigate to your project
cd /Users/nirav/development/AgentText

# Make sure API server is running
cd AgentText/APIServer
node api-server.ts &
cd ../..

# Test sending a message
python3 AgentText/Scripts/send_message.py "+1234567890" "Test message"

# Test getting messages
python3 AgentText/Scripts/get_messages.py --limit 5

# Test listing chats
python3 AgentText/Scripts/list_chats.py
```

## Script Locations

When bundled with your Mac app, scripts are located at:
```
AgentText.app/Contents/Resources/Scripts/
├── send_message.py
├── send_file.py
├── batch_send.py
├── get_messages.py
├── get_unread.py
├── list_chats.py
├── watcher.py
└── requirements.txt
```

## Development

### Making Scripts Executable

```bash
chmod +x AgentText/Scripts/*.py
```

### Testing Changes

After modifying scripts:

1. Test manually from command line
2. Verify JSON output format
3. Test error handling
4. Test from Swift via `AgentTextService`

## See Also

- [AgentText Python Package](https://github.com/MilkTeaMx/agenttext_package)
- [AgentText API](https://github.com/niravjaiswal/agenttext_api)
- [Swift Integration](../Services/AgentTextService.swift)
- [Installation Guide](../../../INSTALL_AGENTTEXT_PACKAGE.md)
