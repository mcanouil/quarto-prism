--- Prism - Filter
--- @module "prism"
--- @license MIT License
--- @copyright 2026 Mickaël Canouil
--- @author Mickaël Canouil
--- @brief Promote attributes whose key prefix matches the active Quarto target format.
--- @description
---   Reads attributes whose key follows the `format:name` pattern on `Div`,
---   `Span`, `CodeBlock`, and `Header` elements.
---
---   The `format` prefix is matched against the Quarto target format,
---   resolved from `quarto.format.format_identifier()["target-format"]`
---   (falling back to the Pandoc `FORMAT` global). The target format is the
---   user-declared format name and includes Quarto custom formats, so a
---   custom format such as `mcanouil-typst` is distinct from its base writer
---   `typst`. Matching is exact for individual format names, so `html:`
---   targets HTML output without also affecting revealjs.
---
---   In addition to exact format names, the `slide` alias matches every HTML
---   slide format (revealjs, slidy, s5, dzslides, slideous), so `slide:` can
---   target the whole group at once.
---
---   A `default:name` prefix provides a fallback value, applied only when no
---   format-specific variant of the same `name` matched the active format.
---
---   When the prefix matches, the attribute is re-emitted as `name="value"`
---   and the prefixed key is removed.
---   When the prefix does not match, the attribute is dropped.
---   Attributes whose key contains no colon are passed through unchanged.
---
---   The `typst:` prefix is shared with Pandoc's own Typst writer, which reads
---   `typst:text:<property>` on a div and a span and `typst:<parameter>` on a
---   div, and reads nothing on a code block or a heading. Whenever Pandoc
---   writes Typst those keys keep their prefix and pass through untouched,
---   rather than being promoted to a name no consumer reads. Every other
---   `typst:` key stays prism's, since the writer splices it unvalidated and
---   Typst rejects it. `extensions.prism.claim-typst` names reserved keys to
---   promote instead. See <https://pandoc.org/typst-property-output.html>.
---
---   Precedence for a given `name`: exact format match > alias match >
---   default fallback > unprefixed pass-through.
---
---   Promoted attributes override static ones with the same name. When two
---   format-scoped attributes share the same target name on the same element
---   (e.g. two `html:style` keys), the last one in source order wins.
---
---   Unknown prefixes (neither an exact format name, a known group alias,
---   nor `default`) are treated as non-matching and the attribute is dropped.
---   Enable `extensions.prism.warn-on-drop` to emit a `quarto.log.warning`
---   each time a format-scoped attribute is dropped, which surfaces typos in
---   prefixes that would otherwise vanish silently.
---
---   The filter only inspects key-value attributes; classes and ids are left
---   untouched.
---
---   Usage:
---     ::: {html:style="font-size: 1.2rem;" revealjs:style="font-size: 2em;"}
---     Conditional content.
---     :::
---
---     ::: {slide:style="font-size: 2em;" default:style="font-size: 1rem;"}
---     Larger on every slide format, smaller everywhere else.
---     :::
---
---     ```{.r mcanouil-typst:width="50%"}
---     1 + 1
---     ```

--- Extension name constant, used to namespace log messages and metadata.
local EXTENSION_NAME = 'prism'

local slide_formats = require(quarto.utils.resolve_path('_modules/slide-formats.lua'):gsub('%.lua$', ''))
local log = require(quarto.utils.resolve_path('_modules/logging.lua'):gsub('%.lua$', ''))

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

--- Whether Pandoc writes this render with its Typst writer.
--- Taken from the Pandoc `FORMAT` global rather than the Quarto target format,
--- because a custom format such as `mcanouil-typst` is written by the same
--- writer and reads the same `typst:` attributes.
--- @type boolean
local WRITES_TYPST = FORMAT:match('typst') ~= nil

--- The `default` prefix names a fallback value, applied only when no
--- format-specific variant of the same attribute name matched.
local DEFAULT_PREFIX = "default"

