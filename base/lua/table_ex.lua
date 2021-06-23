-- About: An extension of the table library.

local M = {}


function table:unique()
    -- Indexed table with duplicates removed and sorted in-place to be unique.
    -- Source: Michael Heath.

    -- Values as keys to make unique.
    local x = {}

    for k, v in pairs(self) do
        x[v] = k
    end

    -- Delete keys in passed table.
    for k in pairs(self) do
        self[k] = nil
    end

    -- Keys to values.
    for k in pairs(x) do
        table.insert(self, k)
    end

    -- Sort by keys.
    table.sort(self)
end


-- Add to the module table.
M['unique'] = table.unique


return M
