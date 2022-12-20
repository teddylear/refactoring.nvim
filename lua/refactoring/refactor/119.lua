local Region = require("refactoring.region")
local utils = require("refactoring.utils")
local get_input = require("refactoring.get_input")
local Query = require("refactoring.query")
local Pipeline = require("refactoring.pipeline")
local selection_setup = require("refactoring.tasks.selection_setup")
local refactor_setup = require("refactoring.tasks.refactor_setup")
local post_refactor = require("refactoring.tasks.post_refactor")
local ensure_code_gen = require("refactoring.tasks.ensure_code_gen")

local M = {}

local function get_func_call_prefix(refactor)
    local bufnr_shiftwidth = vim.bo.shiftwidth
    local scope_region = Region:from_node(refactor.scope, refactor.bufnr)
    local _, scope_start_col, _, _ = scope_region:to_vim()
    local baseline_indent = math.floor(scope_start_col / bufnr_shiftwidth)
    local total_indent = baseline_indent + 1
    local opts = {
        indent_width = bufnr_shiftwidth,
        indent_amount = total_indent,
    }
    return refactor.code.indent(opts)
end

local function get_new_var_text(extract_node_text, refactor, var_name)
    local base_text = refactor.code.constant({
        name = var_name,
        value = extract_node_text,
    })

    if
        refactor.ts:is_indent_scope(refactor.scope)
        and refactor.ts:allows_indenting_task()
    then
        local indent_whitespace = get_func_call_prefix(refactor)
        local indented_text = {}
        indented_text[1] = indent_whitespace
        indented_text[2] = base_text
        return table.concat(indented_text, "")
    end

    return base_text
end

local function extract_var_setup(refactor)
    local extract_node = refactor.region_node

    -- local extract_node_text =
        -- table.concat(utils.get_node_text(extract_node), "")
    local extract_node_text = table.concat(
        { vim.treesitter.query.get_node_text(extract_node, refactor.bufnr) },
        ""
    )
    print("extract_node_text:", extract_node_text)

    local sexpr = extract_node:sexpr()
    print("sexpr:", sexpr)
    local occurrences =
        Query.find_occurrences(refactor.scope, sexpr, refactor.bufnr)

    local actual_occurrences = {}
    local texts = {}

    for _, occurrence in pairs(occurrences) do
        local text = table.concat(utils.get_node_text(occurrence), "")
        if text == extract_node_text then
            table.insert(actual_occurrences, occurrence)
            table.insert(texts, text)
        end
    end
    utils.sort_in_appearance_order(actual_occurrences)
    -- This is wrong, should be at least 1 occurence
    print("actual_occurrences:", vim.inspect(actual_occurrences))
    print("Hitting here!")
    print("Hitting here!")
    print("Hitting here!")

    local var_name = get_input("119: What is the var name > ")
    assert(var_name ~= "", "Error: Must provide new var name")

    refactor.text_edits = {}
    for _, occurrence in pairs(actual_occurrences) do
        local region = Region:from_node(occurrence, refactor.bufnr)
        table.insert(refactor.text_edits, {
            add_newline = false,
            region = region,
            text = var_name,
        })
    end

    local block_scope =
        refactor.ts.get_container(refactor.region_node, refactor.ts.block_scope)

    -- TODO: Add test for block_scope being nil
    if block_scope == nil then
        error("block_scope is nil! Something went wrong")
    end

    local unfiltered_statements = refactor.ts:get_statements(block_scope)

    -- TODO: Add test for unfiltered_statements being nil
    if #unfiltered_statements < 1 then
        error("unfiltered_statements is nil! Something went wrong")
    end

    local statements = vim.tbl_filter(function(node)
        return node:parent():id() == block_scope:id()
    end, unfiltered_statements)
    utils.sort_in_appearance_order(statements)

    -- TODO: Add test for statements being nil
    if #statements < 1 then
        error("statements is nil! Something went wrong")
    end

    local contained = nil
    local top_occurrence = actual_occurrences[1]
    for _, statement in pairs(statements) do
        if utils.node_contains(statement, top_occurrence) then
            contained = statement
        end
    end

    if not contained then
        error(
            "Extract var unable to determine its containing statement within the block scope, please post issue with exact highlight + code!  Thanks"
        )
    end

    table.insert(refactor.text_edits, {
        add_newline = false,
        region = utils.region_one_line_up_from_node(contained),
        text = get_new_var_text(extract_node_text, refactor, var_name),
    })
end

local function ensure_code_gen_119(refactor)
    local list = { "constant" }

    if refactor.ts:allows_indenting_task() then
        table.insert(list, "indent")
    end
    return ensure_code_gen(refactor, list)
end

function M.extract_var(bufnr, config)
    Pipeline:from_task(refactor_setup(bufnr, config))
        :add_task(function(refactor)
            return ensure_code_gen_119(refactor)
        end)
        :add_task(selection_setup)
        :add_task(function(refactor)
            extract_var_setup(refactor)
            return true, refactor
        end)
        :after(post_refactor.post_refactor)
        :run()
end

return M
