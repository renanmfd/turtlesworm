--------------------------------------------------------------

local state = "serving"  	-- "serving" "retriving" "placing" "midserving"
local facing = "north"

local x = 0
local z = 1
local y = 0

local chunkCount = 0		-- Number of chunks mined (chunk loader used)
local fullCount = 0		-- Number of full paths
local spotCount = 0		-- Number of spots mined
local slaveCount = 0		-- Number of slave mining turtles

local movex = nil
local movey = nil

-- file handler

local file = "state.cc"
local spot = "spots.cc"

-- Modem channels

local sendCh = 0
local recvCh = 100

--------------------------------------------------------------
--------------------------------------------------------------

local function saveState()
	f = fs.open( file , "w")
	f.writeLine( state )
	f.writeLine( facing )
	f.writeLine( tostring( x ) )
	f.writeLine( tostring( z ) )
	f.writeLine( tostring( y ) )
	f.writeLine( tostring( chunkCount ) )
	f.writeLine( tostring( fullCount ) )
	f.writeLine( tostring( spotCount ) )
	f.close()
end

-------------------------------------------------------------

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
	chunkCount = tonumber( f.readLine() )
	fullCount = tonumber( f.readLine() )
	spotCount = tonumber( f.readLine() )
	f.close()
	return true
end

--------------------------------------------------------------

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
		print("Server: Invalid facing position - updateLocation()")
	end
end

--------------------------------------------------------------

local function updateHeight( str )
	if str == "down" then
		z = z - 1
	elseif str == "up" then
		z = z + 1
	else
		print("Server: Invalid moving down/up position - updateHeight()")
	end
end

--------------------------------------------------------------

local function refuel()
	if turtle.detect() then
		if not turtle.dig() then
			print("Server: Bedrock stop - refuel() ")
		end
	end
	turtle.select(2)
	turtle.place()
	turtle.select(16)
	turtle.dropDown()
	turtle.suck()
	turtle.refuel( 64 )
	print("Server: Fuel level: "..turtle.getFuelLevel() )
	turtle.select(2)
	turtle.dig()
	turtle.select(5)
end

--------------------------------------------------------------

local function forward()
	turtle.select(5)
	while not turtle.forward() do
		if not turtle.dig() then
			print("Server: Unbreakable block reached - forward()")
			return false
		elseif turtle.getFuelLevel() == 0 then
			print("Server: Low fuel - forward()")
			refuel()
			print("Server: Refueled. Ready to go!")
		elseif turtle.attack() then
			print("Server: Mob on my way. Die! - forward()")
		end
	end
	updateLocation()
	saveState()
	return true	
end

local function nforward( num )
        if num <= 0 then
                print("Invalid number - nforward(num)")
                return false
        end
        write("Old position: x=",x," y=",y)
        for i=1 , num do
                forward()
        end
        print(" / new: x=",x," y=",y)
        return true
end    	

--------------------------------------------------------------

local function down()
	turtle.select(5)
	while not turtle.down() do
		if not turtle.digDown() then
			if turtle.attack() then
				print("Server: Mob on the way. Die! - down()")
			elseif turtle.getFuelLevel() == 0 then
				print("Server: Low fuel - down() ")
				refuel()
				print("Server: Refueled. Ready to go!")
			else
				print("Server: Bedrock reached - down()")
				return false
			end
		end
	end
	updateHeight( "down" )
	return true
end

--------------------------------------------------------------

local function up()
	turtle.select(5)
	while not turtle.up() do
		if turtle.getFuelLevel() == 0 then
			print("Server: Low fuel - down() ")
			refuel()
			print("Server: Refueled. Ready to go!")
		elseif turtle.attack() then
			print("Server: Mob on the way. Die! - up()")
		elseif not turtle.dig() then
			print("Server: Bedrock reached - down()")
			return false
		end
	end
	updateHeight( "up" )
	return true
end


--------------------------------------------------------------

local function left()
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
		print("Server: Invalid facing direction - left()")
	end
	saveState();
end

--------------------------------------------------------------

local function right()
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
		print("Server: Invalid facing direction - right()")
	end
	saveState();
end

--------------------------------------------------------------

local function turnTo( dir )
	print("Server: turnTo(",dir,")")
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
			print("Server: Invalid facing direction - turnTo(dir)")
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
			print("Server: Invalid facing direction - turnTo(dir)")
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
			print("Server: Invalid facing direction - turnTo(dir)")
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
			print("Server: Invalid facing direction - turnTo(dir)")
		end
	else
		print("Server: Invalid goto direction - turnTo(dir)")
	end
end

-------------------------------------------------------------

local function move()
        if movex==nil or movey==nill then
                print("Server: Moving position equals to nil - move()")
                return false
        end
        state = "moving"
        print("Server: Moving to "..movex.." "..movey )
        aux_x = movex - x
        aux_y = movey - y
        --print("Server: aux_x=",aux_x," aux_y=",aux_y)
        if aux_x > 0 then
                --print("Server: aux_x>0")
                turnTo("east")
                nforward(aux_x)
        elseif aux_x < 0 then
                --print("Server: aux_x<0")
                turnTo("west")
                nforward(-aux_x)
        end
        if aux_y > 0 then
                --print("Server: aux_y>0")
                turnTo("north")
                nforward(aux_y)
        elseif aux_y < 0 then
                --print("Server: aux_y<0")
                turnTo("south")
                nforward(-aux_y)
        end
        movex = nil
        movey = nil
        return true
