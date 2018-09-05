local FOLDER_NAME, private = ...
local TextDump = LibStub("LibTextDump-1.0")
AzeriteForge = LibStub("AceAddon-3.0"):GetAddon("AzeriteForge")
local L = LibStub("AceLocale-3.0"):GetLocale("AzeriteForge")
AzeriteForgeMiniMap = LibStub("LibDBIcon-1.0")
local AF = AzeriteForge
local maxValue = {}


--#####################################
--Modified blizzard plugins

LoadAddOn("Blizzard_AzeriteUI")
local function AzeriteEmpoweredItemPowerMixin_OnEnter(self,...)
	local location = self.azeriteItemDataSource:GetItemLocation()
	local duplicateLocations = AF:FindStackedTraits(self:GetAzeritePowerID(),location,AF.ReturnSelectedAzeriteTraits())

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
		local DB = AF.ReturnSelectedAzeriteTraits()

		local _, duplicateTraits = AF:FindStackedTraits(self:GetAzeritePowerID(),location, DB)


		if HasAnyUnselectedPowers then
			DB = AvailableAzeriteTraits
		end

		local traitRank = AF.getTraitRanking(self:GetAzeritePowerID(),location, DB)

		
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