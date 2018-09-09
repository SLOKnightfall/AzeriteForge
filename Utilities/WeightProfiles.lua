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


function Profiles.LoadProfile()
	local specID, specName = Utilities.RefreshClassInfo()
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
--return profileData
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
	if specID ~= profile_specID then
	print("Wrong Spec")
	return false
	end

	Profiles.SetUserProfile(profile)
	AF.traitRanksProfileUpdate(profile)
 end


local function deleteProfile(profileName)
	AF.db.global.userWeightLists[profileName] = nil
	Profiles.BuildWeightedProfileList()
	print(("%s - Profile Deleted"):format(profileName))
end



local function createSelectedMenuPage()
	AF.options.args.weights = Utilities.BuildDefaultTable()
	AF.options.args.weights.name = L["Weight Profiles"]
	AF.options.args.weights.args.userDefinedName.name = "Profile Name"
	AF.options.args.weights.args.profileHeader.name = "Selected Profile"
	AF.options.args.weights.args.setProfile = nil
	AF.options.args.weights.args.deleteProfile = nil
	AF.options.args.weights.args.copyProfile = nil

	AF.options.args.weights.args.resetStacking = {
		type = "execute",
		name = L["Reset Default Data with Stacking Data"],
		order = 1,
		width = "double",
		func = function() local data = AF.loadDefaultData("StackData")
			local specID, specName, classID, className = Utilities.RefreshClassInfo()
			local profile = AF.db.char.weightProfile[specID]
			wipe(AF.traitRanks)
			AF.traitRanks = CopyTable(data)
			AF.traitRanks["specID"] = specID
			AF.traitRanks["classID"] = classID
			AF.db.global.userWeightLists[profile] = AF.traitRanks
			end,
		}
	AF.options.args.weights.args.resetIlevel = {
		type = "execute",
		name = L["Reset Default Data with iLevel Data"],
		order = 2,
		width = "double",
		func = function() local data = AF.loadDefaultData("iLevelData")
			local specID, specName, classID, className = Utilities.RefreshClassInfo()
			local profile = AF.db.char.weightProfile[specID]
			wipe(AF.traitRanks)
			AF.traitRanks = CopyTable(data)
			AF.traitRanks["specID"] = specID
			AF.traitRanks["classID"] = classID
			AF.db.global.userWeightLists[profile] = AF.traitRanks
			end,

		}

	AF.options.args.weights.args.clearData = {
		type = "execute",
		name = L["Clear all data"],
		order = 3,
		width = "double",
		func = function()
			local specID, specName, classID, className = Utilities.RefreshClassInfo()
			local profile = AF.db.char.weightProfile[specID]
			--local DB = AF.db.global.userWeightLists[weightProfile]
			wipe(AF.traitRanks)
			AF.traitRanks["specID"] = specID
			AF.traitRanks["classID"] = classID
			AF.db.global.userWeightLists[profile] = AF.traitRanks

			end,

		}

	AF.options.args.weights.args.importData = {
		type = "execute",
		name = L["Import Data"],
		order = 4,
		width = "double",
		func = function()
			AzeriteForge.ImportWindow:Show()
			end,

		}

	AF.options.args.weights.args.exportData = {
		type = "execute",
		name = L["Export Data"],
		order = 5,
		width = "double",
		func = function() AF:ExportData() end,
		}

	AF.options.args.weights.args.createNewProfile = {
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


				}
	AF:CreateTraitMenu(AF.options.args.weights.args)
end


function Profiles.BuildWeightedProfileList()
	local specID = Utilities.RefreshClassInfo()
	local counter = 1

	createSelectedMenuPage()

	for x in pairs(AF.options.args.weights.args) do
		if string.find(x ,"build_")  then
			AF.options.args.weights.args[x] = nil
		end
	end

	for name, data in pairs(AF.db.global.userWeightLists) do
		local profileSpecID = AF.db.global.userWeightLists[name]["specID"] or 0

		local defaultList = Utilities.BuildDefaultTable()
		counter = counter + 1

		local fontColor = ""
		local _, _, _,icon = GetSpecializationInfoByID(profileSpecID)
		local iconText = ""


		if AF.db.char.weightProfile[specID] == name then
			fontColor = GREEN_FONT_COLOR_CODE
		else

			fontColor = NORMAL_FONT_COLOR_CODE
		end

		if icon then
			iconText = "|T"..icon..(":25:25:|t")
		end

		AF:CreateTraitMenu(defaultList.args , true, AF.db.global.userWeightLists[name] )
		local tablename = ("build_%s,%s"):format(name, counter)

		defaultList.name = fontColor..iconText..name
		data.name = name

		defaultList.args.profileHeader.name = name
		AF.options.args.weights.args[tablename] = defaultList
	end
end