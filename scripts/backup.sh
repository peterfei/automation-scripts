#!/bin/bash

# Simple backup script
# Usage: ./backup.sh <source_dir> <destination_dir>

SOURCE_DIR=$1
DEST_DIR=$2

if [ -z "$SOURCE_DIR" ] || [ -z "$DEST_DIR" ]; then
    echo "Usage: $0 <source_directory> <destination_directory>"
    exit 1
fi

if [ ! -d "$SOURCE_DIR" ]; then
    echo "Source directory does not exist: $SOURCE_DIR"
    exit 1
fi

mkdir -p "$DEST_DIR"

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="backup_$TIMESTAMP.tar.gz"

echo "Creating backup: $BACKUP_NAME"
tar -czf "$DEST_DIR/$BACKUP_NAME" -C "$SOURCE_DIR" .

echo "Backup completed: $DEST_DIR/$BACKUP_NAME"
