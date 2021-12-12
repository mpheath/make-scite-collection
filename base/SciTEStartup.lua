-- Defined SciTE Startup Lua script.


-- Ensure SciTEDefaultHome is in the initial package path.
if string.find(package.path, props['SciteDefaultHome'] .. '\\lua\\?.lua', 1, true) == nil then
    package.path = props['SciteDefaultHome'] .. '\\lua\\?.lua;' ..
                   props['SciteDefaultHome'] .. '\\lua\\?\\init.lua;' ..
                   package.path
end

-- Import lua modules.
json = require('json')
require('os_path_ex')
require('string_ex')
require('table_ex')
require('rluawfx')

-- Make this property 0 for the statusbar.
if props['highlight.current.word'] == '' then
    props['highlight.current.word'] = '0'
end

-- Global settings table.
GlobalSettings = {

    -- GlobalTools various settings.
    ['tools'] = {

        -- Save selected name returned from GlobalTools.
        ['name'] = nil,

        -- Hide or show extended tools. true=all tools, false=less tools.
        ['extended'] = false},

    -- Paths that may need to be globally known.
    ['paths'] = {
        ['eskil'] = os.path.join(props['SciteDefaultHome'], 'eskil', 'eskil.exe'),
        ['frhed'] = os.path.join(props['SciteDefaultHome'], 'frhed', 'Frhed.exe'),
        ['winmerge'] = os.path.join(os.getenv('ProgramFiles'), 'WinMerge', 'WinMergeU.exe')}}


function CurSelCountBraces()
    -- Count braces in current selection.

    local text = editor:GetSelText()

    local list = {['('] = 0, [')'] = 0,
                  ['{'] = 0, ['}'] = 0,
                  ['['] = 0, [']'] = 0,
                  ['<'] = 0, ['>'] = 0}

    for item in string.gmatch(text, '[][(){}<>]') do
        list[item] = list[item] + 1
    end

    if list['('] > 0 or list[')'] > 0 then
        print(string.format('%-6s: %4s  (  ) %4s', 'Round', list['('], list[')']) )
    end

    if list['{'] > 0 or list['}'] > 0 then
        print(string.format('%-6s: %4s  {  } %4s', 'Curly', list['{'], list['}']) )
    end

    if list['['] > 0 or list[']'] > 0 then
        print(string.format('%-6s: %4s  [  ] %4s', 'Square', list['['], list[']']) )
    end

    if list['<'] > 0 or list['>'] > 0 then
        print(string.format('%-6s: %4s  <  > %4s', 'Angled', list['<'], list['>']) )
    end
end


function DebugPrintSelection()
    -- Debug print a selection or CurrentWord.

    -- Options.
    local use_markers = false

    -- Get the text to use for print.
    local text = editor:GetSelText()

    if text == '' then
        text = props['CurrentWord']
    end

    if text == '' then
        print('No selected text.')
        return
    end

    -- Goto end of line to end selection and add a new line.
    editor:LineEnd()
    editor:NewLine()

    -- Add a line to print the value.
    if props['FileExt'] == 'au3' then
        -- AutoIt3.
        editor:AddText('ConsoleWrite("' .. string.gsub(text, '"', '""') .. ': " & ' .. text .. ' & @CRLF) ; debug:')
    elseif props['FileExt'] == 'bat' or props['FileExt'] == 'cmd' then
        -- Batch.
        local _, repl = string.gsub(text, '%%', '%%')

        -- If not pair of % signs like %%A or %A%, make it %A%.
        if repl ~= 2 then
            if repl == 1 and string.sub(text, 1, 1) ~= '%' then
                text = string.gsub(text, '%%', '')
                text = '%' .. text .. '%'
            elseif repl == 0 then
                text = '%' .. text .. '%'
            end
        end

        editor:AddText('echo debug: ' .. string.gsub(text, '%%', '%%%%') .. ': ' .. text)
    elseif props['FileExt'] == 'lua' then
        -- Lua.
        editor:AddText('print("' .. string.gsub(text, '"', '\\\"') .. ':", ' .. text .. ') -- debug:')
    elseif props['FileExt'] == 'py' or props['FileExt'] == 'pyw' then
        -- Python.
        editor:AddText('print("' .. string.gsub(text, '"', '\\\"') .. ':", ' .. text .. ') # debug:')
    else
        return
    end

    -- Add a bookmark to keep track of the added line.
    if use_markers then
        editor:MarkerAdd(editor:LineFromPosition(editor.CurrentPos), 1)
    end
end


function DiffFileNameExt()
    -- Diff FileNameExt with fossil or git.

    local filenameext = props['FileNameExt']
    local filedir = props['FileDir']

    -- Validate.
    if filenameext == '' then
        print('Require a FileNameExt.')
        return
    end

    if filedir == '' then
        print('Require a FileDir.')
        return
    end

    -- Run fossil.
    if os.path.exist(os.path.join(filedir, '_FOSSIL_')) then
        local command = 'pushd "' .. filedir .. '" && ' ..
                        'fossil diff "' .. filenameext .. '"'

        local file = io.popen(command)

        if file ~= nil then
            for line in file:lines() do
                print(line)
            end

            file:close()
        end

        return

    -- Run Git.
    elseif os.path.exist(os.path.join(filedir, '.git') .. os.path.sep) then

        local command = 'pushd "' .. filedir .. '" && ' ..
                        'git diff "' .. filenameext .. '"'

        local file = io.popen(command)

        if file ~= nil then
            for line in file:lines() do
                print(line)
            end

            file:close()
        end

        return
    else
        print('No repo files found.')
    end
end


function EskilFilePath()
    -- Run Eskil to diff FilePath with a checkout.

    local filepath = props['FilePath']

    -- Validate.
    if filepath == '' then
        print('Require a filepath.')
        return
    end

    -- Run Eskil.
    if os.path.sep == '\\' then
        local app = GlobalSettings['paths']['eskil']
        local command = 'start "" "' .. app .. '" "' .. filepath .. '"'

        os.execute(command)
    else
        print('No command set for this operating system.')
    end
end


function FrhedFilePath()
    -- Run Frhed to hex edit FilePath.

    local filepath = props['FilePath']

    -- Validate.
    if filepath == '' then
        print('Require a filepath.')
        return
    end

    -- Run Frhed.
    if os.path.sep == '\\' then
        local app = GlobalSettings['paths']['frhed']
        local command = 'start "" "' .. app .. '" "' .. filepath .. '"'

        os.execute(command)
    else
        print('No command set for this operating system.')
    end
