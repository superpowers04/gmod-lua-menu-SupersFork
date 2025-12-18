
local ADDON_PACKS_PATH = "addon_packs_smmenu/"
if(!file.IsDir(ADDON_PACKS_PATH,'DATA')) then file.CreateDir(ADDON_PACKS_PATH) end


surface.CreateFont( "rb655_AddonDesc", {
	size = ScreenScale( 8 ),
	font = "Tahoma"
} )

local FGColor = Color( 256, 256, 256, 256 )
local BackgroundColor = Color( 200, 200, 200, 128 )
local BackgroundColor2 = Color( 200, 200, 200, 255 ) --Color( 0, 0, 0, 100 )
local BackgroundColor3 = Color( 130, 130, 130, 255 ) --Color( 0, 0, 0, 100 )
local searchQuery = nil
local PANEL = {}
local currentPanel = nil


local iconCache = {}
local missingMat = Material("../html/img/addonpreview.png", "nocull smooth")
local lastBuild = 0
local selectedColor = Color(0, 150, 255, 255)

local Addon_Pack_Object = {
	Init = function(self)
		self:SetTall( 200 )
		self:SetWide( 200 )
	end,
	SetFile = function(self, _file)
		self.file = _file
		self.name = _file:StripExtension()
		self:UpdateIcon()
	end,
	OnMouseReleased = function(self, mousecode)
		if(mousecode == MOUSE_LEFT) then return self:DoClick() end
		if(mousecode == MOUSE_RIGHT) then return self:DoRightClick() end
	end,
	DoClick = function(self)

		currentPanel.PackName:SetText('Contents of '..self.file:StripExtension()..':')
		currentPanel.PackText:SetBGColor(BackgroundColor3)
		currentPanel.PackText:SetFGColor(FGColor)
		currentPanel.PackText:SetText(file.Read(ADDON_PACKS_PATH .. self.file,'DATA'))
		currentPanel.PackText:GotoTextStart()
		currentPanel.selectedPack = self
		currentPanel.EnableButton:SetDisabled(false)
		currentPanel.EnableOnlyButton:SetDisabled(false)
		currentPanel.DisablePackButton:SetDisabled(false)
	end,
	-- DoDoubleClick = function(self)
		-- select(v)
	-- end,

	selectPack = function(self, state, only, subscribe)
		local path = self.file
		local contents = file.Read(ADDON_PACKS_PATH .. path,'DATA')
		local state = (state == nil and true) or (state and true or false)

		if(only) then
			for _, addon in pairs(engine.GetAddons()) do
				steamworks.SetShouldMountAddon( addon.wsid, false )
			end
		end
		if(subscribe) then
			for id in contents:gmatch('\n(%d+)') do
				steamworks.Subscribe(id)
			end
		end
		for id in contents:gmatch('\n(%d+)') do
			steamworks.SetShouldMountAddon( id, state)
		end
		steamworks.ApplyAddons() 
		self:GetParent():OpenAddonPacksMenu()
	end,
	DoRightClick = function(self)
		local m = DermaMenu()
		m:AddOption("Enable only pack", function()
			self:selectPack(true, true)
		end)
		m:AddOption("Enable pack", function()
			self:selectPack(true, false)
		end)
		m:AddOption("Disable pack", function()
			self:selectPack(false)
		end)
		m:AddSpacer()
		m:AddOption("Subscribe+Enable pack", function()
			self:selectPack(true, false, true)
		end)
		m:AddSpacer()
		m:AddOption( "Delete", function()
			file.Delete( ADDON_PACKS_PATH .. self.file, "DATA" )
			self:RegenerateList()
		end )
		m:AddOption( "Overwrite", function()
			self:savePack(self.file)
		end )
		m:AddOption( "Cancel" )
		m:Open()
	end,
	_loadImage = function(self)
		local curtime = CurTime()
		if(curtime - lastBuild < 0.02) then return true end
		self.Image = AddonMaterial(self.imgpath)
		self.imgpath = nil
		iconCache[self.file] = self.Image
		lastBuild = curtime
		
	end,
	UpdateIcon = function(self)
		if (iconCache[self.file]) then
			self.Image = iconCache[self.file]
			return
		end
		self.imgpath = 'data/'..ADDON_PACKS_PATH..self.file:StripExtension()..".icon"
		if file.Exists(self.imgpath, "DATA" ) then
			self.queuedAction = self._loadImage
			return
		end
		self.imgpath = 'data/'..ADDON_PACKS_PATH..self.file:StripExtension()..".png"
		if file.Exists(self.imgpath, "DATA" ) then
			self.queuedAction = self._loadImage
			return
		end
		self.imgpath = nil
	end,
	Paint = function(self, w, h )
		-- if ( IsValid(self.DermaCheckbox) ) then
		-- 	self.DermaCheckbox:SetVisible( self.Hovered or self.DermaCheckbox.Hovered or self:GetSelected() )
		-- end
		if ( currentPanel.selectedPack == self ) then
			draw.RoundedBox( 4, 0, 0, w, h, selectedColor )
		end
		
		surface.SetMaterial(self.Image or missingMat)
		local tall,wide = 200,200
		local imageSize = tall - 10
		surface.SetDrawColor(color_white)
		surface.DrawTexturedRect( 5, 5, imageSize, imageSize )

		--[[if ( self.Addon and !steamworks.ShouldMountAddon( self.Addon.wsid ) ) then
			draw.RoundedBox( 4, 0, 0, w, h, Color( 0, 0, 0, 180 ) )
		end]]

		if ( self.Hovered ) then
			draw.RoundedBox( 0, 5, h - 20, w - 10, 15, Color( 0, 0, 0, 180 ) )
		end
		local title = self.name or "N/A"
		local tw = surface.GetTextSize( title )
		local offset = 0
		if ( tw > w ) then
			offset=( ( w - tw ) * math.sin( CurTime() ) )
		end
		draw.SimpleText( title, "DEFAULT", w / 2 - tw / 2 + offset, h - 18, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
		if self.queuedAction and not self:queuedAction() then
			self.queuedAction=nil
		end
	end

}

vgui.Register( "MenuAddonPack", Addon_Pack_Object, "Panel" )



function PANEL:Init()
	currentPanel = self
	self:Dock( FILL )
	local Options = self:Add("Panel")
	Options:DockPadding( 5, 5, 5, 5 )
	Options:Dock( RIGHT )
	Options:SetWide( 350 )
	self.Options = Options


	local PackName = Options:Add("DLabel")
	PackName:SetText('N/A')
	PackName:SetFont('rb655_AddonDesc')
	PackName:Dock( TOP )
	PackName:DockMargin( 0, 20, 0, 20 )
	self.PackName = PackName

	local PackText = Options:Add("RichText")
	PackText:Dock( TOP )
	PackText:SetTall( 300 )
	PackText:DockMargin( 0, 20, 0, 20 )

	self.PackText = PackText
	----


	local EnablePack = Options:Add("DButton")
	self.EnableButton = EnablePack
	EnablePack:Dock( TOP )
	EnablePack:SetText( "#Enable+Sub Pack" )
	EnablePack:SetTall( 20 )
	EnablePack:DockMargin( 0, 0, 230, -20 )
	EnablePack.DoClick = function() self:SelectAll() end
	EnablePack:SetDisabled(true)

	local EnableOnlyPack = Options:Add("DButton")
	self.EnableOnlyButton = EnableOnlyPack
	EnableOnlyPack:Dock( TOP )
	EnableOnlyPack:SetText( "#Enable Only pack" )
	EnableOnlyPack:SetTall( 20 )
	EnableOnlyPack:DockMargin( 120, 0, 110, -20 )
	EnableOnlyPack.DoClick = function() self.selectedPack:selectPack(true,true) end
	EnableOnlyPack:SetDisabled(true)

	local DisablePack = Options:Add("DButton")
	self.DisablePackButton = DisablePack
	DisablePack:Dock( TOP )
	DisablePack:SetText( "#Disable Pack" )
	DisablePack:SetTall( 20 )
	DisablePack:DockMargin( 240, 0, 0, 10 )
	DisablePack.DoClick = function() self.selectedPack:selectPack(false) end
	DisablePack:SetDisabled(true)


	---

	local searchBar = Options:Add( "DTextEntry")
	searchBar:Dock( TOP )
	searchBar:SetPlaceholderText( "searchbar_placeholder" )
	searchBar:SetText(searchQuery or "")
	searchBar:DockMargin(0, 20, 0, 0)
	searchBar:SetHeight( 24 )
	searchBar:SetUpdateOnType( true )
	searchBar.OnValueChange = function() 
		searchQuery = searchBar:GetText():lower()
		if(searchQuery == "") then searchQuery = nil end
		self:RegenerateList()
	end


	local FilenameBar = Options:Add( "DTextEntry")
	FilenameBar:Dock( TOP )
	FilenameBar:SetPlaceholderText( "filename" )
	FilenameBar:SetHeight(24)
	FilenameBar:DockMargin(0, 40, 0, 0)
	self.FilenameBar = FilenameBar

	local SavePackButton = Options:Add( "DButton")
	SavePackButton:Dock( TOP )
	SavePackButton:SetText( "#Save addon pack" )
	SavePackButton:SetHeight(24)
	SavePackButton:DockMargin(0, 10, 0, 0)
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
	-----

	local Scroll = self:Add("DScrollPanel")
	Scroll:DockMargin( 5, 5, 5, 5 )
	Scroll:Dock( FILL )
	function Scroll:Paint( w, h )
		draw.RoundedBoxEx( 4, 0, 0, w, h, BackgroundColor, false, true, false, true )
		draw.RoundedBoxEx( 4, 0, 0, w, h, BackgroundColor2, false, true, false, true )
	end

	self.Scroll = Scroll
	local List = Scroll:Add("DIconLayout")
	List:DockMargin( 5, 5, 5, 5 )
	List:Dock( FILL )
	self.List = List
	self:RegenerateList()
end

vgui.Register( "AddonPacksPanel", PANEL, "EditablePanel" )



function PANEL:savePack(path)
	if(not path:EndsWith('.txt')) then
		path = path..'.txt'
	end
	local mods = {}
	for _, addon in pairs(engine.GetAddons()) do
		if( steamworks.ShouldMountAddon( addon.wsid ) ) then
			mods[#mods+1] = addon.wsid .. " ".. addon.title
		end
	end

	file.Write(ADDON_PACKS_PATH .. path, 'ID - NAME\n'..table.concat(mods,'\n') )
	print('Saved to ' .. ADDON_PACKS_PATH .. path)
	self:RegenerateList()
end

function PANEL:RegenerateList()

	local List = self.List
	List:Clear()
	

	local f = file.Find( "addon_packs_smmenu/*.txt", "DATA", "datedesc" )

	if(#f == 0) then

		local ErrorButton = List:Add("DButton") -- This is honestly stupid but other issues are more important
		ErrorButton:SetText("#No packs found")
		ErrorButton:SetTall(30)
		ErrorButton:SetWide(30)
		ErrorButton:DockMargin(0, 300, 0, 0)
		return
	end

	for k, v in pairs(f) do
		if(searchQuery && !v:lower():find(searchQuery)) then continue end
		local ListItem = List:Add("MenuAddonPack")
		ListItem:SetFile(v)
	end
end

