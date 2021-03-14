--[[
sh_unstuck.lua

Main file for configuration and message handling.

--]]

Unstuck = {}

--[[---------------------------
		CONFIGURATION
--]]---------------------------
Unstuck.Configuration = {

	// The chat command for players to use.
	Command = {
		Prefix = { "!", "/" },
		String = { "stuck", "unstuck" },
	},
	
	// Admins will be notified when a player attemps to use the Unstuck function.
	AdminRanks = {
		"moderator",
		"admin",
		"superadmin",
		"owner",
	},
	
	// Allow the debug information to be sent only to the ranked admins.
	DebugAdminRanksOnly = false, 
	
	// If the unstuck fails, the player will be be respawned.
	RespawnOnFail = false,
	// The time in seconds between the failed message and respawning the player. 
	RespawnTimer = 3,
	
	// Cooldown between each unstuck attempt in seconds.
	Cooldown = 10,
	
	// How many iterations of position checking. Initial iteration is to check the surrounding player.
	// Every iteration after that checks the surrounding checked positions.
	// This has an exponential curve of run time needed and would be advised of no more than 4.
	MaxIteration = 3, 
	
	// The minimum distance from the player when checking for new positions to move to.
	// The addon would otherwise use a value based on the players hull if its greater than this value.
	MinCheckRange = 32,
}


--[[---------------------------
		ENUMERATION
--]]---------------------------
Unstuck.Enumeration = {

	Message = {
		UNSTUCK = 1,
		UNSTUCK_ATTEMPT = 2,
		ADMIN_NOTIFY = 3,
		NOT_ALIVE = 4,
		ARRESTED = 5,
		COOLDOWN = 6,
		FAILED = 7,
		RESPAWNING = 8,
		RESPAWN_FAILED = 9,
		CANT_USE = 10,
	},
	
	PositionTesting = {
		PASSED = 1,
		FAILED = 2,
	},
	
	Debug = {
		COMMAND_ADD = 1,
		COMMAND_CLEAR = 2,
		NOUN_BOX = 3,
		NOUN_LINE = 4
	}
}


--[[---------------------------
		DICTIONARY FOR MESSAGES
--]]---------------------------
Unstuck.Dictionary = {
	[Unstuck.Enumeration.Message.UNSTUCK] = "You should be unstuck!",
	[Unstuck.Enumeration.Message.UNSTUCK_ATTEMPT] = "You are stuck, trying to free you...",
	[Unstuck.Enumeration.Message.ADMIN_NOTIFY] = " used the Unstuck command.", // The players name will be prefixed with this string
	[Unstuck.Enumeration.Message.NOT_ALIVE] = "You must be alive to use this command!",
	[Unstuck.Enumeration.Message.ARRESTED] = "You are arrested!",
	[Unstuck.Enumeration.Message.COOLDOWN] = "Cooldown period still active! Wait a bit!",
	[Unstuck.Enumeration.Message.FAILED] = "Sorry, I failed.",
	[Unstuck.Enumeration.Message.RESPAWNING] = "Respawning in "..Unstuck.Configuration.RespawnTimer.." seconds.",
	[Unstuck.Enumeration.Message.RESPAWN_FAILED] = "Respawn canceled. Your are dead.",
	[Unstuck.Enumeration.Message.CANT_USE] = "You can't use this command at the moment.",
}


--[[---------------------------
		Message handling below.
--]]---------------------------
if SERVER then
	
	util.AddNetworkString( "Unstuck.Message" )
	util.AddNetworkString( "Unstuck.Debug" )
	local Player = FindMetaTable( "Player" )

	
	--[[------------------------------------------------
		Name: PlayerMessage()
		Desc: Sends a message to a single player.
			2nd argument used with Admin Notify
	--]]------------------------------------------------
	function Player:UnstuckMessage( enumMessage, ply )
		net.Start( "Unstuck.Message" )
		net.WriteInt( enumMessage, 8 )
		
		-- Also send the target player if notifying admins.
		if ( enumMessage == Unstuck.Enumeration.Message.ADMIN_NOTIFY ) then
			net.WriteEntity( ply )
		end
		
		net.Send( self )
	end

	--[[------------------------------------------------
		Name: PushOnUnstuck()
		Desc: pushes player a little if he is unstuck
			(cheatsy)
	--]]------------------------------------------------
	function Player:PushOnUnstuck()
		if self:GetMoveType() == MOVETYPE_OBSERVER || !self:Alive() then
			self:UnstuckMessage( Unstuck.Enumeration.Message.NOT_ALIVE )
			return
		end

		if self:IsFlagSet( FL_FROZEN ) then
			self:UnstuckMessage( Unstuck.Enumeration.Message.CANT_USE )
			return
		end
		
		self:UnstuckMessage( Unstuck.Enumeration.Message.UNSTUCK_ATTEMPT )
		self:Freeze( true )
		
		timer.Create( "UnstuckPush", 3, 1, function()
			if !self:IsValid() then
				return
			end

			if self.isBlind then
				self:UnstuckMessage( Unstuck.Enumeration.Message.FAILED )
				return
			end

			self:Freeze( false )
			
			if self:GetMoveType() ~= MOVETYPE_OBSERVER and self:Alive() then
				local push_force = 200
				local up_force = 300

				-- Push backwards
				local aim_vec = self:GetAimVector( )
				local angle = math.atan2( aim_vec.y, aim_vec.x )
				local force_vec = -push_force * Vector( math.cos( angle ), math.sin( angle ), 0 ) + Vector( 0, 0, up_force )

				self:SetVelocity( force_vec )
				self:UnstuckMessage( Unstuck.Enumeration.Message.UNSTUCK )
			end
		end)
	end
 
end

if CLIENT then
		
	net.Receive( "Unstuck.Message", function()
		local enumMessage = net.ReadInt( 8 )
		local message = {Color(255,255,0), "[Unstuck] "}
		
		if enumMessage == Unstuck.Enumeration.Message.ADMIN_NOTIFY then
			local ply = net.ReadEntity()
			table.Add( message, {Color(255,0,0), ply:Nick()} )
		end
		
		table.Add( message, {Color(255,255,255), Unstuck.Dictionary[enumMessage]} )
		chat.AddText( unpack( message ) )
	end)

end