--- Aliases that match a group of formats rather than an exact format name.
--- Each value is the set of target formats the alias resolves to.
--- The `slide` set is sourced from the shared `_modules/slide-formats` module
--- so prism and portable-links agree on what counts as an HTML slide format.
--- @type table<string, table<string, boolean>>
local FORMAT_ALIASES = {
  slide = slide_formats.formats,
}

--- The parameters Typst's `block()` function accepts.
--- @type table<string, boolean>
local TYPST_BLOCK_PARAMETERS = {
  width = true,
  height = true,
  breakable = true,
  fill = true,
  stroke = true,
  radius = true,
  inset = true,
  outset = true,
  spacing = true,
  above = true,
  below = true,
  clip = true,
  sticky = true,
}

--- The one prefix that names a namespace Pandoc's own writer consumes.
--- @type string
local PANDOC_TYPST_PREFIX = 'typst'

--- Whether a `typst:` key is one Pandoc's Typst writer reads on some element.
--- Used to tell a `claim-typst` entry that names a real reserved key from one
--- that names a key prism promotes anyway.
--- @param name string The attribute key with the `typst:` prefix removed.
--- @return boolean
local function is_reserved_typst_name(name)
  return name:match('^text:') ~= nil or TYPST_BLOCK_PARAMETERS[name] == true
end

--- Whether Pandoc's Typst writer consumes this attribute on this element.
--- Per <https://pandoc.org/typst-property-output.html> the writer reads
--- `typst:text:<property>` as a set-text rule on a div and on a span, and
--- `typst:<parameter>` as an argument to `#block()` on a div alone. No other
--- nested function is recognised: `typst:par:leading` is dropped by the writer,
--- and code blocks and headings are not covered at all, so prism keeps those.
--- Promoting one of these would strip a prefix the writer is waiting for, and
--- the styling would be lost; a key outside the set fails the render natively
--- with `unexpected argument`, so prism claims it.
--- @param name string The attribute key with the `typst:` prefix removed.
--- @param element_type string The Pandoc element tag, e.g. "Div" or "Span".
--- @return boolean True when Pandoc consumes the attribute itself.
local function is_pandoc_typst_key(name, element_type)
  if element_type == 'Div' then
    return is_reserved_typst_name(name)
  end
  return element_type == 'Span' and name:match('^text:') ~= nil
end

--- Reserved `typst:` keys the document has taken back for prism.
--- Set per document via `extensions.prism.claim-typst: [width]`, which promotes
--- those keys as any other prefixed attribute instead of leaving them to
--- Pandoc's Typst writer.
--- @type table<string, boolean>
local claimed_typst_keys = {}

--- Whether to emit a warning when a format-scoped attribute is dropped.
--- Set per document via `extensions.prism.warn-on-drop: true`.
--- @type boolean
local warn_on_drop = false

--- Resolve how a prefix matches the active target format.
--- Exact format names match identically; group aliases match when the active
--- target format is a member of the alias set.
--- @param prefix string The attribute key prefix (the part before the colon).
--- @return "exact"|"alias"|nil The match kind, or nil when the prefix does not match.
local function match_prefix(prefix)
  if prefix == TARGET_FORMAT then
    return "exact"
  end
  local alias = FORMAT_ALIASES[prefix]
  if alias and alias[TARGET_FORMAT] then
    return "alias"
  end
  return nil
end

--- Describe an element for warning messages: prefer the id, then the first
--- class, then the element tag.
--- @param el pandoc.Div|pandoc.Span|pandoc.CodeBlock|pandoc.Header
--- @return string
local function describe_element(el)
  if el.identifier and el.identifier ~= '' then
    return '#' .. el.identifier
  end
  if el.classes and #el.classes > 0 then
    return '.' .. el.classes[1]
  end
  return el.t or 'element'
end

