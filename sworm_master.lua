-- @file sworm_master.lua
--
-------------------------------------------------------------------------------

-- ============================================================================
-- Variables ------------------------------------------------------------------

local TURTLE_SLOT_FUEL    = 1
local TURTLE_SLOT_UNLOAD  = 2
local TURTLE_SLOT_BUCKET  = 3
local MASTER_CHUNKLOADERS = 4
local MASTER_TURTLES      = 5

-- state and position handlers

local origin = nil
local mineDirection = nil
local state = "serving" -- "serving" "retriving" "placing" "setting"
local chunkCount = 0    -- Number of chunks mined (chunk loader used).
local spotCount  = 0    -- Number of spots mined.
local channels = {}

-- file handler

local file = "state.cc"

-- Modem channels
local modem = nil
local initialChannel = 100

-- ============================================================================
-- PRIVATE functions ----------------------------------------------------------

local function saveState()
  f = fs.open(file , "w")
  f.writeLine(state)
  f.writeLine(origin.x)
  f.writeLine(origin.y)
  f.writeLine(origin.z)
  f.writeLine(mineDirection)
  f.writeLine(tostring(chunkCount))
  f.writeLine(tostring(spotCount))
  f.writeLine(textutils.serialiseJSON(channels))
  f.close()
end

-------------------------------------------------------------------------------

local function loadState()
  local x, y, z
  if not fs.exists(file) then 
    return false
  end
  f = fs.open(file, "r")
  state = f.readLine()
  x = tonumber(f.readLine())
  y = tonumber(f.readLine())
  z = tonumber(f.readLine())
  origin = vector.new(x, y, z)
  mineDirection = f.readLine()
  chunkCount = tonumber(f.readLine())
  spotCount = tonumber(f.readLine())
  channels = textutils.unserialiseJSON(f.readLine())
  f.close()
  return true
end

-------------------------------------------------------------------------------

