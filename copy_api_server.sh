#!/bin/bash

# Script to copy only necessary API server files to app bundle
# This excludes node_modules to avoid conflicts

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SRC_DIR="$SCRIPT_DIR/AgentText/APIServer"
DEST_DIR="${BUILT_PRODUCTS_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/APIServer"

echo "Copying API server files (excluding node_modules)..."

# Create destination directory
mkdir -p "$DEST_DIR"

# Copy necessary files only
cp "$SRC_DIR/api-server.ts" "$DEST_DIR/" 2>/dev/null || true
cp "$SRC_DIR/api-types.ts" "$DEST_DIR/" 2>/dev/null || true
cp "$SRC_DIR/package.json" "$DEST_DIR/" 2>/dev/null || true
cp "$SRC_DIR/tsconfig.json" "$DEST_DIR/" 2>/dev/null || true

# Copy src directory
cp -R "$SRC_DIR/src" "$DEST_DIR/" 2>/dev/null || true

# Copy node_modules
cp -R "$SRC_DIR/node_modules" "$DEST_DIR/" 2>/dev/null || true

echo "API server files copied successfully"
