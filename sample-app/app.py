# sample-app/app.py
from flask import Flask, jsonify
import os

app = Flask(__name__)

@app.route('/health')
def health():
    return jsonify({
        'status': 'healthy',
        'environment': os.environ.get('ENVIRONMENT', 'unknown')
    })

@app.route('/')
def hello():
    return jsonify({
        'message': 'Container Security Pipeline Demo',
        'version': '1.0.0',
        'security_features': [
            'Image scanning with Trivy',
            'Running as non-root user',
            'Read-only filesystem',
            'Dropped capabilities',
            'Encrypted ECR registry'
        ]
    })

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)


# sample-app/requirements.txt
Flask==3.0.0
Werkzeug==3.0.1
