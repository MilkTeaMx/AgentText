#!/usr/bin/env python3
"""
Send an iMessage using the AgentText Python package
Usage: send_message.py <recipient> <message> [--files file1,file2]
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
    parser = argparse.ArgumentParser(description='Send iMessage via AgentText')
    parser.add_argument('recipient', help='Recipient phone number or email')
    parser.add_argument('message', help='Message text')
    parser.add_argument('--files', help='Comma-separated file paths', default=None)
    parser.add_argument('--base-url', default='http://localhost:3000', help='API base URL')

    args = parser.parse_args()

    try:
        # Initialize AgentText client
        client = AgentText(base_url=args.base_url, timeout=30)

        # Send message with optional files
        if args.files:
            file_paths = [f.strip() for f in args.files.split(',')]
            result = client.messages.send_files(
                to=args.recipient,
                file_paths=file_paths,
                text=args.message
            )
        else:
            result = client.messages.send(
                to=args.recipient,
                content=args.message
            )

        print(json.dumps({
            "success": True,
            "message": f"Message sent to {args.recipient}",
            "result": result if isinstance(result, dict) else str(result)
        }))

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
