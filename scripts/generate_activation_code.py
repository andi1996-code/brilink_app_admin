#!/usr/bin/env python3
"""
Simple script to generate activation code for a device using a shared secret.
The activation code is HMAC-SHA256(device_id) and is base64-encoded.

Usage:
  python scripts/generate_activation_code.py --device <DEVICE_ID> --secret <SECRET>

If --secret is omitted, the script uses the default secret: "brilink_app_idnacode".
"""

import argparse
import base64
import hashlib
import hmac
import sys

DEFAULT_SECRET = 'brilink_app_idnacode'


def generate_activation_code(device_id: str, secret: str = DEFAULT_SECRET) -> str:
    mac = hmac.new(secret.encode('utf-8'), device_id.encode('utf-8'), hashlib.sha256)
    return base64.b64encode(mac.digest()).decode('utf-8')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Generate activation code (HMAC-SHA256 base64) for a Device ID.')
    parser.add_argument('-d', '--device', required=True, help='Device ID (exact string from device)')
    parser.add_argument('-s', '--secret', required=False, default=DEFAULT_SECRET, help='Shared secret used to generate code (default matches app constant)')
    parser.add_argument('-q', '--quiet', action='store_true', help='Only print activation code')
    parser.add_argument('-f', '--format', choices=['base64', 'hex'], default='base64', help='Output format (default base64)')
    parser.add_argument('-l', '--len', type=int, default=4, help='Number of bytes used for hex format (default: 4 -> 8 hex characters)')

    args = parser.parse_args()

    if args.format == 'base64':
        code = generate_activation_code(args.device, args.secret)
    else:
        # hex truncated code: take first `len` bytes of HMAC-SHA256 and output uppercase hex
        full = hmac.new(args.secret.encode('utf-8'), args.device.encode('utf-8'), hashlib.sha256).digest()
        truncated = full[: args.len]
        code = ''.join(f'{b:02X}' for b in truncated)

    if args.quiet:
        print(code)
        sys.exit(0)

    print('Device ID :', args.device)
    print('Secret    :', args.secret if args.secret != DEFAULT_SECRET else '(default)')
    print('Activation code:')
    print(code)
    print('\nUse this code in the app Activation screen.')
