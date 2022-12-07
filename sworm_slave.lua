-- @file sworm_slave.lua
--
-------------------------------------------------------------------------------

-- ============================================================================
-- Variables ------------------------------------------------------------------

-- Blocks to ignore.
local INVENTORY_IGNORE_MAP = {
  "minecraft:stone",
  "minecraft:cobblestone",
  "minecraft:deepslate",
  "minecraft:cobbled_deepslate",
  "minecraft:tuff",
  "minecraft:netherrack",
  "minecraft:soul_sand",
  "minecraft:grass_block",
  "minecraft:dirt",
  "minecraft:gravel",
  "minecraft:grass",
  "minecraft:snow",
}

-- state and position handlers
local state  = "setting"   -- "mining" "moving" "waiting" "setting"\
local spot

-- file handler
local file = "state.cc"

-- wireless channels
local modem = nil
local initialChannel = 100
local myChannel = nil

-- ============================================================================
-- PRIVATE functions ----------------------------------------------------------

local function message(str)
  print(str)
  --modem.transmit( initialChannel , myChannel , "- "..str )
end

-------------------------------------------------------------------------------

local function saveState()
  f = fs.open(file, "w")
  f.writeLine(state)
  f.close()
end

-------------------------------------------------------------------------------

local function loadState()
  if not fs.exists(file) then 
    return false
  end
  f = fs.open( file , "r" )
  state = f.readLine()
  f.close()
  return true
end

-------------------------------------------------------------------------------

function rawread()
  print("Press enter to continue")
    while true do
        local sEvent, param = os.pullEvent("key")
        if sEvent == "key" then
            if param == 28 then
                print("Enter detected")
                break
            end
        end
    end
end

-- ============================================================================
-- PUBLIC functions -----------------------------------------------------------

-------------------------------------------------------------------------------

setting = function ()
  local event, side, freq , reply , msg , dist

  state = "setting"
  message("call setting()")

  modem.open(initialChannel)

  modem.transmit(initialChannel, myChannel, "ready")

  modem.open(myChannel)
  event, side, freq , reply , msg , dist = os.pullEvent("modem_message")
  message("Event " .. event .. " on " .. myChannel)

  while tostring(msg) ~= tostring(myChannel) do
    message("Waiting for 'set' message on channel " .. myChannel)
    event, side, freq , reply , msg , dist = os.pullEvent("modem_message")
  end

  message("Channel/ID set to " .. myChannel)

  if turtle.getFuelLevel() < 10 then
    sworm_api.refuel()
  end

  modem.close(initialChannel)
  modem.close(myChannel)
end

-------------------------------------------------------------------------------

getNextSpot = function ()
  local x, y, z
  local count = 0
  local event, side, freq , reply , spot , dist

  message("call getNextSpot()")
  modem.open(myChannel)
  sleep(0.1)

  while true do
    message("Sending Request CH:" .. myChannel)
    modem.transmit(myChannel, myChannel, "request")
    event, side, freq , reply , spot , dist = os.pullEvent("modem_message")

    if event == "modem_message" then
      x, y, z = msg
      message("Request attended x=" .. spot.x .. " y=" .. spot.y .. " z=" .. spot.z)
      break
    elseif event == "timer" then
      count = count + 1
      message("Timeout getNextSpot() " .. count)
      if count > 10 then
        sleep(10)
      end
    end
  end
  modem.close(myChannel)
  return spot
end

-------------------------------------------------------------------------------

excavate = function ()
  local depth = 0
  local success, data

  state = "mining"

  -- Excavate tower.
  while sworm_api.down() do
    for i = 1 , 4 do
      local ignore = checkIgnore()

      if not ignore then
        turtle.dig()
        sworm_api.checkInventory()  
      end

      if i ~= 4 then 
        sworm_api.right() 
      end
    end

    -- Check for lava on bottom coordinates.
    success, data = turtle.inspectDown()
    if data.name == 'minecraft:lava' then
      turtle.select(sworm_api.TURTLE_SLOT_BUCKET)
      turtle.place()
      turtle.refuel()
      message("Lava found and used for fuel.")
      turtle.select(sworm_api.TURTLE_SLOT_INVENTORY)
    elseif data.name == 'minecraft:chest' then
      sworm_api.unloadInventory()
    end

    turtle.digDown()
    sworm_api.quickCheckInventory()

    depth = depth + 1
  end

  -- Back to origin height.
  while depth > 0 do
    sworm_api.up()
    depth = depth - 1
  end

  -- Make sure we're back on the original position.
  sworm_api.moveTo(spot)
end

-------------------------------------------------------------------------------

checkIgnore = function ()
  local index, ignored_block
  local success, data = turtle.inspect()
  
  if not success then
    -- message("turtle.inspect() failed. Probably air.")
    return true
  end
  
  if data.name == 'minecraft:lava' then
    turtle.select(sworm_api.TURTLE_SLOT_BUCKET)
    turtle.place()
    turtle.refuel()
    message("Lava found and used for fuel.")
    turtle.select(sworm_api.TURTLE_SLOT_INVENTORY)
    return true
  elseif data.name == 'minecraft:chest' then
    sworm_api.unloadInventory()
    return false
  end

  for index, ignored_block in pairs(INVENTORY_IGNORE_MAP) do
    if data.name == ignored_block then
      return true
    end
  end

  -- Do not ignore if past all checks.
  return false
end

-------------------------------------------------------------------------------
-- Main -----------------------------------------------------------------------

main = function ()
  local init = false

  modem = peripheral.find("modem")
  myChannel = os.getComputerID()

  if init == false and state ~= "setting" then
    sworm_api.init()
    init = true
  end

  if loadState() then
    message("State loaded. Resuming task.")
    sleep(10)
  else
    message("Slave started. Ready to mine!")
    state = "setting"
  end

  while true do

    if state == "setting" then
      message("--> Setting")
      setting()
      if init == false then
        sworm_api.init()
        init = true
      end
      state = "waiting"
      saveState()

    elseif state == "waiting" then
      message("--> Waiting")
      spot = getNextSpot()
      state = "moving"
      saveState()

    elseif state == "moving" then
      message("--> Moving")
      if init == false then
        sworm_api.init()
        init = true
        state = "waiting"
        spot = getNextSpot()
      end
      spot = vector.new(spot.x, spot.y, spot.z)
      sworm_api.moveTo(spot)
      state = "mining"
      saveState()

    elseif state == "mining" then
      -- rawread()
      message("--> Mining")
      if init == false then
        sworm_api.init()
        init = true
      end
      sworm_api.checkInventory()
      excavate()
      state = "waiting"
      saveState()

    else
      message("Invalid state - main() " .. state)
    end

  end
end

os.loadAPI("sworm_api")
sleep(5)
main()
