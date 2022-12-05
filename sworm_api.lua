-- @file sworm_api.lua
--
-------------------------------------------------------------------------------

-- ============================================================================
-- Constants ------------------------------------------------------------------

-- Turtle inventory mapping.
TURTLE_SLOT_FUEL      = 1
TURTLE_SLOT_UNLOAD    = 2
TURTLE_SLOT_BUCKET    = 3
TURTLE_SLOT_INVENTORY = 4

-- Public - Available X,Z direction constants.
DIRECTION_NORTH = 'north'
DIRECTION_SOUTH = 'south'
DIRECTION_WEST  = 'west'
DIRECTION_EAST  = 'east'

-- Available Y direction constants.
DIRECTION_UP   = 'up'
DIRECTION_DOWN = 'down'

-- Available severity of logs.
local LOG_NOTICE  = 21
local LOG_WARNING = 22
local LOG_ERROR   = 23
local LOG_DEBUG   = 24

-- ============================================================================
-- Variables ------------------------------------------------------------------

-- Direction the turtle is facing.
local facing = nil

-- The turtle position initially set by GPS.
local position = nil

-- ============================================================================
-- SET/GET --------------------------------------------------------------------

-------------------------------------------------------------------------------
getFacing = function ()
  return facing
end

-------------------------------------------------------------------------------
getPosX = function ()
  return position.x
end

-------------------------------------------------------------------------------
getPosY = function ()
  return position.y
end

-------------------------------------------------------------------------------
getPosZ = function ()
  return position.z
end

-------------------------------------------------------------------------------
getPosition = function ()
  return position
end

-- ============================================================================
-- PRIVATE functions ----------------------------------------------------------

-------------------------------------------------------------------------------
-- @function log()
--
-- Log system with severity.
-- This function makes easier to change how turtles print messages. We change
-- the color based on the severity argument.
--
-- @arg String message
--   Message to be logged.
-- @arg Integer severity
--   One of the log constants that tells the severity of the message.
--
local function log(message, severity)
  local severity = severity or LOG_NOTICE
  local colorOld = term.getTextColor()
  local color

  if severity == LOG_NOTICE then
    color = colors.white
  elseif severity == LOG_WARNING then
    color = colors.yellow
  elseif severity == LOG_ERROR then
    color = colors.red
  elseif severity == LOG_DEBUG then
    color = colors.green
  end

  term.setTextColor(color)
  print(message)
  term.setTextColor(colorOld)
end

-------------------------------------------------------------------------------
-- @function updateLocation()
--
-- After every sideways (x,y) move, we update the location track variables.
local function updateLocation()
  if facing == DIRECTION_NORTH then
    -- z = z - 1
    position:add(vector.new(0, 0, -1))
  elseif facing == DIRECTION_SOUTH then
    -- z = z + 1
    position:add(vector.new(0, 0, 1))
  elseif facing == DIRECTION_EAST then
    -- x = x + 1
    position:add(vector.new(1, 0, 0))
  elseif facing == DIRECTION_WEST then
    -- x = x - 1
    position:add(vector.new(-1, 0, 0))
  else
    log("Invalid facing direction (" .. facing .. ")", LOG_ERROR)
  end
end

-------------------------------------------------------------------------------
-- @function updateHeight()
--
-- After every height change, we update the location track variable.
local function updateHeight(str)
  if str == DIRECTION_DOWN then
    -- y = y - 1
    position:add(vector.new(0, -1, 0))
  elseif str == DIRECTION_UP then
    -- y = y + 1
    position:add(vector.new(0, 1, 0))
  else
    log("Invalid height direction (" .. str .. ")", LOG_ERROR)
  end
end

-- ============================================================================
-- PUBLIC functions -----------------------------------------------------------

-------------------------------------------------------------------------------
-- @function refuel()
--
-- Perform the refuel action using the enderchest. We check if there is space
-- for the chest to be placed and use the last inventory slot to suck the fuel.
--
refuel = function ()
  if turtle.detect() then
    while isTurtle("front") do
      sleep(2)
    end
    if not turtle.dig() then
      log('Bedrock stop - refuel()', LOG_ERROR)
    return
    end
  end
  turtle.select(TURTLE_SLOT_FUEL)
  turtle.place()
  turtle.select(16)
  turtle.suck(64)
  turtle.refuel(64)
  log('Fuel level: ' .. turtle.getFuelLevel(), LOG_NOTICE)
  turtle.select(TURTLE_SLOT_FUEL)
  turtle.dig()
  turtle.select(TURTLE_SLOT_INVENTORY)
end

-------------------------------------------------------------------------------
-- @function checkFuel()
--
-- Check fuel levels.
checkFuel = function ()
  if turtle.getFuelLevel() < 20 then
    log("Fuel is almost over. Refueling!", LOG_NOTICE)
    refuel()
  end
