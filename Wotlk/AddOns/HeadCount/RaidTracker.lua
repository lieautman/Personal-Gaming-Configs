--[[
Project name: HeadCount
Developed by: seppyk
Website: http://www.wowace.com/projects/head-count/
Description: Manages tracking of raid attendance and more.
License: All Rights Reserved unless otherwise explicitly stated. 
File: RaidTracker.lua
File description: Tracks raids.
]]

local AceOO = AceLibrary("AceOO-2.0")
local L = AceLibrary("AceLocale-2.2"):new("HeadCount")
local HeadCount = HeadCount

HeadCount.RaidTracker = AceOO.Class()

-- Current session variables
HeadCount.RaidTracker.prototype.isEnabled = nil						-- true if the raid tracker is enabled, false otherwise
HeadCount.RaidTracker.prototype.isCurrentRaidActive = nil			-- true if the current raid is active, false otherwise
HeadCount.RaidTracker.prototype.isWaitlistAcceptanceEnabled = nil	-- true if the wait list acceptance is enabled current raid is active, false otherwise
HeadCount.RaidTracker.prototype.currentBossEvent = nil				-- the current boss encounter or nil if no boss encounter is active
HeadCount.RaidTracker.prototype.messageHandler = nil				-- the raid's message handler

-- Saved variables
HeadCount.RaidTracker.prototype.raidListWrapper = nil		-- the raid list wrapper

function HeadCount.RaidTracker.prototype:init(raidListWrapper)
    HeadCount.RaidTracker.super.prototype.init(self)
	
	self.isEnabled = true
	self.isCurrentRaidActive = false 
	self.currentBossEvent = AceLibrary("HeadCountBossEvent-1.0"):new()	-- initialize the boss event
	
	if (raidListWrapper) then 
		self.raidListWrapper = raidListWrapper 
	else
		self.raidListWrapper = AceLibrary("HeadCountRaidListWrapper-1.0"):new({ ["raidList"] = { }, ["numberOfRaids"] = 0 })	-- create an online player, starting in no list
	end
	
	self.messageHandler = AceLibrary("HeadCountMessageHandler-1.0"):new()	
end

-- Saves the raid list to the db profile
function HeadCount.RaidTracker.prototype:saveRaidListWrapper() 
	HeadCount:SetRaidListWrapper(self.raidListWrapper)
end

-- Process recovery for the raid tracker
function HeadCount.RaidTracker.prototype:recover() 
	local raid = self:retrieveMostRecentRaid() 	
	if (raid) then 
		local isRaidFinalized = raid:getIsFinalized() 
		local isUnitInRaid = UnitInRaid("player")	
		
		local utcDateTimeInSeconds = HeadCount:getUTCDateTimeInSeconds()
		local activityTime = AceLibrary("HeadCountTime-1.0"):new({ ["utcDateTimeInSeconds"] = utcDateTimeInSeconds })
		
		if (isUnitInRaid) then 
			-- owner is present in raid
			if (isRaidFinalized) then 
				-- most recent raid is finalized
				HeadCount:LogDebug(string.format(L["debug.raidtracker.setup.raid.final"], HeadCount.TITLE, HeadCount.VERSION))
				self.isCurrentRaidActive = false				
			else
				-- most recent raid is NOT finalized
				HeadCount:LogDebug(string.format(L["debug.raidtracker.setup.raid.nofinal"], HeadCount.TITLE, HeadCount.VERSION))
				raid:recover(activityTime)
				
				-- Set proper events and flags for recovered raid
				self:beginRaid()
			end
		else
			-- owner is NOT present in raid
			if (isRaidFinalized) then 
				-- most recent raid is finalized
				HeadCount:LogDebug(string.format(L["debug.raidtracker.setup.noraid.final"], HeadCount.TITLE, HeadCount.VERSION))
				self.isCurrentRaidActive = false							
			else
				-- most recent raid is NOT finalized
				HeadCount:LogDebug(string.format(L["debug.raidtracker.setup.noraid.nofinal"], HeadCount.TITLE, HeadCount.VERSION))
				self:endRaid()
				raid:finalize(activityTime)
				self.isCurrentRaidActive = false						
			end		
		end		
	else
		--HeadCount:LogInformation("The most recent raid does not exist.")
	end	
end

-- Processes beginning of a raid.
function HeadCount.RaidTracker.prototype:beginRaid() 
	self:setIsCurrentRaidActive(true)						-- current raid is active
	
	local waitlistDuration = HeadCount:GetWaitlistDuration()
	if (waitlistDuration > 0) then 
		self:SetWaitlistAcceptanceEnabled(false)
	else
		self:SetWaitlistAcceptanceEnabled(true)
	end	

	HeadCount:addChatEvent("CHAT_MSG_WHISPER", HeadCount.CHAT_MSG_WHISPER_FILTER)			-- enable received whisper event tracking
	HeadCount:addChatEvent("CHAT_MSG_WHISPER_INFORM", HeadCount.CHAT_MSG_WHISPER_INFORM_FILTER)	-- enable sent whisper event tracking
	HeadCount:addEvent("CHAT_MSG_WHISPER")
	HeadCount:addEvent("PLAYER_REGEN_DISABLED")				-- enable being added to combat event tracking for boss kill processing
	HeadCount:removeEvent("PLAYER_REGEN_ENABLED")			-- disable being removed from combat event tracking
	HeadCount:removeEvent("COMBAT_LOG_EVENT_UNFILTERED")	-- disable combat log event tracking
	HeadCount:removeEvent("CHAT_MSG_MONSTER_YELL")			-- disable monster yell events
end

-- Processes ending of a raid.
function HeadCount.RaidTracker.prototype:endRaid() 
	self:setIsCurrentRaidActive(false)						-- current raid is inactive
	self:SetWaitlistAcceptanceEnabled(false)				-- waitlist acceptance is disabled

	HeadCount:removeChatEvent("CHAT_MSG_WHISPER", HeadCount.CHAT_MSG_WHISPER_FILTER)			-- enable received whisper event tracking
	HeadCount:removeChatEvent("CHAT_MSG_WHISPER_INFORM", HeadCount.CHAT_MSG_WHISPER_INFORM_FILTER)	-- enable sent whisper event tracking
	HeadCount:removeEvent("CHAT_MSG_WHISPER")
	HeadCount:removeEvent("PLAYER_REGEN_DISABLED")		
	HeadCount:removeEvent("PLAYER_REGEN_ENABLED")		
	HeadCount:removeEvent("COMBAT_LOG_EVENT_UNFILTERED")
	HeadCount:removeEvent("CHAT_MSG_MONSTER_YELL")
	
	self.currentBossEvent:endEvent()	
end

-- Determines if there is an active raid.
-- @return boolean Returns true if there is an active raid, and false otherwise.
function HeadCount.RaidTracker.prototype:isRaidActive()
	local isActive = false

	local numberOfRaids = self.raidListWrapper:getNumberOfRaids()
	if ((self.isCurrentRaidActive) and (numberOfRaids > 0)) then
		-- raids exist and there is a current raid active
		isActive = true
	end	
	
	return isActive
end

