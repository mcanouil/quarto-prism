# Prism

A Quarto filter that promotes attributes whose key matches the active rendering format.
On `Div`, `Span`, and `CodeBlock` elements, any attribute whose key follows the `format:name` pattern is re-emitted as `name="value"` when the prefix resolves to the active format and dropped otherwise.
Classes and identifiers are left untouched.

The metaphor is the optical prism: one source splits into format-specific outputs.

## Installation

```bash
quarto add mcanouil/quarto-prism
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

```markdown
::: {revealjs:style="font-size: 2em;" html:style="font-size: 1.2rem;"}
Conditional content.
:::

[Inline span]{html:style="background: yellow;"}

```{.r revealjs:style="font-size: 0.6em;"}
1 + 1
```
```

The `format` part is resolved through `quarto.doc.is_format`, so aliases work.
For example, `html:` matches `html`, `astek-html`, and any other format whose base is HTML.
A static attribute of the same name is kept and overridden by a format-scoped attribute that resolves; this lets you write defaults plus format-specific overrides on the same element.

### Syntax

| Pattern              | Behaviour                                                                |
| -------------------- | ------------------------------------------------------------------------ |
| `format:name="..."`  | Promoted to `name="..."` when `format` matches; dropped otherwise.       |
| `name="..."`         | Passed through unchanged.                                                |
| `format:name`        | (no value) Treated as a key with empty value; same prefix rules apply.   |
| Classes (`.foo`)     | Untouched.                                                               |
| Identifiers (`#foo`) | Untouched.                                                               |

## Example

Here is the source code for a minimal example: [example.qmd](example.qmd).

Rendered output:

- [HTML](https://m.canouil.dev/quarto-prism/).
