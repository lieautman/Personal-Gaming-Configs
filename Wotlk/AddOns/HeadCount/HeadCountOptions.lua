--[[
Project name: HeadCount
Developed by: seppyk
Website: http://www.wowace.com/projects/head-count/
Description: Manages tracking of raid attendance and more.
License: Creative Common Attribution-NonCommercial-ShareAlike 3.0 Unported
File: HeadCountOptions.lua
File description: Options listing
]]

local L = AceLibrary("AceLocale-2.2"):new("HeadCount")
local HeadCount = HeadCount

local partyGroups = { "1", "2", "3", "4", "5", "6", "7", "8", }
local exportFormats = { 
	["EQdkp"] = "EQdkp", 
	["DKPBoard"] = "DKPBoard", 
	["phpBB"] = "phpBB",
	["phpBB_ItemStats"] = "phpBB_ItemStats", 
	["CSV"] = "CSV", 
	["Text"] = "Text", 
	["XML"] = "XML", 
}
local channels = { 
	["guild"] = "GUILD", 
	["officer"] = "OFFICER", 
	["party"] = "PARTY", 
	["raid"] = "RAID", 
	["say"] = "SAY", 
	["yell"] = "YELL",
}

-- configuration options
local options = { 
    type = "group", 
	handler = HeadCount, 
    args = {
        gui = {
            type = "execute", 
            name = L["console.command.gui.name"],
            desc = L["console.command.gui.description"],
			func = "ToggleUI", 
			order = 1, 
        },	
		raid = {
			type = "group", 
			name = L["console.command.raid.name"], 
			desc = L["console.command.raid.description"], 
			order = 2, 
		    args = {
				groupsetup = {
					type = "group", 
					name = L["console.command.raid.groupsetup.name"], 
					desc = L["console.command.raid.groupsetup.description"], 
					order = 1, 
					args = {
						raidlistgroups = { 
							type = "text", 
							name = L["console.command.raid.groupsetup.raidlistgroups.name"], 
							desc = L["console.command.raid.groupsetup.raidlistgroups.description"], 
							usage = L["console.usage.groups"], 
							multiToggle = true, 
							get = "GetRaidListGroups", 
							set = function(key, value) 
									HeadCount:SetRaidListGroups(key, value)
									HeadCount:RAID_ROSTER_UPDATE(false) 
							end, 
							validate = partyGroups, 
							order = 1, 					
						}, 
						waitlistgroups = { 
							type = "text", 
							name = L["console.command.raid.groupsetup.waitlistgroups.name"], 
							desc = L["console.command.raid.groupsetup.waitlistgroups.description"], 
							usage = L["console.usage.groups"], 
							multiToggle = true, 
							get = "GetWaitListGroups", 
							set = function(key, value) 
									HeadCount:SetWaitListGroups(key, value)
									HeadCount:RAID_ROSTER_UPDATE(false)
							end, 
							validate = partyGroups,  					
							order = 2, 					
						}, 		
						autogrouping = {
							type = "toggle", 
							name = L["console.command.raid.groupsetup.autogrouping.name"], 
							desc = L["console.command.raid.groupsetup.autogrouping.description"], 
							get = "IsAutomaticGroupSelectionEnabled", 
							set = "ToggleAutomaticGroupSelection", 
							order = 3, 						
						}, 						
					}, 
				}, 
				waitlist = {
					type = "group", 
					name = L["console.command.raid.waitlist.name"], 
					desc = L["console.command.raid.waitlist.description"], 
					order = 2, 
					args = {
						duration = {
							type = "range", 
							name = L["console.command.raid.waitlist.duration.name"], 
							desc = L["console.command.raid.waitlist.duration.description"], 
							get = "GetWaitlistDuration", 
							set = function(duration)
								HeadCount:SetWaitlistDuration(duration)
								HeadCount:manageWaitlistChange(duration)
							end, 
							min = 0,
							max = 30, 
							step = 1, 
							order = 1, 						
						}, 					
						autoremoval = {
							type = "toggle", 
							name = L["console.command.raid.waitlist.autoremoval.name"], 
							desc = L["console.command.raid.waitlist.autoremoval.description"], 
							get = "IsWaitlistAutoremovalEnabled", 
							set = function(key, value) 
								HeadCount:ToggleWaitlistAutoremoval()
								HeadCount:RAID_ROSTER_UPDATE(false)
							end,
							order = 2, 
						}, 
						incoming = {
							type = "toggle", 
							name = L["console.command.raid.waitlist.incoming.name"], 
							desc = L["console.command.raid.waitlist.incoming.description"], 
							get = "IsWaitlistIncomingEnabled", 
							set = "ToggleWaitlistIncoming", 
							order = 3, 
						}, 
						outgoing = {
							type = "toggle", 
							name = L["console.command.raid.waitlist.outgoing.name"], 
							desc = L["console.command.raid.waitlist.outgoing.description"], 
							get = "IsWaitlistOutgoingEnabled", 
							set = "ToggleWaitlistOutgoing", 
							order = 4, 
						}, 
						notify = {
							type = "toggle", 
							name = L["console.command.raid.waitlist.notify.name"], 
							desc = L["console.command.raid.waitlist.notify.description"], 
							get = "IsWaitlistNotifyEnabled", 
							set = "ToggleWaitlistNotify", 
							order = 5, 
						}
					}, 
				}, 
				pruning = {
					type = "group", 
					name = L["console.command.raid.pruning.name"], 
					desc = L["console.command.raid.pruning.description"], 
					order = 3, 
					args = {
						prune = {
							type = "toggle", 
							name = L["console.command.raid.pruning.prune.name"], 
							desc = L["console.command.raid.pruning.prune.description"], 
							get = "IsPruningEnabled", 
							set = "TogglePruning", 
							order = 1, 						
						}, 
						prunetime = { 
							type = "range", 
							name = L["console.command.raid.pruning.prunetime.name"], 
							desc = L["console.command.raid.pruning.prunetime.description"], 
							get = "GetPruningTime", 
							set = "SetPruningTime", 
							min = 1,
							max = 52, 
							step = 1, 
							order = 2, 
						},						
					}, 
				}, 
				delay = {
					type = "range", 
					name = L["console.command.raid.delay.name"], 
					desc = L["console.command.raid.delay.description"], 
					get = "GetDelay", 
					set = "SetDelay", 
					min = 0, 
					max = 20, 
					step = 1, 
					order = 4, 
				}, 
				bgtracking = {
					type = "toggle", 
					name = L["console.command.raid.bgtracking.name"], 
					desc = L["console.command.raid.bgtracking.description"], 
					get = "IsBattlegroundTrackingEnabled", 
					set = "ToggleBattlegroundTracking", 
					order = 5, 
				}, 					
			}, 
		}, 
		["datetime"] = {
			type = "group", 
			name = L["console.command.datetime.name"], 
			desc = L["console.command.datetime.description"], 
			order = 3, 
			args = {
			    dateformat = {
					type = "text",
					name = L["console.command.datetime.dateformat.name"], 
					desc = L["console.command.datetime.dateformat.description"], 	
					usage = L["console.usage.dateformat"], 
					get = "GetDateFormat",
					set = "SetDateFormat", 
					validate = L.dateFormatting, 
					order = 1, 
				}, 
				timetotals = { 
					type = "group", 
					name = L["console.command.datetime.timetotals.name"], 
					desc = L["console.command.datetime.timetotals.description"], 
					order = 2, 
					args = {
						raidlisttime = {
							type = "toggle", 
							name = L["console.command.datetime.timetotals.raidlisttime.name"], 
							desc = L["console.command.datetime.timetotals.raidlisttime.description"], 
							get = "IsRaidListTimeEnabled", 
							set = "ToggleRaidListTime", 
							order = 1, 
						}, 
						waitlisttime = {
							type = "toggle", 
							name = L["console.command.datetime.timetotals.waitlisttime.name"], 
							desc = L["console.command.datetime.timetotals.waitlisttime.description"], 							
							get = "IsWaitListTimeEnabled", 
							set = "ToggleWaitListTime", 							
							order = 2, 
						}, 
						offlinetime = {
							type = "toggle", 
							name = L["console.command.datetime.timetotals.offlinetime.name"], 
							desc = L["console.command.datetime.timetotals.offlinetime.description"], 							
							get = "IsOfflineTimeEnabled", 
							set = "ToggleOfflineTime", 
							order = 3, 
						}, 
					}, 
				}, 
				timezone = { 
					type = "range", 
					name = L["console.command.datetime.timezone.name"], 
					desc = L["console.command.datetime.timezone.description"], 
					get = "GetTimezone", 
					set = "SetTimezone", 
					min = -10 ,
					max = 14, 
					step = 1, 
					order = 3, 
				},
				timeformat = { 
					type = "toggle", 
					name = L["console.command.datetime.timeformat.name"], 
					desc = L["console.command.datetime.timeformat.description"], 
					get = "IsTimeFormatEnabled", 
					set = "ToggleTimeFormat", 
					order = 4, 
				}, 
			},
		},
		boss = {
			type = "group", 
			name = L["console.command.boss.name"], 
			desc = L["console.command.boss.description"], 
			order = 4, 		
			args = {
				["add"] = {
					type = "text", 
					name = L["console.command.boss.add.name"], 
					desc = L["console.command.boss.add.description"], 
					usage = L["console.command.boss.add.usage"], 
					get = false, 
					set = "AddBoss", 
					guiHidden = true, 
					order = 1, 
				},
				groupsetup = {
					type = "group", 
					name = L["console.command.boss.groupsetup.name"], 
					desc = L["console.command.boss.groupsetup.description"], 
					order = 2, 
					args = {
						raidlistgroup = {
							type = "toggle", 
							name = L["console.command.boss.groupsetup.raidlistgroup.name"], 
							desc = L["console.command.boss.groupsetup.raidlistgroup.description"], 
							get = "IsBossRaidListGroupEnabled", 
							set = "ToggleBossRaidListGroup", 
							order = 1, 
						}, 
						waitlistgroup = {
							type = "toggle", 
							name = L["console.command.boss.groupsetup.waitlistgroup.name"], 
							desc = L["console.command.boss.groupsetup.waitlistgroup.description"], 
							get = "IsBossWaitListGroupEnabled", 
							set = "ToggleBossWaitListGroup", 
							order = 2, 
						}, 
						nolistgroup = {
							type = "toggle", 
							name = L["console.command.boss.groupsetup.nolistgroup.name"], 
							desc = L["console.command.boss.groupsetup.nolistgroup.description"], 
							get = "IsBossNoListGroupEnabled", 
							set = "ToggleBossNoListGroup", 
							order = 3, 
						}, 			
						waitlist = {
							type = "toggle", 
							name = L["console.command.boss.groupsetup.waitlist.name"], 
							desc = L["console.command.boss.groupsetup.waitlist.description"], 
							get = "IsBossWaitListEnabled", 
							set = "ToggleBossWaitList", 
							order = 4, 	
							
						}, 
					}, 
				}, 
			}, 
		}, 		
		loot = {
			type = "group", 
			name = L["console.command.loot.name"], 
			desc = L["console.command.loot.description"], 
			order = 5, 
		    args = {
				minimum = {
					type = "text",
					name = L["console.command.loot.minimum.name"],
					desc = L["console.command.loot.minimum.description"], 
					usage = L["console.usage.item.quality"], 
					get = "GetMinimumLootQuality",
					set = "SetMinimumLootQuality", 
					validate = L.itemQuality, 
					order = 1, 
				},	
				popup = { 
					type = "toggle", 
					name = L["console.command.loot.popup.name"], 
					desc = L["console.command.loot.popup.description"], 
					get = "IsLootPopupEnabled", 
					set = "ToggleLootPopup", 
					order = 2, 
				}, 
				exclude = {
					type = "execute", 
					name = L["console.command.loot.exclude.name"], 
					desc = L["console.command.loot.exclude.description"], 
					func = "ManageExclusionList", 
					order = 3, 
				}, 
				["add"] = {
					type = "text", 
					name = L["console.command.loot.add.name"], 
					desc = L["console.command.loot.add.description"], 
					usage = L["console.command.loot.add.usage"], 
					get = false, 
					set = "AddLoot", 
					validate = "ValidateAddLoot", 
					guiHidden = true, 
					order = 4, 
				}, 
			}, 
		}, 
		export = {
			type = "group", 
			name = L["console.command.export.name"], 
			desc = L["console.command.export.description"], 
			order = 6, 
			args = {
				["format"] = {
					type = "text", 
					name = L["console.command.export.format.name"], 
					desc = L["console.command.export.format.description"], 
					usage = L["console.command.export.format.usage"], 
					get = "GetExportFormat", 
					set = "SetExportFormat", 
					validate = exportFormats,					
					order = 1, 
				}, 	
				["eqdkp"] = {
					type = "group", 
					name = L["console.command.export.eqdkp.name"], 
					desc = L["console.command.export.eqdkp.description"], 
					order = 2, 
					args = {
						["difficulty"] = {
							type = "toggle", 
							name = L["console.command.export.eqdkp.difficulty.name"], 
							desc = L["console.command.export.eqdkp.difficulty.description"], 
							get = "IsEQDKPDifficultyEnabled", 
							set = "ToggleEQDKPDifficulty", 
							order = 1, 
						}, 
					}, 
				}, 
			}, 
		}, 
		reporting = {
			type = "group", 
			name = L["console.command.reporting.name"], 
			desc = L["console.command.reporting.description"], 
			order = 7, 
			args = {
				broadcastchannel = {
					type = "text", 
					name = L["console.command.reporting.broadcastchannel.name"], 
					desc = L["console.command.reporting.broadcastchannel.description"], 
					usage = L["console.usage.channels"], 
					get = "GetBroadcastChannel", 
					set = "SetBroadcastChannel", 
					validate = channels, 
					order = 1, 
				}, 				
				bosskills = {
					type = "toggle", 
					name = L["console.command.reporting.bosskills.name"], 
					desc = L["console.command.reporting.bosskills.description"], 
					get = "IsBossBroadcastEnabled", 
					set = "ToggleBossBroadcast", 
					order = 2, 
				}, 
				loot = {
					type = "toggle", 
					name = L["console.command.reporting.loot.name"], 
					desc = L["console.command.reporting.loot.description"], 
					get = "IsLootBroadcastEnabled", 
					set = "ToggleLootBroadcast", 
					order = 3, 
				}, 				
			}, 		
		}, 
        ["debug"] = {
            type = "toggle", 
            name = L["console.command.debug.name"],
            desc = L["console.command.debug.description"],
            get = "IsDebugEnabled",
            set = "ToggleDebugEnabled", 
			order = 8, 
        }, 
		exclude = { 
			type = "group", 
			name = L["console.command.exclude.name"], 
			desc = L["console.command.exclude.description"], 			
			guiHidden = true, 
			order = 9, 
			args = { 
				add = {
					type = "text", 
					name = L["console.command.exclude.add.name"], 
					desc = L["console.command.exclude.add.description"], 
					usage = L["console.usage.exclude"], 
					get = false, 
					set = "AddToExclusionList", 
					validate = "ValidateAddToExclusionList", 
					order = 1, 
				}, 
				["remove"] = {
					type = "text", 
					name = L["console.command.exclude.remove.name"], 
					desc = L["console.command.exclude.remove.description"], 
					usage = L["console.usage.exclude"], 
					get = false, 
					set = "RemoveFromExclusionList", 
					validate = "ValidateRemoveFromExclusionList", 
					order = 2, 
				}, 				
		        ["list"] = {
		            type = "execute", 
		            name = L["console.command.exclude.list.name"],
		            desc = L["console.command.exclude.list.description"],
					func = "DisplayExclusionList", 
					order = 3, 
		        },	
			}, 
		}, 
    },
}

