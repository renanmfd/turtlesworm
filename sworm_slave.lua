--------------------------------------------------------------

-- state and position handlers

local state   = "setting"   -- "mining" "moving" "waiting" "setting"
local facing  = "north"     -- "north" "south" "east" "west"
local x	= 0
local z = 0
local y = 0

-- moving handlers

local movex = -1
local movey = -1

-- file handler

local file = "state.cc"

-- wireless channels

local sendCh = 100
local recvCh = 0
local modem = peripheral.wrap("right")

--------------------------------------------------------------
--------------------------------------------------------------

local function message( str )
	print( str )
	--modem.transmit( sendCh , recvCh , "- "..str )
end

--------------------------------------------------------------

local function unloadInventory()
	turtle.select(2)
	turtle.placeUp()
	for i=4 , 16 do
		turtle.select(i)
		turtle.dropUp()
	end
	turtle.select(2)
	turtle.digUp()
end

--------------------------------------------------------------

local function checkInventory()
	for i=4 , 16 do
		turtle.select(i)
		item = turtle.getItemCount(i)
		if item == 0 then
			return false		
		end
	end
	unloadInventory()
	return true
end

--------------------------------------------------------------

local function saveState()
	f = fs.open( file , "w" )
	f.writeLine( state )
	f.writeLine( facing )
	f.writeLine( tostring( x ) )
	f.writeLine( tostring( z ) )
	f.writeLine( tostring( y ) )
	f.writeLine( tostring( movex ) )
	f.writeLine( tostring( movey ) )
	f.close()
end

--------------------------------------------------------------

local function loadState()
	if not fs.exists( file ) then 
		return false
	end
	f = fs.open( file , "r" )
	state = f.readLine()
	facing = f.readLine()
	x = tonumber( f.readLine() )
	z = tonumber( f.readLine() )
	y = tonumber( f.readLine() )
	movex = tonumber( f.readLine() )
	movey = tonumber( f.readLine() )
	f.close()
	return true
end

--------------------------------------------------------------

local function left()
	--print("turnLeft() facing=", facing," direction")
	turtle.turnLeft()
	if facing == "north" then
		facing = "west"
	elseif facing == "south" then
		facing = "east"
	elseif facing == "east" then
		facing = "north"
	elseif facing == "west" then
		facing = "south"
	else 
		message("Invalid facing direction - left() ",facing )
	end
	saveState();
end

--------------------------------------------------------------

local function right()
	--print("turnRight() facing=", facing," direction")
	turtle.turnRight()
	if facing == "north" then
		facing = "east"
	elseif facing == "south" then
		facing = "west"
	elseif facing == "east" then
		facing = "south"
	elseif facing == "west" then
		facing = "north"
	else 
		message("Invalid facing direction - right() ",facing)
	end
	saveState();
end
--------------------------------------------------------------

local function refuel()
	turtle.select(3)
	while not turtle.place() do
		if y<0 then 
			turtle.dig() 
		else 
			right()	
		end
	end
	turtle.suck()
	turtle.refuel(64)
	message("Fuel level: "..turtle.getFuelLevel() )
	turtle.select(3)
	turtle.dig()
	turtle.select(4)
end

-------------------------------------------------------------

local function updateLocation()
	if facing == "north" then
		y = y + 1
	elseif facing == "south" then
		y = y - 1
	elseif facing == "east" then
		x = x + 1
	elseif facing == "west" then
		x = x - 1
	else
		message("Invalid facing position - updateLocation()")
	end
end

--------------------------------------------------------------

local function updateHeight( str )
	if str == "down" then
		z = z - 1
	elseif str == "up" then
		z = z + 1
	else
		message("Invalid moving down/up position - updateHeight()")
	end
end

--------------------------------------------------------------

local function forward()
	turtle.select(4)
	while not turtle.forward() do
		if peripheral.isPresent("front") then
			right()
			forward()
			left()
			forward()
			left()
			forward()
			right()
			return true
		elseif not turtle.dig() then
			message("Unbreakable block reached - forward()")
			message("I'm stuck on x="..x.." y="..y.." z="..z )
			return false
		elseif turtle.getFuelLevel() == 0 then
			message("Low fuel - forward()")
			refuel()
			message("Refueled. Ready to go!")
		elseif turtle.attack() then
			message("Mob on my way. Die! - forward()")
		end
		checkInventory()
	end
	updateLocation()
	saveState()
	return true	
end

local function nforward( num )
	if num < 0 then
		message("Invalid number - nforward(num) =",num)
		return false
	elseif num==0 then
		return true
	end
	print("Old position: x=",x," y=",y)
	for i=1 , num do
		forward()
	end
	print("New position: x=",x," y=",y)
	return true
end	

--------------------------------------------------------------

local function down()
	turtle.select(4)
	while not turtle.down() do
		if peripheral.isPresent("down") then
			message("Stuck trying to move down. Turtle on the way")
			sleep(2)
		elseif not turtle.digDown() then
			if turtle.attack() then
				message("Mob on the way. Die! - down()")
			elseif turtle.getFuelLevel() == 0 then
				message("Low fuel - down() ")
				refuel()
				message("Refueled. Ready to go!")
			else
				message("Bedrock reached - down()")
				return false
			end
		end
	end
	updateHeight( "down" )
	checkInventory()
	return true