function spotMapping()
  local spots = {}
  -- =================================== --
  spots[0]  = {front = 2, side = 0, job = 'clear'}

  spots[1]  = {front = 0, side = 15, job = 'excavate'}
  spots[2]  = {front = 0, side = 10, job = 'excavate'}
  spots[3]  = {front = 0, side = 5, job = 'excavate'}
  spots[14] = {front = 0, side = 0, job = 'excavate'}

  spots[5]  = {front = 1, side = 12, job = 'excavate'}
  spots[6]  = {front = 1, side = 7, job = 'excavate'}
  spots[7]  = {front = 1, side = 2, job = 'excavate'}

  spots[8]  = {front = 2, side = 14, job = 'excavate'}
  spots[9]  = {front = 2, side = 9, job = 'excavate'}
  spots[10]  = {front = 2, side = 4, job = 'excavate'}
  spots[11] = {front = 2, side = -1, job = 'excavate'}

  spots[12] = {front = 3, side = 16, job = 'excavate'}
  spots[13] = {front = 3, side = 11, job = 'excavate'}
  spots[14] = {front = 3, side = 6, job = 'excavate'}
  spots[4]  = {front = 3, side = 1, job = 'excavate'}

  spots[16] = {front = 4, side = 13, job = 'excavate'}
  spots[17] = {front = 4, side = 8, job = 'excavate'}
  spots[18] = {front = 4, side = 3, job = 'excavate'}
  -- =================================== --
  spots[19] = {front = 5, side = 15, job = 'excavate'}
  spots[20] = {front = 5, side = 10, job = 'excavate'}
  spots[21] = {front = 5, side = 5, job = 'excavate'}
  spots[22] = {front = 5, side = 0, job = 'excavate'}

  spots[23] = {front = 6, side = 12, job = 'excavate'}
  spots[24] = {front = 6, side = 7, job = 'excavate'}
  spots[25] = {front = 6, side = 2, job = 'excavate'}

  spots[26] = {front = 7, side = 14, job = 'excavate'}
  spots[27] = {front = 7, side = 9, job = 'excavate'}
  spots[28] = {front = 7, side = 4, job = 'excavate'}
  spots[29] = {front = 7, side = -1, job = 'excavate'}

  spots[30]  = {front = 10, side = 0, job = 'clear'}

  spots[31] = {front = 8, side = 16, job = 'excavate'}
  spots[32] = {front = 8, side = 11, job = 'excavate'}
  spots[33] = {front = 8, side = 6, job = 'excavate'}
  spots[34] = {front = 8, side = 1, job = 'excavate'}

  spots[35] = {front = 9, side = 13, job = 'excavate'}
  spots[36] = {front = 9, side = 8, job = 'excavate'}
  spots[37] = {front = 9, side = 3, job = 'excavate'}
  -- =================================== --
  spots[38] = {front = 10, side = 15, job = 'excavate'}
  spots[39] = {front = 10, side = 10, job = 'excavate'}
  spots[40] = {front = 10, side = 5, job = 'excavate'}
  spots[41] = {front = 10, side = 0, job = 'excavate'}

  spots[42] = {front = 11, side = 12, job = 'excavate'}
  spots[43] = {front = 11, side = 7, job = 'excavate'}
  spots[44] = {front = 11, side = 2, job = 'excavate'}

  spots[45] = {front = 12, side = 14, job = 'excavate'}
  spots[46] = {front = 12, side = 9, job = 'excavate'}
  spots[47] = {front = 12, side = 4, job = 'excavate'}
  spots[48] = {front = 12, side = -1, job = 'excavate'}

  spots[49] = {front = 13, side = 16, job = 'excavate'}
  spots[50] = {front = 13, side = 11, job = 'excavate'}
  spots[51] = {front = 13, side = 6, job = 'excavate'}
  spots[52] = {front = 13, side = 1, job = 'excavate'}

  spots[53] = {front = 14, side = 13, job = 'excavate'}
  spots[54] = {front = 14, side = 8, job = 'excavate'}
  spots[55] = {front = 14, side = 3, job = 'excavate'}
  -- =================================== --
  --spots[56] = {front = 15, side = 15}
  --spots[57] = {front = 15, side = 10}
  --spots[58] = {front = 15, side = 5}
  --spots[59] = {front = 15, side = 0}

  return spots
end

-- ============================================================================
-- PUBLIC functions -----------------------------------------------------------

-------------------------------------------------------------------------------

getSpot = function (index)
  local spots = spotMapping()

  if index < 0 or index > #spots then
    return false, false
  end

  return spots[index].front, spots[index].side, spots[index].job
end

-------------------------------------------------------------------------------

getSpotMax = function ()
  local spots = spotMapping()
  return table.getn(spots) + 1
end

-------------------------------------------------------------------------------

getNextSpot = function ()
  local nextChunk = false
  local spotFront, spotSide, x, z, y, pos, facing

  spotFront, spotSide, spotJob = getSpot(spotCount)
  -- print("getNextSpot from map (" .. spotCount .. ") " .. spotFront .. ", " .. spotSide)
  spotCount = spotCount + 1

  -- If all spots on the "chunk" (15 blocks, not 16) got mined, move to the next.
  if spotCount >= getSpotMax() then
    spotCount = 0
    nextChunk = true
  end
  saveState()

  -- Set mining spot based on facing direction and position.
  pos = sworm_api.getPosition()
  facing = sworm_api.getFacing()
  y = pos.y - 2

  if facing == sworm_api.DIRECTION_NORTH then
    x = pos.x + spotSide
    z = pos.z - spotFront
  elseif facing == sworm_api.DIRECTION_SOUTH then
    x = pos.x - spotSide
    z = pos.z + spotFront
  elseif facing == sworm_api.DIRECTION_WEST then
    x = pos.x - spotFront
    z = pos.z - spotSide
  elseif facing == sworm_api.DIRECTION_EAST then
    x = pos.x + spotFront
    z = pos.z + spotSide
  end

  return {x = x, y = y, z = z, job = spotJob, dir = mineDirection}, nextChunk
