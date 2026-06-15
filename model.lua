local vars = require 'vars'
local view = require 'view'

local grid = {}
grid.__index = grid

function grid:new(newGrid)
    return setmetatable(newGrid or {}, self)
end

function grid:copy()
    local copyGrid = grid:new()
    copyGrid:replace(self)
    return copyGrid
end

function grid:replace(newGrid)
    for wi, hi in self:each() do
        if self[wi] == nil then self[wi] = {} end
        self[wi][hi] = newGrid[wi][hi]
    end
end

function grid:init()
    self:fillEmptyCells(true)
end

function grid:tick()
    return function()
        local score = self:findCombos()

        if score > 0 then
            vars.score = vars.score + score
            self:fillEmptyCells()
            return score
        end

        if self:isMixNeeded() then
            print('Нет доступных вариантов. Перемешиваем поле')
            self:mix()
            return 0
        end

        self:dump()
        return nil
    end
end

function grid:move(from, to)
    self[from[1]][from[2]], self[to[1]][to[2]] = self[to[1]][to[2]], self[from[1]][from[2]]

    if not self:hasCombo(from[1], from[2]) and not self:hasCombo(to[1], to[2]) then
        print('Совпадения не найдены')
        self[from[1]][from[2]], self[to[1]][to[2]] = self[to[1]][to[2]], self[from[1]][from[2]]
        return
    end

    for score in self:tick() do end
end

