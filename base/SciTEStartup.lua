-- Defined SciTE Startup Lua script.


-- Ensure SciteDefaultHome is in the initial package path.
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

    -- WinMerge compare paths for left and middle.
    ['compare_paths'] = {},

    -- GlobalTools various settings.
    ['tools'] = {

        -- Save selected name returned from GlobalTools.
        ['name'] = nil,

        -- Hide or show extended tools. true=all tools, false=less tools.
        ['extended'] = false},

    -- Last file closed that can be reopened later.
    ['last_closed_file'] = nil,

    -- SetProperty record for the last property name set by the SelectProperty item.
    ['prop_last'] = '',

    -- SetProperty... record of property names with modified values.
    ['prop_list'] = {},

    -- SetStyle by ColourDialog=true, by InputBox=false, set by MsgBox=nil.
    ['style_by_colour'] = nil,

    -- Paths that may need to be globally known.
    ['paths'] = {
        ['dbeditor'] = os.path.join(os.getenv('ProgramFiles'),
                                    'DB Browser for SQLite',
                                    'DB Browser for SQLite.exe'),
        ['eskil'] = os.path.join(props['SciteDefaultHome'], 'eskil', 'eskil.exe'),
        ['frhed'] = os.path.join(props['SciteDefaultHome'], 'frhed', 'Frhed.exe'),
        ['sqlite'] = os.path.join(props['SciteDefaultHome'], 'sqlite', 'sqlite3.exe'),
        ['winmerge'] = os.path.join(os.getenv('ProgramFiles'), 'WinMerge', 'WinMergeU.exe')}}


-- Common functions.
-- Must be at top to be accessible to other functions.

Buffer = (function()
    -- Provides a buffer table with a key for each filepath.

    local function GetFilePath()
        -- Return empty string on fail, to be consistent with props.

        -- Get the current filepath.
        local filepath = props['FilePath']

        if filepath == '' then
            return ''
        end

        -- Reject if filepath ends with a trailing back\slash.
        if string.find(filepath, '[/\\]$') ~= nil then
            return ''
        end

        return filepath
    end

    return {
        buffer = {},

        add = function(self)
            -- Buffer:add()

            local filepath = GetFilePath()

            if filepath == '' then
                return
            end

            if self.buffer[filepath] == nil then
                self.buffer[filepath] = {}
                return true
            end
        end,

        get = function(self, key)
            -- Buffer:get([key])

            local filepath = GetFilePath()

            if filepath == '' or self.buffer[filepath] == nil then
                return
            end

            if key then
                return self.buffer[filepath][key]
            else
                return self.buffer[filepath]
            end
        end,

        has_strip = function(self)
            -- Buffer:has_strip()

            local filepath = GetFilePath()

            if filepath == '' or self.buffer[filepath] == nil then
                return
            end

            for k in pairs(self.buffer[filepath]) do
                if string.find(k, '^strip_') ~= nil then
                    return true
                end
            end
        end,

        insert = function(self, key, value)
            -- Buffer:insert(key, value)

            local filepath = GetFilePath()

            if filepath == '' or self.buffer[filepath] == nil then
                return
            end

            if value ~= nil then
                self.buffer[filepath][key] = value
                return true
            end
        end,

        remove = function(self, key)
            -- Buffer:remove([key])

            local filepath = GetFilePath()

            if filepath == '' or self.buffer[filepath] == nil then
                return
            end

            if key then
                self.buffer[filepath][key] = nil
            else
                self.buffer[filepath] = nil
            end

            return true
        end
    }
end)()


local _ = (function()
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
            return
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
            return
        end
    end

    -- Get the value of autoit3dir.
    au3dir = PropsTrim('autoit3dir')

    -- Check if autoit3dir needs to be set.
    if au3dir == nil or au3dir == '' or au3dir == '*' then
        props['autoit3dir'] = '.'
    end
end)()


local function EscapeComment(comment)
    -- Escape comment for safe SQLite use.

    if comment == nil or comment == '' then
        return comment
    end

    -- Replace newlines with a space with pasted multiline comments.
    comment = string.gsub(comment, '[\r\n]+', ' ')

    -- Replace double quotes with back quotes.
    comment = string.gsub(comment, '"', '`')

    -- Replace pipe with space.
    comment = string.gsub(comment, '|', ' ')

    -- Escape single quotes in comments.
    comment = string.gsub(comment, '\'', '\'\'')

    -- Remove outer spaces.
    comment = string.gsub(comment, '^%s*(.-)%s*$', '%1')

    return comment
end


local function GetTmpFilename(fileext)
    -- Create a temporary filename.

    local tmpfile = os.tmpname()

    if string.sub(tmpfile, 1, 1) == '\\' then
        tmpfile = os.getenv('TEMP') .. tmpfile
    end

    if fileext and fileext ~= '' then
        if not string.find(tmpfile, '%.' .. fileext .. '$') then
            if not os.path.exist(tmpfile .. '.' .. fileext) then
                tmpfile = tmpfile .. '.' .. fileext
            end
        end
    end

    return tmpfile
end


local function PrintNumberedLine(number, line)
    -- Print filename, line number and reformatted line text.

    -- Trim right side of whitespace.
    line = string.gsub(line, '%s+$', '')

    -- Replace leading tabs with spaces.
    if editor.UseTabs and editor.TabWidth then
        local _, i = string.find(line, '^\t+')

        if i and i > 0 then
            line = string.gsub(line, '^\t+', string.rep(' ', editor.TabWidth * i))
        end
    end

    -- Print reformated line.
    print(string.format('%s:%04i: %s', props['FileNameExt'], number, line))
end


local function Run(command, execute)
    -- Run the command and print the output.
    -- Execute:
    --   true = no output.
    --   false = print all with normalized eol.
    --   nil = print line by line.

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

    if execute == false then
        local text = file:read('a')

        if os.path.sep == '\\' then
            text = string.gsub(text, '\r?\n', '\r\n')
        end

        print(text)
    else
        for line in file:lines() do
            print(line)
        end
    end

    file:close()
end


local function ShowStrip()
    -- Show a strip at the bottom of the pane.

    local edit_commit = Buffer:get('strip_edit_commit')

    if edit_commit then
        scite.StripShow("'Comment:'[](?)(Com&pare)(Co&mmit)(&Cancel)")
        scite.StripSet(1, edit_commit['comment'])
    end
end


-- GlobalTools related functions.
-- Must be above the GlobalTools function.

