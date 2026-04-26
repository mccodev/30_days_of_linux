import requests
import time
import json
from datetime import datetime

def check_service_health():
    services = {
        'api-ingestor': 'http://api-ingestor:8000/health',
        'data-processor': 'http://data-processor:8001/health',
        'web-api': 'http://web-api:5000/health',
        'database': 'http://web-api:5000/db-health'
    }

    while True:
        timestamp = datetime.now().isoformat()
        status_report = {"timestamp": timestamp, "services": {}}

        for service, url in services.items():
            try:
                response = requests.get(url, timeout=5)
                status = "healthy" if response.status_code == 200 else "unhealthy"
            except Exception as e:
                status = f"error: {str(e)}"

            status_report["services"][service] = status

        print(json.dumps(status_report, indent=2))
        time.sleep(30)

if __name__ == "__main__":
    check_service_health()