-- Gets the options.
-- @return table Returns the options.
function HeadCount:getOptions()
	return options
end

-- default configuration options
local defaultOptions = { 
	raidListGroups = { ["1"] = true, ["2"] = true, ["3"] = true, ["4"] = true, ["5"] = true, ["6"] = false, ["7"] = false, ["8"] = false, }, 
	waitListGroups = { ["1"] = false, ["2"] = false, ["3"] = false, ["4"] = false, ["5"] = false, ["6"] = true, ["7"] = true, ["8"] = true, }, 
	
	-- raid management
	raid = {
		["groupsetup"] = {
			["isAutomaticGroupSelectionEnabled"] = true, 
		}, 
		["waitlist"] = {
			["duration"] = 0, 		-- default announce duration of always enabled
			["autoremoval"] = true, -- automatically remove players from the wait list upon joining a raid list group
			["incoming"] = true, 	-- display incoming wait list whispers
			["outgoing"] = false, 	-- do NOT display outgoing wait list whispers
			["notify"] = false, 	-- do NOT display the waitlist notification message
		}, 
		["pruning"] = {
			["isPruningEnabled"] = false, 
			["pruningTime"] = 12,	-- default pruning time of ~3 months
		}, 
	}, 
	
	-- boss management
	boss = {
		["groupsetup"] = {
			["raidlistgroup"] = true, 
			["waitlistgroup"] = false, 
			["nolistgroup"] = false, 
			["waitlist"] = false, 
		}, 
	}, 
	
	delay = 5,	-- default delay value of 5 seconds
	isBattlegroundTrackingEnabled = false, 
	dateFormat = L.dateFormatting[2], 
	timezone = -5, -- "-5 GMT, Eastern Standard Time" 
	isTimeFormatEnabled = true, 
	isRaidListTimeEnabled = true, 
	isWaitListTimeEnabled = false, 
	isOfflineTimeEnabled = false, 
	minimumLootQuality = L.itemQuality[5],
	isLootPopupEnabled = false, 	
	broadcastChannel = channels["guild"], 
	isLootBroadcastEnabled = false, 
	isBossBroadcastEnabled = false,
	exportFormat = exportFormats["EQdkp"], 
	
	-- export
	export = { 
		["eqdkp"] = {
			["difficulty"] = false, 
		}, 
	}, 
	
	isDebugEnabled = false, 
	raidListWrapper = nil, 
	exclusionList = { 
		[20725] = true, -- Nexus Crystal
		[22450] = true, -- Void Crystal
		[29434] = true, -- Badge of Justice
		[30311] = true, -- Warp Slicer
		[30312] = true, -- Infinity Blade
		[30313] = true, -- Staff of Disintegration
		[30314] = true, -- Phaseshift Bulwark
		[30316] = true, -- Devastation
		[30317] = true, -- Cosmic Infuser
		[30318] = true, -- Netherstrand Longbow
		[30319] = true, -- Nether Spike
		[30320] = true, -- Bundle of Nether Spikes
		[34057] = true, -- Abyss Crystal
		[36919] = true, -- Cardinal Ruby
		[36922] = true, -- King's Amber
		[36925] = true, -- Majestic Zircon
		[36928] = true, -- Dreadstone
		[36931] = true, -- Ametrine
		[36934] = true, -- Eye of Zul
		[40752] = true, -- Emblem of Heroism
		[40753] = true, -- Emblem of Valor
		[45624] = true, -- Emblem of Conquest
		[47241] = true, -- Emblem of Triumph
		[49426] = true, -- Emblem of Frost
		[49110] = true, -- Nightmare Tear
	}, 
}