end

-------------------------------------------------------------------------------

placeChunkLoader = function ()
  turtle.digUp()
  turtle.select(MASTER_CHUNKLOADERS)
  turtle.placeUp()
  turtle.select(MASTER_TURTLES)
end

-------------------------------------------------------------------------------

findChunkLoader = function ()
  local success, inspect, i

  sworm_api.turnTo(mineDirection)
  sworm_api.turnAround()

  for i = 0, 16 do
    success, inspect = turtle.inspectUp()
    sworm_api.forward()
    if inspect ~= nil and inspect.name == "chickenchunks:chunk_loader" then
      return true
    end
  end

  sworm_api.turnAround()

  for i = 0, 16 do
    success, inspect = turtle.inspectUp()
    sworm_api.forward()
    if inspect ~= nil and inspect.name == "chickenchunks:chunk_loader" then
      return true
    end
  end

  return false
end

-------------------------------------------------------------------------------

rescueChunkLoader = function ()
  local success, inspect = turtle.inspectUp()
  local location, itemDetail

  -- Check chunk loaders in inventory.
  turtle.select(MASTER_CHUNKLOADERS)
  itemDetail = turtle.getItemDetail()

  if itemDetail = nil then
  -- If chunkloader not in place, find it.
    if inspect == nil or inspect.name ~= "chickenchunks:chunk_loader" then
      location = sworm_api.getLocation()
      success = findChunkLoader()

      if not success then
        print("Chunk loader not found!")
        exit()
      end

      turtle.select(MASTER_CHUNKLOADERS)
      turtle.digUp()
      turtle.select(MASTER_TURTLES)

      sworm_api.moveTo(location)
      sworm_api.turnTo(mineDirection)
      return
    end
  end

  turtle.select(MASTER_CHUNKLOADERS)
  turtle.digUp()
  turtle.select(MASTER_TURTLES)
end

-------------------------------------------------------------------------------

goToNextChunk = function ()
  local newChunkDirection, newChunkPosition, facing

  state = "moving"
  saveState()
  
  -- Make sure we are at the origin.
  sworm_api.moveTo(origin)
  facing = sworm_api.getFacing()

  -- Get direction vector based on facing direction.
  if facing == sworm_api.DIRECTION_NORTH then
    newChunkDirection = vector.new(0, 0, -15)
  elseif facing == sworm_api.DIRECTION_SOUTH then
    newChunkDirection = vector.new(0, 0, 15)
  elseif facing == sworm_api.DIRECTION_WEST then
    newChunkDirection = vector.new(-15, 0, 0)
  elseif facing == sworm_api.DIRECTION_EAST then
    newChunkDirection = vector.new(15, 0, 0)
  else
    print("Facing direction invalid  " .. facing)
    error()
  end

  newChunkPosition = origin:add(newChunkDirection)
  print("goToNextChunk " .. newChunkPosition:tostring())
  
  print("Placing chunk loader")
  sworm_api.moveTo(newChunkPosition, false)
  placeChunkLoader()

  print("Rescuing chunk loader")
  sworm_api.moveTo(origin, false)
  rescueChunkLoader()

  print("Reposition to start serving")
  sworm_api.moveTo(newChunkPosition, false)
  origin = newChunkPosition
  saveState()

  -- Check inventory.
  sworm_api.quickCheckInventory()

  print("Done chunk move")
end

-------------------------------------------------------------------------------

setupSlaveInventory = function ()
  -- Same order as inventory on slavescode.
  turtle.select(TURTLE_SLOT_FUEL)
  turtle.dropDown(1)
  turtle.select(TURTLE_SLOT_UNLOAD)
  turtle.dropDown(1)
  turtle.select(TURTLE_SLOT_BUCKET)
  turtle.dropDown(1)
