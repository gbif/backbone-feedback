
#!/bin/bash

tsv_file="report.tsv"
header_skipped=true
while IFS=$'\t' read -r issue status type; do
    if [ "$header_skipped" = true ]; then
        header_skipped=false
        continue
    fi
 
    status=${status//\"/}  # Unquote the status variable
    issue=${issue//\"/}  # Unquote the issue variable
 
    echo "issue num from tsv: $issue"
    echo "issue status from tsv: $status"

    if [ "$status" = "ISSUE_CLOSED" ]; then
    update_label="autocheck - issue closed on xRelease"
    fi
    if [ "$status" = "ISSUE_OPEN" ]; then
    update_label="autocheck - issue open on xRelease"
    fi
    if [ "$status" = "JSON-TAG-ERROR" ]; then
    update_label="autocheck - status unclear on xRelease"
    fi

    echo "Update label: $update_label"

    labels=$(gh issue view "$issue" --json labels --jq '.labels[].name')
    
    current_label="" 
    if [ -z "$current_label" ]; then
    current_label=$(echo "$labels" | grep -qF "autocheck - status open on xRelease" && echo "autocheck - status open on xRelease" || echo "")
    fi 
    if [ -z "$current_label" ]; then
    current_label=$(echo "$labels" | grep -qF "autocheck - issue closed on xRelease" && echo "autocheck - issue closed on xRelease" || echo "")
    fi 
    if [ -z "$current_label" ]; then
    current_label=$(echo "$labels" | grep -qF "autocheck - status unclear on xRelease" && echo "autocheck - status unclear on xRelease" || echo "")
    fi 
    echo "Current label: $current_label"

    if [ "$current_label" = "$update_label" ]; then
    echo "No change in label required for issue #$issue"
    continue
    fi

    # if the label needs to changed 
    gh issue edit $issue --remove-label 'autocheck - issue open on xRelease'
    gh issue edit $issue --remove-label 'autocheck - issue closed on xRelease'
    gh issue edit $issue --remove-label 'autocheck - status unclear on xRelease'
    
    if [ "$status" = "ISSUE_CLOSED" ]; then
        echo "updating label to: autocheck - issue closed on xRelease"   
        gh issue edit $issue --add-label 'autocheck - issue closed on xRelease'
    fi
    if [ "$status" = "ISSUE_OPEN" ]; then
        echo "updating label to: autocheck - issue open on xRelease"
        gh issue edit $issue --add-label 'autocheck - issue open on xRelease'
    fi
    if [ "$status" = "JSON-TAG-ERROR" ]; then
        echo "updating label to: autocheck - status unclear on xRelease"
        gh issue edit $issue --add-label 'autocheck - status unclear on xRelease'
    fi

done < "$tsv_file"




