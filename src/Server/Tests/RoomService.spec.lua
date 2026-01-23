return function()
	local ServerScriptService = game:GetService("ServerScriptService")
	local RoomService = require(ServerScriptService.Server.Services.RoomService)

	describe("RoomService Logic", function()
		
		-- TEST ROOM CREATION
		it("should create a room and return a 4-letter code", function()
			local hostPlayer = {UserId = 1001} -- Mock Player
			
			local code = RoomService:CreateRoom(hostPlayer)
			
			expect(typeof(code)).to.equal("string")
			expect(#code).to.equal(4) -- Code must be 4 chars
			
			local room = RoomService:GetRoom(code)
			expect(room).to.be.ok()
			expect(room.Host).to.equal(hostPlayer)
		end)

		-- TEST JOINING LOGIC
		it("should allow a player to join an existing room", function()
			local host = {UserId = 1001}
			local code = RoomService:CreateRoom(host)
			
			-- Act: A new player tries to join
			local joiner = {UserId = 2002}
			local success = RoomService:JoinRoom(joiner, code)
			
			-- Assert: Join was successful
			expect(success).to.equal(true)
			
			-- Verify player is actually in the room list
			local room = RoomService:GetRoom(code)
			expect(room.Players[joiner]).to.equal(true)
		end)

		-- 3. TEST INVALID CODES
		it("should reject joining a non-existent room", function()
			local rando = {UserId = 9999}
			local success = RoomService:JoinRoom(rando, "FAKE")
			
			expect(success).to.equal(false)
		end)
	end)
end