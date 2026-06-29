# gbifbf

GBIF Backbone Feedback Tools - R package for checking and processing GBIF backbone feedback issues.

## Installation

You can install the development version from GitHub:

```r
# install.packages("devtools")
devtools::install_github("gbif/backbone-feedback", subdir = "gbifbf")
```

## Features

- Query the ChecklistBank API for taxonomic information
- Validate taxonomic ranks
- Process JSON tags from GitHub issues
- Automated issue status checking

## Functions

- `cb_name_usage()`: Query ChecklistBank API for name usage information
- `cb_name_usage_search()`: Search ChecklistBank for taxonomic information
- `wrong_rank()`: Check if a taxon has the correct rank
- `strip_html()`: Helper function to remove HTML tags

## Usage

```r
library(gbifbf)

# Query a taxon
result <- cb_name_usage(q = "Animalia")

# Check rank
status <- wrong_rank(list(
  name = "Animalia",
  wrongRank = "phylum",
  rightRank = "kingdom"
))
```
