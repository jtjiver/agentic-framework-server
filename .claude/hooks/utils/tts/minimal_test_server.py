#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.8"
# dependencies = [
#     "flask",
# ]
# ///

from flask import Flask, jsonify

app = Flask(__name__)

@app.route('/health', methods=['GET'])
def health():
    return jsonify({"status": "ok"})

@app.route('/test', methods=['POST'])
def test():
    return jsonify({"message": "test received"})

if __name__ == '__main__':
    print("Minimal test server starting...")
    app.run(host='127.0.0.1', port=5556, debug=False)