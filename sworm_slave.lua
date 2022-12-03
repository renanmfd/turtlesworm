-- @file sworm_slave.lua
--
-------------------------------------------------------------------------------

-- ============================================================================
-- Variables ------------------------------------------------------------------

-- Blocks to ignore.
local INVENTORY_IGNORE_MAP = {
	"minecraft:stone",
	"minecraft:cobblestone",
	"minecraft:grass_block",
	"minecraft:dirt",
	"minecraft:grass",
	"minecraft:snow",
}

-- state and position handlers
local state  = "setting"   -- "mining" "moving" "waiting" "setting"

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
	state = "setting"
	message("call setting()")

	modem.open(initialChannel)
	sleep(0.1)

	modem.transmit(initialChannel, myChannel, "ready")

	modem.open(myChannel)
	local event, side, freq , reply , msg , dist = os.pullEvent("modem_message")
	message(msg .. " - " .. myChannel)

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
		os.startTimer(20)
		event, side, freq , reply , spot , dist = os.pullEvent()
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
	local ignore, height
  local originalPosition = sworm_api.getPosition()

	state = "mining"

  -- Excavate tower.
	while sworm_api.down() do
		for i = 1 , 4 do
			ignore = checkIgnore()

			if not ignore then
				turtle.dig()
				sworm_api.checkInventory()	
			end

			if i ~= 4 then 
				sworm_api.right() 
			end
		end
	end

  -- Back to origin height.
  sworm_api.moveTo(originalPosition)
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
  local spot
  local init = false
  
  if init == false and state ~= "setting" then
    sworm_api.init()
    init = true
  end

	modem = peripheral.find("modem")
	myChannel = os.getComputerID()

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
			state = "waiting"
      if init == false then
        sworm_api.init()
        init = true
      end
		elseif state == "waiting" then
			message("--> Waiting")
			spot = getNextSpot()
			state = "moving"
		elseif state == "moving" then
			message("--> Moving")
      if init == false then
        sworm_api.init()
        init = true
      end
      if spot == nil then
        spot = getNextSpot()
      end
      spot = vector.new(spot.x, spot.y, spot.z)
			sworm_api.moveTo(spot)
			state = "mining"
		elseif state == "mining" then
			-- rawread()
			message("--> Mining")
      if init == false then
        sworm_api.init()
        init = true
      end
			excavate()
			state = "waiting"
		else
			message("Invalid state - main() " .. state)
		end
	end
end

os.loadAPI("sworm_api")
main()
