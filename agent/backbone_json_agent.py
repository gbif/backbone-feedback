#!/usr/bin/env python3
"""
OpenAI Agent for Backbone Feedback JSON Tag Generation

This agent reads backbone feedback issues written in plain English and outputs
structured JSON tags for automation. It uses the COL (Catalogue of Life) API 
to validate and normalize taxonomic names.

Environment Variables Required:
- OPENAI_API_KEY: OpenAI API key for agent access
- GBIF_USER: GBIF username for COL API authentication  
- GBIF_PWD: GBIF password for COL API authentication

JSON Tags Supported:
1. wrongRank: Taxonomic name has incorrect rank
2. badName: Name shouldn't exist in database
3. missingName: Name is missing from database
4. nameChange: Name should be changed
5. wrongGroup: Taxon placed in wrong higher group
6. synIssue: Synonym relationship issue
"""

import os
import json
import requests
from typing import Optional, Dict, Any, List
from openai import OpenAI

# Initialize OpenAI client
client = OpenAI(api_key=os.environ.get("OPENAI_API_KEY"))

# COL API configuration
COL_API_BASE = "https://api.checklistbank.org/dataset/3LXRC"
GBIF_USER = os.environ.get("GBIF_USER")
GBIF_PWD = os.environ.get("GBIF_PWD")


def col_api_search(query: str) -> Dict[str, Any]:
    """
    Search the Catalogue of Life (COL) API for a taxonomic name.
    
    Args:
        query: Scientific name to search for
        
    Returns:
        Dictionary containing API response with taxonomic information
        
    Raises:
        requests.RequestException: If API request fails
    """
    url = f"{COL_API_BASE}/nameusage"
    params = {"q": query}
    
    try:
        response = requests.get(
            url,
            params=params,
            auth=(GBIF_USER, GBIF_PWD) if GBIF_USER and GBIF_PWD else None,
            timeout=10
        )
        response.raise_for_status()
        return response.json()
    except requests.RequestException as e:
        return {"error": str(e), "query": query}


def col_api_match(query: str) -> Dict[str, Any]:
    """
    Match a name using the COL API name matching service.
    This is more precise than search for getting exact matches.
    
    Args:
        query: Scientific name to match
        
    Returns:
        Dictionary containing match results with normalized 'label'
    """
    url = f"{COL_API_BASE}/match/nameusage"
    params = {"q": query}
    
    try:
        response = requests.get(
            url,
            params=params,
            auth=(GBIF_USER, GBIF_PWD) if GBIF_USER and GBIF_PWD else None,
            timeout=10
        )
        response.raise_for_status()
        return response.json()
    except requests.RequestException as e:
        return {"error": str(e), "query": query}


# Define tools for OpenAI agent
tools = [
    {
        "type": "function",
        "function": {
            "name": "col_api_match",
            "description": """Match and validate a taxonomic name using the Catalogue of Life API. 
            This normalizes user input and returns the accepted scientific name label, rank, 
            classification, and status. Use this to validate that species names, genus names, 
            and higher group names actually exist before including them in JSON output.
            Returns the 'label' field which is the normalized name.""",
            "parameters": {
                "type": "object",
                "properties": {
                    "query": {
                        "type": "string",
                        "description": "The scientific name to validate and normalize (e.g., 'Telegonus favilla', 'Animalia', 'Amphibia')"
                    }
                },
                "required": ["query"]
            }
        }
    }
]

# System prompt defining the agent's behavior
SYSTEM_PROMPT = """You are a taxonomic data expert assistant that converts plain English 
backbone feedback issues into structured JSON tags for automation.

Your task is to:
1. Read user feedback about taxonomic issues
2. Identify the type of issue being reported
3. Use the col_api_match tool to validate ALL taxonomic names mentioned before outputting them
4. Generate appropriate JSON tags ONLY using the schemas defined below
5. Return ONLY valid JSON - no additional text or markdown formatting

CRITICAL RULES:
- ALWAYS validate taxonomic names with col_api_match before including them in JSON
- Use the 'label' field from col_api_match results as the normalized name
- NEVER create non-existent species names or group names
- ONLY use the 6 JSON tag types defined below - do not create new tag types
- If a name doesn't exist in COL API, ask for clarification or omit the field
- Output ONLY the JSON object, nothing else

JSON TAG SCHEMAS:

1. WRONG RANK - When a taxon has incorrect taxonomic rank:
{
  "name": "Species Name",
  "wrongRank": "current_rank",
  "rightRank": "correct_rank"
}
Ranks: KINGDOM, PHYLUM, CLASS, ORDER, FAMILY, GENUS, SPECIES, SUBSPECIES, VARIETY, FORM

2. BAD NAME - When a name shouldn't exist in the database:
{
  "badName": "Incorrect Name"
}

3. MISSING NAME - When a valid name is missing from the database:
{
  "missingName": "Name That Should Exist"
}

4. NAME CHANGE - When a taxon name should be changed:
{
  "currentName": "Current Name in Database",
  "proposedName": "Proposed New Name"
}

5. WRONG GROUP - When a taxon is in the wrong higher classification:
{
  "name": "Taxon Name",
  "wrongGroup": "Current Incorrect Parent Group",
  "rightGroup": "Correct Parent Group"
}
Note: wrongGroup or rightGroup can be null if only one is known

6. SYNONYM ISSUE - When there's a problem with synonym relationships:
{
  "name": "Name in Question",
  "wrongStatus": "ACCEPTED|SYNONYM|null",
  "rightStatus": "ACCEPTED|SYNONYM|null",
  "wrongParent": "Incorrect Parent Name or null",
  "rightParent": "Correct Parent Name or null"
}
Note: Use ACCEPTED or SYNONYM for status fields

VALIDATION WORKFLOW:
1. Parse user's plain English issue
2. Identify which JSON tag type applies
3. Extract all taxonomic names mentioned
4. Call col_api_match for EACH taxonomic name to validate it exists
5. Use the validated 'label' from API response in your JSON output
6. If a name doesn't exist, either ask for clarification or use null
7. Output the final JSON with validated names only

Remember: Your output must be ONLY valid JSON, parseable by json.loads(). 
No markdown code blocks, no explanatory text."""


