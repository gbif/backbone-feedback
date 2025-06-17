#!/bin/bash

# Check if issue argument is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <issue_number>"
    exit 1
fi

issue=$1

echo "Processing issue: $issue"
COMMENTS=$(curl -H "Authorization: token $GH_TOKEN" -H "Accept: application/vnd.github.v3+json" https://api.github.com/repos/gbif/backbone-feedback/issues/$issue/comments)
echo $COMMENTS

if [ -z "$COMMENTS" ]; then
    echo "Error: No comments received for issue $issue"
    continue
fi

if ! echo "$COMMENTS" | jq empty; then
    echo "Error: Invalid JSON received for issue $issue"
    continue
fi

JSON=$(echo "$COMMENTS" | jq '.[] | select(.body | contains("// json for auto-checking")) | {body}')
COMMENT_BODY=$(echo "$JSON" | jq '.body')
echo $COMMENT_BODY
Rscript process_json.R "$COMMENT_BODY" "$issue"






