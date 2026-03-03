# GitHub Actions for AI-Generated JSON Tags

This directory contains GitHub Actions workflows and scripts that automatically generate JSON tags for backbone feedback issues using the OpenAI agent.

## Workflow: `ai-generate-tags.yml`

### What it does

1. **Triggers** on new or reopened issues
2. **Checks** if the issue already has the `ai-checked` label (skips if yes)
3. **Analyzes** the issue title and body using the OpenAI agent
4. **Generates** JSON tags based on the COL API validation
5. **Posts** the tags as a comment on the issue
6. **Adds** the `ai-checked` label to mark it as processed

### Triggers

- **Automatic**: When an issue is opened or reopened
- **Manual**: Can be triggered via workflow_dispatch for any specific issue

### Prerequisites

The following secrets must be set in the repository settings:

- `OPENAI_API_KEY` - Your OpenAI API key
- `GBIF_USER` - GBIF username for COL API authentication
- `GBIF_PWD` - GBIF password for COL API authentication

### Example Output

When an issue is processed, the bot will post a comment like:

```markdown
## 🤖 AI-Generated JSON Tags

The OpenAI agent has analyzed this issue and generated the following JSON tags:

```json
{
  "badName": "Cercopida"
}
```

### What's next?

1. **Review** the generated tags for accuracy
2. **Copy** the JSON if correct and add it as a code comment in your issue
3. **Edit** your issue if the tags seem incorrect

...
```

### Labels

- **ai-checked** (green): Automatically added after processing to prevent re-processing

### Configuration

To exclude issues from processing:
- The workflow skips issues that already have the `ai-checked` label
- For issues in specific projects, they can be manually labeled before triggering

### Manual Trigger

To manually run the agent on a specific issue:

1. Go to Actions → AI-Generate JSON Tags for Issues
2. Click "Run workflow"
3. Enter the issue number
4. Click "Run workflow"

## Scripts

### `process_issue.py`

Helper script that:
- Checks if an issue should be processed
- Validates against project membership
- Generates JSON tags using the agent
- Formats output for GitHub Actions

## Development

To test the workflow locally:

```bash
# Set environment variables
export OPENAI_API_KEY="your-key"
export GBIF_USER="your-username"
export GBIF_PWD="your-password"
export ISSUE_TITLE="Test issue"
export ISSUE_BODY="Cercopida is a misspelling of Cercopidae"

# Run the generation
cd agent
python cli.py "$ISSUE_TITLE $ISSUE_BODY"
```

## Workflow Diagram

```
Issue Opened/Reopened
  ↓
Check for ai-checked label
  ↓ (not found)
Get issue title & body
  ↓
Generate JSON tags (OpenAI + COL API)
  ↓
Post comment with tags
  ↓
Add ai-checked label
```

## Troubleshooting

### Workflow not running

- Check that the workflow file is in `.github/workflows/`
- Verify repository secrets are set correctly
- Check Actions tab for error messages

### Invalid JSON generated

- The agent sometimes struggles with very complex or ambiguous issues
- Try rephrasing the issue with clearer taxonomic names
- Check the workflow logs for API errors

### API Rate Limits

- OpenAI: Check your usage at platform.openai.com
- GitHub: Actions have rate limits per repository
- COL API: Generally no rate limits with authentication

## Cost Considerations

Each issue processing costs:
- ~$0.001-0.01 per OpenAI API call (GPT-4)
- Free COL API access with GBIF credentials
- Free GitHub Actions minutes (within limits)

Estimated: $0.01-0.05 per issue depending on complexity.

## License

Same as parent repository
