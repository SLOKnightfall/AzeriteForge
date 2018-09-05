--	///////////////////////////////////////////////////////////////////////////////////////////
--
--	AzeriteForge v@project-version@
--	Author: SLOKnightfall

--	
--	///////////////////////////////////////////////////////////////////////////////////////////
local HasActiveAzeriteItem, FindActiveAzeriteItem, GetAzeriteItemXPInfo, GetPowerLevel = C_AzeriteItem.HasActiveAzeriteItem, C_AzeriteItem.FindActiveAzeriteItem, C_AzeriteItem.GetAzeriteItemXPInfo, C_AzeriteItem.GetPowerLevel

local FOLDER_NAME, private = ...
local TextDump = LibStub("LibTextDump-1.0")
AzeriteForge = LibStub("AceAddon-3.0"):GetAddon("AzeriteForge")
local L = LibStub("AceLocale-3.0"):GetLocale("AzeriteForge")
AzeriteForgeMiniMap = LibStub("LibDBIcon-1.0")
local AceGUI = LibStub("AceGUI-3.0")
local AF = AzeriteForge

BINDING_HEADER_AZERITEFORGE = "AzeriteForge"
BINDING_NAME_AZERITEFORGE_OPEN_HEAD = L["Head Powers"]
BINDING_NAME_AZERITEFORGE_OPEN_CHEST = L["Shoulder Powers"]
BINDING_NAME_AZERITEFORGE_OPEN_SHOULDER = L["Chest Powers"]

local BagScrollFrame
AF.BagScrollFrame = BagScrollFrame
local currentXp, currentMaxXp, startXp =  0, 0 , 0 
local currentLevel, startLevel = 0 , 0 
local lastXpGain = 0
local azeriteItemLocation
local azeriteIcon = "Interface/Icons/Inv_smallazeriteshard"
local azeriteItemIcon = azeriteIcon
local COLOR_GREEN  = CreateColor(0.1, 0.8, 0.1, 1)
local spec = 0
local specID  = 0
local className, classFile, classID
local UnselectedPowersCount = 0
local powerLocationButtonIDs = {}

local bagDataStorage = {}

local globalDb 
local configDb 
local WeeklyQuestGain = 0
local WeeklyQuestRequired = 0
local searchbar = nil


local UnselectedLocationTraits = {}
local azeriteTraits = {}
local traitRanks = {}
local ap = {}
local ReforgeCost = {}
local buttons = {}
local AzeriteTraitsName_to_ID ={}
local UnselectedPowers = {}
local AzeriteLocations = {["Head"] = ItemLocation:CreateFromEquipmentSlot(1),
			["Shoulder"] = ItemLocation:CreateFromEquipmentSlot(3), 
			["Chest"]= ItemLocation:CreateFromEquipmentSlot(5),
			[1] = "Head",
			[3] = "Shoulder",
			[5] = "Chest",}
local locationIDs = {["Head"] = 1, ["Shoulder"] = 3, ["Chest"] = 5,}
local AvailableAzeriteTraits = {["Shoulder"] = {}, ["Head"] = {}, ["Chest"]= {},}
local SelectedAzeriteTraits = {["Shoulder"] = {}, ["Head"] = {}, ["Chest"]= {},}


local function DoStuff(table)
	for i,y in pairs(table) do
		local test = table[i]
		if type(test) == "table" then
			DoStuff(test)
		else
			print(i)
			print(test)
			print("--")
		end
	end
end


-- ----------------------------------------------------------------------------
-- Debugger.
-- ----------------------------------------------------------------------------
local Debug, DebugPour, GetDebugger
do
	--local TextDump = LibStub("LibTextDump-1.0")

	local DEBUGGER_WIDTH = 750
	local DEBUGGER_HEIGHT = 800

	local debugger

	function Debug(...)
		if not debugger then
			debugger = TextDump:New(("%s Output"):format(FOLDER_NAME), DEBUGGER_WIDTH, DEBUGGER_HEIGHT)
		end

		local t = type(...)
		if t == "string" then
			local message = string.format(...)
			debugger:AddLine(message, "%X")
		elseif t == "number" then
			local message = string.format tostring((...))
			debugger:AddLine(message, "%X")
		elseif t == "boolean" then
			local message = string.format tostring((...))
			debugger:AddLine(message, "%X")
		elseif t == "table" then
			debugger:AddLine(message, "%X")
			--pour(textOrAddon, ...)
		else
			--error("Invalid argument 2 to :Pour, must be either a string or a table.")
		end
		
		return message
	end

	function DebugPour(...)
		DEFAULT_CHAT_FRAME:AddMessage(string.format(...));
		Debug(...)
		
	end

	function GetDebugger()
		if not debugger then
			debugger = TextDump:New(("%s Output"):format(FOLDER_NAME), DEBUGGER_WIDTH, DEBUGGER_HEIGHT)
		end

		return debugger
	end

	function ClearDebugger()
		if not debugger then
			debugger = TextDump:New(("%s Output"):format(FOLDER_NAME), DEBUGGER_WIDTH, DEBUGGER_HEIGHT)
		end

		debugger:Clear()
	end

	function Export(...)
		if not debugger then
			debugger = TextDump:New(("%s Export"):format(FOLDER_NAME), DEBUGGER_WIDTH, DEBUGGER_HEIGHT)
		end

		debugger:Clear()
			local message = string.format(...)
			debugger:AddLine(message)

		 debugger:Display()
		 return debugger
		
	end

	private.Debug = Debug
	private.DebugPour = DebugPour
end

-- ----------------------------------------------------------------------------
-- Helpers.
-- ----------------------------------------------------------------------------

--Determines if a value is stored in a table
local function inTable(table, value)
	for index, data in pairs(table) do
		if type(data) == "table" then
			return inTable(data, value)
		else
			if tostring(data) == tostring(value) then 
				return true
			end
		end
	end
	return false
end

local function validTrait(traitID)
	local traitClasses = AzeriteForge.TraitData[traitID].classesId
	local traitSpecs = AzeriteForge.TraitData[traitID].specsId
	if (inTable(traitClasses, classID) and (traitSpecs and inTable(traitSpecs, specID))) then  
		return true

	elseif (inTable(traitClasses, classID) and not traitSpecs) then 
		return true

	else
		return false
	end
end

