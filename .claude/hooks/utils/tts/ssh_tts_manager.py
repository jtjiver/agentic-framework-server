#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.8"
# dependencies = [
#     "requests",
# ]
# ///
"""
SSH TTS Manager - One-command setup for SSH TTS notifications

This script handles:
- Starting/stopping TTS server and ngrok
- Auto-configuring the remote server via SSH
- Port management and conflict resolution
- Cross-platform compatibility

Usage:
    ./ssh_tts_manager.py start      # Start services + auto-configure server
    ./ssh_tts_manager.py stop       # Stop services
    ./ssh_tts_manager.py status     # Check status
    ./ssh_tts_manager.py restart    # Restart services
"""

import argparse
import json
import os
import re
import subprocess
import sys
import time
import signal
from pathlib import Path
import requests
import socket

class SSHTTSManager:
    def __init__(self):
        self.home_dir = Path.home()
        self.log_dir = self.home_dir / ".ssh_tts_logs"
        self.log_dir.mkdir(exist_ok=True)
        
        self.tts_server_script = self.home_dir / "laptop_tts_server.py"
        self.tts_server_pid_file = self.log_dir / "tts_server.pid"
        self.ngrok_pid_file = self.log_dir / "ngrok.pid"
        self.ngrok_url_file = self.log_dir / "ngrok_url.txt"
        
        # SSH connection details
        self.ssh_host = "cc-user@152.53.136.76"
        self.ssh_port = "2222"
        
        # Get port from ASW port manager
        self.tts_port = self.get_asw_port()

    def get_asw_port(self):
        """Get TTS port from ASW port manager"""
        try:
            result = subprocess.run([
                "/opt/asw/agentic-framework-infrastructure/bin/asw-port-manager",
                "get", "tts-laptop-server"
            ], capture_output=True, text=True, check=True)
            return int(result.stdout.strip())
        except (subprocess.CalledProcessError, ValueError):
            # Fallback to infrastructure registry check
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
            # Final fallback
            return 1414

    def find_available_port(self):
        """Find an available port, avoiding common conflicts"""
        # Known conflicted ports (Cursor IDE uses 5555, 5556)
        avoid_ports = [5555, 5556, 4040]  # 4040 is ngrok web interface
        
        for port in range(1414, 9000):
            if port in avoid_ports:
                continue
            if not self.is_port_in_use(port):
                return port
        
        raise Exception("No available ports found")

    def is_port_in_use(self, port):
        """Check if a port is in use using socket binding"""
        try:
            with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
                sock.bind(('localhost', port))
                return False
        except OSError:
            return True

    def get_elevenlabs_key_secure(self):
        """Get ElevenLabs API key securely using ASW security module"""
        try:
            # Load service account token
            token_file = "/opt/asw/.secrets/op-service-account-token"
            if os.path.exists(token_file):
                result = subprocess.run(["sudo", "cat", token_file], 
                                      capture_output=True, text=True, timeout=5)
                if result.returncode == 0 and result.stdout.strip():
                    os.environ['OP_SERVICE_ACCOUNT_TOKEN'] = result.stdout.strip()
                    print("🔒 1Password service account token loaded")
                else:
                    print("⚠️  Failed to read service account token")
            
            # Use ASW security module pattern: op item get
            result = subprocess.run([
                "op", "item", "get", "elevenlabs - API - claude-code", 
                "--reveal", "--field", "credential", 
                "--vault", "TennisTracker-Dev-Vault"
            ], capture_output=True, text=True, timeout=10)
            
            if result.returncode == 0 and result.stdout.strip():
                print("🔒 ElevenLabs API key loaded from 1Password")
                return result.stdout.strip()
            else:
                print(f"⚠️  1Password failed: {result.stderr.strip()}")
        
        except subprocess.TimeoutExpired:
            print("⚠️  1Password read timed out")
        except FileNotFoundError:
            print("⚠️  1Password CLI not found")
        except Exception as e:
            print(f"⚠️  1Password error: {e}")
        
        # Fallback to environment variable (less secure)
        env_key = os.getenv('ELEVENLABS_API_KEY')
        if env_key:
            print("🔍 ElevenLabs API key found in environment (fallback)")
            return env_key
        
        print("❌ No ElevenLabs API key found")
        return None

    def update_tts_server_port(self):
        """Update TTS server script to use the correct port"""
        if not self.tts_server_script.exists():
            print(f"❌ TTS server script not found: {self.tts_server_script}")
            print(f"📥 Copy it from server:")
            print(f"   scp -P {self.ssh_port} {self.ssh_host}:/opt/asw/.claude/hooks/utils/tts/laptop_tts_server.py {self.tts_server_script}")
            return False
        
        # Read and update the script
        content = self.tts_server_script.read_text()
        content = re.sub(r'port=\d+', f'port={self.tts_port}', content)
        content = re.sub(r':\d{4,5}', f':{self.tts_port}', content)
        self.tts_server_script.write_text(content)
        
        print(f"✅ Updated TTS server to use port {self.tts_port}")
        return True

    def start_tts_server(self):
        """Start the TTS webhook server"""
        print(f"📡 Starting TTS server on port {self.tts_port}...")
        
        # Kill existing servers
        self.kill_process_by_name("laptop_tts_server.py")
        
        # Update port
        if not self.update_tts_server_port():
            return False
        
        # Start server with environment variables
        log_file = self.log_dir / "tts_server.log"
        
        # Ensure environment variables are passed to subprocess
        env = os.environ.copy()
        
        # Get ElevenLabs API key securely from 1Password
        elevenlabs_key = self.get_elevenlabs_key_secure()
        
        if elevenlabs_key:
            print(f"✅ ElevenLabs API key found - will use high-quality voice")
            # Ensure it's in the environment for the subprocess
            env['ELEVENLABS_API_KEY'] = elevenlabs_key
        else:
            print(f"⚠️  No ELEVENLABS_API_KEY found - will use system TTS")
            print(f"   Current env keys: {list(k for k in env.keys() if 'ELEVEN' in k.upper())}")
            print(f"   Add to ~/.zshrc: export ELEVENLABS_API_KEY=your_key")
        
        with open(log_file, 'w') as f:
            process = subprocess.Popen(
                [str(self.tts_server_script)],
                stdout=f,
                stderr=subprocess.STDOUT,
                start_new_session=True,
                env=env  # Pass environment variables
            )
        
        # Save PID
        self.tts_server_pid_file.write_text(str(process.pid))
        
        # Wait and check if it started
        time.sleep(3)
        
        try:
            response = requests.get(f"http://localhost:{self.tts_port}/health", timeout=5)
            if response.status_code == 200:
                print(f"✅ TTS server started (PID: {process.pid})")
                return True
        except requests.RequestException:
            pass
        
        print("❌ TTS server failed to start")
        print(f"📝 Check logs: cat {log_file}")
        return False

    def start_ngrok(self):
        """Start ngrok tunnel"""
        print("🌐 Starting ngrok tunnel...")
        
        # Kill existing ngrok
        self.kill_process_by_name("ngrok")
        
        # Start ngrok
        log_file = self.log_dir / "ngrok.log"
        with open(log_file, 'w') as f:
            process = subprocess.Popen(
                ["ngrok", "http", str(self.tts_port), "--log=stdout"],
                stdout=f,
                stderr=subprocess.STDOUT,
                start_new_session=True
            )
        
        # Save PID
        self.ngrok_pid_file.write_text(str(process.pid))
        
        # Wait for ngrok to start and retry multiple times
        print("⏳ Waiting for ngrok to start...")
        
        for attempt in range(10):  # Try for up to 30 seconds
            time.sleep(3)
            try:
                response = requests.get("http://localhost:4040/api/tunnels", timeout=5)
                data = response.json()
                
                for tunnel in data.get("tunnels", []):
                    if tunnel.get("proto") == "https":
                        ngrok_url = tunnel["public_url"]
                        self.ngrok_url_file.write_text(ngrok_url)
                        print(f"✅ Ngrok started: {ngrok_url}")
                        return ngrok_url
                        
                # If no HTTPS tunnel found, print available tunnels for debugging
                if attempt == 0:
                    print(f"🔍 Available tunnels: {[t.get('public_url') for t in data.get('tunnels', [])]}")
                    
            except requests.RequestException as e:
                if attempt < 5:  # Only show early errors
                    print(f"⏳ Attempt {attempt + 1}: Waiting for ngrok...")
                elif attempt == 9:  # Last attempt
                    print(f"❌ Failed to get ngrok URL after 30 seconds: {e}")
                    print("💡 Try manually starting ngrok: ngrok http " + str(self.tts_port))
        
        print("❌ Ngrok failed to start")
        return None

    def configure_server(self, ngrok_url):
        """Auto-configure the SSH server"""
        print("🔗 Auto-configuring server...")
        
        # Test SSH connection
        test_cmd = ["ssh", "-A", "-p", self.ssh_port, self.ssh_host, "-o", "ConnectTimeout=5", "echo 'SSH test'"]
        try:
            subprocess.run(test_cmd, check=True, capture_output=True, timeout=10)
        except (subprocess.CalledProcessError, subprocess.TimeoutExpired):
            print("⚠️  Cannot connect to SSH server automatically")
            print("📋 Manual setup required:")
            print(f"   ssh -A -p {self.ssh_port} {self.ssh_host}")
            print(f"   export TTS_WEBHOOK_URL=\"{ngrok_url}/tts\"")
            return False
        
        # Configure webhook on server
        print("📡 Setting webhook URL on server...")
        webhook_url = f"{ngrok_url}/tts"
        
        ssh_commands = f"""
        # Create /opt/asw/.env if it doesn't exist
        touch /opt/asw/.env
        
        # Remove existing webhook URL
        sed -i '/^TTS_WEBHOOK_URL=/d' /opt/asw/.env 2>/dev/null || true
        
        # Add new webhook URL
        echo "TTS_WEBHOOK_URL={webhook_url}" >> /opt/asw/.env
        
        # Make sure the file is readable
        chmod 644 /opt/asw/.env
        
        # Export for current session
        export TTS_WEBHOOK_URL="{webhook_url}"
        
        # Verify it was written
        echo "📝 Verifying .env file:"
        grep "TTS_WEBHOOK_URL" /opt/asw/.env || echo "❌ Failed to write to .env"
        
        echo "✅ Server configured with webhook: {webhook_url}"
        
        # Test the connection
        echo "🧪 Testing webhook connection..."
        if curl -s -X POST "{webhook_url}" \\
            -H "Content-Type: application/json" \\
            -d '{{"text": "SSH TTS setup complete"}}' \\
            --max-time 5 >/dev/null 2>&1; then
            echo "✅ Webhook test successful - you should hear TTS!"
        else
            echo "❌ Webhook test failed"
        fi
        """
        
        ssh_cmd = ["ssh", "-A", "-p", self.ssh_port, self.ssh_host, ssh_commands]
        try:
            result = subprocess.run(ssh_cmd, check=True, capture_output=True, text=True, timeout=30)
            print(result.stdout)
            print("✅ Server auto-configuration complete!")
            return True
        except (subprocess.CalledProcessError, subprocess.TimeoutExpired) as e:
            print(f"❌ Server configuration failed: {e}")
            return False

    def kill_process_by_name(self, name):
        """Kill processes by name using subprocess"""
        try:
            # Use pkill which doesn't require special permissions
            subprocess.run(["pkill", "-f", name], check=False, capture_output=True)
        except Exception:
            pass

    def stop_services(self):
        """Stop all services"""
        print("🛑 Stopping SSH TTS services...")
        
        # Stop TTS server
        if self.tts_server_pid_file.exists():
            try:
                pid = int(self.tts_server_pid_file.read_text())
                os.kill(pid, signal.SIGTERM)
                self.tts_server_pid_file.unlink()
                print("✅ TTS server stopped")
            except (ValueError, ProcessLookupError):
                pass
        
        # Stop ngrok
        if self.ngrok_pid_file.exists():
            try:
                pid = int(self.ngrok_pid_file.read_text())
                os.kill(pid, signal.SIGTERM)
                self.ngrok_pid_file.unlink()
                self.ngrok_url_file.unlink(missing_ok=True)
                print("✅ Ngrok stopped")
            except (ValueError, ProcessLookupError):
                pass
        
        # Kill any remaining processes
        self.kill_process_by_name("laptop_tts_server.py")
        self.kill_process_by_name("ngrok")
        
        print("🏁 All services stopped")

    def show_status(self):
        """Show service status"""
        print("📊 SSH TTS Status")
        print("=" * 20)
        
        # Check TTS server
        try:
            response = requests.get(f"http://localhost:{self.tts_port}/health", timeout=3)
            if response.status_code == 200:
                print(f"✅ TTS Server: Running on port {self.tts_port}")
            else:
                print("❌ TTS Server: Not responding")
        except requests.RequestException:
            print("❌ TTS Server: Not running")
        
        # Check ngrok
        if self.ngrok_url_file.exists():
            ngrok_url = self.ngrok_url_file.read_text().strip()
            print(f"✅ Ngrok: {ngrok_url}")
        else:
            print("❌ Ngrok: Not running")

    def start_services(self):
        """Start all services and configure server"""
        print("🎙️ Starting SSH TTS Services...")
        print("=" * 35)
        print(f"✅ Port {self.tts_port} selected")
        
        # Start TTS server
        if not self.start_tts_server():
            return False
        
        # Start ngrok
        ngrok_url = self.start_ngrok()
        if not ngrok_url:
            return False
        
        # Show connection info
        print("")
        print("🚀 SSH TTS Services Started!")
        print("=" * 30)
        print(f"📡 TTS Server: http://localhost:{self.tts_port}")
        print(f"🌐 Ngrok URL: {ngrok_url}")
        print("")
        
        # Ask for auto-configuration
        try:
            auto_config = input("🤖 Auto-configure SSH server? (y/n): ").strip().lower()
            if auto_config in ['y', 'yes']:
                self.configure_server(ngrok_url)
            else:
                print("📋 Manual setup:")
                print(f"   ssh -A -p {self.ssh_port} {self.ssh_host}")
                print(f"   export TTS_WEBHOOK_URL=\"{ngrok_url}/tts\"")
        except KeyboardInterrupt:
            print("\n⚠️  Skipping server configuration")
        
        print("")
        print("🛑 To stop services:")
        print(f"   {sys.argv[0]} stop")
        
        return True

def main():
    parser = argparse.ArgumentParser(description="SSH TTS Manager")
    parser.add_argument("action", choices=["start", "stop", "status", "restart"], 
                       help="Action to perform")
    
    args = parser.parse_args()
    manager = SSHTTSManager()
    
    try:
        if args.action == "start":
            manager.start_services()
        elif args.action == "stop":
            manager.stop_services()
        elif args.action == "status":
            manager.show_status()
        elif args.action == "restart":
            manager.stop_services()
            time.sleep(2)
            manager.start_services()
    except KeyboardInterrupt:
        print("\n🛑 Operation cancelled")
        sys.exit(1)
    except Exception as e:
        print(f"❌ Error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()