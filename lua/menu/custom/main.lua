
-- Developer stuff
concommand.Add( "lua", function( ply, cmd, args, str )
	if ( IsInGame() ) then return end
	RunString( str )
end )

local MenuButton = {}

language.Add( "achievements", "Achievements" )

surface.CreateFont( "MenuButton", {
	font	= "Helvetica",
	size	= 24,
	weight	= 600
} )

local DLabel = baseclass.Get( "DLabel" )

function MenuButton:Init()
	self:SetFont( "MenuButton" )
	self:SetCursor( "hand" )
	self:SetMouseInputEnabled( true )
	self:SetTextColor( Color( 255, 255, 255 ) )
	self:Dock(TOP)
	self:UpdateColor()
end

function MenuButton:SetText( ... )
	DLabel.SetText( self, ... )
	self:SizeToContents()
end

function MenuButton:SetDisabled( b )
	self.Disabled = b
	self:SetCursor( b and "none" or "hand" )
end

local disabledColor,hoveredColor,color = Color( 120, 120, 120 ), Color( 255, 255, 128 ), Color( 255, 255, 255 )

-- function MenuButton:Paint()
-- 	if (self.Disabled) then self:SetFGColor( Color( 120, 120, 120 ) ) return end
-- 	self:SetFGColor(self.Hovered and Color( 255, 255, 128 ) or Color( 255, 255, 255 ))
-- end
function MenuButton:UpdateColor()
	self:SetFGColor(
		self.Disabled and disabledColor
		or self.Hovered and hoveredColor 
		or Color( 255, 255, 255 )
	)
end

function MenuButton:OnCursorEntered()
	self.Hovered = true
	self:UpdateColor()
	if (self.Disabled) then return end 
	surface.PlaySound( "garrysmod/ui_hover.wav" )
end
function MenuButton:OnCursorExited()
	self.Hovered = false
	if (self.Disabled) then return end 
	self:UpdateColor()
end

function MenuButton:OnMousePressed()
	if self.Disabled then return end
	DLabel.OnMousePressed( self )
	surface.PlaySound( "garrysmod/ui_click.wav" )
end

vgui.Register( "MenuButton", MenuButton, "DLabel" )

local PANEL = {}

function PANEL:Init()

	self:Dock( FILL )

	local mainButtons = self:Add("DPanel")
	function mainButtons:Paint( w, h )
		---draw.RoundedBox( 0, 0, 0, w, h, Color( 0, 0, 0, 200 ) )
		self:SetPos( ScrW() / 20, math.max( ScrH() / 2 - self:GetTall() / 2, 150 ) )
	end
	mainButtons:SetSize( 250, 450 )
	self.MenuButtons = mainButtons

	local Resume = mainButtons:Add("MenuButton")
	Resume:DockMargin( 5, 5, 5, 20 )
	Resume:SetText( "#resume_game" )
	Resume.DoClick = function()
		gui.HideGameUI()
	end
	self.Resume = Resume

	local NewGame = mainButtons:Add("MenuButton")
	NewGame:DockMargin( 5, 5, 5, 0 )
	NewGame:SetText( "#new_game" )
	NewGame.DoClick = function()
		self:GetParent():OpenNewGameMenu()
	end

	local PlayMP = mainButtons:Add("MenuButton")
	PlayMP:DockMargin( 5, 0, 5, 0 )
	PlayMP:SetText( "#find_mp_game" )
	PlayMP.DoClick = function()
		RunGameUICommand( "OpenServerBrowser" )
	end

	local Addons = mainButtons:Add("MenuButton")
	Addons:DockMargin( 5, 20, 5, 0 )
	Addons:SetText( "#addons" )
	Addons.DoClick = function()
		self:GetParent():OpenAddonsMenu()
	end

	local AddonPacks = mainButtons:Add("MenuButton")
	AddonPacks:DockMargin( 5, 20, 5, 0 )
	AddonPacks:SetText( "Addon Packs(WIP)" )
	AddonPacks.DoClick = function()
		self:GetParent():OpenAddonPacksMenu()
	end

	local Saves = mainButtons:Add("MenuButton")
	Saves:DockMargin( 5, 0, 5, 0 )
	Saves:SetText( "#saves" )
	Saves.DoClick = function()
		self:GetParent():OpenSavesMenu( false, "saves" )
	end

	local Demos = mainButtons:Add("MenuButton")
	Demos:DockMargin( 5, 0, 5, 0 )
	Demos:SetText( "#demos" )
	Demos.DoClick = function()
		self:GetParent():OpenSavesMenu( false, "demos" )
	end

	local Achievements = mainButtons:Add("MenuButton")
	Achievements:DockMargin( 5, 0, 5, 0 )
	Achievements:SetText( "#achievements" )
	Achievements.DoClick = function()
		self:GetParent():OpenAchievementsMenu()
	end

	local Options = mainButtons:Add("MenuButton")
	Options:Dock( TOP )
	Options:SetText( "#options" )
	Options:DockMargin( 5, 20, 5, 20 )
	Options.DoClick = function()
		RunGameUICommand( "OpenOptionsDialog" )
	end

	local Disconnect = mainButtons:Add("MenuButton")
	Disconnect:Dock( TOP )
	Disconnect:SetText( "#disconnect" )
	Disconnect:DockMargin( 5, 5, 5, 0 )
	Disconnect.DoClick = function()
		RunGameUICommand( "Disconnect" )
	end
	self.Disconnect = Disconnect

	local Quit = mainButtons:Add("MenuButton")
	Quit:Dock( TOP )
	Quit:SetText( "#quit" )
	Quit:DockMargin( 5, 0, 5, 0 )
	Quit.DoClick = function()
		RunGameUICommand( "quit" )
	end

end

local old = 0
function PANEL:Paint()

	if ScrH() != old then
		old = ScrH()
	end

	if ( !self.Image or self.Image:GetName() != "../gamemodes/" .. engine.ActiveGamemode() .. "/logo" ) then
		self.Image = Material( "../gamemodes/" .. engine.ActiveGamemode() .. "/logo.png", "nocull smooth" )
	end

	if ( self.Image and !self.Image:IsError() ) then
		surface.SetMaterial( self.Image )
		local x, y = self.MenuButtons:GetPos()
		local w, h = self.Image:GetInt( "$realwidth" ), self.Image:GetInt( "$realheight" )
		surface.DrawTexturedRect( x, y - h, w, h )
	end

	if ( self.IsInGame != IsInGame() ) then
		self.IsInGame = IsInGame()
		
		self.Disconnect:SetVisible(self.IsInGame)
		self.Resume:SetVisible(self.IsInGame)
	end

end

vgui.Register( "MainMenuScreenPanel", PANEL, "EditablePanel" )
