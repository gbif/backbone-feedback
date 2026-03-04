#!/bin/bash

# current_dir=$(pwd)
# cd /mnt/c/Users/ftw712/Desktop/scripts/shell/bb/backbone-feedback/

# Check if issue number is provided as command-line argument
if [ -n "$1" ]; then
    echo "Processing single issue: $1"
    issue_array=("$1")
else
    # gh issue list  --search "is:issue is:open project:gbif/23"
    echo "Fetching all open issues from project..."
    issues=$(gh issue list --search "is:issue is:open project:gbif/23" --json number --jq '.[].number' --limit 500)
    echo $issues
    
    for issue in $issues; do
        issue_array+=("$issue")
    done
fi

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
    
    # Process comments with "// json for auto-checking" UNLESS they have an unchecked checkbox
    # Skip ONLY if checkbox is explicitly unchecked: "- [ ] **Accept AI suggestion**"
    # Process if: (1) checkbox is checked, OR (2) no checkbox exists (legacy comments)
    JSON=$(echo "$COMMENTS" | jq '.[] | select(.body | contains("// json for auto-checking") and (contains("- [ ] **Accept AI suggestion**") | not)) | {body}')
    COMMENT_BODY=$(echo "$JSON" | jq '.body')
    echo $COMMENT_BODY
    if [ "$COMMENT_BODY" != "null" ] && [ -n "$COMMENT_BODY" ]; then
        Rscript process_json.R "$COMMENT_BODY" "$issue"
    else
        echo "No processable JSON comments found for issue $issue (may have unchecked checkbox)"
    fi
done






