# Manuscripts

A writing appliance for students. Manuscripts combines a Markdown editor, source management, Chicago/Turabian citations, and PDF export in a single terminal application.

## Philosophy

Students shouldn't need to understand filesystems, BibTeX, or Zotero. They should think about **essays** and **sources**. Manuscripts provides:

- **Projects, not files** — students see "Gatsby Essay," not `~/Documents/english/essay1.md`
- **Simplified sources** — add a book by entering Author, Title, Year, Publisher. No BibTeX syntax required.
- **One-key citations** — press `Ctrl+R`, search, press Enter. A Chicago-format footnote appears.
- **Integrated export** — open the command palette (`Ctrl+P`) and select Export.

## Requirements

- Python 3.9+
- Textual (and its dependencies: Rich, markdown-it-py, mdit-py-plugins, platformdirs)
- For PDF/DOCX export: Pandoc
- For PDF export: LibreOffice

### Option A: pip install (recommended)

```bash
pip install textual
```

Then just run `python3 manuscripts.py`.

### Option B: Vendored dependencies (no network needed)

Place these zip files in the project directory:

- `rich-master.zip` (from github.com/Textualize/rich)
- `mdit-py-plugins-master.zip` (from github.com/executablebooks/mdit-py-plugins)
- `textual-main.zip` (from github.com/Textualize/textual)

Then:

```bash
chmod +x setup.sh run.sh
./setup.sh     # unpacks into vendor/
./run.sh       # launches manuscripts
```

## Usage

```bash
python3 manuscripts.py    # if textual is pip-installed
./run.sh                   # if using vendored dependencies
MANUSCRIPTS_DATA=~/essays ./run.sh   # custom data directory
```

Data is stored in `~/.manuscripts/` by default. Exports go to `~/Documents/manuscripts.exports/`.

## Keyboard Shortcuts

### Projects Screen

| Key | Action |
|-----|--------|
| n | New manuscript |
| d | Delete manuscript |
| e | Toggle exports view |

Type in the search bar to filter manuscripts by name.

### Editor

| Key | Action |
|-----|--------|
| Ctrl+R | Insert citation |
| Ctrl+N | Insert blank footnote (`^[]`) |
| Ctrl+B | Bold |
| Ctrl+I | Italic |
| Ctrl+O | Manage sources |
| Ctrl+S | Save |
| Ctrl+M | Return to manuscripts |
| Ctrl+H | Toggle keybindings panel |
| Ctrl+P | Command palette |

### Command Palette

Cite, Bibliography, Sources, Export, and Insert frontmatter properties (author, title, instructor, date, spacing, style).

## YAML Frontmatter

```yaml
---
title: "My Essay"
author: "First Last"
instructor: "Prof. Name"
date: "January 2026"
spacing: double
style: chicago
---
```

- **spacing**: `single`, `double`, `dg.single`, `dg.double`
- **style**: `chicago` (Turabian cover page) or `mla` (MLA header)

## Source Types

### Book
Author (Last, First), Title, Year, Publisher

### Book Section
Author (Last, First), Chapter Title, Book Title, Editor, Year, Publisher, Pages

### Article
Author (Last, First), Title, Year, Journal, Volume, Issue, Pages

### Website
Author (Last, First), Title, Year, Website Name, URL, Access Date

Sources can also be imported from other manuscripts in your library.

## Citation Format

Chicago/Turabian style:

**Footnote:** F. Scott Fitzgerald, *The Great Gatsby* (Scribner, 1925), 42.

**Bibliography:** Fitzgerald, F. Scott. *The Great Gatsby*. Scribner, 1925.

**Book section footnote:** John Smith, "My Chapter," in *The Big Book*, ed. Jane Doe (Oxford Press, 2020), 45-67.

**Book section bibliography:** Smith, John. "My Chapter." In *The Big Book*, edited by Jane Doe, 45-67. Oxford Press, 2020.

## Data Storage

Projects are stored as JSON files in `~/.manuscripts/projects/`. Each project contains its text content and source metadata. No external database required.

## License

MIT
