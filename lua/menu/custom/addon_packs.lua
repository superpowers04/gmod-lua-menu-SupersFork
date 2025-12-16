
if(!file.IsDir('addon_packs_smmenu','DATA')) then file.CreateDir('addon_packs_smmenu') end
local searchQuery = nil

local PANEL = {}
function PANEL:Init()
	self:Dock( FILL )
	local Options = self:Add("Panel")
	Options:DockPadding( 5, 200, 5, 5 )
	Options:Dock( LEFT )
	Options:SetWide( 200 )
	self.Options = Options


	local searchBar = Options:Add( "DFancyTextEntry")
	searchBar:Dock( TOP )
	searchBar:SetFont( "DermaRobotoDefault" )
	searchBar:SetPlaceholderText( "searchbar_placeholer" )
	searchBar:SetText(searchQuery or "")
	searchBar:DockMargin( 0, 0, 0, 0 )
	searchBar:SetZPos( -1 )
	searchBar:SetHeight( 24 )
	searchBar:SetUpdateOnType( true )
	searchBar.OnValueChange = function() 
		searchQuery = searchBar:GetText():lower()
		if( searchQuery == "" ) then searchQuery = nil end
		self:RegenerateList()
	end


	local FilenameBar = Options:Add( "DFancyTextEntry")
	FilenameBar:Dock( TOP )
	FilenameBar:SetFont( "DermaRobotoDefault" )
	FilenameBar:SetPlaceholderText( "filename" )
	FilenameBar:SetZPos( -1 )
	FilenameBar:SetHeight( 24 )
	FilenameBar:DockMargin( 0, 0, 0, 20 )
	self.FilenameBar = FilenameBar

	local SavePackButton = Options:Add( "DButton")
	SavePackButton:Dock( TOP )
	SavePackButton:SetText( "#Save addon pack" )
	SavePackButton:SetHeight( 24 )
	SavePackButton:SetZPos( -1 )
	SavePackButton:DockMargin( 0, 0, 0, 20 )
	SavePackButton.DoClick = function() 
		local filename = FilenameBar:GetText()
		if(filename == "") then
			filename = "untitled_pack"
			local index = 1
			while file.Exists('addon_packs_smmenu/'..filename..index..'.txt','MOD') do
				index = index + 1
			end
			filename = filename..index
		end
		self:savePack(filename:lower())
	end
	self.SavePackButton = SavePackButton

	local Scroll = self:Add("DScrollPanel")
	Scroll:Dock( FILL )
	Scroll:DockMargin( 20, 5, 5, 5 )

	self.Scroll = Scroll
	List = vgui.Create( "DListLayout", self.Scroll, "packlist")
	List:Dock( FILL )
	self.List = List
	self:RegenerateList()
end

vgui.Register( "AddonPacksPanel", PANEL, "EditablePanel" )



function PANEL:savePack(path)
	if(!path:EndsWith('.txt')) then
		path = path..'.txt'
	end
	local mods = {}
	for _, addon in pairs(engine.GetAddons()) do
		if( steamworks.ShouldMountAddon( addon.wsid ) ) then
			mods[#mods+1] = addon.wsid .. " ".. addon.title
		end
	end

	file.Write("addon_packs_smmenu/" .. path, '\n'..table.concat(mods,'\n') )
	print('Saved to ' .. "addon_packs_smmenu/" .. path)
	self:RegenerateList()
end
function PANEL:selectPack(path, state, only, subscribe)
	local contents = file.Read("addon_packs_smmenu/" .. path,'DATA')
	local state = (state == nil and true) or (state and true or false)

	if(only) then
		for _, addon in pairs(engine.GetAddons()) do
			steamworks.SetShouldMountAddon( addon.wsid, false )
		end
	end
	if(subscribe) then
		for id in contents:gmatch('\n([^ ]+)') do
			steamworks.Subscribe(id)
		end
	end
	for id in contents:gmatch('\n([^ ]+)') do
		steamworks.SetShouldMountAddon( id, state)
	end
	steamworks.ApplyAddons() 
	self:GetParent():OpenAddonPacksMenu()
end

function PANEL:RegenerateList()

	local List = self.List
	List:Clear()
	

	local f = file.Find( "addon_packs_smmenu/*.txt", "DATA", "datedesc" )

	if(table.Count(f) == 0) then

		local ErrorButton = List:Add("DButton") -- This is honestly stupid but other issues are more important
		ErrorButton:SetText("#No packs found")
		ErrorButton:SetTall(30)
		ErrorButton:SetWide(30)
		ErrorButton:DockMargin(0, 300, 0, 0)
		
		return
	end

	for k, v in pairs(f) do
		if(searchQuery && !v:lower():find(searchQuery)) then continue end
		local ListItem = List:Add("DButton")
		ListItem:SetText( v:StripExtension() )
		ListItem.DoDoubleClick = function()
			select(v)
		end
		-- ListItem.DoClick = function()
		-- 	self.FilenameBar:SetText(v:StripExtension())
		-- end
		ListItem.DoRightClick = function()
			local m = DermaMenu()
			m:AddOption("Enable only pack", function()
				self:selectPack(v, true, true)
			end)
			m:AddOption("Enable pack", function()
				self:selectPack(v, true, false)
			end)
			m:AddOption("Disable pack", function()
				self:selectPack(v, false)
			end)
			m:AddSpacer()
			m:AddOption("Subscribe+Enable pack", function()
				self:selectPack(v, true, false, true)
			end)
			m:AddSpacer()
			m:AddOption( "Delete", function()
				file.Delete( "addon_packs_smmenu/" .. v, "DATA" )
				self:RegenerateList()
			end )
			m:AddOption( "Overwrite", function()
				self:savePack(v)
			end )
			m:AddOption( "Cancel" )
			m:Open()
		end
		ListItem.DoClick = ListItem.DoRightClick
	end
end

