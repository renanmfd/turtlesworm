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
local state = "serving" -- "serving" "retriving" "placing" "setting"
local chunkCount = 0    -- Number of chunks mined (chunk loader used).
local chunkThird = 0    -- How many 1/3 of chunk mined.
local spotCount  = 0    -- Number of spots mined.

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
  f.writeLine(tostring(chunkCount))
  f.writeLine(tostring(chunkThird))
  f.writeLine(tostring(spotCount))
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
  chunkCount = tonumber(f.readLine())
  chunkThird = tonumber(f.readLine())
  spotCount = tonumber(f.readLine())
  f.close()
  return true
end

-------------------------------------------------------------------------------

function spotMapping()
  local spots = {}

  spots[0] = {front = 0, side = 15}
  spots[1] = {front = 1, side = 12}
  spots[2] = {front = 0, side = 10}
  spots[3] = {front = 1, side = 7}
  spots[4] = {front = 0, side = 5}
  spots[5] = {front = 1, side = 2}
  spots[6] = {front = 0, side = 0}
  spots[7] = {front = 2, side = -1}
  spots[8] = {front = 3, side = 1}
  spots[9] = {front = 4, side = 3}
  spots[10] = {front = 2, side = 4}
  spots[11] = {front = 3, side = 6}
  spots[12] = {front = 4, side = 8}
  spots[13] = {front = 2, side = 9}
  spots[14] = {front = 3, side = 11}
  spots[15] = {front = 4, side = 13}
  spots[16] = {front = 2, side = 14}
  spots[17] = {front = 3, side = 16}

  return spots
end

-- ============================================================================
-- PUBLIC functions -----------------------------------------------------------

-------------------------------------------------------------------------------

getSpot = function (index)
  local spots = spotMapping()

  if index < 0 or index > #spots then
    return false
  end

  return spots[index].front, spots[index].side
end

-------------------------------------------------------------------------------

getSpotMax = function ()
  local spots = spotMapping()
  return #spots
end

-------------------------------------------------------------------------------

getNextSpot = function ()
  local nextChunk = false
  local spotFront, spotSide, x, z, y, pos, facing

  spotFront, spotSide = getSpot(spotCount)
  print("getNextSpot from map " .. spotFront .. " - " .. spotSide)
  spotCount = spotCount + 1

  -- If all spots on the 1/3 of chunk got mined, move to the next 1/3.
  if spotCount >= getSpotMax() then
    spotCount = 0
    chunkThird = chunkThird + 1
  end
  -- If the 3 1/3 of the chunk got mined, move to next chunk.
  if chunkThird >= 3 and spotCount >= 4 then
    chunkThird = 0
    nextChunk = true
  end

  -- Set mining spot based on facing direction and position.
  pos = sworm_api.getPosition()
  facing = sworm_api.getFacing()
  y = pos.y - 1

  if facing == sworm_api.DIRECTION_NORTH then
    x = pos.x + spotSide
    z = pos.z - (spotFront * chunkThird) - (chunkCount * 16)
  elseif facing == sworm_api.DIRECTION_SOUTH then
    x = pos.x - spotSide
    z = pos.z + (spotFront * chunkThird) + (chunkCount * 16)
  elseif facing == sworm_api.DIRECTION_WEST then
    x = pos.x - (spotFront * chunkThird) - (chunkCount * 16)
    z = pos.z - spotSide
  elseif facing == sworm_api.DIRECTION_EAST then
    x = pos.x + (spotFront * chunkThird) + (chunkCount * 16)
    z = pos.z + spotSide
  end

  print("getNextSpot " .. x .. " " .. y .. " " .. z)
  return {x = x, y = y, z = z}, nextChunk
end

-------------------------------------------------------------------------------

placeChunkLoader = function ()
  turtle.digUp()
  turtle.select(MASTER_CHUNKLOADERS)
  turtle.placeUp()
  turtle.select(MASTER_TURTLES)
end

-------------------------------------------------------------------------------

rescueChunkLoader = function ()
  turtle.select(MASTER_CHUNKLOADERS)
  turtle.digUp()
  turtle.select(MASTER_TURTLES)
end

-------------------------------------------------------------------------------