local function BackupFilePath()
    -- Save FilePath to database and access later.

    local sqlite = GlobalSettings['paths']['sqlite']
    local filepath = props['FilePath']
    local dbfile = filepath .. '.backups'

    -- Validate.
    if filepath == '' then
        MsgBox('Require a FilePath.', 'BackupFilePath', MB_ICONWARNING)
        return
    end

    if props['FileNameExt'] == '' then
        MsgBox('Require a FileNameExt.', 'BackupFilePath', MB_ICONWARNING)
        return
    end

    -- Database handling functions.
    local function GetDataBaseSize()
        -- Get the size of the database file.

        local file = io.open(dbfile)

        if not file then
            return
        end

        local size, err = file:seek('end')

        file:close()

        return size, err
    end

    local function InitilizeDatabase()
        -- Create the database and the main table.
        local command = '""' .. sqlite .. '" "' .. dbfile .. '" ' ..
                        '"CREATE TABLE main ' ..
                        '(cdate TEXT,' ..
                        ' comment TEXT,' ..
                        ' content BLOB)""'

        os.execute(command)
    end

    local function SelectDatabaseItem(index, total)
        -- Show ListBox and return the selected rowid and comment.

        -- Get the rowids and the comments.
        local command = '""' .. sqlite .. '" "' .. dbfile .. '" ' ..
                        '-separator "\t" ' ..
                        '"SELECT rowid, comment FROM main"'

        local file = io.popen(command)

        if file == nil then
            return
        end

        local rowids = {}
        local comments = {}

        for line in file:lines() do
            for rowid, comment in string.gmatch(line, '(.-)\t(.+)') do
                table.insert(rowids, rowid)
                table.insert(comments, comment)
            end
        end

        -- Select item from the ListBox to return the rowid and comment.
        local title = 'Select the commit'

        if index then
            if total then
                if total > 1 then
                    title = string.format('Select the %s of %s commits',
                                          ({'1st', '2nd', '3rd'})[index],
                                          total)
                end
            else
                -- Get next commit automatically.
                local rowid = tostring(index)

                for i, v in ipairs(rowids) do
                    if v == rowid then
                        if rowids[i + 1] then
                            return rowids[i + 1], comments[i + 1]
                        end

                        break
                    end
                end

                return false
            end
        end

        local result = ListBox(comments, title, #comments - 1)

        if result ~= nil then
            return rowids[result + 1], comments[result + 1]
        end
    end

    -- Select mode from the list box.
    local list = {'Commit filepath',
                  'Compact the database',
                  'Delete any commit',
                  'Delete the database',
                  'Edit any commit',
                  'Edit the database',
                  'Open any commit',
                  'Print all comments',
                  'Restore any commit',
                  'WinMerge any commit'}

    if not os.path.exist(dbfile) then
        list = {list[1]}
    end

    local result = ListBox(list, 'Select the mode')

    if result == nil then
        return
    end

    local mode = string.lower(list[result + 1])

    -- Show lists with multiple modes.
    if mode == 'restore any commit'
    or mode == 'winmerge any commit' then

        if mode == 'restore any commit' then
            list = {'Restore any commit to edit pane',
                    'Restore any commit to filepath'}
        elseif mode == 'winmerge any commit' then
            list = {'WinMerge any commit with filepath',
                    'WinMerge any commit with filepath 3-way',
                    'WinMerge any commit with blank',
                    'WinMerge any commit with blank 3-way',
                    'WinMerge any commit with any commit',
                    'WinMerge any commit with any commit 3-way',
                    'WinMerge any commit with next commit',
                    'WinMerge any commit with next commit 3-way'}
        end

        result = ListBox(list, 'Select the mode')

        if result == nil then
            return
        end

        mode = string.lower(list[result + 1])
    end

    if mode == 'commit filepath' then

        -- Prepare the default commit comment.
        local text = ''

        if not os.path.exist(dbfile) then
            text = 'Initial commit'
        end

        -- Get commit comment from input box.
        local comment = InputBox(text, 'Commit', 'Enter a comment.\r\n\r\n' ..
                                 'Dir: "' .. props['FileDir'] .. '"\r\n' ..
                                 'File: "' .. props['FileNameExt'] .. '"')

        if comment == nil then
            return
        end

        comment = string.gsub(comment, '^%s*(.-)%s*$', '%1')

        if comment == '' then
            MsgBox('Commit comment cannot be empty', 'BackupFilePath', MB_ICONWARNING)
            return
        end

        comment = EscapeComment(comment)

        -- Initialize the database.
        if not os.path.exist(dbfile) then
            InitilizeDatabase()
        end

        -- Insert the new entry.
        local command = '""' .. sqlite .. '" "' .. dbfile .. '" ' ..
                        '"INSERT INTO main VALUES' ..
                        '(date(\'now\', \'localtime\'),' ..
                        ' \'' .. comment .. '\',' ..
                        ' readfile(\'' .. filepath .. '\'))""'

        os.execute(command)

        return
    end

    -- Check if database file exist.
    if not os.path.exist(dbfile) then
        MsgBox('The database file does not exist.', 'BackupFilePath', MB_ICONWARNING)
        return
    end

    if mode == 'compact the database' then

        -- Get before file size.
        local before = GetDataBaseSize()

        -- Perform a vacuum of the database.
        local command = '""' .. sqlite .. '" "' .. dbfile .. '" "VACUUM""'

        os.execute(command)

        -- Get after file size.
        local after = GetDataBaseSize()

        -- Display results of before and after.
        if not before or not after then
            MsgBox('Before and after sizes unknown', 'BackupFilePath')
            return
        end

        local len = string.len(tostring(before))

        MsgBox(string.format('Size before: %' .. len .. 's\r\n' ..
                             'Size after:  %' .. len .. 's\r\n', before, after),
                             'BackupFilePath', MB_ICONINFORMATION)

    elseif mode == 'delete any commit' then

        -- Select the commit.
        local rowid = SelectDatabaseItem()

        if rowid == nil then
            return
        end

        -- Get confirmation.
        if MsgBox('Delete the commit?', 'BackupFilePath', MB_ICONQUESTION|
                                                          MB_DEFBUTTON2|
                                                          MB_YESNO) == IDNO then
            return
        end

        -- Delete the commit.
        local command = '""' .. sqlite .. '" "' .. dbfile .. '" ' ..
                        '"DELETE FROM main WHERE rowid = ' ..
                        rowid .. '""'

        os.execute(command)

    elseif mode == 'delete the database' then

        -- Get confirmation.
        if MsgBox('Delete the database?', 'BackupFilePath', MB_ICONQUESTION|
                                                            MB_DEFBUTTON2|
                                                            MB_YESNO) == IDNO then
            return
        end

        -- Delete the database.
        local ok, err = os.remove(dbfile)

        if not ok then
            MsgBox(err, 'BackupFilePath', MB_ICONWARNING)
        end

    elseif mode == 'edit any commit' then

        -- Select the commit.
        local rowid, comment = SelectDatabaseItem()

        if rowid == nil then
            return
        end

        -- Get the file extension.
        local fileext = props['FileExt']

        -- Write the commit to a temporary file and open it for editing.
        local tmpfile = GetTmpFilename(fileext)

        local command = '""' .. sqlite .. '" "' .. dbfile .. '" ' ..
                        '"SELECT writefile(\'' .. tmpfile .. '\', content) ' ..
                        'FROM main WHERE rowid = ' .. rowid .. '""'

        os.execute(command)

        -- Open the tmpfile and show the strip.
        scite.Open(tmpfile)

        -- Record the details to pass to the strip.
        Buffer:insert('strip_edit_commit', {['sqlite'] = sqlite,
                                            ['dbfile'] = dbfile,
                                            ['rowid'] = rowid,
                                            ['comment'] = comment,
                                            ['tmpfile'] = tmpfile,
                                            ['filepath'] = filepath,
                                            ['fileext'] = fileext})

        Buffer:insert('tmpfile', true)
        ShowStrip()

    elseif mode == 'edit the database' then

        -- Set path to the database editor.
        local app = GlobalSettings['paths']['dbeditor']

        -- Run the database editor.
        local command = 'start "" "' .. app .. '" "' .. dbfile .. '"'

        os.execute(command)

    elseif mode == 'open any commit' then

        local rowid = SelectDatabaseItem()

        if rowid == nil then
            return
        end

        local command = '""' .. sqlite .. '" "' .. dbfile .. '" ' ..
                        '"SELECT content FROM main WHERE rowid = ' ..
                        rowid .. '""'

        local file = io.popen(command)

        if file == nil then
            return
        end

        local text = file:read('a')
        file:close()

        -- Open an empty tab and append the content.
        if text then
            scite.Open('')

            if editor:GetText() == '' then
                editor:SetText(text)
            else
                MsgBox('Not recognized as a empty pane.', 'BackupFilePath', MB_ICONWARNING)
            end
        end

    elseif mode == 'print all comments' then

        -- Print comments.
        local command = '"' .. sqlite .. '" -separator "  " "' .. dbfile .. '" ' ..
                        '"SELECT cdate, comment FROM main"'

        Run(command, false)

    elseif mode == 'restore any commit to edit pane' then

        -- Get the rowid.
        local rowid = SelectDatabaseItem()

        if rowid == nil then
            return
        end

        -- Read the committed content.
        local command = '""' .. sqlite .. '" "' .. dbfile .. '" ' ..
                        '"SELECT content FROM main WHERE rowid = ' ..
                        rowid .. '""'

        local file = io.popen(command)

        if file == nil then
            return
        end

        local text = file:read('a')
        text = string.gsub(text, '\n\n$', '\n')
        file:close()

        -- Restore the content in the current tab.
        if text then
            editor:ClearAll()

            if editor:GetText() == '' then
                editor:SetText(text)
            else
                MsgBox('Not recognized as a empty pane.', 'BackupFilePath', MB_ICONWARNING)
            end
        end

    elseif mode == 'restore any commit to filepath' then

        -- Get the rowid.
        local rowid = SelectDatabaseItem()

        if rowid == nil then
            return
        end

        -- Write to FilePath.
        local command = '""' .. sqlite .. '" "' .. dbfile .. '" ' ..
                        '"SELECT writefile(\'' .. filepath .. '\', content) ' ..
                        'FROM main WHERE rowid = ' .. rowid .. '""'

        os.execute(command)

    elseif string.match(mode, '^winmerge any commit .+') then

        -- Set path to WinMerge.
        local app = GlobalSettings['paths']['winmerge']

        -- Get the extension for the tmpfiles.
        local fileext = props['FileExt']

        -- Will be set to the number of tmpfiles.
        local tmpfilecount = 1

        -- Will be set to true if mode is next commit.
        local automatic

        -- Set tmpfile count, filepath and possibly set automatic to true.
        local text = string.match(mode, '^winmerge any commit with (.+)$')

        for k, v in pairs({['filepath'         ] = {1, filepath},
                           ['filepath 3-way'   ] = {2, filepath},
                           ['blank'            ] = {1, ''      },
                           ['blank 3-way'      ] = {2, ''      },
                           ['any commit'       ] = {2, nil     },
                           ['any commit 3-way' ] = {3, nil     },
                           ['next commit'      ] = {2, nil     },
                           ['next commit 3-way'] = {3, nil     }}) do
            if k == text then
                tmpfilecount, filepath = v[1], v[2]
                break
            end
        end

        if text == 'next commit' or text == 'next commit 3-way' then
            automatic = true
        end

        -- Get tmpfile names and comments and write the tmpfiles.
        local comments = {}
        local tmpfiles = {}
        local rowid, comment

        for i = 1, tmpfilecount do

            -- Get the rowid and the comment.
            if automatic and i > 1 then
                rowid, comment = SelectDatabaseItem(tonumber(rowid))

                if rowid == false then
                    for _ = i, tmpfilecount do
                        table.insert(tmpfiles, '')
                        table.insert(comments, '')
                    end

                    break
                end
            else
                rowid, comment = SelectDatabaseItem(i, tmpfilecount)
            end

            if not rowid then
                return
            end

            -- Trim long comments.
            if string.len(comment) > 40 then
                local pos = 36

                for x in string.gmatch(comment, '()%s+') do
                    if x > 26 and x < 37 then
                        pos = x
                    end
                end

                comment = string.sub(comment, 1, pos) .. '...'
            end

            -- Write the text to a temporary file.
            local tmpfile = GetTmpFilename(fileext)

            table.insert(tmpfiles, tmpfile)
            table.insert(comments, comment)

            local command = '""' .. sqlite .. '" "' .. dbfile .. '" ' ..
                            '"SELECT writefile(\'' .. tmpfile .. '\', content) ' ..
                            'FROM main WHERE rowid = ' .. rowid .. '""'

            os.execute(command)
        end

        -- Build the file extension argument.
        local fileext_arg = ''

        if fileext ~= '' then
            if not string.find(tmpfiles[1], '%.' .. fileext .. '$') then
                fileext_arg = '/fileext "' .. fileext .. '" '
            end
        end

        -- Build the command to diff the files.
        local command = '"' .. app .. '" /u ' .. fileext_arg ..
                        '/dl "' .. comments[1] .. '" ' ..
                        '/wl "' .. tmpfiles[1] .. '" '

        if filepath then
            command = command .. '"' .. filepath .. '" '
        end

        local args = {{'/dr', '/wr'}, {'/dm', '/wm'}}

        for i = 2, #tmpfiles do
            local v = args[#tmpfiles + 1 - i]

            if comments[i] ~= '' then
                command = command .. string.format('%s "%s" ', v[1], comments[i])
            end

            if tmpfiles[i] ~= '' then
                command = command .. string.format('%s "%s" ', v[2], tmpfiles[i])
            else
                command = command .. '"" '
            end
        end

        for i = 1, #tmpfiles do
            if tmpfiles[i] ~= '' then
                command = command .. string.format('&del "%s" ', tmpfiles[i])
            end
        end

        command = string.sub(command, 1, -2)

        -- Run WinMerge.
        os.execute('start "" /b cmd /s /c "' .. command .. '"')
    end
end


local function CurSelCountBraces()
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


local function DiffFileNameExt()
    -- Diff FileNameExt with fossil or git.

    local filenameext = props['FileNameExt']
    local filedir = props['FileDir']

    -- Validate.
    if filenameext == '' then
        MsgBox('Require a FileNameExt.', 'DiffFileNameExt', MB_ICONWARNING)
        return
    end

    if filedir == '' then
        MsgBox('Require a FileDir.', 'DiffFileNameExt', MB_ICONWARNING)
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
        MsgBox('No repo files found.', 'DiffFileNameExt', MB_ICONWARNING)
    end
end


local function EmptyUndoBuffer()
    -- Empty undo and redo of the buffers and clear the Change History.

    local list = {}

    if not editor.Modify and (editor:CanUndo() or editor:CanRedo()) then
        table.insert(list, 'editor')
    end

    if output:CanUndo() or output:CanRedo() then
        table.insert(list, 'output')
    end

    if #list == 2 then
        table.insert(list, 'both')
    end

    local result = ListBox(list, 'EmptyUndoBuffer')

    if result == nil then
        return
    end

    local mode = list[result + 1]

    if mode == 'editor' or mode == 'both' then
        local setting = editor.ChangeHistory
        editor.ChangeHistory = 0
        editor:EmptyUndoBuffer()
        editor.ChangeHistory = setting
    end

    if mode == 'output' or mode == 'both' then
        output:EmptyUndoBuffer()
    end
end


local function EskilFilePath()
    -- Run Eskil to diff FilePath with a checkout.

    local filepath = props['FilePath']

    -- Validate.
    if filepath == '' then
        MsgBox('Require a filepath.', 'EskilFilePath', MB_ICONWARNING)
        return
    end

    -- Run Eskil.
    local app = GlobalSettings['paths']['eskil']
    local command = 'start "" "' .. app .. '" "' .. filepath .. '"'

    os.execute(command)
end


local function FrhedFilePath()
    -- Run Frhed to hex edit FilePath.

    local filepath = props['FilePath']

    -- Validate.
    if filepath == '' then
        MsgBox('Require a filepath.', 'FrhedFilePath', MB_ICONWARNING)
        return
    end

    -- Run Frhed.
    local app = GlobalSettings['paths']['frhed']
    local command = 'start "" "' .. app .. '" "' .. filepath .. '"'

    os.execute(command)
end


local function GotoPosition()
    -- Goto a character position.

    local msg = 'Enter position to goto\r\n\r\n' ..
                'Current position:  ' .. tostring(editor.CurrentPos) .. '\r\n' ..
                'Last position:  ' .. tostring(editor.Length)

    local pos = InputBox(tostring(editor.CurrentPos), 'GotoPosition', msg)

    if not pos then
        return
    elseif not string.match(pos, '^[0-9]+$') then
        MsgBox('Position value entered was not an integer',
               'GlobalTools', MB_ICONWARNING)
        return
    end

    local line = editor:LineFromPosition(pos)
    editor:EnsureVisible(line)
    editor:GotoPos(pos)
end


local function InsertCtrlCharacter()
    -- Insert a control character.

    local list = {'Null.  NUL',
                  'Start of header.  SOH',
                  'Start of text.  STX',
                  'End of text.  ETX',
                  'End of transmission.  EOT',
                  'Enquiry.  ENQ',
                  'Acknowledge.  ACK',
                  'Bell.  BEL',
                  'Backspace.  BS',
                  'Horizontal tab.  HT',
                  'Line feed.  LF',
                  'Vertical tab.  VT',
                  'Form feed.  FF',
                  'Carriage return.  CR',
                  'Shift out.  SO',
                  'Shift in.  SI',
                  'Data link escape.  DLE',
                  'Device control 1.  DC1',
                  'Device control 2.  DC2',
                  'Device control 3.  DC3',
                  'Device control 4.  DC4',
                  'Negative acknowledge.  NAK',
                  'Synchronize.  SYN',
                  'End of transmission block.  ETB',
                  'Cancel.  CAN',
                  'End of medium.  EM',
                  'Substitute.  SUB',
                  'Escape.  ESC',
                  'File separator.  FS',
                  'Group separator.  GS',
                  'Record separator.  RS',
                  'Unit separator.  US'}

    -- Get the selected name and insert the character.
    local result = ListBox(list, 'InsertCtrlCharacter')

    if result then
        editor:AddText(string.char(result))
    end
end


local function InsertDate()
    -- Insert or replace date in the format of 'yyyy-mm-dd'.

    local text = editor:GetSelText()
    local date = os.date('%Y-%m-%d')

    if text == '' or string.match(text, '^%d%d%d%d%-%d%d%-%d%d$') ~= nil then
        editor:ReplaceSel(date)
    else
        editor:AddText(date)
    end
end


local function ManageBookmarks()
    -- Empty, Prune, Restore and Store bookmarks.

    local bookmark = 1
    local mask = 1 << bookmark
    local stored_bookmarks = Buffer:get('stored_bookmarks')
    local list = {'Store'}

    if stored_bookmarks then
        if #stored_bookmarks > 1 then
            list = {'Empty', 'Prune', 'Restore', 'Store'}
        else
            list = {'Empty', 'Restore', 'Store'}
        end
    end

    local result = ListBox(list, 'ManageBookmarks')

    if not result then
        return
    end

    local mode = list[result + 1]

    if mode == 'Empty' then
        Buffer:remove('stored_bookmarks')
        return
    end

    if mode == 'Prune' then
        list = {}

        for i = 1, #stored_bookmarks do
            table.insert(list, (stored_bookmarks[i])[1])
        end

        result = ListBox(list, 'ManageBookmarks Prune')

        if not result then
            return
        end

        table.remove(stored_bookmarks, result + 1)
        table.sort(stored_bookmarks, function(x, y) return x[1] < y[1] end)

        if #stored_bookmarks == 0 then
            Buffer:remove('stored_bookmarks')
        end

        return
    end

    if mode == 'Restore' then
        list = {}

        for i = 1, #stored_bookmarks do
            table.insert(list, (stored_bookmarks[i])[1])
        end

        result = ListBox(list, 'ManageBookmarks Restore')

        if not result then
            return
        end

        local t = (stored_bookmarks[result + 1])[2]

        for _, v in pairs(t) do
            editor:MarkerAdd(v, bookmark)
        end

        return
    end

    if mode == 'Store' then
        local markers = {}

        for i = 0, editor.LineCount - 1 do
            if editor:MarkerGet(i) & mask ~= 0 then
                table.insert(markers, i)
            end
        end

        if next(markers) then
            local comment = InputBox('', 'ManageBookmarks Store',
                                     'Comment for a stored bookmark set')

            if not comment then
                return
            end

            if not stored_bookmarks then
                stored_bookmarks = {}
                Buffer:insert('stored_bookmarks', stored_bookmarks)
            end

            table.insert(stored_bookmarks, {comment, markers})
        end

        return
    end
end


local function ManageTemplates()
    -- Add from, edit or browse template files.

    local function GetFilePattern()
        -- Get file pattern for matching template files.

        local fileext = props['FileExt']
        local lang = props['Language']
        local pattern

        -- Get pattern from filetype.
        if fileext ~= '' and lang ~= 'null' or fileext == 'txt' then
            pattern = '*.' .. fileext
        else
            -- Get pattern from document language.
            local patterns = {['au3'] = '*.au3',
                              ['batch'] = '*.bat *.cmd',
                              ['cpp'] = '*.c *.cpp *.cxx *.h *.hpp .hxx',
                              ['hypertext'] = '*.hta *.html',
                              ['inno'] = '*.iss',
                              ['lua'] = '*.lua',
                              ['markdown'] = '*.md',
                              ['pascal'] = '*.pas',
                              ['powershell'] = '*.ps1 *.psm1',
                              ['props'] = '*.cfg *.ini *.hhp *.properties *.session',
                              ['python'] = '*.py *.pyw',
                              ['sql'] = '*.sql'}

            pattern = patterns[lang]
        end

        if pattern == nil then
            pattern = '*'
        end

        return pattern
    end

    -- Get the mode of operation.
    local list = {'Add from template file',
                  'Edit template file',
                  'Open template folder'}

    local result = ListBox(list, 'ManageTemplates')

    if result == nil then
        return
    end

    local mode = list[result + 1]

    -- Set templates path.
    local appdata = os.getenv('AppData')
    local templates = appdata .. '\\Microsoft\\Windows\\Templates'

    -- Open templates folder.
    if mode == 'Open template folder' then
        os.execute('start "" "' .. templates .. '"')
        return
    end

    -- Get template files.
    local pattern = GetFilePattern()

    local command = 'pushd "' .. templates .. '" ' ..
                    '& dir /b /a:-d ' .. pattern .. ' ' ..
                    '& popd'

    list = {}
    local file = io.popen(command)

    if file then
        for line in file:lines() do
            table.insert(list, line)
        end

        file:close()
    end

    -- Show list of template filenames.
    result = ListBox(list, 'ManageTemplates')

    if result == nil then
        return
    end

    -- Add from or edit a template file.
    local template = templates .. '\\' .. list[result + 1]

    if mode == 'Edit template file' then
        scite.Open(template)

    elseif mode == 'Add from template file' then
        file = io.open(template)

        if file then
            local text = file:read('a')
            file:close()

            if text ~= '' then
                editor:AddText(text)
            end
        end
    end
end


local function OpenAbbrevFile()
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


local function OpenApiFile()
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


local function OpenChmFile()
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


local function OpenFileDir()
    -- Open the current files directory.

    local filedir = props['FileDir']
    os.execute('start "" "' .. filedir .. '"')
end


local function OpenHtaFile()
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


local function OpenLastClosedFile()
    -- Open last closed file.

    local filepath = GlobalSettings['last_closed_file']
    scite.Open(filepath)
end


local function OpenLuaExtensionFile()
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


local function OpenSciteVarsFile()
    -- Open scitevars.cfg that PrintSciteVars() can read.

    scite.Open('scitevars.cfg')
end


local function OpenTempFile()
    -- Open a file for temporary use.

    local fileext = props['FileExt']

    if fileext == '' then
        MsgBox('Require a FileExt.', 'OpenTempFile', MB_ICONWARNING)
        return
    end

    -- Get the prefix from the file extension.
    local prefixes = {['cmd'] = '::',
                      ['cpp'] = '//',
                      ['cxx'] = '//',
                      ['json'] = '//',
                      ['lua'] = '--',
                      ['md'] = '#',
                      ['pas'] = '//',
                      ['php'] = '//',
                      ['properties'] = '#',
                      ['ps1'] = '#',
                      ['py'] = '#',
                      ['sql'] = '--',
                      ['txt'] = '#'}

    local prefix = prefixes[fileext] or ';'

    -- Create the comment.
    local comment

    comment = prefix .. ' about: Temporary file ' ..
              'that will be removed on close.\n\n'

    -- Create the temporary file and open it.
    local tmpfile = GetTmpFilename(fileext)

    local file = io.open(tmpfile, 'w')

    if file then
        if comment then
            file:write(comment)
        end

        file:close()
        scite.Open(tmpfile)
        editor:GotoLine(2)
        Buffer:insert('tmpfile', true)
    else
        MsgBox('No file handle to write.', 'OpenTempFile', MB_ICONWARNING)
    end
end


local function PrintApiKeywords()
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


local function PrintApiLuaPropsFiles()
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


local function PrintAsciiTable()
    -- Print ASCII table of decimal, hexadecimal and characters.

    -- Set literal representations for unprintable characters.
    local repr = true

    local t = {['\0'] = '[NULL]',
               ['\r'] = '[CR]',
               ['\n'] = '[LF]',
               ['\t'] = '[TAB]',
               ['\32'] = '[SPACE]'}

    for i = 0, 255 do
        local ch = string.char(i)

        if repr and i <= 32 then
            ch = t[ch] or ch
        end

        print(string.format('%4s  %2x  %s', i, i, ch))
    end
end


local function PrintCommentLines(mode)
    -- Get comment lines from the source in the editor.

    -- Options.
    local use_markers = false

    -- Get data.
    local text = editor:GetText()
    local fileext = props['FileExt']

    -- Set the title.
    local title = 'PrintCommentLines'

    if mode == 'code' then
        title = 'PrintCodeCommentLines'
    end

    -- Check if valid.
    if text == nil or text == '' then
        MsgBox('No editor text.', title, MB_ICONWARNING)
        return
    end

    if fileext == '' then
        MsgBox('No file extension.', title, MB_ICONWARNING)
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
        MsgBox('No comment pattern.', title, MB_ICONWARNING)
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


local function PrintFindText()
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
        MsgBox('No text to find.', 'PrintFindText', MB_ICONWARNING)
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


local function PrintGlobalNames(mode)
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


local function PrintGlobalTables(arg_table, arg_extra, skip_G)
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


local function PrintMarkers(mode)
    -- Print markers to output.

    local mask

    if mode == 'bookmarks' then
        local SCITE_BOOKMARK = 1
        mask = 1 << SCITE_BOOKMARK
    elseif mode == 'change_history' then
        mask = (1 << SC_MARKNUM_HISTORY_REVERTED_TO_ORIGIN) |
               (1 << SC_MARKNUM_HISTORY_SAVED) |
               (1 << SC_MARKNUM_HISTORY_MODIFIED) |
               (1 << SC_MARKNUM_HISTORY_REVERTED_TO_MODIFIED)
    end

    local prev_line

    for i = 0, editor.LineCount - 1 do
        if editor:MarkerGet(i) & mask ~= 0 then
            if prev_line then
                if i - 1 ~= prev_line then
                    print()
                end
            end

            PrintNumberedLine(i + 1, editor:GetLine(i))
            prev_line = i
        end
    end
end


local function PrintPropertyList()
    -- Print a list of property names and values modified by SetProperty.

    local list = {}

    for k, v in pairs(GlobalSettings['prop_list']) do
        table.insert(list, string.format('%s=%s', k, v))
    end

    table.sort(list)

    for i = 1, #list do
        print(list[i])
    end
end


local function PrintReminders()
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


local function PrintSciteVars()
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


local function ReplaceSelEscape()
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
        MsgBox('The filetype .' .. fileext .. ' is not set for escaping.',
               'ReplaceSelEscape', MB_ICONWARNING)
        return
    end

    editor:ReplaceSel(text)
end


local function ReplaceSelSortLines()
    -- Sorts a selection of text by line.

    -- Get the current selection text.
    local text = editor:GetSelText()

    if text == '' then
        MsgBox('No text selected.', 'ReplaceSelSortLines', MB_ICONWARNING)
        return
    end

    -- Get the line separator.
    local sep = string.match(text, '\r?\n')

    if sep == nil then
        MsgBox('No line separator.', 'ReplaceSelSortLines', MB_ICONWARNING)
        return
    end

    -- Ensure text has a trailing newline sequence.
    local ends_with_sep = true

    if string.find(text, '\r?\n$') == nil then
        ends_with_sep = false
        text = text .. sep
    end

    -- Insert each line into a table and sort.
    local lines = {}

    for line in string.gmatch(text, '(.-)\r?\n') do
        if line ~= '' then
            table.insert(lines, line)
        end
    end

    local result = ListBox('Sensitive|' ..
                           'Insensitive lower compare|' ..
                           'Insensitive upper compare|' ..
                           'Sensitive reverse|' ..
                           'Insensitive lower compare reverse|' ..
                           'Insensitive upper compare reverse',
                           'ReplaceSelSortLines')

    if result == nil then
        return
    elseif result == 1 then
        table.sort(lines,   function(a, b)
                                return string.lower(a) < string.lower(b)
                            end)
    elseif result == 2 then
        table.sort(lines,   function(a, b)
                                return string.upper(a) < string.upper(b)
                            end)
    elseif result == 3 then
        table.sort(lines,   function(a, b)
                                return a > b
                            end)
    elseif result == 4 then
        table.sort(lines,   function(a, b)
                                return string.lower(a) > string.lower(b)
                            end)
    elseif result == 5 then
        table.sort(lines,   function(a, b)
                                return string.upper(a) > string.upper(b)
                            end)
    else
        table.sort(lines)
    end

    -- Join the lines into a string.
    text = table.concat(lines, sep)

    if ends_with_sep then
        text = text .. sep
    end

    -- Replace the selection.
    editor:ReplaceSel(text)
end


local function ReplaceSelSortList()
    -- Sort a list of items.

    -- Get the string.
    local text = editor:GetSelText()

    -- Check if string is empty.
    if text == '' then
        MsgBox('No text selected.', 'ReplaceSelSortList', MB_ICONWARNING)
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


local function ReplaceSelWrapList()
    -- Wrap a list of items into multiple lines.

    -- Get the string.
    local text = editor:GetSelText()

    -- Check if string is empty.
    if text == '' then
        MsgBox('No text selected.', 'ReplaceSelSortList', MB_ICONWARNING)
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

    -- Get end of line sequence.
    local eol = ({'\r\n', '\r', '\n'})[editor.EOLMode + 1]

    -- Insert newlines.
    text = string.gsub(text, '(["\']?), (["\']?)', '%1,' .. eol .. indent .. '%2')

    -- Replace selection.
    editor:ReplaceSel(text)
end


local function SelectCalltipColour()
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


local function SetChangeHistory()
    -- Set the Change History view option.

    if editor.ChangeHistory == 0 then
        MsgBox('Change History is disabled.',
               'SetChangeHistory', MB_ICONWARNING)
        return
    end

    local list = {'None',
                  'Markers',
                  'Indicators',
                  'Markers and Indicators'}

    local result = ListBox(list, 'SetChangeHistory')

    if result == nil then
        return
    end

    local option = {[0]=1, [1]=3, [2]=5, [3]=7}
    editor.ChangeHistory = option[result]
end


local function SetColour()
    -- Set a value for a colour variable.

    -- Set the style names.
    local list = {'Default',
                  'colour.aqua',
                  'colour.blue',
                  'colour.char',
                  'colour.code.comment.box',
                  'colour.code.comment.doc',
                  'colour.code.comment.line',
                  'colour.code.comment.nested',
                  'colour.default',
                  'colour.embedded.comment',
                  'colour.embedded.js',
                  'colour.error',
                  'colour.fuchsia',
                  'colour.grey',
                  'colour.keyword',
                  'colour.lime',
                  'colour.maroon',
                  'colour.notused',
                  'colour.number',
                  'colour.operator',
                  'colour.other.comment',
                  'colour.other.operator',
                  'colour.preproc',
                  'colour.red',
                  'colour.silver',
                  'colour.string',
                  'colour.string.unclosed',
                  'colour.text.comment',
                  'colour.white',
                  'colour.whitespace',
                  'colour.yellow'}

    -- Get the selected name.
    local result = ListBox(list, 'SetColour')

    if result == nil then
        return
    end

    result = result + 1
    local name = list[result]

    -- Unmask all recorded colour values.
    if name == 'Default' then
        for k in pairs(GlobalSettings['prop_list']) do
            if string.find(k, '^colour%.') ~= nil then
                GlobalSettings['prop_list'][k] = nil
                props[k] = nil
            end
        end

        return
    end

    -- Set fore and back colour by ColourDialog.
    local title = name .. '=' .. props[name]
    local value = ''

    for _, v in pairs({'fore:', 'back:'}) do
        result = MsgBox('Set ' .. v, title, MB_ICONQUESTION|
                                            MB_YESNOCANCEL)
        if result == IDYES then
            result = ColourDialog()

            if result == nil then
                break
            end

            if value ~= '' then
                value = value .. ','
            end

            value = value .. v .. result
        elseif result == IDCANCEL then
            return
        end
    end

    -- Set eolfilled only if previously set.
    if string.find(value, 'back:') and string.find(title, 'eolfilled') then
        result = MsgBox('Set eolfilled', title, MB_ICONQUESTION|
                                                MB_YESNOCANCEL)
        if result == IDYES then
            value = value .. ',eolfilled'
        elseif result == IDCANCEL then
            return
        end
    end

    -- Set the value.
    if value ~= '' then
        props[name] = value
        GlobalSettings['prop_list'][name] = props[name]
    end
end


local function SetProperty()
    -- Change a property value for the current SciTE instance.

    -- Preset property values.
    local preset = {['off_on'] = {'Default', '0 = Off', '1 = On'},
                    ['grey_colours'] = {'Default', 'Empty', 'SelectColour',
                                        '#000000', '#111111', '#222222',
                                        '#333333', '#444444', '#555555',
                                        '#666666', '#777777', '#888888',
                                        '#999999', '#AAAAAA', '#BBBBBB',
                                        '#CCCCCC', '#DDDDDD', '#EEEEEE',
                                        '#FFFFFF'},
                    ['policy_lines'] = {'Default',
                                        '1 = 1 line',
                                        '2 = 2 lines',
                                        '3 = 3 lines',
                                        '4 = 4 lines',
                                        '5 = 5 lines',
                                        '6 = 6 lines',
                                        '7 = 7 lines',
                                        '8 = 8 lines',
                                        '9 = 9 lines',
                                        '10 = 10 lines',
                                        '15 = 15 lines',
                                        '20 = 20 lines',
                                        '25 = 25 lines'},
                    ['scroll_width'] = {'Default',
                                        'Empty',
                                        '80 = 80 characters',
                                        '120 = 120 characters',
                                        '160 = 160 characters',
                                        '200 = 200 characters',
                                        '256 = 256 characters',
                                        '512 = 512 characters',
                                        '1024 = 1024 characters',
                                        '2048 = 2048 characters',
                                        '4096 = 4096 characters',
                                        '8192 = 8192 characters',
                                        '10240 = 10240 characters',
                                        '20480 = 20480 characters',
                                        '40960 = 40960 characters',
                                        '81920 = 81920 characters',
                                        '102400 = 102400 characters'}}

    -- Properties and the available values.
    local list = {
        ['are.you.sure.on.reload'] = preset.off_on,
        ['autocomplete.choose.single'] = preset.off_on,
        ['autocomplete.multi'] = preset.off_on,
        ['autocomplete.visible.item.count'] = {'Default',
                                               'Empty',
                                               '3 = 3 items',
                                               '6 = 6 items',
                                               '9 = 9 items',
                                               '12 = 12 items',
                                               '15 = 15 items',
                                               '18 = 18 items',
                                               '21 = 21 items',
                                               '24 = 24 items',
                                               '27 = 27 items',
                                               '30 = 30 items'},
        ['autocompleteword.automatic'] = preset.off_on,
        ['braces.check'] = preset.off_on,
        ['braces.sloppy'] = preset.off_on,
        ['caret.additional.blinks'] = preset.off_on,
        ['caret.additional.fore'] = preset.grey_colours,
        ['caret.fore'] = preset.grey_colours,
        ['caret.line.back'] = preset.grey_colours,
        ['caret.line.frame'] = {'Default',
                                '0 = Off',
                                '1 = 1 pixel',
                                '2 = 2 pixels',
                                '3 = 3 pixels',
                                '4 = 4 pixels',
                                '5 = 5 pixels'},
        ['caret.line.layer'] = {'Default',
                                '0 = Opaque',
                                '1 = Under text',
                                '2 = Over text'},
        ['caret.period'] = {'Default',
                            '1000 = 1 second',
                            '2000 = 2 seconds'},
        ['caret.policy.xslop'] = preset.off_on,
        ['caret.policy.width'] = {'Default',
                                  '10 = 10 pixels',
                                  '20 = 20 pixels',
                                  '30 = 30 pixels',
                                  '40 = 40 pixels',
                                  '50 = 50 pixels',
                                  '60 = 60 pixels',
                                  '70 = 70 pixels',
                                  '80 = 80 pixels',
                                  '90 = 90 pixels',
                                  '100 = 100 pixels',
                                  '120 = 120 pixels',
                                  '140 = 140 pixels',
                                  '160 = 160 pixels',
                                  '180 = 180 pixels',
                                  '200 = 200 pixels'},
        ['caret.policy.xstrict'] = preset.off_on,
        ['caret.policy.xeven'] = preset.off_on,
        ['caret.policy.xjumps'] = preset.off_on,
        ['caret.policy.yslop'] = preset.off_on,
        ['caret.policy.lines'] = preset.policy_lines,
        ['caret.policy.ystrict'] = preset.off_on,
        ['caret.policy.yeven'] = preset.off_on,
        ['caret.policy.yjumps'] = preset.off_on,
        ['caret.style'] = {'Default',
                           '1 = Line',
                           '2 = Block'},
        ['caret.width'] = {'Default',
                           '1 = 1 pixel',
                           '2 = 2 pixels',
                           '3 = 3 pixels',
                           '4 = 4 pixels',
                           '5 = 5 pixels',
                           '6 = 6 pixels',
                           '7 = 7 pixels',
                           '8 = 8 pixels',
                           '9 = 9 pixels'},
        ['change.history'] = {'Default',
                              '0 = Off',
                              '1 = On',
                              '3 = Markers',
                              '5 = Indicators',
                              '7 = Markers and Indicators'},
        ['clear.before.execute'] = preset.off_on,
        ['code.page'] = {'Default',
                         '0 = ANSI',
                         '65001 = UTF-8'},
        ['default.file.ext'] = {'Default', 'Empty', '.au3', '.bas', '.c',
                                '.cmd', '.cpp', '.css', '.cxx', '.diff',
                                '.html', '.iss', '.js', '.json', '.lua',
                                '.md', '.pas', '.php', '.properties',
                                '.ps1', '.py', '.sh', '.sql', '.txt', '.xml'},
        ['discover.properties'] = preset.off_on,
        ['edge.colour'] = preset.grey_colours,
        ['edge.column'] = {'Default',
                           '40 = 40 characters',
                           '60 = 60 characters',
                           '80 = 80 characters',
                           '100 = 100 characters',
                           '120 = 120 characters',
                           '140 = 140 characters',
                           '160 = 160 characters',
                           '180 = 180 characters',
                           '200 = 200 characters'},
        ['edge.mode'] = preset.off_on,
        ['editor.config.enable'] = {'Default',
                                    '0 = Off',
                                    '1 = On for files to be opened'},
        ['end.at.last.line'] = preset.off_on,
        ['ensure.consistent.line.ends'] = preset.off_on,
        ['ensure.final.line.end'] = preset.off_on,
        ['eol.auto'] = preset.off_on,
        ['error.inline'] = preset.off_on,
        ['error.select.line'] = {'Default',
                                 '0 = Goto line',
                                 '1 = Goto line and select whole line'},
        ['export.html.folding'] = preset.off_on,
        ['export.html.title.fullpath'] = preset.off_on,
        ['export.html.wysiwyg'] = preset.off_on,
        ['export.keep.ext'] = {'Default',
                               '0 = Filename.html',
                               '1 = Fullpath.ext.html',
                               '2 = Fullpath_ext.html'},
        ['ext.lua.auto.reload'] = preset.off_on,
        ['ext.lua.reset'] = preset.off_on,
        ['filter.context'] = {'Default',
                              '0 = Off',
                              '1 = 1 line',
                              '2 = 2 lines',
                              '3 = 3 lines'},
        ['find.close.on.find'] = {'Default',
                                  '0 = Close strip manually',
                                  '1 = Close strip auto (Default if undefined)',
                                  '2 = Close strip auto on match'},
        ['find.command'] = {'Default',
                            'Empty',
                            'find /n $(find.matchcase) "$(find.what)" $(find.files)',
                            'findstr /n /s $(find.matchcase) "/d:$(find.directory)" "$(find.what)" $(find.files)'},
        ['find.input'] = {'Default',
                          'Empty',
                          '$(find.what)'},
        ['find.option.matchcase.0'] = {'Default', 'Empty', '-i', '/i'},
        ['find.option.matchcase.1'] = {'Default', 'Empty'},
        ['find.option.wholeword.0'] = {'Default', 'Empty'},
        ['find.option.wholeword.1'] = {'Default', 'Empty', '-w', '/w'},
        ['find.replace.advanced'] = {'Default',
                                     '0 = Off',
                                     '1 = Enable replace in buffers'},
        ['find.use.strip'] = preset.off_on,
        ['fold'] = preset.off_on,
        ['fold.compact'] = preset.off_on,
        ['fold.flags'] = {'Default',
                          '0 = Off',
                          '2 = Line above unfolded',
                          '4 = Line above folded',
                          '6 = Line above both',
                          '8 = Line below unfolded',
                          '16 = Line below folded',
                          '24 = Line below both',
                          '30 = Line all',
                          '64 = Debug fold levels',
                          '128 = Debug line state'},
        ['fold.highlight'] = preset.off_on,
        ['fold.on.open'] = preset.off_on,
        ['fold.stroke.width'] = {'Default',
                                 '100 = Standard displays',
                                 '200 = High DPI displays'},
        ['fold.symbols'] = {'Default',
                            '0 = Directional arrows',
                            '1 = Plus and minus',
                            '2 = Round shape',
                            '3 = Square shape'},
        ['font.monospace'] = {},
        ['font.quality'] = {'Default',
                            '0 = Default',
                            '1 = Non-antialiased',
                            '2 = Antialiased',
                            '3 = LCD Optimized'},
        ['highlight.current.word'] = preset.off_on,
        ['highlight.current.word.by.style'] = preset.off_on,
        ['horizontal.scroll.width'] = preset.scroll_width,
        ['horizontal.scroll.width.tracking'] = preset.off_on,
        ['horizontal.scrollbar'] = preset.off_on,
        ['indent.auto'] = preset.off_on,
        ['indent.automatic'] = preset.off_on,
        ['indent.closing'] = preset.off_on,
        ['indent.opening'] = preset.off_on,
        ['lexer.errorlist.escape.sequences'] = preset.off_on,
        ['lexer.errorlist.value.separate'] = preset.off_on,
        ['load.on.activate'] = preset.off_on,
        ['output.horizontal.scroll.width'] = preset.scroll_width,
        ['output.horizontal.scroll.width.tracking'] = preset.off_on,
        ['output.horizontal.scrollbar'] = preset.off_on,
        ['output.scroll'] = {'Default',
                             '0 = No auto scroll',
                             '1 = Auto scroll and return to command',
                             '2 = Auto scroll to end and remain'},
        ['print.colour.mode'] = {'Default',
                                 '1 = Inverted',
                                 '2 = Black on white',
                                 '3 = Force background to white',
                                 '4 = Force default background to white'},
        ['print.magnification'] = {'Default',
                                   '-9 = Smaller',
                                   '-8 = Smaller',
                                   '-7 = Smaller',
                                   '-6 = Smaller',
                                   '-5 = Smaller',
                                   '-4 = Smaller',
                                   '-3 = Smaller',
                                   '-2 = Smaller',
                                   '-1 = Smaller',
                                   '0 = Same',
                                   '1 = Larger',
                                   '2 = Larger',
                                   '3 = Larger',
                                   '4 = Larger',
                                   '5 = Larger',
                                   '6 = Larger',
                                   '7 = Larger',
                                   '8 = Larger',
                                   '9 = Larger'},
        ['properties.directory.enable'] = {'Default',
                                           '0 = Off',
                                           '1 = On for files to be opened'},
        ['read.only'] = {'Default',
                         '0 = Off',
                         '1 = Open as read only'},
        ['reload.preserves.undo'] = preset.off_on,
        ['replace.use.strip'] = preset.off_on,
        ['representations'] = {'Default',
                               'Empty',
                               '!1,#A0A0A0,\\x0D\\x0A=CRLF',
                               '!1,#A0A0A0,\\x0A=LF,\\x0D=CR',
                               '!1,#A0A0A0,\\x0D\\x0A=\\r\\n',
                               '!1,#A0A0A0,\\x0A=\\n,\\x0D=\\r',
                               '!1,#AAAA55,\\x20= ,!1,#A0A0A0,\\x0A=\\n,\\x0D=\\r'},
        ['save.check.modified.time'] = preset.off_on,
        ['save.deletes.first'] = preset.off_on,
        ['save.find'] = preset.off_on,
        ['save.on.deactivate'] = preset.off_on,
        ['save.on.timer'] = {'Default',
                             '0 = Off',
                             '60 = 1 minute',
                             '300 = 5 minutes',
                             '600 = 10 minutes',
                             '900 = 15 minutes',
                             '1800 = 30 minutes',
                             '2700 = 45 minutes',
                             '3600 = 1 hour'},
        ['save.position'] = preset.off_on,
        ['save.recent'] = preset.off_on,
        ['save.session'] = preset.off_on,
        ['selection.additional.typing'] = {'Default',
                                           '0 = Only the main selection',
                                           '1 = All selections.'},
        ['selection.multipaste'] = {'Default',
                                    '0 = Only the last selection',
                                    '1 = All selections'},
        ['selection.multiple'] = preset.off_on,
        ['selection.rectangular.switch.mouse'] = preset.off_on,
        ['session.bookmarks'] = preset.off_on,
        ['session.folds'] = preset.off_on,
        ['strip.trailing.spaces'] = preset.off_on,
        ['tabbar.hide.index'] = preset.off_on,
        ['tabbar.hide.one'] = preset.off_on,
        ['technology'] = {'Default',
                          '0 = GDI',
                          '1 = DirectWrite',
                          '2 = DirectWrite (retain frame)',
                          '3 = DirectWrite (works with some cards)',
                          '4 = DirectWrite (updated v1.1)'},
        ['time.commands'] = preset.off_on,
        ['title.full.path'] = {'Default',
                               '0 = Filename',
                               '1 = Fullpath',
                               '2 = Filename in directory'},
        ['title.show.buffers'] = preset.off_on,
        ['undo.selection.history'] = preset.off_on,
        ['virtual.space'] = {'Default',
                             '0 = Off',
                             '1 = Allow rectangle selection',
                             '2 = Allow arrow keys and mouse click',
                             '3 = Allow both',
                             '4 = Prevent left arrow wrapping previous line'},
        ['visible.policy.strict'] = preset.off_on,
        ['visible.policy.slop'] = preset.off_on,
        ['visible.policy.lines'] = preset.policy_lines,
        ['wrap.indent.mode'] = {'Default',
                                '0 = Indented left of window + wrap.visual.startindent',
                                '1 = Align to 1st subline',
                                '2 = Align to 1st subline + 1 indent'},
        ['wrap.visual.flags'] = {'Default',
                                 '0 = Off',
                                 '1 = End of lines',
                                 '2 = Begin of lines',
                                 '3 = Begin and end of lines'},
        ['wrap.visual.flags.location'] = {'Default',
                                          '0 = Begin and end markers near border',
                                          '1 = End markers near text',
                                          '2 = Begin markers near text',
                                          '3 = All markers near text'},
        ['wrap.visual.startindent'] = {'Default',
                                       '0 = No indent',
                                       '1 = 1 indent',
                                       '2 = 2 indents',
                                       '3 = 3 indents',
                                       '4 = 4 indents'}}

    -- Language related properties.
    local language = props['Language']
    local lexprops = {}

    for _, v in pairs({'cpp', 'html', 'json', 'markdown',
                       'properties', 'python', 'sql', 'xml'}) do

        if v == language then
            local text = 'Include ' .. language .. ' related property names?'

            if MsgBox(text, 'SetProperty', MB_ICONQUESTION|
                                           MB_DEFBUTTON2|
                                           MB_YESNO) == IDNO then
                goto endlanguages
            end

            break
        end
    end

    if language == 'cpp' then
        lexprops = {['fold.at.else'] = preset.off_on,
                    ['fold.comment'] = preset.off_on,
                    ['fold.cpp.comment.explicit'] = preset.off_on,
                    ['fold.cpp.comment.multiline'] = preset.off_on,
                    ['fold.cpp.explicit.anywhere'] = preset.off_on,
                    ['fold.cpp.preprocessor.at.else'] = preset.off_on,
                    ['fold.cpp.syntax.based'] = preset.off_on,
                    ['fold.preprocessor'] = preset.off_on,
                    ['lexer.cpp.allow.dollars'] = preset.off_on,
                    ['lexer.cpp.backquoted.strings'] = preset.off_on,
                    ['lexer.cpp.escape.sequence'] = preset.off_on,
                    ['lexer.cpp.hashquoted.strings'] = preset.off_on,
                    ['lexer.cpp.track.preprocessor'] = preset.off_on,
                    ['lexer.cpp.triplequoted.strings'] = preset.off_on,
                    ['lexer.cpp.update.preprocessor'] = preset.off_on,
                    ['lexer.cpp.verbatim.strings.allow.escapes'] = preset.off_on,
                    ['styling.within.preprocessor'] = preset.off_on}
    elseif language == 'json' then
        lexprops = {['lexer.json.allow.comments'] = preset.off_on,
                    ['lexer.json.escape.sequence'] = preset.off_on}
    elseif language == 'markdown' then
        lexprops = {['lexer.markdown.header.eolfill'] = preset.off_on}
    elseif language == 'properties' then
        lexprops = {['lexer.props.allow.initial.spaces'] = preset.off_on}
    elseif language == 'python' then
        lexprops = {['fold.quotes.python'] = preset.off_on,
                    ['indent.python.colon'] = preset.off_on,
                    ['lexer.python.decorator.attributes'] = preset.off_on,
                    ['lexer.python.identifier.attributes'] = preset.off_on,
                    ['lexer.python.keywords2.no.sub.identifiers'] = preset.off_on,
                    ['lexer.python.literals.binary'] = preset.off_on,
                    ['lexer.python.strings.b'] = preset.off_on,
                    ['lexer.python.strings.f'] = preset.off_on,
                    ['lexer.python.strings.f.pep.701'] = preset.off_on,
                    ['lexer.python.strings.over.newline'] = preset.off_on,
                    ['lexer.python.strings.u'] = preset.off_on,
                    ['lexer.python.unicode.identifiers'] = preset.off_on,
                    ['tab.timmy.whinge.level'] = {'Default',
                                                  '0 = No indent check',
                                                  '1 = Check line consistent',
                                                  '2 = Check indent for space before tab',
                                                  '3 = Check indent for any spaces',
                                                  '4 = Check indent for any tabs'}}
    elseif language == 'sql' then
        lexprops = {['fold.sql.at.else'] = preset.off_on,
                    ['fold.sql.only.begin'] = preset.off_on,
                    ['lexer.sql.allow.dotted.word'] = preset.off_on,
                    ['lexer.sql.numbersign.comment'] = preset.off_on,
                    ['sql.backslash.escapes'] = preset.off_on}
    elseif language == 'xml' or language == 'html' then
        lexprops = {['fold.html'] = preset.off_on,
                    ['fold.html.preprocessor'] = preset.off_on,
                    ['fold.hypertext.comment'] = preset.off_on,
                    ['fold.hypertext.heredoc'] = preset.off_on,
                    ['fold.xml.at.tag.open'] = preset.off_on,
                    ['html.tags.case.sensitive'] = preset.off_on,
                    ['lexer.html.django'] = preset.off_on,
                    ['lexer.html.mako'] = preset.off_on,
                    ['lexer.xml.allow.scripts'] = preset.off_on}
    end

    for name, value in pairs(lexprops) do
        list[name] = value
    end

    ::endlanguages::

    -- Get the names.
    local names = {}

    for name in pairs(list) do
        table.insert(names, name)
    end

    if names == '' then
        return
    end

    if next(GlobalSettings['prop_list']) then
        table.insert(names, 'Default')
    end

    table.insert(names, 'SelectProperty')

    table.sort(names)

    -- Get the selected name.
    local result = ListBox(names, 'SetProperty')

    if not result then
        return
    end

    result = result + 1
    local name = names[result]

    -- Unmask all recorded property values.
    if name == 'Default' then
        for k in pairs(GlobalSettings['prop_list']) do
            GlobalSettings['prop_list'][k] = nil
            props[k] = nil
        end

        return
    end

    -- Set a property and value with a InputBox.
    if name == 'SelectProperty' then
        name = GlobalSettings['prop_last'] or ''

        name = InputBox(name, 'SetProperty', 'Enter a property name')

        if name == nil or name == '' then
            return
        end

        local value = InputBox(props[name],
                               'SetProperty',
                               'Enter the value for ' .. name)

        if value == nil then
            return
        end

        if value == '' then
            local reply = MsgBox('Set the value as empty for ' .. name .. '?' ..
                                 '\r\n\r\n' ..
                                 'Select No to unmask and use the actual value.',
                                 'SetProperty', MB_YESNOCANCEL)

            if reply == IDYES then
                value = ''
            elseif reply == IDNO then
                value = nil
            else
                return
            end
        end

        props[name] = value
        GlobalSettings['prop_list'][name] = value
        GlobalSettings['prop_last'] = name
        return
    end

    -- Set edge.column to include current column position.
    if name == 'edge.column' then
        local column = editor.Column[editor.CurrentPos]

        if column > 0 then
            local text = string.format('%s = %s characters (Current Column)', column, column)
            table.insert(list['edge.column'], text)
        end
    end

    -- Set font.monospace values based on technology used.
    if name == 'font.monospace' then

        -- Get technology in use.
        local directwrite = string.match(props['technology'], '[1-4]') ~= nil

        -- Default fonts.
        list[name] = {'Default',
                      'font:Consolas,size:10',
                      'font:Courier New,size:10',
                      'font:Lucida Console,size:10'}

        if not directwrite then
            table.insert(list[name], 'font:Courier,size:10')
        end

        -- Include some 3rd party fonts.
        local text = 'Include 3rd party fonts?'

        if directwrite then
            text = 'Using DirectWrite which supports font ligatures...\n\n' .. text
        else
            text = 'Using GDI\n\n' .. text
        end

        if MsgBox(text, name, MB_ICONQUESTION|
                              MB_DEFBUTTON2|
                              MB_YESNO) == IDYES then

            -- Fonts with ligatures.
            table.insert(list[name], 'font:Cascadia Code,size:10')
            table.insert(list[name], 'font:Fira Code,size:10')
            table.insert(list[name], 'font:JetBrains Mono,size:10')

            -- Fonts without ligatures.
            table.insert(list[name], 'font:Source Code Pro,size:10')

            if directwrite then
                table.insert(list[name], 'font:Cascadia Mono,size:10')
            end
        end

        table.sort(list[name])
    end

    -- Get the selected value.
    result = ListBox(table.concat(list[name], '|'), name .. '=' .. props[name])

    if not result then
        return
    end

    result = result + 1
    local selected = (list[name])[result]

    -- Set fold.flags with a wider line margin if debugging folds.
    if name == 'fold.flags' then
        local digits = string.match(selected, '^%d+')

        if digits == '64' or digits == '128' then
            props['line.margin.width'] = '10+'
        else
            props['line.margin.width'] = nil
        end
    end

    -- Set the Property with the new value.
    if selected == 'Default' then
        props[name] = nil
        GlobalSettings['prop_list'][name] = nil
    elseif selected == 'Empty' then
        props[name] = ''
        GlobalSettings['prop_list'][name] = ''
    elseif selected == 'SelectColour' then
        local colour = ColourDialog()

        if colour then
            props[name] = colour
            GlobalSettings['prop_list'][name] = colour
        end
    else
        local digits = string.match(selected, '^%-?%d+')

        if digits then
            props[name] = digits
        else
            props[name] = selected
        end

        GlobalSettings['prop_list'][name] = props[name]
    end

    -- Reload properties needed only for these items.
    if name == 'title.full.path' or name == 'title.show.buffers' then
        scite.ReloadProperties()
    end

    -- Show information about UI items.
    if name == 'tabbar.hide.index' or name == 'tabbar.hide.one' then
        MsgBox('A UI property may need a UI event to update.\n' ..
               'Possibly switching tabs...', name, MB_ICONINFORMATION)
    end
end


local function SetStyle()
    -- Change a style value for the current SciTE instance.

    -- Get the lexer language.
    local language = props['Language']

    if language == '' or language == 'null' then
        MsgBox('Cannot style this language: ' .. language, 'SetStyle', MB_ICONWARNING)
        return
    end

    -- Set to use ColourDialog or InputBox for the current instance.
    if GlobalSettings['style_by_colour'] == nil then
        if MsgBox('Select foreground colour by Colour Dialog?\n\n' ..
                  'Click No to edit the value by InputBox.\n\n' ..
                  'This question will be asked only once per instance.',
                  'SetStyle', MB_ICONQUESTION|MB_YESNO) == IDYES then

            GlobalSettings['style_by_colour'] = true
        else
            GlobalSettings['style_by_colour'] = false
        end
    end

    -- Get the style names.
    local list = {'Default'}
    local prefix = 'style.' .. language .. '.'

    local id = editor.StyleAt[editor.CurrentPos]
    local index = 0

    for i = 0, 127 do
        local name = string.format(prefix .. '%s', i)

        if i == id then
            index = #list
        end

        if props[name] ~= '' then
            table.insert(list, name)
        end
    end

    -- Get the selected name.
    local result = ListBox(list, 'SetStyle', index)

    if result == nil then
        return
    end

    result = result + 1
    local name = list[result]

    -- Unmask all recorded style values for this language.
    if name == 'Default' then
        prefix = string.gsub(prefix, '%.', '%%.')

        for k in pairs(GlobalSettings['prop_list']) do
            if string.find(k, '^' .. prefix) ~= nil then
                GlobalSettings['prop_list'][k] = nil
                props[k] = nil
            end
        end

        return
    end

    -- Set foreground colour by ColourDialog.
    if GlobalSettings['style_by_colour'] then
        local value = ColourDialog()

        if value == nil then
            return
        end

        props[name] = 'fore:' .. value
        GlobalSettings['prop_list'][name] = props[name]
        return
    end

    -- Get the description of the style.
    local description = ''

    id = string.match(name, '%d+$')

    if id then
        id = tonumber(id)
        description = editor:DescriptionOfStyle(id)

        if description == '' then
            for k, v in pairs({[32] = 'Default style',
                               [33] = 'Line numbers in the margin',
                               [34] = 'Matching brace',
                               [35] = 'Non-matching brace',
                               [36] = 'Control characters',
                               [37] = 'Indentation guides',
                               [38] = 'Calltips'}) do

                if k == id then
                    description = v
                    break
                end
            end
        end
    end

    -- Set a property and value with a InputBox.
    local value = InputBox(props[name],
                           'SetStyle',
                           'Enter the value for ' .. name ..
                           '\r\n\r\n    ' .. description)

    if value == nil then
        return
    end

    if value == '' then
        local reply = MsgBox('Set the value as empty for ' .. name .. '?' ..
                             '\r\n\r\n' ..
                             'Select No to unmask and use the actual value.',
                             'SetStyle', MB_YESNOCANCEL)

        if reply == IDYES then
            value = ''
        elseif reply == IDNO then
            value = nil
        else
            return
        end
    end

    props[name] = value
    GlobalSettings['prop_list'][name] = props[name]
end


local function StartExeFile()
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


local function StripTrailingSpaces()
    -- http://lua-users.org/wiki/SciteCleanDocWhitespace

    local report_nomatch = false
    local count = 0
    local fs, fe = editor:findtext('[ \\t]+$', SCFIND_REGEXP)

    if fe then
        editor:BeginUndoAction()

        repeat
            count = count + 1
            editor:remove(fs, fe)
            fs, fe = editor:findtext('[ \\t]+$', SCFIND_REGEXP, fs)
        until not fe

        editor:EndUndoAction()

        MsgBox('Removed trailing spaces from ' .. count .. ' line(s).',
               'StripTrailingSpaces', MB_ICONINFORMATION)
    elseif report_nomatch then
        MsgBox('Document was clean already; nothing to do.',
               'StripTrailingSpaces', MB_ICONINFORMATION)
    end
end


local function ToggleCodePage()
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


local function ToggleDimComments()
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


local function ToggleExtendedTools()
    -- Toggle extended setting and show ListBox again.

    -- Toggle extended setting.
    GlobalSettings['tools']['extended'] = not GlobalSettings['tools']['extended']

    -- Show ListBox again.
    GlobalTools()
end


local function ToggleHighlightCurrentWord()
    -- Toggles the property highlight.current.word of 0 and 1.

    local setting = props['highlight.current.word']

    if setting == '0' or setting == '' then
        props['highlight.current.word'] = '1'
    else
        props['highlight.current.word'] = '0'
    end
end


local function ToggleMonospaceFont()
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


local function UserContextMenu()
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
                scite.ReloadProperties()
            end
        end
    else
        props['user.context.menu'] = nil

        if opt_tools then
            if props['command.name.48.*'] == 'DebugPrintSelection' then
                props['command.name.48.*'] = nil
                props['command.shortcut.48.*'] = nil
                scite.ReloadProperties()
            end
        end
    end
end


local function WinMergeFilePath(mode)
    -- Run WinMerge to diff FilePath with another file.
    -- If mode is 'unsaved', diff editor with FilePath if exist, else with selection.

    local filepath = props['FilePath']

    -- Set path to WinMerge.
    local app = GlobalSettings['paths']['winmerge']

    -- Build the command.
    local command

    if mode == 'left' then
        table.insert(GlobalSettings['compare_paths'], 1, filepath)
        return
    elseif mode == 'middle' then
        table.insert(GlobalSettings['compare_paths'], 2, filepath)
        return
    end

    if mode == 'unsaved' then
        local text = editor:GetText()

        if text == nil or text == '' then
            MsgBox('No editor text.', 'WinMergeFilePath unsaved', MB_ICONWARNING)
            return
        end

        -- Strip \r as lua may add \r to \n on write.
        text = string.gsub(text, '\r', '')

        -- Write the unsaved text to a temporary file.
        local fileext = props['FileExt']
        local tmpfile = GetTmpFilename(fileext)

        local file = io.open(tmpfile, 'w')

        if file == nil then
            MsgBox('No file handle to write.', 'WinMergeFilePath unsaved', MB_ICONWARNING)
            return
        end

        file:write(text)
        file:close()

        -- Build the command to diff the files.
        if mode == 'unsaved' then
            command = '"' .. app .. '" /u ' ..
                      '/dl "Unsaved" ' ..
                      '/wl "' .. tmpfile .. '"'

            -- Check filepath is actual file.
            if string.match(filepath, '\\$') then
                filepath = ''
            end

            if filepath ~= '' then
                command = command .. ' "' .. filepath .. '"'
            end
        end

        command = command .. ' &del "' .. tmpfile .. '"'
    else
        -- Check filepath.
        if filepath == '' then
            MsgBox('Require a filepath.', 'WinMergeFilePath', MB_ICONWARNING)
            return
        end

        -- Build the command to diff the files.
        command = '"' .. app .. '" /u'

        if next(GlobalSettings['compare_paths']) then
            for i = 1, #GlobalSettings['compare_paths'] do
                command = command .. ' "' .. GlobalSettings['compare_paths'][i] .. '"'
            end

            GlobalSettings['compare_paths'] = {}
        end

        command = command .. ' "' .. filepath .. '"'
    end

    -- Run WinMerge.
    os.execute('start "" /b cmd /s /c "' .. command .. '"')
end


-- Global functions.
-- Called externally with events, tools menu, extension scripts...

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
        MsgBox('No selected text.', 'DebugPrintSelection', MB_ICONWARNING)
        return
    end

    -- Goto end of line to end selection and add a new line.
    editor:LineEnd()
    editor:NewLine()

    -- Add a line to print the value.
    if props['FileExt'] == 'au3' then
        -- AutoIt3.
        editor:AddText('ConsoleWrite("' .. string.gsub(text, '"', '""') .. ': " & ' .. text .. ' & @CRLF)  ; debug:')
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
        editor:AddText('print("' .. string.gsub(text, '"', '\\\"') .. ':", ' .. text .. ')  -- debug:')
    elseif props['FileExt'] == 'py' or props['FileExt'] == 'pyw' then
        -- Python.
        editor:AddText('print("' .. string.gsub(text, '"', '\\\"') .. ':", ' .. text .. ')  # debug:')
    else
        return
    end

    -- Add a bookmark to keep track of the added line.
    if use_markers then
        editor:MarkerAdd(editor:LineFromPosition(editor.CurrentPos), 1)
    end
end


function ReplaceSelAutocomplete()
    -- Replace current selection or current word with autocompletion.

    if editor:AutoCActive() then
        return
    end

    -- Get selected text or word.
    local selected = props['CurrentSelection']

    if selected == '' then
        selected = props['CurrentWord']
    end

    if selected == '' then
        return
    end

    -- Set pattern for the language.
    local language = editor.LexerLanguage
    local pattern

    if language == 'batch' then
        pattern = '[%w_]'
    elseif language == 'css' or language == 'powershell' then
        pattern = '[%w%-]'
    elseif language == 'lua' then
        pattern = '[%w_%.:]'
    else
        pattern = '[%w_%.]'
    end

    if not string.find(selected, '^' .. pattern .. '+$') then
        return
    end

    -- Get initial pos to go back if needed later.
    local initialPos = editor.CurrentPos

    -- Ensure anchor is at start.
    if editor.Anchor > editor.CurrentPos then
        editor:SwapMainAnchorCaret()
    end

    -- Extend selection start.
    local startPos = editor.Anchor

    repeat
        startPos = startPos - 1
        local ch = editor.CharAt[startPos]
    until not string.find(string.char(ch), pattern)

    startPos = startPos + 1

    while string.find(string.char(editor.CharAt[startPos]), '[%-%.:]') do
        startPos = startPos + 1
    end

    editor.SelectionStart = startPos

    -- Extend selection end.
    local endPos = editor.CurrentPos - 1

    repeat
        endPos = endPos + 1
        local ch = editor.CharAt[endPos]
    until not string.find(string.char(ch), pattern)

    while string.find(string.char(editor.CharAt[endPos - 1]), '[%-%.:]') do
        endPos = endPos - 1
    end

    editor.SelectionEnd = endPos

    -- Search api files for keywords.
    local api = props['APIPath']

    local list = {}

    for path in string.gmatch(api, '[^;]+') do
        local file = io.open(path)

        if file then
            local selectedLower = string.lower(selected)

            for line in file:lines() do
                local keyword = string.match(line, '^' .. pattern .. '+')

                if keyword then
                    local keywordLower = string.lower(keyword)

                    if string.find(keywordLower, selectedLower, 1, true) then
                        table.insert(list, keyword)
                    end
                end
            end

            file:close()
        end
    end

    table.unique(list)

    -- Get full selection and return if autocomplete list is selection.
    selected = editor:GetSelText()

    if #list == 0 or (#list == 1 and list[1] == selected) then
        editor:SetEmptySelection(initialPos)
        return
    else
        if editor.AutoCIgnoreCase then
            local function comp(x, y)
                return string.upper(x) < string.upper(y)
            end

            table.sort(list, comp)
        else
            table.sort(list)
        end
    end

    -- Show autocomplete.
    local itemList = table.concat(list, ' ')

    if itemList ~= '' then
        if editor.Anchor < editor.CurrentPos then
            editor:SwapMainAnchorCaret()
        end

        editor.AutoCSeparator = 0x20
        editor:AutoCShow(0, itemList)

        if editor:AutoCActive() then
            editor:Clear()

            -- Autocomplete select item only if needed.
            if #list < 2 then
                return
            end

            if selected == '' or editor.AutoCCurrentText == selected then
                return
            end

            -- Try exact match.
            for _, v in pairs(list) do
                if v == selected then
                    editor:AutoCSelect(selected)
                    return
                end
            end

            -- Try editor object for subsystem languages.
            if language == 'lua' or language == 'python' then
                for _, v in pairs(list) do
                    if string.find(v, '^editor[.:]') then
                        editor:AutoCSelect(v)
                        return
                    end
                end
            end

            -- Try from start match.
            local selectedLen = string.len(selected)

            for _, v in pairs(list) do
                if string.sub(v, 1, selectedLen) == selected then
                    editor:AutoCSelect(selected)
                    return
                end
            end
        end
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


function GlobalTools()
    -- List all local lua functions for tool menu.

    -- List of tools.
    local list = {}

    if props['FileNameExt'] ~= '' then
        list['BackupFilePath'] = BackupFilePath
    end

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

    if (not editor.Modify and (editor:CanUndo() or editor:CanRedo())) or
        (output:CanUndo() or output:CanRedo()) then

        list['EmptyUndoBuffer'] = EmptyUndoBuffer
    end

    if os.path.exist(GlobalSettings['paths']['eskil']) then
        list['EskilFilePath'] = EskilFilePath
    end

    if os.path.exist(GlobalSettings['paths']['frhed']) then
        list['FrhedFilePath'] = function()
                                    FrhedFilePath()
                                end
    end

    list['GotoPosition']          = GotoPosition
    list['InsertCtrlCharacter']   = InsertCtrlCharacter
    list['InsertDate']            = InsertDate

    if Buffer:get() then
        list['ManageBookmarks']   = ManageBookmarks
    end

    list['ManageTemplates']       = ManageTemplates
    list['OpenAbbrevFile']        = OpenAbbrevFile
    list['OpenApiFile']           = OpenApiFile
    list['OpenChmFile']           = OpenChmFile
    list['OpenFileDir']           = OpenFileDir
    list['OpenHtaFile']           = OpenHtaFile

    if GlobalSettings['last_closed_file'] then
        list['OpenLastClosedFile'] = OpenLastClosedFile
    end

    list['OpenLuaExtensionFile']  = OpenLuaExtensionFile

    if GlobalSettings['tools']['extended'] then
        list['OpenSciteVarsFile'] = OpenSciteVarsFile
    end

    if props['FileExt'] ~= '' then
        if not string.find(props['FileExt'], '^%d+$') then
            list['OpenTempFile']  = OpenTempFile
        end
    end

    list['PrintApiKeywords']      = PrintApiKeywords
    list['PrintApiLuaPropsFiles'] = PrintApiLuaPropsFiles
    list['PrintAsciiTable']       = PrintAsciiTable

    list['PrintBookmarks']    = function()
                                    PrintMarkers('bookmarks')
                                end

    list['PrintChangeHistory']    = function()
                                        PrintMarkers('change_history')
                                    end

    list['PrintCommentLines']     = PrintCommentLines

    list['PrintCommentedCodeLines']   = function()
                                            PrintCommentLines('code')
                                        end

    list['PrintFindText'] = PrintFindText

    if GlobalSettings['tools']['extended'] then
        list['PrintGlobalNames brief']    = function()
                                                PrintGlobalNames(1)
                                            end

        list['PrintGlobalNames calltip_style']    = function()
                                                        PrintGlobalNames(3)
                                                    end

        list['PrintGlobalNames informative']  = function()
                                                    PrintGlobalNames(2)
                                                end

        list['PrintGlobalNames name_only']    = function()
                                                    PrintGlobalNames(0)
                                                end

        list['PrintGlobalTables .* brief']    = function()
                                                    PrintGlobalTables(nil, false, false)
                                                end

        list['PrintGlobalTables .* extra']    = function()
                                                    PrintGlobalTables(nil, true, true)
                                                end

        list['PrintGlobalTables _G brief']    = function()
                                                    PrintGlobalTables(_G, false, true)
                                                end

        list['PrintGlobalTables _G extra']    = function()
                                                    PrintGlobalTables(_G, true, true)
                                                end
    end

    if next(GlobalSettings['prop_list']) ~= nil then
        list['PrintPropertyList']       = PrintPropertyList
    end

    list['PrintReminders']              = PrintReminders

    if GlobalSettings['tools']['extended'] then
        list['PrintSciteVars']          = PrintSciteVars
    end

    list['ReplaceSelAutocomplete']      = ReplaceSelAutocomplete
    list['ReplaceSelEscape']            = ReplaceSelEscape
    list['ReplaceSelSortLines']         = ReplaceSelSortLines
    list['ReplaceSelSortList']          = ReplaceSelSortList
    list['ReplaceSelWrapList']          = ReplaceSelWrapList
    list['SelectCalltipColour']         = SelectCalltipColour
    list['SetChangeHistory']            = SetChangeHistory
    list['SetColour']                   = SetColour
    list['SetProperty']                 = SetProperty
    list['SetStyle']                    = SetStyle
    list['StartExeFile']                = StartExeFile
    list['StripTrailingSpaces']         = StripTrailingSpaces
    list['ToggleCodePage']              = ToggleCodePage
    list['ToggleDimComments']           = ToggleDimComments
    list['ToggleExtendedTools']         = ToggleExtendedTools
    list['ToggleHighlightCurrentWord']  = ToggleHighlightCurrentWord
    list['ToggleMonospaceFont']         = ToggleMonospaceFont

    if os.path.exist(GlobalSettings['paths']['winmerge']) then
        if props['FileNameExt'] ~= '' then
            list['WinMergeFilePath'] = WinMergeFilePath

            list['WinMergeFilePath left'] = function()
                                                WinMergeFilePath('left')
                                            end

            if next(GlobalSettings['compare_paths']) then
                list['WinMergeFilePath middle']   = function()
                                                        WinMergeFilePath('middle')
                                                    end
            end
        end

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


function OnBeforeSave()
    -- Event handler for about to save file.

    -- Add a buffer table for filepath.
    -- Untitled buffers get a table if saved.
    Buffer:add()

    -- Check if ensure final line end setting is enabled.
    if props['ensure.final.line.end'] == '1' then

        -- Get data.
        local text = editor:GetText()

        -- Check if text is only a line end sequence.
        if text == '\r\n' or text == '\r' or text == '\n' then

            -- Question YesNo to rewrite as empty file.
            if MsgBox('The setting ensure.final.line.end may have caused an ' ..
                      'insertion of a newline sequence into a blank document.\n\n' ..
                      'Do you want the document to be cleared before ' ..
                      'the save to file?', 'OnBeforeSave', MB_ICONQUESTION|
                                                           MB_YESNO) == IDYES then
                editor:ClearAll()
            end
        end
    end
end


function OnClose(filepath)
    -- Event handler for the current closing file.

    -- Can be an empty string at startup.
    if filepath == '' or filepath == nil then
        return
    end

    -- Remove tmpfile and the filepath key.
    if Buffer:get('tmpfile') then
        os.remove(filepath)
    else
        -- Record last closed file.
        GlobalSettings['last_closed_file'] = filepath
    end

    Buffer:remove()
end


function OnOpen()
    -- Event handler for opening a file tab.

    -- Add a buffer table for filepath.
    Buffer:add()

    -- Close strip if no strip data.
    if not Buffer:has_strip() then
        scite.StripShow('')
    end

    -- Update the context menu.
    UserContextMenu()
end


function OnStrip(control, change)
    -- Event handler for strips.

    -- Close strip if no strip data.
    if not Buffer:has_strip() then
        scite.StripShow('')
        return
    end

    -- Set names for the events.
    local changetype = {'click', 'change', 'focusin', 'focusout'}

    -- Get all of the strips data.
    local edit_commit = Buffer:get('strip_edit_commit')

    -- Handle an event from BackupFilePath().
    if edit_commit then

        -- Set names for the controls.
        local controltype = {'comment', '?', 'compare', 'commit', 'cancel'}

        -- Only handle the click event.
        if changetype[change] ~= 'click' then
            return
        end

        -- ? button clicked.
        if controltype[control] == '?' then
            local text = ''
            local t = {}

            for k in pairs(edit_commit) do
                table.insert(t, k)
            end

            table.sort(t)

            for i = 1, #t do
                text = text .. t[i] .. ': ' .. edit_commit[ t[i] ] .. '\n\n'
            end

            text = string.sub(text, 1, -3)
            MsgBox(text, 'Information')
            return
        end

        -- Compare button clicked.
        if controltype[control] == 'compare' then

            -- Set path to WinMerge.
            local winmerge = GlobalSettings['paths']['winmerge']

            if not winmerge then
                MsgBox('Path for WinMerge not set.', 'Compare', MB_ICONWARNING)
                return
            end

            -- Build the file extension argument.
            local fileext = edit_commit['fileext']
            local fileext_arg = ''

            if fileext ~= '' then
                fileext_arg = '/fileext "' .. fileext .. '" '
            end

            -- Build the command to diff the files.
            local command = '"' .. winmerge .. '" /u ' .. fileext_arg ..
                            '/wl "' .. edit_commit['filepath'] .. '" ' ..
                            '"' .. edit_commit['tmpfile'] .. '"'

            -- Run WinMerge.
            os.execute('start "" /b cmd /s /c "' .. command .. '"')

            return
        end

        -- Commit button clicked.
        if controltype[control] == 'commit' then

            -- Get the comment.
            local comment = scite.StripValue(1)
            comment = EscapeComment(comment)

            if comment == nil or comment == '' then
                MsgBox('Invalid commit comment', 'Commit', MB_ICONWARNING)
                return
            end

            -- Get filename only for dbfile for the following message.
            local dbfile = string.match(edit_commit['dbfile'], '[^\\/]-$')

            if not dbfile then
                dbfile = edit_commit['dbfile']
            end

            -- Get confirmation.
            local result
            local text = 'Database: "' .. dbfile .. '"\r\n\r\n'

            if editor.Modify then
                text = text .. 'WARNING: Buffer content has not been saved.\n\n'
            end

            if comment == edit_commit['comment'] then
                text = text .. 'Comment has not changed. ' ..
                       'Insert new commit option is available ' ..
                       'only if the comment has changed.\n\n' ..
                       'Update the commit?'

                result = MsgBox(text, 'Commit', MB_ICONQUESTION|
                                                MB_DEFBUTTON2|
                                                MB_OKCANCEL)

                if result == IDOK then
                    result = IDNO
                end
            else
                text = text .. 'Comment has changed. ' ..
                       'Insert new commit option is available.\n\n' ..
                       'Insert as a new commit instead of ' ..
                       'update the commit?'

                result = MsgBox(text, 'Commit', MB_ICONQUESTION|
                                                MB_DEFBUTTON3|
                                                MB_YESNOCANCEL)
            end

            -- Insert the modified tmpfile into the database.
            local command = '""' .. edit_commit['sqlite'] .. '" ' ..
                            '"' .. edit_commit['dbfile'] .. '" '

            if result == IDYES then
                command = command .. '"INSERT INTO main VALUES' ..
                          '(date(\'now\', \'localtime\'),' ..
                          ' \'' .. comment .. '\',' ..
                          ' readfile(\'' .. edit_commit['tmpfile'] .. '\'))""'

            elseif result == IDNO then
                command = command .. '"UPDATE main ' ..
                          "SET comment='" .. comment .. "'," ..
                          'content=' ..
                          'readfile(\'' .. edit_commit['tmpfile'] .. '\') ' ..
                          'WHERE rowid = ' .. edit_commit['rowid'] .. '""'
            else
                return
            end

            os.execute(command)
        end

        -- Close the strip.
        scite.StripShow('')
        Buffer:remove('strip_edit_commit')

        -- Close the tmpfile tab.
        if Buffer:get('tmpfile') then
            scite.MenuCommand(IDM_CLOSE)

            -- Activate original tab.
            if props['FilePath'] ~= edit_commit['filepath'] then
                scite.Open(edit_commit['filepath'])
            end
        end
    end
end


function OnSwitchFile()
    -- Event handler for switching file tab.

    -- Add a buffer table for filepath.
    Buffer:add()

    -- Set strip show state.
    if Buffer:has_strip() then
        ShowStrip()
    else
        scite.StripShow('')
    end

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
