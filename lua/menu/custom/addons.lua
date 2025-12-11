
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
local FGColor = Color( 256, 256, 256, 256 )
local BackgroundColor = Color( 200, 200, 200, 128 )
local BackgroundColor2 = Color( 200, 200, 200, 255 ) --Color( 0, 0, 0, 100 )
local BackgroundColor3 = Color( 130, 130, 130, 255 ) --Color( 0, 0, 0, 100 )
local missingMat = Material("../html/img/addonpreview.png", "nocull smooth")
local lastBuild = 0
local imageCache = {}
local selectedColor, enabledColor, disabledColor = Color(0, 150, 255, 255), Color(160, 255, 160, 255), Color(100, 100, 100, 255)

local function fileSize(n)
	local i = 1
	while n > 1024 do
		n = n/1024
		i=i+1
	end
	return ('%.2f '):format(n) .. ({"B",'KB',"MB",'GB','TB','PB','???'})[i]
end

local function getDataFromID(id)
	id=tostring(id)
	if gDataTable[id] then return gDataTable[id] end
	local tbl = {
		dependants = {},
	}

	gDataTable[id] = tbl
	return tbl
end



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
	
	updateModStuffs = function(self)
		PANEL.modImage:SetMaterial(self.Image or missingMat)
		PANEL.modText:SetBGColor(BackgroundColor3)
		PANEL.modText:SetFGColor(FGColor)
		local text = {self.Addon.title,''}
		if(self.AdditionalData) then
			local data = self.AdditionalData
			text[#text+1] = data.description
			text[#text+1] = "\nSize: " .. fileSize(data.size)
			text[#text+1] = ("Score: %.2f"):format(data.score)
			text[#text+1] = ("Upvotes/Downvotes: %i/%i"):format(data.up,data.down)
			if(#data.content_descriptors > 0) then
				text[#text+1] = "Content Descriptors: " .. table.concat( data.content_descriptors, ", ")
			end
			if(#data.children > 0) then
				local dependsOn = {}
				for i,id in ipairs(data.children) do
					local id = tostring(id)
					dependsOn[#dependsOn+1] = gDataTable[id] and gDataTable[id].title or id .. '(N/A)'
				end
				text[#text+1] = "\nRequires: " .. table.concat( dependsOn, ", ")
			end
			if(data.dependants) then
				local dependants = {}
				for id in pairs(data.dependants) do
					dependants[#dependants+1] = gDataTable[id] and gDataTable[id].title or v .. '(N/A)'
				end
				if(#dependants > 0) then
					text[#text+1] = "\nRequired by: " .. table.concat( dependants, ", ")
				end
			end

		end

		PANEL.modText:SetText(table.concat(text,'\n'))
	end,
	OnMouseReleased = function (self, mousecode)
		if ( mousecode == MOUSE_MIDDLE ) then 
			self:SetAddonState(!self:GetAddonState())
			self:updateModStuffs()
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
					self:updateModStuffs()
					return
				end
			end
			if(!input.IsControlDown() and !self.DermaCheckbox:IsHovered()) then
				for index,addon in pairs(PANEL.AddonList:GetChildren()) do
					if(addon.GetSelected and addon:GetSelected()) then
						addon:SetSelected(false)
					end
				end
				self:updateModStuffs()
			end

			self:SetSelected(!self:GetSelected())
			self:updateModStuffs()
			
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
		self:updateModStuffs()
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
	SetSelected = function(self, b) 
		self.DermaCheckbox:SetChecked( b )

		
	end,
	GetSelected = function(self) return self.DermaCheckbox:GetChecked() end,


	UpdateData = function(self, data)
		self.AdditionalData = data
		self:SetTooltip(data.title)
		if(not self.Addon.wsid or not data.children) then return end
		for i,v in pairs(data.children) do
			getDataFromID(v).dependants[self.Addon.wsid] = true
		end
	end,
	SetAddon = function(self, data)
		self.Addon = data
		self:SetTooltip(self.Addon.title)
		if ( gDataTable[ data.wsid ] ) then 
			self:UpdateData(gDataTable[data.wsid])
			return
		end
		if data.wsid then
			getDataFromID(data.wsid)
		end

		steamworks.FileInfo( data.wsid, function( result )
			-- gDataTable[ data.wsid ] = result
			local tbl = gDataTable[ data.wsid ]
			for i,v in pairs(result) do
				tbl[i]=v
			end


			if ( !file.Exists( "cache/workshop/" .. result.previewid .. ".cache", "MOD" ) ) then
				steamworks.Download( result.previewid, false, function(name) end )
			end

			if ( !IsValid(self) ) then return end

			self.panel:RefreshAddons()
			self:UpdateData(result)
		end )
	end,
	Paint = function(self, w, h )
		if ( IsValid(self.DermaCheckbox) ) then
			self.DermaCheckbox:SetVisible( self.Hovered or self.DermaCheckbox.Hovered or self:GetSelected() )
		end

		if (imageCache[ self.AdditionalData.previewid ]) then
			self.Image = imageCache[ self.AdditionalData.previewid ]
		elseif (CurTime() - lastBuild) > 0.1 and file.Exists( "cache/workshop/" .. self.AdditionalData.previewid .. ".cache", "MOD" ) then
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

local Sorting = {
	{
		label = "Name",
		id="title",
	},
	{
		label = "Last Updated",
		id="updated",
	},
	{
		label = "Size",
		id="size",
	},
	{
		label = "Sub date",
		id="timeadded",
	},
	{
		label = "ID",
		id="id",
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
	Categories:DockPadding( 5, 5, 5, 5 )
	Categories:Dock( RIGHT )
	Categories:SetWide( 350 )
	Categories:SetBGColor(BackgroundColor)


	--[[ ------------------------------------------------------------------------- ]]

	local modImage = vgui.Create( "DImage", Categories )
	modImage:Dock( TOP )
	modImage:SetWidth( 350 )
	modImage:SetHeight( 350 )
	modImage:SetZPos( -1 )
	modImage:DockMargin( 0, 0, 0, 0 )
	modImage:SetMaterial(missingMat)

	PANEL.modImage = modImage

	local modText = vgui.Create( "RichText", Categories )
	modText:Dock( TOP )
	modText:SetTall( 300 )
	modText:SetZPos( -1 )
	modText:DockMargin( 0, 0, 0, 20 )

	PANEL.modText = modText


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
	Groups:DockMargin( 0, 0, 160, -20 )
	Groups:SetTall( 20 )
	Groups:SetWide( 140 )
	for id, group in pairs( Grouping ) do 
		Groups:AddChoice( "Group by: " .. group.label, id, !Groups:GetSelectedID() )
	end
	Groups.OnSelect = function( index, value, data ) self:RefreshAddons() end

	local Filters = vgui.Create( "DComboBox", Categories )
	self.Filters = Filters
	Filters:Dock( TOP )
	Filters:DockMargin( 200, 0, 0, 20 )
	Filters:SetTall( 20 )
	Filters:SetWide( 150 )
	for id, f in pairs( AddonFilters ) do 
		Filters:AddChoice( "Filter by: " .. f.label, id, !Filters:GetSelectedID() )
	end
	Filters.OnSelect = function( index, value, data ) self:RefreshAddons() end

	local Sorts = vgui.Create( "DComboBox", Categories )
	self.Sorts = Sorts
	Sorts:Dock( TOP )
	Sorts:DockMargin( 0, 0, 160, 20 )
	Sorts:SetTall( 20 )
	Sorts:SetWide( 140 )
	for id, sort in pairs( Sorting ) do 
		Sorts:AddChoice( "Sort by: " .. sort.label, id, !Sorts:GetSelectedID() )
	end
	Sorts.OnSelect = function( index, value, data ) self:RefreshAddons() end
	--[[ ------------------------------------------------------------------------- ]]

	local SelectAll = vgui.Create( "DButton", Categories )
	self.SelectAllButton = SelectAll
	SelectAll:Dock( TOP )
	SelectAll:SetText( "#Select All" )
	SelectAll:SetTall( 20 )
	SelectAll:DockMargin( 0, 0, 230, -20 )
	SelectAll.DoClick = function() self:SelectAll() end

	local DeselectAll = vgui.Create( "DButton", Categories )
	self.DeselectAllButton = DeselectAll
	DeselectAll:Dock( TOP )
	DeselectAll:SetText( "#Deselect All" )
	DeselectAll:SetTall( 20 )
	DeselectAll:DockMargin( 120, 0, 110, -20 )
	DeselectAll.DoClick = function() self:DeselectAll() end

	local InvertAll = vgui.Create( "DButton", Categories )
	InvertAll:Dock( TOP )
	InvertAll:SetText( "#Invert" )
	InvertAll:SetTall( 20 )
	InvertAll:DockMargin( 240, 0, 0, 10 )
	InvertAll.DoClick = function() self:InvertSelection() end


	local ToggleMounted = vgui.Create( "DButton", Categories )
	self.ToggleMounted = ToggleMounted
	ToggleMounted:Dock( TOP )
	ToggleMounted:SetText( "#Toggle Selected" )
	ToggleMounted:SetTall( 20 )
	ToggleMounted:DockMargin( 0, 0, 230, -20 )
	ToggleMounted.DoClick = function() self:ToggleSelected() end

	local EnableSelection = vgui.Create( "DButton", Categories )
	self.EnableSelection = EnableSelection
	EnableSelection:Dock( TOP )
	EnableSelection:SetText( "#Enable Selected" )
	EnableSelection:SetTall( 20 )
	EnableSelection:DockMargin( 120, 0, 110, -20 )
	EnableSelection.DoClick = function() self:EnableSelected() end

	local DisableSelection = vgui.Create( "DButton", Categories )
	self.DisableSelection = DisableSelection
	DisableSelection:Dock( TOP )
	DisableSelection:SetText( "#Disable Selected" )
	DisableSelection:SetTall( 20 )
	DisableSelection:DockMargin( 240, 0, 0, 10 )
	DisableSelection.DoClick = function() self:DisableSelected() end

	--[[ ------------------------------------------------------------------------- ]]
	--[[ ------------------------------------------------------------------------- ]]

	local OpenWorkshop = vgui.Create( "DButton", Categories )
	OpenWorkshop:Dock( TOP )
	OpenWorkshop:SetText( "#Open Workshop" )
	OpenWorkshop:SetTall( 30 )
	OpenWorkshop:DockMargin( 0, 20, 0, 0 )
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
	delyeet:DockMargin( 0, 10, 0, 0 )
	delyeet.DoClick = function() 
		self:UninstallSelected()
	end
	self.UninstallSelectedButton = delyeet

	------------------- Addon List

	local Scroll = vgui.Create( "DScrollPanel", self )
	Scroll:Dock( FILL )
	Scroll:DockMargin( 5, 5, 5, 5 )
	function Scroll:Paint( w, h )
		draw.RoundedBoxEx( 4, 0, 0, w, h, BackgroundColor, false, true, false, true )
		draw.RoundedBoxEx( 4, 0, 0, w, h, BackgroundColor2, false, true, false, true )
	end

	local AddonList = vgui.Create( "DIconLayout", Scroll )
	AddonList:SetSpaceX(5)
	AddonList:SetSpaceY(5)
	AddonList:Dock(FILL)
	AddonList:DockMargin(5, 5, 5, 5)
	AddonList:DockPadding(5, 5, 5, 5)

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
	PANEL.anyAddonChanged = false
end


function PANEL:RefreshAddons()

	self.AddonList:Clear()

	local grp = self.Groups:GetOptionData( self.Groups:GetSelectedID() )
	local filter = self.Filters:GetOptionData( self.Filters:GetSelectedID() )
	local sort = self.Sorts:GetOptionData( self.Sorts:GetSelectedID() )

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

		for k, mod in SortedPairsByMemberValue( addns, Sorting[sort].id ) do

			local pnl = self.AddonList:Add( "MenuAddon" )
			pnl.panel = self
			pnl:SetAddon( mod )
			pnl:DockMargin( 0, 0, 5, 5 )

		end

	end

end

vgui.Register( "AddonsPanel", PANEL, "EditablePanel" )
