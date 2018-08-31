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


local currentXp, currentMaxXp, startXp
local currentLevel, startLevel
local lastXpGain=0
local azeriteItemLocation
local azeriteIcon = "Interface/Icons/Inv_smallazeriteshard"
local azeriteItemIcon = azeriteIcon
local ap = {}
local COLOR_GREEN  = CreateColor(0.1, 0.8, 0.1, 1)

local ReforgeCost = {}
local AzeriteTraits={}
local spec = "nil"
local specid  = "nil"
local className, classFile, classID


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

local AzeriteLocations = {["Head"] = ItemLocation:CreateFromEquipmentSlot(1),
			["Shoulder"] = ItemLocation:CreateFromEquipmentSlot(3), 
			["Chest"]= ItemLocation:CreateFromEquipmentSlot(5),
			[1] = "Head",
			[3] = "Shoulder",
			[5] = "Chest",}

local AvailableAzeriteTraits = {["Shoulder"] = {}, ["Head"] = {}, ["Chest"]= {},}
local SelectedAzeriteTraits = {["Shoulder"] = {}, ["Head"] = {}, ["Chest"]= {},}


function AzeriteForge:GetAzeriteTraits()
	AvailableAzeriteTraits = {["Shoulder"] = {}, ["Head"] = {}, ["Chest"]= {},}
	SelectedAzeriteTraits = {["Shoulder"] = {}, ["Head"] = {}, ["Chest"]= {},}

	if GetInventoryItemID("player", 3) then 
		AzeriteForge:GetAzeriteLocationTraits("Shoulder")
	end

	if GetInventoryItemID("player", 1) then 
		AzeriteForge:GetAzeriteLocationTraits("Head")
	end

	if GetInventoryItemID("player", 5) then 
		AzeriteForge:GetAzeriteLocationTraits("Chest")
	end
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
	AzeriteForge:BuildAzeriteDataTables()
	AzeriteForge:GetAzeriteData()
	AzeriteForge:GetAzeriteTraits()
AzeriteForge:LoadClassTraitRanks()
	AzeriteForge:createframes()
	AzeriteForge:Build()
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
end

function AzeriteForge:AZERITE_ITEM_EXPERIENCE_CHANGED(event, ...)
	local azeriteItemLocation, oldExperienceAmount, newExperienceAmount = ...
	Debug(string.format("GAL AZERITE_ITEM_EXPERIENCE_CHANGED old AP: %d new AP: %d - Level %d", oldExperienceAmount, newExperienceAmount, GetPowerLevel(azeriteItemLocation)))
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

  Debug(string.format("GAL AZERITE_ITEM_POWER_LEVEL_CHANGED old: %d new: %d - AP gain: %d", oldPowerLevel, newPowerLevel, lastXpGain))
  --self:GetAzeriteData()
 -- self:SetBrokerText()

  --self:RecordXpGain(lastXpGain)
end







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
		--DoStuff(azeriteItemLocation)
   -- if db.char.ever == 0 then
      -- estimate total AP earned previously based on current level/xp
    --  db.char.ever = aptotals[startLevel] + startXp
   -- end
	end

	currentXp, currentMaxXp = GetAzeriteItemXPInfo(azeriteItemLocation)
	currentLevel = GetPowerLevel(azeriteItemLocation)
	Debug(("currentXp: %s"):format(currentXp))
	Debug(("currentMaxXp: %s"):format(currentMaxXp))
	Debug(("currentLevel: %s"):format(currentLevel))

	ap[currentLevel] = ap[currentLevel] or currentMaxXp



	--print(headslot)
	--DoStuff(C_AzeriteEmpoweredItem.GetAllTierInfo(shoulderSlot))

