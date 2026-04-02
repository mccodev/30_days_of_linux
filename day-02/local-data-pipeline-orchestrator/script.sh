#!/bin/bash

# Setting up folders
mkdir -p data/raw data/staging data/processed data/backups

# Generating dummy data
touch data/raw/data1.csv data/raw/data2.csv data/raw/error.log

# 3. Organize
mv data/raw/*.csv data/staging/
rm data/raw/*.log

# 4. Create a shortcut for the admin
ln -s $(pwd)/data/processed $(pwd)/latest_results

echo "Pipeline complete!"