end

-------------------------------------------------------------------------------
-- @function unloadInventory()
--
-- ??
unloadInventory = function ()
  turtle.select(TURTLE_SLOT_UNLOAD)
  while isTurtle("up") do
    sleep(2)
  end
  turtle.digUp()
  turtle.placeUp()
  for i = TURTLE_SLOT_INVENTORY, 16 do
    turtle.select(i)
    turtle.dropUp()
  end
  turtle.select(TURTLE_SLOT_UNLOAD)
  turtle.digUp()
  turtle.select(TURTLE_SLOT_INVENTORY)
end

-------------------------------------------------------------------------------
-- @function checkInventory()
--
-- ??
checkInventory = function ()
  local result = true
  for i = TURTLE_SLOT_INVENTORY, 16 do
    turtle.select(i)
    item = turtle.getItemCount(i)
    if item == 0 then
      result = false
      break
    end
  end
  if result then
    unloadInventory()
  end
  turtle.select(TURTLE_SLOT_INVENTORY)
  return result
end

-------------------------------------------------------------------------------
-- @function quickCheckInventory()
--
-- ??
quickCheckInventory = function ()
  local result = true
  turtle.select(16)
  item = turtle.getItemCount(16)
  if item == 0 then
    result = false
  else
    unloadInventory()
  end
  turtle.select(TURTLE_SLOT_INVENTORY)
  return result
end

-------------------------------------------------------------------------------
-- @function isTurtle()
--
-- Check if block on a specific side is a turtle to prevent destruction.
isTurtle = function (side)
  local success, data

  if side == "up" then
    success, data = turtle.inspectUp()
  elseif side == "down" then
    success, data = turtle.inspectDown()
  else
    success, data = turtle.inspect()
  end

  if success == false then
    return false
  end

  if data.name == "computercraft:turtle" or
      data.name == "computercraft:turtle_advanced" then
    return true
  end

  return false
end

-------------------------------------------------------------------------------
-- MOVING FUNCTIONS -----------------------------------------------------------

-------------------------------------------------------------------------------
-- @function forward()
--
-- Move the turtle forward breaking blocks, attacking entities and refuel if 
-- needed. If there is an unbreakable block the move fails.
--
-- @return Boolean
--   False if reached unbreakable block, true otherwise.
forward = function ()
  local max = 50

  while not turtle.forward() do
    -- Fuel low.
    if turtle.getFuelLevel() < 20 then
      log("Fuel is almost over. Refueling!")
      refuel()
    -- Mob on the way.
    elseif turtle.attack() then
      log("Mob on my way. Die!")
      local isAttacking
      repeat
        sleep(1)
      until not turtle.attack()
    -- Block on the way.
    elseif isTurtle("front") then
      left()
      forward()
      right()
      sleep(math.random(1, 5))
      forward()
      forward()
      right()
      forward()
      left()
    else
      log("Block on the way. Dig!")
      if not turtle.dig() then
        log("Hit bedrock", LOG_ERROR)
        return false
      end
    end

    -- Timeout limit on the loops.
    max = max - 1
    if max <= 0 then
      log("Timeout on forward()", LOG_ERROR)
      return false
    end
  end
  updateLocation()
  return true  
end

-- Alias
f = forward

-------------------------------------------------------------------------------
-- @function nforward()
--
-- Easy and clean way to move more than 1 block forward.
--
-- @arg Integer num
--   Number of blocks to move forward.
-- @return Boolean
--   False if reached unbreakable block, true otherwise.
nforward = function (num, uplevel)
  local i

  if uptravel == nil then
    uptravel = true
  end

  if num < 0 then
    message("Invalid number - nforward(num) =" .. num)
    return false
  elseif num == 0 then
    return true
  end

  -- If moving a lot forward, lets travel one level above.
  if num > 5 and uptravel then
    forward()
    up()

    -- Move
    for i = 2 , num - 1 do
      forward()
    end

    down()
    forward()
  else
    for i = 1 , num do
      forward()
    end
  end
  return true
end  

-------------------------------------------------------------------------------
-- @function down()
--
-- Move the turtle down, digging if block is bellow, attacking if entity,
-- refuel if needed and checking for bedrock.
--
-- @return Boolean
--   False if bedrock is reached, true otherwise.
down = function ()
  local max = 30

  while not turtle.down() do
    -- Fuel low.
    if turtle.getFuelLevel() < 20 then
      log("up() - Fuel is almost over. Refueling!")
      refuel()
    -- Mob on the way.
    elseif turtle.attackDown() then
      log("up() - Mob on my way. Die!")
      local isAttacking
      repeat
        sleep(1)
      until not turtle.attackDown()
    -- Turtle on the way.
    elseif isTurtle("down") then
      forward()
      turnAround()
      sleep(math.random(3, 10))
      forward()
    -- Block on the way.
    elseif turtle.detectDown() then
      log("Block on the way. Dig!")
      if not turtle.digDown() then
        log("Hit bedrock", LOG_ERROR)
        return false
      end
    end

    -- Timeout limit on the loops.
    max = max - 1
    if max <= 0 then
      log("Timeout on forward()", LOG_ERROR)
      return false
    end
  end
  updateHeight(DIRECTION_DOWN)
  return true
