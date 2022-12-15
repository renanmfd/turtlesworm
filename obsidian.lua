-- @file floorer.lua
--
-------------------------------------------------------------------------------

-- wget https://raw.githubusercontent.com/renanmfd/turtlesworm/master/obsidian.lua obsidian

local args = {...}
local size
local count = 0

if args[1] == nil then
    size = 1
elseif args[1] < 1 then
    exit()
else
    size = args[1]
end

while true do
    turtle.dig()
    turtle.forward()
    turtle.left()
    turtle.dig()
    turtle.right()
    turtle.right()
    turtle.dig()
    turtle.left()
    
    count = count + 1
    if count >= size then
        break
    end
end

turtle.left()
turtle.left()
turtle.digDown()
turtle.down()
