--###########################################
--Frame Generation


--AzeriteEmpoweredItemUI.BorderFrame.portrait
local FOLDER_NAME, private = ...
local TextDump = LibStub("LibTextDump-1.0")
AzeriteForge = LibStub("AceAddon-3.0"):GetAddon("AzeriteForge")
local L = LibStub("AceLocale-3.0"):GetLocale("AzeriteForge")
AzeriteForgeMiniMap = LibStub("LibDBIcon-1.0")
local AF = AzeriteForge
AF.Buttons = {}
local AceGUI = LibStub("AceGUI-3.0")
local buttons = AF.Buttons
AF.powerLocationButtonIDs = {}
local powerLocationButtonIDs = AF.powerLocationButtonIDs
AF.UnselectedPowers = {}
local UnselectedPowers = AF.UnselectedPowers
local BagScrollFrame
local locationIDs = {["Head"] = 1, ["Shoulder"] = 3, ["Chest"] = 5,}
local azeriteIcon = "Interface/Icons/Inv_smallazeriteshard"

local AzeriteLocations = {["Head"] = ItemLocation:CreateFromEquipmentSlot(1),
			["Shoulder"] = ItemLocation:CreateFromEquipmentSlot(3), 
			["Chest"]= ItemLocation:CreateFromEquipmentSlot(5),
			[1] = "Head",
			[3] = "Shoulder",
			[5] = "Chest",}




local function addFramesToAzeriteEmpoweredItemUI()
	local f = CreateFrame("Frame",nil,AzeriteEmpoweredItemUI)
	f:SetFrameStrata("DIALOG")
	f:ClearAllPoints()
	f:SetPoint("TOPRIGHT", AzeriteEmpoweredItemUI.BorderFrame.portrait, "TOPRIGHT",0,0)
	f:SetPoint("BOTTOMLEFT", AzeriteEmpoweredItemUI.BorderFrame.portrait, "BOTTOMLEFT",0,0)
	f:Show()

	local AzeriteLevel = f:CreateFontString("AZF_Level", "DIALOG", "GameFontNormalHuge3Outline")
	AzeriteLevel:SetTextColor(HIGHLIGHT_FONT_COLOR:GetRGB())
	AzeriteLevel:ClearAllPoints()
	AzeriteLevel:SetPoint("CENTER", AzeriteEmpoweredItemUI.BorderFrame.portrait, "CENTER",0,0)
	AzeriteLevel:SetText(currentLevel)
	f:SetScript("OnShow", function() AzeriteLevel:SetText(currentLevel)  end)
	f:SetToplevel(true)
	f:SetScript("OnEnter", function()

		GameTooltip:SetOwner(f, "ANCHOR_RIGHT");
		AF.BuildAzeriteInfoTooltip(GameTooltip)
		GameTooltip:Show();
	end)

	f:SetScript("OnLeave", function()GameTooltip:Hide() end)

--todo  ADD ITEM RANK INFO/DATA

end


local function CreateGenericFrame(name, parent)
	local window = CreateFrame("Frame", (name or nil), (parent or UIParent), "InsetFrameTemplate")
	window:Hide()

	window:SetFrameStrata("DIALOG")
	window:SetWidth(500)
	window:SetHeight(100)
	window:SetPoint("CENTER")
	window:SetMovable(false)
	window:EnableMouse(true)
	window:RegisterForDrag("LeftButton")
	window:SetScript("OnShow", function()
		PlaySound(844) -- SOUNDKIT.IG_QUEST_LOG_OPEN
	end)

	window:SetScript("OnHide", function()
		PlaySound(845) -- SOUNDKIT.IG_QUEST_LOG_CLOSE
	end)

	local titlebg = window:CreateTexture(nil, "BORDER")
	titlebg:SetTexture("Interface\\PaperDollInfoFrame\\UI-GearManager-Title-Background") --
	titlebg:SetPoint("TOPLEFT", 9, -6)
	titlebg:SetPoint("BOTTOMRIGHT", window, "TOPRIGHT", -28, -24)

	local title = window:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	title:SetPoint("CENTER", titlebg, -6, -3)
	title:SetTextColor(1, 1, 1, 1)
	window.title = title

	

	local close = CreateFrame("Button", nil, window, "UIPanelCloseButton")
	close:SetPoint("TOPRIGHT", 2, 1)
	close:SetScript("OnClick", function() window:Hide() end)
	window.close = close

	return window