end

-------------------------------------------------------------------------------
-- @function up()
--
-- Move the turtle up, digging if any block above, attacking if entity,
-- refuel if needed and checking for bedrock.
--
-- @return Boolean
--   False if bedrock is reached, true otherwise.
up = function ()
  local max = 30

  while not turtle.up() do
    -- Fuel low.
    if turtle.getFuelLevel() < 20 then
      log("up() - Fuel is almost over. Refueling!")
      refuel()
    -- Mob on the way.
    elseif turtle.attackUp() then
      log("up() - Mob on my way. Die!")
      local isAttacking
      repeat
        sleep(1)
      until not turtle.attackUp()
    -- Turtle on the way.
    elseif isTurtle("up") then
      forward()
      turnAround()
      sleep(math.random(3, 10))
      forward()
    -- Block on the way.
    elseif turtle.detectUp() then
      log("Block on the way. Dig!")
      if not turtle.digUp() then
        log("Hit bedrock", LOG_ERROR)
        return false
      end
    end

    -- Timeout limit on the loops.
    max = max - 1
    if max <= 0 then
      log("Timeout on forward()", LOG_ERROR)
      return false
    end
  end
  updateHeight(DIRECTION_UP)
  return true
end

-------------------------------------------------------------------------------
-- @function left()
--
-- Turn turtle to the left.
left = function ()
  --print("turnLeft() facing=", facing," direction")
  turtle.turnLeft()
  if facing == DIRECTION_NORTH then
    facing = DIRECTION_WEST
  elseif facing == DIRECTION_SOUTH then
    facing = DIRECTION_EAST
  elseif facing == DIRECTION_EAST then
    facing = DIRECTION_NORTH
  elseif facing == DIRECTION_WEST then
    facing = DIRECTION_SOUTH
  else 
    log("Invalid facing direction (" .. facing .. ")", LOG_ERROR)
  end
end

-------------------------------------------------------------------------------
-- @function right()
--
-- Turn turtle to the right.
right = function ()
  --print("turnRight() facing=", facing," direction")
  turtle.turnRight()
  if facing == DIRECTION_NORTH then
    facing = DIRECTION_EAST
  elseif facing == DIRECTION_SOUTH then
    facing = DIRECTION_WEST
  elseif facing == DIRECTION_EAST then
    facing = DIRECTION_SOUTH
  elseif facing == DIRECTION_WEST then
    facing = DIRECTION_NORTH
  else 
    log("Invalid facing direction (" .. facing .. ")", LOG_ERROR)
  end
end

-------------------------------------------------------------------------------
-- @function turnAround()
--
-- Turn turtle around.
turnAround = function ()
  left()
  left()
end

-------------------------------------------------------------------------------
-- @function turnTo(dir)
--
-- Turn to the argument direction. This is based on initial conditions. Initial
-- facing direction is always north.
--
-- @arg Integer dir
--   One of the direction constants.
-- @return Boolean
--   Return false if turning or facing directions are invalid and true
--   otherwise.
turnTo = function (dir)
  if dir == DIRECTION_NORTH then
    if facing == DIRECTION_NORTH then
      return true
    elseif facing == DIRECTION_SOUTH then
      right()
      right()
    elseif facing == DIRECTION_EAST then
      left()
    elseif facing == DIRECTION_WEST then
      right()
    else
      getDirection()
      log("Invalid facing direction - turnTo(dir) " .. facing, LOG_ERROR)
    end
  elseif dir == DIRECTION_SOUTH then
    if facing == DIRECTION_SOUTH then
      return true
    elseif facing == DIRECTION_NORTH then
      right()
      right()
    elseif facing == DIRECTION_WEST then
      left()
    elseif facing == DIRECTION_EAST then
      right()
    else
      getDirection()
      log("Invalid facing direction - turnTo(dir) " .. facing, LOG_ERROR)
    end
  elseif dir == DIRECTION_WEST then
    if facing == DIRECTION_WEST then
      return true
    elseif facing == DIRECTION_EAST then
      right()
      right()
    elseif facing == DIRECTION_NORTH then
      left()
    elseif facing == DIRECTION_SOUTH then
      right()
    else
      getDirection()
      log("Invalid facing direction - turnTo(dir) " .. facing, LOG_ERROR)
    end
  elseif dir == DIRECTION_EAST then
    if facing == DIRECTION_EAST then
      return true
    elseif facing == DIRECTION_WEST then
      right()
      right()
    elseif facing == DIRECTION_SOUTH then
      left()
    elseif facing == DIRECTION_NORTH then
      right()
    else
      getDirection()
      log("Invalid facing direction - turnTo(dir) " .. facing, LOG_ERROR)
    end
  else
    log("Invalid goto direction - turnTo(dir) " .. dir, LOG_ERROR)
        return false
  end
  return true