-- Ends the current active raid if it exists
-- @param activityTime The activity time.
-- @return boolean Returns true if the current raid was ended and false otherwise.
function HeadCount.RaidTracker.prototype:endCurrentRaid(activityTime)
	local isCurrentRaidEnded = false
	
	if ((activityTime) and (self.isCurrentRaidActive)) then
		-- end the currently active raid
		local currentRaid = self:retrieveMostRecentRaid()
	
		if (currentRaid) then	
			-- No raid is active, kill all boss tracking events
			self:endRaid()
				
			-- finalize the current raid
			currentRaid:finalize(activityTime)	

			isCurrentRaidEnded = true
		end
	end
	
	return isCurrentRaidEnded
end

-- Remove a raid.
-- @param id The raid id.
-- @return
-- @return boolean Returns true if the raid was successfully removed and false otherwise.
-- @return boolean Returns true if the current raid was ended and false otherwise.
function HeadCount.RaidTracker.prototype:removeRaid(id)
	local isRaidRemoved = false
	local isCurrentRaidEnded = false

	local isPresent = self.raidListWrapper:isRaidPresent(id)

	if (isPresent) then 
		-- raid is present and raid
		local raid = self.raidListWrapper:getRaidById(id)
		if ((not raid:getIsFinalized()) and (self.isCurrentRaidActive)) then		
			-- raid is not finalized, raid is active
			self:endRaid()
			
			isCurrentRaidEnded = true
		end
		
		self.raidListWrapper:removeRaid(id)
		
		isRaidRemoved = true
	end
	
	return isRaidRemoved, isCurrentRaidEnded
end

-- Remove all raids.
function HeadCount.RaidTracker.prototype:removeAllRaids() 
	-- No raid is active, kill all boss tracking events
	self:endRaid()	
	self.raidListWrapper:removeAll()
end

-- Removes a player from a given raid.
-- @param id The raid id.
-- @param playerName The player name.
function HeadCount.RaidTracker.prototype:removePlayer(id, playerName)
	local raid = self.raidListWrapper:getRaidById(id) 	
	if (raid) then
		-- raid exists
		raid:removePlayer(playerName)
	end
end

-- Removes a player's wait list status.
-- @param id The raid id.
-- @param playerName The player name.
function HeadCount.RaidTracker.prototype:removeWaitlistPlayer(id, playerName)
	local raid = self.raidListWrapper:getRaidById(id) 	
	if (raid) then
		-- raid exists
		raid:removeWaitlistPlayer(playerName)
	end
end

-- Removes a boss from a given raid.
-- @param id The raid id.
-- @param bossName The boss name.
function HeadCount.RaidTracker.prototype:removeBoss(id, bossName)
	local raid = self.raidListWrapper:getRaidById(id)
	if (raid) then 
		-- raid exist
		raid:removeBoss(bossName)
	end
end

-- Removes an event attendee.
-- @param raidId The raid id.
-- @param bossName The boss name.
-- @param attendeeId The attendee id.
function HeadCount.RaidTracker.prototype:removeEventAttendee(raidId, bossName, attendeeId)
	local raid = self.raidListWrapper:getRaidById(raidId)
	if (raid) then 
		-- raid exists
		raid:removeEventAttendee(bossName, attendeeId)
	end	
end

-- Removes loot from a given raid.
-- @param raidId The raid id.
-- @param lootId The loot id.
function HeadCount.RaidTracker.prototype:removeLoot(raidId, lootId) 
	local raid = self.raidListWrapper:getRaidById(raidId)
	if (raid) then 
		-- raid exists
		raid:removeLoot(lootId)
	end
end

-- Gets the current enabled status
-- @return boolean Return true if the raid tracker is enabled and false otherwise
function HeadCount.RaidTracker.prototype:getIsEnabled()
	return self.isEnabled
end

-- Sets the current enabled status
-- @param isEnabled The raid tracker enabled status
function HeadCount.RaidTracker.prototype:setIsEnabled(isEnabled)
	self.isEnabled = isEnabled
end

-- Gets the current active raid status
-- @return boolean Returns true if the current raid is active, false otherwise.
function HeadCount.RaidTracker.prototype:getIsCurrentRaidActive()
	return self.isCurrentRaidActive
end

-- Sets the current active raid status
-- @param isCurrentRaidActive The current active raid status
function HeadCount.RaidTracker.prototype:setIsCurrentRaidActive(isCurrentRaidActive) 
	self.isCurrentRaidActive = isCurrentRaidActive
end

-- Gets the waitlist acceptance status.
-- @return boolean Returns true if waitlist acceptance is enabled and false otherwise.
function HeadCount.RaidTracker.prototype:IsWaitlistAcceptanceEnabled()
	return self.isWaitlistAcceptanceEnabled
end

-- Sets the waitlist acceptance status.
-- @param isWaitlistAcceptanceEnabled The waitlist acceptance status.
function HeadCount.RaidTracker.prototype:SetWaitlistAcceptanceEnabled(isWaitlistAcceptanceEnabled)
	self.isWaitlistAcceptanceEnabled = isWaitlistAcceptanceEnabled
end

-- Retrieves the most recent raid.
-- @return object Returns the most recently added raid or nil if none exists.
function HeadCount.RaidTracker.prototype:retrieveMostRecentRaid() 	
	local raid = self.raidListWrapper:retrieveMostRecentRaid()
	
	return raid
end

-- Retrieves the current raid id.
-- @return number Returns the current raid id
function HeadCount.RaidTracker.prototype:retrieveCurrentRaidId()
	local raidId = self.raidListWrapper:retrieveMostRecentRaidId()

	return raidId
end

-- Retrieves the ordered raid list.
-- @return table Returns the ordered raid list
function HeadCount.RaidTracker.prototype:retrieveOrderedRaidList(isDescending)	 
	local orderedRaidList = self.raidListWrapper:retrieveOrderedRaidList(isDescending) 
	
	return orderedRaidList
end

-- Sets the current raid
-- @param raid The current raid.
function HeadCount.RaidTracker.prototype:addRaid(raid) 
	local raidStartTime = raid:retrieveStartingTime():getUTCDateTimeInSeconds()
	self.raidListWrapper:addRaid(raidStartTime, raid)
end

-- Gets the number of raids
-- @return number Returns the number of raids
function HeadCount.RaidTracker.prototype:getNumberOfRaids()
	return self.raidListWrapper:getNumberOfRaids()
end

-- Gets the raid list wrapper.
-- @return object Returns the raid list wrapper.
function HeadCount.RaidTracker.prototype:getRaidListWrapper()
	return self.raidListWrapper
end

-- Gets a given raid by its id.
-- @param id The raid id.
-- @return object Returns the given raid or nil if none exists.
function HeadCount.RaidTracker.prototype:getRaidById(id) 
	assert(type(id) == "number", "Unable get raid by id because the id is not a number.")
	
	return self.raidListWrapper:getRaidById(id)
end