local sortTable = {}
local maxValue = {}
local function getTraitRanking(traitID, locationID)
	if not traitRanks[traitID] then return false  end

	local itemLevel = 0
	local itemLink = nil
	local rank = 0
	local bag, slot = locationID:GetBagAndSlot()

	if locationID.equipmentSlotIndex then
		itemLink = GetInventoryItemLink("player", locationID.equipmentSlotIndex)

	elseif bag and slot then
		itemLink = GetContainerItemLink(bag, slot)

	end

	if itemLink then
		 _, _, _, itemLevel = GetItemInfo(itemLink)
	end

	local ItemLocation = AzeriteLocations[locationID] or AzeriteLocations[locationID.equipmentSlotIndex] or locationID


	if #traitRanks[traitID] >0 then
		rank = 0
		local  _, stackedRank = AF:FindStackedTraits(traitID, locationID, SelectedAzeriteTraits)
		local maxRank = 1
	 
		for index, itemrank in pairs(traitRanks[traitID]) do
			maxRank = itemrank
		end

		rank = traitRanks[traitID][stackedRank + 1] or maxRank


	else
		rank = itemLevel
		sortTable = {}
		for id, data in pairs(traitRanks[traitID]) do
			tinsert(sortTable, id)
		end

		table.sort(sortTable, function(a,b) return a < b  end)

		for index, ilevel in pairs(sortTable) do
			if itemLevel <= ilevel then
				break

			end
			rank = ilevel
		end
		if rank <= sortTable[1] then
			rank = sortTable[1]

		end

		rank = traitRanks[traitID][rank]	
	end

	return rank
end

function AF.BuildAzeriteInfoTooltip(frame)
	local RespecCost = C_AzeriteEmpoweredItem.GetAzeriteEmpoweredItemRespecCost()

	frame:AddLine(("Current Level: %s"):format(currentLevel),1.0, 1.0, 1.0);
	frame:AddLine(("XP: %s/%s"):format(currentXp, currentMaxXp), 1.0, 1.0, 1.0);
	frame:AddLine(("Xp to Next Level: %s"):format(currentMaxXp - currentXp), 1.0, 1.0, 1.0);
	frame:AddLine(("Current Respec Cost: %sg"):format(RespecCost/10000), 1.0, 1.0, 1.0);
	frame:AddLine(("Islands: %s/%s"):format(WeeklyQuestGain, WeeklyQuestRequired ), 1.0, 1.0, 1.0);
	frame:AddLine(("Remaining: %s"):format( WeeklyQuestRequired- WeeklyQuestGain ), 1.0, 1.0, 1.0);
end


--Opens a location's Azerite trait page
function AF.ShowEmpoweredItem(itemLocation)
	local equipmentSlotID = itemLocation:GetEquipmentSlot()

	if ItemLocationMixin:IsEquipmentSlot(itemLocation) or not C_Item.DoesItemExist(itemLocation) then return end
		if C_AzeriteEmpoweredItem.IsAzeriteEmpoweredItem(itemLocation) then
			OpenAzeriteEmpoweredItemUIFromItemLocation(itemLocation);

			for i in pairs (powerLocationButtonIDs) do
				if i == equipmentSlotID then 
					powerLocationButtonIDs[i]:LockHighlight()
				else
					powerLocationButtonIDs[i]:UnlockHighlight()
				end
			end
		else
			DEFAULT_CHAT_FRAME:AddMessage("Equipped item is not an Azerite item.");
		end
end


---------
--options.args.weights.args
local options = {
    name = "AzeriteForge",
    handler = AzeriteForge,
    type = "group",
    args = {
	options = {
		name = "Options",
		handler = AzeriteForge,
		type = "group",
		args = {
			header1 = {
				type = "header",
				name = L["Weight Data Options"],
				order = 0,
				},
			debug = {

				type = "execute",
				name = "Debug",
				hidden = true,
				func = function()
					local debugger = GetDebugger()

					if debugger:Lines() == 0 then
						debugger:AddLine("Nothing to report.")
						debugger:Display()
						debugger:Clear()
						return
					end
					debugger:Display()
					end,
				},
			resetStacking = {
				type = "execute",
				name = L["Reset Default Data with Stacking Data"],
				order = 1,
				width = "double",
				func = function()
					traitRanks = AF.loadDefaultData("StackData")-- StackData
					AzeriteForgeDB.SavedSpecData[specID] = traitRanks
					end,	
				},
			resetIlevel = {
				type = "execute",
				name = L["Reset Default Data with iLevel Data"],
				order = 2,
				width = "double",
				func = function()
					traitRanks = AF.loadDefaultData("iLevelData")-- StackData
					AzeriteForgeDB.SavedSpecData[specID] = traitRanks
					end,
					
				},
			clearData = {
				type = "execute",
				name = L["Clear all data"],
				order = 3,
				width = "double",
				func = function()
					wipe(traitRanks)
					end,
					
				},
			importData = {
				type = "execute",
				name = L["Import Data"],
				order = 4,
				width = "double",
				func = function()
					AzeriteForge.ImportWindow:Show()
					end,
					
				},
			exportData = {
				type = "execute",
				name = L["Export Data"],
				order = 5,
				width = "double",
				func = function() AF:ExportData() end,	
				},
			header2 = {
				type = "header",
				name = L["MiniMap Icon Settings"],
				order = 5.99,
				},
			showMapicon = {
				type = "toggle",
				name = L["Show Minimap Icon"],
				order = 6,
				width = "full",
				set = function(info,val) AzeriteForge.db.profile.showMapicon = val; private.MiniMapIconToggle(val)
				end,
				get = function(info) return AzeriteForge.db.profile.showMapicon end,
				},
			tooltipHeader = {
				type = "header",
				name = L["Tooltip Settings"],
				order =7,
				},
			enhancedTooltip = {
				type = "toggle",
				name = L["Enhanced Tooltips"],
				order = 8,
				set = function(info,val) AzeriteForge.db.profile.enhancedTooltip = val end,
				get = function(info) return AzeriteForge.db.profile.enhancedTooltip end,
				},
			tooltipCurrentTraits = {
				type = "toggle",
				name = L["Show current spec traits"],
				order =9,
				set = function(info,val) AzeriteForge.db.profile.tooltipCurrentTraits = val end,
				get = function(info) return AzeriteForge.db.profile.tooltipCurrentTraits end,
				},
			tooltipIconsOnly = {
				type = "toggle",
				name = L["Icons only"],
				order = 10,
				set = function(info,val) AzeriteForge.db.profile.tooltipIconsOnly = val end,
				get = function(info) return AzeriteForge.db.profile.tooltipIconsOnly end,
				},
			},
		},
	weights = {
		    name = "Trait Weights",
		    handler = AzeriteForge,
		    type = "group",
		    args = {
		    	search = {
				name = "",
				type = "input",
				width = "full",
				order = .01,
				set = function(info,val) searchbar = val end,
				get = function(info) return searchbar end
				},
			},
		   },
	},
}


--Ace3 Menu Settings for the Zone Settings window
local talent_options = {
    name = "AzeriteForge_Talents",
    handler = AzeriteForge,
    type = 'group',
    args = {
    	bagData = {	
		name = "BagData",
		type = "group",
		args = {
			Topheader = {
				order = 0,
				type = "header",
				name = "AzeriteForge",
				},
		},
	},	
	options={
		name = "Options",
		type = "group",
		args={
			Topheader = {
				order = 0,
				type = "header",
				name = "AzeriteForge",
			},
			search = {
				name = "",
				type = "input",
				width = "full",
				order = .01,
				set = function(info,val) searchbar = val end,
				get = function(info) return searchbar end
			},

			filler1 = {
				order = 0.2,
				type = "description",
				name = "\n",
			},

		},
	},

	stats = {
		name = "Stats",
		type = "group",
		args={	
			Topheader = {
				order = 0,
				type = "header",
				name = "AzeriteForge",
				},
			headHeader = {
				order = 1,
				type = "header",
				name = L["Head Powers"],
				},
			shoulderHeader = {
				order = 3,
				type = "header",
				name = L["Shoulder Powers"],
				},
			chestHeader = {
				order = 5,
				type = "header",
				name = L["Chest Powers"],
				},
			},
		},
	},


}