end


function GlobalTools()
    -- List all local lua functions for tool menu.

    -- List of tools.
    local list = {}

    list['ClearAll']  = function()
                            editor:AnnotationClearAll()

                            for i = 0, 24 do
                                editor:MarkerDeleteAll(i)
                            end
                        end

    list['ClearAnnotations']  = function()
                                    editor:AnnotationClearAll()
                                end

    list['ClearBookmarks']    = function()
                                    editor:MarkerDeleteAll(1)
                                end

    list['ClearErrormarks']   = function()
                                    editor:MarkerDeleteAll(0)
                                end

    list['ClearOthermarks']   = function()
                                    for i = 2, 24 do
                                        editor:MarkerDeleteAll(i)
                                    end
                                end

    list['CopyFileDir']   = function()
                                editor:CopyText(props['FileDir'])
                            end

    list['CopyFileName']  = function()
                                editor:CopyText(props['FileName'])
                            end

    list['CopyFileNameExt']   = function()
                                    editor:CopyText(props['FileNameExt'])
                                end

    list['CopyFilePath']  = function()
                                editor:CopyText(props['FilePath'])
                            end

    list['CurSelCountBraces']     = CurSelCountBraces
    list['DiffFileNameExt']       = DiffFileNameExt

    if os.path.exist(GlobalSettings['paths']['eskil']) then
        list['EskilFilePath'] = EskilFilePath
    end

    if os.path.exist(GlobalSettings['paths']['frhed']) then
        list['FrhedFilePath'] = function()
                                    FrhedFilePath()
                                end
    end

    list['InsertDate']            = InsertDate
    list['OpenAbbrevFile']        = OpenAbbrevFile
    list['OpenApiFile']           = OpenApiFile
    list['OpenChmFile']           = OpenChmFile
    list['OpenFileDir']           = OpenFileDir
    list['OpenHtaFile']           = OpenHtaFile
    list['OpenLuaExtensionFile']  = OpenLuaExtensionFile

    if GlobalSettings['tools']['extended'] then
        list['OpenSciteVarsFile'] = OpenSciteVarsFile
    end

    list['PrintApiKeywords']      = PrintApiKeywords
    list['PrintApiLuaPropsFiles'] = PrintApiLuaPropsFiles
    list['PrintAsciiTable']       = PrintAsciiTable
    list['PrintCommentLines']     = PrintCommentLines

    list['PrintCommentedCodeLines']   = function()
                                            PrintCommentLines('code')
                                        end

    list['PrintFindText'] = PrintFindText

    if GlobalSettings['tools']['extended'] then
        list['PrintGlobalNames name_only']    = function()
                                                    PrintGlobalNames(0)
                                                end

        list['PrintGlobalNames brief']    = function()
                                                PrintGlobalNames(1)
                                            end

        list['PrintGlobalNames informative']  = function()
                                                    PrintGlobalNames(2)
                                                end

        list['PrintGlobalNames calltip_style']    = function()
                                                        PrintGlobalNames(3)
                                                    end

        list['PrintGlobalTables _G brief']    = function()
                                                    PrintGlobalTables(_G, false, true)
                                                end

        list['PrintGlobalTables _G extra']    = function()
                                                    PrintGlobalTables(_G, true, true)
                                                end

        list['PrintGlobalTables .* brief']    = function()
                                                    PrintGlobalTables(nil, false, false)
                                                end

        list['PrintGlobalTables .* extra']    = function()
                                                    PrintGlobalTables(nil, true, true)
                                                end
    end

    list['PrintReminders']              = PrintReminders

    if GlobalSettings['tools']['extended'] then
        list['PrintSciteVars']          = PrintSciteVars
    end

    list['ReplaceSelEscape']            = ReplaceSelEscape
    list['ReplaceSelSortLines']         = ReplaceSelSortLines
    list['ReplaceSelSortList']          = ReplaceSelSortList
    list['ReplaceSelWrapList']          = ReplaceSelWrapList
    list['SelectCalltipColour']         = SelectCalltipColour
    list['StartExeFile']                = StartExeFile
    list['StripTrailingSpaces']         = StripTrailingSpaces
    list['ToggleCodePage']              = ToggleCodePage
    list['ToggleDimComments']           = ToggleDimComments
    list['ToggleExtendedTools']         = ToggleExtendedTools
    list['ToggleHighlightCurrentWord']  = ToggleHighlightCurrentWord
    list['ToggleMonospaceFont']         = ToggleMonospaceFont

    if os.path.exist(GlobalSettings['paths']['winmerge']) then
        list['WinMergeFilePath']          = WinMergeFilePath

        list['WinMergeFilePath unsaved']  = function()
                                                WinMergeFilePath('unsaved')
                                            end
    end

    -- Get the key names and sort.
    local names = {}

    for k in pairs(list) do
        table.insert(names, k)
    end

    table.sort(names)

    -- Get the id of the last selected name.
    local id = 0

    if GlobalSettings['tools']['name'] then
        for k, v in pairs(names) do
            if v == GlobalSettings['tools']['name'] then
                id = k - 1
            end
        end
    end

    -- Get the selection.
    local title = 'GlobalTools'

    if GlobalSettings['tools']['extended'] then
        title = title .. ' Extended'
    end

    local result = ListBox(names, title, id)

    if result ~= nil then
        local name = names[result + 1]
        GlobalSettings['tools']['name'] = name
        list[name]()
    end
end


function InsertDate()
    -- Insert or replace date in the format of 'yyyy-mm-dd'.

    local text = editor:GetSelText()
    local date = os.date('%Y-%m-%d')

    if text == '' or string.match(text, '^%d%d%d%d%-%d%d%-%d%d$') ~= nil then
        editor:ReplaceSel(date)
    else
        editor:AddText(date)
    end
end


function OnBeforeSave(filename)  --luacheck: no unused args
    -- Event handler for about to save file.

    -- Check if ensure final line end setting is enabled.
    if props['ensure.final.line.end'] == '1' then

        -- Get data.
        local text = editor:GetText()

        -- Check if text is only a line end sequence.
        if text == '\r\n' or text == '\n' then

            -- Question YesNo to rewrite as empty file.
            if MsgBox('The setting ensure.final.line.end may have caused an ' ..
                      'insertion of a newline sequence into a blank document.\n\n' ..
                      'Do you want the document to be cleared before ' ..
                      'the save to file?', 'Sc1', 0x24) == 6 then

                editor:ClearAll()
            end
        end
    end
