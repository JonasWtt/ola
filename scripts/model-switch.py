#!/usr/bin/env python3
"""
Model Switch Server for vLLM
Allows Odysseus to switch between different models dynamically

Usage:
1. Start vLLM with dynamic config: docker compose -f docker-compose.vllm.dynamic.yml up -d
2. Start this script: python scripts/model-switch.py
3. In Odysseus, configure multiple model endpoints pointing to this server
4. Switch models by calling: POST http://localhost:8001/switch?model=<model-name>

Available models (must match HuggingFace model names):
- LiquidAI/LFM2.5-8B-A1B-AWQ
- Qwen/CodeQwen1.5-7B-Chat-AWQ
- meta-llama/Meta-Llama-3-8B-Instruct-AWQ
- Qwen/Qwen2-7B-Instruct-AWQ
- TheBloke/Mistral-7B-Instruct-v0.2-AWQ
- microsoft/Phi-3-mini-4k-instruct-awq
- cyankiwi/devstral-small-2-awq
"""

import os
import json
import subprocess
import sys
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import parse_qs, urlparse
import threading
import time

# Configuration
VLLM_CONTAINER = os.getenv('VLLM_CONTAINER', 'vllm-dynamic')
DOCKER_COMPOSE_FILE = os.getenv('VLLM_COMPOSE_FILE', 'docker-compose.vllm.dynamic.yml')
MODEL_CACHE_DIR = os.getenv('MODEL_CACHE_DIR', './vllm-data/models')
HOST = '0.0.0.0'
PORT = 8001

# Available models mapping (short name -> full HuggingFace name)
MODEL_MAPPING = {
    'lfm2-5-8b-a1b': 'LiquidAI/LFM2.5-8B-A1B-AWQ',
    'codeqwen-7b': 'Qwen/CodeQwen1.5-7B-Chat-AWQ',
    'llama3-8b': 'meta-llama/Meta-Llama-3-8B-Instruct-AWQ',
    'qwen2-7b': 'Qwen/Qwen2-7B-Instruct-AWQ',
    'mistral-7b': 'TheBloke/Mistral-7B-Instruct-v0.2-AWQ',
    'phi-3-mini': 'microsoft/Phi-3-mini-4k-instruct-awq',
    'devstral-small': 'cyankiwi/devstral-small-2-awq',
}

# Default model
DEFAULT_MODEL = 'LiquidAI/LFM2.5-8B-A1B-AWQ'
current_model = DEFAULT_MODEL

class ModelSwitchHandler(BaseHTTPRequestHandler):
    def log_message(self, format, *args):
        # Suppress default logging
        pass
    
    def do_GET(self):
        """Handle GET requests"""
        parsed = urlparse(self.path)
        
        if parsed.path == '/models':
            # List available models
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            models = [
                {'id': name, 'name': full, 'default': full == DEFAULT_MODEL}
                for name, full in MODEL_MAPPING.items()
            ]
            response = {
                'models': models,
                'current_model': current_model
            }
            self.wfile.write(json.dumps(response).encode())
        
        elif parsed.path == '/current':
            # Get current model
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            response = {'current_model': current_model}
            self.wfile.write(json.dumps(response).encode())
        
        elif parsed.path == '/health':
            # Health check
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            response = {'status': 'healthy', 'current_model': current_model}
            self.wfile.write(json.dumps(response).encode())
        
        else:
            self.send_response(404)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            response = {'error': 'Not found'}
            self.wfile.write(json.dumps(response).encode())
    
    def do_POST(self):
        """Handle POST requests"""
        parsed = urlparse(self.path)
        
        if parsed.path == '/switch':
            # Switch model
            content_length = int(self.headers.get('Content-Length', 0))
            body = self.rfile.read(content_length)
            
            try:
                data = json.loads(body)
                model_name = data.get('model', '')
            except:
                model_name = ''
            
            # Also check query params
            if not model_name:
                query = parse_qs(parsed.query)
                model_name = query.get('model', [''])[0]
            
            # Look up full model name
            full_model = MODEL_MAPPING.get(model_name.lower(), model_name)
            
            if not full_model:
                self.send_response(400)
                self.send_header('Content-Type', 'application/json')
                self.end_headers()
                response = {'error': f'Unknown model: {model_name}'}
                self.wfile.write(json.dumps(response).encode())
                return
            
            # Switch the model
            def switch_model_thread():
                global current_model
                try:
                    # Stop the vLLM container
                    print(f"Stopping vLLM container to switch from {current_model} to {full_model}...")
                    subprocess.run(
                        ['docker', 'compose', '-f', DOCKER_COMPOSE_FILE, 'down'],
                        check=True,
                        capture_output=True
                    )
                    
                    # Update environment variable
                    env_file = '.env.vllm.dynamic'
                    with open(env_file, 'w') as f:
                        f.write(f'DEFAULT_MODEL={full_model}\n')
                    
                    # Start with new model
                    print(f"Starting vLLM with model: {full_model}")
                    subprocess.run(
                        ['docker', 'compose', '-f', DOCKER_COMPOSE_FILE, 'up', '-d'],
                        check=True,
                        capture_output=True
                    )
                    
                    # Wait for vLLM to be ready
                    print(f"Waiting for vLLM to be ready with {full_model}...")
                    time.sleep(10)
                    
                    # Verify
                    import requests
                    max_retries = 30
                    for i in range(max_retries):
                        try:
                            response = requests.get('http://localhost:8000/v1/models', timeout=5)
                            if response.status_code == 200:
                                current_model = full_model
                                print(f"Successfully switched to {full_model}")
                                return
                        except:
                            time.sleep(5)
                    
                    print(f"Warning: vLLM may not be fully ready after {max_retries * 5} seconds")
                    current_model = full_model
                    
                except Exception as e:
                    print(f"Error switching model: {e}")
            
            # Start switching in background thread
            thread = threading.Thread(target=switch_model_thread)
            thread.daemon = True
            thread.start()
            
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            response = {
                'status': 'switching',
                'from': current_model,
                'to': full_model,
                'message': 'Model switch in progress...'
            }
            self.wfile.write(json.dumps(response).encode())
        
        else:
            self.send_response(404)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            response = {'error': 'Not found'}
            self.wfile.write(json.dumps(response).encode())

def run_server():
    """Run the HTTP server"""
    server_address = (HOST, PORT)
    httpd = HTTPServer(server_address, ModelSwitchHandler)
    print(f"Model Switch Server running on http://{HOST}:{PORT}")
    print(f"Current model: {current_model}")
    print(f"Available models: {', '.join(MODEL_MAPPING.values())}")
    print("\nEndpoints:")
    print("  GET /models - List available models")
    print("  GET /current - Get current model")
    print("  POST /switch - Switch model (body: {\"model\": \"model-name\"})")
    print("  GET /health - Health check")
    print("\nTo switch model from command line:")
    print(f"  curl -X POST http://localhost:{PORT}/switch -H 'Content-Type: application/json' -d '{\"model\": \"llama3-8b\"}'")
    
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\nShutting down server...")
        httpd.shutdown()

if __name__ == '__main__':
    # Ensure .env file exists
    env_file = '.env.vllm.dynamic'
    if not os.path.exists(env_file):
        with open(env_file, 'w') as f:
            f.write(f'DEFAULT_MODEL={DEFAULT_MODEL}\n')
    
    run_server()