end

-------------------------------------------------------------------------------

checkSlotItem = function (slot, item)
  local inspect = turtle.getItemDetail(slot)
  if inspect == nil then
    return false
  end
  return inspect.name == item
end

-------------------------------------------------------------------------------

initChunkloader = function ()
  -- Make sure we can place the chunk loader at the top and place it.
  if turtle.detectUp() then
    if not turtle.digUp() then
      print("Error: Master's top not clear.")
      error()
    end
  end
  turtle.select(MASTER_CHUNKLOADERS)
  turtle.placeUp()
  turtle.select(MASTER_TURTLES)
end

-------------------------------------------------------------------------------

setupSlaves = function ()
  local timeout, spot, nextChunk

  -- Open connection to attached wireless modem and open chanel.
  modem.open(initialChannel)
  -- print("Receive channel " .. initialChannel .. " is open")

  -- Loop through all slave turtle inventories.
  for i = MASTER_TURTLES , 16 do
    turtle.select(i)

    -- Check if there is only on item (turtle) in the slot. If empty, skip.
    if turtle.getItemCount(i) ~= 1 then
      -- Silent fail. Happens very often.
      -- print("Skipping inventory slot " .. i)
      break
    end

    -- Check if selected item is a turtle.
    if not checkSlotItem(i, 'computercraft:turtle') and not checkSlotItem(i, 'computercraft:turtle_advanced') then
      print("No turtle on the turtle slot " .. i)
      break
    end

    -- Check if we have all necessary items.
    if not checkSlotItem(TURTLE_SLOT_FUEL, 'enderstorage:ender_chest') then
      print("No fuel enderchest on slot " .. TURTLE_SLOT_FUEL)
      break
    end
    if not checkSlotItem(TURTLE_SLOT_UNLOAD, 'enderstorage:ender_chest') then
      print("No unload item enderchest on slot " .. TURTLE_SLOT_UNLOAD)
      break
    end
    if not checkSlotItem(TURTLE_SLOT_BUCKET, 'minecraft:bucket') then
      print("No lava for fuel bucket on slot " .. TURTLE_SLOT_BUCKET)
      break
    end

    state = "setting"
    sworm_api.down()
    saveState()

    -- Place the slave turtle at the bottom.
    -- print("Placing Turtle " .. (i - MASTER_TURTLES + 1))
    turtle.digDown()
    turtle.placeDown()
    sleep(0.5)

    -- Check if the turtle is at the bottom.
    if peripheral.isPresent("bottom") then
      -- Turn on slave turtle.
      -- print("---> Turtle")
      peripheral.wrap("bottom").turnOn()
      sleep(2)

      -- Connect to slave and wait response.
      -- print("Waiting for slave response")
      event, side, freq , reply , msg , dist = os.pullEvent("modem_message")

      -- Fail safe.
      timeout = 0
      while msg ~= "ready" do
        event, side, freq , reply , msg , dist = os.pullEvent("modem_message")
  
        timeout = timeout + 1
        if timeout > 10 then
          print("Giving up on the turtle 1.")
          turtle.digDown()
          sworm_api.up()
          modem.close(initialChannel)
          return
        end

        print("No response. Retry in 2 sec (" .. timeout .. "/10).")
        sleep(2)
      end

      -- Setup slave.
      -- print("Response received. Seting him up to mine.")
      setupSlaveInventory()
      channel = reply
      channels[reply] = channel

      -- Sending all set message.
      -- print("Sending 'all set' message CH:" .. channel)
      modem.open(channel)
      modem.transmit(channel, 0, channel)

      event, side, freq , reply , msg , dist = os.pullEvent("modem_message")

      -- Fail safe.
      timeout = 0
      while reply ~= channel do
        os.startTimer(3)
        event, side, freq , reply , msg , dist = os.pullEvent()

        if event ~= "modem_message" then
          timeout = timeout + 1
          if timeout > 10 then
            print("Giving up on the turtle 2.")
            turtle.digDown()
            sworm_api.up()
            modem.close(initialChannel)
            return
          end
        elseif reply == channel then
          print("Got response from slave " .. channel)
          break
        end

        print("No response. Retry in 3 sec (" .. timeout .. "/10).")
        sleep(3)
      end

      -- Send the first mine spot to the slave.
      -- print("Slave requesting spot")
      spot, nextChunk = getNextSpot()
      -- spot.y = spot.y + 1
      modem.transmit(channel, 0, spot)
      print("Slave " .. channel .. " started (" .. spotCount .. ") x=" .. spot.x .. " y=" .. spot.y .. " z=" .. spot.z)

      if nextChunk then
        state = "moving"
        goToNextChunk()
        chunkCount = chunkCount + 1
      end

      -- Make sure we don't close the channels.
      -- modem.close(channel)

      sworm_api.up()
      saveState()
      sleep(5)
    else
      print("Error: Turtle not present at the bottom.")
    end
    print("---------------------------------")
  end

  modem.close(initialChannel)