local DB_DEFAULTS = {
	profile = {
		showMapicon = true,
		debugPrint = false,
		MMDB = { 
			hide = false,
		--minimap = {},
		},
		tooltipCurrentTraits = false,
		tooltipIconsOnly = false,
		enhancedTooltip = true,		
	},
	global = {
	},

}


function AzeriteTooltip_GetSpellID(powerID)
	local powerInfo = C_AzeriteEmpoweredItem.GetPowerInfo(powerID)
  	if (powerInfo) then
    	local azeriteSpellID = powerInfo["spellID"]
    	return azeriteSpellID
  	end
end


function AF:ChatCommand(input)
    if not input or input:trim() == "" then
        LibStub("AceConfigDialog-3.0"):Open("AzeriteForge_Talents", widget, "stats")

    else
        LibStub("AceConfigCmd-3.0"):HandleCommand("az", "AzeriteForge", input)
    end
end



function AF:GetAzeriteTraits()
	AvailableAzeriteTraits = {["Shoulder"] = {}, ["Head"] = {}, ["Chest"]= {},}
	SelectedAzeriteTraits = {["Shoulder"] = {}, ["Head"] = {}, ["Chest"]= {},}

	if not GetInventoryItemID("player", 3) then --or C_AzeriteEmpoweredItem.IsAzeriteEmpoweredItem(itemLocation) then 
		buttons.shoulderSlotButton:Hide()
	else
		buttons.shoulderSlotButton:Show()
		AF:GetAzeriteLocationTraits("Shoulder")
		AF:UnselectTraits("Shoulder")
	end

	if not GetInventoryItemID("player", 1) then 
		buttons.headSlotButton:Hide()
	else
		buttons.headSlotButton:Show()
		AF:GetAzeriteLocationTraits("Head")
		AF:UnselectTraits("Head")
	end

	if not GetInventoryItemID("player", 5) then 
		buttons.chestSlotButton:Hide()
	else
		buttons.chestSlotButton:Show()
		AF:GetAzeriteLocationTraits("Chest")
		AF:UnselectTraits("Head")

	end

	UnselectedPowersCount = AzeriteUtil.GetEquippedItemsUnselectedPowersCount()

	updateInventoryLDB()
end





function updateInventoryLDB()
	--Azerite Window Tabs
	buttons.headSlotButton:SetNormalTexture(GetItemIcon(GetInventoryItemID("player", 1))  or "Interface\\Icons\\inv_boot_helm_draenordungeon_c_01")
	buttons.shoulderSlotButton:SetNormalTexture(GetItemIcon(GetInventoryItemID("player", 3)) or "Interface\\Icons\\inv_misc_desecrated_clothshoulder")
	buttons.chestSlotButton:SetNormalTexture(GetItemIcon(GetInventoryItemID("player", 5)) or "Interface\\Icons\\inv_chest_chain")
	
	--LDB Icons
	AF.setLDBItems("Head")
	AF.setLDBItems("Shoulder")
	AF.setLDBItems("Chest")

	private.updateLDBShine()
end


function AF:updateInfoLDB()
	AF.AzeriteForgeInfoLDB.text = string.format("L:%s  XP: %s/%s", currentLevel, currentXp, currentMaxXp)
end

local function UpdateWeeklyQuest()
	local questID = C_IslandsQueue.GetIslandsWeeklyQuestID();
	
	local _, _, _, WeeklyGain, WeeklyRequired = GetQuestObjectiveInfo(questID, 1, false);
	WeeklyQuestGain = WeeklyGain or 0
	WeeklyQuestRequired = WeeklyRequired or 0
end



function AF:OnInitialize()




end


function AF:OnEnable()
	self.db = LibStub("AceDB-3.0"):New("AzeriteForgeDB", DB_DEFAULTS, true)
		AzeriteForgeDB.SavedSpecData = AzeriteForgeDB.SavedSpecData or {}
	AzeriteForgeDB.SavedSpecData[specID] = traitRanks
	LibStub("AceConfig-3.0"):RegisterOptionsTable("AzeriteForge_Talents", talent_options)
	LibStub("AceConfig-3.0"):RegisterOptionsTable("AzeriteForge", options)
	self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("AzeriteForge", "AzeriteForge")

	globalDb = self.db.global
	configDb = self.db.profile
	Config = self.db.profile
	self:RegisterChatCommand("az", "ChatCommand")
	self:RegisterChatCommand("azeriteforge", "ChatCommand")

	self:RegisterEvent("AZERITE_ITEM_EXPERIENCE_CHANGED")
	self:RegisterEvent("AZERITE_ITEM_POWER_LEVEL_CHANGED")
	self:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
	self:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
	self:RegisterEvent("PLAYER_ENTERING_WORLD")

	AzeriteForgeMiniMap:Register("AzeriteForgeMini", AF.AzeriteForgeInfoLDB, Config.MMDB)
	AzeriteForge.MinimapIcon = AzeriteForgeMiniMap:GetMinimapButton("AzeriteForgeMini")

	spec = GetSpecialization()
	specID = GetSpecializationInfo(spec) 
	className, classFile, classID = UnitClass("player")

	AF:CreateFrames()
	AF:BuildAzeriteDataTables()
	AF:GetAzeriteData()
	AF:GetAzeriteTraits()
	AF:LoadClassTraitRanks()
	--AF:CreateTraitMenu()
	UpdateWeeklyQuest()
	--AF:UpdateBagDataMenu()
	AF:updateInfoLDB()

	AF:SecureHookScript(GameTooltip,"OnTooltipSetItem")
	AF:SecureHookScript(ItemRefTooltip,"OnTooltipSetItem")
	AF:SecureHookScript(WorldMapTooltip,"OnTooltipSetItem")

--AF:RawHook(AzeriteEmpoweredItemPowerMixin,"OnEnter",true) 
end

function AF:PLAYER_ENTERING_WORLD()


end


function AF:OnDisable()
    -- Called when the addon is disabled
end


function AF:PLAYER_EQUIPMENT_CHANGED(event, ...)
	local InventorySlotId = ...
	if InventorySlotId == INVSLOT_HEAD or InventorySlotId == 3 or InventorySlotId == 5 then
		AF:GetAzeriteTraits()
		AF:GetAzeriteData()
	AF:GetAzeriteTraits()
	AF:UpdateBagDataMenu("")
	AF:updateInfoLDB()
	end
end


function AF:PLAYER_SPECIALIZATION_CHANGED(event, ...)
	spec = GetSpecialization()
	specID = GetSpecializationInfo(spec) 
	AF:BuildAzeriteDataTables()


	AF:GetAzeriteData()
	AF:GetAzeriteTraits()
	AF:LoadClassTraitRanks()
	AF:updateInfoLDB()
