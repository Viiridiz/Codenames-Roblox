return function()
	-- Load the module directly for unit testing logic
	local ServerScriptService = game:GetService("ServerScriptService")
	local RoomService = require(ServerScriptService.Server.Services.RoomService)

	describe("RoomService Logic", function()
		
		it("should create a room and return a 4-letter code", function()
			local hostPlayer = {UserId = 1001, Name = "TestHost", IsA = function() return true end} 
			
			local code = RoomService:CreateRoom(hostPlayer)
			
			expect(typeof(code)).to.equal("string")
			expect(#code).to.equal(4)
			
			local room = RoomService:GetRoom(code)
			expect(room).to.be.ok()
			expect(room.Host).to.equal(hostPlayer)
		end)

		it("should allow a player to join an existing room", function()
			local host = {UserId = 1001, Name = "Host", IsA = function() return true end}
			local code = RoomService:CreateRoom(host)
			
			local joiner = {UserId = 2002, Name = "Joiner", IsA = function() return true end}
			local success = RoomService:JoinRoom(joiner, code)
			
			expect(success).to.equal(true)
			
			local room = RoomService:GetRoom(code)
			expect(room.Players[joiner]).to.equal(true)
		end)

		it("should reject joining a non-existent room", function()
			local rando = {UserId = 9999, Name = "Rando", IsA = function() return true end}
			local success = RoomService:JoinRoom(rando, "FAKE")
			
			expect(success).to.equal(false)
		end)
	end)
end