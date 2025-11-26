#!/usr/bin/env python3
"""
BibTeX to Hugo Publications Import Script
For People Analytics Lab of the Bayou

This script helps import publications from BibTeX files exported from Google Scholar
into the Hugo website structure.

Usage:
1. Export your publications from Google Scholar as BibTeX
2. Save the .bib file in the scripts/ directory
3. Run: python scripts/import_publications.py your_file.bib
"""

import sys
import os
import re
from pathlib import Path
import bibtexparser
from datetime import datetime

def clean_filename(title):
    """Convert publication title to a safe filename"""
    # Remove special characters and convert to lowercase
    clean = re.sub(r'[^\w\s-]', '', title.lower())
    clean = re.sub(r'[-\s]+', '-', clean)
    return clean[:50]  # Limit length

def create_publication_page(bib_entry, output_dir):
    """Create a Hugo publication page from a BibTeX entry"""
    
    # Determine publication type
    pub_type = bib_entry.get('ENTRYTYPE', 'article')
    if pub_type == 'article':
        publication_type = 'article-journal'
    elif pub_type == 'inproceedings':
        publication_type = 'paper-conference'
    else:
        publication_type = 'article'
    
    # Extract authors - use plain text names instead of author IDs
    authors = bib_entry.get('author', '').split(' and ')
    author_list = []
    for author in authors:
        # Clean up author name (remove extra spaces, etc.)
        clean_author = author.strip()
        if clean_author:
            author_list.append(clean_author)
    
    # Create publication metadata
    title = bib_entry.get('title', '').strip('{}')
    journal = bib_entry.get('journal', bib_entry.get('booktitle', ''))
    year = bib_entry.get('year', '')
    doi = bib_entry.get('doi', '')
    url = bib_entry.get('url', '')
    
    # Create filename
    filename = clean_filename(title)
    pub_dir = output_dir / filename
    
    # Create directory
    pub_dir.mkdir(exist_ok=True)
    
    # Create index.md
    index_content = f"""---
title: "{title}"
authors:
{chr(10).join([f"  - {author}" for author in author_list])}
date: "{year}-01-01T00:00:00Z"
doi: "{doi}"
publishDate: "{year}-01-01T00:00:00Z"
publication_types: ["{publication_type}"]
publication: "*{journal}*"
publication_short: ""
abstract: ""
summary: ""
tags: []
featured: false
projects: []
slides: ""

url_pdf: "{url}"
url_code: ""
url_dataset: ""
url_poster: ""
url_project: ""
url_slides: ""
url_source: ""
url_video: ""

image:
  caption: ""
  focal_point: ""
  preview_only: false

---
"""
    
    # Write index.md
    with open(pub_dir / 'index.md', 'w') as f:
        f.write(index_content)
    
    # Copy BibTeX entry
    with open(pub_dir / 'cite.bib', 'w') as f:
        f.write(f"@{bib_entry['ENTRYTYPE']}{{{bib_entry['ID']},\n")
        for key, value in bib_entry.items():
            if key not in ['ENTRYTYPE', 'ID']:
                f.write(f"  {key} = {{{value}}},\n")
        f.write("}\n")
    
    print(f"Created: {filename}")

def main():
    if len(sys.argv) != 2:
        print("Usage: python import_publications.py <bibtex_file>")
        sys.exit(1)
    
    bib_file = sys.argv[1]
    if not os.path.exists(bib_file):
        print(f"Error: File {bib_file} not found")
        sys.exit(1)
    
    # Read BibTeX file
    with open(bib_file, 'r') as f:
        bib_content = f.read()
    
    # Parse BibTeX
    parser = bibtexparser.bparser.BibTexParser()
    bib_database = bibtexparser.loads(bib_content, parser)
    
    # Output directory
    output_dir = Path('content/publication')
    
    print(f"Importing {len(bib_database.entries)} publications...")
    
    for entry in bib_database.entries:
        create_publication_page(entry, output_dir)
    
    print("Import complete!")
    print("\nNext steps:")
    print("1. Review the generated publication pages")
    print("2. Add abstracts and summaries")
    print("3. Add featured images if desired")
    print("4. Update author information")

if __name__ == "__main__":
    main() 