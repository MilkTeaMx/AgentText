#!/usr/bin/env python3
"""
Simple test script using the agenttext library
This sends a test message to verify the integration is working
"""

import sys
import json

try:
    from agenttext import AgentText
except ImportError:
    print(json.dumps({
        "success": False,
        "error": "AgentText package not installed. Run: pip3 install -e /path/to/agenttext_package"
    }))
    sys.exit(1)

def main():
    try:
        # Initialize client (API server must be running on http://localhost:3000)
        client = AgentText()

        # Send a message
        result = client.messages.send(to="+9255776728", content="Hello!")

        print(json.dumps({
            "success": True,
            "message": "Test message sent successfully!",
            "result": result if isinstance(result, dict) else str(result)
        }))

    except Exception as e:
        print(json.dumps({
            "success": False,
            "error": str(e)
        }))
        sys.exit(1)


if __name__ == "__main__":
    main()
