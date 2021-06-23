-- About: An extension of the os library.

local path = {}

--~ path.sep = string.find(package.config, '/') and '/' or '\\'
path.sep = string.sub(package.config, 1, 1)


function path:exist()
    -- Check if file or dir exist. Use a trailing slash for dir.
    -- Relative paths for a dir path can be unreliable.

    local ok, err, code = os.rename(self, self)

    if not ok then
        if code == 13 then
            -- Permission denied, but it exists.
            return true
        end
    end

    return ok, err
end


function path.join(...)
    -- Joins path segments together. Does not do much checking.

    local args = {...}
    local newpath = ''
    local split_args = {}

    for i = 1, #args do
        for item in string.gmatch(args[i], '[^\\/]*') do
            if item == '..' then
                table.remove(split_args, #split_args)
            elseif item ~= '.' then
                table.insert(split_args, item)
            end
        end
    end

    newpath = table.concat(split_args, path.sep)

    return newpath
end

-- Add to the module table.
os.path = path


return path
