local Config = require("refactoring.config")
local TreeSitter = require("refactoring.treesitter")
local Point = require("refactoring.point")

-- TODO: Move refactor into the actual init function.  Seems weird
-- to have here.  Also make refactor object into a table instead of this
-- monstrosity

---@param input_bufnr number
---@param config c|Config
---@return fun(): true, Refactor
local function refactor_setup(input_bufnr, config)
    input_bufnr = input_bufnr or vim.api.nvim_get_current_buf()
    config = config or Config.get()

    return function()
        -- Setting bufnr to test bufnr
        local bufnr
        if config:get_test_bufnr() ~= nil then
            bufnr = config:get_test_bufnr()
        else
            bufnr = input_bufnr
        end

        local ts = TreeSitter.get_treesitter()

        local filetype = vim.bo[bufnr].filetype
        local root = ts:get_root()
        local win = vim.api.nvim_get_current_win()
        local cursor = Point:from_cursor()

        ---@class Refactor
        ---@field region RefactorRegion|nil
        ---@field region_node TSNode|nil
        ---@field scope TSNode|nil
        ---@field cursor_col_adjustment integer|nil
        ---@field text_edits LspTextEdit[] | {bufnr: integer|nil}[] | nil
        ---@field code code_generation
        local refactor = {
            ---@type {cursor: integer, highlight_start: integer|nil, highlight_end: integer|nil, func_call: integer|nil}
            whitespace = {
                cursor = vim.fn.indent(cursor.row),
            },
            cursor = cursor,
            code = config:get_code_generation_for(filetype),
            ts = ts,
            filetype = filetype,
            bufnr = bufnr,
            win = win,
            root = root,
            config = config,
            buffers = { bufnr },
        }

        return true, refactor
    end
end

return refactor_setup
