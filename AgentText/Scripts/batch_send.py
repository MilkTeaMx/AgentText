#!/usr/bin/env python3
"""
Send batch messages using the AgentText Python package
Usage: batch_send.py <json_file>

JSON file format:
[
  {"to": "+1234567890", "content": "Hello!"},
  {"to": "user@example.com", "content": "Hi there!"}
]
"""

import sys
import json
import argparse

try:
    from agenttext import AgentText, AgentTextAPIException, AgentTextConnectionException
except ImportError:
    print(json.dumps({
        "success": False,
        "error": "AgentText package not installed. Run: pip3 install -e /path/to/agenttext_package"
    }))
    sys.exit(1)


def main():
    parser = argparse.ArgumentParser(description='Send batch messages via AgentText')
    parser.add_argument('json_file', help='JSON file with message array')
    parser.add_argument('--base-url', default='http://localhost:3000', help='API base URL')

    args = parser.parse_args()

    try:
        # Read messages from JSON file
        with open(args.json_file, 'r') as f:
            messages = json.load(f)

        if not isinstance(messages, list):
            print(json.dumps({
                "success": False,
                "error": "JSON file must contain an array of messages"
            }))
            sys.exit(1)

        # Initialize AgentText client
        client = AgentText(base_url=args.base_url, timeout=30)

        # Send batch
        results = client.messages.send_batch(messages)

        print(json.dumps({
            "success": True,
            "message": f"Sent {len(messages)} messages",
            "results": results if isinstance(results, list) else []
        }, indent=2))

    except FileNotFoundError:
        print(json.dumps({
            "success": False,
            "error": f"File not found: {args.json_file}"
        }))
        sys.exit(1)
    except json.JSONDecodeError as e:
        print(json.dumps({
            "success": False,
            "error": f"Invalid JSON: {str(e)}"
        }))
        sys.exit(1)
    except AgentTextConnectionException as e:
        print(json.dumps({
            "success": False,
            "error": f"Connection error: {str(e)}. Make sure the API server is running on {args.base_url}"
        }))
        sys.exit(1)
    except AgentTextAPIException as e:
        print(json.dumps({
            "success": False,
            "error": f"API error: {str(e)}"
        }))
        sys.exit(1)
    except Exception as e:
        print(json.dumps({
            "success": False,
            "error": str(e)
        }))
        sys.exit(1)


if __name__ == "__main__":
    main()
