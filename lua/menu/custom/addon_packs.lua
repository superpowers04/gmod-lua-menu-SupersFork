
if(!file.IsDir('addon_packs_smmenu','DATA')) then file.CreateDir('addon_packs_smmenu') end
local PANEL = {}
local searchQuery = nil

function PANEL:Init()
	self:Dock( FILL )
	local Options = vgui.Create( "DListLayout", self )
	Options:DockPadding( 5, 200, 5, 5 )
	Options:Dock( LEFT )
	Options:SetWide( 200 )
	self.Options = Options


	local searchBar = vgui.Create( "DFancyTextEntry", Options, 'searchBar')
	searchBar:Dock( TOP )
	searchBar:SetFont( "DermaRobotoDefault" )
	searchBar:SetPlaceholderText( "searchbar_placeholer" )
	searchBar:SetText(searchQuery or "")
	searchBar:DockMargin( 0, 0, 0, 50 )
	searchBar:SetUpdateOnType( true )
	searchBar.OnValueChange = function() 
		searchQuery = searchBar:GetText():lower()
		if( searchQuery == "" ) then searchQuery = nil end
		self:RegenerateList()
	end


	local FilenameBar = vgui.Create( "DFancyTextEntry", Options, 'FilenameBar')
	FilenameBar:Dock( TOP )
	FilenameBar:SetFont( "DermaRobotoDefault" )
	FilenameBar:SetPlaceholderText( "filename" )
	FilenameBar:DockMargin( 0, 40, 0, 0 )
	self.FilenameBar = FilenameBar

	local SavePackButton = vgui.Create( "DButton", Options, 'SavePackButton')
	SavePackButton:Dock( TOP )
	SavePackButton:SetText( "#Save addon pack" )
	-- SavePackButton:DockMargin( 0, 50, 0, 0 )
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

	--[[ --]] 

	local Scroll = vgui.Create( "DScrollPanel", self )
	Scroll:Dock( FILL )
	Scroll:DockMargin( 30, 5, 5, 5 )

	self.Scroll = Scroll


	self:RegenerateList()

end
function PANEL:savePack(path)
	if(!path:EndsWith('.txt')) then
		path = path..'.txt'
	end
	local mods = {}
	for _, addon in pairs( engine.GetAddons() ) do
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
		for _, addon in pairs( engine.GetAddons() ) do
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
	if(self.list) then
		List:Clear()
		List:Remove()
	end
	List = vgui.Create( "DListLayout", self.Scroll, "packlist")
	List:Dock( FILL )
	self.List = List

	local f = file.Find( "addon_packs_smmenu/*.txt", "DATA", "datedesc" )

	if(table.Count(f) == 0) then

		local ErrorButton = vgui.Create( "DButton" , List ) -- This is honestly stupid but other issues are more important
		ErrorButton:Dock( TOP )
		ErrorButton:SetText( "#No packs found" )
		ErrorButton:SetTall( 30 )
		ErrorButton:SetWide( 30 )
		ErrorButton:DockMargin( 0, 50, 0, 0 )
		
		return
	end

	for k, v in pairs( f ) do
		if(searchQuery && !v:lower():find(searchQuery)) then continue end
		local ListItem = vgui.Create( "DButton" , List, 'button-'..v)
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

function PANEL:Paint( w, h )
	surface.SetDrawColor( 0, 0, 0, 150 )
	surface.DrawRect( 0, 0, w, h )
end

vgui.Register( "AddonPacksPanel", PANEL, "EditablePanel" )