end


function AF:AZERITE_ITEM_EXPERIENCE_CHANGED(event, ...)
	local azeriteItemLocation, oldExperienceAmount, newExperienceAmount = ...
	lastXpGain = newExperienceAmount - oldExperienceAmount
	UpdateWeeklyQuest()
	AF:updateInfoLDB()
	AF:GetAzeriteData()
  -- if it's not equal then we will defer the xp gain to the power level event
	if GetPowerLevel(azeriteItemLocation) == currentLevel then 
    --self:GetAzeriteData()
    --self:SetBrokerText()
    --self:RecordXpGain(lastXpGain)
	end
end


-- it is assumed that this event always happens AFTER a XP change event
function AF:AZERITE_ITEM_POWER_LEVEL_CHANGED(event, ...)
	local azeriteItemLocation, oldPowerLevel, newPowerLevel, unlockedEmpoweredItemsInfo = ...
	local lastLevelGain = newPowerLevel - oldPowerLevel
	if lastLevelGain ~= 1 then
		DebugPour("Unexpected Azerite Item level change of %d, please report as a bug", lastLevelGain)
	end
	AF:updateInfoLDB()
	AF:GetAzeriteData()
end


function AF:UnselectTraits(location)
	local locationData = AzeriteLocations[location]

	if not C_Item.DoesItemExist(locationData) or not C_AzeriteEmpoweredItem.IsAzeriteEmpoweredItem(locationData) then return false end

	UnselectedLocationTraits[location] = C_AzeriteEmpoweredItem.HasAnyUnselectedPowers(locationData)
	return UnselectedLocationTraits[location]
end


--Gets Azerite xp info
function AF:GetAzeriteData()
	if not HasActiveAzeriteItem() then
		return
	end
	
	if not azeriteItemLocation then 
		-- set up start values
		currentMaxXp = currentMaxXp or 1
		azeriteItemLocation = FindActiveAzeriteItem()
		azeriteItemIcon = C_Item.GetItemIcon(azeriteItemLocation)
		startXp = GetAzeriteItemXPInfo(azeriteItemLocation)
		startLevel, currentMaxXp = GetPowerLevel(azeriteItemLocation)
		Debug(("StartXP: %s"):format(startXp))
		Debug(("startLevel: %s"):format(startLevel or "0"))
		Debug(("currentMaxXp: %s"):format(currentMaxXp or "NA"))
	end

	currentXp, currentMaxXp = GetAzeriteItemXPInfo(azeriteItemLocation)
	currentLevel = GetPowerLevel(azeriteItemLocation)
	Debug(("currentXp: %s"):format(currentXp))
	Debug(("currentMaxXp: %s"):format(currentMaxXp))
	Debug(("currentLevel: %s"):format(currentLevel))
end


--Looks to see if an Azerite ability is on other gear pieces
function AF:FindStackedTraits(powerID, locationID, traitList)
	local ItemLocation = AzeriteLocations[locationID] or AzeriteLocations[locationID.equipmentSlotIndex] or locationID
	local foundLocations = nil
	local count = 0
	for location, data in pairs(traitList) do
		for level , level_data in pairs(traitList[location]) do
			for index , spellID in pairs(traitList[location][level]["azeritePowerIDs"]) do
				if spellID == powerID  and ItemLocation ~= location then 
					foundLocations = (foundLocations or "")..location..","
					count = count + 1
				end
			end
		end
	end
	return foundLocations, count
end


function AF:GetAzeriteLocationTraits(location)
	local locationData = AzeriteLocations[location]
	--if not C_AzeriteEmpoweredItem.IsAzeriteEmpoweredItem(locationData) then return end
	if not C_Item.DoesItemExist(locationData) or not C_AzeriteEmpoweredItem.IsAzeriteEmpoweredItem(locationData) then return end

	local allTierInfo = C_AzeriteEmpoweredItem.GetAllTierInfo(locationData)

	if not allTierInfo then return end

	for j in ipairs(allTierInfo) do
		local tierLevel = allTierInfo[j]["unlockLevel"]

		for index, azeritePowerIDs in pairs (allTierInfo[j]["azeritePowerIDs"]) do
		
			if azeritePowerIDs == 13 then break end -- Ignore +5 item level tier

			AvailableAzeriteTraits[location][j] = AvailableAzeriteTraits[location][j] or {}
			AvailableAzeriteTraits[location][j]["unlockLevel"] = tierLevel
			AvailableAzeriteTraits[location][j]["azeritePowerIDs"] = AvailableAzeriteTraits[location][j]["azeritePowerIDs"] or {}
			AvailableAzeriteTraits[location][j]["azeritePowerIDs"][index] = azeritePowerIDs

			local azeriteSpellID = AzeriteTooltip_GetSpellID(azeritePowerIDs)				
			local azeritePowerName, _, icon = GetSpellInfo(azeriteSpellID)
			local isSelected = C_AzeriteEmpoweredItem.IsPowerSelected(locationData, azeritePowerIDs)

			if isSelected then
				SelectedAzeriteTraits[location][j] = SelectedAzeriteTraits[location][j] or {}
				SelectedAzeriteTraits[location][j]["azeritePowerIDs"] = SelectedAzeriteTraits[location][j]["azeritePowerIDs"] or {}
				SelectedAzeriteTraits[location][j]["azeritePowerIDs"][index] = azeritePowerIDs

				talent_options.args.stats.args[location..j]  = {
					name = azeritePowerName.."\n"..GetSpellDescription(azeriteSpellID),
					type = "description",
					desc  = function() return GetSpellDescription(azeriteSpellID) end,
					image = icon,
					imageWidth = 20,
					imageHeight = 20,
					width = "full",
					icon = icon,
					fontSize  = "medium",
					order = locationIDs[location]+tonumber("."..j),
				}
	
			end

			Debug(("Trait Level: %s"):format(j))
			Debug(("Power ID: %s"):format(azeritePowerIDs))
			Debug(("Power SpellID: %s"):format(azeriteSpellID))
			Debug(("Power Name: %s"):format(azeritePowerName))
			Debug(("Unlock Level: %s"):format(tierLevel))
			Debug(("Is Selected Power: %s"):format(tostring(isSelected)))
		end

	end
	local HasAnyUnselectedPowers = C_AzeriteEmpoweredItem.HasAnyUnselectedPowers(locationData)
	UnselectedPowers[location] = HasAnyUnselectedPowers

end


--Cycles though the various azerite power ids and builds a database info from it
function AF:BuildAzeriteDataTables()
	wipe(azeriteTraits)
	azeriteTraits = {}

	for traitID, data in pairs(AzeriteForge.TraitData) do
		if validTrait(traitID) then
			local name, _, icon = GetSpellInfo(AzeriteForge.TraitData[traitID]["spellId"])
			azeriteTraits[traitID] = data
			azeriteTraits[traitID]["icon"] = icon
			azeriteTraits[traitID]["valid"] = true
			azeriteTraits[traitID]["name"] = name
			AzeriteTraitsName_to_ID[name] = traitID
		end
	end

	AF:CreateTraitMenu()
