#!/bin/bash

file_to_check="$(Rscript xrelease_ver.R).tsv"

# Check if the file exists in the report archive
if [ -f "$file_to_check" ]; then
    echo "File '$file_to_check' exists in report-archive."
else
    echo "File '$file_to_check' does not exist in report-archive."
    cp "report.tsv" "report-archive/$file_to_check"
fi