end


function AF:CreateImportFrame()
	local window = CreateGenericFrame()
	window.title:SetText("AzeriteForge "..L["Import"])

	local content = CreateFrame("Frame",nil, window)
	content:SetPoint("TOPLEFT",15,-35)
	content:SetPoint("BOTTOMRIGHT",-15,15)
	--This creats a cusomt AceGUI container which lets us imbed a AceGUI menu into our frame.
	local widget = {
		frame     = window,
		content   = content,
		type      = "AzForgeContainer"
	}

	widget["OnRelease"] = function(self)
		self.status = nil
		wipe(self.localstatus)
	end


	AceGUI:RegisterAsContainer(widget)
	widget:SetLayout("List")

	local textField = AceGUI:Create("EditBox")
	textField:SetText("")
	textField:SetRelativeWidth(1)
	widget:AddChild(textField)

	local btn = AceGUI:Create("Button")
	btn:SetWidth(100)
	btn:SetText(L["Import"])
	btn:SetCallback("OnClick", function() AF:ImportData(textField:GetText()) end)

	widget:AddChild(btn)
	btn:ClearAllPoints()
	btn:SetPoint( "TOPRIGHT", 0,-25)
	window:SetScript("OnShow", function () textField:SetText("") end)
	AzeriteForge.ImportWindow = window

end

--AzeriteEmpoweredItemUI
local function CreateBagInfoFrame()
	local window = CreateGenericFrame ("AzeriteForgeItemFrame", AzeriteEmpoweredItemUI)
	
	window:ClearAllPoints()
	window:SetPoint("TOPLEFT", AzeriteEmpoweredItemUI, "TOPLEFT",-5,-20)
	window:SetPoint("BOTTOMRIGHT", AzeriteEmpoweredItemUI,"BOTTOMRIGHT")
	window:SetParent(UIParent)
	window.title:SetText(L["Azerite Gear"])
	window:SetScript("OnShow", function(self)
		buttons.inventoryButton:LockHighlight()
			AF:UpdateBagDataMenu("")

		end)

	window:SetScript("OnHide", function(self)
		buttons.inventoryButton:UnlockHighlight()
		end)

	local content = CreateFrame("Frame",nil, window)
	content:SetPoint("TOPLEFT",15,-35)
	content:SetPoint("BOTTOMRIGHT",-15,15)

	AzeriteForge.Bag = window

	--This creats a cusomt AceGUI container which lets us imbed a AceGUI menu into our frame.
	local widget = {
		frame     = window,
		content   = content,
		type      = "AzForgeContainer"
	}
	widget["OnRelease"] = function(self)
		self.status = nil
		wipe(self.localstatus)
	end
	AceGUI:RegisterAsContainer(widget)
	widget:SetLayout("Fill")
	AzeriteForge.Bag.widget= widget
	local scroll = AceGUI:Create("ScrollFrame")
	scroll:SetLayout("List")
	widget:AddChild(scroll)

	BagScrollFrame = scroll
end

