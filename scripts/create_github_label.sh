
#!/bin/bash

starting_dir=$(pwd)

tsv_file="report.tsv"
header_skipped=true
while IFS=$'\t' read -r issue status type; do
    if [ "$header_skipped" = true ]; then
        header_skipped=false
        continue
    fi
    cd /mnt/c/Users/ftw712/Desktop/scripts/shell/bb/backbone-feedback
    status=${status//\"/}  # Unquote the status variable
    issue=${issue//\"/}  # Unquote the issue variable
    echo $status
    echo $issue
    # remove all previous labels 
    gh issue edit $issue --remove-label 'autocheck - issue open on xRelease'
    gh issue edit $issue --remove-label 'autocheck - issue closed on xRelease'
    gh issue edit $issue --remove-label 'autocheck - status unknown on xRelease'
    
    if [ "$status" = "ISSUE_CLOSED" ]; then
        echo "closed issue"   
        gh issue edit $issue --add-label 'autocheck - issue closed on xRelease'
    fi
    if [ "$status" = "ISSUE_OPEN" ]; then
        echo "open issue"
        gh issue edit $issue --add-label 'autocheck - issue open on xRelease'
    fi
    if [ "$status" = "JSON-TAG-ERROR" ]; then
        echo "error issue"
        gh issue edit $issue --add-label 'autocheck - status unknown on xRelease'
    fi

    cd "$starting_dir"

done < "$tsv_file"

# gh issue edit $issue --add-label "autocheck - closed on xRelease"
# gh issue edit $issue --add-label "autocheck - open on xRelease"
cd "$starting_dir"


# cd /mnt/c/Users/ftw712/Desktop/scripts/shell/bb/backbone-feedback
# gh issue edit $issue --add-label "occurrenceID - large change in record counts"
# cd "$starting_dir"

# issue=$(gh issue list --search "is:issue is:open label:$uuid"|
# awk '{print $1}')
# cd "$starting_dir"



