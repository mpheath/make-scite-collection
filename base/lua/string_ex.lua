-- About: An extension of the string library.

local M = {}


function string:split(delimiter)
    -- Split a string.
    -- Source: https://gist.github.com/jaredallard/ddb152179831dd23b230

    local result = { }
    local from  = 1
    local delim_from, delim_to = string.find( self, delimiter, from  )

    while delim_from do
        table.insert( result, string.sub( self, from , delim_from-1 ) )
        from  = delim_to + 1
        delim_from, delim_to = string.find( self, delimiter, from  )
    end

    table.insert( result, string.sub( self, from  ) )
    return result
end


function string:textwrap(text, limit, indent, indentFirst)
    -- Wrap text. Default limit is 72.
    -- text (required string) - The string of text which you want to line-wrap.
    -- limit (optional integer) - The maximum character interval at which to wrap the lines.
    -- indent (optional string) - Indention string for each line.
    -- indentFirst (optional string) - Indention string for the first line only.
    -- Source: https://docs.coronalabs.com/tutorial/data/luaStringMagic/index.html

    limit = limit or 72
    indent = indent or ""
    indentFirst = indentFirst or indent

    local here = 1 - #indentFirst
    return indentFirst .. text:gsub( "(%s+)()(%S+)()",
        function( sp, st, word, fi )
            if fi - here > limit then
                here = st - #indent
                return "\n" .. indent .. word
            end
        end
    )
end


function string:titlecase()
    -- Format text as title case.
    -- Source: https://docs.coronalabs.com/tutorial/data/luaStringMagic/index.html

    local result = string.gsub(self, "(%a)([%w_']*)",
        function(first, rest)
            return first:upper() .. rest:lower()
        end
    )

    return result
end


-- Add to the module table.
M['split'] = string.split
M['textwrap'] = string.textwrap
M['titlecase'] = string.titlecase


return M