local function CreateCharacterFrameTabs()

	local powerWindowButton = CreateFrame("Button", "AF_CharacterPage_Icon" , CharacterFrame, "UIPanelButtonTemplate")

	buttons.powerWindowButton2 = powerWindowButton2
	powerWindowButton2= powerWindowButton
	powerWindowButton:SetNormalTexture(azeriteIcon)
	powerWindowButton:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
	powerWindowButton:SetPoint("TOPLEFT",CharacterFrameTab3, "TOPRIGHT", 0, 0)
	powerWindowButton:SetWidth(27)
	powerWindowButton:SetHeight(27)
	powerWindowButton:SetToplevel(true)
	powerWindowButton.view = "skills"
	powerWindowButton:Hide()

	powerWindowButton:SetFrameLevel(CharacterFrame:GetFrameLevel())
	powerWindowButton:Lower()

	powerWindowButton:SetScript("OnClick", function(self, button, down)
		for equipSlotIndex, itemLocation in AzeriteUtil.EnumerateEquipedAzeriteEmpoweredItems() do
			if C_AzeriteEmpoweredItem.IsAzeriteEmpoweredItem(itemLocation) then
				--Open first azerite item
				AF.ShowEmpoweredItem(itemLocation)

				if CharacterFrame:IsShown() then
					HideUIPanel(CharacterFrame)
				end
			else
				DEFAULT_CHAT_FRAME:AddMessage(L["No Empowered items equipped"])
			end
		end
	end)

	powerWindowButton:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner (self, "ANCHOR_RIGHT")
			GameTooltip:SetText(L["Azerite Power List"], 1, 1, 1)
			GameTooltip:Show()
		end)

	powerWindowButton:SetScript("OnLeave", function()
			GameTooltip:Hide()
		end)

end


--Handlers to add shine to tabs
local maxShines = 4;
local shineGet = {}
local function GetShine (frame)
	local shine = shineGet[1];
	
	if ( shine ) then
		tremove(shineGet, 1);
	else
		shine = CreateFrame("FRAME", "AutocastShine" .. maxShines, frame, "SpellBookShineTemplate");
		maxShines = maxShines + 1;
	end
	return shine;
end


local function ReleaseAutoCastShine (shine)
	if ( not shine ) then
		return;
	end
	shine:Hide();
	AutoCastShine_AutoCastStop(shine);
	tinsert(shineGet, shine);
end


local function ToggleShine(frame, toggle)
	if not frame.shine  then
		frame.shine = GetShine(frame);

	end

	if toggle then 
		frame.shine:Show()
		frame.shine:SetParent(frame)
		frame.shine:SetPoint("CENTER", frame, "CENTER")
		AutoCastShine_AutoCastStart(frame.shine)

	else
		ReleaseAutoCastShine(frame.shine)
		frame.shine = nil;
	end
end


local function ToggleLDBShine(toggle)
	ToggleShine(AzeriteForge.MinimapIcon, toggle)
end


function private.updateLDBShine()
if Config.MMDB.hide then return end

	for location in pairs(UnselectedPowers) do
			if UnselectedPowers[location] and not AzeriteForge.MinimapIcon.shine then 
				ToggleShine(AzeriteForge.MinimapIcon, true)
				--ToggleShine(AzeriteForgeInfoLDB.icon, true)

				
			elseif not UnselectedPowers[location] and AzeriteForge.MinimapIcon.shine then
				ToggleShine(AzeriteForge.MinimapIcon, false)
				--ToggleShine(AzeriteForgeInfoLDB, false)
			end
	end
end


local headTraitsAvailable = false
local chestTraitsAvailable = false
local shoulderTraitsAvalable = false

