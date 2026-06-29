#!/bin/bash

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Install the latest version of gbifbf package from source
echo "Installing gbifbf package from source..."
Rscript -e 'install.packages("./gbifbf", repos = NULL, type = "source")'

# Parse command-line options
ISSUE_STATE="open"
REPORT_FILE="report.tsv"

while [[ $# -gt 0 ]]; do
    case $1 in
        --closed)
            ISSUE_STATE="closed"
            REPORT_FILE="report-closed.tsv"
            shift
            ;;
        [0-9]*)
            # Numeric argument is an issue number
            SINGLE_ISSUE="$1"
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--closed] [issue_number]"
            exit 1
            ;;
    esac
done

# Check if issue number is provided as command-line argument
if [ -n "$SINGLE_ISSUE" ]; then
    echo "Processing single issue: $SINGLE_ISSUE"
    issue_array=("$SINGLE_ISSUE")
else
    # Fetch issues based on state
    echo "Fetching all $ISSUE_STATE issues from project..."
    issues=$(gh issue list --search "is:issue is:$ISSUE_STATE project:gbif/23" --json number --jq '.[].number' --limit 500)
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
        Rscript process_json.R "$COMMENT_BODY" "$issue" "$REPORT_FILE"
    else
        echo "No processable JSON comments found for issue $issue (may have unchecked checkbox)"
    fi
done






