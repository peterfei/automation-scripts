#!/bin/bash

# Batch rename files in a directory
# Usage: ./batch_rename.sh <directory> <old_pattern> <new_pattern>

DIR=$1
OLD_PATTERN=$2
NEW_PATTERN=$3

if [ -z "$DIR" ] || [ -z "$OLD_PATTERN" ] || [ -z "$NEW_PATTERN" ]; then
    echo "Usage: $0 <directory> <old_pattern> <new_pattern>"
    exit 1
fi

if [ ! -d "$DIR" ]; then
    echo "Directory does not exist: $DIR"
    exit 1
fi

cd "$DIR"

for file in *"$OLD_PATTERN"*; do
    if [ -f "$file" ]; then
        new_name="${file//$OLD_PATTERN/$NEW_PATTERN}"
        mv "$file" "$new_name"
        echo "Renamed: $file -> $new_name"
    fi
done

echo "Batch rename completed."
