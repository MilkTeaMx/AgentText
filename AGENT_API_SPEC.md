# Agent API Specification

This document describes the API interface that your agent must implement to work with AgentText.

## Overview

When a user mentions your agent in a message (e.g., `@YourAgent 5`), AgentText will make an HTTP POST request to your configured API endpoint with the conversation context and integration credentials.

## Request Format

### HTTP Method
```
POST
```

### Headers
```
Content-Type: application/json
```

### Request Body Structure

```json
{
  "messages": [
    {
      "text": "string",
      "isFromMe": boolean,
      "sender": "string | null",
      "date": "ISO8601 timestamp string"
    }
  ],
  "count": number,
  "integrations": {
    "integration_name": "api_key_string"
  }
}
```

### Field Descriptions

#### `messages` (array, required)
An array of message objects representing the conversation context. Messages are ordered from oldest to newest.

- **`text`** (string, required): The content of the message
- **`isFromMe`** (boolean, required): `true` if the message was sent by the user, `false` if received from another person
- **`sender`** (string | null, required): The name/identifier of the message sender. May be `null` for some messages.
- **`date`** (string, required): ISO8601 formatted timestamp of when the message was sent (e.g., `"2024-01-15T10:30:00Z"`)

#### `count` (number, required)
The number of context messages requested by the user. This matches the number specified in the mention (e.g., `@Agent 5` → `count: 5`).

If the user mentions the agent without a number (e.g., `@Agent`), `count` will be `0` and `messages` will be an empty array.

#### `integrations` (object, optional)
A map of integration names to API keys/credentials. Only present if your agent requested integrations and the user has configured them.

**Example integrations:**
- `google_calendar`: Google Calendar API key
- More integrations coming soon...

If your agent doesn't use integrations or the user hasn't configured them, this field may be `null` or omitted.

**Important:** Users must configure their integration API keys in the AgentText app under **Integrations** settings. If your agent requires an integration but the user hasn't configured it, you should return a helpful error message instructing them to add the API key.

---

## Response Format

### HTTP Status Code
Your API should return:
- `200 OK` for successful responses
- `4xx` or `5xx` for errors (AgentText will not send a message to the user)

### Response Body Structure

```json
{
  "message": "string"
}
```

### Field Descriptions

#### `message` (string, required)
The text response from your agent. This will be sent back to the user in the same conversation where they mentioned your agent.

**Guidelines:**
- Keep responses concise and relevant
- Format text naturally (no special formatting required)
- The message will appear as if sent from you
- Maximum recommended length: ~1000 characters

---

## Example Request/Response Flow

### Example 1: Agent with Context Messages

**User sends:** `@CoffeeChatAgent 3`

**Your API receives:**
```json
{
  "messages": [
    {
      "text": "Hey, want to grab coffee tomorrow?",
      "isFromMe": false,
      "sender": "Alice",
      "date": "2024-01-15T10:00:00Z"
    },
    {
      "text": "Sure! What time works for you?",
      "isFromMe": true,
      "sender": "You",
      "date": "2024-01-15T10:05:00Z"
    },
    {
      "text": "How about 2pm at Starbucks?",
      "isFromMe": false,
      "sender": "Alice",
      "date": "2024-01-15T10:10:00Z"
    }
  ],
  "count": 3,
  "integrations": {
    "google_calendar": "ya29.a0AfH6SMBx..."
  }
}
```

**Your API responds:**
```json
{
  "message": "I've added 'Coffee with Alice' to your calendar for tomorrow at 2pm. The event has been created at Starbucks."
}
```

**User sees:** The message appears in their conversation with Alice.

---

### Example 2: Agent without Context

**User sends:** `@WeatherAgent`

**Your API receives:**
```json
{
  "messages": [],
  "count": 0,
  "integrations": null
}
```

**Your API responds:**
```json
{
  "message": "Current weather in San Francisco: 68°F, Partly Cloudy. High of 72°F today."
}
```

---

### Example 3: Agent with Multiple Integrations

**Your API receives:**
```json
{
  "messages": [
    {
      "text": "Can you check my schedule?",
      "isFromMe": true,
      "sender": "You",
      "date": "2024-01-15T14:30:00Z"
    }
  ],
  "count": 1,
  "integrations": {
    "google_calendar": "ya29.a0AfH6SMBx...",
    "slack": "xoxb-1234567890..."
  }
}
```

