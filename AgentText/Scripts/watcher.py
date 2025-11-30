#!/usr/bin/env python3
"""
Start/stop/check watcher using the AgentText Python package
Usage:
  watcher.py start [--webhook-url URL]
  watcher.py stop
  watcher.py status
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
    parser = argparse.ArgumentParser(description='Manage message watcher via AgentText')
    parser.add_argument('action', choices=['start', 'stop', 'status'], help='Watcher action')
    parser.add_argument('--webhook-url', help='Webhook URL for message notifications')
    parser.add_argument('--base-url', default='http://localhost:3000', help='API base URL')

    args = parser.parse_args()

    try:
        # Initialize AgentText client
        client = AgentText(base_url=args.base_url, timeout=30)

        if args.action == 'start':
            webhook = {'url': args.webhook_url} if args.webhook_url else None
            result = client.watcher.start(webhook=webhook)
            print(json.dumps({
                "success": True,
                "action": "start",
                "message": "Watcher started",
                "result": result if isinstance(result, dict) else str(result)
            }))

        elif args.action == 'stop':
            result = client.watcher.stop()
            print(json.dumps({
                "success": True,
                "action": "stop",
                "message": "Watcher stopped",
                "result": result if isinstance(result, dict) else str(result)
            }))

        elif args.action == 'status':
            result = client.watcher.status()
            print(json.dumps({
                "success": True,
                "action": "status",
                "status": result if isinstance(result, dict) else str(result)
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
