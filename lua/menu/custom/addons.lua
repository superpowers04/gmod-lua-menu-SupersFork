
surface.CreateFont( "rb655_AddonName", {
	size = ScreenScale( 12 ),
	font = "Tahoma"
} )

surface.CreateFont( "rb655_AddonDesc", {
	size = ScreenScale( 8 ),
	font = "Tahoma"
} )


gDataTable = gDataTable or {}


local PANEL = {
	anyAddonChanged=false,
}
local searchQuery = nil
local BackgroundColor = Color( 200, 200, 200, 128 )
local BackgroundColor2 = Color( 200, 200, 200, 255 ) --Color( 0, 0, 0, 100 )
local missingMat = Material("../html/img/addonpreview.png", "nocull smooth")
local lastBuild = 0
local imageCache = {}
local selectedColor, enabledColor, disabledColor = Color(0, 150, 255, 255), Color(160, 255, 160, 255), Color(100, 100, 100, 255)


local Addon_Object = {
	Init = function(self)
		self:SetTall( 200 )
		self:SetWide( 200 )

		self.Selected = false

		local DermaCheckbox = vgui.Create( "DCheckBox", self )
		DermaCheckbox:SetPos( 10, 10 )
		DermaCheckbox:SetValue( 0 )
		self.DermaCheckbox = DermaCheckbox
	end,
	OnMouseReleased = function (self, mousecode)
		if ( mousecode == MOUSE_MIDDLE ) then 
			self:SetAddonState(!self:GetAddonState())
			return
		end
		if ( mousecode ~= MOUSE_RIGHT ) then 

			if(input.IsShiftDown()) then
				local start_of_enabled = -1
				local diff = 10000
				local self_id = 0
				local addonList = PANEL.AddonList:GetChildren()
				for id, pnl in ipairs( addonList ) do
					if(pnl ~= self) then continue end
					self_id = id
					break
				end
				for id, pnl in ipairs( addonList ) do
					if not (pnl.GetSelected and pnl:GetSelected() and diff > math.abs(id-self_id)) then
						continue
					end
					start_of_enabled = id
					diff = math.abs(id-self_id)
				end
				if(start_of_enabled ~= -1 and diff ~= 10000) then
					local _start,_end = math.min(start_of_enabled,self_id), math.max(start_of_enabled,self_id)
					for i=_start,_end do
						addonList[i]:SetSelected(true)
					end
					return
				end
			end

			self:SetSelected(!self:GetSelected())
			
			return
		end

		local m = DermaMenu()

		if ( !self.panel.ToggleMounted:GetDisabled() ) then
			m:AddOption( "Invert Selection", function() self.panel:InvertSelection() end )
			m:AddSpacer()
		end
		if ( self.Addon ) then
			m:AddOption( "Open Workshop Page", function() 
				self.queuedAction = function(self) 
					steamworks.ViewFile( self.Addon.wsid )
				end
			end)
			m:AddSpacer()
			local should_mount_addon = steamworks.ShouldMountAddon( self.Addon.wsid )
			if(should_mount_addon) then
				m:AddOption("Disable", function() self.queuedAction = self.DisableAddon end)
			else
				m:AddOption("Enable", function() self.queuedAction = self.EnableAddon end)
			end
			m:AddOption( "Uninstall", function() self.queuedAction = self.UninstallAddon end) 
		end
		m:AddSpacer()
		m:AddOption( "Cancel", function() end )
		m:Open()
	end,

	SetAddonState = function(self, state)
		steamworks.SetShouldMountAddon( self.Addon.wsid, state )
		PANEL.anyAddonChanged = true
	end,
	GetAddonState = function(self) return steamworks.ShouldMountAddon(self.Addon.wsid) end,
	EnableAddon = function(self) self:SetAddonState(true) end,
	DisableAddon = function(self) self:SetAddonState(false) end,
	UninstallAddon = function(self)
		steamworks.Unsubscribe( self.Addon.wsid )
		PANEL.anyAddonChanged = true
	end, -- Do we need ApplyAddons here?

	toggle = function(self) return end,
	SetSelected = function(self, b) self.DermaCheckbox:SetChecked( b ) end,
	GetSelected = function(self) return self.DermaCheckbox:GetChecked() end,


	SetAddon = function(self, data)
		self.Addon = data
		if ( gDataTable[ data.wsid ] ) then 
			self.AdditionalData = gDataTable[ data.wsid ]
			return
		end

		steamworks.FileInfo( data.wsid, function( result )
			gDataTable[ data.wsid ] = result

			if ( !file.Exists( "cache/workshop/" .. result.previewid .. ".cache", "MOD" ) ) then
				steamworks.Download( result.previewid, false, function( name ) end )
			end

			if ( !IsValid(self) ) then return end


			self.panel:RefreshAddons()
			self.AdditionalData = result
			self:SetTooltip(self.Addon.title)
		end )
	end,
	Paint = function(self, w, h )
		if ( IsValid( self.DermaCheckbox ) ) then
			self.DermaCheckbox:SetVisible( self.Hovered or self.DermaCheckbox.Hovered or self:GetSelected() )
		end

		if ( self.AdditionalData and imageCache[ self.AdditionalData.previewid ] ) then
			self.Image = imageCache[ self.AdditionalData.previewid ]
		end

		if ( !self.Image and self.AdditionalData and file.Exists( "cache/workshop/" .. self.AdditionalData.previewid .. ".cache", "MOD" ) and CurTime() - lastBuild > 0.1 ) then
			self.Image = AddonMaterial( "cache/workshop/" .. self.AdditionalData.previewid .. ".cache" )
			imageCache[ self.AdditionalData.previewid ] = self.Image
			lastBuild = CurTime()
		end

		if ( self:GetSelected() ) then
			draw.RoundedBox( 4, 0, 0, w, h, selectedColor )
		end
		if ( self.Addon and steamworks.ShouldMountAddon( self.Addon.wsid ) ) then
			draw.RoundedBox( 4, 2, 2, w-4, h-4, enabledColor )
		else
			draw.RoundedBox( 4, 2, 2, w-4, h-4, disabledColor )
		end

		surface.SetMaterial( self.Image or missingMat)
		local tall,wide = self:GetTall(),self:GetWide()
		local imageSize = tall - 10
		surface.SetDrawColor( color_white )
		surface.DrawTexturedRect( 5, 5, imageSize, imageSize )
		if not self.Addon then return end

		--[[if ( self.Addon and !steamworks.ShouldMountAddon( self.Addon.wsid ) ) then
			draw.RoundedBox( 4, 0, 0, w, h, Color( 0, 0, 0, 180 ) )
		end]]

		if ( self.Hovered ) then
			draw.RoundedBox( 0, 5, h - 20, w - 10, 15, Color( 0, 0, 0, 180 ) )
			local title = self.Addon.title
			local tw = surface.GetTextSize( title )
			local offset = 0
			if ( tw > w ) then
				offset=( ( w - tw ) * math.sin( CurTime() ) )
			end
			draw.SimpleText( title, "DEFAULT", w / 2 - tw / 2 + offset, h - 24, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
		end
		if( self.queuedAction and not self:queuedAction()) then
			self.queuedAction=nil
		end

	end

}

vgui.Register( "MenuAddon", Addon_Object, "Panel" )

--------------------------------------------------------------------------------------------------------------------------------

local AddonFilters = {
	none = {
		label = "None",
		func = function()
			return true
		end
	},
	enabled = {
		label = "Enabled",
		func = function( mod )
			return mod.mounted
		end
	},
	disabled = {
		label = "Disabled",
		func = function( mod )
			return !mod.mounted
		end
	},
}

local Grouping = {
	none = {
		label = "None",
		func = function( addons )
			return { { addons = addons } }
		end
	},
	enabled = {
		label = "Enabled",
		func = function( addons )
			local t = {
				[true] = {
					title = "Enabled",
					addons = {}
				},
				[false] = {
					title = "Disabled",
					addons = {}
				}
			}

			for _, addon in pairs( engine.GetAddons() ) do
				table.insert( t[ addon.mounted ].addons, addon ) -- if addon.mounted ever returns nil, I'm going to cry
			end
			t.enabled = t[true]
			t.disabled = t[false]
			t[true]=nil
			t[false]=nil

			return t
		end
	},
	ptags = {
		label = "Primary Tags",
		func = function( addons )
			local t = {
				noinfo = {
					title = "Information not loaded yet!",
					addons = {}
				}
			}

			local Ptags = { ['server content'] = "Server Content",servercontent = "Server Content", effects = "Effects", model = "Model", gamemode = "Gamemode", npc = "NPC", tool = "Tool", vehicle = "Vehicle", weapon = "Weapon", map = "Map" }
			for _, addon in pairs( engine.GetAddons() ) do
				if ( !gDataTable[ addon.wsid ] ) then
					table.insert( t.noinfo.addons, addon )
					continue
				end
				local tags = (","):Explode(gDataTable[ addon.wsid ].tags )
				for _, tag in pairs( tags ) do
					if ( tag == "Addon" ) then continue end -- Don't duplicate ALL addons
					tag = Ptags[ tag:lower() ] or "Other"
					if ( !t[ tag ] ) then t[ tag ] = { title = tag, addons = {} } end

					table.insert( t[ tag ].addons, addon )
					break
				end
				
			end

			return t
		end
	},
	--[[models = {
		label = "Models",
		func = function( addons )
			local t = {
				models = {
					title = "Has Models",
					addons = {}
				},
				nomodels = {
					title = "Doesn't Have Models",
					addons = {}
				}
			}

			for _, addon in pairs( engine.GetAddons() ) do
				if ( addon.models > 0 ) then
					table.insert( t.models.addons, addon )
				else
					table.insert( t.nomodels.addons, addon )
				end
			end

			return t
		end
	}]] -- Disabled models are reported as "no models" :(
}




function PANEL:Init()

	self:Dock( FILL )

	local Categories = vgui.Create( "DListLayout", self )
	Categories:DockPadding( 5, 200, 5, 5 )
	Categories:Dock( LEFT )
	Categories:SetWide( 200 )


	--[[ ------------------------------------------------------------------------- ]]

	local searchBar = vgui.Create( "DFancyTextEntry", Categories )
	searchBar:Dock( TOP )
	searchBar:SetFont( "DermaRobotoDefault" )
	searchBar:SetPlaceholderText( "searchbar_placeholer" )
	searchBar:DockMargin( 0, 0, 0, 20 )
	searchBar:SetZPos( -1 )
	searchBar:SetHeight( 24 )
	searchBar:SetUpdateOnType( true )
	searchBar.OnValueChange = function() 
		searchQuery = searchBar:GetText():lower()
		if( searchQuery == "" ) then searchQuery = nil end
		self:RefreshAddons()
	end

	--[[ ------------------------------------------------------------------------- ]]

	local Groups = vgui.Create( "DComboBox", Categories )
	self.Groups = Groups
	Groups:Dock( TOP )
	Groups:SetTall( 30 )
	Groups:DockMargin( 0, 0, 0, 5 )
	for id, group in pairs( Grouping ) do 
		Groups:AddChoice( "Group by: " .. group.label, id, !Groups:GetSelectedID() )
	end
	Groups.OnSelect = function( index, value, data ) self:RefreshAddons() end

	local Filters = vgui.Create( "DComboBox", Categories )
	self.Filters = Filters
	Filters:Dock( TOP )
	Filters:SetTall( 30 )
	Filters:DockMargin( 0, 0, 0, 40 )
	for id, f in pairs( AddonFilters ) do 
		Filters:AddChoice( "Filter by: " .. f.label, id, !Filters:GetSelectedID() )
	end
	Filters.OnSelect = function( index, value, data ) self:RefreshAddons() end

	--[[ ------------------------------------------------------------------------- ]]

	local ToggleMounted = vgui.Create( "DButton", Categories )
	self.ToggleMounted = ToggleMounted
	ToggleMounted:Dock( TOP )
	ToggleMounted:SetText( "#Toggle Selected" )
	ToggleMounted:SetTall( 30 )
	ToggleMounted:DockMargin( 0, 0, 0, 5 )
	ToggleMounted.DoClick = function() self:ToggleSelected() end

	local EnableSelection = vgui.Create( "DButton", Categories )
	self.EnableSelection = EnableSelection
	EnableSelection:Dock( TOP )
	EnableSelection:SetText( "#Enable Selected" )
	EnableSelection:SetTall( 30 )
	EnableSelection:DockMargin( 0, 0, 0, 5 )
	EnableSelection.DoClick = function() self:EnableSelected() end

	local DisableSelection = vgui.Create( "DButton", Categories )
	self.DisableSelection = DisableSelection
	DisableSelection:Dock( TOP )
	DisableSelection:SetText( "#Disable Selected" )
	DisableSelection:SetTall( 30 )
	DisableSelection:DockMargin( 0, 0, 0, 5 )
	DisableSelection.DoClick = function() self:DisableSelected() end

	--[[ ------------------------------------------------------------------------- ]]

	local SelectAll = vgui.Create( "DButton", Categories )
	self.SelectAllButton = SelectAll
	SelectAll:Dock( TOP )
	SelectAll:SetText( "#Select All" )
	SelectAll:SetTall( 16 )
	SelectAll:DockMargin( 0, 0, 0, 5 )
	SelectAll.DoClick = function() self:SelectAll() end

	local DeselectAll = vgui.Create( "DButton", Categories )
	self.DeselectAllButton = DeselectAll
	DeselectAll:Dock( TOP )
	DeselectAll:SetText( "#Deselect All" )
	DeselectAll:SetTall( 16 )
	DeselectAll:DockMargin( 0, 0, 0, 5 )
	DeselectAll.DoClick = function() self:DeselectAll() end

	local InvertAll = vgui.Create( "DButton", Categories )
	InvertAll:Dock( TOP )
	InvertAll:SetText( "#Invert Selection" )
	InvertAll:SetTall( 16 )
	InvertAll:DockMargin( 0, 0, 0, 40 )
	InvertAll.DoClick = function() self:InvertSelection() end

	--[[ ------------------------------------------------------------------------- ]]

	local OpenWorkshop = vgui.Create( "DButton", Categories )
	OpenWorkshop:Dock( TOP )
	OpenWorkshop:SetText( "#Open Workshop" )
	OpenWorkshop:SetTall( 30 )
	OpenWorkshop:DockMargin( 0, 40, 0, 0 )
	OpenWorkshop.DoClick = steamworks.OpenWorkshop

	local OpenWorkshop = vgui.Create( "DButton", Categories )
	OpenWorkshop:Dock( TOP )
	OpenWorkshop:SetText( "#Apply Addon Changes" )
	OpenWorkshop:SetTall( 30 )
	OpenWorkshop:DockMargin( 0, 5, 0, 0 )
	OpenWorkshop.DoClick = function() 
		PANEL.anyAddonChanged = false
		steamworks.ApplyAddons()
	end

	local delyeet = vgui.Create( "DButton", Categories )
	delyeet:Dock( TOP )
	delyeet:SetText( "#Uninstall Selected" )
	delyeet:SetTall( 30 )
	delyeet:DockMargin( 0, 40, 0, 0 )
	delyeet.DoClick = function() 
		self:UninstallSelected()
	end
	self.UninstallSelectedButton = delyeet

	------------------- Addon List

	local Scroll = vgui.Create( "DScrollPanel", self )
	Scroll:Dock( FILL )
	Scroll:DockMargin( 0, 5, 5, 5 )
	function Scroll:Paint( w, h )
		draw.RoundedBoxEx( 4, 0, 0, w, h, BackgroundColor, false, true, false, true )
		draw.RoundedBoxEx( 4, 0, 0, w, h, BackgroundColor2, false, true, false, true )
	end

	local AddonList = vgui.Create( "DIconLayout", Scroll )
	AddonList:SetSpaceX(5)
	AddonList:SetSpaceY(5)
	AddonList:Dock(FILL)
	AddonList:DockMargin(5, 5, 5, 5)
	AddonList:DockPadding(5, 5, 5, 10)

	PANEL.AddonList = AddonList
	self.AddonList = AddonList
	self:RefreshAddons()

end


function PANEL:Think()
	local anySelected = false
	local allSelected = true
	local onlyEnabled = true
	local onlyDisabled = true
	for id, pnl in pairs( self.AddonList:GetChildren() ) do
		if pnl.GetSelected then 
			if pnl:GetSelected() then
				anySelected = true
			else
				allSelected = false
			end
		end

		if ( pnl.Addon ) then
			if(steamworks.ShouldMountAddon( pnl.Addon.wsid )) then
				onlyDisabled = false
			else
				onlyEnabled = false
			end
		end
		if(anySelected and not onlyDisabled and not onlyEnabled) then
			break
		end
	end
	local noneSelected = !anySelected
	self.ToggleMounted:SetDisabled( noneSelected )
	self.EnableSelection:SetDisabled( noneSelected or onlyEnabled )
	self.DisableSelection:SetDisabled( noneSelected or onlyDisabled )

	self.SelectAllButton:SetDisabled( allSelected )
	self.DeselectAllButton:SetDisabled( noneSelected )
	self.UninstallSelectedButton:SetDisabled( noneSelected )
end

function PANEL:ToggleSelected()
	for id, pnl in pairs( self.AddonList:GetChildren() ) do
		if ( !pnl.GetSelected || !pnl:GetSelected() ) then continue end
		steamworks.SetShouldMountAddon( pnl.Addon.wsid, !steamworks.ShouldMountAddon( pnl.Addon.wsid ) )
	end
	PANEL.anyAddonChanged = true
end

function PANEL:DisableSelected()
	for id, pnl in pairs( self.AddonList:GetChildren() ) do
		if ( !pnl.GetSelected or !pnl:GetSelected() ) then continue end
		steamworks.SetShouldMountAddon( pnl.Addon.wsid, false )
	end
	PANEL.anyAddonChanged = true
end

function PANEL:EnableSelected()
	for id, pnl in pairs( self.AddonList:GetChildren() ) do
		if ( !pnl.GetSelected or !pnl:GetSelected() ) then continue end
		steamworks.SetShouldMountAddon( pnl.Addon.wsid, true )
	end
	PANEL.anyAddonChanged = true
end

function PANEL:InvertSelection()
	for id, pnl in pairs( self.AddonList:GetChildren() ) do
		if ( !pnl.GetSelected ) then continue end
		pnl:SetSelected( !pnl:GetSelected() )
	end
	PANEL.anyAddonChanged = true
end

function PANEL:DeselectAll()
	for id, pnl in pairs( self.AddonList:GetChildren() ) do
		if ( !pnl.GetSelected ) then continue end
		pnl:SetSelected( false )
	end
	PANEL.anyAddonChanged = true
end

function PANEL:SelectAll()
	for id, pnl in pairs( self.AddonList:GetChildren() ) do
		if ( !pnl.GetSelected ) then continue end
		pnl:SetSelected( true )
	end
end


function PANEL:UninstallSelected()
	for id, pnl in pairs( self.AddonList:GetChildren() ) do
		if ( !pnl.GetSelected or !pnl:GetSelected() ) then continue end
		pnl:UninstallAddon()
	end
	PANEL.anyAddonChanged = true
end

function PANEL:Update()
	self:RefreshAddons()
end

function PANEL:OnRemove()
	self:TryAddonReload()
end
function PANEL.CheckAddonDependants(addon)
	for i,v in pairs(addon.children) do
		if not engine.ShouldMountAddon(v) then
			print(('[Warn] %s depends on %s but it isn\'t enabled!'):format(addon.wsid,tostring(v)))
		end
	end
end
function PANEL:TryAddonReload()
	if(!PANEL.anyAddonChanged) then return end
	steamworks.ApplyAddons() 
	for id,v in pairs(engine.GetAddons()) do
		if ( gDataTable[ data.wsid ] ) then 
			self.AdditionalData = gDataTable[ data.wsid ]
			PANEL.CheckAddonDependants(data)
			return
		end

		steamworks.FileInfo( data.wsid, function( result )
			gDataTable[ data.wsid ] = result
			PANEL.CheckAddonDependants(result)
		end )
	end
	PANEL.anyAddonChanged = false
end


function PANEL:RefreshAddons()

	self.AddonList:Clear()

	local grp = self.Groups:GetOptionData( self.Groups:GetSelectedID() )
	local filter = self.Filters:GetOptionData( self.Filters:GetSelectedID() )

	local addons = Grouping[ grp ].func( engine.GetAddons() )

	for id, group in SortedPairsByMemberValue( addons, "title" ) do
		if ( #group.addons < 1 ) then continue end

		local addns = {}
		for k, mod in pairs( group.addons ) do
			if ( (searchQuery and mod.title and not mod.title:lower():find(searchQuery) )
				or not AddonFilters[filter].func(mod) ) then 
				continue
			end
			table.insert( addns, mod )
		end

		if ( #addns < 1 ) then continue end

		if ( group.title ) then
			local pnl = self.AddonList:Add( "DLabel" )
			pnl.OwnLine = true
			pnl:SetFont( "rb655_AddonName" )
			pnl:SetText( group.title )
			pnl:SetDark( true )
			pnl:SizeToContents()
		end

		for k, mod in SortedPairsByMemberValue( addns, "title" ) do

			local pnl = self.AddonList:Add( "MenuAddon" )
			pnl.panel = self
			pnl:SetAddon( mod )
			pnl:DockMargin( 0, 0, 5, 5 )

		end

	end

end

vgui.Register( "AddonsPanel", PANEL, "EditablePanel" )
