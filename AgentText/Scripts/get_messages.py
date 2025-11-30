#!/usr/bin/env python3
"""
Get messages using the AgentText Python package
Usage: get_messages.py [--limit 10] [--sender "+1234567890"] [--unread-only]
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
    parser = argparse.ArgumentParser(description='Get messages via AgentText')
    parser.add_argument('--limit', type=int, default=10, help='Maximum number of messages')
    parser.add_argument('--sender', help='Filter by sender phone/email')
    parser.add_argument('--unread-only', action='store_true', help='Only unread messages')
    parser.add_argument('--base-url', default='http://localhost:3000', help='API base URL')

    args = parser.parse_args()

    try:
        # Initialize AgentText client
        client = AgentText(base_url=args.base_url, timeout=30)

        # Build filters
        filters = {'limit': args.limit}
        if args.sender:
            filters['sender'] = args.sender
        if args.unread_only:
            filters['unreadOnly'] = True

        # Get messages
        messages = client.messages.list(**filters)

        print(json.dumps({
            "success": True,
            "messages": messages if isinstance(messages, (list, dict)) else [],
            "count": len(messages) if isinstance(messages, list) else 0
        }, indent=2))

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
