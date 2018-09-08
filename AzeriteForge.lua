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

local BagScrollFrame = AF.BagScrollFrame
local currentXp, currentMaxXp, startXp =  0, 0 , 0 
local currentLevel, startLevel = 0 , 0 
local lastXpGain = 0
local azeriteItemLocation
local azeriteIcon = "Interface/Icons/Inv_smallazeriteshard"
local azeriteItemIcon = azeriteIcon
local COLOR_GREEN  = CreateColor(0.1, 0.8, 0.1, 1)
local spec = 0
local specID  = 0
local specName
local className, classFile, classID
local UnselectedPowersCount = 0

local powerLocationButtonIDs = AF.powerLocationButtonIDs

local bagDataStorage = {}

local globalDb 
local configDb 
local WeeklyQuestGain = 0
local WeeklyQuestRequired = 0
AF.searchbar = nil


local UnselectedLocationTraits = {}
local azeriteTraits = {}
AF.traitRanks = {}
local ap = {}
local ReforgeCost = {}
local buttons = AF.Buttons
local AzeriteTraitsName_to_ID ={}
local UnselectedPowers = AF.UnselectedPowers
local AzeriteLocations = {["Head"] = ItemLocation:CreateFromEquipmentSlot(1),
			["Shoulder"] = ItemLocation:CreateFromEquipmentSlot(3), 
			["Chest"]= ItemLocation:CreateFromEquipmentSlot(5),
			[1] = "Head",
			[3] = "Shoulder",
			[5] = "Chest",}
local locationIDs = {["Head"] = 1, ["Shoulder"] = 3, ["Chest"] = 5,}
local AvailableAzeriteTraits = {["Shoulder"] = {}, ["Head"] = {}, ["Chest"]= {},}
local SelectedAzeriteTraits = {["Shoulder"] = {}, ["Head"] = {}, ["Chest"]= {},}


function AF.ReturnSelectedAzeriteTraits()
	return SelectedAzeriteTraits

end

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

function AF.getTraitRanking(traitID, locationID)
	if not AF.traitRanks[traitID] then return false  end

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


	if #AF.traitRanks[traitID] >0 then
		rank = 0
		local  _, stackedRank = AF:FindStackedTraits(traitID, locationID, SelectedAzeriteTraits)
		local maxRank = 1
	 
		for index, itemrank in pairs(AF.traitRanks[traitID]) do
			maxRank = itemrank
		end

		rank = AF.traitRanks[traitID][stackedRank + 1] or maxRank


	else
		rank = itemLevel
		sortTable = {}
		for id, data in pairs(AF.traitRanks[traitID]) do
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

		rank = AF.traitRanks[traitID][rank]	
	end

	return rank
end

local function toggleAF_CharacterPage_Icon(toggle)

	local _, _, _, _, _, _, _, _, _, _, _, _, wasEarnedByMe = GetAchievementInfo(12918)

	if not wasEarnedByMe then AF_CharacterPage_Icon:Hide(); return end

	if toggle then 
		AF_CharacterPage_Icon:Show()
	else
		AF_CharacterPage_Icon:Hide()
	end



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

local newProfileName = ""



function AF.duplicateNameCheck(profileName)

	for name in pairs(AF.db.global.userWeightLists) do
		if string.find(tostring(name), tostring(profileName)) then
			print("Duplicate Name Found. Choose another name")
			return true
		else
			
		end

	end
	return false
end


