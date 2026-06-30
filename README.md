# Backbone Feedback

[![Run Tests](https://github.com/gbif/backbone-feedback/actions/workflows/run-tests.yml/badge.svg)](https://github.com/gbif/backbone-feedback/actions/workflows/run-tests.yml)

This repository contains the feedback reported to GBIF relating to the GBIF Backbone taxonomy.

## Automation Code

### Code Organization

The automation system is split between two repositories:

**This repository (`backbone-feedback`)** contains:
- Issue tracking for backbone taxonomy feedback
- GitHub Actions workflows for automated processing
- Orchestration scripts: `issue_check.sh`, `process_json.R`, `create_github_label.sh`

**External repository ([gbif/backbone-feedback-automation](https://github.com/gbif/backbone-feedback-automation))** contains:
- `gbifbf` R package - validation functions for checking taxonomic issues
- Python AI agent - converts natural language issues to structured JSON
- Documentation and examples

The workflows automatically checkout the automation repository to access the R package and Python agent while using local orchestration scripts.