--local allTierInfo = C_AzeriteEmpoweredItem.GetAllTierInfo(shoulderSlot)
	--if not allTierInfo[1]["azeritePowerIDs"][1] then return end


	--C_AzeriteEmpoweredItem.HasAnyUnselectedPowers(
	--C_AzeriteEmpoweredItem.GetPowerInfo(powerID)
	--C_AzeriteEmpoweredItem.GetAllTierInfo
	--268599

end

function AzeriteForge:FindDuplicateTraits(powerID, locationID, traitList)
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
	if not C_AzeriteEmpoweredItem.IsAzeriteEmpoweredItem(locationData) then return end

	local allTierInfo = C_AzeriteEmpoweredItem.GetAllTierInfo(locationData)

	if not allTierInfo[1]["azeritePowerIDs"][1] then return end
		for j=1, 3 do

			local tierLevel = allTierInfo[j]["unlockLevel"]
			--local azeritePowerIDs = allTierInfo[j]["azeritePowerIDs"][1]

			for index, azeritePowerIDs in pairs (allTierInfo[j]["azeritePowerIDs"]) do
			
			if azeritePowerIDs == 13 then break end -- Ignore +5 item level tier

			AvailableAzeriteTraits[location][j] = AvailableAzeriteTraits[location][j] or {}
			AvailableAzeriteTraits[location][j]["unlockLevel"] = tierLevel
			AvailableAzeriteTraits[location][j]["azeritePowerIDs"] = AvailableAzeriteTraits[location][j]["azeritePowerIDs"] or {}
			AvailableAzeriteTraits[location][j]["azeritePowerIDs"][index] = azeritePowerIDs
	--C_AzeriteEmpoweredItem.IsPowerSelected(azeriteEmpoweredItemLocation, powerID)

	local azeriteSpellID = AzeriteTooltip_GetSpellID(azeritePowerIDs)				
	local azeritePowerName, _, icon = GetSpellInfo(azeriteSpellID)
	local isSelected = C_AzeriteEmpoweredItem.IsPowerSelected(locationData, azeritePowerIDs)

	if isSelected then
		SelectedAzeriteTraits[location][j] = SelectedAzeriteTraits[location][j] or {}
		SelectedAzeriteTraits[location][j]["azeritePowerIDs"] = SelectedAzeriteTraits[location][j]["azeritePowerIDs"] or {}
		SelectedAzeriteTraits[location][j]["azeritePowerIDs"][index] = azeritePowerIDs
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
        --InterfaceOptionsFrame_OpenToCategory(self.optionsFrame)
    else
        LibStub("AceConfigCmd-3.0"):HandleCommand("az", "AzeriteForge", input)
    end
end





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
		local duplicateLocations = AzeriteForge:FindDuplicateTraits(self:GetAzeritePowerID(),location.equipmentSlotIndex,SelectedAzeriteTraits)
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
end


local traitRanks = {}


traitRanks[482] = {[1] = 5,[2] = 4,}
traitRanks[44] = {[1] = 15,}
traitRanks[194] = {[1] = 15,}
--traitRanks[162] = {[1] = 15,}
traitRanks[162] = {15,16,17}

function getTraitRanking(traitID, locationID)

	if not traitRanks[traitID] then return false  end

--AzeriteForge:FindDuplicateTraits(self:GetAzeritePowerID(),location.equipmentSlotIndex, DB)
	local rank = 0
	local  _, duplicates = AzeriteForge:FindDuplicateTraits(traitID, locationID, SelectedAzeriteTraits)
	local maxRank = 1
 
	for index, itemrank in pairs(traitRanks[traitID]) do
		maxRank = itemrank
	end

	rank = traitRanks[traitID][duplicates + 1] or maxRank

	return rank
end


local azeriteTraits = {}

function ids()
ClearDebugger()
--TextDump:Clear()
for i=1,600 do
local power = C_AzeriteEmpoweredItem.GetPowerInfo(i)
if power then

local name, _, icon = GetSpellInfo(GetSpellInfo(power["spellID"]))
azeriteTraits[i] = {}
azeriteTraits[i] ["name"] = name
azeriteTraits[i] ["spellID"] = power["spellID"]
azeriteTraits[i] [ "icon"] = icon
local spec = C_AzeriteEmpoweredItem.GetSpecsForPower(i)

if spec then 
for x, y in pairs(spec) do

--print(y["specID"])
end


end
local name = GetSpellInfo(power["spellID"])
Debug("("..i..") - "..name)
--print(power["spellID"])

end
end
---id = GetSpecialization()
--GetSpecializationInfo(id)





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
	--f:SetText(currentLevel)
	f:Hide()
	self.AdditionalTraits = f

	local f = self:CreateFontString(nil, "DIALOG", "GameFontNormalHuge3Outline")
	f:SetTextColor(GREEN_FONT_COLOR:GetRGB())
	f:ClearAllPoints()
	f:SetPoint("CENTER",0,-20)
	--f:SetText(currentLevel)
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

		local _,DuplicateTriaits = AzeriteForge:FindDuplicateTraits(self:GetAzeritePowerID(),location.equipmentSlotIndex, DB)
		local traitRank = getTraitRanking(self:GetAzeritePowerID(),location.equipmentSlotIndex, DB)

		if traitRank and self.TraitRank and HasAnyUnselectedPowers then 
			self.AdditionalTraits:SetPoint("CENTER",0,20)
			self.TraitRank:SetText(("+ %s"):format(traitRank))
			self.TraitRank:Show()
		else
			self.TraitRank:Hide()
			self.AdditionalTraits:SetPoint("CENTER",0,0)
		end

		if self.AdditionalTraits and DuplicateTriaits > 0 then 
			self.AdditionalTraits:SetText(("+%s"):format(DuplicateTriaits))
			self.AdditionalTraits:Show()
		else
			self.AdditionalTraits:Hide()
		end
	end
end





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
textField:SetText("[\"Archive of the Titans\",205,400,626],[\"Relational Normalization Gizmo\",211,427,638]")
f:AddChild(textField)
f:Hide()
btn:SetCallback("OnClick", function() AzeriteForge:ImportWeights(textField:GetText()) end)

--Debug(AzeriteForge:Serialize(traitRanks))


--import  {[spellid]={1,2,3}


    function pairsByKeys (t, f)
      local a = {}
      for n in pairs(t) do table.insert(a, n) end
      table.sort(a, f)
      local i = 0      -- iterator variable
      local iter = function ()   -- iterator function
        i = i + 1
        if a[i] == nil then return nil
        else return a[i], t[a[i]]
        end
      end
      return iter
    end

    local AzeriteTraitsName_to_ID ={}

---------
function AzeriteForge:Build()
---------
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

		LibStub("AceConfigDialog-3.0"):Open("AzeriteForge_Talents", widget, "options")
		f:Show()
		end)

	f:SetScript("OnHide", function(self)

		f:Hide()
		end)

	LibStub("AceGUI-3.0"):RegisterAsContainer(widget)

	local mountButton = CreateFrame("Button", nil , MountJournal)
	mountButton:SetNormalTexture("Interface\\Buttons\\UI-MicroButton-Mounts-Up")
	mountButton:SetPushedTexture("Interface\\Buttons\\UI-MicroButton-Mounts-Down")
	mountButton:SetPoint("BOTTOMRIGHT", MountJournal, "BOTTOMRIGHT", 0, 0)
	mountButton:SetWidth(30)
	mountButton:SetHeight(45)
	mountButton:SetScript("OnClick", function(self, button, down)
		local Shift = IsShiftKeyDown()
		if Shift then
			selectedZone = C_Map.GetBestMapForUnit("player")
			EnableZoneEdit = not EnableZoneEdit
			GoGoMount_Manager:UpdateCB()
		else
			if f:IsShown() then
				f:Hide()
			else
				f:Show()
			end
		end

	end)
	mountButton:SetScript("OnEnter",
		function(self)
			GameTooltip:SetOwner (self, "ANCHOR_RIGHT")
			--GameTooltip:SetText(L.GOGOMOUNT_BUTTON_TOOLTIP, 1, 1, 1)
			GameTooltip:Show()
		end
	)
	mountButton:SetScript("OnLeave",
		function()
			GameTooltip:Hide()
		end
	)

			

	AzeriteForge:CreateTraitMenu()	
	
end


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
			azeriteTraits[traitID] [ "icon"] = icon
			azeriteTraits[traitID] [ "valid"] = true
			azeriteTraits[traitID] [ "name"] = name
			AzeriteTraitsName_to_ID[name]  = traitID
		end
	end



--[[
	for i=14,560 do
		local power = C_AzeriteEmpoweredItem.GetPowerInfo(i)
		if power then
			local name, _, icon = GetSpellInfo(power["spellID"])
			Debug(name.."."..i)
			azeriteTraits[i] = {}
			azeriteTraits[i] ["name"] = name
			azeriteTraits[i] ["spellID"] = power["spellID"]
			azeriteTraits[i] [ "icon"] = icon
			azeriteTraits[i] [ "valid"] = true
			AzeriteTraitsName_to_ID[name] = i
			--if icon ==136243 then break end --not actual trait

			local powerSpec = C_AzeriteEmpoweredItem.GetSpecsForPower(i)

			if powerSpec then 
				for x, y in pairs(powerSpec) do
				--classID

					if y["specID"] == specid then 

					azeriteTraits[i] [ "valid"] = "Class"
					break
					else 
					--azeriteTraits[i] [ "valid"] = false
					end
				end
			else 
				--azeriteTraits[i] [ "valid"] = "Generic"
				--azeriteTraits[i] [ "valid"] = false

			end
		end
	end

	]]--
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