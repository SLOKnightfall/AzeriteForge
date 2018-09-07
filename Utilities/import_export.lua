local FOLDER_NAME, private = ...
local TextDump = LibStub("LibTextDump-1.0")
AzeriteForge = LibStub("AceAddon-3.0"):GetAddon("AzeriteForge")
local L = LibStub("AceLocale-3.0"):GetLocale("AzeriteForge")
AzeriteForgeMiniMap = LibStub("LibDBIcon-1.0")
local AF = AzeriteForge


local APW_template = "^%s*%(%s*AzeritePowerWeights%s*:%s*(%d+)%s*:%s*\"([^\"]+)\"%s*:%s*(%d+)%s*:%s*(%d+)%s*:%s*(.+)%s*%)%s*$"
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

--Handler to import AzeriteForge export strings
local function AZForgeImport(data)
	wipe(AF.traitRanks)
	ClearDebugger()
	local classID, specID
	
	for class, spec in string.gmatch(data , "AZFORGE:(%w+):(%w+)") do
		classID = class
		specID = spec

	end
	local traits = {string.split("^",data )}

	for i, traitData in ipairs(traits) do
		for traitID, rankData in string.gmatch(traitData,"%[(%w+)%](.+)") do
			AF.traitRanks[tonumber(traitID)] = AF.traitRanks[tonumber(traitID)] or {}
			for id, rank in string.gmatch(rankData,"(%w+):(%p?%w+),") do
				AF.traitRanks[tonumber(traitID)][tonumber(id)] = tonumber(rank)
			end
		end
	end
	AF.traitRanks["specID"] = specID
	AF.traitRanks["classID"] = classID
	local profile = AF.db.char.weightProfile
	AF.db.global.userWeightLists[profile] = AF.traitRanks

	print("Importing AzeriteForge data")
end



--modified code from AzeritePowerWeights


--Inserts data from AzeritePowerWeights export strings
local function insertCustomScalesData(classIndex, specID, powerData) -- Inser into table
	local t = {}
	if powerData and powerData ~= "" then -- String to table
		for _, weight in pairs({ strsplit(",", powerData) }) do
			local azeritePowerID, value = strsplit("=", strtrim(weight))
			azeritePowerID = tonumber(azeritePowerID) or nil
			value = tonumber(value) or nil

			AF.traitRanks[azeritePowerID] = AF.traitRanks[azeritePowerID] or {}

			if azeritePowerID and value and value > 0 then
				value = value > reallyBigNumber and reallyBigNumber or value

				tinsert(AF.traitRanks[azeritePowerID],  value)

				if pvpPairs[azeritePowerID] then -- Mirror PvP Powers for both factions
					local pvpID = azeritePowerID + pvpPairs[azeritePowerID]
					AF.traitRanks[pvpID] = AF.traitRanks[pvpID] or {}
					tinsert(AF.traitRanks[pvpID],  value)
				end
			end
		end
			AF.traitRanks["specID"] = specID
			AF.traitRanks["classID"] = classIndex
			local profile = AF.db.char.weightProfile
			AF.db.global.userWeightLists[profile] = AF.traitRanks
	end

end


--Processes AzeritePowerWeights export strings
local function AzeritePowerWeightsImport(data)
		local player_spec = GetSpecialization()
		local player_specID = GetSpecializationInfo(player_spec)
		local startPos, endPos, stringVersion, scaleName, classID, specID, powerWeights = strfind(data, APW_template)

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
	local spec = AF.traitRanks["specID"]
	local class = AF.traitRanks["classID"]
	local text = ("AZFORGE:%s:%s^"):format(class,spec)

	for id, data in pairs(AF.traitRanks) do
		if not string.find(id, "specID") and not string.find(id, "classID") then 
			text = text.."["..id.."]"

			for i,d in pairs(data) do
				text = text..tostring(i)..":"..tostring(d)..","
			end

			text = text.."^"

		end
	end

	return Export(text)	 
end






