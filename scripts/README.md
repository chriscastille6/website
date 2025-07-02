# Publications Import System

This directory contains tools to import publications from Google Scholar into your Hugo website.

## Setup

1. Install Python dependencies:
   ```bash
   pip install -r requirements.txt
   ```

## How to Import Publications from Google Scholar

### Step 1: Export from Google Scholar
1. Go to your Google Scholar profile: https://scholar.google.com/citations?user=vO-9e7MAAAAJ
2. Click on "My Citations" or "All Publications"
3. Select the publications you want to import
4. Click "Export" and choose "BibTeX" format
5. Save the .bib file in this directory

### Step 2: Run the Import Script
```bash
python import_publications.py your_publications.bib
```

### Step 3: Review and Customize
The script will create publication pages in `content/publication/`. You should:

1. **Add abstracts**: Edit each `index.md` file to add the abstract
2. **Add summaries**: Create brief summaries for the homepage
3. **Add tags**: Add relevant tags for categorization
4. **Add featured images**: Place images in each publication directory
5. **Update author information**: Add co-authors if needed

## File Structure
Each publication will be created as:
```
content/publication/
├── publication-title-1/
│   ├── index.md          # Publication metadata and content
│   ├── cite.bib          # BibTeX citation
│   └── featured.jpg      # Optional featured image
└── publication-title-2/
    ├── index.md
    ├── cite.bib
    └── featured.jpg
```

## Benefits
- **Single source of truth**: Maintain your Google Scholar profile
- **Automatic updates**: Export and re-import when you add new publications
- **Consistent formatting**: All publications follow the same structure
- **Citation support**: BibTeX files enable easy citation management

## Tips
- Run the script in a clean directory first to test
- Back up your existing publications before importing
- The script will overwrite existing publications with the same title
- You can run the script multiple times to update existing publications 