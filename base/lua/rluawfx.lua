-- About: https://github.com/robertorossi73/rscite/

local rwfx_NameDLL = 'rluawfx-en.dll'

local rwfx_ListBox = package.loadlib(rwfx_NameDLL, 'c_ListDlg')
local rwfx_MsgBox = package.loadlib(rwfx_NameDLL, 'c_MsgBox')
local rwfx_InputBox = package.loadlib(rwfx_NameDLL, 'c_InputBox')
local rwfx_ExecuteCmd = package.loadlib(rwfx_NameDLL, 'c_SendCmdScite')
local rwfx_Sleep = package.loadlib(rwfx_NameDLL, 'c_Sleep')


-- Warning to show once per instance.
local Warning_SendCmdScite = true


function InputBox(prompt, title, msg)
    -- Show a rluawfx input box gui.

    prompt = prompt or ''
    title = title or 'SciTE'
    msg = msg or 'Insert the data'

    local tmpfile = os.tmpname()

    if string.sub(tmpfile, 1, 1) == '\\' then
        tmpfile = os.getenv('TEMP') .. tmpfile
    end

    local result = rwfx_InputBox(prompt, title, msg, tmpfile)

    if result then
        local file = io.open(tmpfile)

        if file then
            local content = file:read('a')
            file:close()
            os.remove(tmpfile)
            return content
        end
    end
end


function ListBox(list, title, preset, x, y, w, h)
    -- Show a rluawfx list box gui.

    title = title or 'SciTE'
    preset = preset or 0
    x = x or -1
    y = y or -1
    w = w or 0
    h = h or 0

    if type(list) == 'table' then
        list = table.concat(list, '|')
    end

    return rwfx_ListBox(list, title, false, x, y, w, h, true, "", preset)
end


function MsgBox(msg, title, flag, custom_button)
    -- Show a rluawfx message box gui.

    title = title or 'SciTE'

    if flag ~= nil and custom_button ~= nil then
        return rwfx_MsgBox(msg, title, flag, custom_button)
    elseif flag ~= nil then
        return rwfx_MsgBox(msg, title, flag)
    else
        return rwfx_MsgBox(msg, title)
    end
end


function SendCmdScite(command)
    -- Send a command to the SciTE Director.
    -- Does not return anything in source.

    -- Set a property and read it to confirm if safe to send message.
    local identifier = props['WindowID']
    rwfx_ExecuteCmd('property:IdentifySciTEDirector=' .. identifier)

    if props['IdentifySciTEDirector'] ~= identifier then
        local lang = props['Language']

        local msg = '! SendCmdScite() called from Lua, failed to identify\r\n' ..
                    '! the SciTE Director window for the language ' .. lang .. '.\r\n' ..
                    '! More than 1 SciTE Editor window can cause this failure\r\n' ..
                    '! as another SciTE Director window may get priority.\r\n' ..
                    '! If reload properties is needed, a change of tab or\r\n' ..
                    '! similar event can help to provoke a reload.\r\n' ..
                    '! Recommend only 1 SciTE Editor for the language ' .. lang .. '.\r\n'

        if Warning_SendCmdScite then
            Warning_SendCmdScite = false
            print('! This warning will print once only for this instance!')
            print(msg)
        end

        return false
    end

    rwfx_ExecuteCmd(command)
    return true
end


function Sleep(milliseconds)
    -- Sleep for the set amount of time.

    rwfx_Sleep(milliseconds)
end
