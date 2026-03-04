"""
Backbone Feedback JSON Tag Agent

OpenAI-powered agent for converting plain English taxonomic issues 
into structured JSON tags for automation.
"""

from .backbone_json_agent import (
    col_api_match,
    col_api_search,
    generate_json_tags,
    SYSTEM_PROMPT,
    tools
)

__version__ = "1.0.0"
__all__ = [
    "col_api_match",
    "col_api_search", 
    "generate_json_tags",
    "SYSTEM_PROMPT",
    "tools"
]