-- Gets the default options.
-- @return table Returns the default options.             
function HeadCount:getDefaultOptions()
	return defaultOptions
end

-----------------------------------------------------
-- TOGGLE USER INTERFACE
-----------------------------------------------------							
-- Opens the configuration menu
function HeadCount:ToggleUI() 
	if (UnitInRaid("player")) then
		HeadCount:RAID_ROSTER_UPDATE(false)	-- update attendance and the UI
	end
	
	HeadCount:ToggleUserInterface()
end

-----------------------------------------------------
-- GROUP SETUP
-----------------------------------------------------	
function HeadCount:isGroupNumberAssigned(groupNumber)
	local isGroupNumberValid = false
	
	if (HeadCount:isRaidListGroup(groupNumber) or HeadCount:isWaitListGroup(groupNumber)) then
		-- the group number is in the raid list or wait list
		isGroupNumberValid = true
	end
	
	return isGroupNumberValid
end

-- Determines if a party group number is assigned to the raid list group.
-- @param groupNumber The group number.
-- @return boolean Returns true if the group number is assigned to the raid list, false otherwise.
function HeadCount:isRaidListGroup(groupNumber) 
	local isGroupNumberValid = false

	assert(type(groupNumber), "string", string.format(L["error.type.string"], HeadCount.TITLE, "isRaidListGroup"))
	
	local groupString = string.format("%d", groupNumber)
	if (self.db.profile.raidListGroups[groupString]) then
		isGroupNumberValid = true
	end
	
	return isGroupNumberValid
