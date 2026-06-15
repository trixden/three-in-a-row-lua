local model = require 'model'
local vars = require 'vars'
local command = {}

function command:new()
    self.grid = model:new()
    return self
end

function command:start()
    self.grid:init()
    self.grid:dump()
    self:listen()
end

function command:listen()
    while true do
        print('Введите вашу команду:')
        self:parse(io.read())
    end
end

function command:parse(input)
    if input == 'c' or input == 'q' then
        self:quit()
        return
    end

    local x, y, d = input:match('m%s+(%d+)%s+(%d+)%s+([lrud])')

    if x ~= nil then
        command:move(tonumber(x), tonumber(y), d)
        return
    end

    print('Команда не распознана')
end

function command:move(x, y, d)
    local from = {x + 1, vars.GRID_HEIGHT - y}
    local to = {}

    if d == 'l' then
        to = {from[1] - 1, from[2]}
    elseif d == 'r' then
        to = {from[1] + 1, from[2]}
    elseif d == 'u' then
        to = {from[1], from[2] + 1}
    elseif d == 'd' then
        to = {from[1], from[2] - 1}
    end

    if from[1] < 1 or from[2] < 1 or to[1] < 1 or to[2] < 1
        or from[1] > vars.GRID_WIDTH or from[2] > vars.GRID_HEIGHT
        or to[1] > vars.GRID_WIDTH or to[2] > vars.GRID_HEIGHT then
            print('Выход за пределы поля')
            return
        end

    self.grid:move(from, to)
end

function command:quit()
    print('Игра окончена')
    os.exit()
end

return command