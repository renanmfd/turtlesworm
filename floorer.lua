-- @file floorer.lua
--
-------------------------------------------------------------------------------

-- wget https://raw.githubusercontent.com/renanmfd/turtlesworm/master/floorer.lua floorer

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
    for i = 2, 16 do
        turtle.select(i)
        inspect = turtle.getItemDetail(i)
        if inspect.name == "minecraft:dirt" then
            return i
        end
    end
    return false
end

local placeFloor = function (size)
    local count = 0
    local blockSlot

    while count < size do
        blockSlot = selectBlock()

        repeat
            print("Waiting for more dirt.")
            os.pullEvent("turtle_inventory")
            blockSlot = selectBlock()
        until blockSlot == false

        turtle.placeDown()
        sworm_api.forward()
        count = count + 1
    end
end

local main = function ()
    local size, maxdepth = checkInputs()
    local depth = 0

    sworm_api.init()

    print("Facing: " .. facing)

    sworm_api.up()

    while depth < maxdepth do
        if math.fmod(depth, 2) == 0 then
            sworm_api.right()
        else
            sworm_api.left()
        end

        placeFloor(size)

        if math.fmod(depth, 2) == 0 then
            sworm_api.left()
        else
            sworm_api.right()
        end

        depth = depth + 1
    end
end

print("BIG TUNNEL by renanmfd")
if not fs.exists("sworm_api") then
    print("  -- Installing sworm_api")
    shell.run("rom/programs/http/wget https://raw.githubusercontent.com/renanmfd/turtlesworm/master/sworm_api.lua sworm_api")
end

os.loadAPI("sworm_api")
sleep(2)
main()

-- wget https://raw.githubusercontent.com/renanmfd/turtlesworm/master/bigtunnel.lua bigtunnel