-- Retrieve the current active raid or creates a new raid if no current raid exists.
-- @param activityTime The activity time.
-- @return object Returns the current raid.
function HeadCount.RaidTracker.prototype:retrieveCurrentRaid(activityTime) 
	local currentRaid = nil
	local isNewRaid = false
	
	if (self.isCurrentRaidActive) then
		-- a raid currently exists, process existing raid
		currentRaid = self:retrieveMostRecentRaid()
		isNewRaid = false		
	else
		-- a raid does not already exist, create a new raid, then process it
		local args = {
			["playerList"] = {
				["raidgroup"] = { }, 
				["nogroup"] = { }, 
			}, 
			["bossList"] = { }, 
			["lootList"] = { }, 
			["timeList"] = { }, 
			["difficulty"] = nil, 
			["raidTime"] = 0, 
			["lastActivityTime"] = activityTime, 
			["zone"] = nil, 
			["numberOfPlayers"] = 0, 
			["numberOfBosses"] = 0, 
			["isFinalized"] = false
		}

		local timePair = AceLibrary("HeadCountTimePair-1.0"):new({ ["beginTime"] = nil, ["endTime"] = nil, ["note"] = nil })			
		timePair:setBeginTime(activityTime)
		table.insert(args["timeList"], timePair)	-- insert the first time pair (includes begin time with no end time)		
		
		currentRaid = AceLibrary("HeadCountRaid-1.0"):new(args)			
		self:addRaid(currentRaid)
		isNewRaid = true
		HeadCount:LogInformation(string.format(L["info.newraid"], HeadCount.TITLE, HeadCount.VERSION, HeadCount:getDateTimeAsString(currentRaid:getLastActivityTime())))			
		
		-- Set proper events and flags for new raid
		self:beginRaid()
	end
	
	return currentRaid, isNewRaid 
end

-- Process the current tracking status
-- @param zone The zone name.
function HeadCount.RaidTracker.prototype:processStatus(zone)
	assert(zone, "Unable to determine battleground status because the zone is nil.")
	
	if ((not HeadCount:IsBattlegroundTrackingEnabled()) and (HeadCount:isBattlegroundZone(zone))) then 	
		-- battleground tracking is disabled and current zone is a battleground
		if (self.isEnabled) then 
			HeadCount:LogDebug(string.format(L["debug.status.battleground.enter"], HeadCount.TITLE, HeadCount.VERSION, zone))
			self.isEnabled = false
		end		
	else
		-- battleground tracking is enabled or zone is not a battleground
		if (not self.isEnabled) then 		
			HeadCount:LogDebug(string.format(L["debug.status.battleground.leave"], HeadCount.TITLE, HeadCount.VERSION))
			
			--[[
			local inInstance, instanceType = IsInInstance()	
			HeadCount:LogDebug("Zone: " .. zone)
			if (inInstance) then
				HeadCount:LogDebug("In instance: true")
			else
				HeadCount:LogDebug("In instance: false")
			end
		
			if (instanceType) then 
				HeadCount:LogDebug("Instance type: " .. instanceType)
			end
			--]]
			
			self.isEnabled = true
		end		
	end
end

-- Process a zone change.
-- @return string Returns the current zone name
function HeadCount.RaidTracker.prototype:processZoneChange() 
	local zone = GetRealZoneText() 

	-- update the status
	self:processStatus(zone)
	
	if (self.isEnabled) then
		-- check if the current zone is a valid raid instance zone
		self:processAutomaticGroupSelection(zone)	-- process automatic group selection if applicable				
		self:processRaidZone(zone)					-- process the zone
		self:processDifficulty()					-- process the instance difficulty
	end
	
	return zone
end

-- Processes automatic group selection
-- Automatic group selection will only process if automatic group selection is enabled and the raid is supported
-- @param zone The zone name.
function HeadCount.RaidTracker.prototype:processAutomaticGroupSelection(zone) 
	local isAutomaticGroupSelectionEnabled = HeadCount:IsAutomaticGroupSelectionEnabled()
	
	if ((HeadCount:isRaidInstance()) and (self.isCurrentRaidActive) and (isAutomaticGroupSelectionEnabled)) then
		local difficulty = HeadCount:determineDifficulty()		
		local instance = HeadCount.INSTANCES[zone]
		if ((instance) and (difficulty)) then 
			-- zone is a support instance with known difficulty
			
			-- determine number of players
			local numberOfPlayers = instance.players[difficulty] or HeadCount.NUMBER_OF_HEROIC_PLAYERS
			
			HeadCount:LogDebug(string.format(L["debug.raid.automaticgroupselection.change"], HeadCount.TITLE, HeadCount.VERSION, instance.name, numberOfPlayers))
			
			local numberOfRaidGroups = numberOfPlayers / HeadCount.NUMBER_OF_PARTY_PLAYERS
			for i = 1, HeadCount.NUMBER_OF_PARTY_GROUPS do
				-- 10 / 5 = 2,  20 / 5 = 4,  25 / 5 = 5, 40 / 5 = 8
				local partyGroupString = string.format("%d", i)
				
				if (i <= numberOfRaidGroups) then 
					HeadCount:SetRaidListGroups(partyGroupString, true)
				else
					HeadCount:SetWaitListGroups(partyGroupString, true) 
				end
			end
		end
	end
end

-- Processes the current raid zone.
-- If the current raid has no raid zone assigned to it, set the raid zone name.
-- @param zone The zone name.
function HeadCount.RaidTracker.prototype:processRaidZone(zone)
	if ((HeadCount:isRaidInstance()) and (self.isCurrentRaidActive)) then
		-- player is in a raid instance and a tracked raid is active
		local currentRaid = self:retrieveMostRecentRaid()
		if (not currentRaid:getZone()) then
			-- current raid zone is not set
			if (HeadCount.INSTANCES[zone]) then
				local localizedZoneName = HeadCount.INSTANCES[zone].name	-- get the name
				currentRaid:setZone(localizedZoneName)
				self:saveRaidListWrapper()	-- save the raid list
			end 
		end
	end
end

-- Processes the difficulty
function HeadCount.RaidTracker.prototype:processDifficulty()
	if ((HeadCount:isRaidInstance()) and (self.isCurrentRaidActive)) then
		-- player is in a raid instance and a tracked raid is active
		local currentRaid = self:retrieveMostRecentRaid()
		if (not currentRaid:getDifficulty()) then
			-- current raid difficulty is not set
			local difficulty = HeadCount:determineDifficulty()
			if (difficulty) then
				-- difficulty is returned
				local difficultyString = HeadCount.INSTANCE_DIFFICULTY[difficulty]
				HeadCount:LogDebug(string.format(L["debug.raid.update.difficulty"], HeadCount.TITLE, HeadCount.VERSION, difficultyString))
				currentRaid:setDifficulty(difficulty)
				self:saveRaidListWrapper()	-- save the raid list
			end
		end
	end
end

