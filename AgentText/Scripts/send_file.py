#!/usr/bin/env python3
"""
Send a file via iMessage using the AgentText Python package
Usage: send_file.py <recipient> <file_path> [--text "Optional message"]
"""

import sys
import json
import argparse
import os

try:
    from agenttext import AgentText, AgentTextAPIException, AgentTextConnectionException
except ImportError:
    print(json.dumps({
        "success": False,
        "error": "AgentText package not installed. Run: pip3 install -e /path/to/agenttext_package"
    }))
    sys.exit(1)


def main():
    parser = argparse.ArgumentParser(description='Send file via iMessage')
    parser.add_argument('recipient', help='Recipient phone number or email')
    parser.add_argument('file_path', help='Path to file to send')
    parser.add_argument('--text', help='Optional message text', default=None)
    parser.add_argument('--base-url', default='http://localhost:3000', help='API base URL')

    args = parser.parse_args()

    # Validate file exists
    if not os.path.exists(args.file_path):
        print(json.dumps({
            "success": False,
            "error": f"File not found: {args.file_path}"
        }))
        sys.exit(1)

    try:
        # Initialize AgentText client
        client = AgentText(base_url=args.base_url, timeout=30)

        # Send file
        result = client.messages.send_file(
            to=args.recipient,
            file_path=args.file_path,
            text=args.text
        )

        print(json.dumps({
            "success": True,
            "message": f"File sent to {args.recipient}",
            "file": args.file_path,
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
