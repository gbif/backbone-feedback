# Setup Script for Backbone Feedback JSON Agent

## Quick Setup Guide

### 1. Install Python Dependencies

```bash
pip install -r requirements.txt
```

### 2. Set Environment Variables

#### On Linux/Mac:

```bash
export OPENAI_API_KEY="your-openai-api-key"
export GBIF_USER="your-gbif-username"
export GBIF_PWD="your-gbif-password"
```

Add to `~/.bashrc` or `~/.zshrc` for persistence:

```bash
echo 'export OPENAI_API_KEY="your-key"' >> ~/.bashrc
echo 'export GBIF_USER="your-username"' >> ~/.bashrc
echo 'export GBIF_PWD="your-password"' >> ~/.bashrc
source ~/.bashrc
```

#### On Windows PowerShell:

```powershell
$env:OPENAI_API_KEY="your-openai-api-key"
$env:GBIF_USER="your-gbif-username"
$env:GBIF_PWD="your-gbif-password"
```

For persistence, use System Environment Variables:
1. Search "Environment Variables" in Windows
2. Click "Environment Variables" button
3. Add new User or System variables

Or use PowerShell profile:

```powershell
# Open profile
notepad $PROFILE

# Add these lines:
$env:OPENAI_API_KEY="your-key"
$env:GBIF_USER="your-username"
$env:GBIF_PWD="your-password"
```

### 3. Verify Setup

```bash
python -c "import os; print('OPENAI_API_KEY:', 'SET' if os.getenv('OPENAI_API_KEY') else 'NOT SET')"
python -c "import os; print('GBIF_USER:', 'SET' if os.getenv('GBIF_USER') else 'NOT SET')"
python -c "import os; print('GBIF_PWD:', 'SET' if os.getenv('GBIF_PWD') else 'NOT SET')"
```

### 4. Test the Agent

```bash
# Command line (simple)
python cli.py "Amphibia is under Plantae but should be under Animalia"

# Command line (verbose)
python cli.py --verbose "Your issue text"

# Run interactive examples
python examples.py

# Interactive mode
python backbone_json_agent.py
```

## Getting API Keys

### OpenAI API Key

1. Go to https://platform.openai.com/api-keys
2. Sign in or create an account
3. Click "Create new secret key"
4. Copy the key (starts with `sk-`)
5. Set as `OPENAI_API_KEY` environment variable

**Note:** OpenAI API usage is paid. Check pricing at https://openai.com/api/pricing/

### GBIF Credentials

1. Go to https://www.gbif.org/
2. Create an account or sign in
3. Use your username and password as `GBIF_USER` and `GBIF_PWD`

## Usage Examples

### Single Issue (Interactive)

```bash
python backbone_json_agent.py
```

### Single Issue (Programmatic)

```python
from backbone_json_agent import generate_json_tags

issue = "Amphibia is under Plantae but should be under Animalia"
result = generate_json_tags(issue)
print(result)
```

### Process Multiple Issues

Create a text file with issues, one per line or separated by blank lines:

```bash
# Process file and save output
while IFS= read -r line; do
  echo "$line" | python cli.py >> all_results.json
done < my_issues.txt

# Or use the sample file
python cli.py --file sample_issues.txt
```

### Integration with R

```r
# Generate JSON from Python
issue <- "Amphibia is under Plantae but should be under Animalia"
writeLines(issue, "temp_issue.txt")
system("python backbone_json_agent.py < temp_issue.txt > temp_output.json")

# Parse in R
tags <- jsonlite::fromJSON("temp_output.json")

# Validate with existing functions
source("check_functions_cb.R")
if(!is.null(tags$wrongGroup)) {
  result <- wrong_group(tags)
  print(paste("Status:", result))
}
```

## Troubleshooting

### Import Error: No module named 'openai'

```bash
pip install --upgrade openai
```

### Import Error: No module named 'requests'

```bash
pip install --upgrade requests
```

### Authentication Error with COL API

- Verify GBIF credentials are correct
- Try logging in at https://www.gbif.org/
- Check if your account is active

### OpenAI API Error: Invalid API Key

- Verify your API key starts with `sk-`
- Check if key is active at https://platform.openai.com/api-keys
- Regenerate key if needed

### Rate Limiting

If you hit rate limits:
- Add delays between batch processing
- Upgrade your OpenAI plan
- Contact OpenAI support

## Files

- `backbone_json_agent.py` - Main agent implementation
- `cli.py` - Command-line interface (recommended)
- `examples.py` - Interactive example demonstrations
- `sample_issues.txt` - Sample issues for testing
- `requirements.txt` - Python dependencies
- `README.md` - Comprehensive documentation

## Support

For issues related to:
- **Agent functionality**: Check AGENT_README.md
- **JSON tag validation**: See check_functions_cb.R and tests/
- **COL API**: https://api.checklistbank.org/
- **OpenAI**: https://platform.openai.com/docs
- **GBIF**: https://www.gbif.org/