def generate_json_tags(user_issue: str, verbose: bool = False) -> str:
    """
    Generate JSON tags from a plain English backbone feedback issue.
    
    Args:
        user_issue: Plain English description of taxonomic issue
        verbose: If True, print conversation steps
        
    Returns:
        JSON string with appropriate tags
    """
    messages = [
        {"role": "system", "content": SYSTEM_PROMPT},
        {"role": "user", "content": user_issue}
    ]
    
    max_iterations = 10
    iteration = 0
    
    while iteration < max_iterations:
        iteration += 1
        
        if verbose:
            print(f"\n=== Iteration {iteration} ===")
        
        response = client.chat.completions.create(
            model="gpt-4o",
            messages=messages,
            tools=tools,
            tool_choice="auto"
        )
        
        assistant_message = response.choices[0].message
        messages.append(assistant_message)
        
        # Check if agent wants to call tools
        if assistant_message.tool_calls:
            for tool_call in assistant_message.tool_calls:
                function_name = tool_call.function.name
                function_args = json.loads(tool_call.function.arguments)
                
                if verbose:
                    print(f"Calling {function_name} with args: {function_args}")
                
                # Execute the tool
                if function_name == "col_api_match":
                    result = col_api_match(function_args["query"])
                    if verbose:
                        print(f"Result: {json.dumps(result, indent=2)}")
                    
                    # Add tool result to messages
                    messages.append({
                        "role": "tool",
                        "tool_call_id": tool_call.id,
                        "content": json.dumps(result)
                    })
        else:
            # No more tool calls, return the response
            content = assistant_message.content
            
            # Strip markdown code blocks if present
            if content.startswith("```"):
                # Remove opening ```json or ``` 
                content = content.split("\n", 1)[1] if "\n" in content else content[3:]
                # Remove closing ```
                if content.endswith("```"):
                    content = content.rsplit("```", 1)[0]
                content = content.strip()
            
            if verbose:
                print(f"\nFinal response: {content}")
            return content
    
    return json.dumps({"error": "Max iterations reached"})


def main():
    """Main function with example usage."""
    
    # Check environment variables
    if not os.environ.get("OPENAI_API_KEY"):
        print("ERROR: OPENAI_API_KEY environment variable not set")
        return
    
    if not os.environ.get("GBIF_USER") or not os.environ.get("GBIF_PWD"):
        print("WARNING: GBIF_USER and/or GBIF_PWD not set. COL API calls may fail.")
    
    # Example usage
    print("=" * 60)
    print("Backbone Feedback JSON Tag Generator")
    print("=" * 60)
    
    examples = [
        "Amphibia is currently placed under Plantae but it should be under Animalia",
        "The species Agrion splendens is marked as ACCEPTED but it should be a SYNONYM of Calopteryx splendens",
        "The name 'Dog dog Waller 2025' should not exist in the database",
        "The name Cryptophyta should be changed to Cryptista Cavalier-Smith, 1989"
    ]
    
    print("\nExample issues:\n")
    for i, example in enumerate(examples, 1):
        print(f"{i}. {example}")
    
    print("\n" + "=" * 60)
    print("\nEnter your issue (or press Enter to use example 1):")
    user_input = input("> ").strip()
    
    if not user_input:
        user_input = examples[0]
        print(f"Using example: {user_input}")
    
    print("\nGenerating JSON tags...")
    print("-" * 60)
    
    result = generate_json_tags(user_input, verbose=True)
    
    print("\n" + "=" * 60)
    print("GENERATED JSON:")
    print("=" * 60)
    print(result)
    
    # Try to parse and pretty-print
    try:
        parsed = json.loads(result)
        print("\nFormatted JSON:")
        print(json.dumps(parsed, indent=2))
    except json.JSONDecodeError:
        print("\nNote: Response is not valid JSON")


if __name__ == "__main__":
    main()
