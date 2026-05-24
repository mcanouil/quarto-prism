# Changelog

## Unreleased

### New Features

- feat: Add the `slide` format-group alias, which matches every HTML slide format (`revealjs`, `slidy`, `s5`, `dzslides`, `slideous`), so a single prefix can target the whole group.
- feat: Add the `default:name` fallback prefix, applied only when no format-specific variant of the same attribute name matched the active format.

## 0.1.0 (2026-05-03)

### New Features

- feat: Initial release of the prism filter, promoting `format:name` attributes on Div, Span, and CodeBlock elements when the prefix matches the active rendering format.
