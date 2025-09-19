#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.8"
# dependencies = [
#     "requests",
#     "paramiko",
# ]
# ///
"""
SSH TTS Diagnostics Tool

Comprehensive testing of the SSH TTS system from laptop to server.
Tests the entire chain: laptop TTS server → ngrok → server webhook client.

Usage:
    ./ssh_tts_diagnostics.py
    ./ssh_tts_diagnostics.py --server-only
    ./ssh_tts_diagnostics.py --local-only
"""

import argparse
import json
import os
import subprocess
import sys
import time
from pathlib import Path
import requests
import paramiko

class SSHTTSDiagnostics:
    def __init__(self):
        self.home_dir = Path.home()
        self.log_dir = self.home_dir / ".ssh_tts_logs"
        self.ngrok_url_file = self.log_dir / "ngrok_url.txt"
        
        # Server connection details
        self.ssh_host = "152.53.136.76"
        self.ssh_port = 2222
        self.ssh_user = "cc-user"
        
        self.results = {
            "laptop_tts_server": False,
            "ngrok_tunnel": False,
            "server_connection": False,
            "server_webhook_config": False,
            "end_to_end_test": False,
            "errors": []
        }

    def log_test(self, test_name, success, details=""):
        """Log test results"""
        status = "✅" if success else "❌"
        print(f"{status} {test_name}")
        if details:
            print(f"   {details}")
        if not success:
            self.results["errors"].append(f"{test_name}: {details}")

    def test_laptop_tts_server(self):
        """Test local TTS server functionality"""
        print("\n🔍 Testing Laptop TTS Server")
        print("=" * 40)
        
        # Test health endpoint
        try:
            response = requests.get("http://localhost:1414/health", timeout=5)
            if response.status_code == 200:
                self.log_test("TTS Server Health", True, "Server responding")
                self.results["laptop_tts_server"] = True
            else:
                self.log_test("TTS Server Health", False, f"HTTP {response.status_code}")
                return False
        except requests.RequestException as e:
            self.log_test("TTS Server Health", False, f"Connection failed: {e}")
            return False
        
        # Test TTS functionality
        try:
            test_payload = {"text": "Laptop TTS diagnostics test"}
            response = requests.post(
                "http://localhost:1414/tts",
                json=test_payload,
                timeout=10
            )
            
            if response.status_code == 200:
                self.log_test("TTS Server Function", True, "TTS request accepted")
                print("   🎙️ You should hear: 'Laptop TTS diagnostics test'")
                return True
            else:
                self.log_test("TTS Server Function", False, f"HTTP {response.status_code}")
                return False
                
        except requests.RequestException as e:
            self.log_test("TTS Server Function", False, f"Request failed: {e}")
            return False

    def test_ngrok_tunnel(self):
        """Test ngrok tunnel availability"""
        print("\n🌐 Testing Ngrok Tunnel")
        print("=" * 40)
        
        # Check if ngrok URL file exists
        if not self.ngrok_url_file.exists():
            self.log_test("Ngrok URL File", False, "URL file not found")
            return False
        
        # Read ngrok URL
        try:
            ngrok_url = self.ngrok_url_file.read_text().strip()
            self.log_test("Ngrok URL File", True, f"URL: {ngrok_url}")
        except Exception as e:
            self.log_test("Ngrok URL File", False, f"Read error: {e}")
            return False
        
        # Test ngrok health endpoint
        try:
            health_url = f"{ngrok_url.replace('/tts', '')}/health"
            response = requests.get(health_url, timeout=10)
            
            if response.status_code == 200:
                self.log_test("Ngrok Health", True, "Tunnel responding")
                self.results["ngrok_tunnel"] = True
            else:
                self.log_test("Ngrok Health", False, f"HTTP {response.status_code}")
                return False
                
        except requests.RequestException as e:
            self.log_test("Ngrok Health", False, f"Connection failed: {e}")
            return False
        
        # Test ngrok TTS endpoint
        try:
            test_payload = {"text": "Ngrok tunnel diagnostics test"}
            # Ensure the URL ends with /tts
            tts_url = ngrok_url if ngrok_url.endswith('/tts') else f"{ngrok_url}/tts"
            response = requests.post(
                tts_url,
                json=test_payload,
                timeout=10
            )
            
            if response.status_code == 200:
                self.log_test("Ngrok TTS", True, "TTS via tunnel works")
                print("   🎙️ You should hear: 'Ngrok tunnel diagnostics test'")
                return True
            else:
                self.log_test("Ngrok TTS", False, f"HTTP {response.status_code}: {response.text}")
                return False
                
        except requests.RequestException as e:
            self.log_test("Ngrok TTS", False, f"Request failed: {e}")
            return False

    def test_server_connection(self):
        """Test SSH connection to server"""
        print("\n🔗 Testing Server Connection")
        print("=" * 40)
        
        try:
            # Test SSH connection
            ssh = paramiko.SSHClient()
            ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
            
            # Use SSH agent for authentication
            ssh.connect(
                hostname=self.ssh_host,
                port=self.ssh_port,
                username=self.ssh_user,
                timeout=10
            )
            
            self.log_test("SSH Connection", True, f"Connected to {self.ssh_user}@{self.ssh_host}")
            self.results["server_connection"] = True
            
            # Test basic command
            stdin, stdout, stderr = ssh.exec_command("echo 'SSH test successful'")
            output = stdout.read().decode().strip()
            
            if output == "SSH test successful":
                self.log_test("SSH Command", True, "Command execution works")
            else:
                self.log_test("SSH Command", False, f"Unexpected output: {output}")
            
            ssh.close()
            return True
            
        except Exception as e:
            self.log_test("SSH Connection", False, f"Connection failed: {e}")
            return False

    def test_server_webhook_config(self):
        """Test server webhook configuration"""
        print("\n⚙️ Testing Server Webhook Config")
        print("=" * 40)
        
        try:
            ssh = paramiko.SSHClient()
            ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
            ssh.connect(
                hostname=self.ssh_host,
                port=self.ssh_port,
                username=self.ssh_user,
                timeout=10
            )
            
            # Check environment variables
            stdin, stdout, stderr = ssh.exec_command(
                'echo "TTS_WEBHOOK_URL: $TTS_WEBHOOK_URL"; echo "SSH_CLIENT: $SSH_CLIENT"'
            )
            output = stdout.read().decode().strip()
            
            if "TTS_WEBHOOK_URL:" in output and "SSH_CLIENT:" in output:
                self.log_test("Server Environment", True, "Variables detected")
                print(f"   {output}")
                
                # Extract webhook URL
                webhook_url = None
                for line in output.split('\n'):
                    if line.startswith('TTS_WEBHOOK_URL:'):
                        webhook_url = line.split(':', 1)[1].strip()
                        break
                
                if webhook_url and webhook_url != "":
                    self.log_test("Webhook URL Config", True, f"URL: {webhook_url}")
                    self.results["server_webhook_config"] = True
                else:
                    self.log_test("Webhook URL Config", False, "URL not set")
                    
            else:
                self.log_test("Server Environment", False, "Variables not found")
            
            ssh.close()
            return True
            
        except Exception as e:
            self.log_test("Server Environment", False, f"Check failed: {e}")
            return False

    def test_end_to_end(self):
        """Test complete end-to-end functionality"""
        print("\n🎯 Testing End-to-End Functionality")
        print("=" * 40)
        
        try:
            ssh = paramiko.SSHClient()
            ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
            ssh.connect(
                hostname=self.ssh_host,
                port=self.ssh_port,
                username=self.ssh_user,
                timeout=10
            )
            
            # Test webhook TTS script
            command = 'export PATH="$HOME/.local/bin:$PATH"; uv run /opt/asw/.claude/hooks/utils/tts/webhook_tts.py "End-to-end diagnostics test"'
            stdin, stdout, stderr = ssh.exec_command(command)
            
            # Wait for command completion
            exit_status = stdout.channel.recv_exit_status()
            error_output = stderr.read().decode().strip()
            
            if exit_status == 0:
                self.log_test("End-to-End Test", True, "Command executed successfully")
                print("   🎙️ You should hear: 'End-to-end diagnostics test'")
                self.results["end_to_end_test"] = True
                return True
            else:
                self.log_test("End-to-End Test", False, f"Exit code: {exit_status}")
                if error_output:
                    print(f"   Error: {error_output}")
                return False
            
        except Exception as e:
            self.log_test("End-to-End Test", False, f"Test failed: {e}")
            return False
        finally:
            try:
                ssh.close()
            except:
                pass

    def run_diagnostics(self, local_only=False, server_only=False):
        """Run comprehensive diagnostics"""
        print("🔍 SSH TTS Diagnostics Tool")
        print("=" * 50)
        
        if not server_only:
            # Test local components
            self.test_laptop_tts_server()
            self.test_ngrok_tunnel()
        
        if not local_only:
            # Test server components
            self.test_server_connection()
            if self.results["server_connection"]:
                self.test_server_webhook_config()
                self.test_end_to_end()
        
        # Summary
        self.print_summary()

    def print_summary(self):
        """Print diagnostic summary"""
        print("\n📊 Diagnostic Summary")
        print("=" * 50)
        
        total_tests = len([k for k in self.results.keys() if k != "errors"])
        passed_tests = len([k for k, v in self.results.items() if v is True])
        
        print(f"Tests passed: {passed_tests}/{total_tests}")
        print()
        
        # Component status
        components = [
            ("Laptop TTS Server", self.results["laptop_tts_server"]),
            ("Ngrok Tunnel", self.results["ngrok_tunnel"]),
            ("Server Connection", self.results["server_connection"]),
            ("Server Config", self.results["server_webhook_config"]),
            ("End-to-End", self.results["end_to_end_test"])
        ]
        
        for name, status in components:
            status_icon = "✅" if status else "❌"
            print(f"{status_icon} {name}")
        
        # Errors
        if self.results["errors"]:
            print("\n🚨 Issues Found:")
            for error in self.results["errors"]:
                print(f"   • {error}")
        
        # Recommendations
        print("\n💡 Recommendations:")
        if not self.results["laptop_tts_server"]:
            print("   • Start laptop TTS server: ~/ssh_tts_manager.py start")
        if not self.results["ngrok_tunnel"]:
            print("   • Check ngrok is running and accessible")
        if not self.results["server_webhook_config"]:
            print("   • Run server configuration: ~/ssh_tts_manager.py start (auto-config)")
        if not self.results["end_to_end_test"]:
            print("   • Check firewall/network connectivity between server and laptop")

def main():
    parser = argparse.ArgumentParser(description="SSH TTS Diagnostics Tool")
    parser.add_argument("--local-only", action="store_true", 
                       help="Test only laptop components")
    parser.add_argument("--server-only", action="store_true", 
                       help="Test only server components")
    
    args = parser.parse_args()
    
    if args.local_only and args.server_only:
        print("❌ Cannot specify both --local-only and --server-only")
        sys.exit(1)
    
    diagnostics = SSHTTSDiagnostics()
    try:
        diagnostics.run_diagnostics(
            local_only=args.local_only,
            server_only=args.server_only
        )
    except KeyboardInterrupt:
        print("\n🛑 Diagnostics cancelled")
        sys.exit(1)
    except Exception as e:
        print(f"\n❌ Diagnostics failed: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()