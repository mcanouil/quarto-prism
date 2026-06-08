# Prism Extension for Quarto

A Quarto filter for **conditional attributes**: attach format-specific attributes to a single Div, Span, CodeBlock, or Heading and have each format pick its own.
Style a paragraph one way in HTML, another in revealjs, another in Typst, all without duplicating the prose or the code under separate `content-visible` blocks.

Each attribute is keyed `format:name="value"`.
At render time, attributes whose `format` matches the active output are re-emitted as `name="value"`; the rest are dropped.
Unprefixed attributes pass through unchanged.
Classes and identifiers are left untouched.

The name is the metaphor: one source splits into format-specific outputs.

## Installation

```bash
quarto add mcanouil/quarto-prism@0.4.1
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

## Heading {html:style="color: hotpink;" revealjs:style="color: deepskyblue;"}

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

### Format-group aliases

A prefix can target a group of formats instead of a single one.
The `slide` alias matches every HTML slide format: `revealjs`, `slidy`, `s5`, `dzslides`, and `slideous`.
So `slide:style="font-size: 2em;"` applies under any of those formats, without repeating the same value once per format.

```markdown
::: {slide:style="font-size: 2em;"}
Larger text on every HTML slide format.
:::
```

An exact format prefix always wins over the `slide` alias for the same attribute name.
Under `revealjs`, the element below resolves to the `revealjs:` value, while under `slidy` it resolves to the `slide:` value.

```markdown
::: {slide:style="color: teal;" revealjs:style="color: crimson;"}
Crimson under revealjs, teal under the other slide formats.
:::
```

### Default fallback

A `default:name="value"` prefix provides a fallback value, applied only when no format-specific variant of the same `name` matched the active format.
This lets you set a baseline value and override it only where needed.

```markdown
::: {default:style="color: gray;" html:style="color: rebeccapurple;"}
Purple under HTML, gray under every other format.
:::
```

### Precedence

For a given attribute name on the same element, the resolved value is chosen in this order:

| Rank | Source                             | Example                               |
| ---- | ---------------------------------- | ------------------------------------- |
| 1    | Exact format match.                | `html:style="..."` under `html`.      |
| 2    | Group-alias match (e.g. `slide:`). | `slide:style="..."` under `revealjs`. |
| 3    | `default:` fallback.               | `default:style="..."`.                |
| 4    | Unprefixed pass-through.           | `style="..."`.                        |

When two entries share the same rank for the same attribute name (e.g. two `html:style` keys, or two `slide:style` keys), the last one in source order wins.

A static unprefixed attribute is dropped from the output whenever a higher-rank entry resolves to the same name; otherwise it is passed through unchanged.
This guarantees a single value per attribute name and avoids Pandoc's duplicate-attribute warning.

The promoted attributes appear after the unprefixed kept attributes in the element's final attribute list, in the source order in which their target name first appeared.

```markdown
::: {style="color: gray;" default:style="color: silver;" html:style="color: crimson;"}
Crimson in HTML (exact), silver elsewhere (default), and never gray because a higher-rank entry exists for `style`.
:::
```

### Unknown prefixes

A prefix is "known" when it equals an exact format name, a group alias such as `slide`, or `default`.
Any other prefix is treated as a non-matching format and the attribute is dropped.
This is intentional, since a future format with that name would then resolve the attribute; but it also hides typos such as `revaeljs:style` until you set `extensions.prism.warn-on-drop: true`.

### Options

| Option         | Type    | Default | Description                                                                                     |
| -------------- | ------- | ------- | ----------------------------------------------------------------------------------------------- |
| `warn-on-drop` | boolean | `false` | Emit a Quarto warning each time a format-scoped attribute is dropped because no prefix matched. |

Enable it for a document or project via the front matter:

```yaml
extensions:
  prism:
    warn-on-drop: true
```

A typo such as `revaeljs:style="..."` then surfaces during render as:

```text
(W) [prism] Dropped attribute(s) 'revaeljs:style' on #mybox because no prefix matched target format 'revealjs'.
```

### Syntax

| Pattern              | Behaviour                                                                             |
| -------------------- | ------------------------------------------------------------------------------------- |
| `format:name="..."`  | Promoted to `name="..."` when `format` matches the active format; dropped otherwise.  |
| `slide:name="..."`   | Promoted when the active format is `revealjs`, `slidy`, `s5`, `dzslides`, `slideous`. |
| `default:name="..."` | Promoted only when no format-specific variant of `name` matched.                      |
| `name="..."`         | Passed through unchanged.                                                             |
| Classes (`.foo`)     | Untouched.                                                                            |
| Identifiers (`#foo`) | Untouched.                                                                            |

## Example

Here is the source code for a minimal example: [example.qmd](example.qmd).

Rendered output:

- [HTML](https://m.canouil.dev/quarto-prism/).