local function createNewProfile(profileName)

	if not profileName or profileName == "" then print("Please enter a name"); return false end

	if AF.duplicateNameCheck(profileName) then return  end

	spec = GetSpecialization()
	specID, specName = GetSpecializationInfo(spec) 
	className, classFile, classID = UnitClass("player")

	AF.db.global.userWeightLists[profileName] = {}
	AF.db.global.userWeightLists[profileName]["specID"] = specID
	AF.db.global.userWeightLists[profileName]["classID"] = classID
	--AF.db.global.userWeightLists[profileName]

	print(("%s - Profile Created"):format(profileName))
	newProfileName = ""

	AF.BuildWeightedProfileList()
	return true
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
			showRankTotal = {
				type = "toggle",
				name = L["Show Ranks Totals in Tooltip"],
				order = 10.1,
				set = function(info,val) AzeriteForge.db.profile.showRankTotal = val end,
				get = function(info) return AzeriteForge.db.profile.showRankTotal end,
				width = "full",
				},
			misctipHeader = {
				type = "header",
				name =L["Misc Options"],
				order =11,
				},
			showCharacterPageIcon = {
				type = "toggle",
				name = L["Display Azerite Power Icon on Character Sheet"],
				order = 12,
				set = function(info,val) AzeriteForge.db.profile.showCharacterPageIcon = val; toggleAF_CharacterPage_Icon(val) end,
				get = function(info) return AzeriteForge.db.profile.showCharacterPageIcon end,
				width = "full",
				},
			unavailableAlert = {
				type = "toggle",
				name = L["Alert user if equiped item has un-useable trait"],
				order = 13,
				set = function(info,val) AzeriteForge.db.profile.unavailableAlert = val end,
				get = function(info) return AzeriteForge.db.profile.unavailableAlert end,
				width = "full",
				},
			unavailableAlertSound = {
				type = "toggle",
				name = L["Play Alert Sound when triggered"],
				order = 14,
				set = function(info,val) AzeriteForge.db.profile.unavailableAlertsound = val end,
				get = function(info) return AzeriteForge.db.profile.unavailableAlertsound end,
				width = "full",
				},




				


			},

			
		},
	weights = {
		    name = L["Weight Profiles"],
		    handler = AzeriteForge,
		    type = "group",
		    args = {
		    	profileHeader = {
				name = "Selected Profile",
				type = "header",
				width = "full",
				order = .01,
				},
		    	userDefinedName = {
				name = "Profile Name",
				type = "input",
				width = "full",
				order = .02,
				set = function(info,val)  AF.renameProfile(AF.db.char.weightProfile[specID], val);AF.db.char.weightProfile[specID] = val  end,
				get = function(info) return AF.db.char.weightProfile[specID]  end
				},
			profileDescription = {
				name = function() 
				local profile =  AF.db.char.weightProfile[specID]
				--print(specID)
				if not AF.db.global.userWeightLists[profile] then return end
				local profileSpecID = AF.db.global.userWeightLists[profile]["specID"] or 0
				local _, name, _,icon, _, class = GetSpecializationInfoByID(profileSpecID)
				if icon then 
					icon = "|T"..icon..(":25:25:|t")
				else
					icon = ""
				end
				return ("%sClass: %s, Spec: %s"):format(icon or "",class or "", name or"") end,
				type = "description",
				width = "full",
				order = .03,
				},

			resetStacking = {
				type = "execute",
				name = L["Reset Default Data with Stacking Data"],
				order = 1,
				width = "double",
				func = function() local data = AF.loadDefaultData("StackData")
					local profile = AF.db.char.weightProfile[specID]
					wipe(AF.traitRanks)
					AF.traitRanks = CopyTable(data)
					AF.traitRanks["specID"] = specID
					AF.traitRanks["classID"] = classID
					AF.db.global.userWeightLists[profile] = AF.traitRanks
					end,	
				},
			resetIlevel = {
				type = "execute",
				name = L["Reset Default Data with iLevel Data"],
				order = 2,
				width = "double",
				func = function() local data = AF.loadDefaultData("iLevelData")
					local profile = AF.db.char.weightProfile[specID]
					wipe(AF.traitRanks)
					AF.traitRanks = CopyTable(data)
					AF.traitRanks["specID"] = specID
					AF.traitRanks["classID"] = classID
					AF.db.global.userWeightLists[profile] = AF.traitRanks
					end,
					
				},
			clearData = {
				type = "execute",
				name = L["Clear all data"],
				order = 3,
				width = "double",
				func = function()
					local profile = AF.db.char.weightProfile[specID]
					--local DB = AF.db.global.userWeightLists[weightProfile]
					wipe(AF.traitRanks)
					AF.traitRanks["specID"] = specID
					AF.traitRanks["classID"] = classID
					AF.db.global.userWeightLists[profile] = AF.traitRanks

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

			createNewProfile = {
				name = L["Create New Profile"],
				type = "group",
				handler = AzeriteForge,
				type = "group",
				inline =false,
				order = 1,
				args = {
				createProfileTextbox = {
					name = "Profile Name",
					type = "input",
					width = "full",
					order = .01,
					set = function(info,val) newProfileName = val  end,
					get = function(info)  return newProfileName end,
						},
				createProfilebutton = {
				type = "execute",
				name = L["Create Profile"],
				order = 5,
				width = "double",
				func = function(info, val)  createNewProfile(newProfileName)end,	
				},
					},


				},

		    	search = {
				name = "Search",
				type = "input",
				width = "full",
				order = 7,
				set = function(info,val) AF.searchbar = val end,
				get = function(info) return AF.searchbar end
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
				set = function(info,val) AF.searchbar = val end,
				get = function(info) return AF.searchbar end
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
		unavailableAlert = false,
		unavailableAlertsound = false, 
		showCharacterPageIcon = true,
		showRankTotal = true
	},
	global = {
		userWeightLists = {}
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
        --LibStub("AceConfigDialog-3.0"):Open("AzeriteForge_Talents", widget, "stats")

    else
        LibStub("AceConfigCmd-3.0"):HandleCommand("az", "AzeriteForge", input)
    end
end



function AF:GetAzeriteTraits()
	AvailableAzeriteTraits = {["Shoulder"] = {}, ["Head"] = {}, ["Chest"]= {},}
	SelectedAzeriteTraits = {["Shoulder"] = {}, ["Head"] = {}, ["Chest"]= {},}

	--AF.PowerSummaryFrame
	AceGUI:Release(AF.PowerSummaryFrame.scrollFrame)

	local scroll = AceGUI:Create("ScrollFrame")
	scroll:SetLayout("Flow")
	AF.PowerSummaryFrame:AddChild(scroll)
	AF.PowerSummaryFrame.scrollFrame = scroll

	local AF_Header = AceGUI:Create("Heading")
	AF_Header:SetText(L["AzeriteForge"])
	AF_Header:SetRelativeWidth(1)
	scroll:AddChild(AF_Header)

	local headPower_Header = AceGUI:Create("Heading")
	headPower_Header:SetText(L["Head Powers"])
	headPower_Header:SetRelativeWidth(1)
	scroll:AddChild(headPower_Header)

	if not GetInventoryItemID("player", 1) then 
		buttons.headSlotButton:Hide()
	else
		buttons.headSlotButton:Show()
		AF:GetAzeriteLocationTraits("Head")
		AF:UnselectTraits("Head")
	end

	local chestPower_Header = AceGUI:Create("Heading")
	chestPower_Header:SetText(L["Chest Powers"])
	chestPower_Header:SetRelativeWidth(1)
	scroll:AddChild(chestPower_Header)

	if not GetInventoryItemID("player", 3) then --or C_AzeriteEmpoweredItem.IsAzeriteEmpoweredItem(itemLocation) then 
		buttons.shoulderSlotButton:Hide()
	else
		buttons.shoulderSlotButton:Show()
		AF:GetAzeriteLocationTraits("Shoulder")
		AF:UnselectTraits("Shoulder")
	end

	local shoulderPower_Header = AceGUI:Create("Heading")
	shoulderPower_Header:SetText(L["Shoulder Powers"])
	shoulderPower_Header:SetRelativeWidth(1)
	scroll:AddChild(shoulderPower_Header)
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
		--AzeriteForgeDB.SavedSpecData = AzeriteForgeDB.SavedSpecData or {}
	--AzeriteForgeDB.SavedSpecData[specID] = AF.traitRanks



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



	AF:SecureHookScript(GameTooltip,"OnTooltipSetItem")
	AF:SecureHookScript(ItemRefTooltip,"OnTooltipSetItem")
	AF:SecureHookScript(WorldMapTooltip,"OnTooltipSetItem")
	AF:CreateFrames()
	AF.OldDataConvert()

--AF:RawHook(AzeriteEmpoweredItemPowerMixin,"OnEnter",true) 
end

function AF:PLAYER_ENTERING_WORLD()
	spec = GetSpecialization()
	specID, specName = GetSpecializationInfo(spec)
	className, classFile, classID = UnitClass("player")



	AF:BuildAzeriteDataTables()
	AF.BuildWeightedProfileList()
	AF:GetAzeriteData()
	AF:GetAzeriteTraits()

	AF.loadWeightProfile()
	--AF:LoadClassTraitRanks()
	
	UpdateWeeklyQuest()
	AF:updateInfoLDB()
	toggleAF_CharacterPage_Icon(AzeriteForge.db.profile.showCharacterPageIcon) 

	AF:Aurora()
end


function AF:OnDisable()
    -- Called when the addon is disabled
end


function AF:PLAYER_EQUIPMENT_CHANGED(event, ...)
	local InventorySlotId = ...
	if InventorySlotId == INVSLOT_HEAD or InventorySlotId == 3 or InventorySlotId == 5 then
		AF:GetAzeriteTraits()
		AF:GetAzeriteData()
		AF:UpdateBagDataMenu("")
		AF:updateInfoLDB()
	end
end


function AF:PLAYER_SPECIALIZATION_CHANGED(event, ...)
	spec = GetSpecialization()
	specID, specName = GetSpecializationInfo(spec) 
	AF.loadWeightProfile()
	AF:BuildAzeriteDataTables()
	AF.BuildWeightedProfileList()

	AF:GetAzeriteData()
	AF:GetAzeriteTraits()
	--AF:LoadClassTraitRanks()

	AF:updateInfoLDB()
	
	AF.BuildWeightedProfileList()

	AF:updateInfoLDB()
end



function AF.loadWeightProfile()
	AF.db.char.weightProfile = AF.db.char.weightProfile or {}
	--AF.db.char.weightProfile[specID] = AF.db.char.weightProfile[specID] or {}
	 local userProfile = AF.db.char.weightProfile[specID]
	  local _, specName = GetSpecializationInfoByID(specID)
	 local weightProfile = AF.db.global.userWeightLists[userProfile]

	local profileData = {}
	if not userProfile or not weightProfile  then 
		userProfile =  "[Default] - "..className.." "..specName
		profileData = AF.loadDefaultData("StackData")
		AF.db.global.userWeightLists[userProfile] =  profileData

		AF.db.char.weightProfile[specID] = userProfile
		AF.traitRanks = profileData
		AF.BuildWeightedProfileList()
		
	else

	--local userProfile = AF.db.char.weightProfile[specID] or ""
		profileData = AF.db.global.userWeightLists[userProfile]
		AF.traitRanks = profileData
	end

	
	AF.db.global.userWeightLists[userProfile] = AF.traitRanks 
	
--return profileData
end


function AF.traitRanksProfileUpdate(userProfile)
	--local userProfile = AF.db.char.weightProfile or ""
	local profileData = AF.db.global.userWeightLists[userProfile] --or {}

	AF.traitRanks = profileData
--return profileData
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
			local isAvailable = C_AzeriteEmpoweredItem.IsPowerAvailableForSpec(azeritePowerIDs, specID)

			if isSelected then
				SelectedAzeriteTraits[location][j] = SelectedAzeriteTraits[location][j] or {}
				SelectedAzeriteTraits[location][j]["azeritePowerIDs"] = SelectedAzeriteTraits[location][j]["azeritePowerIDs"] or {}
				SelectedAzeriteTraits[location][j]["azeritePowerIDs"][index] = azeritePowerIDs

				local item = AceGUI:Create("AzeriteForgeItem")
				item.item.icon:SetTexture(azeriteIcon)
				AF.PowerSummaryFrame.scrollFrame:AddChild(item)

				item.item.icon:SetTexture(icon)
				item.item:SetPoint("TOPLEFT", item.frame, "TOPLEFT")
				item.description:Hide()
				item.item:SetScript("OnEnter", nil)
				item.item:SetScript("OnClick", nil)

				item.traits:ClearAllPoints()
				item.traits:SetPoint("TOPLEFT", item.item, "TOPRIGHT", 5, 0)
				item.traits:SetWidth(165)

				if not isAvailable then 
					item.traits:SetTextColor(RED_FONT_COLOR.r,RED_FONT_COLOR.g,RED_FONT_COLOR.b)
					if AzeriteForge.db.profile.unavailableAlert then 
					print((L[RED_FONT_COLOR_CODE.."%s item has traits unuseable in current spec"]):format(location))
						if AzeriteForge.db.profile.unavailableAlertsound then 
							PlaySound(6595)
						end
					end
				end

				item.traits:SetText(azeritePowerName.."\n"..GetSpellDescription(azeriteSpellID))
				item.traits:SetJustifyH("LEFT")


				item.frame:SetHeight(item.traits:GetHeight()+5)

--[[
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
	]]--
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
	--azeriteTraits = {}

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

	AF:CreateTraitMenu(options.args.weights.args)
end



function AF:TextGetter(traitID, profile)
	local text = ""
	local DB = profile or AF.traitRanks
	if not DB[traitID] then return end
		for i,d in pairs(DB[traitID]) do
			text = ("%s[%s]:%s,"):format(text,i,d)
			--text = text.."["..tostring(i).."]:"..tostring(d)..","
		end
	return text 
end


function AF:ParseText(traitID, val)
	local text = {string.split(",",val)}

	if string.find(text[1], "%[") then
		for i,data in ipairs(text) do
			for w,x in string.gmatch(data,"%[(%w+)%]:(%p?%w+)") do
				AF.traitRanks[tonumber(traitID)][tonumber(w)] = tonumber(x)
			end
		end
	else
		for i, data in ipairs(text) do
			text[i] = tonumber(data)
		end
		AF.traitRanks[traitID] = CopyTable(text)
	end
end


function AF.loadDefaultData(DB)
	local traitRanks = {}
	specID, specName = GetSpecializationInfo(spec)
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

	traitRanks["specID"] = specID
	traitRanks["classID"] = classID

	return traitRanks
end


--loads defaults into saved variables table
function AF:LoadClassTraitRanks(DB)
	--AF.traitRanks = AzeriteForgeDB.SavedSpecData[specID] or AF.loadDefaultData("StackData")
	--AzeriteForgeDB.SavedSpecData[specID] = AF.traitRanks
end

AF.options = options

function AF:CreateTraitMenu(aceTable,disable, profile)
	local count = 10
	local sortTable = {}
	for id, data in pairs(azeriteTraits) do
		tinsert(sortTable, id)
	end

	--clear any previous data
	for x in pairs(aceTable) do
		if x== "Topheader" or x=="search" or x == "filler1" then
		else
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
			aceTable[name] = {
			type = "header",
			name = name,
			width = "full",
			order = count,
			hidden = function() local search = nil; if AF.searchbar then 
			search = not string.match(string.lower(azeriteTraits[traitID].name), string.lower(AF.searchbar))end;
			return search or (azeriteTraits[traitID] and not azeriteTraits[traitID].valid) or false end,
			disabled = disable,
			}

			aceTable[name.."1"] = {
			name = function() return name end,
			type = "execute",
			--desc  = function() return GetSpellDescription(azeriteTraits[traitID].spellId) end,
			image = icon,
			width = "normal",
			icon = icon,
			order = count+.1,
			disabled = disable,
			hidden = function() local search = nil; if AF.searchbar then 
			search = not string.match(string.lower(azeriteTraits[traitID].name), string.lower(AF.searchbar))end;
			return search or (azeriteTraits[traitID] and not azeriteTraits[traitID].valid) or false end,
			disabled = disable,
			}

			aceTable[name.."2"] = {
			name = " ",
			desc = function() return GetSpellDescription(azeriteTraits[traitID].spellId) end,
			type = "input",
			multiline  = 3,
			width = "normal",
			icon = icon,
			order = count+.2,
			disabled = disable,
			hidden = function() local search = nil; if AF.searchbar then 
			search = not string.match(string.lower(azeriteTraits[traitID].name), string.lower(AF.searchbar))end;
			return search or (azeriteTraits[traitID] and not azeriteTraits[traitID].valid) or false end,
			disabled = disable,
			get = function(info)  
				--if not AF.traitRanks[traitID] then  return "" end
				return AF:TextGetter(traitID,profile)


				end,
			set = function(info,val) AF.traitRanks[traitID] = {}; return AF:ParseText(traitID,val) end,
			}
			

		end

	end
end

local rankTotals = ""

local tooltipCatcher = CreateFrame("GameTooltip",nil, UIParent)
--###########################
--Tooltip stuff
function AF:BuildTraitText(itemLink, tooltip, name, force)
	if force then tooltip = tooltipCatcher end
	
	-- Current Azerite LevelcreateItemLocation
	local azeriteItemLocation = AF.createItemLocation(itemLink)

	rankTotals = ""

	if azeriteItemLocation then
		currentLevel = C_AzeriteItem.GetPowerLevel(C_AzeriteItem.FindActiveAzeriteItem())
	end

	local specID = GetSpecializationInfo(GetSpecialization())
	local allTierInfo = C_AzeriteEmpoweredItem.GetAllTierInfoByItemID(itemLink)

	if not allTierInfo[1]["azeritePowerIDs"][1] then return end

	local iconSize = 15
	local iconShade = 255
	local fullText = ""
	local maxRankTotal = 0
	local totalSelected = 0

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
			local empoweredLocation = AF.createItemLocation(itemLink)
			local tierRankTotal = 0
		

			for i, _ in pairs(allTierInfo[j]["azeritePowerIDs"]) do
				local azeritePowerID = allTierInfo[j]["azeritePowerIDs"][i]
				local azeriteSpellID = AzeriteTooltip_GetSpellID(azeritePowerID)
				local azeritePowerName, _, icon = GetSpellInfo(azeriteSpellID)
				local iconText = "|T"..icon..(":%d:%d:0:-7:64:64:4:60:4:60:%d:%d:%d|t")
				local traitText = ""
				local fontColor = GREEN_FONT_COLOR_CODE
				local textBreak = ""
				local rank = AF.getTraitRanking(azeritePowerID, azeriteItemLocation)
				tierRankTotal = max(tierRankTotal, rank or 0)
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
				if rank then traitText = ("%s (%s) "):format(traitText, rank) end

				
				if rank and isSelected then 
					rankTotals = ("%s Tier%s: %s"):format(rankTotals,j, rank )
					totalSelected = rank + totalSelected
				elseif not rank and isSelected then 
					rankTotals = ("%s Tier%s: %s"):format(rankTotals,j, 0 )
				end

				traitText = ("%s%s"):format(traitText,textBreak)
				azeriteTooltipText = ((force or not Config.tooltipCurrentTraits or (Config.tooltipCurrentTraits and C_AzeriteEmpoweredItem.IsPowerAvailableForSpec(azeritePowerID, specID))) and azeriteTooltipText.."  "..azeriteIcon.."  "..traitText) or azeriteTooltipText

			end
			maxRankTotal = maxRankTotal + tierRankTotal

			--rankTotals = ("%s %s"):format(rankTotals,"/" )

			if Config.enhancedTooltip then 
				tooltip:AddLine(azeriteTooltipText)
			end
			fullText = fullText.. azeriteTooltipText		
	end

	if Config.showRankTotal  then 
		rankTotals = ("%s [%s/%s}"):format(rankTotals, totalSelected, maxRankTotal )
		tooltip:AddLine(rankTotals)
	end

	return  fullText
end

function DisplayRankTotals()



end


function AF:OnTooltipSetItem(self,...)
	local name, link = self:GetItem()
  	if not name then return end

  	if C_AzeriteEmpoweredItem.IsAzeriteEmpoweredItemByID(link)  then
    		AF:BuildTraitText(link, self, name)
	end
end