--Builds Trait Ranking Window
--------
local function CreateAzeriteDataFrame()
---------
--Powers Window
	local f = CreateFrame('Frame', "AzeriteForge_PowersList", UIParent, "InsetFrameTemplate")
	f:SetClampedToScreen(true)
	f:SetSize(250, 160)
	f:SetPoint("TOPLEFT",AzeriteEmpoweredItemUI,"TOPRIGHT")
	f:SetPoint("BOTTOMLEFT",AzeriteEmpoweredItemUI,"BOTTOMRIGHT")
	f:Hide()
	f:EnableMouse(true)
	f:SetFrameStrata('DIALOG')
	f:SetMovable(false)
	f:SetToplevel(true)

	local close_ = CreateFrame("Button", nil, f)
	close_:SetNormalTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up")
	close_:SetPushedTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Down")
	close_:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight", "ADD")
	close_:SetSize(32, 32)
	close_:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)
	close_:SetScript("OnClick", function(self)
		self:GetParent():Hide()
		self:GetParent().free = true
		end)

	f.close = close_

	--f:Show()

	local content = CreateFrame("Frame",nil, f)
	content:SetPoint("TOPLEFT",15,-15)
	content:SetPoint("BOTTOMRIGHT",-15,25)
	--This creats a cusomt AceGUI container which lets us imbed a AceGUI menu into our frame.
	local widget = {
		frame     = f,
		content   = content,
		type      = "AzForgeContainer"
	}

	widget["OnRelease"] = function(self)
		self.status = nil
		wipe(self.localstatus)
		end	

	f:SetScript("OnShow", function(self)
		--LibStub("AceConfigDialog-3.0"):Open("AzeriteForge_Talents", widget, "stats")
		buttons.powerWindowButton:LockHighlight()
		f:SetToplevel(true)
		end)

	f:SetScript("OnHide", function(self)
	buttons.powerWindowButton:UnlockHighlight()
		--f:Hide()
		--RestoreUIPanelArea("CharacterFrame")
		end)

	LibStub("AceGUI-3.0"):RegisterAsContainer(widget)

	widget:SetLayout("Fill")


	AceGUI:RegisterAsContainer(widget)
	widget:SetLayout("Fill")
	local scroll = AceGUI:Create("ScrollFrame")
	scroll:SetLayout("List")
	widget:AddChild(scroll)
	AF.PowerSummaryFrame = widget
	AF.PowerSummaryFrame.scrollFrame = scroll