end

-- Determines if a party group number is assigned to the wait list group.
-- @return boolean Returns true if the group number is assigned to the wait list, false otherwise.
function HeadCount:isWaitListGroup(groupNumber) 
	local isGroupNumberValid = false

	assert(type(groupNumber), "string", string.format(L["error.type.string"], HeadCount.TITLE, "isWaitListGroup"))

	local groupString = string.format("%d", groupNumber)	
	if (self.db.profile.waitListGroups[groupString]) then
		isGroupNumberValid = true
	end
	
	return isGroupNumberValid
end

-- *** ATTENDANCE TRACKING ***
-- Gets the raid list groups table.
-- @return table Returns the raid list groups table.
function HeadCount:GetRaidListGroupsTable() 
	return self.db.profile.raidListGroups
end

-- Gets the raid list groups status.
-- @param key The raid list group key.
-- @return boolean Returns the raid list group status value.
function HeadCount:GetRaidListGroups(key) 
	return self.db.profile.raidListGroups[key]
end

-- Sets the raid list groups.
-- @param key The raid list group key.
-- @param value The raid list group status.
function HeadCount:SetRaidListGroups(key, value) 
	self.db.profile.raidListGroups[key] = value
    
    -- HeadCount:LogDebug(string.format(L["debug.console.command.raid.groupsetup.raidlistgroups.set"], HeadCount.TITLE, HeadCount.VERSION, key, HeadCount:convertBooleanToString(value)))

	if (value) then
		self.db.profile.waitListGroups[key] = false
	end
end

-- Gets the wait list groups status.
-- @return boolean Returns true if this group is a member of the wait list, false otherwise.
function HeadCount:GetWaitListGroups(key) 
	return self.db.profile.waitListGroups[key]
end

-- Sets the wait list groups.
-- @param key The wait list group key.
-- @param value The wait list group status.
function HeadCount:SetWaitListGroups(key, value) 
	self.db.profile.waitListGroups[key] = value
	
    -- HeadCount:LogDebug(string.format(L["debug.console.command.raid.groupsetup.waitlistgroups.set"], HeadCount.TITLE, HeadCount.VERSION, key, HeadCount:convertBooleanToString(value)))
    
	if (value) then
		self.db.profile.raidListGroups[key] = false 
	end
end

-- Gets the automatic group selection.
-- @return boolean Returns true if automatic group select is enabled and false otherwise.
function HeadCount:IsAutomaticGroupSelectionEnabled()
	return self.db.profile.raid["groupsetup"]["isAutomaticGroupSelectionEnabled"]
end

-- Sets/toggles automatic group selection.
function HeadCount:ToggleAutomaticGroupSelection()
	self.db.profile.raid["groupsetup"]["isAutomaticGroupSelectionEnabled"] = not self.db.profile.raid["groupsetup"]["isAutomaticGroupSelectionEnabled"]
