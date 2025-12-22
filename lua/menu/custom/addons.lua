
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
-- TODO WARN IF MOD REQUIRES ANOTHER MOD THAT ISN'T ENABLED


local searchQuery = nil
local FGColor = Color(256, 256, 256, 256)
local TextBGColor = Color(0, 0, 0, 180)
local LinkColor = Color(192, 192, 255, 255)
local BackgroundColor = Color(200, 200, 200, 128)
local BackgroundColor2 = Color(200, 200, 200, 255) --Color( 0, 0, 0, 100 )
local BackgroundColor3 = Color(130, 130, 130, 255) --Color( 0, 0, 0, 100 )
local missingColor = Color(255,0,0,255)
local invalidColor = Color(255,150,0,255)
local TEXT_ALIGN_CENTER = TEXT_ALIGN_CENTER
local missingAddonMat = Material("materials/gui/noicon.png", "nocull smooth")
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

		local DermaCheckbox = self:Add("DCheckBox")
		DermaCheckbox:SetPos(10, 10)
		DermaCheckbox:SetValue(false)
		self.DermaCheckbox = DermaCheckbox
	end,
	
	updateModStuffs = function(self)
		surface.PlaySound( "garrysmod/ui_hover.wav" )
		local modText = PANEL.modText
		PANEL.modImage:SetMaterial(self.Image or missingMat)
		modText:SetBGColor(BackgroundColor3)
		modText:SetFGColor(FGColor)
		local text = {}
		if(self.AdditionalData) then
			local data = self.AdditionalData
			text[#text+1] = data.description ..'(...)'
			text[#text+1] = ("id: %s"):format(tostring(self.Addon.wsid))
			text[#text+1] = ("\nSize: %s"):format(fileSize(data.size))
			text[#text+1] = ("previewid: %s"):format(tostring(data.previewid))
			text[#text+1] = ("Score: %.2f"):format(data.score)
			text[#text+1] = ("Upvotes/Downvotes: %i/%i"):format(data.up,data.down)
			if(#data.content_descriptors > 0) then
				text[#text+1] = "Content Descriptors: " .. table.concat( data.content_descriptors, ", ")
			end
		else
			text[#text+1] = ("id: %s"):format(tostring(self.Addon.wsid))

		end
		PANEL.modNameText:SetText(self.Addon.title)
		modText:SetText(table.concat(text,'\n'))

		if(self.AdditionalData) then
			local data = self.AdditionalData
			local function appendModId(id)
				-- print(gDataTable[id].title, tostring(id))
				local title = gDataTable[id] and gDataTable[id].title
				if(title) then
					modText:InsertColorChange((steamworks.ShouldMountAddon(id) and enabledColor or missingColor):Unpack())
				else
					modText:InsertColorChange(invalidColor:Unpack())
				end
				modText:InsertClickableTextStart(tostring(id))
				modText:AppendText(title or (id .. "(Missing)"))
				modText:InsertClickableTextEnd()
				modText:InsertColorChange(FGColor:Unpack())
			end
			if(data.children and #data.children > 0) then
				PANEL.modText:AppendText("\nRequires: ")
				local putComma = false
				for i,id in ipairs(data.children) do
					if(putComma) then
						PANEL.modText:AppendText(", ")
					else
						putComma = true
					end
					local id = tostring(id)
					appendModId(id)
				end
			end
			if(data.dependants and table.HasValue(data.dependants, true)) then
				local dependants = {}
				modText:AppendText("\nRequired By: ")
				local putComma = false
				for id in pairs(data.dependants) do
					if(putComma) then
						PANEL.modText:AppendText(", ")
					else
						putComma = true
					end
					local id = tostring(id)
					appendModId(id)
				end
			end
			modText.OnTextClicked = function(self, id)

				local m = DermaMenu(BackgroundColor3)
				-- TODO, DO THIS PROPERLY INSTEAD OF JUST ADDING SPACES
				-- TODO, RELOAD MODTEXT WHEN SOMETHING IS CHANGED THROUGH THIS MENU
				local idLabel = Label('  ID: ' .. id)
				idLabel:SetTextColor(color_black)
				m:AddPanel(idLabel)
				local stateLabel = Label('  State: ' .. ((not steamworks.IsSubscribed(id) and "Not Subbed") or steamworks.ShouldMountAddon(id) and "Mounted" or "Not Mounted"))
				stateLabel:SetTextColor(color_black)
				m:AddPanel(stateLabel)
				m:AddSpacer()
				if(gDataTable[id]) then
					local panel_object = gDataTable[id].panel_object
					if IsValid(panel_object) then
						
						panel_object:AppendContextMenu(m)

						if(table.HasValue(PANEL.AddonList:GetChildren(),panel_object)) then
							m:AddOption("Scroll to", function() PANEL.Scroll:ScrollToChild(panel_object) end)
						end
					else
						m:AddOption( "Open Workshop Page", function() 
							steamworks.ViewFile(id)
						end)
					end
				else
					m:AddPanel(Label("   Debug: Addon missing?"))
					m:AddOption( "Open Workshop Page", function() 
						steamworks.ViewFile(id)
					end)
				end
				if not steamworks.IsSubscribed(id) then
					m:AddOption( "Subscribe", function() 
						steamworks.Subscribe(id)
					end)
				end
				
				m:AddSpacer()
				m:AddOption( "Cancel", function() end )
				m:Open()
			end
		end


		if(self.Image == missingAddonMat) then
			modText:InsertColorChange(invalidColor:Unpack())
			modText:AppendText("\n\nAddon thumbnail was unable to be read, It's probably in an invalid format (Expects png, or jpg)")
			modText:InsertColorChange(FGColor:Unpack())
		end

		PANEL.modText:GotoTextStart()
	end,
	OnMouseReleased = function (self, mousecode)
		if ( mousecode == MOUSE_MIDDLE ) then 
			self:SetAddonState(!self:GetAddonState())
			self:updateModStuffs()
			return
		end
		if ( mousecode ~= MOUSE_RIGHT ) then 

			if(input.IsShiftDown() and input.IsControlDown()) then
				self:SetAddonState(!self:GetAddonState())
				self:updateModStuffs()
				return
			end
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
			end

			self:SetSelected(!self:GetSelected())
			self:updateModStuffs()

			
			return
		end

		local m = DermaMenu()
		m.OnMouseReleased = function() surface.PlaySound( "garrysmod/ui_click.wav" ) end

		if(self.Addon and self.Addon.wsid) then
			local idLabel = Label('  ID: ' .. self.Addon.wsid)
			idLabel:SetTextColor(color_black)
			m:AddPanel(idLabel)
			local stateLabel = Label('  State: ' .. (steamworks.ShouldMountAddon(self.Addon.wsid) and "Mounted" or "Not Mounted"))
			stateLabel:SetTextColor(color_black)
			m:AddPanel(stateLabel)
			m:AddSpacer()
		end
		if ( !self.panel.ToggleMounted:GetDisabled() ) then
			m:AddOption( "Invert Selection", function() self.panel:InvertSelection() end )
			m:AddSpacer()
		end
		self:AppendContextMenu(m)
		m:AddSpacer()
		m:AddOption( "Cancel", function() end )
		m:Open()
		self:updateModStuffs()
	end,

	AppendContextMenu = function(self, menu)
		if self.Addon then
			menu:AddOption( "Open Workshop Page", function() 
				steamworks.ViewFile( self.Addon.wsid )
			end)
			menu:AddSpacer()
			if(self:IsSubscribed()) then
				local should_mount_addon = steamworks.ShouldMountAddon( self.Addon.wsid )
				if(should_mount_addon) then
					menu:AddOption("Disable", function() self:DisableAddon() end)
				else
					menu:AddOption("Enable", function() self:EnableAddon() end)
				end
				menu:AddOption( "Uninstall", function() self:UninstallAddon() end) 
			else
				menu:AddOption( "Subscribe", function() self:InstallAddon() end) 
			end
			menu:AddSpacer()
			if(self.Image == missingAddonMat) then
				menu:AddOption("Redownload thumbnail", function() self:DownloadThumbnail() end)
			end
			if(self.AdditionalData) then
				for _ in pairs(self.AdditionalData.dependants) do
					menu:AddOption("Select all dependants", function() self:SelectDependants() end)
					break
				end
				if(#self.AdditionalData.children) then
					menu:AddOption("Select all related", function() self:SelectRelated() end)
				end
			end
		end
	end,

	SetAddonState = function(self, state)
		if(state and not self:IsSubscribed()) then
			return self:InstallAddon(true)
		end
		steamworks.SetShouldMountAddon( self.Addon.wsid, state )
		PANEL.anyAddonChanged = true
	end,
	GetAddonState = function(self) return steamworks.ShouldMountAddon(self.Addon.wsid) end,
	EnableAddon = function(self) self:SetAddonState(true) end,
	DisableAddon = function(self) self:SetAddonState(false) end,
	InstallAddon = function(self, shouldMount) -- 
		steamworks.Subscribe(self.Addon.wsid)
		if(shouldMount ~= nil) then
			steamworks.SetShouldMountAddon(self.Addon.wsid, shouldMount)
		end
		PANEL.anyAddonChanged = true
	end,
	UninstallAddon = function(self)
		steamworks.Unsubscribe(self.Addon.wsid)
		PANEL.anyAddonChanged = true
	end,
	IsSubscribed = function(self)
		return self.Addon and steamworks.IsSubscribed(self.Addon.wsid) or false
	end,
	IsMounted = function(self)
		return self.Addon and steamworks.ShouldMountAddon(self.Addon.wsid) or false
	end,


	toggle = function(self) return end,
	SetSelected = function(self, b) self.DermaCheckbox:SetChecked( b ) end,
	GetSelected = function(self) return self.DermaCheckbox:GetChecked() end,
	SelectDependants = function(self, goneOver)
		if not goneOver then goneOver = {} end
		if(goneOver[self]) then return end -- If we don't do this, we will probably encounter an endless loop
		goneOver[self] = true
		self:SetSelected(true)
		for id in pairs(self.AdditionalData.dependants) do
			if(gDataTable[id] and gDataTable[id].panel_object) then
				gDataTable[id].panel_object:SelectDependants(goneOver)
			end
		end
	end,
	SelectRelated = function(self, goneOver)
		if not goneOver then goneOver = {} end
		if(goneOver[self]) then return end -- If we don't do this, we will probably encounter an endless loop
		goneOver[self] = true
		self:SetSelected(true)
		for id in pairs(self.AdditionalData.dependants) do
			if(gDataTable[id] and gDataTable[id].panel_object) then
				gDataTable[id].panel_object:SelectRelated(goneOver)
			end
		end
		for _,id in pairs(self.AdditionalData.children) do
			id=tostring(id)
			if(gDataTable[id] and gDataTable[id].panel_object) then
				gDataTable[id].panel_object:SelectRelated(goneOver)
			end
		end
	end,


	UpdateData = function(self, data)
		self.AdditionalData = data
		self.Addon.title = data.title
		self:SetTooltip(data.title)
		data.panel_object = self

		self:UpdateIcon()
		if(not self.Addon.wsid or not data.children) then return end
		for i,v in pairs(data.children) do
			getDataFromID(v).dependants[self.Addon.wsid] = true
		end
	end,

	_loadImage = function(self)
		local curtime = CurTime()
		if(curtime - lastBuild < 0.02) then return true end

		self.Image = AddonMaterial( "cache/workshop/" .. self.AdditionalData.previewid .. ".cache" )
		if(self.Image == nil) then
			self.Image = missingAddonMat
			MsgN(('%q has an invalid thumbnail!'):format(self.Addon.title or self.Addon.wsid))
		end
		imageCache[ self.AdditionalData.previewid ] = self.Image
		lastBuild = curtime
		
	end,
	UpdateIcon = function(self)
		if(not self.AdditionalData or not self.AdditionalData.previewid) then
			self.Image=missingMat
			return
		end
		local previewid = self.AdditionalData.previewid
		if not previewid then
			self.Image=missingAddonMat
			return
		end
		if (imageCache[previewid]) then
			self.Image = imageCache[previewid]
			return
		end
		if file.Exists( "cache/workshop/" .. previewid .. ".cache", "MOD" ) then
			self.queuedAction = self._loadImage
			return
		end
	end,
	SetAddon = function(self, data)
		self.Image = nil
		self.Addon = data
		self:SetTooltip(data.title or data.wsid)
		if not data.wsid then 
			ErrorNoHaltWithStack("Addon has no workshop id?!")
			return
		end


		local datatable = gDataTable[data.wsid]
		if ( datatable ) then 
			self:UpdateData(datatable)
			return
		end
		local cached_data = getDataFromID(data.wsid)
		self.AdditionalData = cached_data
		for i,v in pairs(data) do
			if(cached_data[i] == nil) then
				cached_data[i]=v
			end
		end

		steamworks.FileInfo( data.wsid, function( _result )
			-- gDataTable[ data.wsid ] = result
			if(not _result or _result.err) then
				ErrorNoHaltWithStack("Unable to get addon information! ".. _result.err)
				return
			end
			for i,v in pairs(_result) do
				cached_data[i]=v
			end

			if not cached_data.previewid then
				self.Image = missingAddonMat
			elseif not file.Exists("cache/workshop/" .. cached_data.previewid .. ".cache", "MOD") then
				self:DownloadThumbnail()
			end

			if not IsValid(self) then return end
			self:UpdateData(cached_data)

			-- self.panel:RefreshAddons()
		end )
	end,
	DownloadThumbnail = function(self)
		print('Downloading ',"cache/workshop/" .. self.AdditionalData.previewid .. ".cache")
		steamworks.Download(self.AdditionalData.previewid, false, function(name) 
			self:UpdateIcon()
		end )
	end,
	Paint = function(self, w, h )
		-- if ( IsValid(self.DermaCheckbox) ) then
		-- 	self.DermaCheckbox:SetVisible( self.Hovered or self.DermaCheckbox.Hovered or self:GetSelected() )
		-- end
		if self:GetSelected() then
			draw.RoundedBox( 4, 0, 0, w, h, selectedColor )
		end
		
		draw.RoundedBox( 4, 2, 2, w-4, h-4, self:IsMounted() and enabledColor 
		                or not self:IsSubscribed() and missingColor 
		                or disabledColor)

		surface.SetMaterial(self.Image or missingMat)
		local tall,wide = self:GetTall(),self:GetWide()
		local imageSize = tall - 10
		surface.SetDrawColor(color_white)
		surface.DrawTexturedRect( 5, 5, imageSize, imageSize )

		--[[if ( self.Addon and !steamworks.ShouldMountAddon( self.Addon.wsid ) ) then
			draw.RoundedBox( 4, 0, 0, w, h, Color( 0, 0, 0, 180 ) )
		end]]

		if self.Hovered then
			draw.RoundedBox( 0, 5, 5, w - 10, 10, TextBGColor )
			draw.RoundedBox( 0, 5, h - 20, w - 10, 15, TextBGColor )
		end
		if(self.Hovered or self.Image == missingAddonMat) then 
			local title = self.Addon and self.Addon.title or "N/A"
			local tw = surface.GetTextSize(title) or (#title * 12)
			if ( tw > imageSize ) then
				local offset = -(((SysTime()*60) % (tw+w))-w)
				
				draw.SimpleText( title, "DEFAULT", 5 + offset, h - 18, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
			else
				draw.SimpleText( title, "DEFAULT", 5, h - 18, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
			end
		end
		if self.queuedAction and not self:queuedAction() then
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
		func = function(mod)
			return steamworks.ShouldMountAddon(mod.wsid)
		end
	},
	disabled = {
		label = "Disabled",
		func = function(mod)
			return !steamworks.ShouldMountAddon(mod.wsid)
		end
	},
	cached = {
		label = "Cached",
		func = function()
			return true
		end,
		GetAddons = function()
			local files = file.Find( "cache/workshop/*.gma", "MOD")
			for i,v in ipairs(files) do
				files[i] = {wsid=v:StripExtension()}
			end

			return files
		end,

	},
	-- Popular = {
	-- 	label = "Popular",
	-- 	func = function()
	-- 		return true
	-- 	end,
	-- 	GetAddons = function()
	-- 		-- local files = file.Find( "cache/workshop/*.gma", "MOD")

	-- 		for i,v in ipairs(files) do
	-- 			files[i] = {wsid=v:StripExtension()}
	-- 		end

	-- 		return 
	-- 		-- files
	-- 	end,

	-- },
	-- wsfolder = {
	-- 	label = "Workshop folder",
	-- 	func = function()
	-- 		return true
	-- 	end,
	-- 	-- GetAddons = function()
	-- 	-- 	local files = file.Find( "../../../cache/workshop/*.gma", "MOD")
	-- 	-- 	for i,v in ipairs(files) do
	-- 	-- 		files[i] = {wsid=v:StripExtension()}
	-- 	-- 	end

	-- 	-- 	return files
	-- 	-- end,

	-- },
	-- selected_mod_relations = {
	-- 	label = "Related to selected mod",
	-- 	func = function(mod)
	-- 		return true
	-- 	end
	-- },
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
	searchQuery = nil


	self:Dock( FILL )

	local Categories = self:Add("Panel" )
	Categories:DockPadding( 5, 5, 5, 5 )
	Categories:Dock( RIGHT )
	Categories:SetWide( 350 )
	Categories:SetBGColor(BackgroundColor)


	--[[ ------------------------------------------------------------------------- ]]

	local modNameText = Categories:Add("DLabel")
	modNameText:Dock( TOP )
	modNameText:SetText('N/A')
	modNameText:DockMargin( 5,5,5,5 )
	modNameText:SetFont("rb655_AddonDesc")
	modNameText:SetTextColor(color_white)
	
	PANEL.modNameText = modNameText
	
	local modImage = Categories:Add("DImage")
	modImage:Dock( TOP )
	modImage:SetWidth( 350 )
	modImage:SetHeight( 350 )
	modImage:DockMargin( 0, 0, 0, 0 )
	modImage:SetMaterial(missingMat)

	PANEL.modImage = modImage

	local modText = Categories:Add("RichText")
	modText:Dock( TOP )
	modText:SetTall( 300 )
	modText:DockMargin( 0, 0, 0, 20 )

	PANEL.modText = modText


	--[[ ------------------------------------------------------------------------- ]]
	local searchBar = Categories:Add("DTextEntry")
	searchBar:Dock( TOP )
	searchBar:SetFont( "DermaRobotoDefault" )
	searchBar:SetPlaceholderText( "searchbar_placeholer" )
	searchBar:DockMargin( 0, 0, 0, 20 )
	searchBar:SetHeight( 24 )
	searchBar:SetUpdateOnType( true )
	searchBar.OnValueChange = function() 
		searchQuery = searchBar:GetText():lower()
		if( searchQuery == "" ) then searchQuery = nil end
		self:RefreshAddons()
	end

	--[[ ------------------------------------------------------------------------- ]]

	local Groups = Categories:Add("DComboBox")
	self.Groups = Groups
	Groups:Dock( TOP )
	Groups:DockMargin( 0, 0, 160, -20 )
	Groups:SetTall( 20 )
	Groups:SetWide( 140 )
	for id, group in pairs( Grouping ) do 
		Groups:AddChoice( "Group by: " .. group.label, id, !Groups:GetSelectedID() )
	end
	Groups.OnSelect = function( index, value, data ) self:RefreshAddons() end

	local Filters = Categories:Add("DComboBox")
	self.Filters = Filters
	Filters:Dock( TOP )
	Filters:DockMargin( 200, 0, 0, 20 )
	Filters:SetTall( 20 )
	Filters:SetWide( 150 )
	for id, f in pairs( AddonFilters ) do 
		Filters:AddChoice( "Filter by: " .. f.label, id, !Filters:GetSelectedID() )
	end
	Filters.OnSelect = function( index, value, data ) self:RefreshAddons() end

	local Sorts = Categories:Add("DComboBox")
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

	local SelectAll = Categories:Add("DButton")
	self.SelectAllButton = SelectAll
	SelectAll:Dock( TOP )
	SelectAll:SetText( "#Select All" )
	SelectAll:SetTall( 20 )
	SelectAll:DockMargin( 0, 0, 230, -20 )
	SelectAll.DoClick = function() self:SelectAll() end

	local DeselectAll = Categories:Add("DButton")
	self.DeselectAllButton = DeselectAll
	DeselectAll:Dock( TOP )
	DeselectAll:SetText( "#Deselect All" )
	DeselectAll:SetTall( 20 )
	DeselectAll:DockMargin( 120, 0, 110, -20 )
	DeselectAll.DoClick = function() self:DeselectAll() end

	local InvertAll = Categories:Add("DButton")
	InvertAll:Dock( TOP )
	InvertAll:SetText( "#Invert" )
	InvertAll:SetTall( 20 )
	InvertAll:DockMargin( 240, 0, 0, 10 )
	InvertAll.DoClick = function() self:InvertSelection() end


	local ToggleMounted = Categories:Add("DButton")
	self.ToggleMounted = ToggleMounted
	ToggleMounted:Dock( TOP )
	ToggleMounted:SetText( "#Toggle Selected" )
	ToggleMounted:SetTall( 20 )
	ToggleMounted:DockMargin( 0, 0, 230, -20 )
	ToggleMounted.DoClick = function() self:ToggleSelected() end

	local EnableSelection = Categories:Add("DButton")
	self.EnableSelection = EnableSelection
	EnableSelection:Dock( TOP )
	EnableSelection:SetText( "#Enable Selected" )
	EnableSelection:SetTall( 20 )
	EnableSelection:DockMargin( 120, 0, 110, -20 )
	EnableSelection.DoClick = function() self:EnableSelected() end

	local DisableSelection = Categories:Add("DButton")
	self.DisableSelection = DisableSelection
	DisableSelection:Dock( TOP )
	DisableSelection:SetText( "#Disable Selected" )
	DisableSelection:SetTall( 20 )
	DisableSelection:DockMargin( 240, 0, 0, 10 )
	DisableSelection.DoClick = function() self:DisableSelected() end

	--[[ ------------------------------------------------------------------------- ]]
	--[[ ------------------------------------------------------------------------- ]]

	local OpenWorkshop = Categories:Add("DButton")
	OpenWorkshop:Dock( TOP )
	OpenWorkshop:SetText( "#Open Workshop" )
	OpenWorkshop:SetTall( 30 )
	OpenWorkshop:DockMargin( 0, 20, 0, 0 )
	OpenWorkshop.DoClick = steamworks.OpenWorkshop

	local ApplyAddonChanges = Categories:Add("DButton")
	ApplyAddonChanges:Dock( TOP )
	ApplyAddonChanges:SetText( "#Apply Addon Changes" )
	ApplyAddonChanges:SetTall( 30 )
	ApplyAddonChanges:DockMargin( 0, 5, 0, 0 )
	ApplyAddonChanges.DoClick = function() 
		PANEL.anyAddonChanged = false
		steamworks.ApplyAddons()
	end

	local delyeet = Categories:Add("DButton")
	delyeet:Dock( TOP )
	delyeet:SetText( "#Uninstall Selected" )
	delyeet:SetTall( 30 )
	delyeet:DockMargin( 0, 10, 0, 0 )
	delyeet.DoClick = function() 
		self:UninstallSelected()
	end
	self.UninstallSelectedButton = delyeet

	------------------- Addon List

	local Scroll = self:Add("DScrollPanel")
	Scroll:Dock( FILL )
	Scroll:DockMargin( 5, 5, 5, 5 )
	function Scroll:Paint( w, h )
		draw.RoundedBoxEx( 4, 0, 0, w, h, BackgroundColor, false, true, false, true )
		draw.RoundedBoxEx( 4, 0, 0, w, h, BackgroundColor2, false, true, false, true )
	end
	PANEL.Scroll = Scroll
	self.Scroll = Scroll

	local AddonList = Scroll:Add("DIconLayout")
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

	local AddonList = self.AddonList
	AddonList:Clear()

	local grp = self.Groups:GetOptionData( self.Groups:GetSelectedID() )
	local filter = self.Filters:GetOptionData( self.Filters:GetSelectedID() )
	local sort = self.Sorts:GetOptionData( self.Sorts:GetSelectedID() )
	local AddonFilter = AddonFilters[filter]
	local addons = Grouping[ grp ].func(AddonFilter.GetAddons and AddonFilter.GetAddons() or engine.GetAddons())

	for id, group in SortedPairsByMemberValue( addons, "title" ) do
		if ( #group.addons < 1 ) then continue end

		local addns = {}
		for k, mod in pairs( group.addons ) do
			if ( (searchQuery and mod.title and not mod.title:lower():find(searchQuery) )
				or not AddonFilter.func(mod) ) then 
				continue
			end
			table.insert( addns, mod )
		end

		if ( #addns < 1 ) then continue end

		if ( group.title ) then
			local pnl = AddonList:Add( "DLabel" )
			pnl.OwnLine = true
			pnl:SetFont( "rb655_AddonName" )
			pnl:SetText( group.title )
			pnl:SetDark( true )
			pnl:SizeToContents()
		end

		for k, mod in SortedPairsByMemberValue( addns, Sorting[sort].id ) do

			local pnl = AddonList:Add( "MenuAddon" )
			pnl.panel = self
			pnl:SetAddon( mod )
			pnl:DockMargin( 0, 0, 5, 5 )

		end

	end

end

vgui.Register( "AddonsPanel", PANEL, "EditablePanel" )
