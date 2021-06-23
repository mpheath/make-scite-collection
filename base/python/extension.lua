-- Defined SciTE Lua extension for python language.


function OnChar(char)
    -- Event handler for a character added to the editor.

    -- Get the character style at current position.
    local style = editor.StyleAt[editor:WordStartPosition(editor.CurrentPos, true)]

    -- No processing these styles.
    for id in pairs{[1]='comment',
                    [3]='dquote',
                    [4]='squote',
                    [6]='triple_squote',
                    [7]='triple_dquote',
                    [16]='f_string',
                    [17]='squote_fstring',
                    [18]='triple_squote_fstring',
                    [19]='triple_dquote_fstring'} do
        if style == id then
            return
        end
    end

    -- Get the current line text.
    local curline = editor:GetCurLine()

    if char == ' ' then

        -- AutoComplete import module names.
        if string.match(curline, "^%s*import ") then
            local pos = editor.CurrentPos
            local startpos = editor:WordStartPosition(pos, true)
            local len = pos - startpos
            local names = props['substylewords.11.1.$(file.patterns.py)']
            editor:AutoCShow(len, names)
            return true
        end

        -- AutoComplete exception names.
        if string.match(curline, "^%s*except ") then
            local pos = editor.CurrentPos
            local startpos = editor:WordStartPosition(pos, true)
            local len = pos - startpos
            local names = props['keywordclass1.python3']

            if names ~= '' then
                local filtered = {}

                names = string.gsub(names, 'Ellipsis ', '')

                for item in string.gmatch(names, '%u%a+') do
                    table.insert(filtered, item)
                end

                names = table.concat(filtered, ' ')

                editor:AutoCShow(len, names)
                return true
            end
        end
    end

    if char == '.' then

        local match

        -- AutoComplete variable name file [rw] methods.
        match = nil

        if string.match(curline, '%f[%w][rw]%.\r?\n?$') then
            local pos = editor.CurrentPos
            local startpos = editor:WordStartPosition(pos, true)
            local len = pos - startpos

            local names = 'buffer close closed detach encoding errors ' ..
                          'fileno flush isatty line_buffering mode name ' ..
                          'newlines read readable readline readlines ' ..
                          'reconfigure seek seekable tell truncate ' ..
                          'writable write write_through writelines'

            editor:AutoCShow(len, names)
            return true
        end

        -- AutoComplete variable name dict methods.
        match = nil

        for _, word in pairs{'dic', 'settings'} do
            if string.match(curline, '%f[%w]' .. word .. '%.\r?\n?$') then
                match = true
                break
            end
        end

        if match then
            local pos = editor.CurrentPos
            local startpos = editor:WordStartPosition(pos, true)
            local len = pos - startpos

            local names = 'clear copy fromkeys get items keys ' ..
                          'pop popitem setdefault update values'

            editor:AutoCShow(len, names)
            return true
        end

        -- AutoComplete variable name list methods.
        match = nil

        for _, word in pairs{'items', 'texts', 'contents', 'lines'} do
            if string.match(curline, '%f[%w]' .. word .. '%.\r?\n?$') then
                match = true
                break
            end
        end

        if match then
            local pos = editor.CurrentPos
            local startpos = editor:WordStartPosition(pos, true)
            local len = pos - startpos

            local names = 'append clear copy count extend ' ..
                          'index insert pop remove reverse sort'

            editor:AutoCShow(len, names)
            return true
        end

        -- AutoComplete literal or variable name number methods.
        match = nil

        for _, word in pairs{'count', 'idx', 'index', 'integer', 'number'} do
            if string.match(curline, '%f[%w]' .. word .. '%.\r?\n?$') then
                match = true
                break
            end
        end

        if match or string.match(curline, "[0-9]%.\r?\n?$") then
            local pos = editor.CurrentPos
            local startpos = editor:WordStartPosition(pos, true)
            local len = pos - startpos

            local names = 'as_integer_ratio bit_length conjugate denominator ' ..
                          'from_bytes imag numerator real to_bytes'

            editor:AutoCShow(len, names)
            return true
        end

        -- AutoComplete literal or variable name string methods.
        match = nil

        for _, word in pairs{'item', 'text', 'content', 'line'} do
            if string.match(curline, '%f[%w]' .. word .. '%.\r?\n?$') then
                match = true
                break
            end
        end

        if match or string.match(curline, "['\"]%.\r?\n?$") then
            local pos = editor.CurrentPos
            local startpos = editor:WordStartPosition(pos, true)
            local len = pos - startpos

            local names = 'capitalize casefold center count encode endswith ' ..
                          'expandtabs find format format_map index isalnum ' ..
                          'isalpha isascii isdecimal isdigit isidentifier ' ..
                          'islower isnumeric isprintable isspace istitle ' ..
                          'isupper join ljust lower lstrip maketrans ' ..
                          'partition removeprefix removesuffix replace ' ..
                          'rfind rindex rjust rpartition rsplit rstrip ' ..
                          'split splitlines startswith strip swapcase ' ..
                          'title translate upper zfill'

            editor:AutoCShow(len, names)
            return true
        end
    end
end


function OnKey(keycode, shift, ctrl, alt)
    -- Event handler for a keycode.

    -- On Enter key.
    if keycode == 13 then
        local curline = editor:GetCurLine()

        -- Get 1st word and last char.
        local startword, char = string.match(curline, '^%s*(%w+)(.?)$')

        -- AutoAdd missing colon after these keywords.
        for _, word in pairs{'else', 'except', 'finally', 'try'} do
            if word == startword then
                if char ~= ':' then
                    editor:AddText(':')
                end
            end
        end
    end
end
