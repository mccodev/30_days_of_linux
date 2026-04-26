import pandas as pd
import glob
import os
from datetime import datetime

def process_csv(input_file):
    df = pd.read_csv(input_file)
    
    # Data cleaning and transformation
    df['title_length'] = df['title'].str.len()
    df['word_count'] = df['body'].str.split().str.len()
    df['processed_at'] = datetime.now()
    
    # Filter and aggregate
    processed = df[df['title_length'] > 10]
    summary = processed.groupby('userId').agg({
        'title_length': 'mean',
        'word_count': 'mean',
        'id': 'count'
    }).reset_index()
    
    return processed, summary

def main():
    files = glob.glob('/data/raw/*.csv')
    if not files:
        print("No data files found")
        return
    
    latest_file = max(files)
    print(f"Processing {latest_file}")
    
    processed_data, summary = process_csv(latest_file)
    
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    processed_file = f"/data/processed/processed_{timestamp}.csv"
    summary_file = f"/data/processed/summary_{timestamp}.csv"
    
    os.makedirs(os.path.dirname(processed_file), exist_ok=True)
    processed_data.to_csv(processed_file, index=False)
    summary.to_csv(summary_file, index=False)
    
    print(f"Processed data saved to {processed_file}")
    print(f"Summary saved to {summary_file}")

if __name__ == "__main__":
    main()
