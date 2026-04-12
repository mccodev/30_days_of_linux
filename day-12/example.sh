#!/bin/bash


# Batch transform files using find + xargs

# This script demonstrates how to locate 50 files and execute an 
# in-place replacement (transform) using sed.
# 
# Example scenario: 
# We want to change the column header "STATUS" to "ACCOUNT_STATUS"
# in all the .csv files inside the data/ directory.


# 1. 'find' locates all files ending in .csv within the data/ directory.
# 2. '-print0' sends the file paths separated by a null character (safe for spaces).
# 3. 'xargs -0' correctly reads the null-separated paths as individual arguments.
# 4. 'sed -i' performs the text substitution directly within those files.

find ./data -type f -name "*.csv" -print0 | xargs -0 sed -i 's/STATUS/ACCOUNT_STATUS/g'

echo "Transformation complete! All 'STATUS' headers have been changed to 'ACCOUNT_STATUS'."


# ALTERNATIVE (Using the -I placeholder):
# If your command doesn't natively accept a list of files piled onto 
# the end of it (like 'cp' or custom scripts), you can use -I {} 
# to explicitly define where to place the file name:
#
# find ./data -name "*.csv" | xargs -I {} cp {} /tmp/backup_dir/