end


--Handler to import AzeriteForge export strings
local function AZForgeImport(data)
	wipe(traitRanks)
	ClearDebugger()
	local traits = {string.split("^",data )}

	for i, traitData in ipairs(traits) do
		for traitID, rankData in string.gmatch(traitData,"%[(%w+)%](.+)") do
			traitRanks[tonumber(traitID)] = traitRanks[tonumber(traitID)] or {}
			for id, rank in string.gmatch(rankData,"(%w+):(%p?%w+),") do
				traitRanks[tonumber(traitID)][tonumber(id)] = tonumber(rank)
			end
		end
	end
	print("Importing AzeriteForge data")
end



--modified code from AzeritePowerWeights
local reallyBigNumber = 2^31 - 1 -- 2147483647, go over this and errors are thrown

local pvpPairs = { -- Used for Exporting/Importing. These powers have same effects, but are different powers
	-- Horde
	[486] = 6,
	[487] = 6,
	[488] = 6,
	[489] = 6,
	[490] = 6,
	[491] = 6,

	-- Alliance
	[492] = -6,
	[493] = -6,
	[494] = -6,
	[495] = -6,
	[496] = -6,
	[497] = -6
}

--Inserts data from AzeritePowerWeights export strings
local function insertCustomScalesData(classIndex, specID, powerData) -- Inser into table
	local t = {}
	if powerData and powerData ~= "" then -- String to table
		for _, weight in pairs({ strsplit(",", powerData) }) do
			local azeritePowerID, value = strsplit("=", strtrim(weight))
			azeritePowerID = tonumber(azeritePowerID) or nil
			value = tonumber(value) or nil

			traitRanks[azeritePowerID] = traitRanks[azeritePowerID] or {}

			if azeritePowerID and value and value > 0 then
				value = value > reallyBigNumber and reallyBigNumber or value

				tinsert(traitRanks[azeritePowerID],  value)

				if pvpPairs[azeritePowerID] then -- Mirror PvP Powers for both factions
					local pvpID = azeritePowerID + pvpPairs[azeritePowerID]
					traitRanks[pvpID] = traitRanks[pvpID] or {}
					tinsert(traitRanks[pvpID],  value)
				end
			end
		end
	end

end


--Processes AzeritePowerWeights export strings
local function AzeritePowerWeightsImport(data)
		local player_spec = GetSpecialization()
		local player_specID = GetSpecializationInfo(spec)
		local template = "^%s*%(%s*AzeritePowerWeights%s*:%s*(%d+)%s*:%s*\"([^\"]+)\"%s*:%s*(%d+)%s*:%s*(%d+)%s*:%s*(.+)%s*%)%s*$"

		local startPos, endPos, stringVersion, scaleName, classID, specID, powerWeights = strfind(data, template)
		stringVersion = tonumber(stringVersion) or 0
		scaleName = scaleName or L.ScaleName_Unnamed
		powerWeights = powerWeights or ""
		classID = tonumber(classID) or nil
		specID = tonumber(specID) or nil

		if not specID == player_spec then
			print("import not for this spec")
			return false
		end

		if type(classID) ~= "number" or classID < 1 or type(specID) ~= "number" or specID < 1 then -- No class or no spec, this really shouldn't happen ever
			--Print(L.ImportPopup_Error_MalformedString)
		else -- Everything seems to be OK
			local result = insertCustomScalesData(classID, specID, powerWeights)
			print("Importing AzeritePowerWeights data")
		end

end


--Imports text data into the traitsRanks Table
--Data format is ["localized trait name" or trait id, Rank1, Rank2, Rank3],
--Multiple traits can be imported if seperated by commas and only one Rank is needed
function AF:ImportData(data)
	if not data then return end

	local validAddons = {"AZFORGE", "AzeritePowerWeights"}
	local exportAddon = false

	for _, addonName in ipairs(validAddons) do
		local isfound = strfind(data, addonName)

		if isfound then 
			exportAddon = addonName
		end
	end

	if not exportAddon then print("Not Valid Import Data"); return end

	if exportAddon == "AZFORGE" then 

		AZForgeImport(data)

	elseif exportAddon == "AzeritePowerWeights" then

		AzeritePowerWeightsImport(data)
	end
	 AzeriteForge.ImportWindow:Hide()
end


--Parses Trait data and dumps it to a window
function AF:ExportData()
	local text = "AZFORGE^"
	for id, data in pairs(traitRanks) do
		text = text.."["..id.."]"

		
		for i,d in pairs(data) do
			text = text..tostring(i)..":"..tostring(d)..","
		end
		text = text.."^"
	end

	return Export(text)	 
end



function AF:TextGetter(traitID)
	local text = ""
		for i,d in pairs(traitRanks[traitID]) do
			text = text.."["..tostring(i).."]:"..tostring(d)..","
		end
	return text 
end


function AF:ParseText(traitID, val)
	local text = {string.split(",",val)}

	if string.find(text[1], "%[") then
		for i,data in ipairs(text) do
			for w,x in string.gmatch(data,"%[(%w+)%]:(%p?%w+)") do
				traitRanks[tonumber(traitID)][tonumber(w)] = tonumber(x)
			end
		end
	else
		for i, data in ipairs(text) do
			text[i] = tonumber(data)
		end
		traitRanks[traitID] = text
	end
end


function AF.loadDefaultData(DB)
	local traitRanks = {}
	spec = GetSpecialization()
	specID = GetSpecializationInfo(spec)

	if not AzeriteForge[DB][specID] then
		Debug("No default data found - possibly healer class")
		return traitRanks 
	end

	for name, data in pairs(AzeriteForge[DB][specID]) do	
		 if AzeriteTraitsName_to_ID[name] then
			traitRanks[AzeriteTraitsName_to_ID[name]] = data
		 end
	end
	return traitRanks
end


--loads defaults into saved variables table
function AF:LoadClassTraitRanks(DB)
	traitRanks = AzeriteForgeDB.SavedSpecData[specID] or AF.loadDefaultData("StackData")
	AzeriteForgeDB.SavedSpecData[specID] = traitRanks
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

--

local function findItemLocation(itemLink)
	for i = 0, NUM_BAG_SLOTS do
		for j = 1, GetContainerNumSlots(i) do
			local _, _, _, _, _, _, link = GetContainerItemInfo(i, j);
			if link == itemLink then 
				return i, j
			end
		end
	end
	return false
end


local function getItemsLocation(link)

	for x,y in pairs (locationIDs) do
		local itemLink = GetInventoryItemLink("player", y)
		if itemLink == link then 
		
			return ItemLocation:CreateFromEquipmentSlot(y)
		end
	end


	local bag, slot = findItemLocation(link)

	if bag then 
		return ItemLocation:CreateFromBagAndSlot(bag, slot)

	end

	return false
end