end

-----------------------------------------------------
-- WAITLIST MANAGEMENT
-----------------------------------------------------	
-- Gets the wait list acceptance duration.
-- @return number Returns the wait list acceptance duration.
function HeadCount:GetWaitlistDuration()
	return self.db.profile.raid["waitlist"]["duration"]
end

-- Sets the wait list acceptance duration.
-- @param duration The wait list acceptance duration.
function HeadCount:SetWaitlistDuration(duration) 
	self.db.profile.raid["waitlist"]["duration"] = duration
end

-- Gets the wait list automatic removal flag.
-- @return boolean Returns true if players are automatically removed from the wait list upon joining a raid list group and false otherwise.
function HeadCount:IsWaitlistAutoremovalEnabled()
	return self.db.profile.raid["waitlist"]["autoremoval"]
end

-- Sets/toggles the wait list automatic removal flag.
function HeadCount:ToggleWaitlistAutoremoval()
	self.db.profile.raid["waitlist"]["autoremoval"] = not self.db.profile.raid["waitlist"]["autoremoval"]
end

-- Gets the wait list incoming whispers flag.
-- @return boolean Returns true if incoming wait list whispers are displayed and false otherwise.
function HeadCount:IsWaitlistIncomingEnabled() 
	return self.db.profile.raid["waitlist"]["incoming"]
end

-- Sets/toggles the wait list incoming whispers flag.
function HeadCount:ToggleWaitlistIncoming()
	self.db.profile.raid["waitlist"]["incoming"] = not self.db.profile.raid["waitlist"]["incoming"]
end

-- Gets the wait list outgoing whispers flag.
-- @return boolean Returns true if outgoing wait list whispers are displayed and false otherwise.
function HeadCount:IsWaitlistOutgoingEnabled()
	return self.db.profile.raid["waitlist"]["outgoing"]
end

-- Sets/toggles the wait list outgoing whispers flag.
function HeadCount:ToggleWaitlistOutgoing()
	self.db.profile.raid["waitlist"]["outgoing"] = not self.db.profile.raid["waitlist"]["outgoing"]
end

-- Gets the wait list notify message flag.
-- @return boolean Returns true if the wait list notify flag is enabled and false otherwise.
function HeadCount:IsWaitlistNotifyEnabled()
	return self.db.profile.raid["waitlist"]["notify"]
end

-- Sets/toggles the wait list notify message flag.
function HeadCount:ToggleWaitlistNotify()
	self.db.profile.raid["waitlist"]["notify"] = not self.db.profile.raid["waitlist"]["notify"]
end

-----------------------------------------------------
-- RAID PRUNING
-----------------------------------------------------							
-- Gets the automatic pruning selection
-- @return boolean Returns true if automatic pruning is enabled and false otherwise.
function HeadCount:IsPruningEnabled() 
	return self.db.profile.raid["pruning"]["isPruningEnabled"]
end

-- Sets/toggles automatic pruning.
function HeadCount:TogglePruning()
	self.db.profile.raid["pruning"]["isPruningEnabled"] = not self.db.profile.raid["pruning"]["isPruningEnabled"]
end
	
-- Gets the pruning time in number of weeks.
-- @return number Returns the pruning time in number of weeks.
function HeadCount:GetPruningTime() 
	return self.db.profile.raid["pruning"]["pruningTime"]
end

-- Sets the pruning time in number of weeks.
-- @param number The pruning time in number of weeks.
function HeadCount:SetPruningTime(pruningTime)
	self.db.profile.raid["pruning"]["pruningTime"] = pruningTime
end
				
-----------------------------------------------------
-- MISCELLANEOUS RAID MANAGEMENT
-----------------------------------------------------					
-- Gets the attendance delay value.
-- @return number Returns the attendance delay value
function HeadCount:GetDelay()
	return self.db.profile.delay
end

-- Sets the attendance delay.
-- @param delay The attendance delay value
function HeadCount:SetDelay(delay)
	self.db.profile.delay = delay
end
					
-- Gets the battleground tracking status
-- @return boolean Returns true if battleground tracking is enabled and false otherwise.
function HeadCount:IsBattlegroundTrackingEnabled()
	return self.db.profile.isBattlegroundTrackingEnabled
end

-- Sets/toggles battleground tracking
function HeadCount:ToggleBattlegroundTracking()
	self.db.profile.isBattlegroundTrackingEnabled = not self.db.profile.isBattlegroundTrackingEnabled
	
	HeadCount:RAID_ROSTER_UPDATE(false)	-- update attendance and the UI
end

-----------------------------------------------------
-- DATE AND TIME
-----------------------------------------------------					
-- Gets the date format
-- @return string The date format
function HeadCount:GetDateFormat() 
	return self.db.profile.dateFormat
end

-- Sets the date format
-- @param value The date format
function HeadCount:SetDateFormat(value) 
	self.db.profile.dateFormat = value
	HeadCount:HeadCountFrame_Update()	-- display change, update the UI
end

-- Gets the time zone difference (from UTC).
-- @return number Returns the time zone difference.
function HeadCount:GetTimezone() 
	return self.db.profile.timezone
end

-- Sets the time zone difference (from UTC).
-- @param timezone Sets the time zone difference.
function HeadCount:SetTimezone(timezone)
	self.db.profile.timezone = timezone
	HeadCount:HeadCountFrame_Update()	-- display change, update the UI
end

-- Gets the time format status
-- @return boolean Returns true if in 24-hour time format, false for 12-hour time format.
function HeadCount:IsTimeFormatEnabled() 
	return self.db.profile.isTimeFormatEnabled
end

-- Sets/toggles the time format status
function HeadCount:ToggleTimeFormat() 
	self.db.profile.isTimeFormatEnabled = not self.db.profile.isTimeFormatEnabled
	HeadCount:HeadCountFrame_Update()	-- display change, update the UI