-- Processing a loot update. 
-- LOOT_ITEM: %s receives loot: %s.
-- LOOT_ITEM_MULTIPLE: %s receives loot: %sx%d.
-- LOOT_ITEM_SELF: You receive loot: %s.
-- LOOT_ITEM_SELF_MULTIPLE: You receive loot: %sx%d.
-- @param message The loot message.
-- @return boolean Returns true if a boss kill or loot was successfully processed and false otherwise.
function HeadCount.RaidTracker.prototype:processLootUpdate(message) 
	local isProcessed = false

	if (self.isCurrentRaidActive) then 
		-- current raid is active
		local playerName, item, quantity = self:processLootPattern(message) 
		if (playerName) then 
			-- message matched proper loot pattern 
			local utcDateTimeInSeconds = HeadCount:getUTCDateTimeInSeconds()
			local activityTime = AceLibrary("HeadCountTime-1.0"):new({ ["utcDateTimeInSeconds"] = utcDateTimeInSeconds })	

			-- Process the loot source if it is a new boss encounter
			local isBoss, lootSource = self:processLootSource()
			local encounterName = HeadCount:retrieveBossEncounterName(lootSource)								
			
			local isBossKillProcessed = false
			if (isBoss) then
				-- loot source is valid and is a raid boss, process it for possible boss kill
				local zone = GetRealZoneText()
				local difficulty = HeadCount:determineDifficulty()
				isBossKillProcessed = self:addBossKill(encounterName, zone, difficulty, activityTime)	
			end
			
			-- Process the loot
			local isLootProcessed = self:processLoot(playerName, item, quantity, activityTime, encounterName)
			
			isProcessed = (isBossKillProcessed or isLootProcessed)
		end
	end
	
	return isProcessed
end

-- Process the loot source
-- @return isBoss Returns if the loot source is a boss
-- @return lootSource Returns the loot source (mob name)
function HeadCount.RaidTracker.prototype:processLootSource()
	local isBoss = false
	local lootSource = HeadCount.DEFAULT_LOOT_SOURCE

	local numberOfRaidMembers = GetNumRaidMembers()
	for i = 1, numberOfRaidMembers do
		-- Raid target
		local unit = "raid" .. i .. "target"
		if (self:isBossUnitDead(unit)) then
			isBoss = true
			lootSource = UnitName(unit)
			break
		end			
	end		
	
	return isBoss, lootSource
end

-- Processing a loot
-- @param playerName The player name.
-- @param item The item string
-- @param quantity The loot quantity
-- @param activityTime The activity time.
-- @param source The loot source
-- @return boolean Returns true if loot was processed and false otherwise
function HeadCount.RaidTracker.prototype:processLoot(playerName, item, quantity, activityTime, source)
	local isProcessed = false
	local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture = GetItemInfo(item) 
	
	local minimumLootQuality = L.itemQualityNumbers[HeadCount:GetMinimumLootQuality()] 
	local id = string.match(itemLink, "item:(%d+):")
	local numberId = tonumber(id)
	local exclusionList = HeadCount:GetExclusionList()
	if ((itemRarity >= minimumLootQuality) and (not exclusionList[numberId])) then 
		-- item dropped is greater than or equal to minimum loot quality and the item is not excluded, track it!  
		local realZoneText = GetRealZoneText()
		
		local itemId = AceLibrary("HeadCountLoot-1.0"):retrieveItemId(itemLink)	-- get the item id
		local loot = AceLibrary("HeadCountLoot-1.0"):new({ ["itemId"] = itemId, ["playerName"] = playerName, ["cost"] = 0, ["activityTime"] = activityTime, ["quantity"] = quantity, ["zone"] = realZoneText, ["source"] = source, ["note"] = nil, })
		local currentRaid = self:retrieveMostRecentRaid()
		
		-- Add this loot to the raid
		currentRaid:addLoot(loot)				
		
		-- Should we broadcast this loot to guild chat?
		if (HeadCount:IsLootBroadcastEnabled()) then
			-- player is in a guild and loot broadcasting is enabled, broadcast to the guild!
			local channel = HeadCount:GetBroadcastChannel()
			HeadCount:SendMessage(string.format(L["guild.broadcast.loot"], playerName, itemLink, source), channel)
		end

		-- Should the loot management popup window show?
		if (HeadCount:IsLootPopupEnabled()) then
			-- loot popup window should show			
			local raidId = currentRaid:retrieveStartingTime():getUTCDateTimeInSeconds()
			local lootId = currentRaid:numberOfLoots()
			HeadCount:HeadCountFrameLootManagementPopup_Show(raidId, lootId)
		end
		
		isProcessed = true
	end
	
	return isProcessed
end

-- Processes a loot message pattern
-- @param message The loot message.
-- @return string, string, number  Returns the player name, item name, and quantity or nil if the message does not match any pattern
function HeadCount.RaidTracker.prototype:processLootPattern(message) 
	local playerName = nil
	local item = nil
	local quantity = nil
	
	local multipleLootSelfRegex = HeadCount:getMULTIPLE_LOOT_SELF_REGEX()
	local lootSelfRegex = HeadCount:getLOOT_SELF_REGEX()
	local multipleLootRegex = HeadCount:getMULTIPLE_LOOT_REGEX() 
	local lootRegex = HeadCount:getLOOT_REGEX() 	
	
	if (message:match(multipleLootSelfRegex)) then 
		item, quantity = message:match(multipleLootSelfRegex) 
		playerName = UnitName("player") 
		--HeadCount:LogInformation("MULTIPLE SELF LOOT: " .. playerName .. " received loot " .. item .. "x" .. quantity)
	elseif (message:match(lootSelfRegex)) then 
		item = message:match(lootSelfRegex) 
		playerName = UnitName("player") 
		quantity = 1
		--HeadCount:LogInformation("SELF LOOT: " .. playerName .. " received loot " .. item)		
	elseif (message:match(multipleLootRegex)) then 
		playerName, item, quantity = message:match(multipleLootRegex) 
		--HeadCount:LogInformation("MULTIPLE LOOT: " .. playerName .. " received loot " .. item .. "x" .. quantity)
	elseif (message:match(lootRegex)) then 
		playerName, item = message:match(lootRegex) 
		quantity = 1
		--HeadCount:LogInformation("LOOT: " .. playerName .. " received loot " .. item) 		
	else
		--HeadCount:LogInformation("The loot message did not match any pattern.")
	end	
	
	return playerName, item, quantity
end

-- Add a boss kill.
-- @param encounterName The boss encounter name.
-- @param zone The zone name.
-- @param activityTime The boss kill time.
-- @return boolean Returns true if a boss kill was processed and false otherwise
function HeadCount.RaidTracker.prototype:addBossKill(encounterName, zone, difficulty, activityTime)	
	local isProcessed = false
	local currentRaid = self:retrieveMostRecentRaid()
	if (not currentRaid:isBossPresent(encounterName)) then
		HeadCount:LogDebug(string.format(L["debug.boss.kill.complete"], HeadCount.TITLE, HeadCount.VERSION, encounterName))		
						
		self:processAttendance(activityTime)	-- update attendance
	
		local raidMemberSort = HeadCount:getRAID_MEMBER_SORT()	
		local playerList = currentRaid:retrieveOrderedPlayerList("Name", HeadCount:IsBossRaidListGroupEnabled(), HeadCount:IsBossWaitListGroupEnabled(), HeadCount:IsBossNoListGroupEnabled(), HeadCount:IsBossWaitListEnabled(), true, true)
		
		local args = {
			["name"] = encounterName, 
			["zone"] = zone, 
			["difficulty"] = difficulty, 
			["activityTime"] = activityTime, 
			["playerList"] = playerList
		}
			
		local boss = AceLibrary("HeadCountBoss-1.0"):new(args)									
			
		currentRaid:addBoss(boss)

		-- Should we broadcast this to guild chat?
		if (HeadCount:IsBossBroadcastEnabled()) then
			-- boss kill broadcasting is enabled
			local channel = HeadCount:GetBroadcastChannel()
			HeadCount:SendMessage(string.format(L["guild.broadcast.bosskill"], encounterName), channel)
		end
		
		isProcessed = true
	end
	
	return isProcessed