--Overlay
	local overlay = CreateFrame('Frame', "AzeriteForge_Overlay", UIParent)
	overlay:SetClampedToScreen(true)
	overlay:SetSize(250, 160)
	overlay:SetPoint("TOPLEFT",AzeriteEmpoweredItemUI,"TOPLEFT")
	overlay:SetPoint("BOTTOMRIGHT",AzeriteEmpoweredItemUI,"BOTTOMRIGHT")
	overlay:EnableMouse(true)
	overlay:SetFrameStrata('LOW')
	overlay:SetMovable(false)
	overlay:SetToplevel(true)

	AF:HookScript(AzeriteEmpoweredItemUI, "OnShow", function()  C_Timer.NewTimer(.2, function()f:Show(); overlay:Show() end) end)
	AF:HookScript(AzeriteEmpoweredItemUI, "OnHide", function() f:Hide(); overlay:Hide(); AzeriteForge.Bag:Hide() end)

	local headSlotButton = CreateFrame("Button", "AZ_HeadSlotButton" , overlay)
	buttons.headSlotButton = headSlotButton
	powerLocationButtonIDs[1] = headSlotButton
	headSlotButton:SetNormalTexture("Interface\\Icons\\inv_boot_helm_draenordungeon_c_01")
	headSlotButton:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")

	headSlotButton:SetPoint("TOPLEFT", AzeriteEmpoweredItemUI, "BOTTOMLEFT", 0, 0)
	headSlotButton:SetWidth(45)
	headSlotButton:SetHeight(45)
	headSlotButton:SetScript("OnUpdate", function(self,...)
		if UnselectedPowers["Head"] and not self.shine then 
			ToggleShine(headSlotButton, true)
		elseif not UnselectedPowers["Head"] and self.shine then
			ToggleShine(headSlotButton, false)
		end

		end)

	headSlotButton:SetScript("OnClick", function(self, button, down)
		AF.ShowEmpoweredItem(AzeriteLocations["Head"])
		AzeriteForge.Bag:Hide()

		end)

	headSlotButton:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner (self, "ANCHOR_RIGHT")
			GameTooltip:SetText(L["Head Powers"], 1, 1, 1)
			GameTooltip:Show()

		end)

	headSlotButton:SetScript("OnLeave", function()
			GameTooltip:Hide()
		end)

	local shoulderSlotButton = CreateFrame("Button", nil , overlay)
	buttons.shoulderSlotButton = shoulderSlotButton
	powerLocationButtonIDs[3] = shoulderSlotButton
	shoulderSlotButton:SetNormalTexture("Interface\\Icons\\inv_misc_desecrated_clothshoulder")
	shoulderSlotButton:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
	shoulderSlotButton:SetPoint("LEFT", headSlotButton, "RIGHT", 0, 0)
	shoulderSlotButton:SetWidth(45)
	shoulderSlotButton:SetHeight(45)
	shoulderSlotButton:SetScript("OnClick", function(self, button, down)
		AF.ShowEmpoweredItem(AzeriteLocations["Shoulder"])
		AzeriteForge.Bag:Hide()

	end)

	shoulderSlotButton:SetScript("OnUpdate", function(self,...)
		if UnselectedPowers["Shoulder"] and not self.shine then 
			ToggleShine(shoulderSlotButton, true)
		elseif not UnselectedPowers["Shoulder"] and self.shine then
			ToggleShine(shoulderSlotButton, false)
		end
	end)

	shoulderSlotButton:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner (self, "ANCHOR_RIGHT")
			GameTooltip:SetText(L["Shoulder Powers"], 1, 1, 1)
			GameTooltip:Show()
		end)

	shoulderSlotButton:SetScript("OnLeave", function()
			GameTooltip:Hide()
		end)

	local chestSlotButton = CreateFrame("Button", nil , overlay, MainMenuBarMicroButton)
	buttons.chestSlotButton = chestSlotButton
	powerLocationButtonIDs[5] = chestSlotButton
	chestSlotButton:SetNormalTexture("Interface\\Icons\\inv_chest_chain")
	chestSlotButton:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
	chestSlotButton:SetPoint("LEFT", shoulderSlotButton, "RIGHT", 0, 0)
	chestSlotButton:SetWidth(45)
	chestSlotButton:SetHeight(45)
	chestSlotButton:SetScript("OnClick", function(self, button, down)
		AF.ShowEmpoweredItem(AzeriteLocations["Chest"])
		AzeriteForge.Bag:Hide()
	end)

	chestSlotButton:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner (self, "ANCHOR_RIGHT")
			GameTooltip:SetText(L["Chest Powers"], 1, 1, 1)
			GameTooltip:Show()
		end)
	chestSlotButton:SetScript("OnLeave", function()
			GameTooltip:Hide()
		end)
	chestSlotButton:SetScript("OnUpdate", function(self,...)
		if UnselectedPowers["Chest"] and not self.shine then 
			ToggleShine(chestSlotButton, true)
		elseif not UnselectedPowers["Chest"] and self.shine then
			ToggleShine(chestSlotButton, false)
		end
	end)

	local powerWindowButton = CreateFrame("Button", nil , overlay)
	buttons.powerWindowButton = powerWindowButton
	powerWindowButton:SetNormalTexture(azeriteIcon)
	powerWindowButton:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
	powerWindowButton:SetPoint("LEFT", chestSlotButton, "RIGHT", 0, 0)
	powerWindowButton:SetWidth(45)
	powerWindowButton:SetHeight(45)
	powerWindowButton:SetFrameStrata('DIALOG')
	powerWindowButton:SetToplevel(true)
	powerWindowButton.view = "skills"
	powerWindowButton:SetScript("OnHide", function() powerWindowButton.view = "skills" end)

	powerWindowButton:SetScript("OnClick", function(self, button, down)
		local Shift = IsShiftKeyDown()
		if Shift then
			LibStub("AceConfigDialog-3.0"):Open("AzeriteForge", "weights")

		else
			if f:IsShown() then
				f:Hide()	
			else
				--LibStub("AceConfigDialog-3.0"):Open("AzeriteForge_Talents", widget, "stats")
				f:Show()
			end
		end

		end)

	powerWindowButton:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner (self, "ANCHOR_RIGHT")
			GameTooltip:SetText(L["Azerite Power List"], 1, 1, 1)
			GameTooltip:Show()
		end)

	powerWindowButton:SetScript("OnLeave", function()
			GameTooltip:Hide()
		end)

	local characterButton = CreateFrame("Button", nil , overlay,MainMenuBarMicroButton)
	buttons.characterButton = characterButton
	characterButton:SetNormalTexture(azeriteIcon)
	characterButton.texture = characterButton:CreateTexture("AZF_CharacterButton_Texture", "OVERLAY")
	characterButton:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
	characterButton.texture:SetAllPoints()
	characterButton.texture:SetColorTexture(1, 1, 1, 0.5)
	SetPortraitTexture(characterButton.texture, "player")

	characterButton:SetPoint("LEFT", powerWindowButton, "RIGHT", 0, 0)
	characterButton:SetWidth(45)
	characterButton:SetHeight(45)
	characterButton:SetScript("OnClick", function(self, button, down)
			ToggleCharacter("PaperDollFrame")
		end)
	characterButton:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner (self, "ANCHOR_RIGHT")
			GameTooltip:SetText(L["Toggle Character Info"], 1, 1, 1)
			GameTooltip:Show()
		end)
	characterButton:SetScript("OnLeave", function()
			GameTooltip:Hide()
		end)
	
	local inventoryButton = CreateFrame("Button", nil , overlay)
	buttons.inventoryButton = inventoryButton
	inventoryButton:SetNormalTexture("Interface\\Icons\\inv_tailoring_hexweavebag")
	inventoryButton:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
	inventoryButton:SetPoint("LEFT", characterButton, "RIGHT", 0, 0)
	inventoryButton:SetWidth(45)
	inventoryButton:SetHeight(45)
	inventoryButton:SetScript("OnClick", function(self, button, down)
		if AzeriteForge.Bag:IsShown() then
			AzeriteForge.Bag:Hide()
		else
			AzeriteForge.Bag:Show()
		end
		end)

	inventoryButton:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner (self, "ANCHOR_RIGHT")
			GameTooltip:SetText(L["Azerite Items in Bag"], 1, 1, 1)
			GameTooltip:Show()
		end)

	inventoryButton:SetScript("OnLeave", function()
			GameTooltip:Hide()
		end)
