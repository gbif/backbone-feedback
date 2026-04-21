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


def gbif_species_lookup(species_key: str) -> Dict[str, Any]:
    """
    Look up a species by GBIF species key from a GBIF URL.
    
    Args:
        species_key: GBIF species key (e.g., '6128760' from https://www.gbif.org/species/6128760)
        
    Returns:
        Dictionary containing species information including scientific name, authorship, rank, etc.
    """
    url = f"https://api.gbif.org/v1/species/{species_key}"
    
    try:
        response = requests.get(url, timeout=10)
        response.raise_for_status()
        data = response.json()
        
        # Extract relevant fields for the agent
        result = {
            "key": data.get("key"),
            "scientificName": data.get("scientificName"),
            "canonicalName": data.get("canonicalName"),
            "authorship": data.get("authorship"),
            "rank": data.get("rank"),
            "status": data.get("taxonomicStatus"),
            "kingdom": data.get("kingdom"),
            "phylum": data.get("phylum"),
            "class": data.get("class"),
            "order": data.get("order"),
            "family": data.get("family"),
            "genus": data.get("genus"),
            "species": data.get("species"),
            "acceptedKey": data.get("acceptedKey"),
            "accepted": data.get("accepted"),
            "parentKey": data.get("parentKey"),
            "parent": data.get("parent")
        }
        return result
    except requests.RequestException as e:
        return {"error": str(e), "species_key": species_key}


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
    },
    {
        "type": "function",
        "function": {
            "name": "gbif_species_lookup",
            "description": """Look up species information from GBIF using a species key. 
            Use this when the user provides a GBIF species URL like https://www.gbif.org/species/6128760.
            Extract the numeric key from the URL (e.g., 6128760) and look it up to get the 
            scientific name, authorship, rank, and classification.""",
            "parameters": {
                "type": "object",
                "properties": {
                    "species_key": {
                        "type": "string",
                        "description": "The GBIF species key (numeric ID from GBIF URL, e.g., '6128760')"
                    }
                },
                "required": ["species_key"]
            }
        }
    }
]

