--	///////////////////////////////////////////////////////////////////////////////////////////
--
--	AzeriteForge v@project-version@
--	Author: SLOKnightfall

--	
--	///////////////////////////////////////////////////////////////////////////////////////////
local HasActiveAzeriteItem, FindActiveAzeriteItem, GetAzeriteItemXPInfo, GetPowerLevel = C_AzeriteItem.HasActiveAzeriteItem, C_AzeriteItem.FindActiveAzeriteItem, C_AzeriteItem.GetAzeriteItemXPInfo, C_AzeriteItem.GetPowerLevel

local FOLDER_NAME, private = ...
--AzeriteForge = LibStub("AceAddon-3.0"):NewAddon("AzeriteForge","AceConsole-3.0","AceEvent-3.0", "AceHook-3.0","LibSink-2.0")
--local L = LibStub("AceLocale-3.0"):GetLocale("AzeriteForge", silent)

local TextDump = LibStub("LibTextDump-1.0")
--local Archy = LibStub("AceAddon-3.0"):NewAddon("Archy", "AceConsole-3.0", "AceEvent-3.0", "AceHook-3.0", "AceBucket-3.0", "AceTimer-3.0", "LibSink-2.0", "LibToast-1.0")
--AzeriteForge = LibStub("AceAddon-3.0"):NewAddon("AzeriteForge", "AceConsole-3.0", "AceEvent-3.0","LibSink-2.0", "AceBucket-3.0")
AzeriteForge = LibStub("AceAddon-3.0"):GetAddon("AzeriteForge")
--local sink = LibStub("LibSink-2.0")
local L = LibStub("AceLocale-3.0"):GetLocale("AzeriteForge")


local currentXp, currentMaxXp, startXp
local currentLevel, startLevel
local lastXpGain=0
local azeriteItemLocation
local azeriteIcon = "Interface/Icons/Inv_smallazeriteshard"
local azeriteItemIcon = azeriteIcon
local COLOR_GREEN  = CreateColor(0.1, 0.8, 0.1, 1)
local spec = "nil"
local specid  = "nil"
local className, classFile, classID
local UnselectedPowersCount = 0


local UnselectedLocationTraits = {}
local azeriteTraits = {}
local traitRanks = {}
local ap = {}
local ReforgeCost = {}
local buttons = {}
local AzeriteTraitsName_to_ID ={}
local AzeriteLocations = {["Head"] = ItemLocation:CreateFromEquipmentSlot(1),
			["Shoulder"] = ItemLocation:CreateFromEquipmentSlot(3), 
			["Chest"]= ItemLocation:CreateFromEquipmentSlot(5),
			[1] = "Head",
			[3] = "Shoulder",
			[5] = "Chest",}

local locationIDs = {["Head"] =1,
			["Shoulder"] = 3, 
			["Chest"]= 5,}

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
			debugger = TextDump:New(("%s Debug Output"):format(FOLDER_NAME), DEBUGGER_WIDTH, DEBUGGER_HEIGHT)
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
		

		--local message = string.format(...)
		--debugger:AddLine(message, "%X")

		return message
	end

	function DebugPour(...)
		AzeriteForge:Pour(Debug(...), 1, 1, 1)
	end

	function GetDebugger()
		if not debugger then
			debugger = TextDump:New(("%s Debug Output"):format(FOLDER_NAME), DEBUGGER_WIDTH, DEBUGGER_HEIGHT)
		end

		return debugger
	end

	function ClearDebugger()
		if not debugger then
			debugger = TextDump:New(("%s Debug Output"):format(FOLDER_NAME), DEBUGGER_WIDTH, DEBUGGER_HEIGHT)
		end

		debugger:Clear()
	end

	private.Debug = Debug
	private.DebugPour = DebugPour
end

