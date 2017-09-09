--[[
cl_unstuck_debug.lua

--]]

-- Debug ConVar
Unstuck.Debug = {}
Unstuck.Debug.HelpText = "Renders debug information representing the positions the unstuck addon tested."
Unstuck.Debug.ConVar = CreateClientConVar( "unstuck_debug", "0", true, true, Unstuck.Debug.HelpText )

-- Clear the debug table when the convar is set to false.
cvars.AddChangeCallback( "unstuck_debug", function( convar_name, value_old, value_new )
	if value_new == "0" then
		LocalPlayer().UnstuckDebugData = nil
	end
end )

--[[------------------------------------------------
	Name: Unstuck.Debug()
	Desc: Stores the information in a table for the unstuck results.
		Net Args:
			Int: Task to perform. Refer to enumerations in sh_unstuck.lua
			Int: Render Type enum.
			Vector: Min / Start
			Vector: Max / End
--]]------------------------------------------------
net.Receive( "Unstuck.Debug", function( len, ply )
	local client = LocalPlayer()
	
	local DebugTask = net.ReadInt(8)
	if DebugTask == Unstuck.Enumeration.Debug.COMMAND_CLEAR then
		client.UnstuckDebugData = nil
	elseif DebugTask == Unstuck.Enumeration.Debug.COMMAND_ADD then
		client.UnstuckDebugData = client.UnstuckDebugData or {}
		table.insert(client.UnstuckDebugData, {
			type = net.ReadInt(8),
			point1 = net.ReadVector(),
			point2 = net.ReadVector(),
			color = net.ReadColor()
		} )
	end
end )

--[[------------------------------------------------
	Name: PostDrawOpaqueRenderables()
	Desc: Draws Lines or WireFrame Boxes of the unstuck results that have been stored.
--]]------------------------------------------------
local pairs = pairs
hook.Add( "PostDrawOpaqueRenderables", "Unstuck.Debug.Draw", function( drawDepth, drawSkybox )
	local client = LocalPlayer()
	if Unstuck.Debug.ConVar:GetBool() then
		if client.UnstuckDebugData then
			for _, data in pairs( client.UnstuckDebugData ) do
				if data.type == Unstuck.Enumeration.Debug.NOUN_BOX then 
					render.DrawWireframeBox( Vector(), Angle(), data.point1, data.point2, data.color, true )
				elseif data.type == Unstuck.Enumeration.Debug.NOUN_LINE then
					render.DrawLine( data.point1, data.point2, data.color, true )
				end
			end
		end
		
		local minBound, maxBound = client:GetHull()
		render.DrawWireframeBox( client:GetPos()+Vector(0,0,minBound.z), Angle(), minBound, maxBound, Color(255,0,255), true )
		
		cam.Start3D2D( client:GetPos()+Vector(0,-10,5), Angle(0, 0, 0), 0.3 )
			draw.DrawText(client:GetPos())
		cam.End3D2D()
	end
		
end )
