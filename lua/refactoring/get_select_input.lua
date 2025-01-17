local Config = require("refactoring.config")

local async = require("plenary.async")
local select_input = async.wrap(function(items, prompt, format, kind, callback)
    vim.ui.select(items, {
        prompt = prompt,
        format_item = format,
        kind = kind,
    }, callback)
end, 5)

local function get_select_input(items, question, format)
    -- TODO: Extract to class
    local automation_input = Config.get():get_automated_input()
    if automation_input ~= nil then
        automation_input = tonumber(automation_input)
        return items[automation_input], automation_input
    end

    return select_input(items, question, format, nil)
end

return get_select_input
