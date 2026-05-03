--- Prism - Filter
--- @module prism
--- @license MIT License
--- @copyright 2026 Mickaël Canouil
--- @author Mickaël Canouil
--- @version 0.0.0
--- @brief Promote attributes whose key prefix matches the active rendering format.
--- @description
---   Reads attributes whose key follows the `format:name` pattern on `Div`,
---   `Span`, and `CodeBlock` elements.
---
---   When the `format` prefix matches the active rendering format (resolved via
---   `quarto.doc.is_format`, which understands aliases such as `html` matching
---   `astek-html`), the attribute is re-emitted as `name="value"` and the
---   prefixed key is removed.
---   When the prefix does not match, the attribute is dropped.
---   Attributes whose key contains no colon are passed through unchanged.
---
---   Promoted attributes are appended after the kept ones, so a conditional
---   value overrides a static one with the same name.
---
---   The filter only inspects key-value attributes; classes and ids are left
---   untouched.
---
---   Usage:
---     ::: {revealjs:style="font-size: 2em;" html:style="font-size: 1.2rem;"}
---     Conditional content.
---     :::
---
---     ```{.r revealjs:style="font-size: 0.6em;"}
---     1 + 1
---     ```

--- Extension name constant
local EXTENSION_NAME = 'prism'

--- Rewrite the `attributes` table of an element by resolving format prefixes.
--- @param el pandoc.Div|pandoc.Span|pandoc.CodeBlock The element to process.
--- @return pandoc.Div|pandoc.Span|pandoc.CodeBlock|nil
local function process(el)
  if #el.attributes == 0 then
    return nil
  end

  local kept = {}
  local promoted = {}
  local promoted_names = {}

  for _, kv in ipairs(el.attributes) do
    local key, value = kv[1], kv[2]
    local prefix, name = key:match("^([^:]+):(.+)$")
    if prefix and name then
      if quarto.doc.is_format(prefix) then
        table.insert(promoted, { name, value })
        promoted_names[name] = true
      end
    else
      table.insert(kept, { key, value })
    end
  end

  -- Drop static attributes whose name is also promoted, so the format-scoped
  -- value wins and Pandoc does not see a duplicate-attribute warning.
  local final = {}
  for _, kv in ipairs(kept) do
    if not promoted_names[kv[1]] then
      table.insert(final, kv)
    end
  end
  for _, kv in ipairs(promoted) do
    table.insert(final, kv)
  end

  el.attributes = final
  return el
end

return {
  { Div = process, Span = process, CodeBlock = process }
}
