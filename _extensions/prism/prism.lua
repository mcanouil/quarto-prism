--- Prism - Filter
--- @module prism
--- @license MIT License
--- @copyright 2026 Mickaël Canouil
--- @author Mickaël Canouil
--- @version 0.0.0
--- @brief Pandoc AST filter for prism.
--- @description A Quarto extension.

--- Extension name constant
local EXTENSION_NAME = 'prism'

--- Load modules as needed:
--- local str = require(quarto.utils.resolve_path('_modules/string.lua'):gsub('%.lua$', ''))
--- local log = require(quarto.utils.resolve_path('_modules/logging.lua'):gsub('%.lua$', ''))
--- local meta = require(quarto.utils.resolve_path('_modules/metadata.lua'):gsub('%.lua$', ''))

--- Process Div elements
--- @param el pandoc.Div
--- @return pandoc.Div
local function process_div(el)
  -- Check if this div should be processed
  if not el.classes:includes('prism') then
    return el
  end

  -- Process the element
  -- Add your transformation logic here

  return el
end

--- Process Header elements
--- @param el pandoc.Header
--- @return pandoc.Header
local function process_header(el)
  -- Add header processing logic here
  return el
end

return {
  { Div = process_div },
  { Header = process_header }
}
