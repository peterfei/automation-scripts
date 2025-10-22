#!/bin/bash

# System cleanup script
# Usage: ./cleanup.sh

echo "Cleaning up temporary files..."

# Remove .DS_Store files on macOS
find . -name ".DS_Store" -type f -delete

# Remove __pycache__ directories
find . -name "__pycache__" -type d -exec rm -rf {} +

# Remove .log files older than 7 days
find . -name "*.log" -type f -mtime +7 -delete

# Empty trash on macOS (optional)
# osascript -e 'tell app "Finder" to empty'

echo "Cleanup completed."