end

--------------------------------------------------------------

local function up()
	turtle.select(4)
	while not turtle.up() do
		if turtle.getFuelLevel() == 0 then
			message("Low fuel - up() ")
			refuel()
			message("Refueled. Ready to go!")
		elseif peripheral.isPresent("top") then
			sleep(2)
		elseif turtle.attack() then
			message("Mob on the way. Die! - up()")
		elseif not turtle.dig() then
			message("Bedrock reached - up()")
			return false
		end
	end
	updateHeight( "up" )
	return true
end

---------------------------------------------------------------

local function turnTo( dir )
	if dir == "north" then
		if facing == "north" then
			return true
		elseif facing == "south" then
			right()
			right()
		elseif facing == "east" then
			left()
		elseif facing == "west" then
			right()
		else
			message("Invalid facing direction - turnTo(dir) ",facing)
		end
	elseif dir == "south" then
		if facing == "south" then
			return true
		elseif facing == "north" then
			right()
			right()
		elseif facing == "west" then
			left()
		elseif facing == "east" then
			right()
		else
			message("Invalid facing direction - turnTo(dir) ",facing)
		end
	elseif dir == "west" then
		if facing == "west" then
			return true
		elseif facing == "east" then
			right()
			right()
		elseif facing == "north" then
			left()
		elseif facing == "south" then
			right()
		else
			message("Invalid facing direction - turnTo(dir) ",facing)
		end
	elseif dir == "east" then
		if facing == "east" then
			return true
		elseif facing == "west" then
			right()
			right()
		elseif facing == "south" then
			left()
		elseif facing == "north" then
			right()
		else
			message("Invalid facing direction - turnTo(dir) ", facing)
		end
	else
		message("Invalid goto direction - turnTo(dir) ", dir)
	end
end

--------------------------------------------------------------

local function excavate()
	state = "mining"
	while down() do
		for i=1 , 4 do
			turtle.select(1)
			if not turtle.compare() then
				turtle.dig()
				checkInventory()	
			end
			turtle.select(4)
			if i~=4 then 
				right() 
			end
		end
	end
	while z~=0 do
		up()
	end	
end

--------------------------------------------------------------

local function move()
	if movex==nil or movey==nill then 
		message("Moving position equals to nil - move()")
		return false
	end
	state = "moving"
	message( "Moving to "..movex.." "..movey )
	aux_x = movex - x
	aux_y = movey - y
	--print("aux_x=",aux_x," aux_y=",aux_y)
	if aux_x > 0 then
		--print("aux_x>0")
		turnTo("east")
		nforward(aux_x)
	elseif aux_x < 0 then
		--print("aux_x<0")
		turnTo("west")
		nforward(-aux_x)
	end
	if aux_y > 0 then
		--print("aux_y>0")
		turnTo("north")
		nforward(aux_y)
	elseif aux_y < 0 then
		--print("aux_y<0")
		turnTo("south")
		nforward(-aux_y)
	end
	movex = -1
	movey = -1
	return true
end

--------------------------------------------------------------

local function moveToNextChunk()
	movex = x
	movey = 16
	move()
	y = 0
end

-------------------------------------------------------------

local function getNextSpot()
	modem.open( recvCh )
	sleep(0.2)
	local count = 0
	while true do
		message("Sending Request")
		modem.transmit( sendCh , recvCh , "request" )
		os.startTimer(20)
		event = { os.pullEvent() }
		if event[1] == "modem_message" then
			movex = event[4]
			movey = tonumber( event[5] )
			message("Request attended")
			break
		elseif event[1] == "timer" then
			count = count + 1
			print("Timeout ",count )
		end
	end
end

-------------------------------------------------------------

local function setting()
	modem.open( recvCh )
	sleep(0.2)
	modem.transmit( sendCh , recvCh , "ready" )
	event, side, freq , reply , msg , dist = os.pullEvent("modem_message")
	if msg == "set" then
		recvCh = reply
		message("Channel/ID set to ",recvCh)
	else
		message("Message not SET - setting() ")
	end
	if turtle.getFuelLevel() == 0 then
		refuel()
	end
end

-------------------------------------------------------------
-- ======================================================= --
-------------------------------------------------------------

if loadState() then
	message("State loaded. Resuming task.")
else	
	message("Slave started. Ready to mine!")
end

while true do
	message("ID: ",recvCh)
	if state == "waiting" then
		message("--> Waiting")
		getNextSpot()
		state = "moving"
	elseif state == "mining" then
		message("--> Mining")
		excavate()
		state = "waiting"
	elseif state == "moving" then
		message("--> Moving")
		move()
		state = "mining"
	elseif state == "setting" then
		message("--> Setting")
		setting()
		state = "waiting"
	else
		message("Invalid state - main() ", state )
	end
end