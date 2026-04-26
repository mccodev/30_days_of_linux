from flask import Flask, jsonify
import sqlite3
import os

app = Flask(__name__)

def get_db_connection():
    conn = sqlite3.connect('/data/pipeline.db')
    return conn

@app.route('/health')
def health():
    return jsonify({"status": "healthy", "service": "web-api"})

@app.route('/posts')
def get_posts():
    conn = get_db_connection()
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()
    
    cursor.execute("SELECT * FROM processed_posts ORDER BY processed_at DESC LIMIT 100")
    posts = [dict(row) for row in cursor.fetchall()]
    
    conn.close()
    return jsonify(posts)

@app.route('/summary')
def get_summary():
    conn = get_db_connection()
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()
    
    cursor.execute("SELECT * FROM user_summary ORDER BY updated_at DESC")
    summary = [dict(row) for row in cursor.fetchall()]
    
    conn.close()
    return jsonify(summary)

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=5000)
