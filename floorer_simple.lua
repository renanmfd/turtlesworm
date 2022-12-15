-- @file floorer.lua
--
-------------------------------------------------------------------------------

-- wget https://raw.githubusercontent.com/renanmfd/turtlesworm/master/floorer_simple.lua floorer_simple

local args = {...}

local usage = function ()
    print("floorer <size> <depth>")
    print("  <size>   Integer heigher than 1.")
    print("  <depth>  Integer heigher than 1.")
end

local checkInputs = function ()
    local size, depth

    if args == nil or args[1] == nil or args[2] == nil then
        usage()
        print("Invalid or missing argument.")
        error()
    end

    size = tonumber(args[1])
    depth = tonumber(args[2])

    print("Size: " .. size .. " Dept: " .. depth)

    if size < 1 then
        usage()
        print("Size argument cannot be lower than 1.")
        error()
    end

    if depth < 1 then
        usage()
        print("Dept argument cannot be lower than 1.")
        error()
    end

    return size, depth
end

local selectBlock = function (size)
    local inspect
    for i = 1, 16 do
        turtle.select(i)
        inspect = turtle.getItemDetail(i)
        if inspect ~= nil then
            if inspect.name == "minecraft:dirt" or inspect.name == "minecraft:cobblestone" then
                return i
            else
                print(textutils.serialise(inspect))
            end
        end
    end
    return false
end

local placeSpot = function ()
    local blockSlot = selectBlock()

    if blockSlot == false then
        repeat
            print("Waiting for more dirt.")
            os.pullEvent("turtle_inventory")
            blockSlot = selectBlock()
        until blockSlot == false
    end

    turtle.select(blockSlot)
    turtle.placeDown()
    turtle.forward()
end

local placeRow = function (size)
    local count = 0

    while count < size - 1 do
        placeSpot()
        count = count + 1
    end
end

local main = function ()
    local size, maxdepth = checkInputs()
    local depth = 0

    while depth < maxdepth do
        if math.fmod(depth, 2) == 0 then
            turtle.turnRight()
        else
            turtle.turnLeft()
        end

        placeRow(size)

        if math.fmod(depth, 2) == 0 then
            turtle.turnLeft()
        else
            turtle.turnRight()
        end

        placeSpot()

        depth = depth + 1
    end
end

print("FLOORER by renanmfd")

main()

-- wget https://raw.githubusercontent.com/renanmfd/turtlesworm/master/floorer_simple.lua floorer_simple
