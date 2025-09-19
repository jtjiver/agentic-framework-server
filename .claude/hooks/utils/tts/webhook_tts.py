#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.8"
# dependencies = [
#     "requests",
#     "python-dotenv",
# ]
# ///

import os
import sys
import requests
from pathlib import Path
from dotenv import load_dotenv

def main():
    """
    Webhook-based TTS for SSH sessions
    
    Sends TTS requests to a webhook running on your local laptop.
    This allows TTS to work even when connected via SSH.
    
    Usage:
    - ./webhook_tts.py "Your text here"
    
    Environment variables:
    - TTS_WEBHOOK_URL: URL of the webhook service on your laptop
    - TTS_WEBHOOK_TOKEN: Optional authentication token
    """
    
    # Load environment variables
    load_dotenv()
    
    # Get webhook URL from environment
    webhook_url = os.getenv('TTS_WEBHOOK_URL')
    webhook_token = os.getenv('TTS_WEBHOOK_TOKEN')
    
    if not webhook_url:
        # Silently fail if webhook not configured
        # This allows fallback to other TTS methods
        sys.exit(0)
    
    try:
        # Get text from command line argument or use default
        if len(sys.argv) > 1:
            text = " ".join(sys.argv[1:])
        else:
            text = "Your agent needs your input"
        
        # Prepare request payload
        payload = {
            "text": text,
            "voice": "default"
        }
        
        # Add authentication if token provided
        headers = {"Content-Type": "application/json"}
        if webhook_token:
            headers["Authorization"] = f"Bearer {webhook_token}"
        
        # Send webhook request with short timeout
        response = requests.post(
            webhook_url,
            json=payload,
            headers=headers,
            timeout=3  # Short timeout to avoid blocking
        )
        
        # Check if request was successful
        if response.status_code == 200:
            # Success - exit silently
            sys.exit(0)
        else:
            # Failed - exit silently (don't break the workflow)
            sys.exit(0)
            
    except Exception:
        # Any error - fail silently
        sys.exit(0)

if __name__ == "__main__":
    main()