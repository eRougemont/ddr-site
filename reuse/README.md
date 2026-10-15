# Réemplois textuels — PHP viewer

Small, read-only comparison interface, entirely in French.

## Requirements

- PHP 8.1+ with **DOM/XML** (`php-xml`) enabled. `mbstring` is optional but recommended.
- A PHP web server. No database, framework, Composer, or build process is needed.


## Files and corpus integration

- `data/reused.tsv`: TSV with `file_a`, `file_b`, `score` (bare document identifiers).
- `data/ddr-docs.tsv`: TSV with `identifier`, `title`, `work`, `created`, `issued`, etc.
- `../ddr/ID.html`: XHTML publication files, where `ID` equals `identifier`.

The archive includes the **updated, user-provided TSV files** and **four sample HTML documents**. All other candidate pairs can be listed, but their text comparisons require you to copy the corresponding publication XHTML files to `html/` (or configure the directory in `lib.php`).

URLs are stable and use the two identifiers:

`?a=ddr19400430mds_02&b=ddr19460900polpers_21`

## Scope

- Sidebar search across identifiers, titles, and works; live similarity slider.
- Two text panes, with individual titles and document metadata.
- Tries to place the chronologically earlier record on the left **only when metadata date intervals do not overlap**. Uses `issued` when nonempty, otherwise `created`. These fields may have different scholarly meanings; verify them for your corpus.
- Compares only `.body`; footnotes and note callouts are excluded.
- Word and punctuation token difference highlights, navigation, and differences-only paragraphs.
- Keeps the original publication XHTML unmodified.

## Known limits

- The diff algorithm uses unique four-token anchors, then exact dynamic-programming matching inside reasonably sized gaps. Very large unmatched passages are highlighted wholesale. This is intended as a readable comparison, not a critical apparatus.
- Synchronized scrolling currently follows relative scroll position, **not** semantically aligned passages. For unequal-length texts this may drift.
- Difference navigation moves through highlighted tokens, not grouped editorial changes.
- Displayed page-break markers are suppressed in the comparison; public HTML remains unchanged.
- Source HTML is treated as trusted corpus material. Do not add untrusted third-party HTML without sanitization.
- No persistent filters, notes, workflow, review state, or annotation system.

