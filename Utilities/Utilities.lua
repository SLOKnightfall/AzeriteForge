--###########################################
--Utilities

local FOLDER_NAME, private = ...
local TextDump = LibStub("LibTextDump-1.0")
local AF = LibStub("AceAddon-3.0"):GetAddon("AzeriteForge")
local L = LibStub("AceLocale-3.0"):GetLocale("AzeriteForge")
local AceGUI = LibStub("AceGUI-3.0")

AF.Utilities = {}
local Utilities = AF.Utilities
AF.Profiles = {}
local Profiles = AF.Profiles

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
		if debugger:Lines() == 0 then
			debugger:AddLine("Nothing to report.")
			debugger:Display()
			debugger:Clear()
			return
		end
		debugger:Display()

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

	Utilities.Debug = Debug
	Utilities.DebugPour = DebugPour
	Utilities.Export = Export
	Utilities.GetDebugger =  GetDebugger
end

--Check to see if character has the Have A Heart achievement which unlock Azerite powers
function Utilities.HasTheHeart()
	return  select(13,GetAchievementInfo(12918))
end

function Utilities.RefreshClassInfo()
	local spec = GetSpecialization()
	local specID, specName = GetSpecializationInfo(spec)
	local className, classFile, classID = UnitClass("player")

	return specID, specName, classID, className
end


function Utilities.duplicateNameCheck(profileName)
	for name in pairs(AF.db.global.userWeightLists) do
		if string.find(tostring(name), tostring(profileName)) then
			print("Duplicate Name Found. Choose another name")
			return true
		else

		end
	end
	return false
end


function Utilities.BuildDefaultTable(dataTable)
	local data = dataTable
	local specID, specName, classID, className = Utilities.RefreshClassInfo()
	local profileSpecID = AF.db.global.userWeightLists[data.name]["specID"] or 0
	local defaultList = {
			name = "List",
			type = "group",
			handler = AzeriteForge,
			type = "group",
			inline = false,
			args = {
				profileHeader = {
					name = "Profile Name",
					type = "header",
					width = "full",
					order = .01,
					},
				userDefinedName = {
					name = "",
					type = "input",
					width = "full",
					order = .03,
					set = function(info,val)  Profiles.RenameProfile(data.name,val) end,
					get = function(info) return data.name end,
					disabled = true,
					},

				profileDescription = {
					name = function()

						if not AF.db.global.userWeightLists[data.name] then return end
						
						local _, name, _,icon, _, class = GetSpecializationInfoByID(profileSpecID)

						if icon then
							icon = "|T"..icon..(":25:25:|t")
						else
							icon = ""
						end
						return ("%sClass: %s, Spec: %s"):format(icon or "",class or "", name or"") end,
						type = "description",
						width = "full",
						order = .04,
					},
				setProfile = {
					type = "execute",
					name = function () return L["Set as active profile"] end,
					order = .05,
					--width = "double",
					func = function(info, val) Profiles.LoadSelectedProfile(data.name); Profiles.BuildWeightedProfileList()
						end,
					disabled = function() return data.name == AF.db.char.weightProfile[specID] or data.spec ~= profileSpecID end,
						},
				deleteProfile = {
					type = "execute",
					name = L["Delete Profile"],
					order = .06,
					--width = ",
					func = function(info) deleteProfile(data.name)
						end,
					disabled = function() return data.name == AF.db.char.weightProfile[specID]    end,
					},
				copyProfile = {
					type = "execute",
					name = L["Copy Profile"],
					order = .06,
					--width = ",
					hidden = true,
					func = function()
						end,
					},
				traitsHeader = {
					name = "",
					type = "header",
					width = "full",
					order = .07,
					},
				search = {
					name = "",
					type = "input",
					width = "full",
					order = .08,
					set = function(info,val) AF.searchbar = val end,
					get = function(info) return AF.searchbar end,
					},
				},
			}
	return defaultList
end