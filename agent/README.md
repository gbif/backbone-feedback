# Backbone Feedback JSON Tag Agent

An OpenAI-powered agent that converts plain English backbone feedback issues into structured JSON tags for automation.

## Overview

This agent uses the OpenAI SDK and the Catalogue of Life (COL) API to:
- Parse natural language descriptions of taxonomic issues
- Validate taxonomic names against the COL database
- Generate structured JSON tags following the [GBIF Backbone Feedback automation schema](https://github.com/gbif/backbone-feedback/wiki/JSON-comments-for-automation-%E2%80%90-Experimental)

## Features

- **Name Validation**: Automatically validates all taxonomic names using COL API before including them in output
- **Smart Normalization**: Uses the `label` field from COL API to ensure consistent naming
- **Six JSON Tag Types**:
  1. `wrongRank` - Incorrect taxonomic rank
  2. `badName` - Invalid name that shouldn't exist
  3. `missingName` - Valid name that's missing from database
  4. `nameChange` - Name should be changed
  5. `wrongGroup` - Wrong higher classification
  6. `synIssue` - Synonym relationship problem

## Setup

### Prerequisites

```bash
pip install openai requests
```

### Environment Variables

Set the following environment variables:

```bash
# Required for OpenAI
export OPENAI_API_KEY="your-openai-api-key"

# Required for COL API authentication
export GBIF_USER="your-gbif-username"
export GBIF_PWD="your-gbif-password"
```

On Windows PowerShell:
```powershell
$env:OPENAI_API_KEY="your-openai-api-key"
$env:GBIF_USER="your-gbif-username"
$env:GBIF_PWD="your-gbif-password"
```

## Usage

### Command Line (Recommended)

The easiest way to use the agent is via the CLI tool:

```bash
# Simple usage - text as argument
python cli.py "Amphibia is under Plantae but should be under Animalia"

# Verbose mode - see agent reasoning
python cli.py --verbose "Anthocoridea is a misspelling"
python cli.py -v "Anthocoridea is a misspelling"

# From file
python cli.py --file issue.txt

# From stdin (pipe)
echo "Your issue text" | python cli.py
cat issue.txt | python cli.py

# Interactive mode
python cli.py
# (then type/paste your text, press Ctrl+D or Ctrl+Z when done)

# Save output to file
python cli.py "Your issue" > output.json
```

### Interactive Examples

Run through example scenarios:

```bash
python examples.py
```

### Programmatic Usage

```python
from backbone_json_agent import generate_json_tags

# Simple usage
issue = "Amphibia is currently placed under Plantae but it should be under Animalia"
json_output = generate_json_tags(issue)
print(json_output)

# Verbose mode (see API calls and agent reasoning)
json_output = generate_json_tags(issue, verbose=True)
```

## Examples

### Example 1: Wrong Group
**Input:**
```
Amphibia is currently placed under Plantae but it should be under Animalia
```

**Output:**
```json
{
  "name": "Amphibia",
  "wrongGroup": "Plantae",
  "rightGroup": "Animalia"
}
```

### Example 2: Synonym Issue
**Input:**
```
The species Agrion splendens is marked as ACCEPTED but it should be a SYNONYM of Calopteryx splendens
```

**Output:**
```json
{
  "name": "Agrion splendens",
  "wrongStatus": "ACCEPTED",
  "rightStatus": "SYNONYM",
  "rightParent": "Calopteryx splendens"
}
```

### Example 3: Bad Name
**Input:**
```
The name 'Dog dog Waller 2025' should not exist in the database
```

**Output:**
```json
{
  "badName": "Dog dog Waller 2025"
}
```

### Example 4: Name Change
**Input:**
```
The name Cryptophyta should be changed to Cryptista Cavalier-Smith, 1989
```

**Output:**
```json
{
  "currentName": "Cryptophyta",
  "proposedName": "Cryptista Cavalier-Smith, 1989"
}
```

## How It Works

1. **Issue Parsing**: The agent analyzes the plain English input to understand the type of issue
2. **Name Extraction**: Identifies all taxonomic names mentioned in the issue
3. **COL API Validation**: Calls `col_api_match` for each name to verify it exists in the database
4. **JSON Generation**: Creates the appropriate JSON tag structure with validated names
5. **Output**: Returns pure JSON (no markdown or extra text)

## API Reference

### COL API

The agent uses the Catalogue of Life API v3LR (COL Checklist):
- **Base URL**: `https://api.checklistbank.org/dataset/3LXRC`
- **Match Endpoint**: `/match/nameusage?q=<name>`
- **Authentication**: Basic auth using GBIF credentials

### Functions

#### `col_api_match(query: str) -> Dict[str, Any]`
Validates and normalizes a taxonomic name using COL API.

#### `generate_json_tags(user_issue: str, verbose: bool = False) -> str`
Main function that converts plain English to JSON tags.

## Architecture

The agent uses OpenAI's function calling (tools) to:
1. Receive natural language input
2. Autonomously call the COL API validation tool
3. Use validated data to construct JSON output
4. Iterate until it has verified all names and generated correct JSON

## Limitations

- Maximum 10 iterations per request
- Requires valid GBIF credentials for COL API access
- Only generates the 6 predefined JSON tag types
- Names must exist in COL database (3LR version) for validation

## Troubleshooting

**Error: "OPENAI_API_KEY environment variable not set"**
- Set your OpenAI API key in environment variables

**Warning: "GBIF_USER and/or GBIF_PWD not set"**
- COL API requires authentication; set GBIF credentials

**Agent outputs non-JSON text**
- The model occasionally adds explanatory text; the system prompt instructs against this, but you may need to parse the JSON from the response

## References

- [GBIF Backbone Feedback JSON Tags](https://github.com/gbif/backbone-feedback/wiki/JSON-comments-for-automation-%E2%80%90-Experimental)
- [Catalogue of Life API](https://www.checklistbank.org/)
- [OpenAI Function Calling](https://platform.openai.com/docs/guides/function-calling)