--- Rewrite the `attributes` table of an element by resolving format prefixes.
--- @param el pandoc.Div|pandoc.Span|pandoc.CodeBlock|pandoc.Header The element to process.
--- @return pandoc.Div|pandoc.Span|pandoc.CodeBlock|pandoc.Header|nil
local function process(el)
  if #el.attributes == 0 then
    return nil
  end

  local kept = {}
  local promoted_order = {}
  local promoted_value = {}
  local promoted_kind = {}
  local default_order = {}
  local default_value = {}
  local dropped = {}

  for _, kv in ipairs(el.attributes) do
    local key, value = kv[1], kv[2]
    local prefix, name = key:match("^([^:]+):(.+)$")
    local typst_namespace = WRITES_TYPST and prefix == PANDOC_TYPST_PREFIX
    -- A claimed key is claimed for the writer, so it promotes under a custom
    -- format over that writer as it does under `typst` itself.
    local claimed = typst_namespace and claimed_typst_keys[name]
    if typst_namespace and not claimed and is_pandoc_typst_key(name, el.t) then
      -- Pandoc's Typst writer reads this key itself, so it keeps its prefix and
      -- passes through untouched. Promoting it would leave a name neither the
      -- writer nor Quarto's CSS filter consumes, and the styling would vanish.
      -- Outside a Typst render the key falls through and is dropped as usual.
      table.insert(kept, { key, value })
    elseif prefix and name then
      if prefix == DEFAULT_PREFIX then
        if default_value[name] == nil then
          table.insert(default_order, name)
        end
        default_value[name] = value
      else
        local kind = claimed and "exact" or match_prefix(prefix)
        -- An exact match always wins over an alias match for the same name.
        if kind == "exact" or (kind == "alias" and promoted_kind[name] ~= "exact") then
          if promoted_value[name] == nil then
            table.insert(promoted_order, name)
          end
          promoted_value[name] = value
          promoted_kind[name] = kind
        else
          table.insert(dropped, key)
        end
      end
    else
      table.insert(kept, { key, value })
    end
  end

  -- A default fallback applies only when no format-specific variant of the
  -- same name matched the active target format.
  for _, name in ipairs(default_order) do
    if promoted_value[name] == nil then
      table.insert(promoted_order, name)
      promoted_value[name] = default_value[name]
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

  if warn_on_drop and #dropped > 0 then
    log.log_warning(
      EXTENSION_NAME,
      "Dropped attribute(s) '" .. table.concat(dropped, "', '") ..
        "' on " .. describe_element(el) ..
        " because no prefix matched target format '" .. TARGET_FORMAT .. "'."
    )
  end

  el.attributes = final
  return el
end

--- Record a `claim-typst` entry, warning when it names a key prism already owns.
--- A key outside the reserved set is promoted with or without the option, so
--- naming it changes nothing and points at a typo or a stale configuration.
--- @param value any A single metadata value from the `claim-typst` option.
--- @return nil
local function claim_typst_key(value)
  local name = pandoc.utils.stringify(value)
  if name == '' then
    return nil
  end
  if not is_reserved_typst_name(name) then
    log.log_warning(
      EXTENSION_NAME,
      'claim-typst names "' .. name .. '", which is not a key Pandoc reads, ' ..
      'so it is promoted either way and the entry has no effect.'
    )
    return nil
  end
  claimed_typst_keys[name] = true
  return nil
end

--- Read the `extensions.prism` options from document metadata.
--- @param meta table The document metadata table.
--- @return nil
local function read_options(meta)
  local config = meta['extensions'] and meta['extensions'][EXTENSION_NAME]
  if not config then return nil end
  if config['warn-on-drop'] ~= nil then
    warn_on_drop = pandoc.utils.stringify(config['warn-on-drop']) == 'true'
  end
  -- A metadata scalar and a metadata list are both Lua tables, so the list has
  -- to be recognised through `pandoc.utils.type` rather than through `type`.
  local claim = config['claim-typst']
  if claim ~= nil then
    if pandoc.utils.type(claim) ~= 'List' then
      claim = { claim }
    end
    for _, entry in ipairs(claim) do
      claim_typst_key(entry)
    end
  end
  return nil
end

return {
  { Meta = read_options },
  { Div = process, Span = process, CodeBlock = process, Header = process }
}
