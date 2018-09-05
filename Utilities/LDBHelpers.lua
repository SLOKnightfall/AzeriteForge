local FOLDER_NAME, private = ...
local TextDump = LibStub("LibTextDump-1.0")
AzeriteForge = LibStub("AceAddon-3.0"):GetAddon("AzeriteForge")
local L = LibStub("AceLocale-3.0"):GetLocale("AzeriteForge")
AzeriteForgeMiniMap = LibStub("LibDBIcon-1.0")
local AF = AzeriteForge

local azeriteIcon = "Interface/Icons/Inv_smallazeriteshard"
local AzeriteLocations = {["Head"] = ItemLocation:CreateFromEquipmentSlot(1),
			["Shoulder"] = ItemLocation:CreateFromEquipmentSlot(3), 
			["Chest"]= ItemLocation:CreateFromEquipmentSlot(5),
			[1] = "Head",
			[3] = "Shoulder",
			[5] = "Chest",}
local locationIDs = {["Head"] = 1, ["Shoulder"] = 3, ["Chest"] = 5,}
local AceGUI = LibStub("AceGUI-3.0")


--looks at equpment slots to find an empowered item to open to, giving priority to items with selectable powers
local function OpenToBestEmpoweredLocation()
	local itemFound = false
	local availableTraits  =false
	local firstFound = false
	for equipSlotIndex, itemLocation in AzeriteUtil.EnumerateEquipedAzeriteEmpoweredItems() do
		if C_AzeriteEmpoweredItem.IsAzeriteEmpoweredItem(itemLocation) then
			if not firstFound then firstFound = itemlocation end
			if not availableTraits then availableTraits = itemLocation; break end
		end
	end

	if availableTraits or firstFound then 

		AF.ShowEmpoweredItem(availableTraits or firstFound)

		if CharacterFrame:IsShown() then
			HideUIPanel(CharacterFrame)
		end
		return  true
	end
			
	if not itemFound then
		DEFAULT_CHAT_FRAME:AddMessage(L["No Empowered items equipped"])
		return false
	end
end

--LDB handlers
local AzeriteForgeInfoLDB = LibStub("LibDataBroker-1.1"):NewDataObject("AzeriteForge", {
	type = "data source",
	text = "AzeriteForge",
	icon = azeriteIcon,
	OnClick = function(self, button, down) 
		if (button == "RightButton") then
			LibStub("AceConfigDialog-3.0"):Open("AzeriteForge")
		elseif (button == "LeftButton") then
			--AF.ShowEmpoweredItem(AzeriteLocations["Head"])
			OpenToBestEmpoweredLocation()
		end
	end,})

AF.AzeriteForgeInfoLDB = AzeriteForgeInfoLDB

function AzeriteForgeInfoLDB:OnTooltipShow()
	AF.BuildAzeriteInfoTooltip(self)
end


function AzeriteForgeInfoLDB:OnEnter()
	GameTooltip:SetOwner(self, "ANCHOR_NONE")
	GameTooltip:SetPoint("TOPLEFT", self, "BOTTOMLEFT")
	GameTooltip:ClearLines()
	AzeriteForgeInfoLDB.OnTooltipShow(GameTooltip)
	GameTooltip:Show()
end


function AzeriteForgeInfoLDB:OnLeave()
	GameTooltip:Hide()
end

--Head LDB

local function LDBItemOnEnter(self, location)
	if not location then return end

	local itemLink = GetInventoryItemLink("player", location)
	if not itemLink then return end
	GameTooltip:SetOwner(self, "ANCHOR_NONE")
	GameTooltip:SetPoint("TOPLEFT", self, "BOTTOMLEFT")
	GameTooltip:SetHyperlink(itemLink)
	GameTooltip:Show()
end

local function LDBItemOnClick(self, button, location)

	local locationID = locationIDs[location]
	local itemID =  GetInventoryItemID("player", locationID)

	if (button == "RightButton") then
		--AzeriteForge.Bag:Show()
		--AF:UpdateBagDataMenu(false, locationID)
		--LibStub("AceConfigDialog-3.0"):Open("AzeriteForge")
	elseif (button == "LeftButton") then
		if itemID then
			AF.ShowEmpoweredItem(AzeriteLocations[location])
		else
		DEFAULT_CHAT_FRAME:AddMessage((L["No Empowered %s item equipped"]):format(location));
			--ShowUIPanel(AzeriteEmpoweredItemUI)
			--AzeriteForge.Bag:Show()
			--AF:UpdateBagDataMenu(false, locationID)
		end
	end
end


local AzeriteForgeHeadLDB = LibStub("LibDataBroker-1.1"):NewDataObject("AzeriteForge-Head", {
	type = "data source",
	text = "HeadSlot",
	icon = azeriteIcon,
	OnClick = function(self, button) LDBItemOnClick(self, button, "Head") end,
	OnEnter = function(self) LDBItemOnEnter(self, 1) end,
	})
AF.AzeriteForgeHeadLDB = AzeriteForgeHeadLDB



local AzeriteForgeChestLDB = LibStub("LibDataBroker-1.1"):NewDataObject("AzeriteForge-Chest", {
	type = "data source",
	text = "AzeriteForge-Head",
	icon = azeriteIcon,
	OnClick = function(self, button) LDBItemOnClick(self, button, "Chest") end,
	OnEnter = function(self) LDBItemOnEnter(self, 5) end,
	})
AF.AzeriteForgeChestLDB = AzeriteForgeChestLDB

local AzeriteForgeShoulderLDB = LibStub("LibDataBroker-1.1"):NewDataObject("AzeriteForge-Shoulder", {
	type = "data source",
	text = "AzeriteForge-Shoulder",
	icon = azeriteIcon,
	OnClick = function(self, button) LDBItemOnClick(self, button, "Shoulder") end,
	OnEnter = function(self) LDBItemOnEnter(self, 3) end,
	})
AF.AzeriteForgeShoulderLDB = AzeriteForgeShoulderLDB


function AF.setLDBItems(location)
	local LDB_Location = {["Head"] = AF.AzeriteForgeHeadLDB, ["Chest"] = AF.AzeriteForgeChestLDB, ["Shoulder"] = AF.AzeriteForgeShoulderLDB}
	local itemName, itemLink, itemIcon  = false, false, false
	local locationID = locationIDs[location]
	local itemID =  GetInventoryItemID("player", locationID)
	local HasAnyUnselectedPowers = false
	local azeriteLocation = ItemLocation:CreateFromEquipmentSlot(locationID)
	
	if itemID then 
		local isAzeriteItem = C_AzeriteEmpoweredItem.IsAzeriteEmpoweredItem(azeriteLocation)
		itemName, itemLink, _, _, _, _, _, _,_, itemIcon  = GetItemInfo(itemID)
		if isAzeriteItem then 
			HasAnyUnselectedPowers = C_AzeriteEmpoweredItem.HasAnyUnselectedPowers(azeriteLocation)
		end
	end

	if itemName and HasAnyUnselectedPowers then itemName = "*"..itemName.."*" end

	LDB_Location[location].icon = (itemIcon  or azeriteIcon)
	LDB_Location[location].itemLink = itemLink
	LDB_Location[location].text = itemName or "Empty"

end

function AF.MiniMapIconToggle(value)
		if value then
			AzeriteForgeMiniMap:Show("AzeriteForgeMini")
			Config.MMDB.hide = false;
		else
			AzeriteForgeMiniMap:Hide("AzeriteForgeMini")
			Config.MMDB.hide = true;
		end
end