local options = {
    name = "AzeriteForge",
    handler = AzeriteForge,
    type = "group",
    args = {
        debug = {
            type = "execute",
            name = "Debug",
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

    },
}

local searchbar = nil
--Ace3 Menu Settings for the Zone Settings window
local talent_options = {
    name = "AzeriteForge_Talents",
    handler = AzeriteForge,
    type = 'group',
    args = {
	options={
			name = "Options",
			type = "group",
			--hidden = true,
			args={
				Topheader = {
					order = 0,
					type = "header",
					name = "AzeriteForge",

				},
				search = {
					name = " ",
					--desc = GetSpellDescription(azeriteTraits[traitID].spellID),
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
	},
}

local talent_options = {
    name = "AzeriteForge_Talents",
    handler = AzeriteForge,
    type = 'group',
    args = {
	options={
			name = "Options",
			type = "group",
			--hidden = true,
			args={
				Topheader = {
					order = 0,
					type = "header",
					name = "AzeriteForge",

				},
				search = {
					name = " ",
					--desc = GetSpellDescription(azeriteTraits[traitID].spellID),
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
		--hidden = true,
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
        notification = {
            sink = {},
        },
        debugPrint = false,
    },
    global = {
        data = {}
    }
}


function AzeriteTooltip_GetSpellID(powerID)
	local powerInfo = C_AzeriteEmpoweredItem.GetPowerInfo(powerID)
  	if (powerInfo) then
    	local azeriteSpellID = powerInfo["spellID"]
    	return azeriteSpellID
  	end
end




function AzeriteForge:GetAzeriteTraits()
	AvailableAzeriteTraits = {["Shoulder"] = {}, ["Head"] = {}, ["Chest"]= {},}
	SelectedAzeriteTraits = {["Shoulder"] = {}, ["Head"] = {}, ["Chest"]= {},}

	if not GetInventoryItemID("player", 3) then --or C_AzeriteEmpoweredItem.IsAzeriteEmpoweredItem(itemLocation) then 
		buttons.shoulderSlotButton:Hide()
	else
		buttons.shoulderSlotButton:Show()
		AzeriteForge:GetAzeriteLocationTraits("Shoulder")
		AzeriteForge:UnselectTraits("Shoulder")
	end

	if not GetInventoryItemID("player", 1) then 
		buttons.headSlotButton:Hide()
	else
		buttons.headSlotButton:Show()
		AzeriteForge:GetAzeriteLocationTraits("Head")
		AzeriteForge:UnselectTraits("Head")
	end

	if not GetInventoryItemID("player", 5) then 
		buttons.chestSlotButton:Hide()
	else
		buttons.chestSlotButton:Show()
		AzeriteForge:GetAzeriteLocationTraits("Chest")
		AzeriteForge:UnselectTraits("Head")
	end

	buttons.headSlotButton:SetNormalTexture(GetItemIcon(GetInventoryItemID("player", 1))  or "Interface\\Icons\\inv_boot_helm_draenordungeon_c_01")
	buttons.shoulderSlotButton:SetNormalTexture(GetItemIcon(GetInventoryItemID("player", 3)) or "Interface\\Icons\\inv_misc_desecrated_clothshoulder")
	buttons.chestSlotButton:SetNormalTexture(GetItemIcon(GetInventoryItemID("player", 5)) or "Interface\\Icons\\inv_chest_chain")
	
	UnselectedPowersCount = AzeriteUtil.GetEquippedItemsUnselectedPowersCount()


end


local WeeklyGain = 0
local WeeklyRequired = 0

local function UpdateWeeklyQuest()
	local questID = C_IslandsQueue.GetIslandsWeeklyQuestID();
	
	 _, _, _, WeeklyGain, WeeklyRequired = GetQuestObjectiveInfo(questID, 1, false);

	--print(
end


--options.args.output = self:GetSinkAce3OptionsDataTable()

function AzeriteForge:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("AzeriteForgeDB", DB_DEFAULTS, true)
	LibStub("AceConfig-3.0"):RegisterOptionsTable("AzeriteForge_Talents", talent_options)
	globalDb = self.db.global
	configDb = self.db.profile
	LibStub("AceConfig-3.0"):RegisterOptionsTable("AzeriteForge", options)
	self:RegisterChatCommand("az", "ChatCommand")
	self:RegisterChatCommand("azeriteforge", "ChatCommand")
end

function AzeriteForge:OnEnable()
    -- Called when the addon is enabled
    	self:RegisterEvent("AZERITE_ITEM_EXPERIENCE_CHANGED")
	self:RegisterEvent("AZERITE_ITEM_POWER_LEVEL_CHANGED")
	self:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
	self:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
	spec = GetSpecialization()
	specid = GetSpecializationInfo(spec) 
	className, classFile, classID = UnitClass("player")

		AzeriteForge:createframes()
	AzeriteForge:Build()

	AzeriteForge:BuildAzeriteDataTables()
	AzeriteForge:GetAzeriteData()
	AzeriteForge:GetAzeriteTraits()
	AzeriteForge:LoadClassTraitRanks()

	UpdateWeeklyQuest()
--AzeriteForge:RawHook(AzeriteEmpoweredItemPowerMixin,"OnEnter",true)
    
end

function AzeriteForge:OnDisable()
    -- Called when the addon is disabled
end



function AzeriteForge:PLAYER_EQUIPMENT_CHANGED(event, ...)
	local InventorySlotId = ...
	if InventorySlotId == 1 or InventorySlotId == 3 or InventorySlotId == 5 then
		AzeriteForge:GetAzeriteTraits()
	end
end


function AzeriteForge:PLAYER_SPECIALIZATION_CHANGED(event, ...)
	spec = GetSpecialization()
	specid = GetSpecializationInfo(spec) 
	AzeriteForge:BuildAzeriteDataTables()

	AzeriteForge:GetAzeriteData()
	AzeriteForge:GetAzeriteTraits()
	AzeriteForge:LoadClassTraitRanks()
end

function AzeriteForge:AZERITE_ITEM_EXPERIENCE_CHANGED(event, ...)
	local azeriteItemLocation, oldExperienceAmount, newExperienceAmount = ...
	lastXpGain = newExperienceAmount - oldExperienceAmount
	UpdateWeeklyQuest()
  -- if it's not equal then we will defer the xp gain to the power level event
	if GetPowerLevel(azeriteItemLocation) == currentLevel then 
    --self:GetAzeriteData()
    --self:SetBrokerText()
    --self:RecordXpGain(lastXpGain)
	end
end

-- it is assumed that this event always happens AFTER a XP change event
function AzeriteForge:AZERITE_ITEM_POWER_LEVEL_CHANGED(event, ...)
	local azeriteItemLocation, oldPowerLevel, newPowerLevel, unlockedEmpoweredItemsInfo = ...
	local lastLevelGain = newPowerLevel - oldPowerLevel
	if lastLevelGain ~= 1 then
		DebugPour("Unexpected Azerite Item level change of %d, please report as a bug", lastLevelGain)
	end

	-- Correct our power gain 
	--lastXpGain = lastXpGain + ap[oldPowerLevel]


  --self:GetAzeriteData()
 -- self:SetBrokerText()

  --self:RecordXpGain(lastXpGain)
end



function AzeriteForge:UnselectTraits(location)
	local locationData = AzeriteLocations[location]

	if not C_Item.DoesItemExist(locationData) or not C_AzeriteEmpoweredItem.IsAzeriteEmpoweredItem(locationData) then return false end

	UnselectedLocationTraits[location] = C_AzeriteEmpoweredItem.HasAnyUnselectedPowers(locationData)
	print(UnselectedLocationTraits[location])
	return UnselectedLocationTraits[location]
end









--Gets Azerite xp info
function AzeriteForge:GetAzeriteData()
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
function AzeriteForge:FindStackedTraits(powerID, locationID, traitList)
	local ItemLocation = AzeriteLocations[locationID]
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


function AzeriteForge:GetAzeriteLocationTraits(location)
	local locationData = AzeriteLocations[location]
	--if not C_AzeriteEmpoweredItem.IsAzeriteEmpoweredItem(locationData) then return end
	if not C_Item.DoesItemExist(locationData) or not C_AzeriteEmpoweredItem.IsAzeriteEmpoweredItem(locationData) then return end

	local allTierInfo = C_AzeriteEmpoweredItem.GetAllTierInfo(locationData)

	if not allTierInfo[1]["azeritePowerIDs"][1] then return end

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
end


function AzeriteForge:ChatCommand(input)
    if not input or input:trim() == "" then
        LibStub("AceConfigDialog-3.0"):Open("AzeriteForge_Talents", widget, "stats")

    else
        LibStub("AceConfigCmd-3.0"):HandleCommand("az", "AzeriteForge", input)
    end
end





--AzeriteEmpoweredItemUI.BorderFrame.portrait

function AzeriteForge:createframes()
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
	f:SetToplevel(true)
	f:SetScript("OnEnter", function()

	local RespecCost = C_AzeriteEmpoweredItem.GetAzeriteEmpoweredItemRespecCost()

	GameTooltip:SetOwner(f, "ANCHOR_RIGHT");
	GameTooltip:AddLine(("Current Level: %s"):format(currentLevel),1.0, 1.0, 1.0);
	GameTooltip:AddLine(("XP: %s/%s"):format(currentXp, currentMaxXp), 1.0, 1.0, 1.0);
	GameTooltip:AddLine(("Xp to Next Level: %s"):format(currentMaxXp - currentXp), 1.0, 1.0, 1.0);
	GameTooltip:AddLine(("Current Respec Cost: %sg"):format(RespecCost/10000), 1.0, 1.0, 1.0);
	GameTooltip:AddLine(("Islands: %s/%s"):format(WeeklyGain, WeeklyRequired ), 1.0, 1.0, 1.0);
	GameTooltip:AddLine(("Remaining: %s"):format( WeeklyRequired- WeeklyGain ), 1.0, 1.0, 1.0);


	GameTooltip:Show();
				
	end)
	f:SetScript("OnLeave", function()GameTooltip:Hide() end)


	local AceGUI = LibStub("AceGUI-3.0")
	-- Create a container frame
	local f = AceGUI:Create("Frame")
	f:SetCallback("OnClose",function(widget) AceGUI:Release(widget) end)
	f:SetTitle("AceGUI-3.0 Example")
	f:SetStatusText("Status Bar")
	f:SetLayout("Flow")
	-- Create a button
	local btn = AceGUI:Create("Button")
	btn:SetWidth(170)
	btn:SetText("Button !")

	-- Add the button to the container
	f:AddChild(btn)
	local textField = AceGUI:Create("EditBox")
	textField:SetText("")
	f:AddChild(textField)
	f:Hide()
	btn:SetCallback("OnClick", function() AzeriteForge:ImportWeights(textField:GetText()) end)
end



function getTraitRanking(traitID, locationID)
	if not traitRanks[traitID] then return false  end

	local rank = 0
	local  _, stackedRank = AzeriteForge:FindStackedTraits(traitID, locationID, SelectedAzeriteTraits)
	local maxRank = 1
 
	for index, itemrank in pairs(traitRanks[traitID]) do
		maxRank = itemrank
	end

	rank = traitRanks[traitID][stackedRank + 1] or maxRank

	return rank
end




--Opens a location's Azerite trait page
local function openLocation(itemLocation)
	if C_Item.DoesItemExist(itemLocation) then 
		if C_AzeriteEmpoweredItem.IsAzeriteEmpoweredItem(itemLocation) then
			OpenAzeriteEmpoweredItemUIFromItemLocation(itemLocation);
		else
			DEFAULT_CHAT_FRAME:AddMessage("Equipped shoulder is not an Azerite item.");

		end
	end

end



--Tabs have issues if the frame parent is set to CharacterFrame.  
	local f = CreateFrame('Frame', "AzeriteCharacterPanel", UIPARENT)
	f:SetSize(166, 166)
	f:ClearAllPoints()
	f:SetPoint("TOPLEFT",CharacterFrameTab3,"TOPRIGHT", -15 ,0)
	f.border = f:CreateTexture()
	f.border:SetAllPoints()
	f.border:SetColorTexture(0,0,0,1)
	f.border:SetTexture([[Interface\Tooltips\UI-Tooltip-Background]])
	f.border:SetDrawLayer('BORDER')


	local t = CreateFrame("Button", "AzeriteCharacterPanelTab1", f, "CharacterFrameTabButtonTemplate")
	t:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
	t.id = 1
	t:SetScript("OnLoad", nil)
	t:SetScript("OnShow", function()return end)
	t:SetScript("OnEvent", function()return end)
	t:SetScript("OnClick", function()return end)
	t:SetText("Azerite")


	AzeriteForge:HookScript(CharacterFrame, "OnShow", function()  f:Show() end)
	AzeriteForge:HookScript(CharacterFrame, "OnHide", function() f:Hide() end)
	PanelTemplates_SetNumTabs(t, 1);
	PanelTemplates_DeselectTab(t, 1);

	t:SetScript("OnClick", function(self, button, down)
		for equipSlotIndex, itemLocation in AzeriteUtil.EnumerateEquipedAzeriteEmpoweredItems() do
			if C_AzeriteEmpoweredItem.IsAzeriteEmpoweredItem(itemLocation) then
				--Open first azerite item
				openLocation(itemLocation)
			end
		end

		if CharacterFrame:IsShown() then
			CharacterFrame:Hide()

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

	--AzeriteCharacterPanelTab1Text:ClearAllPoints()
	--AzeriteCharacterPanelTab1Text:SetPoint("CENTER", AzeriteCharacterPanelTab1Middle,"CENTER", 0, 5)




local function AddAzeriteToCharacterTab()
	local f = CreateFrame("Button", "CharacterFrameTab4",CharacterTab, "CharacterFrameTabButtonTemplate")
	f:SetClampedToScreen(true)
	f:SetSize(110, 160)
	f:SetPoint("LEFT",CharacterFrameTab3,"RIGHT")
	f:SetText("Azerite")
	f:SetScript("OnShow", function()return end)
	f:SetScript("OnEvent", function()return end)
--=f:Show()
	--f:EnableMouse(true)
	--f:SetFrameStrata('HIGH')
	--f:SetMovable(false)
	--f:SetToplevel(true)
		f:SetScript("OnShow", function(self, button, down)

	end)

	f:SetScript("OnClick", function(self, button, down)
		LibStub("AceConfigDialog-3.0"):Open("AzeriteForge_Talents", widget, "stats")
		rankMenuButton.view = "skills"

		if CharacterFrame:IsShown() then
			f:Hide()

		end
	end)

	f:SetScript("OnEnter",
		function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
			GameTooltip:SetText(MicroButtonTooltipText(CHARACTER_INFO, "TOGGLECHARACTER0"), 1.0,1.0,1.0 );
					
		end
	)
	f:SetScript("OnLeave",
		function()
			GameTooltip:Hide()
		end
	)


		--<AbsDimension x="11" y="2"/>

end

--Builds Trait Ranking Window





---------
function AzeriteForge:Build()
---------
--AddAzeriteToCharacterTab()
	local f = CreateFrame('Frame', "AzeriteForge_menu", AzeriteEmpoweredItemUI)
	f:SetClampedToScreen(true)
	f:SetSize(250, 160)
	f:SetPoint("TOPLEFT",AzeriteEmpoweredItemUI,"TOPRIGHT")
	f:SetPoint("BOTTOMLEFT",AzeriteEmpoweredItemUI,"BOTTOMRIGHT")
	f:Hide()
	f:EnableMouse(true)
	f:SetFrameStrata('HIGH')
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

	f:Show()

	local content = CreateFrame("Frame",nil, f)
	content:SetPoint("TOPLEFT",15,-15)
	content:SetPoint("BOTTOMRIGHT",-15,15)
	--This creats a cusomt AceGUI container which lets us imbed a AceGUI menu into our frame.
	local widget = {
		frame     = f,
		content   = content,
		type      = "GGMMContainer"
	}
	widget["OnRelease"] = function(self)
		self.status = nil
		wipe(self.localstatus)
	end

	f:SetScript("OnShow", function(self)

		LibStub("AceConfigDialog-3.0"):Open("AzeriteForge_Talents", widget, "stats")
		f:Show()
		end)

	f:SetScript("OnHide", function(self)

		f:Hide()
		end)

	LibStub("AceGUI-3.0"):RegisterAsContainer(widget)

	local rankMenuButton = CreateFrame("Button", nil , AzeriteEmpoweredItemUI)
	rankMenuButton:SetNormalTexture(azeriteIcon)
	--rankMenuButton:SetPushedTexture("Interface\\Buttons\\UI-MicroButton-Mounts-Down")
	rankMenuButton:SetPoint("BOTTOMRIGHT", AzeriteEmpoweredItemUI, "BOTTOMRIGHT", 0, 0)
	rankMenuButton:SetWidth(45)
	rankMenuButton:SetHeight(45)
	rankMenuButton.view = "skills"
	rankMenuButton:SetScript("OnClick", function(self, button, down)
		local Shift = IsShiftKeyDown()
		if Shift then
			if rankMenuButton.view == "skills" then
				LibStub("AceConfigDialog-3.0"):Open("AzeriteForge_Talents", widget, "options")
				rankMenuButton.view = "weights"

			else
				LibStub("AceConfigDialog-3.0"):Open("AzeriteForge_Talents", widget, "stats")
				rankMenuButton.view = "skills"
			end
		

		else
			if f:IsShown() then
				f:Hide()
			else
				f:Show()
			end
		end

	end)
	rankMenuButton:SetScript("OnEnter",
		function(self)
			GameTooltip:SetOwner (self, "ANCHOR_RIGHT")
			--GameTooltip:SetText(L.GOGOMOUNT_BUTTON_TOOLTIP, 1, 1, 1)
			GameTooltip:Show()
		end
	)
	rankMenuButton:SetScript("OnLeave",
		function()
			GameTooltip:Hide()
		end
	)


	local headSlotButton = CreateFrame("Button", nil , AzeriteEmpoweredItemUI)
	buttons.headSlotButton = headSlotButton
	headSlotButton:SetNormalTexture(GetItemIcon(GetInventoryItemID("player", 1)) or "Interface\\Icons\\inv_boot_helm_draenordungeon_c_01")
	headSlotButton:SetPoint("TOPLEFT", AzeriteEmpoweredItemUI, "BOTTOMLEFT", 0, 0)
	headSlotButton:SetWidth(45)
	headSlotButton:SetHeight(45)
	
	headSlotButton:SetScript("OnClick", function(self, button, down)
		openLocation(AzeriteLocations["Head"])

	end)
	headSlotButton:SetScript("OnEnter",
		function(self)
			GameTooltip:SetOwner (self, "ANCHOR_RIGHT")
			--GameTooltip:SetText(L.GOGOMOUNT_BUTTON_TOOLTIP, 1, 1, 1)
			GameTooltip:Show()
		end
	)
	headSlotButton:SetScript("OnLeave",
		function()
			GameTooltip:Hide()
		end
	)

	local shoulderSlotButton = CreateFrame("Button", nil , AzeriteEmpoweredItemUI)
	buttons.shoulderSlotButton = shoulderSlotButton
	shoulderSlotButton:SetNormalTexture(GetItemIcon(GetInventoryItemID("player", 3)) or "Interface\\Icons\\inv_misc_desecrated_clothshoulder")
	--rankMenuButton:SetPushedTexture("Interface\\Buttons\\UI-MicroButton-Mounts-Down")
	shoulderSlotButton:SetPoint("LEFT", headSlotButton, "RIGHT", 0, 0)
	shoulderSlotButton:SetWidth(45)
	shoulderSlotButton:SetHeight(45)
	shoulderSlotButton:SetScript("OnClick", function(self, button, down)
		openLocation(AzeriteLocations["Shoulder"])

	end)
	shoulderSlotButton:SetScript("OnEnter",
		function(self)
			GameTooltip:SetOwner (self, "ANCHOR_RIGHT")
			GameTooltip:SetText(L["Toggle Shoulder Azerite Panel"], 1, 1, 1)
			GameTooltip:Show()
		end
	)
	shoulderSlotButton:SetScript("OnLeave",
		function()
			GameTooltip:Hide()
		end
	)
	local chestSlotButton = CreateFrame("Button", nil , AzeriteEmpoweredItemUI, MainMenuBarMicroButton)
	buttons.chestSlotButton = chestSlotButton
	chestSlotButton:SetNormalTexture(GetItemIcon(GetInventoryItemID("player", 5)) or "Interface\\Icons\\inv_chest_chain")
	--rankMenuButton:SetPushedTexture("Interface\\Buttons\\UI-MicroButton-Mounts-Down")
	chestSlotButton:SetPoint("LEFT", shoulderSlotButton, "RIGHT", 0, 0)
	chestSlotButton:SetWidth(45)
	chestSlotButton:SetHeight(45)
	chestSlotButton:SetScript("OnClick", function(self, button, down)
		openLocation(AzeriteLocations["Chest"])
	end)
	--SetButtonPulse(chestSlotButton, 60, 1)
	chestSlotButton:SetScript("OnEnter",
		function(self)
			GameTooltip:SetOwner (self, "ANCHOR_RIGHT")
			GameTooltip:SetText(L["Toggle Chest Azerite Panel"], 1, 1, 1)
			GameTooltip:Show()
		end
	)
	chestSlotButton:SetScript("OnLeave",
		function()
			GameTooltip:Hide()
		end
	)

	local characterButton = CreateFrame("Button", nil , AzeriteEmpoweredItemUI)
	buttons.characterButton = characterButton
	characterButton:SetNormalTexture("Interface\\Buttons\\UI-MicroButtonCharacter-Up")
	--rankMenuButton:SetPushedTexture("Interface\\Buttons\\UI-MicroButton-Mounts-Down")
	characterButton:SetPoint("LEFT", chestSlotButton, "RIGHT", 0, 0)
	characterButton:SetWidth(45)
	characterButton:SetHeight(45)
	characterButton:SetScript("OnClick", function(self, button, down)
		local Shift = IsShiftKeyDown()
		if Shift then

		else
			ToggleCharacter("PaperDollFrame")
		end

	end)
	characterButton:SetScript("OnEnter",
		function(self)
			GameTooltip:SetOwner (self, "ANCHOR_RIGHT")
			GameTooltip:SetText(L["Toggle Character Info"], 1, 1, 1)
			GameTooltip:Show()
		end
	)
	characterButton:SetScript("OnLeave",
		function()
			GameTooltip:Hide()
		end
	)


	AzeriteForge:CreateTraitMenu()		
end


--
function AzeriteForge:CreateTraitMenu()
	local count = 0
	local sortTable = {}
	for id, data in pairs(azeriteTraits) do

		tinsert(sortTable, id)
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
			talent_options.args.options.args[name] = {
			type = "header",
			name = name,
			width = full,
			order = index,
			hidden = function() local search = nil; if searchbar then search = not string.match(string.lower(azeriteTraits[traitID].name), string.lower(searchbar))end; return search or not azeriteTraits[traitID].valid end,
			}

			talent_options.args.options.args[name.."1"] = {
			name = "",
			type = "description",
			desc  = "ASDF",
			image = icon,
			width = .2,
			icon = icon,
			order = index+.1,
			hidden = function() local search = nil; if searchbar then search = not string.match(string.lower(azeriteTraits[traitID].name), string.lower(searchbar))end; return search or not azeriteTraits[traitID].valid end,
			}

			talent_options.args.options.args[name.."2"] = {
			name = " ",
			desc = function() return GetSpellDescription(azeriteTraits[traitID].spellId) end,
			type = "input",
			confirm = true,
			width = .79,
			icon = icon,
			order = index+.2,
			hidden = function() local search = nil; if searchbar then search = not string.match(string.lower(azeriteTraits[traitID].name), string.lower(searchbar))end; return search or not azeriteTraits[traitID].valid end,
			get = function()  
				if not traitRanks[traitID] then  return "" end
					local text = ""
					for _,n in pairs(traitRanks[traitID]) do
						text = text..n..","
					end
					return text 
				end,
			}

		end

	end
end

--Determines if a value is stored in a table
function inTable(table, value)
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
	if (inTable(traitClasses, classID) and (traitSpecs and inTable(traitSpecs, specid))) then  
		return true

	elseif (inTable(traitClasses, classID) and not traitSpecs) then 
		return true

	else
		return false
	end
end


--Cycles though the various azerite power ids and builds a database info from it
function AzeriteForge:BuildAzeriteDataTables()
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
end


--Imports text data into the traitsRanks Table
--Data format is ["localized trait name" or trait id, Rank1, Rank2, Rank3],
--Multiple traits can be imported if seperated by commas and only one Rank is needed
function AzeriteForge:ImportWeights(data)
	local t = {}
	for k in string.gmatch(data,"%b[]") do
		local text = string.gsub(k,'[%[%]\"]', '')
		local tbl = {string.split(",",text ) }
		local trait = AzeriteTraitsName_to_ID[tbl[1]] or tbl[1]
		tremove(tbl,1)
		traitRanks[trait] = tbl
	end
end



function AzeriteForge:LoadClassTraitRanks()
	traitRanks = {}
	for name, data in pairs(AzeriteForge.StackData[specid]) do	
		 if AzeriteTraitsName_to_ID[name] then
			traitRanks[AzeriteTraitsName_to_ID[name]] = data
		 end
	end
	--Add code to load user saved data here
end


--Modified blizzard plugins

LoadAddOn("Blizzard_AzeriteUI")



function AzeriteEmpoweredItemPowerMixin:OnEnter()
	self:CancelItemLoadCallback();
	if self.SwirlContainer:IsShown() then
		return;
	end

	local item = self.azeriteItemDataSource:GetItem();

	self.itemDataLoadedCancelFunc = item:ContinueWithCancelOnItemLoad(function()
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		local itemID = item:GetItemID();
		local itemLevel = item:GetCurrentItemLevel();
		local itemLink = item:GetItemLink();
		local location = self.azeriteItemDataSource:GetItemLocation()
		local duplicateLocations = AzeriteForge:FindStackedTraits(self:GetAzeritePowerID(),location.equipmentSlotIndex,SelectedAzeriteTraits)
		GameTooltip:SetAzeritePower(itemID, itemLevel, self:GetAzeritePowerID(), itemLink);

		if self:CanBeSelected() then
			GameTooltip:AddLine(" ");
			GameTooltip_AddInstructionLine(GameTooltip, AZERITE_CLICK_TO_SELECT, GREEN_FONT_COLOR);
		else
			local showUnlockReq = not self:MeetsPowerLevelRequirement() and not self:DoesTierHaveAnyPowersSelected();
			if showUnlockReq then
				GameTooltip:AddLine(" ");
				GameTooltip_AddColoredLine(GameTooltip, REQUIRES_AZERITE_LEVEL_TOOLTIP:format(self.unlockLevel), RED_FONT_COLOR);
			end

			if not self:IsSpecAllowed() then
				local specTooltipLine = AzeriteUtil.GenerateRequiredSpecTooltipLine(self:GetAzeritePowerID());
				if specTooltipLine then
					if not showUnlockReq then
						GameTooltip:AddLine(" ");
					end
					GameTooltip_AddColoredLine(GameTooltip, specTooltipLine, RED_FONT_COLOR);
				end
			end
		end

		if duplicateLocations then
			GameTooltip_AddColoredLine(GameTooltip, ("Found on :%s"):format(duplicateLocations), RED_FONT_COLOR);
		end

		GameTooltip:Show();
		self.UpdateTooltip = self.OnEnter;
	end);
end

function AzeriteEmpoweredItemPowerMixin:Setup(owningTierFrame, azeriteItemDataSource, azeritePowerID, baseAngle)
	self:CancelItemLoadCallback();

	self.owningTierFrame = owningTierFrame;
	self.azeriteItemDataSource = azeriteItemDataSource;
	self.azeritePowerID = azeritePowerID;
	self.baseAngle = baseAngle;

	self:Update();

	self.canBeSelected = nil;
	self.transitionStateInitialized = false;

	if self:IsFinalPower() then
		self.IconOn:SetAtlas("Azerite-CenterTrait-On", true);
		self.IconOff:SetAtlas("Azerite-CenterTrait-Off", true);
		self.IconDesaturated:SetAtlas("Azerite-CenterTrait-On", true);
	else
		local spellTexture = GetSpellTexture(self:GetSpellID()); 
		self.IconOn:SetTexture(spellTexture);
		self.IconOff:SetTexture(spellTexture);
		self.IconDesaturated:SetTexture(spellTexture);
	end

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

	self:SetupModelScene();
end

function AzeriteEmpoweredItemPowerMixin:Reset()
	self.CanSelectGlowAnim:Stop();
	self.CanSelectArrowAnim:Stop();
	self.TransitionAnimation:Stop();
	self.SwirlContainer.SelectedAnim:Stop();
	self.SwirlContainer.RevealAnim:Stop();
	self.SwirlContainer:Hide();
	self.needsBuffAvailableSoundPlayed = nil;

	if self.AdditionalTraits then
		self.AdditionalTraits:Hide()
		self.TraitRank:Hide()
	end
end


function AzeriteEmpoweredItemPowerMixin:OnShow()
	self:RegisterEvent("UI_MODEL_SCENE_INFO_UPDATED");
	if self.azeriteItemDataSource then 

		local location = self.azeriteItemDataSource:GetItemLocation()
		local HasAnyUnselectedPowers = C_AzeriteEmpoweredItem.HasAnyUnselectedPowers(location)
		local DB = SelectedAzeriteTraits

		if HasAnyUnselectedPowers then
			DB = AvailableAzeriteTraits
		end

		local _,DuplicateTriaits = AzeriteForge:FindStackedTraits(self:GetAzeritePowerID(),location.equipmentSlotIndex, DB)
		local traitRank = getTraitRanking(self:GetAzeritePowerID(),location.equipmentSlotIndex, DB)

		if traitRank and self.TraitRank then --and HasAnyUnselectedPowers then 
			self.AdditionalTraits:SetPoint("CENTER",0,20)
			self.TraitRank:SetText(("+%s"):format(traitRank))
			self.TraitRank:Show()
		else
			self.TraitRank:Hide()
			self.AdditionalTraits:SetPoint("CENTER",0,0)
		end

		if self.AdditionalTraits and DuplicateTriaits > 0 then 
			self.AdditionalTraits:SetText(("%sX"):format(DuplicateTriaits+1))
			self.AdditionalTraits:Show()
		else
			self.AdditionalTraits:Hide()
		end
	end
end