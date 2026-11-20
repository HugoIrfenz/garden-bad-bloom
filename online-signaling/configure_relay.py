#!/usr/bin/env python3
"""Store a Cloudflare TURN key as encrypted Worker secrets without exposing it in chat."""
from getpass import getpass
from pathlib import Path
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parent
WORKER = "garden-bad-bloom-signaling"


def prompt_secret(label: str, size: int) -> str:
    value = getpass(label).strip()
    if not re.fullmatch(r"[0-9a-fA-F]{%d}" % size, value):
        print("That value has the wrong format. No value was shown or saved.", file=sys.stderr)
        raise SystemExit(1)
    return value


def put_secret(name: str, value: str) -> None:
    result = subprocess.run(
        ["npx", "--yes", "wrangler@4", "secret", "put", name, "--name", WORKER],
        cwd=ROOT, input=value + "\n", text=True,
        stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False,
    )
    if result.returncode:
        # Never echo subprocess diagnostics: treat them as potentially secret-bearing.
        print(f"Could not store {name}. Check Wrangler's account authorization and retry.", file=sys.stderr)
        raise SystemExit(1)
    print(f"Stored {name} as an encrypted Cloudflare Worker secret.")


def main() -> None:
    if not sys.stdin.isatty():
        print("Run this script directly in a terminal so the key can be entered privately.", file=sys.stderr)
        raise SystemExit(1)
    print("Enter the two values from the TURN key page. Your typing will be hidden.")
    print("Cloudflare Realtime has a 1,000 GB included allowance, then bills overages.")
    key_id = prompt_secret("TURN key ID: ", 32)
    api_token = prompt_secret("TURN API token: ", 64)
    put_secret("TURN_KEY_ID", key_id)
    put_secret("TURN_API_TOKEN", api_token)
    key_id = api_token = ""
    print("Deploying the room service with relay fallback...")
    result = subprocess.run(["npx", "--yes", "wrangler@4", "deploy"], cwd=ROOT, check=False)
    if result.returncode:
        print("Deployment failed; existing Worker secrets remain stored. Retry this script after checking Wrangler.", file=sys.stderr)
        raise SystemExit(result.returncode)
    print("Relay configuration deployed. Keep the key private and monitor Cloudflare usage.")


if __name__ == "__main__":
    main()
