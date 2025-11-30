#!/usr/bin/env python3
"""
Watch for new messages using the AgentText Python package
This is a long-running script that monitors for new messages
"""

import sys
import json
import time

try:
    from agenttext import AgentText
except ImportError:
    print(json.dumps({
        "success": False,
        "error": "AgentText package not installed. Run: pip3 install agenttext"
    }))
    sys.exit(1)


def on_message(message):
    """Callback for new messages"""
    print(json.dumps({
        "event": "message",
        "data": message if isinstance(message, dict) else str(message)
    }), flush=True)


def main():
    try:
        # Initialize AgentText client
        client = AgentText(base_url="http://localhost:3000")

        print(json.dumps({
            "success": True,
            "message": "Starting message watcher..."
        }), flush=True)

        # Start watching (this will use polling or webhooks)
        client.watcher.start(callback=on_message)

        # Keep the script running
        while True:
            time.sleep(1)

    except KeyboardInterrupt:
        print(json.dumps({
            "success": True,
            "message": "Watcher stopped"
        }), flush=True)
    except Exception as e:
        print(json.dumps({
            "success": False,
            "error": str(e)
        }), flush=True)
        sys.exit(1)


if __name__ == "__main__":
    main()
