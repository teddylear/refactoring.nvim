local code_utils = require("refactoring.code_generation.utils")
local ts = require("refactoring.code_generation.langs.typescript")

local function build_args(args, arg_types)
    local final_args = {}
    for i, arg in pairs(args) do
        local arg_key = arg .. ":"
        if arg_types[arg_key] ~= code_utils.default_func_param_type() then
            final_args[i] = arg .. ": " .. arg_types[arg_key]
        else
            final_args[i] = arg
        end
    end
    return final_args
end

---@param opts code_generation_function
local function tsx_function(opts)
    if opts.region_type == "jsx_element" then
        local args
        if opts.args_types ~= nil then
            args = build_args(opts.args, opts.args_types)
        else
            args = opts.args
        end

        return string.format(
            [[
%sfunction %s({%s}) {
return (
<>
%s
</>
)
%s}

]],
            opts.func_header,
            opts.name,
            table.concat(args, ", "),
            code_utils.stringify_code(opts.body),
            opts.func_header
        )
    else
        return ts["function"](opts)
    end
end

---@param opts code_generation_call_function
local function tsx_call_function(opts)
    if opts.region_type == "jsx_element" or opts.contains_jsx then
        local args = vim.tbl_map(function(arg)
            return string.format("%s={%s}", arg, arg)
        end, opts.args)
        return string.format("< %s %s/>", opts.name, table.concat(args, " "))
    else
        return ts.call_function(opts)
    end
end

---@type code_generation
local tsx = {
    default_printf_statement = ts.default_printf_statement,
    print = ts.print,
    default_print_var_statement = ts.default_print_var_statement,
    print_var = ts.print_var,
    comment = ts.comment,
    constant = ts.constant,
    pack = ts.pack,

    unpack = ts.unpack,

    ["return"] = ts["return"],
    ["function"] = tsx_function,
    function_return = ts.function_return,
    call_function = tsx_call_function,
    terminate = ts.terminate,

    class_function = ts.class_function,

    class_function_return = ts.class_function_return,

    call_class_function = ts.call_class_function,
}

return tsx
