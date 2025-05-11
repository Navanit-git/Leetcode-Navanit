#!/bin/bash

# GitHub repository details
REPO_OWNER="Navanit-git"
REPO_NAME="Leetcode-Navanit"
FILE_PATH="notes.json"

# Check for GitHub token in environment
if [ -z "$GITHUB_TOKEN" ]; then
    echo -e "${RED}Error: GITHUB_TOKEN environment variable is not set${NC}"
    echo -e "Please set your GitHub token first:"
    echo -e "export GITHUB_TOKEN='your_token_here'"
    exit 1
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test data
TEST_CONTENT='{
  "test-note": "This is a test note from API",
  "timestamp": "'$(date -u +"%Y-%m-%dT%H:%M:%SZ")'"
}'

echo -e "${YELLOW}Starting GitHub API Integration Test...${NC}"

# Step 1: Get the current file SHA (required for updating the file)
echo -e "\n1. Getting current file SHA..."
RESPONSE=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
  "https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/contents/$FILE_PATH")

if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to connect to GitHub API${NC}"
    exit 1
fi

# Check for API rate limiting
if echo "$RESPONSE" | grep -q "API rate limit exceeded"; then
    echo -e "${RED}Error: GitHub API rate limit exceeded${NC}"
    exit 1
fi

# Check for authentication issues
if echo "$RESPONSE" | grep -q "Bad credentials"; then
    echo -e "${RED}Error: Authentication failed - Please check your GitHub token${NC}"
    exit 1
fi

FILE_SHA=$(echo "$RESPONSE" | grep -o '"sha": "[^"]*"' | cut -d'"' -f4)

if [ -z "$FILE_SHA" ]; then
    # Try alternate format
    FILE_SHA=$(echo "$RESPONSE" | grep -o '"sha":"[^"]*"' | cut -d'"' -f3)
fi

if [ -z "$FILE_SHA" ]; then
    echo -e "${RED}Failed to get file SHA - Response:${NC}"
    echo "$RESPONSE"
    exit 1
fi

echo -e "${GREEN}Successfully got SHA: $FILE_SHA${NC}"

# Step 2: Create the update request
echo -e "\n2. Attempting to update file..."

# Base64 encode the content properly
ENCODED_CONTENT=$(echo -n "$TEST_CONTENT" | base64 -w 0)

UPDATE_RESPONSE=$(curl -s -X PUT \
  -H "Authorization: token $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github.v3+json" \
  "https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/contents/$FILE_PATH" \
  -d @- << EOF
{
  "message": "Test API update",
  "content": "$ENCODED_CONTENT",
  "sha": "$FILE_SHA"
}
EOF
)

# Check if the update was successful
if echo "$UPDATE_RESPONSE" | grep -q '"content":'; then
    echo -e "${GREEN}✓ API Test Successful!${NC}"
    echo -e "\nFile URL: $(echo "$UPDATE_RESPONSE" | grep -o '"html_url": "[^"]*"' | cut -d'"' -f4)"
else
    echo -e "${RED}✗ API Test Failed${NC}"
    echo "Error response from GitHub API:"
    echo "$UPDATE_RESPONSE"
fi