end


function OnOpen(filename)  --luacheck: no unused args
    -- Event handler for opening a file tab.

    -- Update the context menu.
    UserContextMenu()
end


function OnSwitchFile()
    -- Event handler for switching file tab.

    -- Update the context menu.
    UserContextMenu()

    -- Toggle clean command on or off.
    local filedir = props['FileDir']
    local file

    if props['FileDir'] ~= props['SciteDefaultHome'] then
        file = io.open(filedir .. '\\clean.lst')
    end

    if file == nil then
        props['command.clean.*'] = nil
        props['command.clean.subsystem.*'] = nil
    else
        file:close()
        props['command.clean.*'] = 'py -u -B "$(SciteDefaultHome)\\py\\tool_clean.py"'
        props['command.clean.subsystem.*'] = '0'
    end
end


function OnUserListSelection(id, item)
    -- Event handler for GetUserListSelection().
    -- Local id events use >= 100.
    -- Extension id events use < 100.

    if id < 100 then
        GetUserListSelection(id, item)
    elseif id == 100 then
        -- Event from ...().
        print('Triggered event 100')
    end

    return true
end


function OpenAbbrevFile()
    -- Open a abbreviation file.

    -- Get the file list.
    local list = {}

    local command = 'cmd /q /c ' ..
                    'pushd "' .. props['SciteDefaultHome'] .. '" ^&^& ' ..
                    'for /d %A in (*) do ' ..
                    'if exist "%~A\\abbrev.properties" ' ..
                    'echo "%~nxA\\abbrev.properties"'

    local file = io.popen(command)

    for line in file:lines() do
        table.insert(list, (string.gsub(line, '"', '')))
    end

    file:close()

    -- Get the selection.
    local result = ListBox(list, 'OpenAbbrevFile')

    if result ~= nil then
        local item = list[result + 1]
        scite.Open(props['SciteDefaultHome'] .. '\\' .. item)
    end
end


function OpenApiFile()
    -- Open a api file.

    -- Get the file list.
    local list = {}

    local command = 'cmd /q /c ' ..
                    'pushd "' .. props['SciteDefaultHome'] .. '" ^&^& ' ..
                    'for %A in (api\\*.api) do echo %A'

    local file = io.popen(command)

    for line in file:lines() do
        table.insert(list, (string.gsub(line, '"', '')))
    end

    file:close()

    -- Get the selection.
    local result = ListBox(list, 'OpenApiFile')

    if result ~= nil then
        local item = list[result + 1]
        scite.Open(props['SciteDefaultHome'] .. '\\' .. item)
    end
end


function OpenChmFile()
    -- Open a chm file.

    -- Get the file list.
    local list = {}

    local command = 'cmd /q /c ' ..
                    'pushd "' .. props['SciteDefaultHome'] .. '" ^&^& ' ..
                    'for /d %A in (*) do ' ..
                    'for %B in ("%~A\\*.chm") do ' ..
                    'echo %B'

    local file = io.popen(command)

    for line in file:lines() do
        table.insert(list, (string.gsub(line, '"', '')))
    end

    file:close()

    -- Main help file for SciTE.
    if os.path.exist(props['SciteDefaultHome'] .. '\\scite.chm') then
        table.insert(list, 'scite.chm')
    end

    -- Some chm files external to SciTE directory.
    if os.path.exist(props['SciteDefaultHome'] .. '\\..\\AutoIt3\\Au3Menu.chm') then
        table.insert(list, '..\\AutoIt3\\Au3Menu.chm')
    end

    if os.path.exist(props['SciteDefaultHome'] .. '\\..\\AutoIt3\\AutoIt.chm') then
        table.insert(list, '..\\AutoIt3\\AutoIt.chm')
    end

    table.sort(list)

    -- Get the selection.
    local result = ListBox(list, 'OpenChmFile')

    if result ~= nil then
        local item = list[result + 1]
        Run('"' .. props['SciteDefaultHome'] .. '\\' .. item .. '"', true)
    end
end


function OpenFileDir()
    -- Open the current files directory.

    local filedir = props['FileDir']

    if os.path.sep == '\\' then

        -- This command is for Windows.
        os.execute('explorer "' .. filedir .. '"')
    else
        print('No command set for this operating system.')
    end
end


function OpenHtaFile()
    -- Open a hta file.

    -- Get the file list.
    local list = {}

    local command = 'cmd /q /c ' ..
                    'pushd "' .. props['SciteDefaultHome'] .. '" ^&^& ' ..
                    'for /d %A in (*) do ' ..
                    'for %B in ("%~A\\*.hta") do ' ..
                    'echo "%~B"'

    local file = io.popen(command)

    for line in file:lines() do
        table.insert(list, (string.gsub(line, '"', '')))
    end

    file:close()

    -- Get the selection.
    local result = ListBox(list, 'OpenHtaFile')

    if result ~= nil then
        local item = list[result + 1]
        os.execute('start "" "' .. props['SciteDefaultHome'] .. '\\' .. item .. '"')
    end
end


function OpenLuaExtensionFile()
    -- Open a lua extension file.

    -- Get the file list.
    local list = {}

    local command = 'cmd /q /c ' ..
                    'pushd "' .. props['SciteDefaultHome'] .. '" ^&^& ' ..
                    'for /d %A in (*) do ' ..
                    'if exist "%~A\\extension.lua" ' ..
                    'echo "%~nxA\\extension.lua"'

    local file = io.popen(command)

    for line in file:lines() do
        table.insert(list, (string.gsub(line, '"', '')))
    end

    file:close()

    -- Get the selection.
    local result = ListBox(list, 'OpenLuaExtensionFile')

    if result ~= nil then
        local item = list[result + 1]
        scite.Open(props['SciteDefaultHome'] .. '\\' .. item)
    end
end


function OpenSciteVarsFile()
    -- Open scitevars.cfg that PrintSciteVars() can read.

    scite.Open('scitevars.cfg')
end


