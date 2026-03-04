#!/usr/bin/env python3
"""
Example scripts demonstrating the Backbone JSON Tag Agent usage.
"""

import os
import sys
import json

# Add agent directory to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'agent'))

from backbone_json_agent import generate_json_tags


def example_wrong_group():
    """Example: Taxon in wrong higher classification."""
    print("\n" + "="*60)
    print("EXAMPLE 1: Wrong Group")
    print("="*60)
    
    issue = """
    Amphibia is currently placed under Plantae but it should be 
    under Animalia
    """
    
    print(f"\nInput: {issue.strip()}")
    print("\nGenerating JSON tags...\n")
    
    result = generate_json_tags(issue, verbose=True)
    
    print("\n" + "="*60)
    print("OUTPUT:")
    print("="*60)
    print(result)
    
    try:
        parsed = json.loads(result)
        print("\nParsed JSON:")
        print(json.dumps(parsed, indent=2))
    except json.JSONDecodeError as e:
        print(f"\nJSON Parse Error: {e}")


def example_synonym_issue():
    """Example: Synonym relationship problem."""
    print("\n" + "="*60)
    print("EXAMPLE 2: Synonym Issue")
    print("="*60)
    
    issue = """
    The species Agrion splendens is marked as ACCEPTED but it 
    should be a SYNONYM of Calopteryx splendens
    """
    
    print(f"\nInput: {issue.strip()}")
    print("\nGenerating JSON tags...\n")
    
    result = generate_json_tags(issue, verbose=True)
    
    print("\n" + "="*60)
    print("OUTPUT:")
    print("="*60)
    print(result)
    
    try:
        parsed = json.loads(result)
        print("\nParsed JSON:")
        print(json.dumps(parsed, indent=2))
    except json.JSONDecodeError as e:
        print(f"\nJSON Parse Error: {e}")


def example_bad_name():
    """Example: Invalid name that shouldn't exist."""
    print("\n" + "="*60)
    print("EXAMPLE 3: Bad Name")
    print("="*60)
    
    issue = """
    The name 'Dog dog Waller 2025' should not exist in the database
    """
    
    print(f"\nInput: {issue.strip()}")
    print("\nGenerating JSON tags...\n")
    
    result = generate_json_tags(issue, verbose=False)
    
    print("\n" + "="*60)
    print("OUTPUT:")
    print("="*60)
    print(result)
    
    try:
        parsed = json.loads(result)
        print("\nParsed JSON:")
        print(json.dumps(parsed, indent=2))
    except json.JSONDecodeError as e:
        print(f"\nJSON Parse Error: {e}")


def example_name_change():
    """Example: Name should be changed."""
    print("\n" + "="*60)
    print("EXAMPLE 4: Name Change")
    print("="*60)
    
    issue = """
    The name Cryptophyta should be changed to Cryptista Cavalier-Smith, 1989
    """
    
    print(f"\nInput: {issue.strip()}")
    print("\nGenerating JSON tags...\n")
    
    result = generate_json_tags(issue, verbose=False)
    
    print("\n" + "="*60)
    print("OUTPUT:")
    print("="*60)
    print(result)
    
    try:
        parsed = json.loads(result)
        print("\nParsed JSON:")
        print(json.dumps(parsed, indent=2))
    except json.JSONDecodeError as e:
        print(f"\nJSON Parse Error: {e}")


def example_missing_name():
    """Example: Valid name missing from database."""
    print("\n" + "="*60)
    print("EXAMPLE 5: Missing Name")
    print("="*60)
    
    issue = """
    The valid species Examplius missingus Smith, 2024 is not 
    present in the database
    """
    
    print(f"\nInput: {issue.strip()}")
    print("\nGenerating JSON tags...\n")
    
    result = generate_json_tags(issue, verbose=False)
    
    print("\n" + "="*60)
    print("OUTPUT:")
    print("="*60)
    print(result)
    
    try:
        parsed = json.loads(result)
        print("\nParsed JSON:")
        print(json.dumps(parsed, indent=2))
    except json.JSONDecodeError as e:
        print(f"\nJSON Parse Error: {e}")


def example_wrong_rank():
    """Example: Taxonomic name has incorrect rank."""
    print("\n" + "="*60)
    print("EXAMPLE 6: Wrong Rank")
    print("="*60)
    
    issue = """
    Telegonus favilla is listed as a GENUS but it should be a SPECIES
    """
    
    print(f"\nInput: {issue.strip()}")
    print("\nGenerating JSON tags...\n")
    
    result = generate_json_tags(issue, verbose=False)
    
    print("\n" + "="*60)
    print("OUTPUT:")
    print("="*60)
    print(result)
    
    try:
        parsed = json.loads(result)
        print("\nParsed JSON:")
        print(json.dumps(parsed, indent=2))
    except json.JSONDecodeError as e:
        print(f"\nJSON Parse Error: {e}")


def main():
    """Run all examples."""
    
    # Check environment variables
    if not os.environ.get("OPENAI_API_KEY"):
        print("ERROR: OPENAI_API_KEY environment variable not set")
        print("Please set it with:")
        print("  export OPENAI_API_KEY='your-api-key'")
        return
    
    if not os.environ.get("GBIF_USER") or not os.environ.get("GBIF_PWD"):
        print("WARNING: GBIF_USER and/or GBIF_PWD not set")
        print("COL API calls may fail without authentication")
        print()
    
    print("="*60)
    print("BACKBONE FEEDBACK JSON TAG AGENT - EXAMPLES")
    print("="*60)
    print("\nSelect an example to run:")
    print("1. Wrong Group (Amphibia classification)")
    print("2. Synonym Issue (Agrion splendens)")
    print("3. Bad Name (Dog dog)")
    print("4. Name Change (Cryptophyta)")
    print("5. Missing Name (Example missing species)")
    print("6. Wrong Rank (Telegonus favilla)")
    print("7. Run all examples")
    print("0. Exit")
    
    choice = input("\nEnter choice (0-7): ").strip()
    
    examples = {
        "1": example_wrong_group,
        "2": example_synonym_issue,
        "3": example_bad_name,
        "4": example_name_change,
        "5": example_missing_name,
        "6": example_wrong_rank,
    }
    
    if choice == "0":
        print("Exiting...")
        return
    elif choice == "7":
        for func in examples.values():
            func()
            print("\n")
    elif choice in examples:
        examples[choice]()
    else:
        print("Invalid choice")


if __name__ == "__main__":
    main()
