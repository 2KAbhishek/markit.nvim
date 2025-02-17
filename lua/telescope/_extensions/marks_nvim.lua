local telescope = require("telescope")
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local entry_display = require("telescope.pickers.entry_display")
local telescope_utils = require("telescope.utils")
local conf = require("telescope.config").values
local marks = require("marks")

-- Display helpers
local function create_displayer(is_bookmark)
  local items = is_bookmark and {
    { width = 1 },
    { width = 5 },
    { width = 20 },
    {},
  } or {
    { width = 3 },
    { width = 10 },
    {},
  }
  return entry_display.create({ separator = " ", items = items })
end

local function make_display(entry, displayer, conf_path)
  if entry.path then -- bookmark
    return displayer({
      { entry.group, "TelescopeResultsIdentifier" },
      { entry.lnum },
      { entry.line, "String" },
      { telescope_utils.transform_path(conf_path, entry.path) },
    })
  else -- mark
    return displayer({
      { entry.mark, "TelescopeResultsIdentifier" },
      { entry.lnum },
      { entry.line, "String" },
    })
  end
end

local function list_items(opts)
  opts = opts or {}
  local conf_path = { path_display = opts.path_display or conf.path_display or {} }

  -- Determine type and get results
  local results
  local title
  local is_bookmark = opts.group ~= nil or opts.bookmarks

  if is_bookmark then
      results = marks.bookmark_state:get_list(opts)
    if opts.group then
      title = string.format("Bookmark %s%s", opts.group, opts.project_only and " (Project)" or " (All)")
    else
      title = "All Bookmarks" .. (opts.project_only and " (Project)" or " (All)")
    end
  else
    results = opts.buffer_only and marks.mark_state:get_buf_list() or marks.mark_state:get_all_list()
    title = opts.buffer_only and "Buffer Marks" or "All Marks"
  end

  results = results or {}
  local displayer = create_displayer(is_bookmark)

  pickers.new(opts, {
    prompt_title = title,
    finder = finders.new_table({
      results = results,
      entry_maker = function(entry)
        entry.value = entry.mark or entry.group
        entry.ordinal = entry.line
        entry.display = function(e)
          return make_display(e, displayer, conf_path)
        end
        return entry
      end,
    }),
    sorter = conf.generic_sorter(opts),
    previewer = conf.grep_previewer(opts),
  }):find()
end

return telescope.register_extension({
  exports = {
    marks_list_buf = function(opts)
      opts = opts or {}
      opts.buffer_only = true
      return list_items(opts)
    end,
    marks_list_all = function(opts)
      return list_items(opts)
    end,
    bookmarks_list_all = function(opts)
      opts = opts or {}
      opts.bookmarks = true
      return list_items(opts)
    end,
  },
})