end

-- Determines if the given unit is dead and a boss.
-- @param unit The unit.
-- @return boolean Returns true if the unit is a dead boss and false otherwise.
function HeadCount.RaidTracker.prototype:isBossUnitDead(unit)
	local isValid = false
	
	if (unit) then
		if ((UnitExists(unit)) and (UnitIsDead(unit))) then
			-- unit exists and unit is dead
			local unitName = UnitName(unit)
			if ((UnitClassification(unit) == "worldboss") and (not HeadCount.BOSS_BLACKLIST[unitName])) then
				isValid = true
			elseif (HeadCount.BOSS_WHITELIST[unitName]) then
				isValid = true
			end
		end	
	end
	
	return isValid
end

-------------------------------
-- ATTENDANCE TRACKING
-------------------------------
-- Process an attendance update
-- @param activityTime The current activity time.
function HeadCount.RaidTracker.prototype:processAttendance(activityTime)	
	assert(activityTime, "Unable to update attendance because the activity time is nil.")

	-- Get the current zone
	local zone = GetRealZoneText()
	
	-- update the status
	self:processStatus(zone)
	
	if (self.isEnabled) then 
		-- raid tracking is enabled
		--local utcDateTimeInSeconds = HeadCount:getUTCDateTimeInSeconds()
		--local activityTime = AceLibrary("HeadCountTime-1.0"):new({ ["utcDateTimeInSeconds"] = utcDateTimeInSeconds })
		
		if (UnitInRaid("player")) then 
			-- player is in a raid		
			local currentRaid, isNewRaid = self:retrieveCurrentRaid(activityTime)	-- retrieve the current raid or create a new raid 
			if (isNewRaid) then
				-- new raid
				HeadCount:DisableModalFrame() 	-- disable all modal frames
				
				if (UnitAffectingCombat("player")) then 
					HeadCount:PLAYER_REGEN_DISABLED()	-- call the combat event immediately
				end
			end

			if (not currentRaid:getZone()) then
				-- process automatic group selection if enabled and only if no zone is already defined for this raid
				self:processAutomaticGroupSelection(zone)	
			end
			self:processRaidZone(zone)			-- Assign zone if current raid does not have a zone assigned					
			self:processDifficulty()			-- Assign difficulty is current difficulty is not yet assigned
			
			-- Update each member in the raid group 
			local numberOfRaidMembers = GetNumRaidMembers()
			if (numberOfRaidMembers > 0) then
				-- active in a raid		

				local trackedPlayerList = { } 
				for i = 1,numberOfRaidMembers do
					local name, rank, subgroup, level, className, fileName, zone, isOnline, isDead, role, isML = GetRaidRosterInfo(i)
					
					-- self:debugRosterMember(name, rank, subgroup, level, className, fileName, zone, isOnline, isDead, role, isML)
					if (currentRaid:isPlayerPresent(name)) then 
						-- player is already present in the player list (existing player)
						local player = currentRaid:retrievePlayer(name)
						local timeDifference = HeadCount:computeTimeDifference(activityTime, player:getLastActivityTime())					
						local moveResult
						
						if (isOnline) then
							-- CURRENT: Player is online	
							local isPresentInRaidList = HeadCount:isRaidListGroup(subgroup)					
							local isPresentInWaitList = HeadCount:isWaitListGroup(subgroup)
							
							if (isPresentInRaidList) then
								-- CURRENT: Player is in the raid list.
								moveResult = player:moveToRaidList(activityTime)
								if (moveResult) then 
									currentRaid:moveToRaidGroup(player)
									HeadCount:LogDebug(string.format(L["debug.raid.update.modifymember.raidlist"], HeadCount.TITLE, HeadCount.VERSION, name))
								end
							elseif (isPresentInWaitList) then
								-- CURRENT: Player is in the wait list.
								moveResult = player:moveToWaitList(activityTime)
								if (moveResult) then 
									currentRaid:moveToRaidGroup(player)
									HeadCount:LogDebug(string.format(L["debug.raid.update.modifymember.waitlist"], HeadCount.TITLE, HeadCount.VERSION, name)) 
								end
							else
								moveResult = player:moveToNoList(activityTime, true)
								if (moveResult) then 
									currentRaid:moveToNoGroup(player)
									HeadCount:LogDebug(string.format(L["debug.raid.update.modifymember.nolist"], HeadCount.TITLE, HeadCount.VERSION, name)) 
								end
							end
						else
							-- CURRENT: Player is offline 
							moveResult = player:moveToNoList(activityTime, false)
							if (moveResult) then 							
								currentRaid:moveToNoGroup(player)						
								HeadCount:LogDebug(string.format(L["debug.raid.update.modifymember.offline"], HeadCount.TITLE, HeadCount.VERSION, name))																										
							end
						end
						
						player:updateValues(i, className, fileName)	-- update player values if needed
					else
						-- CREATE NEW PLAYER
						-- player is NOT present in the player list (new player)
						local _, race = UnitRace("raid" .. i)
						local sex = UnitSex("raid" .. i)
						local guild = GetGuildInfo("raid" .. i)
						
						if (0 == level) then 
							level = UnitLevel("raid" .. i)
						end
						
						if (name) then 
							-- protect against phantom players
							local player = self:createPlayer(name, race, guild, sex, level, className, fileName, subgroup, isOnline, activityTime)			
							currentRaid:addPlayer(player)	-- add the player to the raid player list						
						end
					end	-- end raid member is existing present member or new member 
					
					-- track the player
					if (name) then 
						trackedPlayerList[name] = name	
					end
				end	-- end loop through all raid members
				
				-- TODO: Remove/cleanup members that are no longer in the raid.  
				currentRaid:processMissingPlayers(numberOfRaidMembers, trackedPlayerList, activityTime)
				
				-- Update the last activity time for the raid after member processing is fully complete
				currentRaid:setLastActivityTime(activityTime)
				HeadCount:LogDebug(string.format(L["debug.raid.update.continue"], HeadCount.TITLE, HeadCount.VERSION, HeadCount:getDateTimeAsString(activityTime)))
				--HeadCount:LogDebug(string.format(L["debug.raid.update.numberOfRaidMembers"], HeadCount.TITLE, HeadCount.VERSION, currentRaid:getNumberOfPlayers(), HeadCount:getDateTimeAsString(activityTime)))			
			else
				-- no raid active, cleanup any existing raids
				if (self.isCurrentRaidActive) then
					-- current raid is active, end it
					HeadCount:LogDebug(string.format(L["debug.raid.update.activitytime"], HeadCount.TITLE, HeadCount.VERSION, HeadCount:getDateTimeAsString(activityTime))) 					
					self:endCurrentRaid(activityTime)
					HeadCount:LogDebug(string.format(L["debug.raid.update.end"], HeadCount.TITLE, HeadCount.VERSION, HeadCount:getDateTimeAsString(activityTime)))		
				end
			end	-- end determine number of raid members
		else
			-- cleanup any existing raids
			if (self.isCurrentRaidActive) then
				-- current raid is active, end it 
				HeadCount:LogDebug(string.format(L["debug.raid.update.activitytime"], HeadCount.TITLE, HeadCount.VERSION, HeadCount:getDateTimeAsString(activityTime))) 				
				self:endCurrentRaid(activityTime)
				HeadCount:LogDebug(string.format(L["debug.raid.update.end"], HeadCount.TITLE, HeadCount.VERSION, HeadCount:getDateTimeAsString(activityTime)))					
			end
		end -- end determine if mod owner is in a raid or not
		
		HeadCount:SetRaidListWrapper(self.raidListWrapper)	-- save the raid list
	--[[
	else
		if (self.isCurrentRaidActive) then
			-- current raid is active, end it 
			HeadCount:LogDebug(string.format(L["debug.raid.update.activitytime"], HeadCount.TITLE, HeadCount.VERSION, HeadCount:getDateTimeAsString(activityTime))) 				
			self:endCurrentRaid(activityTime)
			HeadCount:LogDebug(string.format(L["debug.raid.update.end"], HeadCount.TITLE, HeadCount.VERSION, HeadCount:getDateTimeAsString(activityTime)))					
		end
	--]]		
	end
