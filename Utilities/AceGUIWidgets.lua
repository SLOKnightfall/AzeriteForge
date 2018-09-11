--###########################################
--ACE 3 GUI Constructors

local FOLDER_NAME, private = ...
AzeriteForge = LibStub("AceAddon-3.0"):NewAddon(private, "AzeriteForge", "AceConsole-3.0", "AceEvent-3.0", "AceHook-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("AzeriteForge")
local AceGUI = LibStub("AceGUI-3.0")
local AF = AzeriteForge

local AzeriteLocations = {["Head"] = ItemLocation:CreateFromEquipmentSlot(1),
			["Shoulder"] = ItemLocation:CreateFromEquipmentSlot(3),
			["Chest"]= ItemLocation:CreateFromEquipmentSlot(5),
			[1] = "Head",
			[3] = "Shoulder",
			[5] = "Chest",}



--Constructor for ACE-GUI item
do
	local Type = "AzeriteForgeItem"
	local Version = 1

	local function OnAcquire(self)
		self:SetDisabled(false)
		self.showbutton = true
	end

	local function OnRelease(self)
		self.frame:ClearAllPoints()
		self.frame:Hide()
		self:SetDisabled(false)
	end

	local function Control_OnEnter(this)
		this.obj:Fire("OnEnter")
	end

	local function Control_OnLeave(this)
		this.obj:Fire("OnLeave")
	end


	local function SetDisabled(self, disabled)
		self.disabled = disabled
		if disabled then
		end
	end

	local function SetWidth(self, width)
		self.frame:SetWidth(width)
	end

	local function Constructor()
		local num  = AceGUI:GetNextWidgetNum(Type)

		local frame = CreateFrame("Frame","AzeriteForgeItem"..num,UIParent)
		frame:SetSize(50,50)

		local description = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
		description:ClearAllPoints()
		description:SetPoint("TOPLEFT", frame, "TOPLEFT")
		description:SetTextColor(1, 1, 1, 1)
		frame.description = text

		local item = CreateFrame("Button", "AzeriteForgeItem"..num.."item" ,frame,"ItemButtonTemplate")
		item:SetSize(35,35)
		item:SetPoint("TOPLEFT", description, "BOTTOMLEFT", 0,-5)
		item.icon:SetTexture(azeriteIcon)
		item:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetHyperlink(frame.itemLink)
			GameTooltip:Show()

		end)

		item:SetScript("OnClick", function(self, button, down)
			if button == "RightButton" then
				AF.ShowEmpoweredItem(AzeriteLocations["Head"])
				EquipItemByName(frame.itemLink)
				AF.ShowEmpoweredItem(AF.createItemLocation(frame.itemLink))
			else
			if (frame.location)then
				AF.ShowEmpoweredItem(frame.location)
				AF.Bag:Hide()
			end
			end
		end)

		item:SetScript("OnLeave", function(self) GameTooltip:Hide() end)

		local traits = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
		traits:ClearAllPoints()
		traits:SetPoint("TOPLEFT", item, "TOPRIGHT",5, 25)
		traits:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT")
		traits:SetTextColor(1, 1, 1, 1)
		frame.traits = text

		local weights = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
		weights:ClearAllPoints()
		weights:SetPoint("TOP", item, "BOTTOM",0, -7)
		--weights:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT")
		weights:SetTextColor(1, 1, 1, 1)
		frame.weights = text

		local self = {}
		self.type = Type
		self.num = num
		self.location = location
		self.itemLink = frame.itemLink

		self.OnRelease = OnRelease
		self.OnAcquire = OnAcquire

		self.SetDisabled = SetDisabled
		self.SetText = SetText
		self.SetWidth = SetWidth

		self.frame = frame
		frame.obj = self
		self.item = item
		item.obj = self
		self.description = description
		description.obj = self
		self.traits = traits
		traits.obj = self
		self.weights = weights
		weights.obj = self

		self.alignoffset = 30

		frame:SetHeight(109)
		frame:SetWidth(500)

		AceGUI:RegisterAsWidget(self)
		return self
	end

	AceGUI:RegisterWidgetType(Type,Constructor,Version)