function grid:mix()
    local flatlist = {}
    local newGrid = grid:new()

    for _, _, value in self:each() do
        table.insert(flatlist, value)
    end

    for wi, hi in newGrid:each() do
        if newGrid[wi] == nil then newGrid[wi] = {} end

        local availableCristals = self:getCristalsWithoutCombos(wi, hi)
        local tick = 10

        while tick > 0 do
            local currentCristal = table.remove(flatlist, math.random(1, #flatlist))

            for _, availableCristal in ipairs(availableCristals) do
                if currentCristal == availableCristal then
                    newGrid[wi][hi] = currentCristal
                    break
                end
            end

            if newGrid[wi][hi] == nil then
                tick = tick - 1
                table.insert(flatlist, currentCristal)
            else
                break
            end
        end

        if tick <= 0 then
            newGrid[wi][hi] = availableCristals[math.random(1, #availableCristals)]
        end
    end

    self:replace(newGrid)
end

function grid:dump()
    view.visualize(self)
end

--[[
    Заполняет все пустые ячейки случайными кристаллами.
    Если withoutCombo = true, будет проверять каждый кристалл на
    исключение возможности потенциального вызова комбинации
]]
function grid:fillEmptyCells(withoutCombo)
    for wi, hi, value in self:each() do
        if self[wi] == nil then self[wi] = {} end
        if value == nil then
            local availableCristals

            if withoutCombo then
                availableCristals = self:getCristalsWithoutCombos(wi, hi)
            else
                availableCristals = vars.CRISTALS
            end

            self[wi][hi] = availableCristals[math.random(1, #availableCristals)]
        end
    end
end

--[[
    Выдает список цветов для указанных координат, исключая кристаллы,
    которые потенциально вызовут комбинацию
]]
function grid:getCristalsWithoutCombos(wi, hi)
    local combinations = { {-1, -2}, {-1, 1}, {1, 2} }
    local set = {}

    for _, coord in ipairs(combinations) do
        if self[wi] ~= nil
            and self[wi][hi + coord[1]] ~= nil
            and self[wi][hi + coord[1]] == self[wi][hi + coord[2]]
        then
            set[self[wi][hi + coord[1]]] = true
        end

        if self[wi + coord[1]] ~= nil
            and self[wi + coord[2]] ~= nil
            and self[wi + coord[1]][hi] ~= nil
            and self[wi + coord[1]][hi] == self[wi + coord[2]][hi]
        then
            set[self[wi + coord[1]][hi]] = true
        end
    end

    local result = {}

    for _, color in ipairs(vars.CRISTALS) do
        if set[color] ~= true then
            table.insert(result, color)
        end
    end

    return result
end

--[[
    Проверяет, есть ли на поле потенциальные успешные ходы
]]
function grid:isMixNeeded()
    local copyGrid = self:copy()

    for wi, hi in copyGrid:each() do
        local from = {wi, hi}
        local tos = { {wi, hi+1}, {wi+1, hi} }

        for _, to in ipairs(tos) do
            if copyGrid[to[1]] ~= nil and copyGrid[to[1]][to[2]] ~= nil
                and copyGrid[from[1]][from[2]] ~= copyGrid[to[1]][to[2]]
            then
                copyGrid[from[1]][from[2]], copyGrid[to[1]][to[2]] = copyGrid[to[1]][to[2]], copyGrid[from[1]][from[2]]
                if copyGrid:hasCombo(from[1], from[2]) or copyGrid:hasCombo(to[1], to[2]) then return false end
                copyGrid[to[1]][to[2]], copyGrid[from[1]][from[2]] = copyGrid[from[1]][from[2]], copyGrid[to[1]][to[2]]
            end
        end
    end

    return true
end

--[[
    Ищет и удаляет комбинации. Возвращает количество очков
]]
function grid:findCombos()
    local score = 0
    local combos = {}

    local function fillCombos(combo)
        if #combo >= 3 then
            for _, c in ipairs(combo) do
                local key = c[1] .. ':' .. c[2]
                combos[key] = c
            end
        end
    end

    for hi = 1, vars.GRID_HEIGHT do
        local currentCristal
        local combo = {}

        for wi = 1, vars.GRID_WIDTH do
            if self[wi][hi] == nil then
                currentCristal = nil
                combo = {}
            elseif self[wi][hi] == currentCristal then
                table.insert(combo, {wi, hi})
            else
                currentCristal = self[wi][hi]
                fillCombos(combo)
                combo = {{wi, hi}}
            end
        end

        fillCombos(combo)
    end

    for wi = 1, vars.GRID_WIDTH do
        local currentCristal
        local combo = {}

        for hi = 1, vars.GRID_HEIGHT do
            if self[wi][hi] == nil then
                currentCristal = nil
                combo = {}
            elseif self[wi][hi] == currentCristal then
                table.insert(combo, {wi, hi})
            else
                currentCristal = self[wi][hi]
                fillCombos(combo)
                combo = {{wi, hi}}
            end
        end

        fillCombos(combo)
    end

    for _, combo in pairs(combos) do
        self[combo[1]][combo[2]] = true
    end

    for wi = 1, vars.GRID_WIDTH do
        for hi = vars.GRID_HEIGHT, 1, -1 do
            if self[wi][hi] == true then
                score = score + 1
                table.remove(self[wi], hi)
            end
        end
    end

    return score
end

--[[
    Проверяет, есть ли успешная комбинация по указанным координатам
]]
function grid:hasCombo(y, x)
    if self[y] == nil or self[y][x] == nil then
        return false
    end

    local currentCristal = self[y][x]
    local combinations = { {-1, -2}, {-1, 1}, {1, 2} }

    for _, coord in ipairs(combinations) do
        if
            self[y][x+coord[1]] == currentCristal
            and self[y][x+coord[2]] == currentCristal
        then
            return true
        end

        if
            self[y+coord[1]] ~= nil and self[y+coord[2]] ~= nil
            and self[y+coord[1]][x] == currentCristal
            and self[y+coord[2]][x] == currentCristal
        then
            return true
        end
    end

    return false
end

--[[
    Функция для удобного перебора таблицы. Возвращает y, x, value
]]
function grid:each()
    local wi = 1
    local hi = 0
    return function()
        hi = hi + 1

        if hi > vars.GRID_HEIGHT then
            wi = wi + 1
            hi = 1
        end

        if wi > vars.GRID_WIDTH then
            return nil
        end

        if self[wi] == nil then
            return wi, hi, nil
        end

        return wi, hi, self[wi][hi]
    end
end

return grid