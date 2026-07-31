# Prism Extension for Quarto

A Quarto filter for **conditional attributes**: attach format-specific attributes to a single Div, Span, CodeBlock, or Heading and have each format pick its own.

Style a paragraph one way in HTML, another in revealjs, another in Typst, all without duplicating the prose or the code under separate `content-visible` blocks.

Each attribute is keyed `format:name="value"`.
At render time, attributes whose `format` matches the active output are re-emitted as `name="value"`; the rest are dropped.

The name is the metaphor: one source splits into format-specific outputs.

## Installation

```bash
quarto add mcanouil/quarto-prism@0.4.1
```

This will install the extension under the `_extensions` subdirectory.
If you are using version control, you will want to check in this directory.

## Documentation

The full documentation lives at <https://m.canouil.dev/quarto-prism/>: every prefix, the `slide` group alias, the `default` fallback, the precedence between them, and the same source rendered to two formats side by side.

[`example.qmd`](example.qmd) is a short, standalone starting point you can copy.

## Licence

[MIT](https://github.com/mcanouil/quarto-prism?tab=MIT-1-ov-file#readme).
