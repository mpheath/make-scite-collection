-- Defined SciTE Lua extension for lua language.


function FunctionHelp()
    -- Read from help.json and return help for current word.

    local currentword = props['CurrentWord']
    local scitedir = props['SciteDefaultHome']
    local file = assert(io.open(scitedir .. '\\lua\\lua.json'))

    -- Read the json file.
    if file ~= nil then
        content = file:read('a')
        file:close()
        t = json.decode(content)
    end

    -- Show currentword value.
    if t[currentword] ~= nil then
        print(t[currentword])
        return
    end

    -- Show all keys to select from as alternative.
    local list = {}

    for k, v in pairs(t) do
        table.insert(list, k)
    end

    table.sort(list)

    print(string.format('-- %q not found. Select from the following:', currentword))
    print(table.concat(list, '\n'))
end