**Your API responds:**
```json
{
  "message": "You have 3 meetings today:\n- Team standup at 10am\n- Client call at 2pm\n- 1:1 with Sarah at 4pm"
}
```

---

## Implementation Guide

### Minimum Viable Agent

Here's a simple Node.js/Express example:

```javascript
const express = require('express');
const app = express();

app.use(express.json());

app.post('/agent', (req, res) => {
  const { messages, count, integrations } = req.body;

  // Your agent logic here
  const response = processMessages(messages, integrations);

  res.json({ message: response });
});

function processMessages(messages, integrations) {
  // Example: Echo the last message
  if (messages.length > 0) {
    const lastMessage = messages[messages.length - 1];
    return `I received: "${lastMessage.text}"`;
  }
  return "Hello! I didn't receive any context messages.";
}

app.listen(3000, () => {
  console.log('Agent API running on port 3000');
});
```

### Best Practices

1. **Validate Input**: Always validate the request body structure
2. **Handle Missing Integrations**: Check if required integration keys are present
3. **Error Handling**: Return appropriate HTTP status codes
4. **Timeout Handling**: Respond within 30 seconds (recommended)
5. **Security**: Validate that requests are coming from AgentText (implement API key authentication if needed)
6. **Logging**: Log requests for debugging and analytics

### Security Considerations

- **HTTPS**: Always use HTTPS in production
- **Rate Limiting**: Implement rate limiting to prevent abuse
- **Input Sanitization**: Sanitize all input data
- **Integration Keys**: Handle API keys securely, never log them
- **Error Messages**: Don't expose sensitive information in error responses

---

## Testing Your Agent

### Using cURL

```bash
curl -X POST https://your-api.com/agent \
  -H "Content-Type: application/json" \
  -d '{
    "messages": [
      {
        "text": "Test message",
        "isFromMe": true,
        "sender": "Test User",
        "date": "2024-01-15T10:00:00Z"
      }
    ],
    "count": 1,
    "integrations": null
  }'
```

### Expected Response

```json
{
  "message": "Your agent's response here"
}
```

---

## Common Issues

### Issue 1: Agent Not Responding
- **Check**: Is your API endpoint publicly accessible?
- **Check**: Are you returning a `200` status code?
- **Check**: Is the response body valid JSON with a `message` field?

### Issue 2: Integration Keys Not Working
- **Check**: Did you specify the required integrations when creating your agent?
- **Check**: Has the user configured their integration keys in AgentText?
- **Check**: Are you handling the case where integrations might be `null`?

### Issue 3: Messages Not Showing
- **Check**: Is your response message a non-empty string?
- **Check**: Are you returning the response within a reasonable timeout (< 30s)?

---

## Advanced Features

### Context-Aware Responses

Use the `isFromMe` field to understand conversation flow:

```javascript
function analyzeConversation(messages) {
  const userMessages = messages.filter(m => m.isFromMe);
  const otherMessages = messages.filter(m => !m.isFromMe);

  // Your logic to understand the conversation
}
```

### Using Integration APIs

```javascript
async function createCalendarEvent(integrations, eventDetails) {
  if (!integrations || !integrations.google_calendar) {
    return "Please configure Google Calendar integration first.";
  }

  const apiKey = integrations.google_calendar;
  // Make API call to Google Calendar
  // ...

  return "Event created successfully!";
}
```

### Handling Different Request Counts

```javascript
function handleRequest(messages, count) {
  if (count === 0) {
    // No context - general query
    return "How can I help you?";
  } else if (count < 5) {
    // Limited context - simple task
    return processSimpleTask(messages);
  } else {
    // Full context - complex analysis
    return performDeepAnalysis(messages);
  }
}
```

---

## Changelog

### Version 1.0 (Current)
- Initial specification
- Support for message context
- Integration credentials (Google Calendar)
- Standardized request/response format

---

## Support

For questions or issues:
1. Check the [Common Issues](#common-issues) section
2. Review your agent's configuration in AgentText Developer Console
3. Test your API endpoint independently with cURL
4. Check server logs for errors

---

## Future Enhancements

Planned features for future versions:
- Additional integration options (Slack, Gmail, etc.)
- Webhook support for proactive agent messages
- Rich message formatting (markdown, images)
- Streaming responses for long-running tasks
- Agent-to-agent communication