end

-- Gets the raid list time status.
-- @return boolean Returns true if raid list time is enabled and false otherwise.
function HeadCount:IsRaidListTimeEnabled()
	return self.db.profile.isRaidListTimeEnabled
end

-- Sets/toggles the raid list time status.
function HeadCount:ToggleRaidListTime()
	self.db.profile.isRaidListTimeEnabled = not self.db.profile.isRaidListTimeEnabled
	HeadCount:HeadCountFrame_Update()
end

-- Gets the wait list time status.
-- @return boolean Returns true if wait list time is enabled and false otherwise.
function HeadCount:IsWaitListTimeEnabled()
	return self.db.profile.isWaitListTimeEnabled
end

-- Sets/toggles the wait list time status.
function HeadCount:ToggleWaitListTime()
	self.db.profile.isWaitListTimeEnabled = not self.db.profile.isWaitListTimeEnabled
	HeadCount:HeadCountFrame_Update()
end

-- Gets the offline time status.
-- @return boolean Returns true if offline time is enabled and false otherwise.
function HeadCount:IsOfflineTimeEnabled() 
	return self.db.profile.isOfflineTimeEnabled
end

-- Sets/toggles the offline time status.
function HeadCount:ToggleOfflineTime()
	self.db.profile.isOfflineTimeEnabled = not self.db.profile.isOfflineTimeEnabled
	HeadCount:HeadCountFrame_Update()
end

-----------------------------------------------------
-- BOSS
-----------------------------------------------------	
-- Gets the boss raid list group enabled status.
-- @return boolean Returns true if raid list group members are enabled for boss attendance and false otherwise.
function HeadCount:IsBossRaidListGroupEnabled()
	return self.db.profile.boss["groupsetup"]["raidlistgroup"]
end

-- Sets/toggles the boss raid list group enabled status.
function HeadCount:ToggleBossRaidListGroup()
	self.db.profile.boss["groupsetup"]["raidlistgroup"] = not self.db.profile.boss["groupsetup"]["raidlistgroup"]
end

-- Gets the boss wait list group enabled status.
-- @return boolean Returns true if wait list group members are enabled for boss attendance and false otherwise.
function HeadCount:IsBossWaitListGroupEnabled()
	return self.db.profile.boss["groupsetup"]["waitlistgroup"]
end

-- Sets/toggles the boss wait list group enabled status.
function HeadCount:ToggleBossWaitListGroup()
	self.db.profile.boss["groupsetup"]["waitlistgroup"] = not self.db.profile.boss["groupsetup"]["waitlistgroup"]
end

-- Gets the boss no list group enabled status.
-- @return boolean Returns true if no list group members are enabled for boss attendance and false otherwise.
function HeadCount:IsBossNoListGroupEnabled()
	return self.db.profile.boss["groupsetup"]["nolistgroup"]
end

-- Sets/toggles the boss no list group enabled status.
function HeadCount:ToggleBossNoListGroup()
	self.db.profile.boss["groupsetup"]["nolistgroup"] = not self.db.profile.boss["groupsetup"]["nolistgroup"]
end

-- Gets the boss wait list enabled status.
-- @return boolean Returns true if wait list members are enabled for boss attendance and false otherwise.
function HeadCount:IsBossWaitListEnabled() 
	return self.db.profile.boss["groupsetup"]["waitlist"]
end

-- Sets/toggles the boss wait list enabled status.
function HeadCount:ToggleBossWaitList()
	self.db.profile.boss["groupsetup"]["waitlist"] = not self.db.profile.boss["groupsetup"]["waitlist"]
end
	
-- Manually add a boss to a given raid.
-- @param args The boss value arguments.
-- ADDED BY JerryBlade
function HeadCount:AddBoss(args)

	local _, _, bossName = string.find(args, "^(%a+)$")
	local convertedBossName = args
	
	local raidTracker = HeadCount:getRaidTracker() 
	if (raidTracker) then
		if (raidTracker:isRaidActive()) then
			local utcDateTimeInSeconds = HeadCount:getUTCDateTimeInSeconds()
			local activityTime = AceLibrary("HeadCountTime-1.0"):new({ ["utcDateTimeInSeconds"] = utcDateTimeInSeconds })
			local realZoneText = GetRealZoneText()
			local difficulty = HeadCount:determineDifficulty()
			-- local encounterName = HeadCount:retrieveBossEncounterName(lootSource)
			local encounterName = convertedBossName
		
			local currentRaid = raidTracker:retrieveMostRecentRaid()
			raidTracker:processAttendance(activityTime)	-- update attendance
			local raidMemberSort = HeadCount:getRAID_MEMBER_SORT()	
			local playerList = currentRaid:retrieveOrderedPlayerList("Name", HeadCount:IsBossRaidListGroupEnabled(), HeadCount:IsBossWaitListGroupEnabled(), HeadCount:IsBossNoListGroupEnabled(), HeadCount:IsBossWaitListEnabled(), true, true)

			local bossargs = {
				["name"] = encounterName, 
				["zone"] = realZoneText, 
				["difficulty"] = difficulty, 
				["activityTime"] = activityTime, 
				["playerList"] = playerList
			}
				
			local boss = AceLibrary("HeadCountBoss-1.0"):new(bossargs)									
			currentRaid:addBoss(boss)
			-- Broadcast the kill?
			if (HeadCount:IsBossBroadcastEnabled()) then
				-- boss kill broadcasting is enabled
				local channel = HeadCount:GetBroadcastChannel()
				HeadCount:SendMessage(string.format(L["guild.broadcast.manualbosskill"], encounterName), channel)
			end

			HeadCount:LogInformation(string.format(L["info.boss.add.success"], HeadCount.TITLE, HeadCount.VERSION, convertedBossName))				
			HeadCount:HeadCountFrame_Update()	-- display change, update the UI
		else
			HeadCount:LogWarning(string.format(L["warning.boss.add.failure.activeraid"], HeadCount.TITLE, HeadCount.VERSION, convertedBossName))
		end
	else
		HeadCount:LogError(string.format(L["warning.boss.add.failure.raidtracker"], HeadCount.TITLE, HeadCount.VERSION))
	end