end



do
	local Type = "AzeriteForgeFrame"
	local Version = 1

	local function OnAcquire(self)
		self:SetDisabled(false)
		self.showbutton = true
	end

	local function OnRelease(self)
		self.frame:ClearAllPoints()
		self.frame:Hide()
		self:SetDisabled(false)
	end

	local function Control_OnEnter(this)
		this.obj:Fire("OnEnter")
	end

	local function Control_OnLeave(this)
		this.obj:Fire("OnLeave")
	end


	local function SetDisabled(self, disabled)
		self.disabled = disabled
		if disabled then
		end
	end

	local function SetWidth(self, width)
		self.frame:SetWidth(width)
	end

		local function Show(self)
		self.frame:Show()
	end

	local function Hide(self)
		self.frame:Hide()
	end

	local function SetParent(self,parent)
		self.frame:SetParent(parent)
	end

	local function IsShown(self)
		return self.frame:IsShown()
	end

	local function SetScript(self,...)
		return self.frame:SetScript(...)
	end

	local function SetFrameStrata(self,...)
		self.frame:SetFrameStrata(...)
	end


	local function Constructor()
		local num  = AceGUI:GetNextWidgetNum(Type)

		local frame = CreateFrame("Frame","AzeriteForgeFrame"..num,UIParent, "InsetFrameTemplate")
		frame:Show()

		frame:SetFrameStrata("DIALOG")
		frame:SetWidth(500)
		frame:SetHeight(100)
		frame:SetPoint("CENTER")
		frame:SetMovable(false)

		--frame:EnableMouse(true)

		local titlebg = frame:CreateTexture(nil, "BORDER")
		titlebg:SetTexture("Interface\\PaperDollInfoFrame\\UI-GearManager-Title-Background") --
		titlebg:SetPoint("TOPLEFT", 9, -6)
		titlebg:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", -28, -24)

		local title = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
		title:SetPoint("CENTER", titlebg, -6, -3)
		title:SetTextColor(1, 1, 1, 1)

		local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
		close:SetPoint("TOPRIGHT", 2, 1)
		close:SetScript("OnClick", function() frame:Hide() end)


		local self = {}
		self.type = Type
		self.num = num
		self.content = frame
		self.background = _G["AzeriteForgeFrame"..num.."Bg"]

		self.OnRelease = OnRelease
		self.OnAcquire = OnAcquire

		self.SetDisabled = SetDisabled
		self.SetWidth = SetWidth
		self.Show = Show
		self.Hide = Hide
		self.SetParent = SetParent
		self.IsShown = IsShown
		self.SetScript = SetScript
		self.SetFrameStrata = SetFrameStrata

		self.frame = frame
		frame.obj = self
		self.titlebg = titlebg
		titlebg.ojb = self
		self.title = title
		title.obj = self
		self.close = close
		close.obj = self

		self.alignoffset = 30

		frame:SetHeight(109)
		frame:SetWidth(500)

		AceGUI:RegisterAsWidget(self)
		return self
	end

	AceGUI:RegisterWidgetType(Type,Constructor,Version)
end


--[[-----------------------------------------------------------------------------
Fix for texture error between Aurora & ACE Heading Widget
-------------------------------------------------------------------------------]]

AF:RawHook(AceGUI.WidgetRegistry,"Heading", function(self)
	local frame =  AF.hooks[AceGUI.WidgetRegistry]["Heading"]()
	frame.left:SetTexture("")
	frame.right:SetTexture("")
	frame.left:SetTexture("Interface\\Tooltips\\UI-Tooltip-Border")
	frame.right:SetTexture("Interface\\Tooltips\\UI-Tooltip-Border")
	return frame
end)