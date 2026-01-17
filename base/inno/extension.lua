-- Defined SciTE Lua extension for inno language.


function OnChar(char)
    -- Do a task on char.

    -- Get the current section and set the api property value to match.
    if string.match(char, '[%[%{a-zA-Z#]') then
        if SetSection(char) then
            return true
        end
    end
end


function OnKey(keycode)
    -- Do a task on key.

    local pos = editor.CurrentPos

    if keycode == 0x20 then
        local section = GetSectionName()

        if not section then
            return
        end

        if section == 'registry' then
            if editor.CharAt[pos] == 0x0D then
                local curline = editor:GetCurLine()

                -- Autocomplete for Root.
                if string.find(curline, 'Root:\r') then
                    editor:AddText(' ')
                    local start = editor:WordStartPosition(pos, true)

                    editor.AutoCSeparator = 0x20
                    editor:AutoCShow(pos - start, 'HKLM HKCU HKCR HKA HKU HKCC')
                    return true
                end

                -- Autocomplete for ValueType.
                if string.find(curline, 'ValueType:\r') then
                    editor:AddText(' ')
                    local start = editor:WordStartPosition(pos, true)

                    editor.AutoCSeparator = 0x20
                    editor:AutoCShow(pos - start, 'string dword expandsz ' ..
                                                  'multisz qword binary none')
                    return true
                end
            end
        end
    end
end


function GetSectionName()
    -- Get name of the current section.

    -- Get the current line number.
    local pos = editor.CurrentPos
    local linenum = editor:LineFromPosition(pos) - 1

    -- Find the current section.
    local section

    for index = linenum, 0, -1 do
        local line = editor:GetLine(index)
        section = string.match(line, '^%s*%[(%a+)%]%s*$')

        if section ~= nil then
            return string.lower(section)
        end
    end
end


function PrintFunctions()
    -- Print function and procedure definitions.
    -- Does not look for EOL semicolon marker.

    local linenum = 0

    while true do

        -- Get the next line.
        linenum = linenum + 1

        local line = editor:GetLine(linenum)

        if line == nil then
            break
        end

        -- Trim surrounding spaces from line.
        line = string.gsub(line, '^%s+', '')
        line = string.gsub(line, '%s+$', '')

        -- Print line if is a function or procedure definition.
        if string.find(line, '^function') then
            line = string.gsub(line, 'function', 'f', 1)
            PrintNumberedLine(linenum + 1, line)
        elseif string.find(line, '^procedure') then
            line = string.gsub(line, 'procedure', 'p', 1)
            PrintNumberedLine(linenum + 1, line)
        end
    end
end


function SetSection(char)
    -- Get the current section and set the api property value to match.

    local function SetApiProperty(cur, new)
        -- If the new property is different, then update and reload the properties.

        if new ~= nil and new ~= cur then
            props['api.$(file.patterns.inno)'] = new
            scite.ReloadProperties()
        end
    end

    -- Get the current property value.
    local curproperty = props['api.$(file.patterns.inno)']

    -- Table of inno section names.
    local list = {'Setup', 'Types', 'Components', 'Tasks', 'InstallDelete',
                  'Dirs', 'Files', 'Icons', 'INI', 'Registry', 'Run',
                  'UninstallDelete', 'UninstallRun', 'Languages',
                  'LangOptions', 'CustomMessages', 'Messages', 'Code'}

    -- Get current line text.
    local curline = editor:GetCurLine()

    -- Do not process lines starting with comment chars.
    if string.match(curline, '^%s*[%{/;]') then
        return true
    end

    -- If current line starts with [, autocomplete as section name.
    if char == '[' then
        if not string.match(curline, '^%s*%[[\r\n]-$') then
            return
        end

        local pos = editor.CurrentPos
        local start = editor:WordStartPosition(pos, true)

        local autoc = table.concat(list, ' ')
        autoc = string.gsub(autoc, ' ', '] ') .. ']'

        editor.AutoCSeparator = 0x20
        editor:AutoCShow(pos - start, autoc)
        return true
    end

    -- If current line starts with # and not followed by digit, set preprocess api.
    if string.match(curline, '^%s*#') then
        if string.match(curline, '^%s*#%d') == nil then
            SetApiProperty(curproperty,
                props['SciteDefaultHome'] .. '\\api\\innocommon.api;' ..
                props['SciteDefaultHome'] .. '\\api\\innopreprocessor.api')

            return
        end
    end

    -- Find the current section.
    local section = GetSectionName()

    -- Set the new property.
    local newproperty

    for _, v in pairs(list) do
        if section == string.lower(v) then
            if section == 'messages' or section == 'custommessages' then
                newproperty = ''
            else
                newproperty = props['SciteDefaultHome'] .. '\\api\\innocommon.api;' ..
                              props['SciteDefaultHome'] .. '\\api\\inno' .. section .. '.api'
            end

            break
        end
    end

    -- If not in a section, set new property to ''.
    if newproperty == nil and curproperty ~= '' then
        newproperty = ''
    end

    -- Set the new property.
    SetApiProperty(curproperty, newproperty)
end