end

-------------------------------------------------------------

local function getNextSpot()
	if not fs.exists( spot ) then 
		print("Server: Spot file do not exist error - getNextSpot()") 
		return
	end
	f = fs.open( spot , "r" )
	aux = 0
	hx = " "
	hy = " "
	while aux<=spotCount do
		hx = f.readLine()
		hy = f.readLine()
		if hy == nil then
			print("Server: Error nill line - getNextSpot()")
			return
		end
		aux = aux+1
	end
	sx = tonumber( hx )
	sy = tonumber( hy )
	f.close()
	spotCount = spotCount + 1
	saveState()
	--print("Server: Next spot is x=",sx,"  y=",sy+fullCount )
	return sx,sy
end


-------------------------------------------------------------

local function placeChunkLoader()
	turtle.digUp()
	turtle.select(1)
	turtle.placeUp()
	turtle.select(5)
end

-------------------------------------------------------------

local function rescueChunkLoader()
	movex = 0
	movey = chunkCount*16
	move()
	turtle.select(1)
	turtle.digUp()
	turtle.select(5)
end

-------------------------------------------------------------

local function goToNextChunk()
	print("Server: Going to next chunk")
	movex = 0
	movey = (chunkCount+1)*16
	move()
	print("Server: Placing chunk loader")
	placeChunkLoader()
	print("Server: Rescuing chunk loader")
	rescueChunkLoader()
	movex  = 0
	movey = (chunkCount+1)*16
	move()
	print("Server: Done chunk move")
end

-------------------------------------------------------------

local function firstAction()
	up()
	if turtle.detectUp() then
		if not turtle.digUp() then
			print("Server: Error Badrock - firstAction() ")
		end
	end
	turtle.select(1)
	turtle.placeUp()
	modem = peripheral.wrap("right")
	print("Server: Modem attached")
	modem.open( recvCh )
	print("Server: Receive channel ",recvCh," is open")
	for i=5 , 16 do
		turtle.select(i)
		if turtle.getItemCount(i) ==1 then
			print("Server: Placing Turtle "..(i-4) )
			while not turtle.placeDown() do 
				print("Server:Error placing turtle")
				sleep(2) 
			end
			if peripheral.isPresent("bottom") then
				print("Server: turtle turned on")
				peripheral.wrap("bottom").turnOn()
			end
			print("Server: Waiting for slave response")
			event, side, freq , reply , msg , dist = os.pullEvent("modem_message")
			while msg~="ready" do
				event, side, freq , reply , msg , dist = os.pullEvent("modem_message")
			end
			print("Server: Response received. Seting him up to mine.")
			turtle.select(4)
			turtle.dropDown(1)
			turtle.select(3)
			turtle.dropDown(1)
			turtle.select(2)
			turtle.dropDown(1)
			slaveCount = slaveCount + 1
			print("Server: Sending all set message")
			modem.transmit( sendCh , slaveCount , "set" )
			e, s, f, r, m, d= os.pullEvent("modem_message")
			print("e=",e," s=",s," f=",f," r=",r," m=",m," d=",d)
			while r~=slaveCount do
				e, s, f, r, m, d= os.pullEvent("modem_message")
				print("Server: Event=",e )
			end
			print("Server: Slave requesting spot")
			sx , sy = getNextSpot()
			--print("x="..sx.." y="..sy )
			modem.transmit( slaveCount , sx , tostring(sy) )
			print("Server: Slave ",slaveCount," just started his job")
		else 
			break
		end
		sleep(1)
	end
	print("---------------------------------")
	modem.closeAll()
end

-------------------------------------------------------------

local function attendRequests()
	event, side, freq , reply , msg , dist = os.pullEvent("modem_message")
	if msg == "request" then	
		sx , sy = getNextSpot()
		print("Server: Slave ",reply,", job on x=",sx," y=",sy )
		modem.transmit( reply , tonumber(sx) , tostring( sy+fullCount ) )
	end
	if spotCount > 15 then
		spotCount = 0
		fullCount = fullCount+5
	end
end

-------------------------------------------------------------

local function chunkLoader()
	aux = (fullCount + (spotCount/5))/16
	--print("Server: chunkLoader() full=",fullCount," spot=",spotCount," chunk=",chunkCount," aux=",aux)
	if math.floor(aux) > chunkCount then
		print("Server: Do chunk move")
		goToNextChunk()
		chunkCount = chunkCount + 1
	end
end

-------------------------------------------------------------
-- ======================================================= --
-------------------------------------------------------------

local function main()
	if not loadState() then
		firstAction()
	end

	modem = peripheral.wrap("right")
	modem.open( recvCh )

	while true do
		attendRequests()
		chunkLoader()
	end
end

main()

--movex = 5
--movey = 3
--move()