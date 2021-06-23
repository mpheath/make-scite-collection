-- Defined SciTE Lua extension for properties language.


function PrintPropertyValues()
    -- Print properties and values from FilePath.

    local filepath = props['FilePath']

    -- Begin with this max length of properties.
    local maxlen = 10

    -- Get properties.
    local file = io.open(filepath)

    if file ~= nil then
        local list = {}

        for line in file:lines() do

            if line ~= '' and string.find(line, '=') ~= nil then
                local first = string.match(line, '^%s*(.)')

                if first ~= '#' then
                    local property = string.match(line, '^%s*(.-)=')
                    local found = false

                    for _, v in pairs(list) do
                        if v == property then
                            found = true
                        end
                    end

                    if not found then
                        table.insert(list, property)
                    end

                    if string.len(property) > maxlen then
                        maxlen = string.len(property)
                    end
                end
            end
        end

        file:close()

        table.sort(list)

        -- Print properties and values.
        for i = 1, #list do
            local value = props[ list[i] ]

            if value == '' then
                value = '""'
            elseif string.match(value, '^[ \t]*$') then
                value = '"' .. value .. '"'
            end

            print( string.format('%-' .. maxlen .. 's  %s', list[i], value) )
        end
    end
end


function ViewFullPropertyFileAsHta()
    -- View hta file of properties read from a json file.

   local function build_html(module_name, html_content)
       -- Build a full html page.

        return '<!DOCTYPE html>\n' ..
               '<html>\n' ..
               '\n' ..
               '<head>\n' ..
               ' <meta charset="utf-8">\n' ..
               ' <title>View of ' .. module_name .. '.properties</title>\n' ..
               ' <style>\n' ..
               '  body {background: #333333;}\n' ..
               '  h1 {color: darkblue;}\n' ..
               '  span.c {color: #7DE3E3}\n' ..
               '  span.k {color: white}\n' ..
               '  span.v {color: thistle}\n' ..
               '  span.i {color: white; font-weight: bold}\n' ..
               ' </style>\n' ..
               '</head>\n' ..
               '\n<body>\n<pre>' .. html_content .. '</pre>\n</body>\n\n</html>'
    end

    local function escape(text)
        -- Escape some characters with html entities.

       text = string.gsub(text, '&', '&amp;')
       text = string.gsub(text, '<', '&lt;')
       text = string.gsub(text, '>', '&gt;')

       return text
   end

    -- Get module name.
    local module_name = editor:GetSelText()

    if module_name == '' then
        module_name = props['FileName']
    end

    -- Read module content from json.
    local dic
    local json_file = os.path.join(props['SciteDefaultHome'], 'properties', 'modules.json')

    local file = io.open(json_file)

    if file == nil then
        print('Unable to open json file.')
        return
    else
        local text = file:read('a')
        file:close()
        dic = json.decode(text)
    end

    local content = dic['module'][module_name]

    if content == nil then
        print('Unable to get content from the json file. "' ..
              module_name .. '" probably not a standard module name.')
        return
    end

    -- Escape html content.
    content = escape(content)

    -- Track span tag opening and closing.
    local closed_tag = true

    -- Body of html content.
    local html_content = ''

    for _, line in pairs(string.split(content, '\n')) do

        -- No tags for empty lines.
        if line == '' then
            html_content = html_content .. '\n'
            goto end_of_loop

        -- Do not close yet.
        elseif not closed_tag then
            html_content = html_content .. line

        -- Style comment lines.
        elseif string.match(line, '^#') then
            html_content = html_content .. '<span class="c">' .. line

        -- Style if conditionals.
        elseif string.match(line, '^if PLAT_') then
            html_content = html_content .. '<span class="i">' .. line

        -- Separate styles for key=value content.
        else
            if string.find(line, '=') then
                line = string.gsub(line, '^(.-)=(.*)', '<span class="k">%1=</span>' ..
                                                       '<span class="v">%2</span>')
                -- Remove tags with an empty value.
                line = string.gsub(line, '<span class="v"></span>', '')
            end

            html_content = html_content .. '<span class="v">' .. line
        end

        -- No close tag.
        if string.match(line, '\\$') then
            html_content = html_content .. '\n'
            closed_tag = false

        -- Close tag.
        else
            html_content = html_content .. '</span>\n'
            closed_tag = true
        end

        ::end_of_loop::
    end

    -- Finalize html content.
    html_content = build_html(module_name, html_content)

    -- Create hta file and open it.
    local htafile = os.tmpname() .. '.hta'

    if string.sub(htafile, 1, 1) == '\\' then
        htafile = os.getenv('TEMP') .. htafile
    end

    file = io.open(htafile, 'w')

    if file == nil then
        print('Failed to write to temporary file.')
        return
    else
        -- Write and then open the hta file.
        local utf8bom = '\xEF\xBB\xBF'
        file:write(utf8bom .. html_content)
        file:close()

        -- Using ping to allow mshta time to read the file before deleting the file.
        os.execute('start "" mshta.exe "' .. htafile .. '" & ping -n 6 localhost >nul')
        os.remove(htafile)
    end
end