end

-- Manage loot updates
-- @param raidId The raid id.
-- @param lootId The loot id.
-- @param playerName The name of the player who looted the item
-- @paam source The loot source
-- @param lootCost The loot cost.
-- @param lootNote The loot note.
function HeadCount.RaidTracker.prototype:lootManagementUpdate(raidId, lootId, playerName, source, lootCost, lootNote)	
	assert(raidId, "Unable to process loot management update because the raidId is not found.")
	assert(lootId, "Unable to process loot management update because the lootId is not found.")
	assert(playerName, "Unable to process loot management update because the player name is nil.")
	assert(source, "Unable to process loot management update because the loot source is nil.")
	assert(type(lootCost) == "number", "Unable to process loot management update because the loot cost is not a number.")
	assert(lootNote, "Unable to process loot management update because the loot note is nil.")
	
	local raid = self:getRaidById(raidId)
	if (raid) then
		local loot = raid:retrieveLoot(lootId)
		if (loot) then
			loot:setPlayerName(playerName)
			loot:setSource(source)
			loot:setCost(lootCost)	
			loot:setNote(lootNote)
			HeadCount:SetRaidListWrapper(self.raidListWrapper)	-- save the raid list	
		else
			error("Unable to process loot management update because the loot could not be found: " .. lootId)
		end
	else
		error("Unable to process loot management update because the raid could not be found: " .. raidId)
	end	
end

-- Creates a player.
-- @param name The name.
-- @param race The race.
-- @param guild The guild name.
-- @param sex The sex.
-- @param level The player level.
-- @param className The localized class name.
-- @param fileName The standard class name.
-- @param subgroup The subgroup.
-- @param isOnline The online status.
-- @param activityTime The activity time.
-- @return object Returns a player or nil if none can be created.
function HeadCount.RaidTracker.prototype:createPlayer(name, race, guild, sex, level, className, fileName, subgroup, isOnline, activityTime) 
	local player = nil
	
	local utcDateTimeInSeconds = HeadCount:getUTCDateTimeInSeconds()	
	local activityTime = AceLibrary("HeadCountTime-1.0"):new({ ["utcDateTimeInSeconds"] = utcDateTimeInSeconds })		

	local timePair = AceLibrary("HeadCountTimePair-1.0"):new({ ["beginTime"] = nil, ["endTime"] = nil, ["note"] = nil })		
	timePair:setBeginTime(activityTime) 
	
	local args = {
		["name"] = name, 
		["className"] = className, 
		["fileName"] = fileName, 
		["race"] = race, 
		["guild"] = guild, 
		["sex"] = sex, 
		["level"] = level, 
		["isPresentInRaidList"] = false, 
		["isPresentInWaitList"] = false, 		
		["isOnline"] = true, 
		["isWaitlisted"] = false, 
		["waitlistActivityTime"] = nil, 
		["waitlistNote"] = nil, 
		["raidListTime"] = 0, 
		["waitListTime"] = 0, 
		["offlineTime"] = 0, 
		["timeList"] = { }, 
		["lastActivityTime"] = activityTime, 
		["isFinalized"] = false	
	}
	
	if (isOnline) then
		-- CURRENT: Player is online
		if (HeadCount:isRaidListGroup(subgroup)) then
			-- CURRENT: Player is in the raid list.
			args["isPresentInRaidList"] = true
			args["isPresentInWaitList"] = false
			args["isOnline"] = true			
			
			timePair:setNote(L["Raid list"])
			table.insert(args["timeList"], timePair)	-- insert the first time pair (includes begin time with no end time)			
			
			player = AceLibrary("HeadCountPlayer-1.0"):new(args)	-- create an online player, starting in the raid list
			HeadCount:LogDebug(string.format(L["debug.raid.update.addmember.raidlist"], HeadCount.TITLE, HeadCount.VERSION, name))
		elseif (HeadCount:isWaitListGroup(subgroup)) then		
			-- CURRENT: Player is in the wait list.
			args["isPresentInRaidList"] = false
			args["isPresentInWaitList"] = true
			args["isWaitlisted"] = true
			args["waitlistActivityTime"] = activityTime
			args["isOnline"] = true			
			
			timePair:setNote(L["Wait list"])
			table.insert(args["timeList"], timePair)	-- insert the first time pair (includes begin time with no end time)			
			
			player = AceLibrary("HeadCountPlayer-1.0"):new(args)	-- create an online player, starting in the wait list
			HeadCount:LogDebug(string.format(L["debug.raid.update.addmember.waitlist"], HeadCount.TITLE, HeadCount.VERSION, name))														
		else
			-- CURRENT: Player is in no list.
			args["isPresentInRaidList"] = false
			args["isPresentInWaitList"] = false
			args["isOnline"] = true			
			
			timePair:setNote(L["No list"])
			table.insert(args["timeList"], timePair)	-- insert the first time pair (includes begin time with no end time)			
			
			player = AceLibrary("HeadCountPlayer-1.0"):new(args)	-- create an online player, starting in no list
			HeadCount:LogDebug(string.format(L["debug.raid.update.addmember.nolist"], HeadCount.TITLE, HeadCount.VERSION, name))
		end
	else
		-- CURRENT: Player is offline
		args["isPresentInRaidList"] = false
		args["isPresentInWaitList"] = false
		args["isOnline"] = false
		
		timePair:setNote(L["Offline"])
		table.insert(args["timeList"], timePair)	-- insert the first time pair (includes begin time with no end time)			
		
		player = AceLibrary("HeadCountPlayer-1.0"):new(args)	-- create an online player, starting in no list
		HeadCount:LogDebug(string.format(L["debug.raid.update.addmember.offline"], HeadCount.TITLE, HeadCount.VERSION, name))
	end
	
	return player
end

----------------------------
-- BOSS KILL TRACKING
----------------------------
-- Process a target change.
-- @param unit The target unit (target, mouseover, focus, etc.)
function HeadCount.RaidTracker.prototype:processTargetChange(unit)
	if ((unit) and (self.isCurrentRaidActive)) then 
		-- TODO: check if unit is boss and if it is dead
		
		-- TODO: check if unit is boss target (chest)
	end
end