end

-------------------------------------------------------------------------------

attendRequests = function ()
  local spot, nextChunk
  local event, side, freq , reply , msg , dist

  state = "serving"
  saveState()

  event, side, freq , reply , msg , dist = os.pullEvent("modem_message")

  if msg == "request" then
    local spot, nextChunk = getNextSpot()

    print("Slave " .. reply .. " " .. spot.job .. " (" .. spotCount .. ") x=" .. spot.x .. " y=" .. spot.y .. " z=" .. spot.z)
    modem.transmit(reply, 0, spot)

    if nextChunk then
      state = "moving"
      goToNextChunk()
      chunkCount = chunkCount + 1
    end
  end
end

-------------------------------------------------------------------------------

excavateRows = function ()
  local front, side
  local direction = sworm_api.getFacing()

  -- Positioning to clear job site.
  sworm_api.down()

  sworm_api.left()

  for front = 1, 2 do
    sworm_api.clearForward()
  end
  sworm_api.clearForward(false)

  sworm_api.right()
  sworm_api.clearForward()
  sworm_api.right()

  for front = 1, 19 do
    sworm_api.clearForward()
  end
  sworm_api.clearForward(false)

  sworm_api.right()
  sworm_api.clearForward()
  sworm_api.right()

  for front = 1, 17 do
    sworm_api.clearForward()
  end

  sworm_api.right()
end

-------------------------------------------------------------------------------

openChannels = function ()
  print("Opening channels for comms.")
  for channel, open in pairs(channels) do
    modem.open(channel)
    print("  -- channel " .. channel .. " open")
  end
end

-------------------------------------------------------------------------------
-- Main -----------------------------------------------------------------------

main = function ()
  modem = peripheral.find("modem")

  if not loadState() then
    print("Master started. Ready to command!")

    -- Position to start service.
    sworm_api.init()
    sworm_api.up()
    sworm_api.up()
    sworm_api.gpsCheck()
    origin = sworm_api.getPosition()
    saveState()
    initChunkloader()
    excavateRows()
    sworm_api.moveTo(origin)
  else
    print("State loaded. Resuming command! " .. state)
    sworm_api.init()
    sworm_api.turnTo(mineDirection)

    -- Break any turtle not completly set and restart setting.
    if state == "setting" then
      turtle.digDown()
    -- Back to origin and restart next chunk move.
    elseif state == "moving" then
      sworm_api.moveTo(origin)
      goToNextChunk()
    end

    openChannels()
    sleep(1)
    print("Start working...")
  end

  mineDirection = sworm_api.getFacing()
  saveState()

  while true do
    setupSlaves()
    attendRequests()
    sworm_api.broadcastInfo()
  end

  print("Program ENDED")
end

os.loadAPI("sworm_api")
sleep(5)
main()