function AF:UpdateBagDataMenu(filter, filterLocation)
	filterLocation = filterLocation or ""
	local filterText = filter or ""
	local count = 0
	local sortTable = {}
	local guiMenu = talent_options.args.bagData.args
	wipe(guiMenu)
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
		local location = getItemsLocation(link)

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


--
function AF:CreateTraitMenu()
	local count = 0
	local sortTable = {}
	for id, data in pairs(azeriteTraits) do
		tinsert(sortTable, id)
	end

	--clear any previous data
	for x in pairs(options.args.weights.args) do
		if x== "Topheader" or x=="search" or x == "filler1" then
		else
			options.args.weights.args[x] = nil
		end
	end


	table.sort(sortTable, function(a,b) return azeriteTraits[a].name <azeriteTraits[b].name end)
	for i,x in pairs (sortTable) do

	end

	for index, traitID in pairs(sortTable) do
		local name = azeriteTraits[traitID].name
		local icon = azeriteTraits[traitID].icon
		local spellID = azeriteTraits[traitID].spellID
	
		if name and azeriteTraits[traitID].valid then 
		count = count + 1
			options.args.weights.args[name] = {
			type = "header",
			name = name,
			width = "full",
			order = index,
			hidden = function() local search = nil; if searchbar then search = not string.match(string.lower(azeriteTraits[traitID].name), string.lower(searchbar))end; return search or not azeriteTraits[traitID].valid end,
			}

			options.args.weights.args[name.."1"] = {
			name = function() return name end,
			type = "execute",
			--desc  = function() return GetSpellDescription(azeriteTraits[traitID].spellId) end,
			image = icon,
			width = "normal",
			icon = icon,
			order = index+.1,
			hidden = function() local search = nil; if searchbar then search = not string.match(string.lower(azeriteTraits[traitID].name), string.lower(searchbar))end; return search or not azeriteTraits[traitID].valid end,
			}

			options.args.weights.args[name.."2"] = {
			name = " ",
			desc = function() return GetSpellDescription(azeriteTraits[traitID].spellId) end,
			type = "input",
			multiline  = 3,
			width = "normal",
			icon = icon,
			order = index+.2,
			hidden = function() local search = nil; if searchbar then search = not string.match(string.lower(azeriteTraits[traitID].name), string.lower(searchbar))end; return search or not azeriteTraits[traitID].valid end,
			get = function(info)  
				if not traitRanks[traitID] then  return "" end
				return AF:TextGetter(traitID)
				end,
			set = function(info,val) traitRanks[traitID] = {}; return AF:ParseText(traitID,val) end,
			}
			

		end

	end
end



--###########################################
--Frame Generation


--AzeriteEmpoweredItemUI.BorderFrame.portrait

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


