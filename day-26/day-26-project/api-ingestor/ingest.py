import requests
import json
import csv
import os
from datetime import datetime

def fetch_data():
    url = "https://jsonplaceholder.typicode.com/posts"
    response = requests.get(url)
    return response.json()

def save_to_csv(data, filename):
    with open(filename, 'w', newline='') as csvfile:
        writer = csv.writer(csvfile)
        writer.writerow(['id', 'userId', 'title', 'body'])
        for post in data:
            writer.writerow([post['id'], post['userId'], post['title'], post['body']])

if __name__ == "__main__":
    data = fetch_data()
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = f"/data/raw/posts_{timestamp}.csv"
    os.makedirs(os.path.dirname(filename), exist_ok=True)
    save_to_csv(data, filename)
    print(f"Data saved to {filename}")
