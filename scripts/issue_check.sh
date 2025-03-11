#!/bin/bash

# current_dir=$(pwd)
# cd /mnt/c/Users/ftw712/Desktop/scripts/shell/bb/backbone-feedback/

# gh issue list  --search "is:issue is:open project:gbif/23"

issues=$(gh issue list --search "is:issue is:open project:gbif/23" --json number --jq '.[].number' --limit 500)

echo $issues

# cd $current_dir

for issue in $issues; do
    issue_array+=("$issue")
done

# IFS=' ' read -r -a issue_array <<< "$issues"
# issue_array=(506 505 504 503 502 501 500 499 498 496)

for issue in "${issue_array[@]}"
do
    echo "$issue"
done

for issue in "${issue_array[@]}"
do
    echo "Processing issue: $issue"
    COMMENTS=$(curl -H "Authorization: token $GH_TOKEN" -H "Accept: application/vnd.github.v3+json" https://api.github.com/repos/gbif/backbone-feedback/issues/$issue/comments)
    
    if ! echo "$COMMENTS" | jq empty; then
        echo "Error: Invalid JSON received for issue $issue"
        continue
    fi
    
    JSON=$(echo "$COMMENTS" | jq '.[] | select(.body | contains("// json for auto-checking")) | {body}')
    COMMENT_BODY=$(echo "$JSON" | jq '.body')
    echo $COMMENT_BODY
    Rscript scripts/process_json.R "$COMMENT_BODY" "$issue"
done






