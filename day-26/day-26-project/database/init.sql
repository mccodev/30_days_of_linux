CREATE TABLE IF NOT EXISTS processed_posts (
    id INTEGER PRIMARY KEY,
    userId INTEGER,
    title TEXT,
    body TEXT,
    title_length INTEGER,
    word_count INTEGER,
    processed_at TIMESTAMP
);

CREATE TABLE IF NOT EXISTS user_summary (
    userId INTEGER PRIMARY KEY,
    avg_title_length REAL,
    avg_word_count REAL,
    post_count INTEGER,
    updated_at TIMESTAMP
);
