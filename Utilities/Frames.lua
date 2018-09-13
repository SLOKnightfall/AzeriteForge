--###########################################
--Frame Generation


local FOLDER_NAME, private = ...
local AF = LibStub("AceAddon-3.0"):GetAddon("AzeriteForge")
local L = LibStub("AceLocale-3.0"):GetLocale("AzeriteForge")

AF.Buttons = {}
local buttons = AF.Buttons
local AceGUI = LibStub("AceGUI-3.0")

AF.powerLocationButtonIDs = {}
local powerLocationButtonIDs = AF.powerLocationButtonIDs

AF.UnselectedPowers = {}
local UnselectedPowers = AF.UnselectedPowers
local Utilities = AF.Utilities
local Profiles = AF.Profiles

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
	window:SetFrameStrata('FULLSCREEN_DIALOG')
	window:SetToplevel(true)
	window.title:SetText("AzeriteForge "..L["Import"])

	local content = CreateFrame("Frame",nil, window)
	content:SetPoint("TOPLEFT",15,-35)
	content:SetPoint("BOTTOMRIGHT",-15,15)
	--This creats a cusomt AceGUI container which lets us imbed a AceGUI menu into our frame.
	local widget = {
		frame     = window,
		content   = content,
		type      = "AzForgeImportContainer"
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
	local refresh = false

	if AzeriteForge.Bag then
		AceGUI:Release(AzeriteForge.Bag)
		refresh = AzeriteForge.Bag:IsShown()
	end
	local f = AceGUI:Create("AzeriteForgeFrame")

	AceGUI:RegisterAsContainer(f)
	f:SetLayout("Fill")
	AzeriteForgeItemFrame = f
	f:SetParent(AzeriteEmpoweredItemUI)
	f:ClearAllPoints()
	f:SetPoint("TOPLEFT", AzeriteEmpoweredItemUI, "TOPLEFT",-5,-15)
	f:SetPoint("BOTTOMRIGHT", AzeriteEmpoweredItemUI,"BOTTOMRIGHT")
	f:SetFrameStrata("DIALOG")
	AzeriteForge.Bag = f
	f:Hide()

	f.title:SetText(L["Azerite Gear"])
	f:SetScript("OnShow", function(self)
		buttons.inventoryButton:LockHighlight()
			--AF:UpdateBagDataMenu("")

		end)
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



--Overlay
	local overlay = CreateFrame('Frame', "AzeriteForge_Overlay", UIParent)
	overlay:SetClampedToScreen(true)
	overlay:SetSize(250, 160)
	overlay:SetPoint("TOPLEFT",AzeriteEmpoweredItemUI,"TOPLEFT",0,-20)
	overlay:SetPoint("BOTTOMRIGHT",AzeriteEmpoweredItemUI,"BOTTOMRIGHT")
	--overlay:EnableMouse(true)
	overlay:SetFrameStrata('LOW')
	overlay:SetMovable(false)
	overlay:SetToplevel(true)

	AF:HookScript(AzeriteEmpoweredItemUI, "OnShow", function()  if AzeriteForge.db.profile.showPowersWindow  then C_Timer.NewTimer(.2, function()AF.PowerSummaryFrame:Show();end)   end overlay:Show() end)
	AF:HookScript(AzeriteEmpoweredItemUI, "OnHide", function() AF.PowerSummaryFrame:Hide(); overlay:Hide(); AzeriteForge.Bag:Hide() end)

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
			--LibStub("AceConfigDialog-3.0"):Open("AzeriteForge", "weights")
			InterfaceOptionsFrame_OpenToCategory(AF.optionsFrame2)
			InterfaceOptionsFrame_OpenToCategory(AF.optionsFrame2)

		else
			if AF.PowerSummaryFrame:IsShown() then
				AF.PowerSummaryFrame:Hide()
			else
				--LibStub("AceConfigDialog-3.0"):Open("AzeriteForge_Talents", widget, "stats")
				AF.PowerSummaryFrame:Show()
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

		AF:UpdateBagDataMenu("")
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


		--Powers Window

	local f = AceGUI:Create("AzeriteForgeFrame")

	AceGUI:RegisterAsContainer(f)
	f:SetLayout("Fill")
	AF.PowerSummaryFrame = f
	f:SetParent(overlay)
	f.title:SetText(L["Power Summary"])
	f.title:SetJustifyV("CENTER")
	f:SetWidth(250)
	f:SetHeight(160)
	f:SetPoint("TOPLEFT",overlay,"TOPRIGHT")
	f:SetPoint("BOTTOMLEFT",overlay,"BOTTOMRIGHT")
	f:Hide()
	AzeriteForge_PowersList = f
end


--Creates all needed frames
function AF:CreateFrames()
	addFramesToAzeriteEmpoweredItemUI()
	AF:CreateImportFrame()
	CreateCharacterFrameTabs()
	CreateBagInfoFrame()
	CreateAzeriteDataFrame()
	--AF:Balls()

end


local function findInventoryLocation(itemLink)
	for i = 0,  NUM_BAG_SLOTS + GetNumBankSlots() do
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

	local locationID = _G[string.gsub(select(9,GetItemInfo(itemLink)),"INVTYPE", "INVSLOT")]
	local location = ItemLocation:CreateFromEquipmentSlot(locationID) or 0
	return location


--[[

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

	return 0
	]]--
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
	if AF.Bag.container then
		AceGUI:Release(AzeriteForge.Bag.container)
	end
	filterLocation = filterLocation or ""
	local filterText = filter or ""
	local count = 0
	local sortTable = {}


	local content = AceGUI:Create("SimpleGroup")
	content:SetLayout("Fill")
	AF.Bag:AddChild(content)
	content:SetPoint("TOPLEFT",15,-35)
	content:SetPoint("BOTTOMRIGHT",-15,15)
	AzeriteForge.Bag.container = content

	local scroll = AceGUI:Create("ScrollFrame")
	scroll:SetLayout("Flow")
	content:AddChild(scroll)
	AF.BagScrollFrame = scroll

	local searchBar = AceGUI:Create("EditBox")
	searchBar:SetRelativeWidth(.7)
	searchBar:SetText(filterText)
	--searchBar:SetCallback("OnTextChanged", function(self) TextChanged(self) end)
	searchBar:SetCallback("OnEnterPressed", function(self)
		filterText = string.lower(self:GetText())
		AF:UpdateBagDataMenu(filterText)
	end)
	scroll:AddChild(searchBar)

	local resetButton = AceGUI:Create("Button")
	resetButton:SetRelativeWidth(.3)
	resetButton:SetText(L["Reset"])
	resetButton:SetCallback("OnClick", function(self)
		filterText = string.lower("")
		AF:UpdateBagDataMenu("")
	 end)

	scroll:AddChild(resetButton)
	resetButton:SetPoint("LEFT",AF.BagScrollFrame.searchBar,"RIGHT" )

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
		local maxRankTotal,totalSelected  = 0,0

		traitText,maxRankTotal,totalSelected = AF:BuildTraitText(link, GameTooltip, itemName, true)

		item.item.icon:SetTexture(itemIcon)
		item.frame.itemLink = link
		item.description:SetText(itemName.." iLevel:"..itemLevel.." ["..totalSelected .."/"..maxRankTotal.."]")
		item.description:SetTextColor(ITEM_QUALITY_COLORS[itemRarity].r,ITEM_QUALITY_COLORS[itemRarity].g,ITEM_QUALITY_COLORS[itemRarity].b)
		item.description:SetJustifyH("LEFT")
		item.frame.location = location

		if not allTierInfo[1]["azeritePowerIDs"][1] then return end

		item.traits:SetText(traitText)
		item.traits:SetJustifyH("LEFT")

		if item.frame:GetHeight() < item.traits:GetHeight() then
			item.frame:SetHeight(item.traits:GetHeight()-8)
		else
			item.frame:SetHeight(item.traits:GetHeight())
		end

		if string.find(string.lower(traitText), filterText)  or string.find(string.lower(itemName), filterText) or string.find(string.lower(_G[itemEquipLoc]), filterText) then --or itemEquipLocID == filterLocation then
		scroll:AddChild(item)
		else
		AceGUI:Release(item)
		end
	end
end


--Aurora Skinning
function AF.Aurora()
	if not IsAddOnLoaded("Aurora") then return end
--Powers Window
	Aurora.Skin.InsetFrameTemplate(AzeriteForge_PowersList.frame)
	Aurora.Skin.UIPanelCloseButton(AzeriteForge_PowersList.close)
	local Background = AzeriteForge_PowersList.background

	Background:SetDesaturated(true)
	Background:SetAlpha(0.8)
	Background:Show()

--Bag Window
	Aurora.Skin.InsetFrameTemplate(_G.AzeriteForgeItemFrame.frame)
	Aurora.Skin.UIPanelCloseButton(_G.AzeriteForgeItemFrame.close)

	local Background = AzeriteForgeItemFrame.background
--
	Background:SetDesaturated(true)
	Background:SetAlpha(0.9)
	Background:Show()

	Aurora.Skin.UIPanelButtonTemplate(powerWindowButton2)
end


local weightFrames = {}
local function refreshWeights()
	for traitID, frame in pairs(weightFrames) do

	local text = AF:TextGetter(traitID,AF.db.global.userWeightLists[profile]) 
		if text then 
			frame.weights:SetText(text)
		else 
			frame.weights:SetText("")
		end
	end
end



local function addWeight(traitID,rank, weight)
	if not rank or not tonumber(rank) or not weight or not tonumber(weight) or not traitID then return print("invalid data") end

	AF.traitRanks[tonumber(traitID)] = AF.traitRanks[tonumber(traitID)] or {}
	AF.traitRanks[tonumber(traitID)][tonumber(rank)] = tonumber(weight)
	refreshWeights()
end
local next = next

local function removeWeight (traitID,rank)

	if not rank  or not tonumber(rank) then return print("invalid data") end

	AF.traitRanks[tonumber(traitID)] = AF.traitRanks[tonumber(traitID)] or {}
	AF.traitRanks[tonumber(traitID)][tonumber(rank)] = nil
	if not next(AF.traitRanks[tonumber(traitID)]) then AF.Debug("Empty Rank "..traitID); AF.traitRanks[tonumber(traitID)] = nil end
	refreshWeights()
end


local function powerSearch(searchTerm)

	for traitID, frame in pairs(weightFrames) do


		local found = string.match(string.lower(AF.azeriteTraits[traitID].name), string.lower(searchTerm))
					--return search or (azeriteTraits[traitID] and not azeriteTraits[traitID].valid) or false end,
		if found then 
			frame.frame:Show()
		else 
			frame.frame:Hide()
		end
	end
end





function AzeriteForge:Balls()


local specID, specName, classID, className = Utilities.RefreshClassInfo()
local window = LibStub("AceConfigDialog-3.0")["BlizOptions"]["AzeriteForge"]["AzeriteForge".."\001".."weights"]


--local  window = AceGUI:Create("Window")
window:SetCallback("OnClose", function(widget) AceGUI:Release(widget) end)
window:SetLayout("Fill")

local scrollcontainer = AceGUI:Create("SimpleGroup") -- "InlineGroup" is also good
scrollcontainer:SetFullWidth(true)
scrollcontainer:SetFullHeight(true) -- probably?
scrollcontainer:SetLayout("Fill") -- important!

window:AddChild(scrollcontainer)

local scroll = AceGUI:Create("ScrollFrame")
scroll:SetLayout("Flow") -- probably?
scrollcontainer:AddChild(scroll)

local header = AceGUI:Create("Heading")
header:SetText("Selected Profile")
header:SetRelativeWidth(1)
scroll:AddChild(header)

local profileName =  AceGUI:Create("EditBox")
profileName:SetLabel("Profile Name")
local text = AzeriteForge.db.char.weightProfile[specID]
profileName:SetText(text)
scroll:AddChild(profileName)
profileName:SetWidth(200)
profileName:SetCallback("OnEnterPressed", function(widget, event, text) if Profiles.RenameProfile(AF.db.char.weightProfile[specID], text) then AF.db.char.weightProfile[specID] = text end end)
profileName:SetRelativeWidth(1)

local profileDetails = AceGUI:Create("Label")

scroll:AddChild(profileDetails)

local profile =  AF.db.char.weightProfile[specID]

if profile then 
	 local profileSpecID = AF.db.global.userWeightLists[profile]["specID"] or 0
	local _, name, _,icon, _, class = GetSpecializationInfoByID(profileSpecID)
	if icon then
		icon = "|T"..icon..(":25:25:|t")
	else
		icon = ""
	end
	profile = ("%sClass: %s, Spec: %s"):format(icon or "",class or "", name or"")
end
profileDetails:SetText(profile)
profileDetails:SetRelativeWidth(1)




local resetRanks = AceGUI:Create("Button")
resetRanks:SetText( L["Reset with Stacking Defaults"])
resetRanks:SetCallback("OnClick", function() local data = AF.loadDefaultData("StackData")
					local profile = AF.db.char.weightProfile[specID]
					wipe(AF.traitRanks)
					AF.traitRanks = CopyTable(data)
					AF.traitRanks["specID"] = tonumber(specID)
					AF.traitRanks["classID"] = tonumber(classID)
					AF.db.global.userWeightLists[profile] = AF.traitRanks
					refreshWeights()
					end)
scroll:AddChild(resetRanks)
resetRanks:SetRelativeWidth(.5)

local resetiLevel = AceGUI:Create("Button")
resetiLevel:SetCallback("OnClick", function() local data = AF.loadDefaultData("iLevelData")
					local profile = AF.db.char.weightProfile[specID]
					wipe(AF.traitRanks)
					AF.traitRanks = CopyTable(data)
					AF.traitRanks["specID"] = tonumber(specID)
					AF.traitRanks["classID"] = tonumber(classID)
					AF.db.global.userWeightLists[profile] = AF.traitRanks
					refreshWeights()
					end)
resetiLevel:SetText(L["Reset with iLevel Defaults"])
scroll:AddChild(resetiLevel)
resetiLevel:SetRelativeWidth(.5)



local importButton = AceGUI:Create("Button")
importButton:SetCallback("OnClick",  function()	AzeriteForge.ImportWindow:Show() end)
importButton:SetText(L["Import Data"])
scroll:AddChild(importButton) 
importButton:SetRelativeWidth(.5)

local exportButton = AceGUI:Create("Button")
exportButton:SetCallback("OnClick", function() AF:ExportData() end)
exportButton:SetText(L["Export Data"])
scroll:AddChild(exportButton)
exportButton:SetRelativeWidth(.5)

local clearData = AceGUI:Create("Button")
clearData:SetCallback("OnClick",  function()
					local profile = AF.db.char.weightProfile[specID]
					--local DB = AF.db.global.userWeightLists[weightProfile]
					wipe(AF.traitRanks)
					AF.traitRanks["specID"] = tonumber(specID)
					AF.traitRanks["classID"] = tonumber(classID)
					AF.db.global.userWeightLists[profile] = AF.traitRanks
					refreshWeights()

					end)
clearData:SetText(L["Clear all data"])
scroll:AddChild(clearData)
clearData:SetRelativeWidth(1)

local header = AceGUI:Create("Heading")
header:SetText(L["Weights"])
header:SetWidth(1)
scroll:AddChild(header)
header:SetRelativeWidth(1)

local profileDetails = AceGUI:Create("Label")
profileDetails:SetText( L["WEIGHT_INSTRUCTIONS"])
scroll:AddChild(profileDetails)
profileDetails:SetRelativeWidth(1)

local search =  AceGUI:Create("EditBox")
search:SetLabel("Search")
search:SetRelativeWidth(1)

scroll:AddChild(search)
search:SetWidth(200)
search:SetCallback("OnEnterPressed", function(widget, event, text) powerSearch(text) end)

	local sortTable = {}
	for id, data in pairs(AF.azeriteTraits) do
		tinsert(sortTable, id)
	end
	table.sort(sortTable, function(a,b) return AF.azeriteTraits[a].name < AF.azeriteTraits[b].name end)

	for i,x in pairs (sortTable) do
	end

	for index, traitID in pairs(sortTable) do

		local name = AF.azeriteTraits[traitID].name
		--print(name)
		local icon = AF.azeriteTraits[traitID].icon
		local spellID = AF.azeriteTraits[traitID].spellID
		if name and AF.azeriteTraits[traitID].valid then

			--local header = AceGUI:Create("Heading")
			--header:SetText(name)
			--header:SetWidth(1)
			--scroll:AddChild(header)
			--header:SetRelativeWidth(1)
			local weight = AceGUI:Create("AzeriteForgeWeight")
			scroll:AddChild(weight)
			weight.name:SetText(name)
			weight.power.icon:SetTexture(icon)
			weightFrames[traitID] = weight

			local text = AF:TextGetter(traitID,AF.db.global.userWeightLists[profile]) 
			if text then 
			
				weight.weights:SetText(text)
			end

			weight.clear_button:SetScript("OnClick", function() wipe(AF.traitRanks[tonumber(traitID)]); refreshWeights() end)
			weight.add_button:SetScript("OnClick", function() addWeight(traitID,weight.id_editbox:GetText(), weight.weight_editbox:GetText()) end)
			weight.remove_button:SetScript("OnClick", function() removeWeight(traitID,weight.id_editbox:GetText()) end)

		end
	end
end