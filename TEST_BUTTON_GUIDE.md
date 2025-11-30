# Test Button Guide

## What Was Added

I've added a **"Test AgentText"** button to your Marketplace view that runs a simple Python script using your agenttext package.

## Location

The button appears in the **Marketplace** screen (shown after login) in the top-right header, next to the refresh button.

## What It Does

When you click the "Test AgentText" button:

1. **Runs Python Script**: Executes `AgentText/Scripts/simple_test.py`
2. **Uses agenttext Package**: The script imports and uses your agenttext library
3. **Sends Test Message**: Sends "Hello!" to +9255776728
4. **Shows Result**: Displays success/error in an alert

## The Python Script

**File:** [AgentText/Scripts/simple_test.py](AgentText/Scripts/simple_test.py)

```python
from agenttext import AgentText

# Initialize client (API server must be running on http://localhost:3000)
client = AgentText()

# Send a message
result = client.messages.send(to="+9255776728", content="Hello!")
```

This is exactly the example you provided!

## How It Works

```
User clicks button
    ↓
MarketplaceView.runSimpleTest()
    ↓
AgentTextService.shared.runSimpleTest()
    ↓
Executes: python3 AgentText/Scripts/simple_test.py
    ↓
Python script:
    from agenttext import AgentText
    client = AgentText()
    client.messages.send(to="+9255776728", content="Hello!")
    ↓
Returns JSON result to Swift
    ↓
Shows alert with success/error
```

## Files Modified

1. **[AgentText/Scripts/simple_test.py](AgentText/Scripts/simple_test.py)** - NEW
   - Simple Python script using agenttext package
   - Sends test message to +9255776728

2. **[AgentText/Services/AgentTextService.swift](AgentText/Services/AgentTextService.swift)** - UPDATED
   - Added `runSimpleTest()` method
   - Executes the Python script and returns result

3. **[AgentText/Screens/MarketplaceView.swift](AgentText/Screens/MarketplaceView.swift)** - UPDATED
   - Added "Test AgentText" button in header
   - Shows loading spinner while running
   - Displays result in alert dialog

## Testing the Button

### Prerequisites

1. **API Server Running**
   ```bash
   cd AgentText/APIServer
   node api-server.ts
   ```
   Server must be running on `http://localhost:3000`

2. **agenttext Package Installed**
   ```bash
   pip3 install -e ~/agenttext_package
   ```

3. **Full Disk Access**
   - System Settings → Privacy & Security → Full Disk Access
   - Add Xcode

4. **Files Added to Xcode**
   - Make sure all new files are added to your Xcode project
   - Check target membership

### Steps to Test

1. **Build and Run** your Mac app in Xcode
2. **Log in** to your account
3. You'll see the **Marketplace** screen
4. Look for the **green "Test AgentText"** button in the top-right
5. **Click the button**
6. Wait for the result (should take 1-2 seconds)
7. An alert will appear showing:
   - ✅ Success if message was sent
   - ❌ Error if something went wrong

### Expected Results

**Success:**
```
✅ Success!

Test message sent to +9255776728
```

**Common Errors:**

1. **Package not installed:**
   ```
   ❌ Failed

   AgentText package not installed.
   Run: pip3 install -e /path/to/agenttext_package
   ```
   **Fix:** Install the agenttext package

2. **API server not running:**
   ```
   ❌ Error

   Connection error: ...
   Make sure the API server is running on http://localhost:3000
   ```
   **Fix:** Start the API server

3. **Python not found:**
   ```
   ❌ Error

   Python 3 not found. Please install Python 3.
   ```
   **Fix:** Install Python 3

## Customizing the Test

### Change Recipient Number

Edit [AgentText/Scripts/simple_test.py](AgentText/Scripts/simple_test.py):

```python
# Change this line:
result = client.messages.send(to="+9255776728", content="Hello!")

# To your number:
result = client.messages.send(to="+YOUR_NUMBER", content="Hello!")
```

### Change Message Text

```python
result = client.messages.send(to="+9255776728", content="Your custom message!")
```

### Add More Tests

You can expand the script to test other features:

```python
from agenttext import AgentText

client = AgentText()

# Send a message
result1 = client.messages.send(to="+9255776728", content="Hello!")

# Get unread messages
result2 = client.messages.get_unread()

# List chats
result3 = client.chats.list(limit=5)

print(json.dumps({
    "success": True,
    "message": "All tests passed!",
    "results": {
        "send": result1,
        "unread": result2,
        "chats": result3
    }
}))
```

## UI Screenshot Location

The button appears here:

```
┌─────────────────────────────────────────────────┐
│ Marketplace              [Test AgentText] [↻]  │ ← Header
├─────────────────────────────────────────────────┤
│                                                 │
│  [Agent Cards]                                  │
│                                                 │
└─────────────────────────────────────────────────┘
```

## Button States

1. **Normal**: Green button with paper plane icon
2. **Loading**: Spinner replaces icon, button disabled
3. **Result**: Alert dialog shows success/error

## Next Steps

After verifying the button works:

1. ✅ Test button is working
2. You can build more features using the same pattern
3. Use `AgentTextService` methods for other agenttext features
4. Customize the test script for your use cases

## Troubleshooting

### Button doesn't appear
- Make sure you're logged in
- Check you're on the Marketplace screen
- Rebuild the app

### Button does nothing
- Check Xcode console for errors
- Verify API server is running
- Check Python/package installation

### Alert shows error
- Read the error message carefully
- Follow the fix suggestions above
- Check [AGENTTEXT_PACKAGE_INTEGRATION.md](AGENTTEXT_PACKAGE_INTEGRATION.md) for debugging

---

**Your Mac app can now run Python scripts using the agenttext package!** 🎉
