#!/usr/bin/env python3
"""
GitHub Actions helper script for processing issues with the AI agent.

Checks if an issue should be processed and handles the generation.
"""

import os
import sys
import json
import requests
from typing import Dict, Any, Optional

# Add agent directory to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'agent'))
from backbone_json_agent import generate_json_tags


def get_issue_details(repo: str, issue_number: int, token: str) -> Dict[str, Any]:
    """Get issue details from GitHub API."""
    url = f"https://api.github.com/repos/{repo}/issues/{issue_number}"
    headers = {
        "Authorization": f"Bearer {token}",
        "Accept": "application/vnd.github+json"
    }
    
    response = requests.get(url, headers=headers)
    response.raise_for_status()
    return response.json()


def has_label(issue: Dict[str, Any], label_name: str) -> bool:
    """Check if issue has a specific label."""
    return any(label['name'] == label_name for label in issue.get('labels', []))


def is_in_project(repo: str, issue_number: int, project_number: int, token: str) -> bool:
    """
    Check if issue is in a specific project using GraphQL API.
    Returns False if unable to determine (to avoid blocking).
    """
    # GraphQL query to check project membership
    query = """
    query($owner: String!, $repo: String!, $number: Int!) {
      repository(owner: $owner, name: $repo) {
        issue(number: $number) {
          projectItems(first: 10) {
            nodes {
              project {
                number
              }
            }
          }
        }
      }
    }
    """
    
    owner, repo_name = repo.split('/')
    
    variables = {
        "owner": owner,
        "repo": repo_name,
        "number": issue_number
    }
    
    try:
        response = requests.post(
            "https://api.github.com/graphql",
            json={"query": query, "variables": variables},
            headers={
                "Authorization": f"Bearer {token}",
                "Content-Type": "application/json"
            }
        )
        response.raise_for_status()
        data = response.json()
        
        if 'errors' in data:
            print(f"GraphQL errors: {data['errors']}", file=sys.stderr)
            return False
        
        project_items = data['data']['repository']['issue']['projectItems']['nodes']
        return any(
            item['project']['number'] == project_number 
            for item in project_items
        )
    
    except Exception as e:
        print(f"Warning: Could not check project membership: {e}", file=sys.stderr)
        return False  # Don't block processing if check fails


def should_process_issue(
    repo: str, 
    issue_number: int, 
    token: str,
    ai_checked_label: str = "ai-checked",
    skip_project_number: Optional[int] = None
) -> tuple[bool, str]:
    """
    Determine if an issue should be processed.
    
    Returns:
        (should_process: bool, reason: str)
    """
    try:
        issue = get_issue_details(repo, issue_number, token)
        
        # Check if already processed
        if has_label(issue, ai_checked_label):
            return False, "Issue already has ai-checked label"
        
        # Check if in excluded project
        if skip_project_number:
            if is_in_project(repo, issue_number, skip_project_number, token):
                return False, f"Issue is in project #{skip_project_number}"
        
        return True, "OK"
    
    except Exception as e:
        return False, f"Error checking issue: {e}"


def main():
    """Main function for GitHub Actions."""
    
    # Get inputs from environment
    repo = os.environ.get('GITHUB_REPOSITORY')
    issue_number = os.environ.get('ISSUE_NUMBER')
    token = os.environ.get('GITHUB_TOKEN')
    issue_title = os.environ.get('ISSUE_TITLE', '')
    issue_body = os.environ.get('ISSUE_BODY', '')
    
    if not all([repo, issue_number, token]):
        print("ERROR: Missing required environment variables", file=sys.stderr)
        sys.exit(1)
    
    issue_number = int(issue_number)
    
    # Check if we should process
    should_process, reason = should_process_issue(
        repo, 
        issue_number, 
        token,
        skip_project_number=23  # backbone-feedback-automation project
    )
    
    if not should_process:
        print(f"Skipping: {reason}")
        print("should_process=false")
        sys.exit(0)
    
    print("should_process=true")
    
    # Generate JSON tags
    print("Generating JSON tags...", file=sys.stderr)
    
    full_text = f"{issue_title}\n\n{issue_body}"
    
    try:
        result = generate_json_tags(full_text, verbose=False)
        
        # Validate JSON
        parsed = json.loads(result)
        
        print("success=true")
        print(f"json_tags={result}")
        
    except json.JSONDecodeError as e:
        print(f"ERROR: Invalid JSON generated: {e}", file=sys.stderr)
        print("success=false")
        sys.exit(1)
    
    except Exception as e:
        print(f"ERROR: Failed to generate tags: {e}", file=sys.stderr)
        print("success=false")
        sys.exit(1)


if __name__ == "__main__":
    main()