local function CreateGenericFrame()
	local window = CreateFrame("Frame", nil, UIParent)
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
	titlebg:SetTexture(251966) --"Interface\\PaperDollInfoFrame\\UI-GearManager-Title-Background"
	titlebg:SetPoint("TOPLEFT", 9, -6)
	titlebg:SetPoint("BOTTOMRIGHT", window, "TOPRIGHT", -28, -24)

	local title = window:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	title:SetPoint("CENTER", titlebg, -6, -3)
	title:SetTextColor(1, 1, 1, 1)
	window.title = title

	local dialogbg = window:CreateTexture(nil, "BACKGROUND")
	dialogbg:SetTexture(136548) --"Interface\\PaperDollInfoFrame\\UI-Character-CharacterTab-L1"
	dialogbg:SetPoint("TOPLEFT", 8, -12)
	dialogbg:SetPoint("BOTTOMRIGHT", -6, 8)
	dialogbg:SetTexCoord(0.255, 1, 0.29, 1)

	local topleft = window:CreateTexture(nil, "BORDER")
	topleft:SetTexture(251963) --"Interface\\PaperDollInfoFrame\\UI-GearManager-Border"
	topleft:SetWidth(64)
	topleft:SetHeight(64)
	topleft:SetPoint("TOPLEFT")
	topleft:SetTexCoord(0.501953125, 0.625, 0, 1)

	local topright = window:CreateTexture(nil, "BORDER")
	topright:SetTexture(251963) --"Interface\\PaperDollInfoFrame\\UI-GearManager-Border"
	topright:SetWidth(64)
	topright:SetHeight(64)
	topright:SetPoint("TOPRIGHT")
	topright:SetTexCoord(0.625, 0.75, 0, 1)

	local top = window:CreateTexture(nil, "BORDER")
	top:SetTexture(251963) --"Interface\\PaperDollInfoFrame\\UI-GearManager-Border"
	top:SetHeight(64)
	top:SetPoint("TOPLEFT", topleft, "TOPRIGHT")
	top:SetPoint("TOPRIGHT", topright, "TOPLEFT")
	top:SetTexCoord(0.25, 0.369140625, 0, 1)

	local bottomleft = window:CreateTexture(nil, "BORDER")
	bottomleft:SetTexture(251963) --"Interface\\PaperDollInfoFrame\\UI-GearManager-Border"
	bottomleft:SetWidth(64)
	bottomleft:SetHeight(64)
	bottomleft:SetPoint("BOTTOMLEFT")
	bottomleft:SetTexCoord(0.751953125, 0.875, 0, 1)

	local bottomright = window:CreateTexture(nil, "BORDER")
	bottomright:SetTexture(251963) --"Interface\\PaperDollInfoFrame\\UI-GearManager-Border"
	bottomright:SetWidth(64)
	bottomright:SetHeight(64)
	bottomright:SetPoint("BOTTOMRIGHT")
	bottomright:SetTexCoord(0.875, 1, 0, 1)

	local bottom = window:CreateTexture(nil, "BORDER")
	bottom:SetTexture(251963) --"Interface\\PaperDollInfoFrame\\UI-GearManager-Border"
	bottom:SetHeight(64)
	bottom:SetPoint("BOTTOMLEFT", bottomleft, "BOTTOMRIGHT")
	bottom:SetPoint("BOTTOMRIGHT", bottomright, "BOTTOMLEFT")
	bottom:SetTexCoord(0.376953125, 0.498046875, 0, 1)

	local left = window:CreateTexture(nil, "BORDER")
	left:SetTexture(251963) --"Interface\\PaperDollInfoFrame\\UI-GearManager-Border"
	left:SetWidth(64)
	left:SetPoint("TOPLEFT", topleft, "BOTTOMLEFT")
	left:SetPoint("BOTTOMLEFT", bottomleft, "TOPLEFT")
	left:SetTexCoord(0.001953125, 0.125, 0, 1)

	local right = window:CreateTexture(nil, "BORDER")
	right:SetTexture(251963) --"Interface\\PaperDollInfoFrame\\UI-GearManager-Border"
	right:SetWidth(64)
	right:SetPoint("TOPRIGHT", topright, "BOTTOMRIGHT")
	right:SetPoint("BOTTOMRIGHT", bottomright, "TOPRIGHT")
	right:SetTexCoord(0.1171875, 0.2421875, 0, 1)

	local close = CreateFrame("Button", nil, window, "UIPanelCloseButton")
	close:SetPoint("TOPRIGHT", 2, 1)
	close:SetScript("OnClick", function() window:Hide() end)

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
	local window = CreateGenericFrame(AzeriteEmpoweredItemUI)
	
	window:ClearAllPoints()
	window:SetPoint("TOPLEFT", AzeriteEmpoweredItemUI, "TOPLEFT",-5,-20)
	window:SetPoint("BOTTOMRIGHT", AzeriteEmpoweredItemUI,"BOTTOMRIGHT")
	--AF:HookScript(CharacterFrame, "OnShow", function()  f:Show() end)
	window:SetParent(UIParent)
	--AF:HookScript(AzeriteEmpoweredItemUI, "OnHide", function() window:Hide() end)
	window.title:SetText(L["Azerite Gear"])
	window:SetScript("OnShow", function(self)
		buttons.inventoryButton:LockHighlight()
			AF:UpdateBagDataMenu("")

		end)

	window:SetScript("OnHide", function(self)
	buttons.inventoryButton:UnlockHighlight()
		--f:Hide()
		--RestoreUIPanelArea("CharacterFrame")
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
--Tabs have issues if the frame parent is set to CharacterFrame.  
	local f = CreateFrame('Frame', "AzeriteCharacterPanel", UIPARENT)
	f:SetSize(1, 5)
	f:ClearAllPoints()
	f:SetPoint("TOPLEFT",CharacterFrameTab3,"TOPRIGHT", -15 ,0)

	local t = CreateFrame("Button", "AzeriteCharacterPanelTab1", f, "CharacterFrameTabButtonTemplate")
	t:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
	t.id = 1
	t:SetScript("OnLoad", nil)
	t:SetScript("OnShow", function()return end)
	t:SetScript("OnEvent", function()return end)
	t:SetScript("OnClick", function()return end)
	t:SetText("Azerite")





	AF:HookScript(CharacterFrame, "OnShow", function()  f:Show(); buttons.characterButton:LockHighlight() end)
	AF:HookScript(CharacterFrame, "OnHide", function() f:Hide(); buttons.characterButton:UnlockHighlight() end)

	PanelTemplates_SetNumTabs(t, 1);
	PanelTemplates_DeselectTab(t, 1);

	t:SetScript("OnClick", function(self, button, down)
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

	t:SetScript("OnEnter",
		function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
			GameTooltip:SetText("Azerite", 1.0,1.0,1.0 );
					
		end
	)

	t:SetScript("OnLeave",
		function()
			GameTooltip:Hide()
		end
	)
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
	local f = CreateFrame('Frame', "AzeriteForge_PowersList", UIParent)
	f:SetClampedToScreen(true)
	f:SetSize(250, 160)
	f:SetPoint("TOPLEFT",AzeriteEmpoweredItemUI,"TOPRIGHT")
	f:SetPoint("BOTTOMLEFT",AzeriteEmpoweredItemUI,"BOTTOMRIGHT")
	f:Hide()
	f:EnableMouse(true)
	f:SetFrameStrata('DIALOG')
	f:SetMovable(false)
	f:SetToplevel(true)



	f.border = f:CreateTexture()
	f.border:SetAllPoints()
	f.border:SetColorTexture(0,0,0,1)
	f.border:SetTexture([[Interface\Tooltips\UI-Tooltip-Background]])
	f.border:SetDrawLayer('BORDER')

	f.background = f:CreateTexture()
	f.background:SetPoint('TOPLEFT', f, 'TOPLEFT', 1, -1)
	f.background:SetPoint('BOTTOMRIGHT', f, 'BOTTOMRIGHT', 65, 1)
	--f.background:SetColorTexture(0.1,0.1,0.1,1)
	f.background:SetTexture("Interface\\PetBattles\\MountJournal-BG")
	f.background:SetDrawLayer('ARTWORK')

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
	content:SetPoint("BOTTOMRIGHT",-15,15)
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
		LibStub("AceConfigDialog-3.0"):Open("AzeriteForge_Talents", widget, "stats")
		buttons.powerWindowButton:LockHighlight()
		f:SetToplevel(true)
		end)

	f:SetScript("OnHide", function(self)
	buttons.powerWindowButton:UnlockHighlight()
		--f:Hide()
		--RestoreUIPanelArea("CharacterFrame")
		end)

	LibStub("AceGUI-3.0"):RegisterAsContainer(widget)


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

	AF:HookScript(AzeriteEmpoweredItemUI, "OnShow", function()  f:Show(); overlay:Show() end)
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
			GameTooltip:SetText(L["Head Azerite Powers"], 1, 1, 1)
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
			GameTooltip:SetText(L["Toggle Shoulder Azerite Panel"], 1, 1, 1)
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
			GameTooltip:SetText(L["Toggle Chest Azerite Panel"], 1, 1, 1)
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
				LibStub("AceConfigDialog-3.0"):Open("AzeriteForge_Talents", widget, "stats")
				f:Show()
			end
		end

		end)

	powerWindowButton:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner (self, "ANCHOR_RIGHT")
			GameTooltip:SetText(L["Selected Power List"], 1, 1, 1)
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


