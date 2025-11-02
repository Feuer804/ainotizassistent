#!/bin/bash

GITHUB_TOKEN="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"
REPO="Feuer804/ainotizassistent"
FILE_PATH=".github/workflows/build-macos.yml"
BRANCH="main"

# Get current file SHA
echo "Fetching current file SHA..."
RESPONSE=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
  "https://api.github.com/repos/$REPO/contents/$FILE_PATH?ref=$BRANCH")

SHA=$(echo "$RESPONSE" | grep -o '"sha": "[^"]*"' | head -1 | cut -d'"' -f4)

if [ -z "$SHA" ]; then
  echo "Error: Could not get file SHA"
  echo "$RESPONSE"
  exit 1
fi

echo "Current SHA: $SHA"

# Read the corrected workflow content
CONTENT=$(cat /workspace/final_working_workflow.yml | base64 -w 0)

# Update the file
echo "Updating workflow file..."
curl -X PUT \
  -H "Authorization: token $GITHUB_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"message\": \"FIX: Remove unsupported -listSchemes option for Xcode 15.0\",
    \"content\": \"$CONTENT\",
    \"sha\": \"$SHA\",
    \"branch\": \"$BRANCH\"
  }" \
  "https://api.github.com/repos/$REPO/contents/$FILE_PATH"

echo ""
echo "Update complete!"