function PrintApiKeywords()
    -- Print keywords from api files, like those used in autocomplete.

    -- Get api file paths and split into a table.
    local api_paths = props['APIPath']

    if api_paths == '' then
        return
    end

    api_paths = string.split(api_paths, ';')

    -- Read api files to get the keywords.
    local keywords = {}

    for i = 1, #api_paths do
        local file = io.open(api_paths[i])

        if file ~= nil then
            for line in file:lines() do
                if line ~= '' then
                    local keyword, repl = string.gsub(line, '^([^%(%? ]+)(.*)$', '%1')

                    if repl > 0 then
                        table.insert(keywords, keyword)
                    end
                end
            end

            file:close()
        end
    end

    -- Unique sort and print keywords.
    table.unique(keywords)

    for i = 1, #keywords do
        print(keywords[i])
    end
end


function PrintApiLuaPropsFiles()
    -- Print api, lua and properties files.

    -- Build the command.
    local command = 'cmd /q /c ' ..
                    'pushd "' .. props['SciteDefaultHome'] .. '" ^&^& ' ..
                    '(for %A in (api\\*.api) do echo "%~A"^) ^& ' ..
                    '(for /d %A in (*) do ' ..
                    'if exist "%~A\\extension.lua" ' ..
                    'echo "%~nxA\\extension.lua"^) ^& ' ..
                    'dir /b *.properties'

    -- Run the command and print the output.
    local file = io.popen(command)

    for line in file:lines() do
        print((string.gsub(line, '"', '')))
    end

    file:close()
end


function PrintAsciiTable()
    -- Print ASCII table of decimal, hexadecimal and characters.

    for i = 0, 255 do
        print(string.format('%4s  %2x  %s', i, i, string.char(i)))
    end
end


function PrintCommentLines(mode)
    -- Get comment lines from the source in the editor.

    -- Options.
    local use_markers = false

    -- Get data.
    local text = editor:GetText()
    local fileext = props['FileExt']

    if text == nil or text == '' then
        print('No editor text.')
        return
    end

    if fileext == '' then
        print('No file extension.')
        return
    end

    -- Get the pattern from the file extension.
    local chars = {['au3'] = '^%s*(;[^~].*)$',
                   ['cmd'] = '^%s*([rR][eE][mM]%s*[^~].*)$',
                   ['iss'] = '^%s*(;[^~].*)$',
                   ['lua'] = '^%s*(%-%-[^~].*)$',
                   ['pas'] = '^%s*(#[^~].*)$',
                   ['php'] = '^%s*(#[^~].*)$',
                   ['properties'] = '^%s*(#[^~].*)$',
                   ['ps1'] = '^%s*(#[^~].*)$',
                   ['py']  = '^%s*(#[^~].*)$'}

    local pattern = chars[fileext]

    if pattern == nil then
        print('No comment pattern.')
        return
    end

    -- Modify pattern for commented code.
    if mode == 'code' then
        pattern = string.gsub(pattern, '%[%^%~%]', '~')
    end

    -- Set an alternative pattern.
    local alt_pattern

    if fileext == 'cmd' then
        alt_pattern = string.gsub(pattern, '%[rR.-mM%]', '::')
    elseif fileext == 'iss' then
        alt_pattern = string.gsub(pattern, '%(;', '(//')
    end

    local markerNumber

    if use_markers then
        -- Clear annotations and markers.
        markerNumber = 1
        editor:AnnotationClearAll()
        editor:MarkerDeleteAll(markerNumber)

        -- Set arrows as markers if custom markers.
        if markerNumber > 1 then
            editor:MarkerDefine(markerNumber, SC_MARK_ARROWS)
        end
    end

    -- Print each line that is a comment line.
    local lines = string.split(text, '\r?\n')

    for i = 1, #lines do
        local line = string.match(lines[i], pattern)

        if line == nil then
            if fileext == 'cmd' or fileext == 'iss' then
                line = string.match(lines[i], alt_pattern)
            end
        end

        if line ~= nil then
            if use_markers then
                editor:MarkerAdd(i - 1, markerNumber)
            end

            PrintNumberedLine(i, line)
        end
    end
end


function PrintFindText()
    -- Print the lines containing the text.
    -- Source: http://lua-users.org/wiki/SciteMiscScripts

    -- Options.
    local use_markers = false

    -- Get the text.
    local findtext = editor:GetSelText()

    local flags = 0

    if findtext == '' then
        findtext = props['CurrentWord']
        flags = flags | SCFIND_MATCHCASE | SCFIND_WHOLEWORD
    end

    if findtext == '' then
        print('No text to find.')
        return
    end

    local markerNumber

    if use_markers then
        -- Clear annotations and markers.
        markerNumber = 1
        editor:AnnotationClearAll()
        editor:MarkerDeleteAll(markerNumber)

        -- Set arrows as markers if custom markers.
        if markerNumber > 1 then
            editor:MarkerDefine(markerNumber, SC_MARK_ARROWS)
        end
    end

    -- Find the text, print the lines and print the result stats.
    local s, e = editor:findtext(findtext, flags, 0)
    local m = editor:LineFromPosition(s) - 1
    local count = 0

    while s do
        local l = editor:LineFromPosition(s)

        if l ~= m then
            count = count + 1
            local line = editor:GetLine(l)

            if use_markers then
                editor:MarkerAdd(l, markerNumber)
            end

            PrintNumberedLine(l + 1, line)
            m = l
        end

        s, e = editor:findtext(findtext, flags, e + 1)
    end
end


