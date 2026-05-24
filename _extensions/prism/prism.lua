--- Prism - Filter
--- @module "prism"
--- @license MIT License
--- @copyright 2026 Mickaël Canouil
--- @author Mickaël Canouil
--- @brief Promote attributes whose key prefix matches the active Quarto target format.
--- @description
---   Reads attributes whose key follows the `format:name` pattern on `Div`,
---   `Span`, and `CodeBlock` elements.
---
---   The `format` prefix is matched exactly against the Quarto target format,
---   resolved from `quarto.format.format_identifier()["target-format"]`
---   (falling back to the Pandoc `FORMAT` global). The target format is the
---   user-declared format name and includes Quarto custom formats, so a
---   custom format such as `mcanouil-typst` is distinct from its base writer
---   `typst`. Matching is intentionally not alias-aware, so `html:` targets
---   HTML output without also affecting revealjs.
---
---   When the prefix matches, the attribute is re-emitted as `name="value"`
---   and the prefixed key is removed.
---   When the prefix does not match, the attribute is dropped.
---   Attributes whose key contains no colon are passed through unchanged.
---
---   Promoted attributes override static ones with the same name. When two
---   format-scoped attributes share the same target name on the same element
---   (e.g. two `html:style` keys), the last one in source order wins.
---
---   The filter only inspects key-value attributes; classes and ids are left
---   untouched.
---
---   Usage:
---     ::: {html:style="font-size: 1.2rem;" revealjs:style="font-size: 2em;"}
---     Conditional content.
---     :::
---
---     ```{.r mcanouil-typst:width="50%"}
---     1 + 1
---     ```

--- Resolve the active Quarto target format name once per render.
--- Strips Pandoc format variants (e.g. `html+raw_attribute` -> `html`) so
--- prefixes can be written without flag suffixes.
--- @return string
local function resolve_target_format()
  local ok, identifier = pcall(function()
    return quarto.format.format_identifier()
  end)
  local target = ok and identifier and identifier["target-format"] or nil
  if target == nil or target == "" then
    target = FORMAT
  end
  return target:match("^[^+]+") or target
end

local TARGET_FORMAT = resolve_target_format()

--- Rewrite the `attributes` table of an element by resolving format prefixes.
--- @param el pandoc.Div|pandoc.Span|pandoc.CodeBlock The element to process.
--- @return pandoc.Div|pandoc.Span|pandoc.CodeBlock|nil
local function process(el)
  if #el.attributes == 0 then
    return nil
  end

  local kept = {}
  local promoted_order = {}
  local promoted_value = {}

  for _, kv in ipairs(el.attributes) do
    local key, value = kv[1], kv[2]
    local prefix, name = key:match("^([^:]+):(.+)$")
    if prefix and name then
      if prefix == TARGET_FORMAT then
        if promoted_value[name] == nil then
          table.insert(promoted_order, name)
        end
        promoted_value[name] = value
      end
    else
      table.insert(kept, { key, value })
    end
  end

  -- Drop static attributes whose name is also promoted, so the format-scoped
  -- value wins and Pandoc does not see a duplicate-attribute warning.
  -- Among promoted entries, the last source occurrence wins.
  local final = {}
  for _, kv in ipairs(kept) do
    if promoted_value[kv[1]] == nil then
      table.insert(final, kv)
    end
  end
  for _, name in ipairs(promoted_order) do
    table.insert(final, { name, promoted_value[name] })
  end

  el.attributes = final
  return el
end

return {
  { Div = process, Span = process, CodeBlock = process }
}
