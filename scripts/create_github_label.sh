
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
 
    echo $status
    echo $issue

    # remove all previous labels 
    gh issue edit $issue --remove-label 'autocheck - issue open on xRelease'
    gh issue edit $issue --remove-label 'autocheck - issue closed on xRelease'
    gh issue edit $issue --remove-label 'autocheck - status unclear on xRelease'
    
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
        gh issue edit $issue --add-label 'autocheck - status unclear on xRelease'
    fi

done < "$tsv_file"




