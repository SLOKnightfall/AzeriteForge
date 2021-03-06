local FOLDER_NAME, private = ...
local TextDump = LibStub("LibTextDump-1.0")
local AzeriteForge = LibStub("AceAddon-3.0"):GetAddon("AzeriteForge")
local L = LibStub("AceLocale-3.0"):GetLocale("AzeriteForge")
AzeriteForgeMiniMap = LibStub("LibDBIcon-1.0")
local AF = AzeriteForge
local maxValue = {}
local Utilities = AF.Utilities
local azeriteIcon = "Interface/Icons/Inv_smallazeriteshard"
local itemEquipLocToSlot = {
	["INVTYPE_HEAD"] = 1,
	["INVTYPE_SHOULDER"] = 3,
	["INVTYPE_CHEST"] = 5,
	["INVTYPE_ROBE"] = 5
}

--#####################################
--Modified blizzard plugins

LoadAddOn("Blizzard_AzeriteUI")
local function AzeriteEmpoweredItemPowerMixin_OnEnter(self,...)
	local location = self.azeriteItemDataSource:GetItemLocation()
	local item = self.azeriteItemDataSource:GetItem()

	local HasAnyUnselectedPowers, itemLink, locationID

	if location then
		itemLink = C_Item.GetItemLink(location)
	elseif item then
		itemLink = item.itemLink
	end
	local locationID = itemEquipLocToSlot[select(9,GetItemInfo(itemLink))]
	local hasTraitStacks = AF:FindStackedTraits(self:GetAzeritePowerID(),locationID,AF.ReturnSelectedAzeriteTraits())

	if hasTraitStacks then
		GameTooltip_AddColoredLine(GameTooltip, (L["Found on: %s"]):format(hasTraitStacks), RED_FONT_COLOR);
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

	local border = self:CreateTexture(nil, 'OVERLAY')
	border:SetWidth(67); border:SetHeight(67)
	border:SetPoint('CENTER', self)
	border:SetTexture("Interface/Buttons/UI-GROUPLOOT-PASS-DOWN")
	border:SetBlendMode('ADD')
	border:Hide()
	--border:SetVertexColor(0.4, 0.4, 0.4)
	self.border = border



end

AF:SecureHook(AzeriteEmpoweredItemPowerMixin,"Setup", AzeriteEmpoweredItemPowerMixin_Setup)


local function AzeriteEmpoweredItemPowerMixin_Reset(self)
	if self.AdditionalTraits then
		self.AdditionalTraits:Hide()
		self.TraitRank:Hide()
	end
end
AF:SecureHook(AzeriteEmpoweredItemPowerMixin,"Reset", AzeriteEmpoweredItemPowerMixin_Reset)



local function UpdateValues(location, tierIndex)
	local max = 0
	for id, rank in pairs(maxValue[location][tierIndex]) do

		if rank >= max then
			max = rank

		end
	end

	for id, rank in pairs(maxValue[location][tierIndex]) do
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
		local item = self.azeriteItemDataSource:GetItem()
		local HasAnyUnselectedPowers, itemLink, locationID

		if location then
			HasAnyUnselectedPowers = C_AzeriteEmpoweredItem.HasAnyUnselectedPowers(location)
			itemLink = C_Item.GetItemLink(location)
		elseif item then
			itemLink = item.itemLink
			location = item:GetItemLocation()
			HasAnyUnselectedPowers = true

		end

		locationID = itemEquipLocToSlot[select(9,GetItemInfo(itemLink))]
		location = AF.createItemLocation(itemLink)--location or ItemLocation:CreateFromEquipmentSlot(locationID)

		local DB = AF.ReturnSelectedAzeriteTraits()

		local _, duplicateTraits = AF:FindStackedTraits(self:GetAzeritePowerID(),locationID, DB)

		if HasAnyUnselectedPowers then
			DB = AvailableAzeriteTraits
		end
		local specID, specName, classID, className = Utilities.RefreshClassInfo()

		local powerData =  AF.azeriteTraits[self:GetAzeritePowerID()]

		local IsPowerAvailableForSpec =  powerData and powerData["valid"] or false
		local isPowerSelected = self:IsSelected()
		--if isPowerSelected then print(GetSpellInfo(AzeriteTooltip_GetSpellID(self:GetAzeritePowerID()))) end

		local traitRank = AF.getTraitRanking(self:GetAzeritePowerID(),location, itemLink)

		local tierIndex = self:GetTierIndex()

		maxValue[location] = maxValue[location] or {}
		maxValue[location][tierIndex] = maxValue[location][tierIndex] or {}
		maxValue[location][tierIndex][self] = traitRank or 0

		UpdateValues(location, tierIndex)

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


		if AzeriteForge.db.profile.desaturateUnuseable  and not IsPowerAvailableForSpec then
			self.IconOn:SetDesaturated(true)
			--self.border:Show()
			--print(self:GetAzeritePowerID())
		else
			self.IconOn:SetDesaturated(false)
			--self.border:Hide()
		end
	end
end
AF:SecureHook(AzeriteEmpoweredItemPowerMixin,"OnShow", AzeriteEmpoweredItemPowerMixin_OnShow)