goToNextChunk = function ()
  local newChunkDirection, newChunkPosition

  -- Make sure we are at the origin of the chunk.
  sworm_api.moveTo(origin)

  -- Get direction vector based on facing direction.
  if facing == sworm_api.DIRECTION_NORTH then
    newChunkDirection = vector.new(0, 0, -16)
  elseif facing == sworm_api.DIRECTION_SOUTH then
    newChunkDirection = vector.new(0, 0, 16)
  elseif facing == sworm_api.DIRECTION_WEST then
    newChunkDirection = vector.new(-16, 0, 0)
  elseif facing == sworm_api.DIRECTION_EAST then
    newChunkDirection = vector.new(16, 0, 0)
  end

  newChunkPosition = origin.add(newChunkDirection)
  
  print("Placing chunk loader")
  sworm_api.moveTo(newChunkPosition)
  placeChunkLoader()

  print("Rescuing chunk loader")
  sworm_api.moveTo(origin)
  rescueChunkLoader()

  print("Reposition to start serving")
  sworm_api.moveTo(newChunkPosition)
  origin = newChunkPosition

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

initChunkloader = function ()
  -- Make sure we can place the chunk loader at the top and place it.
  if turtle.detectUp() then
    if not turtle.digUp() then
      print("Error: Master's top not clear.")
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
      -- print("Skipping inventory slot " .. i)
      break
    end
    state = "setting"

    -- Place the slave turtle at the bottom.
    -- print("Placing Turtle " .. (i - MASTER_TURTLES + 1))
    turtle.placeDown()
    sleep(0.5)

    -- Check if the turtle is at the bottom.
    if peripheral.isPresent("bottom") then
      -- Turn on slave turtle.
      -- print("---> Turtle")
      peripheral.wrap("bottom").turnOn()

      -- Connect to slave and wait response.
      -- print("Waiting for slave response")
      timeout = 0
      event, side, freq , reply , msg , dist = os.pullEvent("modem_message")
      while msg ~= "ready" do
        event, side, freq , reply , msg , dist = os.pullEvent("modem_message")
        timeout = timeout + 1
        if timeout > 20 then
            turtle.digDown()
          return
        end
        print("No response. Retry in 1 sec.")
        sleep(1)
      end

      -- Setup slave.
      -- print("Response received. Seting him up to mine.")
      setupSlaveInventory()
      channel = reply

      -- Sending all set message.
      -- print("Sending 'all set' message CH:" .. channel)
      modem.transmit(channel, 0, channel)

      modem.open(channel)
      timeout = 0
      event, side, freq , reply , msg , dist = os.pullEvent("modem_message")
      while reply ~= channel do
        event, side, freq , reply , msg , dist = os.pullEvent("modem_message")
        timeout = timeout + 1
        if timeout > 20 then
            turtle.digDown()
          return
        end
        print("No response. Retry in 2 sec.")
        sleep(2)
      end

      -- Send the first mine spot to the slave.
      -- print("Slave requesting spot")
      spot, nextChunk = getNextSpot()
      modem.transmit(channel, 0, spot)
      print("Slave " .. channel .. " started (" .. spotCount .. ") x=" .. spot.x .. " y=" .. spot.y .. " z=" .. spot.z)
      
      -- Make sure we don't close the channels.
      -- modem.close(channel)

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
  local event, side, freq , reply , msg , dist = os.pullEvent("modem_message")
  state = "serving"

  if msg == "request" then
    local spot, nextChunk = getNextSpot()
    print("Slave " .. reply .. ", job on x=" .. spot.x .. " y=" .. spot.y .. " z=" .. spot.z)
    modem.transmit(reply, 0, spot)

    if nextChunk then
      state = "moving"
      goToNextChunk()
      chunkCount = chunkCount + 1
    end
  end
end

-------------------------------------------------------------------------------
-- Main -----------------------------------------------------------------------

main = function ()
  sworm_api.init()
  sworm_api.up()

  origin = sworm_api.getPosition()
  modem = peripheral.find("modem")

  if turtle.getFuelLevel() < 10 then
    sworm_api.refuel()
  end

  if not loadState() then
    print("Master started. Ready to command!")
    initChunkloader()
  else
    print("State loaded. Resuming command!")
    sleep(5)

    -- Break any turtle not completly set and restart setting.
    if state == "setting" then
      turtle.digDown()
    -- Back to origin and restart next chunk move.
    elseif state == "moving" then
      sworm_api.moveTo(origin)
      goToNextChunk()
    end
  end

  while true do
    setupSlaves()
    state = "serving"
    attendRequests()
  end
end

os.loadAPI("sworm_api")
main()
