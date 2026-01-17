-- Defined SciTE Lua extension for batch language.


function OnChar(char)
    -- Event handler for entered char. Used for autocomplete and calltips.

    -- Get the character style at current position.
    local style = editor.StyleAt[editor:WordStartPosition(editor.CurrentPos, true)]

    -- No processing these styles.
    for id in pairs{[1]='comment', [3]='label'} do
        if style == id then
            editor:AutoCCancel()
            return true
        end
    end

    -- Get the current line text.
    local curline = editor:GetCurLine()

    -- Cancel autocomplete if line starts with : char or rem keyword.
    if string.match(curline, '^%s*:') or string.match(curline, '^%s*rem%W') then
        editor:AutoCCancel()
        return true
    end

    if char == ' ' then

        local last_word = string.match(curline, '(%w+) [\r\n]*$')

        -- AutoComplete to show arguments for setlocal.
        if last_word == 'setlocal' then
            -- Get the position.
            local pos = editor.CurrentPos
            local startpos = editor:WordStartPosition(pos, true)

            -- Show the autocomplete.
            editor.AutoCSeparator = 0x20
            editor:AutoCShow(pos - startpos, 'disabledelayedexpansion ' ..
                                             'disableextensions ' ..
                                             'enabledelayedexpansion ' ..
                                             'enableextensions')

            return true
        end

        -- AutoComplete to show labels for call and goto.
        if last_word == 'call' or last_word == 'goto' then
            local text = editor:GetText()
            local names

            -- Get the items for the autocomplete.
            names = {}

            for item in string.gmatch('\n' .. text, '\n%s*(:[%w_]+)') do
                table.insert(names, item)
            end

            table.unique(names)
            names = table.concat(names, ' ')

            -- Show the autocomplete.
            if names and names ~= '' then
                local pos = editor.CurrentPos
                local startpos = editor:WordStartPosition(pos, true)
                editor.AutoCSeparator = 0x20
                editor:AutoCShow(pos - startpos, names)
            end

            return true
        end
    end

    -- Calltip to show arguments for call.
    if string.match(curline, 'call :[%w_]+ [\r\n]*$') then

        -- Get the text from the editor pane.
        local text = editor:GetText()

        -- Get the label text for the search.
        local startcalltip = string.match(curline, 'call (:[%w_]+ )[\r\n]*$')

        -- Find start of the label and the end where caret is located.
        local findstart, findend = string.find(curline, ':[%w_]+ ')

        -- Get the calltip text.
        local calltip = string.match('\n' .. text, '\n%s*(' .. startcalltip .. '.-)\r?\n')

        -- Get the caret position.
        local pos = editor.CurrentPos

        -- Show the calltip.
        editor:CallTipShow(pos - (findend - findstart + 1), calltip)
        return true
    end
end
