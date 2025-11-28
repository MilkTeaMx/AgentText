#!/usr/bin/env python3
"""
List chats using the AgentText Python package
Usage: list_chats.py [--limit 20] [--type group|direct]
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
    parser = argparse.ArgumentParser(description='List chats via AgentText')
    parser.add_argument('--limit', type=int, default=20, help='Maximum number of chats')
    parser.add_argument('--type', choices=['group', 'direct'], help='Filter by chat type')
    parser.add_argument('--base-url', default='http://localhost:3000', help='API base URL')

    args = parser.parse_args()

    try:
        # Initialize AgentText client
        client = AgentText(base_url=args.base_url, timeout=30)

        # Build filters
        filters = {'limit': args.limit}
        if args.type:
            filters['type'] = args.type

        # List chats
        chats = client.chats.list(**filters)

        print(json.dumps({
            "success": True,
            "chats": chats if isinstance(chats, list) else [],
            "count": len(chats) if isinstance(chats, list) else 0
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
