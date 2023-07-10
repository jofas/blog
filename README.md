# https://fassbender.dev/blog/

## DOI to BibTeX Entry

Given a DOI `DOI`, run the following command to add an entry to your
`bibliography.bib` BibTeX file:

```
curl -LH "Accept: text/bibliography; style=bibtex" http://dx.doi.org/"$DOI" >> bibliography.bib
```

## Converting BibTeX References to Markdown

Given a BibTeX file `bibliography.bib`, create a file `bib.md`:

```markdown
---
bibliography: bibliography.bib
nocite: |
    @*
---
```

Execute the following command:

```bash
pandoc -t markdown_strict --citeproc --csl acm.csl -s bib.md -o ref.md
```

Copy the contents of `ref.md` to the markdown of the blog post.
The contents must be formatted a little by hand, removing the `<span>`
elements and adding labels `<a name="ref-X">X</a>` around the numbers
of each reference.
