--###########################################
--Profile Handlers

local FOLDER_NAME, private = ...
local AF = LibStub("AceAddon-3.0"):GetAddon("AzeriteForge")
local L = LibStub("AceLocale-3.0"):GetLocale("AzeriteForge")
local AceGUI = LibStub("AceGUI-3.0")

local locationIDs = {["Head"] = 1, ["Shoulder"] = 3, ["Chest"] = 5,}
local azeriteIcon = "Interface/Icons/Inv_smallazeriteshard"
local Utilities = AF.Utilities
local Profiles = AF.Profiles


function Profiles.GetUserProfile()
	local specID = Utilities.RefreshClassInfo()
	return  AF.db.char.weightProfile[specID]
 end


 function Profiles.SetUserProfile(profile)
	local specID, specName = Utilities.RefreshClassInfo()
	--AF.db.char.weightProfile[profile] = profile
	AF.db.char.weightProfile = AF.db.char.weightProfile or {}
	AF.db.char.weightProfile[specID] = AF.db.char.weightProfile[specID] or {}
	AF.db.char.weightProfile[specID] = profile
 end

local next = next 

function Profiles.LoadProfile()
	local specID, specName, classID, className = Utilities.RefreshClassInfo()
	AF.db.char.weightProfile = AF.db.char.weightProfile or {}
	 local userProfile = AF.db.char.weightProfile[specID]
	  local _, specName = Utilities.RefreshClassInfo()
	 local weightProfile = AF.db.global.userWeightLists[userProfile]

	local profileData = {}
	if not userProfile or not weightProfile  then
		userProfile =  "[Default] - "..className.." "..specName
		profileData = AF.loadDefaultData("StackData")
		AF.db.global.userWeightLists[userProfile] =  profileData

		AF.db.char.weightProfile[specID] = userProfile
		AF.traitRanks = profileData
		Profiles.BuildWeightedProfileList()

	else

	--local userProfile = AF.db.char.weightProfile[specID] or ""
		profileData = AF.db.global.userWeightLists[userProfile]
		AF.traitRanks = profileData
	end


	AF.db.global.userWeightLists[userProfile] = AF.traitRanks

--look for empy ranks and remove them
	for x, y in pairs(AF.traitRanks) do

		if type(y) == "table" then

			if not next(y) then AF.Debug("bad data"..x); y = nil end

		end
	end

	AF.traitRanks["specID"] = tonumber(AF.traitRanks["specID"])
	AF.traitRanks["classID"] = tonumber(AF.traitRanks["classID"])
--return profileData
end


function Profiles.GetProfileData(profile)
	return AF.db.global.userWeightLists[profile]
end


function Profiles.OldDataConvert()
	local specID, specName, classID, className = Utilities.RefreshClassInfo()
	local defaultProfile = ("Recovered profile: %s - %s"):format(className, specName)

	if not AzeriteForgeDB.SavedSpecData then return end

	local oldWeights = AzeriteForgeDB.SavedSpecData[specID]

	if oldWeights then
		--print("Old Data")
		Profiles.SetUserProfile(defaultProfile)

		AF.db.global.userWeightLists[defaultProfile] = CopyTable(oldWeights)
		AF.db.global.userWeightLists[defaultProfile]["specID"] = specID
		AF.db.global.userWeightLists[defaultProfile]["classID"] = classID
		AzeriteForgeDB.SavedSpecData[specID] = nil
	else
	end
end

function Profiles.RenameProfile(orig, new)
	if not new or new == "" then print("Name Can Not Be Blank") end
		if Utilities.duplicateNameCheck(new) then return false end
			AF.db.global.userWeightLists[new] = AF.db.global.userWeightLists[orig]
			AF.db.global.userWeightLists[orig] = nil
			Profiles.BuildWeightedProfileList()
		return true
	end


 function Profiles.LoadSelectedProfile(profile)
	local specID, specName, classID, className = Utilities.RefreshClassInfo()

	local profile_specID = AF.db.global.userWeightLists[profile].specID
	if tonumber(specID) ~= tonumber(profile_specID) then
	print("Wrong Spec")
	return false
	end

	Profiles.SetUserProfile(profile)
	AF.traitRanksProfileUpdate(profile)
 end


function Profiles.deleteProfile(profileName)
	AF.db.global.userWeightLists[profileName] = nil
	Profiles.BuildWeightedProfileList()
	print(("%s - Profile Deleted"):format(profileName))
end


function Profiles.BuildWeightedProfileList()
	local specID = Utilities.RefreshClassInfo()
	local counter = 1

	for x in pairs(AF.options.args.profiles.args) do
		if string.find(x ,"build_")  then
			AF.options.args.profiles.args[x] = nil
		end
	end
	local validSpec = {}
	for i=1, GetNumSpecializations() do
		local id = GetSpecializationInfo(i)
		validSpec[tonumber(id)] = true
	end

	for name, data in pairs(AF.db.global.userWeightLists) do
		local profileSpecID = tonumber(AF.db.global.userWeightLists[name]["specID"]) or 0

		if AzeriteForge.db.profile.showAllProfiles  or ( not AzeriteForge.db.profile.showAllProfiles and validSpec[profileSpecID])  then

			local dataTable = {}
			dataTable.name = name
			dataTable.spec = specID
			local defaultList = Utilities.BuildDefaultTable(dataTable)
			counter = counter + 1

			local fontColor = ""
			local _, _, _,icon = GetSpecializationInfoByID(profileSpecID)
			local iconText = ""


			if AF.db.char.weightProfile[specID] == name then
				fontColor = GREEN_FONT_COLOR_CODE
			elseif specID == profileSpecID then
				fontColor = NORMAL_FONT_COLOR_CODE
			elseif validSpec[profileSpecID] then
				fontColor = GRAY_FONT_COLOR_CODE
			elseif  not validSpec[profileSpecID] then
				fontColor = RED_FONT_COLOR_CODE

			end

			if icon then
				iconText = "|T"..icon..(":25:25:|t")
			end

			AF:CreateTraitMenu(defaultList.args , true, AF.db.global.userWeightLists[name] )
			local tablename = ("build_%s,%s"):format(name, counter)

			defaultList.name = fontColor..iconText..name


			defaultList.args.profileHeader.name = name
			AF.options.args.profiles.args[tablename] = defaultList
		end
	end
end