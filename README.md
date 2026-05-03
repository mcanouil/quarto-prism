<!--
AGENT GUIDELINES:
This README is the primary documentation for the extension.
Update placeholder content with actual extension details.

Required updates:
1. Replace %%placeholders%% with actual values.
2. Write a clear description explaining what the filter does.
3. Document the filter's div/span classes or other syntax.
4. Document all filter options in the Configuration table.
5. Add rendered output links to the Example section.
6. Update or remove the Acknowledgements section.
-->

# Prism

A Quarto extension.

## Installation

```bash
quarto add mcanouil/quarto-prism
```

This will install the extension under the `_extensions` subdirectory.
If you are using version control, you will want to check in this directory.

## Usage

To use the extension, add the following to your document's front matter:

```yaml
filters:
  - prism
```

For timing control, specify the filter path:

```yaml
filters:
  - path: prism
    at: pre-quarto
```

Then use the filter in your document:

<!-- TODO: Update with actual filter syntax -->

```markdown
::: {.prism}
Content to be processed by the filter.
:::
```

## Configuration

Configure the filter in your document's front matter:

```yaml
extensions:
  prism:
    option1: value1
```

### Options

<!-- TODO: Document all filter options -->

| Option    | Type   | Default     | Description            |
| --------- | ------ | ----------- | ---------------------- |
| `option1` | string | `"default"` | Description of option. |

## Example

Here is the source code for a minimal example: [example.qmd](example.qmd).

<!-- TODO: Add rendered output links -->

Rendered output:

- [HTML](https://m.canouil.dev/quarto-prism/).