-- Determines if a boss is engaged.
-- @return boolean Returns true if boss is engaged and false otherwise
-- @return boolean Returns true if the boss engage check needs to be checked again and false otherwise.
function HeadCount.RaidTracker.prototype:processBossEngagement() 
	local isBossEngaged = false
	local isRecheckNeeded = false
	
	if (self.isCurrentRaidActive) then
		-- only check if boss is engaged if in an active raid
		local bossTable = self:processBossTargets()
		
		if (bossTable) then 			
			for k,v in pairs(bossTable) do
				local guid = v["guid"]
				local isDead = v["isDead"]
				if ((not isDead) and (not self.currentBossEvent:isBossPresent(guid))) then 
					-- boss is engaged, alive and boss is not present in the event tracker, add it!
					HeadCount:LogDebug(string.format(L["debug.boss.engage"], HeadCount.TITLE, HeadCount.VERSION, v["bossName"], guid))
					
					self.currentBossEvent:addBoss(v)	-- add the boss to the boss event
					
					isBossEngaged = true					
				end
			end
			
			if (isBossEngaged) then 
				HeadCount:removeEvent("PLAYER_REGEN_DISABLED")		-- disable player enter combat event
				HeadCount:addEvent("PLAYER_REGEN_ENABLED")			-- enable player leave combat event	
				HeadCount:addEvent("COMBAT_LOG_EVENT_UNFILTERED")	-- add combat log event	
				HeadCount:addEvent("CHAT_MSG_MONSTER_YELL")			-- add monster yell event
			else
				-- boss is not engaged yet
				if (UnitAffectingCombat("player")) then 
					-- recheck for boss engagement
					isRecheckNeeded = true
				end
			end
		end
	else
		-- no raid is active, disable all boss kill tracking events
		self:endRaid()
	end
	
	return isBossEngaged, isRecheckNeeded
end

-- Processes boss targets
-- @return table Returns the boss table.
-- @return number Returns the number of entries in the boss table.
function HeadCount.RaidTracker.prototype:processBossTargets() 
	local bossTable = { }
	local numberOfBosses = 0
	
	-- the current zone
	local zone = GetRealZoneText()
	local difficulty = HeadCount:determineDifficulty()
	local isBoss = false
	local guid = nil
	local bossName = nil
	local isDead = nil
	
	isBoss, guid, bossName, isDead = self:isBossUnit("target")
	if (isBoss) then 
		-- target exists, target is in combat, target is a boss mob for this zone	
		bossTable[guid] = { ["guid"] = guid, ["bossName"] = bossName, ["zone"] = zone, ["isDead"] = isDead, }		
		numberOfBosses = numberOfBosses + 1
	end
	
	isBoss, guid, bossName, isDead = self:isBossUnit("focus")
	if (isBoss) then 
		-- focus exists, focus is in combat, focus is a boss mob for this zone	
		if (not bossTable[guid]) then
			bossTable[guid] = { ["guid"] = guid, ["bossName"] = bossName, ["zone"] = zone, ["isDead"] = isDead, }		
			numberOfBosses = numberOfBosses + 1
		end
	end
	
	local numberOfRaidMembers = GetNumRaidMembers()
	if (numberOfRaidMembers > 0) then 
		for i = 1, numberOfRaidMembers do
			local raidUnit = string.format("%s%d%s", "raid", i, "target")
			
			isBoss, guid, bossName, isDead = self:isBossUnit(raidUnit)
			if (isBoss) then 
				-- raid unit target exists, raid unit target is in combat, raid unit target is a boss mob for this zone
				if (not bossTable[guid]) then
					bossTable[guid] = { ["guid"] = guid, ["bossName"] = bossName, ["zone"] = zone, ["difficulty"] = difficulty, ["status"] = isDead, }		
					numberOfBosses = numberOfBosses + 1
				end
			end			
		end
	end
	
	return bossTable, numberOfBosses
end

-- Determines if the current unit is a valid boss in combat
-- @param unit The target unit
-- @return boolean Returns true if the unit is a valid boss and false otherwise.
-- @return string Returns the guid.
-- @return string Returns the boss name or nil if the unit is not a valid boss.
-- @return boolean Returns if the unit is dead or alive
function HeadCount.RaidTracker.prototype:isBossUnit(unit)
	local isValid = false
	local guid = nil
	local name = nil
	local isDead = nil
	
	if (unit) then
		if (UnitExists(unit)) then
			-- unit exists
			local unitName = UnitName(unit)	
			if (UnitAffectingCombat(unit) and (UnitClassification(unit) == "worldboss") and (not HeadCount.BOSS_BLACKLIST[unitName])) then
				-- boss is in combat, boss is a worldboss, boss is not on the ignore list, boss is not tracked yet
				isValid = true
				guid = self:retrieveGUID(unit)			
				name = unitName
				
				isDead = UnitIsDead(unit)

			elseif (UnitAffectingCombat(unit) and (HeadCount.BOSS_WHITELIST[unitName])) then
				-- boss is in combat, boss is on the whitelist, boss is not tracked yet
				isValid = true
				guid = self:retrieveGUID(unit)			
				name = unitName
				
				isDead = UnitIsDead(unit)
--[[
			else
				if (UnitAffectingCombat(unit) and (UnitName(unit) == "Stonescythe Whelp")) then
					-- boss is in combat, boss is not tracked
					isValid = true
					guid = self:retrieveGUID(unit)
					name = unitName					
					isDead = UnitIsDead(unit)
				end			
--]]					
			end		
		end
	end

	return isValid, guid, name, isDead
end

-- Gets the unit GUID.
-- @param unit The unit.
-- @return string Returns the unit GUID or nil if none exists
function HeadCount.RaidTracker.prototype:retrieveGUID(unit)
	local guid = nil

	if (unit) then 
		guid = UnitGUID(unit)
		if (0 == tonumber(guid, 16)) then
			return
		end
	end
	
	return guid
end

-- Determines if the raid has wiped on a boss
-- @return boolean Returns true if there is a boss wipe and false otherwise
-- @return boolean Returns true if the boss wipe check needs to be checked again and false otherwise.
function HeadCount.RaidTracker.prototype:processBossWipe() 
	local isBossWipe = false
	local isRecheckNeeded = false
	
	if (self.isCurrentRaidActive) then 
		if (self.currentBossEvent:getIsStarted()) then
			-- only check for boss wipe if in an active raid an a boss is engaged
			HeadCount:LogDebug(string.format(L["debug.boss.wipe.check"], HeadCount.TITLE, HeadCount.VERSION))
		
			if not UnitIsFeignDeath("player") then 
				-- get the current target list
				local _, numberOfBosses = self:processBossTargets()
				if (numberOfBosses > 0) then 
					-- alive bosses are engaged by the raid, recheck for wipe!
					isRecheckNeeded = true
				else
					-- no alive bosses are engaged by the raid, it's a wipe!
					-- no boss is engaged
					HeadCount:removeEvent("CHAT_MSG_MONSTER_YELL")			-- disable monster yell events
					HeadCount:removeEvent("COMBAT_LOG_EVENT_UNFILTERED")	-- disable combat log event				
					HeadCount:removeEvent("PLAYER_REGEN_ENABLED")			-- disable player leave combat event
					HeadCount:addEvent("PLAYER_REGEN_DISABLED")				-- enable player enter combat event				

					-- no boss is engaged, raid has wiped
					HeadCount:LogDebug(string.format(L["debug.boss.wipe"], HeadCount.TITLE, HeadCount.VERSION))
					
					-- destroy current boss event
					self.currentBossEvent:endEvent()
					
					isBossWipe = true										
				end
			end
		else
			-- no boss event is currently active, reset to standard event handling
			HeadCount:removeEvent("CHAT_MSG_MONSTER_YELL")			-- disable monster yell events
			HeadCount:removeEvent("COMBAT_LOG_EVENT_UNFILTERED")	-- disable combat log event				
			HeadCount:removeEvent("PLAYER_REGEN_ENABLED")			-- disable player leave combat event
			HeadCount:addEvent("PLAYER_REGEN_DISABLED")				-- enable player enter combat event							
			
			self.currentBossEvent:endEvent()
		end
	else
		-- no raid is active, disable all boss kill tracking events
		self:endRaid()		
	end
	
	return isBossWipe, isRecheckNeeded