function PrintGlobalNames(mode)
    -- Print global names for extraordinary use.

    -- Mode 0 name_only.
    --      1 brief.
    --      2 informative.
    --      3 calltip_style.
    if mode == nil then
        mode = 2
    end

    local list = {}

    local function InspectTable(key, value)
        local fstring

        for k, v in pairs(value) do
            if mode == 0 then
                fstring = key .. '.' .. k
            elseif mode == 1 then
                if type(v) == 'function' then
                    fstring = string.format('%s()', key .. '.' .. k)
                else
                    fstring = string.format('%s', key .. '.' .. k)
                end
            elseif mode == 2 then
                if type(v) == 'function' then
                    fstring = string.format('%s()', key .. '.' .. k)
                elseif type(v) == 'string' or type(v) == 'number' then
                    fstring = string.format('%s = %s', key .. '.' .. k, v)
                elseif type(v) == 'table' then
                    fstring = string.format('%s{,}', key .. '.' .. k)
                else
                    fstring = string.format('%s', key .. '.' .. k)
                end
            else
                if type(v) == 'function' then
                    fstring = string.format('%s () [function]', key .. '.' .. k)
                else
                    fstring = string.format('%s (-) [%s]', key .. '.' .. k, type(v))
                end
            end

            table.insert(list, fstring)
        end
    end

    for k, v in pairs(_G) do
        if k ~= '_G' then
            local fstring

            if mode == 0 then
                fstring = k
            elseif mode == 1 then
                if type(v) == 'function' then
                    fstring = string.format('%s()', k)
                else
                    fstring = string.format('%s', k)
                end
            elseif mode == 2 then
                if type(v) == 'function' then
                    fstring = string.format('%s()', k)
                elseif type(v) == 'string' or type(v) == 'number' then
                    fstring = string.format('%s = %s', k, v)
                elseif type(v) == 'table' then
                    fstring = string.format('%s{,}', k)
                else
                    fstring = string.format('%s', k)
                end
            else
                if type(v) == 'function' then
                    fstring = string.format('%s () [function]', k)
                else
                    fstring = string.format('%s (-) [%s]', k, type(v))
                end
            end

            table.insert(list, fstring)

            if type(v) == 'table' then
                InspectTable(k, v)
            end
        end
    end

    table.sort(list)

    for _, v in pairs(list) do
        print(v)
    end
end


function PrintGlobalTables(arg_table, arg_extra, skip_G)
    -- Print lua tables for observation.

    local function TypeToString(object)
        -- Get a string from an object and possibly remove excess substrings.

        local obj_string = tostring(object)

        -- Modify function types, table types...
        if type(object) ~= 'string' then
            obj_string = string.gsub(obj_string, '(%w*: )0*([1-9a-fA-F][0-9a-fA-F]*)', '%1%2')
        end

        -- Modify stderr, stdin and stdout type strings.
        if type(object) == 'userdata' then
            obj_string = string.gsub(obj_string, 'file %(0*([1-9a-fA-F][0-9a-fA-F]*)%)', 'file (%1)')
        end

        return obj_string
    end

    local function TypeLetter(object)
        for _, v in pairs{{' ', 'boolean'},
                          {' ', 'function'},
                          {' ', 'nil'},
                          {' ', 'number'},
                          {' ', 'string'},
                          {'>', 'table'},
                          {' ', 'thread'},
                          {' ', 'userdata'}} do
            if type(object) == v[2] then
                return v[1]
            end
        end
    end

    local function KeysSorted(table_object)
        -- Sort keys.
        local list = {}

        for k in pairs(table_object) do
            table.insert(list, k)
        end

        table.sort(list)

        return list
    end

    if arg_table == '' or arg_table == nil then
        arg_table = package.loaded
    end

    if arg_extra ~= false then
        if arg_extra == '' or arg_extra == nil then
            arg_extra = false
        else
            arg_extra = true
        end
    end

    if skip_G == '' or skip_G == nil then
        skip_G = false
    end

    -- _G table once.
    local table_G_parsed = 0

    if arg_table == _G then
        table_G_parsed = 1
    end

    -- Sort keys.
    local sorted1 = KeysSorted(arg_table)

    for i1 = 1, #sorted1 do
        local k1, v1 = sorted1[i1], arg_table[ sorted1[i1] ]

        if arg_table == _G and v1 == _G then
            goto label_1
        end

        print(string.format('%s %-25s %s', TypeLetter(v1), k1, TypeToString(v1)))

        if type(v1) == 'table' then

            -- Set table _G parsed if found.
            if k1 == '_G' and skip_G then
                table_G_parsed = table_G_parsed + 1
            end

            -- Sort keys.
            local sorted2 = KeysSorted(v1)

            for i2 = 1, #sorted2 do
                local k2, v2 = sorted2[i2], v1[ sorted2[i2] ]

                print(string.format('%s %-28s %-25s %s', TypeLetter(v2), '', k2, TypeToString(v2)))

                if type(v2) == 'table' and arg_extra then

                    -- Skip table _G if found.
                    if k2 == '_G' and skip_G then
                        if table_G_parsed > 0 then
                            goto label_2
                        elseif type(v2) == 'table' then
                            table_G_parsed = table_G_parsed + 1
                        end
                    end

                    -- Sort keys.
                    local sorted3 = KeysSorted(v2)

                    for i3 = 1, #sorted3 do
                        local k3, v3 = sorted3[i3], v2[ sorted3[i3] ]

                        print(string.format('%s %-31s %-25s %-20s %s', TypeLetter(v3), '', '', k3, TypeToString(v3)))
                    end
                    ::label_2::
                end
            end
        end
        ::label_1::
    end
end


function PrintNumberedLine(number, line)
    -- Print filename, line number and trimmed line text.

    local line_trimmed = string.gsub(line, '^%s*(.-)%s*$', '%1')
    print(string.format('%s:%04i: %s', props['FileNameExt'], number, line_trimmed))
end


function PrintReminders()
    -- Find reminder lines in source. Code concept from RSciTE.

    local line, line_lower

    local list_tag = {'debug', 'reminder', 'test', 'testing', 'todo'}

    print('Search keywords: ' .. table.concat(list_tag, ', '))

    for i = 0, editor.LineCount - 1 do
        line = editor:GetLine(i)
        line_lower = string.lower(line)

        for _, item in ipairs(list_tag) do
            if string.find(line_lower, item .. ':[ \r\n]') then
                PrintNumberedLine(i + 1, line)
                break
            end
        end
    end
end


function PrintSciteVars()
    -- Print SciTE property variables.

    -- SciTE variables defined in help under "Properties file" section.
    local scite_vars = {'APIPath', 'AbbrevPath', 'Appearance', 'Contrast',
                        'CurrentMessage', 'CurrentSelection', 'CurrentWord',
                        'FileDir', 'FileExt', 'FileName', 'FileNameExt',
                        'FilePath', 'Language', 'Replacements', 'ScaleFactor',
                        'SciteDefaultHome', 'SciteDirectoryHome',
                        'SciteUserHome', 'SelectionEndColumn',
                        'SelectionEndLine', 'SelectionStartColumn',
                        'SelectionStartLine', 'SessionPath'}

    -- Add custom variables read from a text file.
    local file = io.open('scitevars.cfg')

    if file ~= nil then
        local other_vars = {}
        print('scitevars.cfg:')

        for line in file:lines() do
            if line ~= '' then
                if string.find(line, '^[#;]') == nil then
                    table.insert(other_vars, line)
                end
            end
        end

        -- Sort for the print.
        table.sort(other_vars)

        -- Merge other variables with scite variables.
        for i = 1, #other_vars do
            print('', other_vars[i])
            table.insert(scite_vars, other_vars[i])
        end
    end

    -- Sort all variables.
    table.sort(scite_vars)

    -- Output the variable names and values.
    for i = 1, #scite_vars do
        local value = props[ scite_vars[i] ]

        if value ~= '' then
            print(scite_vars[i] .. ':\n', value)
        end
    end
