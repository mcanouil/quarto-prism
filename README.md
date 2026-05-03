# Prism Extension for Quarto

A Quarto filter for **conditional attributes**: attach format-specific attributes to a single Div, Span, or CodeBlock and have each format pick its own.
Style a paragraph one way in HTML, another in revealjs, another in Typst, all without duplicating the prose or the code under separate `content-visible` blocks.

Each attribute is keyed `format:name="value"`.
At render time, attributes whose `format` matches the active output are re-emitted as `name="value"`; the rest are dropped.
Unprefixed attributes pass through unchanged.
Classes and identifiers are left untouched.

The name is the metaphor: one source splits into format-specific outputs.

## Installation

```bash
quarto add mcanouil/quarto-prism@0.1.0
```

This will install the extension under the `_extensions` subdirectory.
If you are using version control, you will want to check in this directory.

## Usage

Add the filter in your document's front matter:

```yaml
filters:
  - prism
```

Then prefix any attribute key with a format name and a colon:

````markdown
::: {revealjs:style="font-size: 2em;" html:style="font-size: 1.2rem;"}
Conditional content.
:::

[Inline span]{html:style="background: yellow;"}

```{.r revealjs:style="font-size: 0.6em;"}
1 + 1
```
````

The `format` part is matched **exactly** against the Quarto target format, resolved via [`quarto.format.format_identifier()`](https://quarto.org/docs/extensions/lua-api.html#quarto-format-format_identifier) (with a fallback to Pandoc's `FORMAT` global).
That is the user-declared format name and includes Quarto custom formats, so each prefix targets one format:

| Active format             | Matching prefix   |
| ------------------------- | ----------------- |
| `html`                    | `html:`           |
| `revealjs`                | `revealjs:`       |
| `typst`                   | `typst:`          |
| `mcanouil-typst` (custom) | `mcanouil-typst:` |
| `latex` (used for `pdf`)  | `latex:`          |
| `beamer`                  | `beamer:`         |
| `docx`                    | `docx:`           |
| `pptx`                    | `pptx:`           |

A custom Quarto format such as `mcanouil-typst` is distinct from its base writer `typst`: under `mcanouil-typst`, only `mcanouil-typst:` matches (not `typst:`), and vice versa.
PDF outputs render through Pandoc's `latex` writer; target them with `latex:` (there is no `pdf:` target unless you have a custom format named `pdf`).

A static attribute of the same name is kept and overridden by a format-scoped attribute that resolves, which lets you write defaults plus format-specific overrides on the same element.
When two format-scoped attributes share the same target name on the same element (_e.g._, two `html:style` keys), the last one in source order wins.

### Syntax

| Pattern              | Behaviour                                                          |
| -------------------- | ------------------------------------------------------------------ |
| `format:name="..."`  | Promoted to `name="..."` when `format` matches; dropped otherwise. |
| `name="..."`         | Passed through unchanged.                                          |
| Classes (`.foo`)     | Untouched.                                                         |
| Identifiers (`#foo`) | Untouched.                                                         |

## Example

Here is the source code for a minimal example: [example.qmd](example.qmd).

Rendered output:

- [HTML](https://m.canouil.dev/quarto-prism/).