end

-- Determines if a boss has died
-- @param guid The mob unit guid.
-- @param mob The mob that has just died.
-- @return boolean Returns true if a boss kill event is complete and false otherwise.
function HeadCount.RaidTracker.prototype:processBossDeath(guid, mob)
	local isBossKillEventProcessed = false

	if (self.isCurrentRaidActive) then 
		if (self.currentBossEvent:getIsStarted()) then	
			if not guid and mob then
				-- try and look up the guid from the mob
				guid = self.currentBossEvent:getBossGUID(mob)
			end
			if not guid then return isBossKillEventProcessed end
			
			local isPresent = self.currentBossEvent:isBossPresent(guid)
			local isAlive = self.currentBossEvent:isBossAlive(guid)
			if ((isPresent) and (isAlive)) then 
				-- boss kill recorded!
				local encounterName = self.currentBossEvent:retrieveEncounterName()
				HeadCount:LogDebug(string.format(L["debug.boss.kill"], HeadCount.TITLE, HeadCount.VERSION, self.currentBossEvent:getBossName(guid), guid))
				self.currentBossEvent:setBossDead(guid)
				
				-- check for any new targets
				self:processBossEngagement()
				if (self.currentBossEvent:isEventComplete()) then
					-- boss event is complete!					
					HeadCount:removeEvent("CHAT_MSG_MONSTER_YELL")			-- disable monster yell events
					HeadCount:removeEvent("COMBAT_LOG_EVENT_UNFILTERED")	-- disable combat log event				
					HeadCount:removeEvent("PLAYER_REGEN_ENABLED")			-- disable player leave combat event
					HeadCount:addEvent("PLAYER_REGEN_DISABLED")				-- enable player enter combat event	

					local utcDateTimeInSeconds = HeadCount:getUTCDateTimeInSeconds()
					local activityTime = AceLibrary("HeadCountTime-1.0"):new({ ["utcDateTimeInSeconds"] = utcDateTimeInSeconds })
					
					local zone = GetRealZoneText()
					local difficulty = HeadCount:determineDifficulty()
					
					local isBossKillProcessed = self:addBossKill(encounterName, zone, difficulty, activityTime)	-- add the boss kill
					if (isBossKillProcessed) then
						isBossKillEventProcessed = true
					end
					
					self.currentBossEvent:endEvent()	
				end		
			end
		else
			-- no boss event is currently active, reset to standard event handling
			HeadCount:removeEvent("CHAT_MSG_MONSTER_YELL")			-- disable monster yell events
			HeadCount:removeEvent("COMBAT_LOG_EVENT_UNFILTERED")	-- disable combat log event				
			HeadCount:removeEvent("PLAYER_REGEN_ENABLED")			-- disable player leave combat event
			HeadCount:addEvent("PLAYER_REGEN_DISABLED")				-- enable player enter combat event							
			
			self.currentBossEvent:endEvent()			
		end
	else
		-- no raid is active, disable all boss kill tracking events
		self:endRaid()			
	end
	
	return isBossKillEventProcessed
end

-- Sets the raid list wrapper.
-- @param raidList The raid list wrapper.
function HeadCount.RaidTracker.prototype:setRaidListWrapper(raidListWrapper)
	self.raidListWrapper = raidListWrapper
end

-- Prunes old raids.
function HeadCount.RaidTracker.prototype:pruneRaids() 
	local isPruningEnabled = HeadCount:IsPruningEnabled() 
	local pruningTimeInWeeks = HeadCount:GetPruningTime()
	
	if (isPruningEnabled) then
		HeadCount:LogDebug(string.format(L["debug.raid.prune.enabled"], HeadCount.TITLE, HeadCount.VERSION, pruningTimeInWeeks))	
		
		self.raidListWrapper:pruneRaids(pruningTimeInWeeks)	-- prune old raids
	else
		HeadCount:LogDebug(string.format(L["debug.raid.prune.disabled"], HeadCount.TITLE, HeadCount.VERSION))	
	end
end

-- Processes an incoming message.
-- @param message The message.
-- @param author The author.
-- @return boolean Returns true if an update is required as a result of the message.
-- @return boolean Returns true if the message is a supported message.
-- @return table Returns the response message list.
function HeadCount.RaidTracker.prototype:processIncomingMessage(message, author) 
	local isUpdateRequired = false
	local isSupportedMessage = false
	local messageList = nil
	
	if (self.isCurrentRaidActive) then 
		-- Only process incoming messages during an active raid
		local raid = self:retrieveCurrentRaid() 
		isUpdateRequired, isSupportedMessage, messageList = self.messageHandler:processIncomingMessage(raid, self.isWaitlistAcceptanceEnabled, message, author)
	end
	
	return isUpdateRequired, isSupportedMessage, messageList
end

-- Determines if an incoming message is supported.
-- @param message The message.
-- @return boolean Returns true if the message is a supported message.
function HeadCount.RaidTracker.prototype:IsSupportedIncomingMessage(message)
	assert(message, "Unable to determine if incoming message is supported because the message is nil.")
	
	local isSupportedMessage = false

	if (self.isCurrentRaidActive) then 
		isSupportedMessage = self.messageHandler:IsSupportedIncomingMessage(message)
	end
	
	return isSupportedMessage
end

-- Determines if an outgoing message is supported.
-- @param message The message.
-- @return boolean Returns true if the message is a supported message.
function HeadCount.RaidTracker.prototype:IsSupportedOutgoingMessage(message) 
	assert(message, "Unable to determine if the outgoing message is supported because the message is nil.")

	local isSupportedMessage = false
	
	if (self.isCurrentRaidActive) then 
		isSupportedMessage = self.messageHandler:IsSupportedOutgoingMessage(message)
	end
	
	return isSupportedMessage
end

function HeadCount.RaidTracker.prototype:processListWaitlist(channel)
	if (self.isCurrentRaidActive) then 
		local raid = self:retrieveCurrentRaid() 
		self.messageHandler:processListWaitlistMessage(raid, channel)
	else
		HeadCount:LogWarning(string.format(L["warning.waitlist.list.currentraid"], HeadCount.TITLE, HeadCount.VERSION))
	end
end
		
-- To String
-- @return string Returns the string description for this object.
function HeadCount.RaidTracker.prototype:ToString()
	return L["object.RaidTracker"]
end
