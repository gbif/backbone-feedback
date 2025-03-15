#!/bin/bash

# current_dir=$(pwd)
# cd /mnt/c/Users/ftw712/Desktop/scripts/shell/bb/backbone-feedback/

# gh issue list  --search "is:issue is:open project:gbif/23"

issues=$(gh issue list --search "is:issue is:open project:gbif/23" --json number --jq '.[].number' --limit 500)

echo $issues

for issue in $issues; do
    issue_array+=("$issue")
done

for issue in "${issue_array[@]}"
do
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
done






