#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.8"
# dependencies = [
#     "flask",
#     "requests",
#     "elevenlabs",
#     "python-dotenv",
# ]
# ///
"""
TTS Webhook Server for Local Laptop

Run this on your laptop to receive TTS requests from remote SSH sessions.

Usage:
./laptop_tts_server.py

Then set on remote server:
export TTS_WEBHOOK_URL="http://your-laptop-ip:5555/tts"
export TTS_WEBHOOK_TOKEN="your-secret-token"  # optional
"""

import os
import sys
import subprocess
import threading
from flask import Flask, request, jsonify
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

app = Flask(__name__)

def get_asw_port():
    """Get TTS port from ASW port manager"""
    try:
        result = subprocess.run([
            "/opt/asw/agentic-framework-infrastructure/bin/asw-port-manager",
            "infra-list"
        ], capture_output=True, text=True, check=True)
        for line in result.stdout.split('\n'):
            if 'tts-laptop-server' in line:
                return int(line.split()[0])
    except (subprocess.CalledProcessError, ValueError):
        pass
    # Fallback to default port
    return 1414

# Optional authentication token
AUTH_TOKEN = os.getenv('TTS_WEBHOOK_TOKEN')

def play_tts_elevenlabs(text):
    """Play TTS using ElevenLabs (if available)"""
    try:
        from elevenlabs.client import ElevenLabs
        from elevenlabs.play import play
        
        api_key = os.getenv('ELEVENLABS_API_KEY')
        if not api_key:
            return False
            
        client = ElevenLabs(api_key=api_key)
        audio = client.text_to_speech.convert(
            text=text,
            voice_id="MM489xMK9DfnbQX6x7OW",  # Same voice as your setup
            model_id="eleven_turbo_v2_5",
            output_format="mp3_44100_128",
        )
        play(audio)
        return True
    except Exception as e:
        print(f"ElevenLabs TTS failed: {e}")
        return False

def play_tts_system(text):
    """Fallback to system TTS"""
    try:
        if sys.platform == "darwin":  # macOS
            subprocess.run(["say", text], check=True)
        elif sys.platform.startswith("linux"):  # Linux
            subprocess.run(["espeak", text], check=True)
        elif sys.platform == "win32":  # Windows
            subprocess.run(["powershell", "-Command", f"Add-Type -AssemblyName System.Speech; (New-Object System.Speech.Synthesis.SpeechSynthesizer).Speak('{text}')"], check=True)
        return True
    except Exception as e:
        print(f"System TTS failed: {e}")
        return False

def play_tts_async(text):
    """Play TTS in background thread to avoid blocking HTTP response"""
    def tts_worker():
        try:
            # Try ElevenLabs first, fallback to system TTS
            success = play_tts_elevenlabs(text) or play_tts_system(text)
            if success:
                print(f"✅ TTS played: {text}")
            else:
                print(f"❌ TTS failed: {text}")
        except Exception as e:
            print(f"❌ TTS error: {e}")
    
    # Start TTS in background thread
    thread = threading.Thread(target=tts_worker)
    thread.daemon = True
    thread.start()

@app.route('/tts', methods=['POST'])
def tts_webhook():
    """Handle TTS webhook requests"""
    
    # Check authentication if token is set
    if AUTH_TOKEN:
        auth_header = request.headers.get('Authorization', '')
        if not auth_header.startswith('Bearer ') or auth_header[7:] != AUTH_TOKEN:
            return jsonify({"error": "Unauthorized"}), 401
    
    # Get request data
    data = request.get_json()
    if not data or 'text' not in data:
        return jsonify({"error": "Missing 'text' field"}), 400
    
    text = data['text']
    print(f"🎙️ Received TTS request: {text}")
    
    # Start TTS in background thread - return immediately
    play_tts_async(text)
    
    # Return success immediately (don't wait for TTS to complete)
    return jsonify({"status": "success", "message": "TTS request received"})

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({"status": "healthy", "service": "TTS Webhook Server"})

if __name__ == '__main__':
    # Get port from ASW port manager
    port = get_asw_port()

    print("🎙️  TTS Webhook Server Starting...")
    print("=" * 40)
    print(f"Server will run on: http://0.0.0.0:{port}")
    print(f"TTS endpoint: http://your-laptop-ip:{port}/tts")
    print(f"Health check: http://your-laptop-ip:{port}/health")
    print(f"Port managed by: ASW Infrastructure (tts-laptop-server)")

    if AUTH_TOKEN:
        print(f"Authentication: Enabled (token required)")
    else:
        print(f"Authentication: Disabled")

    print("=" * 40)

    # Run the server
    app.run(host='0.0.0.0', port=port, debug=False)