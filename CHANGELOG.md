# Changelog

## Unreleased

## 0.4.0 (2026-06-01)

### New Features

- feat: Resolve format-prefixed attributes on headings (`## Heading {html:style="..."}`), matching the existing behaviour on Div, Span, and CodeBlock elements.

## 0.3.0 (2026-05-31)

### New Features

- feat: Add the `extensions.prism.warn-on-drop` option (default `false`) which emits a `quarto.log.warning` each time a format-scoped attribute is dropped because no prefix matched the active target format; useful to surface typos in prefixes that would otherwise vanish silently.

### Documentation

- docs: Document the final attribute output order (kept then promoted, source-order tiebreak) and the behaviour of unknown prefixes (treated as non-matching and dropped).
- docs: Add an explicit precedence table (exact > alias > default > unprefixed) and a worked example for the conflict case where a static unprefixed value coexists with format-scoped and `default` values for the same attribute name.

### Refactoring

- refactor: Extract the HTML slide-format set into the shared `_modules/slide-formats.lua` module so prism and portable-links agree on what counts as a slide format; the canonical source lives in `mcanouil-skills/skills/creating-quarto-extension/assets/modules` and is copied into each extension on release.

## 0.2.0 (2026-05-24)

### New Features

- feat: Add the `slide` format-group alias, which matches every HTML slide format (`revealjs`, `slidy`, `s5`, `dzslides`, `slideous`), so a single prefix can target the whole group.
- feat: Add the `default:name` fallback prefix, applied only when no format-specific variant of the same attribute name matched the active format.

## 0.1.0 (2026-05-03)

### New Features

- feat: Initial release of the prism filter, promoting `format:name` attributes on Div, Span, and CodeBlock elements when the prefix matches the active rendering format.