local tooltipCatcher = CreateFrame("GameTooltip",nil, UIParent)
--###########################
--Tooltip stuff
function AF:BuildTraitText(itemLink, tooltip, name, force)
	if force then tooltip = tooltipCatcher end
	
	-- Current Azerite Level
	local azeriteItemLocation = C_AzeriteItem.FindActiveAzeriteItem()
	if azeriteItemLocation then
		currentLevel = C_AzeriteItem.GetPowerLevel(azeriteItemLocation)
	end

	local specID = GetSpecializationInfo(GetSpecialization())
	local allTierInfo = C_AzeriteEmpoweredItem.GetAllTierInfoByItemID(itemLink)

	if not allTierInfo[1]["azeritePowerIDs"][1] then return end

	local iconSize = 15
	local iconShade = 255
	local fullText = ""

	tooltip:AddLine("\n"..L["Available Azerite Powers:"])

	for j=1, 3 do
			local tierLevel = allTierInfo[j]["unlockLevel"]
			local azeritePowerID = allTierInfo[j]["azeritePowerIDs"][1]


			if azeritePowerID == 13 then break end -- Ignore +5 item level tier

			local azeriteTooltipText = " "

			if tierLevel <= currentLevel then
				azeriteTooltipText = GREEN_FONT_COLOR_CODE.."Level "..tierLevel..": |r\n"..azeriteTooltipText
			else
				azeriteTooltipText = GRAY_FONT_COLOR_CODE.."Level "..tierLevel..": |r\n"..azeriteTooltipText
			end
			local textBreakCounter = 0 
			local empoweredLocation = getItemsLocation(itemLink)
			for i, _ in pairs(allTierInfo[j]["azeritePowerIDs"]) do
				local azeritePowerID = allTierInfo[j]["azeritePowerIDs"][i]
				local azeriteSpellID = AzeriteTooltip_GetSpellID(azeritePowerID)
				local azeritePowerName, _, icon = GetSpellInfo(azeriteSpellID)
				local iconText = "|T"..icon..(":%d:%d:0:-7:64:64:4:60:4:60:%d:%d:%d|t")
				local traitText = ""
				local fontColor = GREEN_FONT_COLOR_CODE
				local textBreak = ""
				local rank = getTraitRanking(azeritePowerID, azeriteItemLocation)
				local isSelected
				local selectedText = ">>%s<<"

				if empoweredLocation and azeritePowerID then 
					isSelected = C_AzeriteEmpoweredItem.IsPowerSelected(empoweredLocation, azeritePowerID)
				end
						
				textBreakCounter = textBreakCounter+1
				if textBreakCounter == 2 then
					textBreakCounter = 0
					textBreak = "\n"
				end

				if tierLevel <= currentLevel then
					
					if isSelected and not C_AzeriteEmpoweredItem.IsPowerAvailableForSpec(azeritePowerID, specID) then
						iconText = selectedText:format(iconText) --">>"..iconText.."<<"
						fontColor = RED_FONT_COLOR_CODE
					elseif isSelected then
						iconText = selectedText:format(iconText) --">>"..iconText.."<<"

					elseif C_AzeriteEmpoweredItem.IsPowerAvailableForSpec(azeritePowerID, specID) then

						fontColor = LIGHTYELLOW_FONT_COLOR_CODE
					
					elseif not Config.tooltipCurrentTraits then
						iconShade = 150
						fontColor = DISABLED_FONT_COLOR_CODE
					else 
						fontColor = GRAY_FONT_COLOR_CODE
					end
				else
					iconShade = 150
					fontColor = GRAY_FONT_COLOR_CODE
				end

				local azeriteIcon = iconText:format(iconSize,iconSize,iconShade,iconShade,iconShade)
				
				--iconText = (rank  and iconText..rank.." ") or iconText
				
				local traitText = (force or not Config.tooltipIconsOnly) and fontColor..azeritePowerName or ""
				if rank then traitText = traitText.. " ("..rank..") " end
				traitText = traitText..textBreak
				azeriteTooltipText = ((force or not Config.tooltipCurrentTraits or (Config.tooltipCurrentTraits and C_AzeriteEmpoweredItem.IsPowerAvailableForSpec(azeritePowerID, specID))) and azeriteTooltipText.."  "..azeriteIcon.."  "..traitText) or azeriteTooltipText

			end

			tooltip:AddLine(azeriteTooltipText)
			fullText = fullText.. azeriteTooltipText
			
	end
	return  fullText
end


function AF:OnTooltipSetItem(self,...)
	local name, link = self:GetItem()
  	if not name then return end

  	if C_AzeriteEmpoweredItem.IsAzeriteEmpoweredItemByID(link)  then
    		AF:BuildTraitText(link, self, name)
	end
end


--#####################################
--Modified blizzard plugins

LoadAddOn("Blizzard_AzeriteUI")
local function AzeriteEmpoweredItemPowerMixin_OnEnter(self,...)
	local location = self.azeriteItemDataSource:GetItemLocation()
	local duplicateLocations = AF:FindStackedTraits(self:GetAzeritePowerID(),location,SelectedAzeriteTraits)

	if duplicateLocations then
		GameTooltip_AddColoredLine(GameTooltip, (L["Found on: %s"]):format(duplicateLocations), RED_FONT_COLOR);
	end

	GameTooltip:Show();
end

AF:SecureHook(AzeriteEmpoweredItemPowerMixin,"OnEnter", AzeriteEmpoweredItemPowerMixin_OnEnter)



local function AzeriteEmpoweredItemPowerMixin_Setup(self,...)

	local f = self:CreateFontString(nil, "DIALOG", "GameFontNormalHuge3Outline")
	f:SetTextColor(HIGHLIGHT_FONT_COLOR:GetRGB())
	f:ClearAllPoints()
	f:SetPoint("CENTER")
	f:Hide()
	self.AdditionalTraits = f

	local f = self:CreateFontString(nil, "DIALOG", "GameFontNormalHuge3Outline")
	f:SetTextColor(GREEN_FONT_COLOR:GetRGB())
	f:ClearAllPoints()
	f:SetPoint("CENTER",0,-20)
	f:Hide()
	self.TraitRank = f
end

AF:SecureHook(AzeriteEmpoweredItemPowerMixin,"Setup", AzeriteEmpoweredItemPowerMixin_Setup)


local function AzeriteEmpoweredItemPowerMixin_Reset(self)
	if self.AdditionalTraits then
		self.AdditionalTraits:Hide()
		self.TraitRank:Hide()
	end
end
AF:SecureHook(AzeriteEmpoweredItemPowerMixin,"Reset", AzeriteEmpoweredItemPowerMixin_Reset)



local function UpdateValues(location)
	local max = 0
	for id, rank in pairs(maxValue[location]) do

		if rank >= max then
			max = rank

		end
	end

	for id, rank in pairs(maxValue[location]) do
		if rank >= max then
			id.TraitRank:SetTextColor(GREEN_FONT_COLOR:GetRGB())
		else 
			id.TraitRank:SetTextColor(YELLOW_FONT_COLOR:GetRGB())
		end

		if string.find(rank, "-") then 
			id.TraitRank:SetTextColor(RED_FONT_COLOR:GetRGB())
		end
	end
end


local function AzeriteEmpoweredItemPowerMixin_OnShow(self,...)
	if self.azeriteItemDataSource then 
		local location = self.azeriteItemDataSource:GetItemLocation()
		local HasAnyUnselectedPowers = C_AzeriteEmpoweredItem.HasAnyUnselectedPowers(location)
		local DB = SelectedAzeriteTraits

		local _, duplicateTraits = AF:FindStackedTraits(self:GetAzeritePowerID(),location, DB)


		if HasAnyUnselectedPowers then
			DB = AvailableAzeriteTraits
		end

		local traitRank = getTraitRanking(self:GetAzeritePowerID(),location, DB)


		maxValue[location] = maxValue[location] or {}
		maxValue[location][self] = traitRank or 0

		UpdateValues(location)

		if traitRank and self.TraitRank then --and HasAnyUnselectedPowers then 
			self.AdditionalTraits:SetPoint("CENTER",0,20)
			if string.find(traitRank, "-") then 
				self.TraitRank:SetText(("%s"):format(traitRank))
				self.TraitRank:SetTextColor(RED_FONT_COLOR:GetRGB())
			else
				self.TraitRank:SetText(("+%s"):format(traitRank))
			end
			self.TraitRank:Show()
		else
			self.TraitRank:Hide()
			self.AdditionalTraits:SetPoint("CENTER",0,0)
		end

		if self.AdditionalTraits and duplicateTraits > 0 then 
			self.AdditionalTraits:SetText(("%sX"):format(duplicateTraits+1))
			self.AdditionalTraits:Show()
		else
			self.AdditionalTraits:Hide()
		end
	end
end
AF:SecureHook(AzeriteEmpoweredItemPowerMixin,"OnShow", AzeriteEmpoweredItemPowerMixin_OnShow)