end

-----------------------------------------------------
-- LOOT
-----------------------------------------------------					
-- Gets the minimum loot tracking quality.
-- @return string Returns the minimum loot tracking quality.
function HeadCount:GetMinimumLootQuality()
	return self.db.profile.minimumLootQuality
end

-- Sets the minimum loot tracking quality.
-- @param minimumLootQuality The minimum loot quality.
function HeadCount:SetMinimumLootQuality(minimumLootQuality)
	self.db.profile.minimumLootQuality = self:convertStringToProperName(minimumLootQuality)
end

-- Gets the loot popup status
-- @return boolean Returns true if the loot popup is enabled and false otherwise
function HeadCount:IsLootPopupEnabled()
	return self.db.profile.isLootPopupEnabled
end

-- Sets/toggles the loot popup status
function HeadCount:ToggleLootPopup()
	self.db.profile.isLootPopupEnabled = not self.db.profile.isLootPopupEnabled
end

-- Manage the exclusion list.
function HeadCount:ManageExclusionList()
	HeadCount:LogInformation(string.format(L["info.exclude.loot.manage"], HeadCount.TITLE, HeadCount.VERSION))
end

-- Manually add a piece of loot to a given raid.
-- @param args The loot value arguments.
function HeadCount:AddLoot(args)
	local _, _, link, raidNumber, playerName = string.find(args, "^(|c%x+|Hitem:[-%d:]+|h%[.-%]|h|r)%s+(%d+)%s+(%a+)$")	-- loot link
	local itemId = string.match(link, "item:(%d+):")
	local convertedRaidNumber = tonumber(raidNumber)
	local convertedPlayerName = HeadCount:convertStringToProperName(playerName)
	
	local raidTracker = HeadCount:getRaidTracker() 
	if (raidTracker) then
		-- get the raid with ordered id of convertedraidnumber and add loot to that raid
		local orderedRaidList = raidTracker:retrieveOrderedRaidList(false)	-- ascending ordered raid list
		local raid = orderedRaidList[convertedRaidNumber]
		if (raid) then 
			local utcDateTimeInSeconds = HeadCount:getUTCDateTimeInSeconds()
			local activityTime = AceLibrary("HeadCountTime-1.0"):new({ ["utcDateTimeInSeconds"] = utcDateTimeInSeconds })
			local realZoneText = GetRealZoneText()
			local loot = AceLibrary("HeadCountLoot-1.0"):new({ ["itemId"] = itemId, ["playerName"] = convertedPlayerName, ["cost"] = 0, ["activityTime"] = activityTime, ["quantity"] = HeadCount.DEFAULT_LOOT_QUANTITY, ["zone"] = realZoneText, ["source"] = HeadCount.DEFAULT_LOOT_SOURCE, ["note"] = nil, })
			raid:addLoot(loot)
			
			HeadCount:LogInformation(string.format(L["info.loot.add.success"], HeadCount.TITLE, HeadCount.VERSION, link, convertedPlayerName, convertedRaidNumber))				
			
			HeadCount:HeadCountFrame_Update()	-- display change, update the UI
		else
			HeadCount:LogError(string.format(L["error.loot.add.failure.raidtracker"], HeadCount.TITLE, HeadCount.VERSION, convertedRaidNumber))
		end
	else
		HeadCount:LogError(string.format(L["warning.loot.add.failure.raidtracker"], HeadCount.TITLE, HeadCount.VERSION))
	end
end

-- Validate manual loot addition
-- @param args The loot value arguments.
function HeadCount:ValidateAddLoot(args) 
	local isValid = false
	
	if (args) then 
		HeadCount:LogDebug(string.format(L["debug.loot.add.arguments"], HeadCount.TITLE, HeadCount.VERSION, args))

		local _, _, link, raidNumber, playerName = string.find(args, "^(|c%x+|Hitem:[-%d:]+|h%[.-%]|h|r)%s+(%d+)%s+(%a+)$")	-- loot link
		if ((link) and (raidNumber) and (playerName)) then 
			-- received three arguments (a link, a non-negative number, and a string)
			
			-- determine if the raid number if a valid raid
			local raidTracker = HeadCount:getRaidTracker() 
			if (raidTracker) then
				local numberOfRaids = raidTracker:getNumberOfRaids()
				local convertedRaidNumber = tonumber(raidNumber)	-- converted raid number
				if ((convertedRaidNumber > 0) and (convertedRaidNumber <= numberOfRaids)) then
					-- valid raid id, add the loot!
					isValid = true
				else
					HeadCount:LogWarning(string.format(L["warning.loot.add.failure.raidnumber"], HeadCount.TITLE, HeadCount.VERSION, convertedRaidNumber))	
				end
			end	
			--local id = string.match(value, "item:(%d+):")		-- loot id
			--local convertedRaidNumber = tonumber(raidNumber)	-- converted raid number
			--local convertedPlayerName = playerName
		else
			HeadCount:LogWarning(string.format(L["warning.loot.add.failure.arguments"], HeadCount.TITLE, HeadCount.VERSION))
		end	
	end
	
	return isValid
end

-----------------------------------------------------
-- EXPORT
-----------------------------------------------------			
-- Gets the export format.
-- @return string Returns the export format.
function HeadCount:GetExportFormat()
	return self.db.profile.exportFormat
end

-- Sets the export format.
-- @param exportFormat The export format.
function HeadCount:SetExportFormat(exportFormat) 
	self.db.profile.exportFormat = exportFormat
end

-- Gets the EQdkp difficulty status
-- @return boolean Returns true if EQdkp difficulty is enabled and false otherwise.
function HeadCount:IsEQDKPDifficultyEnabled()
	return self.db.profile.export["eqdkp"]["difficulty"]
end

