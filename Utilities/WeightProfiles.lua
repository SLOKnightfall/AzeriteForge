--###########################################
--Frame Generation


--AzeriteEmpoweredItemUI.BorderFrame.portrait
local FOLDER_NAME, private = ...
local TextDump = LibStub("LibTextDump-1.0")
AzeriteForge = LibStub("AceAddon-3.0"):GetAddon("AzeriteForge")
local L = LibStub("AceLocale-3.0"):GetLocale("AzeriteForge")
AzeriteForgeMiniMap = LibStub("LibDBIcon-1.0")
local AF = AzeriteForge
AF.Buttons = {}
local AceGUI = LibStub("AceGUI-3.0")
local buttons = AF.Buttons
AF.powerLocationButtonIDs = {}
local powerLocationButtonIDs = AF.powerLocationButtonIDs
AF.UnselectedPowers = {}
local UnselectedPowers = AF.UnselectedPowers
local BagScrollFrame
local locationIDs = {["Head"] = 1, ["Shoulder"] = 3, ["Chest"] = 5,}
local azeriteIcon = "Interface/Icons/Inv_smallazeriteshard"



--AzeriteForge.GetUserProfile()
--[[
local savedProfiles.profileName = ["classID"] ==
				["specID"]
				[weightData]

	AF.traitRanks = AzeriteForgeDB.SavedSpecData[specID] or AF.loadDefaultData("StackData")
	AzeriteForgeDB.SavedSpecData[specID] = AF.traitRanks

]]--

function AF.GetUserProfile()
 --print(AF.db.char.weightProfile)
 end


 function AF.SetUserProfile(profile)
 	local spec = GetSpecialization()
	local specID, specName = GetSpecializationInfo(spec)
	--AF.db.char.weightProfile[profile] = profile
	AF.db.char.weightProfile = AF.db.char.weightProfile or {}

	AF.db.char.weightProfile[specID] = AF.db.char.weightProfile[specID] or {}

		AF.db.char.weightProfile[specID] = profile


	--AF.db.char.selectedProfle[specID] = profile
  -- print(AF.db.char.weightProfile)
 end


function AF.OldDataConvert()
	local spec = GetSpecialization()
	local specID, specName = GetSpecializationInfo(spec)
	local className, classFile, classID = UnitClass("player")
	local defaultProfile = ("Recovered profile: %s - %s"):format(className, specName)

if not AzeriteForgeDB.SavedSpecData then return end

	local oldWeights = AzeriteForgeDB.SavedSpecData[specID]
	--AF.db.global.userWeightLists[userProfile]

	if oldWeights then
		print("Old Data")
		--print(defaultProfile)
		AF.SetUserProfile(defaultProfile)

		AF.db.global.userWeightLists[defaultProfile] = CopyTable(oldWeights)
		AF.db.global.userWeightLists[defaultProfile]["specID"] = specID
		AF.db.global.userWeightLists[defaultProfile]["classID"] = classID

		AzeriteForgeDB.SavedSpecData[specID] = nil


	--AF.db.char.selectedProfle or ("Default: %s-%s")format(class, spec)

	else

	--print("clear")


		--AF.db.global.userWeightLists[defaultProfile]["specID"] = specID
	end





end



local counter = 1




function AF.renameProfile(orig, new)
if not new or new == "" then print("Name Can Not Be Blank") end
	if AF.duplicateNameCheck(new) then return false end
		AF.db.global.userWeightLists[new] = AF.db.global.userWeightLists[orig]
		AF.db.global.userWeightLists[orig] = nil
		AF.BuildWeightedProfileList()
	return true
end


--function setActiveProfile(profile)


 function AF.LoadSelectedProfile(profile)
	local spec = GetSpecialization()
	local specID = GetSpecializationInfo(spec)
	local className, classFile, classID = UnitClass("player")

	local profile_specID = AF.db.global.userWeightLists[profile].specID
	if specID ~= profile_specID then
	print("Wrong Spec")
	return false
	end

	AF.db.char.weightProfile[specID] = profile

	AF.traitRanksProfileUpdate(profile)
 end


local function deleteProfile(profileName)

	AF.db.global.userWeightLists[profileName] = nil
	AF.BuildWeightedProfileList()
	print(("%s - Profile Deleted"):format(profileName))


end


function AF.BuildWeightedProfileList()
	local spec = GetSpecialization()
	local specID = GetSpecializationInfo(spec)

	for x in pairs(AF.options.args.weights.args) do
		if string.find(x ,"build_")  then
			AF.options.args.weights.args[x] = nil
		end
	end

	for name, data in pairs(AF.db.global.userWeightLists) do
	local profileSpecID = AF.db.global.userWeightLists[name]["specID"] or 0
	local data = {}
	local 	defaultList = {
			name = "List",
				type = "group",
			handler = AzeriteForge,
			type = "group",
			inline =false,
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
				set = function(info,val)  renameProfile(data.name,val) end,
				get = function(info) return data.name end,
				disabled = true,
				},

			profileDescription = {
				name = function()

					if not AF.db.global.userWeightLists[data.name] then return end
					local profileSpecID = AF.db.global.userWeightLists[data.name]["specID"] or 0
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
				func = function(info, val) AF.LoadSelectedProfile(data.name); AF.BuildWeightedProfileList()
					end,
				disabled = function() return data.name == AF.db.char.weightProfile[specID] end,
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

	counter = counter + 1

	local fontColor = ""
	local _, _, _,icon= GetSpecializationInfoByID(profileSpecID)
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
	--defaultList.args.userDefinedName.name = name
	AF.options.args.weights.args[tablename] = defaultList

	end

end