end

-------------------------------------------------------------------------------
-- @function gpsCheck()
--
-- Check turtle position based on GPS information.
gpsCheck = function ()
  local diff
  local gps_pos = getGPS()

  if gps_pos == nil then
    log("Could not get GPS position.", LOG_ERROR)
    return false
  end

  if position:equals(gps_pos) then
    log("Position correct.", LOG_DEBUG)
    return true
  end

  log("Wrong location. Correcting with GPS.", LOG_WARNING)
  position = gps_pos
  return false
end

-------------------------------------------------------------------------------
-- @function getGPS()
--
-- Get GPS coordinates.
getGPS = function ()
  local x, y, z = gps.locate(2)
  local pos = vector.new(x, y, z)

  if pos == nil then
    -- A new GPS request with heigher timeout.
    x, y, z = gps.locate(10)
    pos = vector.new(x, y, z)
    if pos == nil then
      -- GPS not found.
      log("Could not get GPS position.", LOG_ERROR)
      return nil
    end
  end

  log("GPS = " .. pos:tostring(), LOG_DEBUG)
  return pos
end

-------------------------------------------------------------------------------
-- @function getDirection()
--
-- Get turtle facing direction using GPS.
getDirection = function ()
  local pos1, pos2, diff

  -- Make sure we have fuel to move.
  checkFuel()

  pos1 = getGPS()
  while not turtle.forward() do
    turtle.turnLeft()
  end
  pos2 = getGPS()
  turtle.back()

  if pos1 == nil or pos2 == nil then
    log("GPS position not found.", LOG_ERROR)
    return nil
  end

  diff = pos1:sub(pos2)

  if diff.x == 1 then
    return DIRECTION_WEST
  elseif diff.x == -1 then
    return DIRECTION_EAST
  elseif diff.z == 1 then
    return DIRECTION_NORTH
  elseif diff.z == -1 then
    return DIRECTION_SOUTH
  end
  return nil
end

-------------------------------------------------------------------------------
-- @function moveTo(posx, posy)
--
-- Go to specified coordinates.
moveTo = function (destination, uptravel)
  local move_vector, i, pos

  if uptravel == nil then
    uptravel = true
  end

  if destination == nil then 
    log("moveTo() destination not set.", LOG_ERROR)
    return false
  end

  if destination:equals(position) then
    return true
  end

  log("- moveTo pos " .. position:tostring(), LOG_DEBUG)
  log("- moveTo des " .. destination:tostring(), LOG_DEBUG)

  move_vector = destination:sub(position)

  log("- moveTo vec " .. move_vector:tostring(), LOG_DEBUG)

  -- Y axis.
  if move_vector.y > 0 then
    for i = 1, move_vector.y do
      up()
    end
  elseif move_vector.y < 0 then
    for i = 1, math.abs(move_vector.y) do
      down()
    end
  end

  -- Z axis.
  if move_vector.z > 0 then
    turnTo(DIRECTION_SOUTH)
  elseif move_vector.z < 0 then
    turnTo(DIRECTION_NORTH)
  end
  nforward(math.abs(move_vector.z), uptravel)

  -- X axis.
  if move_vector.x > 0 then
    turnTo(DIRECTION_EAST)
  elseif move_vector.x < 0 then
    turnTo(DIRECTION_WEST)
  end
  nforward(math.abs(move_vector.x), uptravel)

  -- If GPS position dont match recorded position, move again.
  while not gpsCheck() do
    log("Position dont match records.", LOG_WARNING)
    sleep(1)
    moveTo(destination)
  end

  -- It's not on the correct destination.
  while not position:equals(destination) do
    log("Position dont match destination.", LOG_WARNING)
    sleep(1)
    moveTo(destination)
  end

  return true
end

-------------------------------------------------------------------------------
-- @function init()
--
-- Initialize turtle.
init = function ()
  -- Set position with GPS.
  log ("Set position", LOG_DEBUG)
  position = getGPS()
  log ("  -- Position " .. position:tostring())

  -- Set facing direction.
  log ("Set facing", LOG_DEBUG)
  facing = getDirection()
  log ("  -- Facing " .. facing, LOG_DEBUG)

  return position ~= nil and facing ~= nil
end
