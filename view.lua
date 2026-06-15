local vars = require 'vars'

local view = {}

--[[
    Выводим сетку в специфичном формате, чтобы удобнее было манипулировать данными

    grid = {
        { -------> }
        { -------> }
        { -------> }
    }
    
    Будет отображен как:
    
      0 1 2
    0 ^ ^ ^
    1 | | |
    2 | | |
]]
view.visualize = function (grid)
    --[[
    for k, v in ipairs(grid) do
        print(k-1 .. '   ' .. table.concat(v, '  '))
    end

    print(string.rep('─', vars.GRID_HEIGHT * 3 + 2))
    --]]

    local result = {'   '}

    for wi = 1, vars.GRID_WIDTH do
        table.insert(result, ' ' .. (wi - 1) .. ' ')
    end

    table.insert(result, '\n  ┌')
    table.insert(result, string.rep('─', vars.GRID_WIDTH * 3 - 1))
    table.insert(result, '\n')

    for wi = vars.GRID_WIDTH, 1, -1  do
        table.insert(result, (vars.GRID_WIDTH - wi) .. ' │')

        for hi = 1, vars.GRID_HEIGHT  do
            local value = grid[hi][wi]
            if value ~= nil then
                table.insert(result, ' ' .. vars.CRISTAL_COLORS[value])
                table.insert(result, value)
                table.insert(result, vars.RESET_COLOR .. ' ')
            else
                table.insert(result, ' - ')
            end
        end
        table.insert(result, '\n')
    end

    table.insert(result, '\n')
    table.insert(result, 'Очков: ' .. vars.score)
    table.insert(result, '\n')
    table.insert(result, string.rep('─', vars.GRID_WIDTH * 3 + 2))

    print(table.concat(result))
end

return view