end


function ReplaceSelEscape()
    -- Escape special characters in some languages.

    local text = editor:GetSelText()
    local fileext = props['FileExt']

    if text == '' or fileext == '' then
        return
    end

    if fileext == 'api' then
        text = string.gsub(text, '\\', '\\\\')

    elseif fileext == 'bat' or fileext == 'cmd' then
        local special = {'|', '&', '<', '>', ')', '='}

        for i = 1, #special do
            text = string.gsub(text, '%' .. special[i], '^%1')
        end

        text = string.gsub(text, '%%', '%%%%')

    elseif fileext == 'hta' or fileext == 'html' then
        local special = {['&']='&amp;', ['<']='&lt;', ['>']='&gt;'}

        for k, v in pairs(special) do
            text = string.gsub(text, k, v)
        end

    elseif fileext == 'lua' then
        text = string.gsub(text, '\\', '\\\\')

    elseif fileext == 'py' or fileext == 'pyw' then
        text = string.gsub(text, '\\', '\\\\')

    elseif fileext == 'sql' then
        text = string.gsub(text, "'", "''")

    else
        print('The filetype .' .. fileext .. ' is not set for escaping.')
        return
    end

    editor:ReplaceSel(text)
end


function ReplaceSelSortLines()
    -- Sorts a selection of text by line.

    -- Get the current selection text.
    local text = editor:GetSelText()

    if text == '' then
        print('Select lines to sort.\n\n' ..
              'Example:\n' ..
              '  item3\n  item1\n  item2\n\n' ..
              'changes to:\n' ..
              '  item1\n  item2\n  item3')
        return
    end

    -- Get the line separator.
    local sep = string.match(text, '\r?\n')

    if sep == nil then
        print('No line separator.')
        return
    end

    -- Ensure text has a trailing newline sequence.
    text = text .. sep

    -- Insert each line into a table and sort.
    local lines = {}

    for line in string.gmatch(text, '(.-)\r?\n') do
        if line ~= '' then
            table.insert(lines, line)
        end
    end

    table.sort(lines)

    -- Join the lines into a string.
    text = table.concat(lines, sep)

    -- Replace the selection.
    editor:ReplaceSel(text)
end


function ReplaceSelSortList()
    -- Sort a list of items.

    -- Get the string.
    local text = editor:GetSelText()

    -- Check if string is empty.
    if text == '' then
        print('Select a list to wrap.\n\n' ..
              'Example:\n' ..
              '  ["item3", "item1", "item2"]\n\n' ..
              'changes to:\n' ..
              '  ["item1", "item2", "item3"]')
        return
    end

    -- Check for braces and remove braces if needed.
    local brace
    local bo, bc = string.match(text, '%s*([%[%{%(]).*([%]%}%)])%s*')

    if (bo == '[' and bc == ']') or
       (bo == '{' and bc == '}') or
       (bo == '(' and bc == ')') then
        brace = true
        text = string.gsub(text, '%s*[%[%{%(](.*)[%]%}%)]%s*', '%1')
    end

    -- Sort separated items into a table.
    local list = {}
    local sep = ','
    local mode_comma = string.find(text, ',') or string.find(text, '[\'"]')

    if mode_comma then
        if string.find(text, ', ') then
            sep = ', '
        end
    else
        if string.find(text, ';') then
            if string.find(text, '; ') then
                sep = '; '
            else
                sep = ';'
            end
        elseif string.find(text, ' ') then
            sep = ' '
        elseif string.find(text, '\t') then
            sep = '\t'
        end
    end

    for item in string.gmatch(text, '%s*([^' .. sep .. ']*)%s*') do
        table.insert(list, item)
    end

    table.sort(list)

    -- Rebuild a new string.
    local newstring = table.concat(list, sep)

    -- Add braces if needed and return the new string.
    if brace then
        newstring = bo .. newstring .. bc
    end

    -- Replace selection.
    editor:ReplaceSel(newstring)
end