end


--Creates all needed frames
function AF:CreateFrames()
	addFramesToAzeriteEmpoweredItemUI()
	AF:CreateImportFrame()
	CreateCharacterFrameTabs()
	CreateAzeriteDataFrame()
	CreateBagInfoFrame()
end


local function findInventoryLocation(itemLink)
	for i = 0, NUM_BAG_SLOTS do
		for j = 1, GetContainerNumSlots(i) do
			local _, _, _, _, _, _, bagItemLink = GetContainerItemInfo(i, j);
			if itemLink == bagItemLink then 
				return i, j
			end
		end
	end
	return false
end


local function createItemLocation(itemLink)
	local bag, slot = findInventoryLocation(itemLink)

	if bag then 
		return ItemLocation:CreateFromBagAndSlot(bag, slot)

	else
		for x,y in pairs (locationIDs) do
			local inventoryItemLink = GetInventoryItemLink("player", y)
			if inventoryItemLink == itemLink then 
			
				return ItemLocation:CreateFromEquipmentSlot(y)
			end
		end
	end

	return false
end

function AF.createItemLocation(itemLink)
	return createItemLocation(itemLink)
end


local itemDB={}

local function bagScan()
	wipe(itemDB)
	for i = 0, NUM_BAG_SLOTS do
		for j = 1, GetContainerNumSlots(i) do
			local _, _, _, _, _, _, link = GetContainerItemInfo(i, j);
			--print(link)
			local itemName = GetItemInfo(link or "")
			if itemName and C_AzeriteEmpoweredItem.IsAzeriteEmpoweredItemByID(itemName) then 
			itemDB[link] = itemName
			end
		end
	end

