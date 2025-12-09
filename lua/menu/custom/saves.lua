local searchQuery = nil
local PANEL = {}

function PANEL:Init()
	self:Dock( FILL )

end

function PANEL:SetType( typ )
	self.Type = typ
	self:UpdateList()
end


function PANEL:UpdateList()
	if(not self.list) then
		local Options = vgui.Create( "DListLayout", self )
		Options:DockPadding( 5, 30, 5, 5 )
		Options:Dock( LEFT )
		Options:SetWide( 200 )
		self.Options = Options
		local Scroll = vgui.Create( "DScrollPanel",  Options, 'ScrollPanel' )
		Scroll:Dock( FILL )
		Scroll:DockPadding( 5, 5, 5, 5 )
		Scroll:SetWide( 200 )
		self.Scroll = Scroll

		local List = vgui.Create( "DIconLayout", Scroll )
		List:Dock( FILL )
		List:SetSpaceY( 5 )
		List:SetSpaceX( 5 )
		self.List = List

		local searchBar = vgui.Create( "DFancyTextEntry", Options, 'searchBar')
		searchBar:Dock( TOP )
		searchBar:SetFont( "DermaRobotoDefault" )
		searchBar:SetPlaceholderText( "searchbar_placeholer" )
		searchBar:SetText(searchQuery or "")
		searchBar:DockMargin( 0, 0, 0, 10 )
		searchBar:SetUpdateOnType( true )
		searchBar.OnValueChange = function() 
			searchQuery = searchBar:GetText():lower()
			if( searchQuery == "" ) then searchQuery = nil end
			self:UpdateList()
		end
		self.searchBar = searchBar
	end
	local List = self.List
	List:Clear()

	local f = nil
	if ( self.Type == "saves" ) then
		f = file.Find( "saves/*.gms", "MOD", "datedesc" )
	elseif ( self.Type == "demos" ) then
		f = file.Find( "demos/*.dem", "MOD", "datedesc" )
	elseif ( self.Type == "dupes" ) then
		f = file.Find( "dupes/*.dupe", "MOD", "datedesc" )
	end

	for k, v in pairs( f ) do
		if(searchQuery and not v:lower():find(searchQuery)) then continue end
		local ListItem = List:Add( "DImageButton" )
		ListItem:SetSize( 128, 128 )
		ListItem:SetImage( self.Type .. "/" .. v:StripExtension() .. ".jpg" )
		ListItem.DoDoubleClick = function()
			if ( self.Type == "saves" ) then
				RunConsoleCommand( "gm_load", "saves/" .. v )
			elseif ( self.Type == "demos" ) then
				RunConsoleCommand( "playdemo", "demos/" .. v )
			end
		end
		ListItem.DoRightClick = function()
			local m = DermaMenu()

			if ( self.Type == "saves" ) then
				m:AddOption( "Load", function() RunConsoleCommand( "gm_load", "saves/" .. v ) end )
			elseif ( self.Type == "demos" ) then
				m:AddOption( "Play", function() RunConsoleCommand( "playdemo", "demos/" .. v ) end )
				m:AddOption( "Demo To Video", function() RunConsoleCommand( "gm_demo_to_video", "demos/" .. v ) end )
			end
			m:AddOption( "Delete", function()
				file.Delete( self.Type .. "/" .. v, "MOD" )
				file.Delete( self.Type .. "/" .. v:StripExtension() .. ".jpg", "MOD" )
				self:UpdateList()
			end )
			m:AddOption( "Cancel" )
			m:Open()
		end
	end
end

function PANEL:Paint( w, h )
	surface.SetDrawColor( 0, 0, 0, 150 )
	surface.DrawRect( 0, 0, w, h )
end

vgui.Register( "SavesPanel", PANEL, "EditablePanel" )

