#!/usr/bin/env python3
"""
Simple CLI tool to convert plain text feedback to JSON tags.

Usage:
    # From command line argument
    python cli.py "Amphibia is under Plantae but should be under Animalia"
    
    # From file
    python cli.py -f issue.txt
    python cli.py --file issue.txt
    
    # From stdin
    echo "Amphibia is under Plantae but should be under Animalia" | python cli.py
    cat issue.txt | python cli.py
    
    # Interactive mode (no arguments)
    python cli.py
    
    # Verbose mode
    python cli.py --verbose "Your issue text here"
    python cli.py -v -f issue.txt
"""

import sys
import os
import json
from backbone_json_agent import generate_json_tags


def main():
    # Check environment variables
    if not os.environ.get("OPENAI_API_KEY"):
        print("ERROR: OPENAI_API_KEY environment variable not set", file=sys.stderr)
        print("Set it with: export OPENAI_API_KEY='your-key'", file=sys.stderr)
        sys.exit(1)
    
    # Parse arguments
    verbose = False
    issue_text = None
    input_file = None
    
    args = sys.argv[1:]
    
    # Check for verbose flag
    if "--verbose" in args or "-v" in args:
        verbose = True
        args = [arg for arg in args if arg not in ("--verbose", "-v")]
    
    # Check for file flag
    if "--file" in args or "-f" in args:
        file_flag_idx = args.index("--file") if "--file" in args else args.index("-f")
        if file_flag_idx + 1 < len(args):
            input_file = args[file_flag_idx + 1]
            args = args[:file_flag_idx] + args[file_flag_idx + 2:]
        else:
            print("ERROR: --file/-f requires a filename argument", file=sys.stderr)
            sys.exit(1)
    
    # Check for help flag
    if "--help" in args or "-h" in args:
        print(__doc__)
        sys.exit(0)
    
    # Get issue text from file, arguments, or stdin
    if input_file:
        # Read from file
        try:
            with open(input_file, 'r', encoding='utf-8') as f:
                issue_text = f.read().strip()
        except FileNotFoundError:
            print(f"ERROR: File not found: {input_file}", file=sys.stderr)
            sys.exit(1)
        except Exception as e:
            print(f"ERROR reading file: {e}", file=sys.stderr)
            sys.exit(1)
    elif args:
        # Text provided as command-line argument
        issue_text = " ".join(args)
    elif not sys.stdin.isatty():
        # Text from stdin (pipe or redirect)
        issue_text = sys.stdin.read().strip()
    else:
        # Interactive mode
        print("Enter your feedback issue (press Ctrl+D or Ctrl+Z when done):")
        print("-" * 60)
        try:
            lines = []
            while True:
                try:
                    line = input()
                    lines.append(line)
                except EOFError:
                    break
            issue_text = "\n".join(lines).strip()
        except KeyboardInterrupt:
            print("\n\nCancelled.")
            sys.exit(0)
    
    if not issue_text:
        print("ERROR: No input provided", file=sys.stderr)
        print("Usage: python cli.py 'Your feedback text here'", file=sys.stderr)
        sys.exit(1)
    
    # Generate JSON tags
    try:
        if verbose:
            print("=" * 60, file=sys.stderr)
            print("INPUT:", file=sys.stderr)
            print("=" * 60, file=sys.stderr)
            print(issue_text, file=sys.stderr)
            print("\n" + "=" * 60, file=sys.stderr)
            print("PROCESSING:", file=sys.stderr)
            print("=" * 60, file=sys.stderr)
        
        result = generate_json_tags(issue_text, verbose=verbose)
        
        if verbose:
            print("\n" + "=" * 60, file=sys.stderr)
            print("OUTPUT:", file=sys.stderr)
            print("=" * 60, file=sys.stderr)
        
        # Output to stdout (so it can be piped)
        print(result)
        
        # Validate JSON
        if verbose:
            try:
                parsed = json.loads(result)
                print("\n✓ Valid JSON", file=sys.stderr)
                print("\nFormatted:", file=sys.stderr)
                print(json.dumps(parsed, indent=2), file=sys.stderr)
            except json.JSONDecodeError as e:
                print(f"\n⚠ Warning: Output is not valid JSON: {e}", file=sys.stderr)
        
    except Exception as e:
        print(f"ERROR: {e}", file=sys.stderr)
        if verbose:
            import traceback
            traceback.print_exc(file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