function ReplaceSelWrapList()
    -- Wrap a list of items into multiple lines.

    -- Get the string.
    local text = editor:GetSelText()

    -- Check if string is empty.
    if text == '' then
        print('Select a list to wrap.\n\n' ..
              'Example:\n' ..
              '  ["item1", "item2", "item3"]\n\n' ..
              'changes to:\n' ..
              '  ["item1",\n' ..
              '   "item2",\n' ..
              '   "item3"]')
        return
    end

    -- Get the column position.
    local pos = props['SelectionStartColumn']

    -- Get leading space count.
    local _, leadingspace = string.find(text, '^%s*')

    -- Set indent.
    local indent = string.rep(' ', pos - 1) .. string.rep(' ', leadingspace)

    -- Add extra space for leading [{( to align the start with quotes.
    if string.find(text, '^%s*[%[%{%(]') then
        indent = indent .. ' '
    end

    -- Insert newlines.
    text = string.gsub(text, '(["\']?), (["\']?)', '%1,\n' .. indent .. '%2')

    -- Replace selection.
    editor:ReplaceSel(text)
end


function Run(command, execute)
    -- Run the command and print the output. If execute is true, no output.

    local filedir = props['FileDir']

    if execute == true then
        if filedir == '' then
            command = 'start "" ' .. command
        else
            command = 'start "" /d "' .. filedir .. '" ' .. command
        end

        os.execute(command)
        return
    end

    if filedir ~= '' then
        command = 'pushd "' .. filedir .. '" && ' .. command
    end

    local file = io.popen(command)

    for line in file:lines() do
        print(line)
    end

    file:close()
end


function SelectCalltipColour()
    -- Select autocomplete and calltip colours.

    -- Colours with rgb values:       {fore,      back,      highlight}.
    local colours = {['Default']    = {nil,       nil,       nil      },
                     ['Black']      = {'#DDDDDD', '#000000', '#BBEEFF'},
                     ['DarkBlue']   = {'#CCCCDD', '#333355', '#BBEEFF'},
                     ['DarkGreen']  = {'#CCCCDD', '#335533', '#BBEEAA'},
                     ['DarkGrey']   = {'#CCCCDD', '#5F5F5F', '#BBEEFF'},
                     ['DarkRed']    = {'#CCCCDD', '#553333', '#EEBBAA'},
                     ['DarkYellow'] = {'#DDDDDD', '#747400', '#FFFF7F'},
                     ['LightGrey']  = {'#222222', '#9F9F9F', '#BBEEFF'},
                     ['PaleGrey']   = {'#222222', '#DDDDDD', '#0000FF'},
                     ['White']      = {'#222222', '#FFFFFF', '#0000FF'},
                     ['Yellow']     = {'#222222', '#FFFF80', '#FF0000'}}

    -- Display ListBox.
    local list = {}

    for k, _ in pairs(colours) do
        if k ~= 'Default' then
            table.insert(list, k)
        end
    end

    table.sort(list)
    table.insert(list, 1, 'Default')

    local result = ListBox(list, 'Calltip colour based on background')

    if not result then
        return
    end

    -- Get selected item as text.
    local item = list[result + 1]

    -- Get Colour values.
    local colour = colours[item]

    -- Set colour properties.
    if colour[1] and colour[2] then
        props['style.*.38'] = 'fore:' .. colour[1] .. ',back:' .. colour[2]
    else
        props['style.*.38'] = nil
    end

    props['autocomplete.fore'] = colour[1]
    props['autocomplete.back'] = colour[2]

    local highlight = colour[3]
    props["calltip.colour.highlight"] = highlight

    if not highlight then
        -- Default Dark Blue.
        highlight = '#00007F'

        -- Override with highlight property value if set.
        if props["calltip.colour.highlight"] ~= '' then
            highlight = props["calltip.colour.highlight"]
        end
    end

    -- Check if highlight is a 7 character rgb value.
    if not string.find(highlight, '^#%x%x%x%x%x%x$') then
        return
    end

    -- Change colour to bgr and cast to number.
    local number = tonumber('0x' .. string.gsub(highlight, '#(%x%x)(%x%x)(%x%x)', '%3%2%1'))

    -- Set the highlight colour.
    if number then
        scite.SendEditor(SCI_CALLTIPSETFOREHLT, number)
    end
end


function ShowUserListSelection(id, items, separator)
    -- Show user selection window.

    local backup_separator

    -- Backup initial separator and set a new separator.
    if separator ~= nil then
        backup_separator = editor.AutoCSeparator
        editor.AutoCSeparator = string.byte(separator)
    end

    -- Join items of table into 1 string.
    if type(items) ~= 'string' then
        items = table.concat(items, string.char(editor.AutoCSeparator))
    end

    -- Show user list.
    editor:UserListShow(id, items)

    -- Restore separator.
    if backup_separator then
        editor.AutoCSeparator = backup_separator
    end
end


function StartExeFile()
    -- Run a executable file in SciTE subdirectory with no arguments.

    -- Get the file list.
    local list = {}

    local command = 'cmd /q /c ' ..
                    'pushd "' .. props['SciteDefaultHome'] .. '" ^&^& ' ..
                    'for /d %A in (*) do ' ..
                    'for %B in ("%~A\\*.exe") do ' ..
                    'echo %B'

    local ignore_list = {'SciTE.exe$',
                         'test.?%.exe$',
                         'lua\\luacheck.exe$'}

    local file = io.popen(command)

    for line in file:lines() do
        line = string.gsub(line, '"', '')

        for _, pattern in pairs(ignore_list) do
            if string.find(line, pattern) then
                goto label_1
            end
        end

        table.insert(list, line)

        ::label_1::
    end

    file:close()

    -- Get the selection.
    local result = ListBox(list, 'StartExeFile')

    if result ~= nil then
        local item = list[result + 1]
        Run('"' .. props['SciteDefaultHome'] .. '\\' .. item .. '"', true)
    end
end


function StripTrailingSpaces()
    -- http://lua-users.org/wiki/SciteCleanDocWhitespace

    local report_nomatch = false
    local count = 0
    local fs, fe = editor:findtext("[ \\t]+$", SCFIND_REGEXP)

    if fe then
        editor:BeginUndoAction()

        repeat
            count = count + 1
            editor:remove(fs, fe)
            fs, fe = editor:findtext("[ \\t]+$", SCFIND_REGEXP, fs)
        until not fe

        editor:EndUndoAction()

        print("Removed trailing spaces from " .. count .. " line(s).")
    elseif report_nomatch then
        print("Document was clean already; nothing to do.")
    end
end


function ToggleCodePage()
    -- Toggle codepage. If unset, SciTE defaults to 0.
    -- 0 -> 65001 -> user setting if set.

    if props['code.page'] == '0' then
        -- UTF-8.
        props['code.page'] = '65001'
    elseif props['code.page'] == '65001' then
        -- Unmask actual value.
        props['code.page'] = nil

        -- If 65001 is actual value, set to 0.
        if props['code.page'] == '65001' then
            props['code.page'] = '0'
        end
    else
        -- System codepage.
        props['code.page'] = '0'
    end
end


function ToggleDimComments()
    -- Dim comment from default to grey.

    local function SetState(value)
        -- Set a value for these SciTE properties.

        local list = {'colour.code.comment.box',
                      'colour.code.comment.line',
                      'colour.code.comment.doc',
                      'colour.code.comment.nested',
                      'colour.text.comment',
                      'colour.other.comment',
                      'colour.embedded.comment',
                      -- others.
                      'style.props.1',
                      -- html.
                      'style.hypertext.9',
                      -- inno.
                      'style.inno.1',
                      'style.inno.7',
                      -- python.
                      'style.python.12',
                      -- registry.
                      'style.registry.1'}

        for _, v in pairs(list) do
            if props[v] ~= nil then
                props[v] = value
            end
        end
    end

    -- Toggle dim comments.
    local light = 'fore:#BBBBBB'
    local dark  = 'fore:#666666'

    if props['colour.code.comment.line'] == light
    or props['colour.code.comment.line'] == dark then
        SetState()
    else
        if props['theme.dark'] ~= '1' then
            SetState(light)
        else
            SetState(dark)
        end
    end
end


function ToggleExtendedTools()
    -- Toggle extended setting and show ListBox again.

    -- Toggle extended setting.
    GlobalSettings['tools']['extended'] = not GlobalSettings['tools']['extended']

    -- Show ListBox again.
    GlobalTools()
end


function ToggleHighlightCurrentWord()
    -- Toggles the property highlight.current.word of 0 and 1.

    local setting = props['highlight.current.word']

    if setting == '0' or setting == '' then
        props['highlight.current.word'] = '1'
    else
        props['highlight.current.word'] = '0'
    end
end


function ToggleMonospaceFont()
    -- Toggle with monospace font with edge mode and proportional font.

    if props['font.override'] ~= '' then

        -- Mask edge.mode and font.override.
        props['edge.mode'] = ''
        props['font.override'] = ''
    else
        -- Unmask edge.mode and font.override.
        props['edge.mode'] = nil
        props['font.override'] = nil

        -- Set font.override to monospace.
        if props['font.override'] == '' then
           props['font.override'] = props['font.monospace']
        end
    end
end


function UserContextMenu()
    -- Add user context menu if file type is supported.

    -- Set to true to add entry to tools menu.
    local opt_tools = false

    -- For these file extensions, add entry DebugPrintSelection.
    if props['FileExt'] == 'au3'
    or props['FileExt'] == 'bat'
    or props['FileExt'] == 'cmd'
    or props['FileExt'] == 'lua'
    or props['FileExt'] == 'py'
    or props['FileExt'] == 'pyw' then
        props['user.context.menu'] = '||DebugPrintSelection|1148|'

        if opt_tools then
            if props['command.name.48.*'] ~= 'DebugPrintSelection' then
                props['command.name.48.*'] = 'DebugPrintSelection'
                props['command.shortcut.48.*'] = 'Alt+D'
                SendCmdScite('reloadproperties:')
            end
        end
    else
        props['user.context.menu'] = nil

        if opt_tools then
            if props['command.name.48.*'] == 'DebugPrintSelection' then
                props['command.name.48.*'] = nil
                props['command.shortcut.48.*'] = nil
                SendCmdScite('reloadproperties:')
            end
        end
    end
end


function WinMergeFilePath(mode)
    -- Run WinMerge to diff FilePath with another file.
    -- If mode is 'unsaved', diff FilePath with editor text.

    local filepath = props['FilePath']

    -- Validate.
    if filepath == '' then
        print('Require a filepath.')
        return
    end

    -- Run WinMerge.
    if os.path.sep == '\\' then
        local app, command, tmpfile

        app = GlobalSettings['paths']['winmerge']

        if mode == 'unsaved' then
            local text = editor:GetText()

            if text == nil or text == '' then
                print('No editor text.')
                return
            end

            -- Strip \r as lua may add \r to \n on write.
            text = string.gsub(text, '\r', '')

            -- Write the unsaved text to a temporary file.
            tmpfile = os.tmpname()

            if string.sub(tmpfile, 1, 1) == '\\' then
                tmpfile = os.getenv('TEMP') .. tmpfile
            end

            local file = io.open(tmpfile, 'w')

            if file == nil then
                print('No file handle to write.')
                return
            end

            file:write(text)
            file:close()

            -- Build command to diff the file with the temporary file.
            command = 'title WinMerge Unsaved & ' ..
                      '"' .. app .. '" "' .. filepath .. '" /u "' .. tmpfile .. '"'
        else
            -- Build command to diff the file with another file.
            command = 'start "" /b "' .. app .. '" /u "' .. filepath .. '"'
        end

        -- Run WinMerge.
        os.execute(command)

        -- Remove temporary file.
        if tmpfile ~= nil then
            local ok, err = os.remove(tmpfile)

            if ok == nil then
                print(err)
            end
        end
    else
        print('No command set for this operating system.')
    end
end


local function SetAutoItDir()
    -- Set autoit3dir (home of AutoIt3.exe) if not already set.
    -- Search for AutoIt3.exe in this order:
    --   Subfolder to autoit3dir. Scite4AutoIt3 uses this as default.
    --   Parallel to autoit3dir.  AutoIt and Scite folders next to each other.
    --   Inside autoit3dir.       Sharing a single directory.
    --   Parent to autoit3dir.    AutoIt3 as a subfolder.
    --   If not found.            Current working directory.

    local function NormPath(path)
        -- Remove .. from path and return updated path if valid.
        -- Updated path is also valid if permission error 13.

        local newpath = string.gsub(path, '^(.*)\\.-\\%.%.\\(.*)$', '%1\\%2')

        if path == newpath then
            return path
        end

        local result, err, code = os.rename(newpath, newpath)

        if not result then
            if code == 13 then
                return newpath
            end

            return path, err
        end

        return newpath
    end

    local function PropsTrim(s)
        -- Remove spaces from either end.
        return string.gsub(props[s], '^%s*(.-)%s*$', '%1')
    end

    -- Get the value of autoit3dir.
    local au3dir = PropsTrim('autoit3dir')

    -- Check if autoit3dir needs to be set.
    if au3dir ~= nil and au3dir ~= '' and au3dir ~= '*' then
        au3dir = NormPath(au3dir)

        local file = io.open(au3dir .. '\\AutoIt3.exe')

        if file ~= nil then
            io.close(file)
            props['autoit3dir'] = au3dir
            return au3dir
        end
    end

    -- Get the value of SciteDefaultHome as the working dir could be anywhere.
    local scitedir = props['SciteDefaultHome']

    -- Paths to the directory of AutoIt3.exe.
    local au3dirs = {scitedir .. '\\..', scitedir .. '\\..\\AutoIt3',
                     scitedir .. '\\AutoIt3', scitedir}

    -- Check AutoIt paths and if ok, set autoit3dir.
    for _, dir in pairs(au3dirs) do
        au3dir = NormPath(dir)

        local file = io.open(au3dir .. '\\AutoIt3.exe')

        if file ~= nil then
            io.close(file)
            props['autoit3dir'] = au3dir
            return au3dir
        end
    end

    -- Get the value of autoit3dir.
    au3dir = PropsTrim('autoit3dir')

    -- Check if autoit3dir needs to be set.
    if au3dir == nil or au3dir == '' or au3dir == '*' then
        props['autoit3dir'] = '.'
    end

    return au3dir
end


-- Set autoit3dir property.
SetAutoItDir()