# System prompt defining the agent's behavior
SYSTEM_PROMPT = """You are a taxonomic data expert assistant that converts plain English 
backbone feedback issues into structured JSON tags for automation.

MANDATORY WORKFLOW - FOLLOW THESE STEPS IN ORDER:
1. Read user feedback about taxonomic issues
2. **IF user provides GBIF URLs** (e.g., https://www.gbif.org/species/6128760):
   - Extract the species key (numeric ID) from the URL
   - Call gbif_species_lookup with that key to get the actual species name
   - Use the scientificName from the response in subsequent steps
3. Identify the type of issue being reported
4. Extract ALL taxonomic names mentioned (both current and proposed names)
5. **MANDATORY**: Call col_api_match for EVERY name before proceeding
6. Wait for ALL validation results before generating JSON
7. Generate appropriate JSON tags using the schemas below
8. Return ONLY valid JSON - no additional text or markdown formatting

CRITICAL RULES - THESE ARE NOT OPTIONAL:
- **GBIF URLs**: If user provides URLs like https://www.gbif.org/species/6128760, extract the key and call gbif_species_lookup FIRST
- You MUST validate ALL taxonomic names with col_api_match BEFORE outputting any JSON
- For nameChange tags (misspellings/corrections): validate BOTH currentName AND proposedName
- **USE THE 'label' FIELD** from col_api_match results - this contains the full scientific name WITH authorship
  * Example: If API returns {"name": "Anthocoridae", "label": "Anthocoridae Fieber, 1837"} 
  * Use "Anthocoridae Fieber, 1837" in your JSON (the label), NOT just "Anthocoridae"
- NEVER output JSON before calling col_api_match for all names
- NEVER create non-existent species names or group names without validation
- ONLY use the 6 JSON tag types defined below - do not create new tag types
- If a name doesn't exist in COL API, use the exact name provided by the user

MULTIPLE ISSUES HANDLING:
- **IMPORTANT**: A single user message may describe MULTIPLE distinct taxonomic issues
- When you identify multiple issues, output an ARRAY of JSON objects: [{"issue1": ...}, {"issue2": ...}]
- For a single issue, output a single JSON object: {"issue": ...}
- Common patterns indicating multiple issues:
  * "X is a synonym of Y and has been demoted to subfamily Z" → TWO issues: synIssue for X, AND wrongRank for Z
  * "Family X belongs to Order Y, and Genus Z is wrongly placed in Family X" → TWO issues: wrongGroup for X, wrongGroup for Z
  * Mentions of both the original name AND a derived name (e.g., family + subfamily)
- Look for derived names: Cicadoprosbolidae (family) → Cicadoprosbolinae (subfamily)
- Each distinct taxonomic name with an issue needs its own JSON tag
- Validate ALL mentioned names separately with col_api_match

JSON TAG SCHEMAS:

1. WRONG RANK - When a taxon has incorrect taxonomic rank:
{
  "name": "Species Name",
  "wrongRank": "current_rank",
  "rightRank": "correct_rank"
}
Ranks: KINGDOM, PHYLUM, CLASS, ORDER, FAMILY, GENUS, SPECIES, SUBSPECIES, VARIETY, FORM

IMPORTANT - RANK NAME ENDINGS:
When evaluating rank changes, consider standard taxonomic name endings:
- **FAMILY** (Zoology): Names typically end in -idae (e.g., Cercopidae, Formicidae)
- **FAMILY** (Botany): Names typically end in -aceae (e.g., Rosaceae, Asteraceae)
- **SUBFAMILY** (Zoology): Names typically end in -inae (e.g., Cicadoprosbolinae, Formicinae)
- **SUBFAMILY** (Botany): Names typically end in -oideae (e.g., Rosoideae)
- **TRIBE** (Zoology): Names typically end in -ini (e.g., Cercopini)
- **TRIBE** (Botany): Names typically end in -eae (e.g., Roseae)
- **SUPERFAMILY** (Zoology): Names typically end in -oidea (e.g., Cercopoidea)
- **ORDER**: Variable endings depending on group (e.g., -formes, -ales, -ida)

These endings can help you identify when a name's current rank doesn't match its suffix.
For example: "Cicadoprosbolinae" with -inae ending suggests SUBFAMILY, not FAMILY.

2. BAD NAME - When a name shouldn't exist (NO valid alternative exists):
{
  "badName": "Incorrect Name"
}
Use ONLY when the name is fundamentally invalid with no clear correction.
Do NOT use for misspellings - use NAME CHANGE instead.

3. MISSING NAME - When a valid name is missing from the database:
{
  "missingName": "Name That Should Exist"
}

4. NAME CHANGE - When a taxon name should be changed (including misspellings):
{
  "currentName": "Current Name in Database",
  "proposedName": "Proposed New Name"
}
Use this for:
- Misspellings: currentName is the misspelled version, proposedName is correct spelling
  * You MUST validate BOTH names with col_api_match
  * Validate proposedName to ensure the correct spelling exists in COL
- Wrong spellings: currentName is wrong, proposedName is correct
- Name updates: currentName is outdated, proposedName is the updated version
IMPORTANT: Always call col_api_match for both currentName AND proposedName

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
Note: Use ACCEPTED or SYNONYM for wrongStatus and rightStatus fields

EXAMPLES:

Issue: "Cercopida is a misspelling of Cercopidae"
Step 1: Call col_api_match("Cercopida") - may not exist or return wrong match
Step 2: Call col_api_match("Cercopidae") - returns {"label": "Cercopidae Leach, 1815", ...}
Step 3: Use NAME CHANGE with label: {"currentName": "Cercopida", "proposedName": "Cercopidae Leach, 1815"}

Issue: "Anthocoridea is misspelled, should be Anthocoridae"
Step 1: Call col_api_match("Anthocoridea") - check if wrong name exists
Step 2: Call col_api_match("Anthocoridae") - returns {"label": "Anthocoridae Fieber, 1837", ...}
Step 3: Use NAME CHANGE with label: {"currentName": "Anthocoridea", "proposedName": "Anthocoridae Fieber, 1837"}

Issue: "Amphibia is under Plantae but should be under Animalia"
Step 1: Call col_api_match("Amphibia") - returns {"label": "Amphibia Blainville, 1816", ...}
Step 2: Call col_api_match("Plantae") - returns {"label": "Plantae", ...}
Step 3: Call col_api_match("Animalia") - returns {"label": "Animalia", ...}
Step 4: Use WRONG GROUP with labels: {"name": "Amphibia Blainville, 1816", "wrongGroup": "Plantae", "rightGroup": "Animalia"}

Issue: "Telegonus favilla should be Urbanus favilla"
Step 1: Call col_api_match("Telegonus favilla") - returns {"label": "Telegonus favilla (Hewitson, 1874)", ...}
Step 2: Call col_api_match("Urbanus favilla") - returns {"label": "Urbanus favilla (Hewitson, 1874)", ...}
Step 3: Use NAME CHANGE with labels: {"currentName": "Telegonus favilla (Hewitson, 1874)", "proposedName": "Urbanus favilla (Hewitson, 1874)"}

Issue: "Check https://www.gbif.org/species/6128760 - the author is wrong, should be Lin C.-C. not Linné"
Step 1: Extract species key from URL: 6128760
Step 2: Call gbif_species_lookup("6128760") - returns {"scientificName": "Formoscolex koshunensis Linné", ...}
Step 3: Call col_api_match("Formoscolex koshunensis Linné") - validate current name
Step 4: Call col_api_match("Formoscolex koshunensis Lin C.-C.") - validate proposed name
Step 5: Use NAME CHANGE: {"currentName": "Formoscolex koshunensis Linné", "proposedName": "Formoscolex koshunensis Lin C.-C."}

Issue: "Cicadoprosbolidae has been synonymized with Tettigarctidae Distant 1905 and demoted to subfamily Cicadoprosbolinae Evans 1956"
ANALYSIS: This describes TWO separate issues:
  1. Cicadoprosbolidae (family) should be marked as synonym
  2. Cicadoprosbolinae (subfamily) exists and may need rank verification
Step 1: Call col_api_match("Cicadoprosbolidae") - returns {"label": "†Cicadoprosbolidae", "status": "accepted", "rank": "family", ...}
Step 2: Call col_api_match("Tettigarctidae") - returns {"label": "Tettigarctidae Distant, 1905", "status": "accepted", "rank": "family", ...}
Step 3: Call col_api_match("Cicadoprosbolinae") - returns {"label": "†Cicadoprosbolinae Evans, 1956", "rank": "subfamily", ...}
Step 4: Check if Cicadoprosbolinae might be at wrong rank in GBIF (user says "demoted to subfamily" - suggests checking rank)
Step 5: Generate TWO JSON objects in an array:
[
  {
    "name": "Cicadoprosbolidae",
    "wrongStatus": "ACCEPTED",
    "rightStatus": "SYNONYM",
    "wrongParent": null,
    "rightParent": "Tettigarctidae Distant, 1905"
  },
  {
    "name": "†Cicadoprosbolinae Evans, 1956",
    "wrongRank": "FAMILY",
    "rightRank": "SUBFAMILY"
  }
]

VALIDATION WORKFLOW:
1. Parse user's plain English issue
2. Identify which JSON tag type applies
3. Extract ALL taxonomic names mentioned (including both sides of nameChange)
4. Call col_api_match for EACH taxonomic name - DO NOT SKIP THIS STEP
5. Wait for all validation results before proceeding
6. **Extract the 'label' field from EACH col_api_match response** - this has the full name with authorship
7. Use the full 'label' value (with authorship) in your JSON output when available
8. If a name doesn't exist in COL, use the exact name from user input
9. Output the final JSON with validated full names including authorship

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
                elif function_name == "gbif_species_lookup":
                    result = gbif_species_lookup(function_args["species_key"])
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