end


function AF:UpdateBagDataMenu(filter, filterLocation)
	filterLocation = filterLocation or ""
	local filterText = filter or ""
	local count = 0
	local sortTable = {}
	--local guiMenu = talent_options.args.bagData.args
	--wipe(guiMenu)
	AceGUI:Release(BagScrollFrame)

	local scroll = AceGUI:Create("ScrollFrame")
	scroll:SetLayout("Flow")
	AzeriteForge.Bag.widget:AddChild(scroll)

	local searchBar = AceGUI:Create("EditBox")
	searchBar:SetRelativeWidth(.7)
	searchBar:SetText(filterText)
	--searchBar:SetCallback("OnTextChanged", function(self) TextChanged(self) end)
	searchBar:SetCallback("OnEnterPressed", function(self) 	
		filterText = string.lower(self:GetText())
		AF:UpdateBagDataMenu(filterText) 
	end)
	BagScrollFrame:AddChild(searchBar)

	local resetButton = AceGUI:Create("Button")
	resetButton:SetRelativeWidth(.3)
	resetButton:SetText(L["Reset"])
	resetButton:SetCallback("OnClick", function(self)
		filterText = string.lower("")
		AF:UpdateBagDataMenu("")
	 end)

	BagScrollFrame:AddChild(resetButton)
	resetButton:SetPoint("LEFT",BagScrollFrame.searchBar,"RIGHT" )

	bagScan()
	
	local breakCounter = 0
	for link in pairs(itemDB) do

		local item = AceGUI:Create("AzeriteForgeItem")
		local itemName, itemLink, itemRarity, itemLevel, _, _, _, _,itemEquipLoc, itemIcon = GetItemInfo(link)
		local itemEquipLocID = _G[string.gsub(itemEquipLoc,"INVTYPE", "INVSLOT")]

		count = count + 1
		local traitText = ""
		local allTierInfo = C_AzeriteEmpoweredItem.GetAllTierInfoByItemID(itemLink)
		local location = createItemLocation(link)

		item.item.icon:SetTexture(itemIcon)
		item.frame.itemLink = link
		item.description:SetText(itemName.." iLevel:"..itemLevel)
		item.description:SetTextColor(ITEM_QUALITY_COLORS[itemRarity].r,ITEM_QUALITY_COLORS[itemRarity].g,ITEM_QUALITY_COLORS[itemRarity].b)
		item.description:SetJustifyH("LEFT")
		item.frame.location = location

		if not allTierInfo[1]["azeritePowerIDs"][1] then return end

		traitText = AF:BuildTraitText(link, GameTooltip, itemName, true)

		item.traits:SetText(traitText)
		item.traits:SetJustifyH("LEFT")

		if string.find(string.lower(traitText), filterText)  or string.find(string.lower(itemName), filterText) or string.find(string.lower(_G[itemEquipLoc]), filterText) then --or itemEquipLocID == filterLocation then 
		BagScrollFrame:AddChild(item) 
		else
		AceGUI:Release(item)
		end
	end
end

--Aurora Skinning 
function AF.Aurora()
if not IsAddOnLoaded("Aurora") then return end
--Powers Window
	Aurora.Skin.InsetFrameTemplate(AzeriteForge_PowersList)
	Aurora.Skin.UIPanelCloseButton(AzeriteForge_PowersList.close)
	local Background = AzeriteForge_PowersListBg
	
	Background:SetDesaturated(true)
	Background:SetAlpha(0.8)
	Background:Show()


		--
--Bag Window
	Aurora.Skin.InsetFrameTemplate(_G.AzeriteForgeItemFrame)
	Aurora.Skin.UIPanelCloseButton(_G.AzeriteForgeItemFrame.close)

	local Background = AzeriteForgeItemFrameBg
	
	Background:SetDesaturated(true)
	Background:SetAlpha(0.9)
	Background:Show()

	Aurora.Skin.UIPanelButtonTemplate(powerWindowButton2)
end