-- Sets/toggles the EQdkp difficulty
function HeadCount:ToggleEQDKPDifficulty()
	self.db.profile.export["eqdkp"]["difficulty"] = not self.db.profile.export["eqdkp"]["difficulty"]
end

-----------------------------------------------------
-- REPORTING
-----------------------------------------------------					
-- Gets the loot broadcast status
-- @return boolean Returns true if loot broadcast is enabled and false otherwise.
function HeadCount:IsLootBroadcastEnabled()
	return self.db.profile.isLootBroadcastEnabled
end

-- Gets the broadcast channel
-- @return string Returns the broadcast channel
function HeadCount:GetBroadcastChannel()
	return self.db.profile.broadcastChannel
end

-- Sets the broadcast channel
-- @param broadcastChannel The broadcast channel
function HeadCount:SetBroadcastChannel(broadcastChannel) 
	self.db.profile.broadcastChannel = broadcastChannel
end

-- Sets/toggles loot broadcast
function HeadCount:ToggleLootBroadcast()
	self.db.profile.isLootBroadcastEnabled = not self.db.profile.isLootBroadcastEnabled
end

-- Gets the boss kill broadcast status
-- @return boolean Returns true if loot broadcast is enabled and false otherwise.
function HeadCount:IsBossBroadcastEnabled()
	return self.db.profile.isBossBroadcastEnabled
end

-- Sets/toggles the boss broadcast
function HeadCount:ToggleBossBroadcast()
	self.db.profile.isBossBroadcastEnabled = not self.db.profile.isBossBroadcastEnabled
end
			
-----------------------------------------------------
-- MISCELLANEOUS
-----------------------------------------------------
-- Gets the debug mode status
-- @return boolean Returns true if the debug flag is enabled, false otherwise.
function HeadCount:IsDebugEnabled() 
	return self.db.profile.isDebugEnabled
end

-- Sets/toggles the debug mode status
function HeadCount:ToggleDebugEnabled() 
    self.db.profile.isDebugEnabled = not self.db.profile.isDebugEnabled
end

-- Gets the raid list wrapper.
-- @return table Returns the raid list wrapper.
function HeadCount:GetRaidListWrapper() 
	return self.db.profile.raidListWrapper
end

-- Sets the raid list wrapper.
-- @param raidListWrapper The raid list wrapper.
function HeadCount:SetRaidListWrapper(raidListWrapper) 
	self.db.profile.raidListWrapper = raidListWrapper
end

-- Gets the exclusion list
-- @return table
function HeadCount:GetExclusionList()
	return self.db.profile.exclusionList
end

-- Sets the exclusion list.
-- @param exclusionList The exclusion list.
function HeadCount:SetExclusionList(exclusionList)
	self.db.profile.exclusionList = exclusionList
end

-- Adds an item to the exclusion list
-- @param link The loot name or link
function HeadCount:AddToExclusionList(link) 	
	local id = string.match(link, "item:(%d+):")	

	local numberId = tonumber(id)
	self.db.profile.exclusionList[numberId] = true
	
	HeadCount:LogInformation(string.format(L["info.exclude.add.success"], HeadCount.TITLE, HeadCount.VERSION, link))				
end

-- Validates addition to the exclusion list.
-- @param name The loot link.
function HeadCount:ValidateAddToExclusionList(name) 
	local isValid = false
	local _, _, link = string.find(name, "(|c%x+|Hitem:[-%d:]+|h%[.-%]|h|r)")
	local id = string.match(name, "item:(%d+):")
	
	if ((link) and (id)) then 
		-- item passed in is a link		
		local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture = GetItemInfo(id)
		if (itemName) then
			-- lookup for base item valid
			local numberId = tonumber(id)
			if (self.db.profile.exclusionList[numberId]) then
				-- item is in the exclusion list
				HeadCount:LogWarning(string.format(L["error.exclude.duplicate"], HeadCount.TITLE, HeadCount.VERSION, itemLink))				
			else
				isValid = true
			end
		end
	end
	
	return isValid
end

-- Removes an item from the exclusion list.
-- @param link The loot name or link.
function HeadCount:RemoveFromExclusionList(link) 
	local id = string.match(link, "item:(%d+):")	

	local numberId = tonumber(id)
	self.db.profile.exclusionList[numberId] = nil
	
	HeadCount:LogInformation(string.format(L["info.exclude.remove.success"], HeadCount.TITLE, HeadCount.VERSION, link))				
end

-- Validates removal from the exclusion list.
-- @param link The loot link.
function HeadCount:ValidateRemoveFromExclusionList(link)
	local isValid = false
	local _, _, linkName = string.find(link, "(|c%x+|Hitem:[-%d:]+|h%[.-%]|h|r)")
	local id = string.match(link, "item:(%d+):")

	if ((linkName) and (id)) then 
		-- item passed in is a link
		local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture = GetItemInfo(id)
		if (itemName) then 
			local numberId = tonumber(id)
			if (self.db.profile.exclusionList[numberId]) then
				-- item is in the exclusion list				
				isValid = true
			else
				HeadCount:LogWarning(string.format(L["error.exclude.missing"], HeadCount.TITLE, HeadCount.VERSION, itemLink))				
			end
		end
	end	
	
	return isValid
end

function HeadCount:DisplayExclusionList() 
	local numberOfExcludedItems = 0

	for k,v in pairs(self.db.profile.exclusionList) do
		local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture = GetItemInfo(k)
		if (itemLink) then
			HeadCount:LogInformation(string.format(L["info.exclude.loot"], HeadCount.TITLE, HeadCount.VERSION, itemLink, k))
		else
			HeadCount:LogInformation(string.format(L["info.exclude.loot"], HeadCount.TITLE, HeadCount.VERSION, L["Item unavailable"], k))
		end
		
		numberOfExcludedItems = numberOfExcludedItems + 1
	end

	HeadCount:LogInformation(string.format(L["info.exclude.loot.title"], HeadCount.TITLE, HeadCount.VERSION, numberOfExcludedItems))
end


