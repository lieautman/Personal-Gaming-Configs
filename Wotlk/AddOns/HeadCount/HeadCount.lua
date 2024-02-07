--[[
Project name: HeadCount
Developed by: seppyk
Website: http://www.wowace.com/projects/head-count/
Description: Manages tracking of raid attendance and more.
License: All Rights Reserved unless otherwise explicitly stated. 
File: HeadCount.lua
File description: Core  application logic / event handling
]]

local MAJOR_VERSION = "HeadCount-1.0"
local MINOR_VERSION = tonumber(("$Revision: 94 $"):match("%d+"))

if not AceLibrary then error(MAJOR_VERSION .. " requires AceLibrary.") end
if not AceLibrary:IsNewVersion(MAJOR_VERSION, MINOR_VERSION) then return end

local L = AceLibrary("AceLocale-2.2"):new("HeadCount")

HeadCount = AceLibrary("AceAddon-2.0"):new("AceConsole-2.0", "AceEvent-2.0", "AceDB-2.0", "FuBarPlugin-2.0")
local HeadCount = HeadCount

HeadCount:RegisterDB("HeadCountDB", "HeadCountDBPC")

local raidTracker = nil
local whisperData = { }

-- Gets the raid tracker.
-- @return object Returns the raid tracker.
function HeadCount:getRaidTracker() 
	return raidTracker
end

-- Automatically called when the  addon is initialized
function HeadCount:OnInitialize()
	self:RegisterDefaults("profile", self:getDefaultOptions())
	self:RegisterChatCommand(L["console.commands"], self:getOptions())
	self.OnMenuRequest = self:getOptions()	-- fubar options menu
	
	-- Initialize constants
	HeadCount:initializeConstants()
	
	self:LogInformation(string.format(L["info.initialization.complete"], HeadCount.TITLE, HeadCount.VERSION))
	self:LogInformation(string.format(L["product.usage"], HeadCount.TITLE, HeadCount.VERSION)) 
end

-----------------------------------------------------
-- ADDON ENABLED
-----------------------------------------------------
-- Automatically called when the  addon is enabled
function HeadCount:OnEnable()
	self:RegisterSelfEvents()	-- register the main events

	if (raidTracker) then
		raidTracker:recover()		-- process recovery for the raid tracker		
		raidTracker:pruneRaids() 	-- prune old raids if applicable	
		HeadCount:RAID_ROSTER_UPDATE(true)	-- update attendance and the UI immediately
	else
		RequestRaidInfo()
	end
	
	self:LogDebug(string.format(L["debug.mod.enable"], HeadCount.TITLE, HeadCount.VERSION))
	self:SetupBroker()		
end

-- Register self events
function HeadCount:RegisterSelfEvents()
	-- Core events (always enabled)
	HeadCount:addEvent("RAID_ROSTER_UPDATE")
	HeadCount:addEvent("ZONE_CHANGED_NEW_AREA") 
	HeadCount:addEvent("CHAT_MSG_LOOT") 
	HeadCount:addEvent("UPDATE_INSTANCE_INFO")
	HeadCount:addEvent("PLAYER_ENTERING_WORLD")
end

-- Automatically called when the UPDATE_INSTANCE_INFO event is triggered
function HeadCount:UPDATE_INSTANCE_INFO() 
	if (not raidTracker) then
		HeadCount:removeEvent("UPDATE_INSTANCE_INFO")
		
		-- Setup the raid tracker
		local raidListWrapper = HeadCount:GetRaidListWrapper() 	
		raidTracker = self.RaidTracker:new(raidListWrapper)	-- instantiate a new raid tracker 			
		raidTracker:recover()		-- process recovery for the raid tracker		
		raidTracker:pruneRaids() 	-- prune old raids if applicable

		if ((raidTracker:getIsCurrentRaidActive()) and (UnitAffectingCombat("player"))) then 
			-- raid was recovered, continuing raid
			-- player is in combat upon login/reload
			HeadCount:PLAYER_REGEN_DISABLED()	-- call the combat event immediately
		end

		HeadCount:RAID_ROSTER_UPDATE(true)	-- update initial attendance and the UI immediately
	end	
end

-----------------------------------------------------
-- ADDON DISABLED
-----------------------------------------------------
-- Automatically called when the  addon is disabled
function HeadCount:OnDisable()
	HeadCount:RAID_ROSTER_UPDATE(true)	-- update attendance and the UI immediately
	
	self:LogDebug(string.format(L["debug.mod.disable"], HeadCount.TITLE, HeadCount.VERSION))		
end

-----------------------------------------------------
-- LOOT MESSAGE
-----------------------------------------------------
-- Automatically called when the CHAT_MSG_LOOT event is triggered
function HeadCount:CHAT_MSG_LOOT(message) 
	if (raidTracker) then		
		local isProcessed = raidTracker:processLootUpdate(message)
		if (isProcessed) then
			HeadCount:RAID_ROSTER_UPDATE(true)	-- update attendance and the UI immediately	
		end
	end
end

-----------------------------------------------------
-- ZONE CHANGE
-----------------------------------------------------  
-- Automatically called when the PLAYER_ENTERING_WORLD event is triggered
function HeadCount:PLAYER_ENTERING_WORLD() 
	if (raidTracker) then
		local zone = GetRealZoneText()
		raidTracker:processStatus(zone)
	end
end

-- Automatically called when the ZONE_CHANGED_NEW_AREA event is triggered
function HeadCount:ZONE_CHANGED_NEW_AREA() 
	if (raidTracker) then
		raidTracker:processZoneChange() 
		HeadCount:RAID_ROSTER_UPDATE(false)	-- update attendance and the UI
	end
end	

-----------------------------------------------------
-- BOSS KILL
-----------------------------------------------------  
-- Automatically called when the player goes into combat.
function HeadCount:PLAYER_REGEN_DISABLED() 
	if (raidTracker) then 
		local isBossEngaged, isRecheckNeeded = raidTracker:processBossEngagement()	-- player is in combat, check for boss engagement
		if (isRecheckNeeded) then
			-- boss engagement unclear, recheck for boss engagement in 1 second
			HeadCount:ScheduleEvent("PLAYER_REGEN_DISABLED", 1)
		end
	end
end

-- Automatically called when the COMBAT_LOG_EVENT_UNFILTERED event is triggered
function HeadCount:COMBAT_LOG_EVENT_UNFILTERED(timestamp, event, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags)
	if ((raidTracker) and (("UNIT_DIED" == event) or ("PARTY_KILL" == event))) then 
		local isBossKillEventProcessed = raidTracker:processBossDeath(destGUID, destName)	-- something died
		if (isBossKillEventProcessed) then 
			HeadCount:HeadCountFrame_Update()	-- update the UI
		end
	end
end

-- Automatically called when the CHAT_MSG_MONSTER_YELL event is triggered
function HeadCount:CHAT_MSG_MONSTER_YELL(message, sender)
	if ((raidTracker) and (HeadCount.BOSS_END_TRIGGER[sender] == message)) then 
		local isBossKillEventProcessed = raidTracker:processBossDeath(nil, sender)	-- something died
		if (isBossKillEventProcessed) then 
			HeadCount:HeadCountFrame_Update()	-- update the UI
		end
	end
end

-- Automatically called when the player is removed from combat.
function HeadCount:PLAYER_REGEN_ENABLED()
	if (raidTracker) then
		local isBossWipe, isRecheckNeeded = raidTracker:processBossWipe()	-- player is out of combat, check for wipe
		if (isRecheckNeeded) then 
			-- boss wipe unclear, recheck for boss wipe in 2 seconds
			HeadCount:ScheduleEvent("PLAYER_REGEN_ENABLED", 2)		
		end
	end
end

-----------------------------------------------------
-- WHISPERS
-----------------------------------------------------  
-- Automatically called filter when the player receives a whisper
-- Global args are available for the recipient and other information.
-- arg1 - Message received 
-- arg2  - Author 
-- arg3  - Language (or nil if universal, like messages from GM) (always seems to be an empty string; argument may have been kicked because whispering in non-standard language doesn't seem to be possible [any more?]) 
-- arg6  - status (like "DND" or "GM") 
-- arg7 -  (number) message id (for reporting spam purposes?) (default: 0) 
-- arg8 -  (number) unknown (default: 0) 
-- FIXED BY JerryBlade
function HeadCount:CHAT_MSG_WHISPER(message,author, ...)
	if (raidTracker) then
		local isUpdateRequired, isSupportedMessage, messageList = raidTracker:processIncomingMessage(message, author)

		if (isUpdateRequired) then 
			HeadCount:RAID_ROSTER_UPDATE(false)	-- update attendance and the UI
		end
		
		if (isSupportedMessage) then 
			-- waitlist message and author was not self
			-- send back response
			HeadCount:LogDebug(string.format(L["debug.message"], HeadCount.TITLE, HeadCount.VERSION, message, author))
			
			table.insert(whisperData, { ["messages"] = messageList, ["recipient"] = author, })
			
			if (not HeadCount:IsEventScheduled(HeadCount.EVENT_OUTGOING_WHISPER_UPDATE)) then
				HeadCount:ScheduleEvent(HeadCount.EVENT_OUTGOING_WHISPER_UPDATE, HeadCount.OUTGOING_WHISPER_UPDATE, HeadCount.EVENT_OUTGOING_WHISPER_UPDATE_DELAY, self)
			end
			
			local isWaitlistIncomingEnabled = HeadCount:IsWaitlistIncomingEnabled()	
			if (not isWaitlistIncomingEnabled) then 
				-- waitlist incoming message display is disabled
				return true, ...
			end
		end
	end
end

-- Automatically called filter when the player receives a whisper
-- Global args are available for the recipient and other information.
function HeadCount:CHAT_MSG_WHISPER_FILTER(chatFrame,event,...)  
	local arg1 = ...;
	if (raidTracker) then
		local message = arg1
		local isSupportedMessage = raidTracker:IsSupportedIncomingMessage(message)
		
		if (isSupportedMessage) then 
			-- waitlist message and author was not self
			local isWaitlistIncomingEnabled = HeadCount:IsWaitlistIncomingEnabled()	
			if (not isWaitlistIncomingEnabled) then 
				-- waitlist incoming message display is disabled
				return true, ...
			end
		end
	end
end

-- Automatically called filter when the player sends a whisper.
-- Global args are available for the recipient and other information.
function HeadCount:CHAT_MSG_WHISPER_INFORM_FILTER(chatFrame,event,...) 
	local arg1 = ...;
	if (raidTracker) then 
		local message = arg1
		local isSupportedMessage = raidTracker:IsSupportedOutgoingMessage(message)

		local isWaitlistOutgoingEnabled = HeadCount:IsWaitlistOutgoingEnabled()
		if ((isSupportedMessage) and (not isWaitlistOutgoingEnabled)) then 
			-- outgoing message is a waitlist message and outgoing waitlist message display is disabled
			return true, ...
		end
	end
end

-- Automatically called when a waitlist whisper is scheduled for outgoing delivery.
-- HeadCount-specific event.
function HeadCount:OUTGOING_WHISPER_UPDATE() 
	local numberOfMessages = # whisperData
	if (numberOfMessages > 0) then
		local utcDateTimeInSeconds = HeadCount:getUTCDateTimeInSeconds()
		local activityTime = AceLibrary("HeadCountTime-1.0"):new({ ["utcDateTimeInSeconds"] = utcDateTimeInSeconds })	

		-- message is ready to be sent			
		local messages = whisperData[1]["messages"]
		local recipient = whisperData[1]["recipient"]
			
		if ((messages) and (recipient)) then 
			for k,v in ipairs(messages) do
				HeadCount:SendWhisper(v, recipient)
			end

			table.remove(whisperData, 1)
		else 
			table.remove(whisperData, 1)
		end

		local updatedNumberOfMessages = # whisperData
		if (updatedNumberOfMessages > 0) then 
			-- more messages to send
			
			-- cancel any currently scheduled events
			if (HeadCount:IsEventScheduled(HeadCount.EVENT_OUTGOING_WHISPER_UPDATE)) then
				HeadCount:CancelScheduledEvent(HeadCount.EVENT_OUTGOING_WHISPER_UPDATE)
			end		
		
			-- schedule a new event
			if (not HeadCount:IsEventScheduled(HeadCount.EVENT_OUTGOING_WHISPER_UPDATE)) then
				HeadCount:ScheduleEvent(HeadCount.EVENT_OUTGOING_WHISPER_UPDATE, HeadCount.OUTGOING_WHISPER_UPDATE, HeadCount.EVENT_OUTGOING_WHISPER_UPDATE_DELAY, self)
			end		
		else
			HeadCount:LogDebug(string.format(L["debug.whisper.nomessages"], HeadCount.TITLE, HeadCount.VERSION))
		end		
	end
end

-- Announce the wait list
-- @param channel The chat channel.
function HeadCount:announceWaitlist(channel)
    if (raidTracker) then
        if (raidTracker:getIsCurrentRaidActive()) then
			raidTracker:SetWaitlistAcceptanceEnabled(true)

            -- Always cancel the schedule event if one exists
            if (HeadCount:IsEventScheduled(HeadCount.EVENT_WAITLIST_ACCEPTANCE_UPDATE)) then
                HeadCount:CancelScheduledEvent(HeadCount.EVENT_WAITLIST_ACCEPTANCE_UPDATE)
            end
            
            local waitlistDuration = HeadCount:GetWaitlistDuration()
            if (waitlistDuration > 0) then
				local waitlistDurationSeconds = waitlistDuration * 60		-- convert to seconds
                if (not HeadCount:IsEventScheduled(HeadCount.EVENT_WAITLIST_ACCEPTANCE_UPDATE)) then
					HeadCount:ScheduleEvent(HeadCount.EVENT_WAITLIST_ACCEPTANCE_UPDATE, self.WAITLIST_ACCEPTANCE_UPDATE, waitlistDurationSeconds, self, channel)
                end
            end
            
			HeadCount:SendMessage(HeadCount.MESSAGE_PREFIX .. " " .. L["info.announce.waitlist.open"], channel)
        else
			HeadCount:LogWarning(string.format(L["warning.waitlist.announce.currentraid"], HeadCount.TITLE, HeadCount.VERSION))
        end
    end
end

-- Automatically called when the wait list acceptance timer expires
function HeadCount:WAITLIST_ACCEPTANCE_UPDATE(channel)
    if (raidTracker) then
        if (HeadCount:IsEventScheduled(HeadCount.EVENT_WAITLIST_ACCEPTANCE_UPDATE)) then
            HeadCount:CancelScheduledEvent(HeadCount.EVENT_WAITLIST_ACCEPTANCE_UPDATE)
        end
    
        local waitlistDuration = HeadCount:GetWaitlistDuration()
        HeadCount:manageWaitlistChange(duration)

        if (waitlistDuration > 0) then
            -- Display closed message if duration is non-zero
			HeadCount:SendMessage(HeadCount.MESSAGE_PREFIX .. " " .. L["info.announce.waitlist.close"], channel)
        end
    end
end

-- Manages a wait list status change
function HeadCount:manageWaitlistChange(duration)
    if (raidTracker) then
        if (raidTracker:getIsCurrentRaidActive()) then
            -- raid is active
            if (HeadCount:IsEventScheduled(HeadCount.EVENT_WAITLIST_ACCEPTANCE_UPDATE)) then
                if (0 == duration) then
					-- wait list status is enabled since duration is 0
					raidTracker:SetWaitlistAcceptanceEnabled(true)
				end
			else
                -- no wait list event is currently scheduled so it is ok to change the current waitlist status
                if (0 == duration) then
                    -- wait list status is enabled since duration is 0
					raidTracker:SetWaitlistAcceptanceEnabled(true)
                else
                    -- wait list status is enabled                
					raidTracker:SetWaitlistAcceptanceEnabled(false)
                end            
            end
        else
            -- raid is not active
            -- disable the wait list
			raidTracker:SetWaitlistAcceptanceEnabled(false)
        end    
    end
end
-----------------------------------------------------
-- RAID UPDATE
-----------------------------------------------------  
-- Automatically called when the  RAID_ROSTER_UPDATE event is triggered
-- @param isForcedUpdate The forced update status
function HeadCount:RAID_ROSTER_UPDATE(isForcedUpdate)	
	if (raidTracker) then		
		local utcDateTimeInSeconds = HeadCount:getUTCDateTimeInSeconds()
		local activityTime = AceLibrary("HeadCountTime-1.0"):new({ ["utcDateTimeInSeconds"] = utcDateTimeInSeconds })
		
		--HeadCount:LogDebug("Forced update?: " .. HeadCount:convertBooleanToString(booleanValue))
	
		if ((UnitInRaid("player")) and (raidTracker:getIsCurrentRaidActive()) and (not isForcedUpdate)) then
			--HeadCount:LogInformation("Raid is currently active.")
			local raid = raidTracker:retrieveMostRecentRaid() 			
			local lastActivityTime = raid:getLastActivityTime()
			local timeDifference = HeadCount:computeTimeDifference(activityTime, lastActivityTime) 
			local delay = HeadCount:GetDelay()
			
			if (timeDifference >= delay) then
				-- attendance call is valid
				--HeadCount:LogInformation("VALID: Delay (" .. delay .. ") | Time difference (" .. timeDifference .. ")")
				
				if (HeadCount:IsEventScheduled(HeadCount.EVENT_RAID_ROSTER_UPDATE)) then
					--HeadCount:LogInformation("HeadCount_RAID_ROSTER_UPDATE is scheduled, canceling.")
					HeadCount:CancelScheduledEvent(HeadCount.EVENT_RAID_ROSTER_UPDATE)
				end

				--HeadCount:LogInformation("Processing attendance.")
				raidTracker:processAttendance(activityTime)	-- update the attendance
				HeadCount:HeadCountFrame_Update()			-- update the UI											
			else
				-- attendance call is invalid
				--HeadCount:LogInformation("INVALID: Delay (" .. delay .. ") | Time difference (" .. timeDifference .. ")")
				
				if (not HeadCount:IsEventScheduled(HeadCount.EVENT_RAID_ROSTER_UPDATE)) then
					--HeadCount:LogInformation("HeadCount_RAID_ROSTER_UPDATE is not scheduled, scheduling.")
					HeadCount:ScheduleEvent(HeadCount.EVENT_RAID_ROSTER_UPDATE, self.RAID_ROSTER_UPDATE, (delay - timeDifference), self)
				end
			end
		else
			--HeadCount:LogInformation("Raid is currently inactive or a forced raid update is occurring.  Processing attendance.")
			raidTracker:processAttendance(activityTime)	-- update the raid attendance
			HeadCount:HeadCountFrame_Update()			-- update the UI							
		end	
	end
end

-----------------------------------------------------
-- MISCELLANEOUS
-----------------------------------------------------  
-- Ends the current raid
-- @param activityTime The activity time.
function HeadCount:endCurrentRaid(activityTime) 
	if (raidTracker) then
		local isCurrentRaidEnded = raidTracker:endCurrentRaid(activityTime)
		
		if (isCurrentRaidEnded) then 
			if (HeadCount:IsEventScheduled(HeadCount.EVENT_WAITLIST_ACCEPTANCE_UPDATE)) then
				HeadCount:CancelScheduledEvent(HeadCount.EVENT_WAITLIST_ACCEPTANCE_UPDATE)
			end
		end
		
		HeadCount:RAID_ROSTER_UPDATE(true)	-- update attendance and the UI immediately
	end
end

-- Remove a raid.
-- @param raidId The raid id.
function HeadCount:removeRaid(raidId)
	if (raidTracker) then
		local isRaidRemoved, isCurrentRaidEnded = raidTracker:removeRaid(raidId)
		
		if (isCurrentRaidEnded) then 
			if (HeadCount:IsEventScheduled(HeadCount.EVENT_WAITLIST_ACCEPTANCE_UPDATE)) then
				HeadCount:CancelScheduledEvent(HeadCount.EVENT_WAITLIST_ACCEPTANCE_UPDATE)
			end
		end		
		
		HeadCount:RAID_ROSTER_UPDATE(true)	-- update attendance and the UI immediately		
	end
end

-- Remove all raids.
function HeadCount:removeAllRaids() 
	if (raidTracker) then
		raidTracker:removeAllRaids()
		
		if (HeadCount:IsEventScheduled(HeadCount.EVENT_WAITLIST_ACCEPTANCE_UPDATE)) then
			HeadCount:CancelScheduledEvent(HeadCount.EVENT_WAITLIST_ACCEPTANCE_UPDATE)
		end
			
		HeadCount:RAID_ROSTER_UPDATE(true)	-- update attendance and the UI immediately		
	end
end

-- Remove a player from a raid.
-- @param raidId The raid id.
-- @param playerName The player name.
function HeadCount:removePlayer(raidId, playerName) 
	if (raidTracker) then
		raidTracker:removePlayer(raidId, playerName)
		HeadCount:RAID_ROSTER_UPDATE(true)	-- update attendance and the UI immediately		
	end
end

-- Removes the wait list status flag from a player for a given raid.
-- @param raidId The raid id.
-- @param playerName The player name.
function HeadCount:removeWaitlistPlayer(raidId, playerName)
	if (raidTracker) then
		raidTracker:removeWaitlistPlayer(raidId, playerName)
		HeadCount:RAID_ROSTER_UPDATE(true)	-- update attendance and the UI immediately		
	end
end

-- Remove a boss from a raid.
-- @param raidId The raid id.
-- @param bossName The boss name.
function HeadCount:removeBoss(raidId, bossName) 
	if (raidTracker) then
		raidTracker:removeBoss(raidId, bossName)
		HeadCount:RAID_ROSTER_UPDATE(true)	-- update attendance and the UI immediately		
	end
end

-- Removes an event attendee.
-- @param raidId The raid id.
-- @param bossName The boss name.
-- @param attendeeId The attendee id.
function HeadCount:removeEventAttendee(raidId, bossName, attendeeId)
	if (raidTracker) then 
		raidTracker:removeEventAttendee(raidId, bossName, attendeeId)
		HeadCount:RAID_ROSTER_UPDATE(true)	-- update attendance and the UI immediately		
	end
end

-- Remove loot from a raid
-- @param raidId The raid id.
-- @param lootId The loot id.
function HeadCount:removeLoot(raidId, lootId) 
	if (raidTracker) then
		raidTracker:removeLoot(raidId, lootId) 
		HeadCount:RAID_ROSTER_UPDATE(true)	-- update attendance and the UI immediately		
	end
end

-- Loot management update
-- @param raidId The raid id
-- @param lootId The loot id
-- @param playerName The name of the player who looted the item
-- @paam source The loot source
-- @param lootCost The loot cost
-- @param lootNote The loot note.
function HeadCount:lootManagementUpdate(raidId, lootId, playerName, source, lootCost, lootNote)	
	if (raidTracker) then
		raidTracker:lootManagementUpdate(raidId, lootId, playerName, source, lootCost, lootNote)	
		HeadCount:HeadCountFrame_Update()			-- update the UI	
	end
end

-----------------------------------------------------
-- EVENT HANDLING
-----------------------------------------------------  
-- Adds a registered event
-- @param event The event name.
-- @param functionName The function name.
function HeadCount:addEvent(event, functionName) 
	if ((event) and (not HeadCount:IsEventRegistered(event))) then 
		-- event is not registered
		--HeadCount:LogDebug(string.format(L["debug.event.register"], HeadCount.TITLE, HeadCount.VERSION, event))	
		if (functionName) then
			HeadCount:RegisterEvent(event, functionName)
		else
			HeadCount:RegisterEvent(event)
		end
	end
end

-- Removes a registered event.
-- @param event The event name.
function HeadCount:removeEvent(event)
	if ((event) and (HeadCount:IsEventRegistered(event))) then 
		-- event is registered, unregister it
		--HeadCount:LogDebug(string.format(L["debug.event.unregister"], HeadCount.TITLE, HeadCount.VERSION, event))
		HeadCount:UnregisterEvent(event)
	end
end

-- Adds a chat message event filter.
-- @param event The event name.
-- @param functionName The function name.
function HeadCount:addChatEvent(event, functionName)
	if ((event) and (functionName)) then 
		ChatFrame_AddMessageEventFilter(event, functionName)
	end
end

-- Removed a chat message event filter.
-- @param event The event name.
-- @param functionName The function name.
function HeadCount:removeChatEvent(event, functionName)
	if ((event) and (functionName)) then 
		ChatFrame_RemoveMessageEventFilter(event, functionName)
	end
end

-----------------------------------------------------
-- LOGGING
-----------------------------------------------------  
-- Logs a debug message for a roster member
function HeadCount:debugRosterMember(name, rank, subgroup, level, className, fileName, zone, isOnline, isDead, role, isML) 
	local memberString = "[name: %s, rank: %d, subgroup: %d, level: %s, class: %s, fileName: %s, zone: %s, isOnline: %s, isDead: %s, role: %s, isML: %s]"

	local isMemberOnline = HeadCount:convertBooleanToString(isOnline)		
	local isMemberDead = HeadCount:convertBooleanToString(isDead)		
	local isMasterLooter = HeadCount:convertBooleanToString(isML)
	local memberRole
	if (role) then
		memberRole = role
	else
		memberRole = L["None"]
	end
		
	self:LogDebug(string.format(memberString, name, rank, subgroup, level, className, fileName, zone, isMemberOnline, isMemberDead, memberRole, isMasterLooter))	
end

-- Logs a debug message to the default chat frame
-- @param message The message.
-- @red The red color for this message.
-- @green The green color for this message.
-- @blue The blue color for this message.
function HeadCount:LogDebug(message, red, green, blue)
	if (self.db.profile.isDebugEnabled) then
		DEFAULT_CHAT_FRAME:AddMessage(message, red, green, blue)
	end
end

-- Logs a information message to the default chat frame
-- @param message The message.
-- @red The red color for this message.
-- @green The green color for this message.
-- @blue The blue color for this message.
function HeadCount:LogInformation(message, red, green, blue)
	DEFAULT_CHAT_FRAME:AddMessage(message, red, green, blue)
end

-- Logs a information message to the default chat frame with default colors
-- @param message The message.
function HeadCount:LogInformation(message)
	DEFAULT_CHAT_FRAME:AddMessage(message, 1.0, 1.0, 1.0)
end

-- Logs a warning message to the default chat frame with default colors
-- @param message The message.
function HeadCount:LogWarning(message)
	DEFAULT_CHAT_FRAME:AddMessage(message, 1.0, 1.0, 1.0)
end

-- Logs a message to the error chat frame
-- @param message The message.
-- @red The red color for this message.
-- @green The green color for this message.
-- @blue The blue color for this message.
function HeadCount:LogError(message, red, green, blue)
	UIErrorsFrame:AddMessage(message, red, green, blue)
end

-----------------------------------------------------
-- CHANNEL MESSAGING
-----------------------------------------------------  
-- Send a chat message to an arbitrary channel
-- @param message The message
-- @param channel The channel
function HeadCount:SendMessage(message, channel)
	assert(message, "Unable to send message because the message is nil.")
	assert(channel, "Unable to send message because the channel is nil.")
	
	if (channel == "GUILD") then
		HeadCount:SendGuildMessage(message)
	elseif (channel == "OFFICER") then
		HeadCount:SendOfficerMessage(message)
	elseif (channel == "PARTY") then
		HeadCount:SendPartyMessage(message)
	elseif (channel == "RAID") then
		HeadCount:SendRaidMessage(message)
	else
		-- TODO: eventually this will have to be modified for SAY/YELL vs arbitrary channels
		SendChatMessage(message, channel, nil, nil)
	end
end


-- Send a chat message to guild chat
-- @param message The message.
function HeadCount:SendGuildMessage(message)
	assert(message, "Unable to send guild message because the message is nil.")
	
	if (IsInGuild()) then
		SendChatMessage(message, "GUILD", nil, nil)
	end
end

-- Send a chat message to guild officer chat.
-- @param message The message.
function HeadCount:SendOfficerMessage(message)
	assert(message, "Unable to send guild officer message because the message is nil.")
	
	if (IsInGuild()) then
		SendChatMessage(message, "OFFICER", nil, nil)
	end
end

-- Send a chat message to party chat.
-- @param message The message.
function HeadCount:SendPartyMessage(message)
	assert(message, "Unable to send party message because the message is nil.")
	
	local isPresentInRaid = UnitInRaid("player")
	local isPresentInParty = (GetNumPartyMembers() > 0)
	if ((isPresentInRaid) or (isPresentInParty)) then
		SendChatMessage(message, "PARTY", nil, nil)
	end
end

-- Send a chat message to raid chat.
-- @param message The message.
function HeadCount:SendRaidMessage(message)
	assert(message, "Unable to send raid message because the message is nil.")
	
	if (1 == UnitInRaid("player")) then
		SendChatMessage(message, "RAID", nil, nil)
	end
end

-- Send a whisper to the recipient.
-- @param message The message.
-- @param recipient The recipient.
function HeadCount:SendWhisper(message, recipient)
	assert(message, "Unable to send whisper message because the message is nil.")
	assert(recipient, "Unable to send whisper message because the recipient is nil.")
	
	SendChatMessage(message, "WHISPER", nil, recipient)
end

----------------------------
-- FUBAR
----------------------------
HeadCount.hasNoText = true
HeadCount.hasIcon = "Interface\\Icons\\INV_Misc_Bone_HumanSkull_01"
HeadCount.hasNoColor = true
HeadCount.defaultPosition = "CENTER"
HeadCount.defaultMinimapPosition = 285
HeadCount.clickableTooltip = false
HeadCount.tooltipHiddenWhenEmpty = true
HeadCount.independentProfile = true
HeadCount.hideWithoutStandby = true
HeadCount.cannotDetachTooltip = true
HeadCount.blizzardTooltip = true

-- Minimap hover tooltip display
function HeadCount:OnTooltipUpdate()
	GameTooltip:AddLine("|cFF9999FF" .. HeadCount.TITLE)
	GameTooltip:AddLine("")
	GameTooltip:AddLine(L["minimap.frame"], 0.2, 1, 0.2)
	GameTooltip:AddLine(L["minimap.configuration"], 0.2, 1, 0.2)
	GameTooltip:AddLine(L["minimap.button.rotate"], 0.2, 1, 0.2)
	GameTooltip:AddLine(L["minimap.button.drag"], 0.2, 1, 0.2)
end 

-- Minimap click display
function HeadCount:OnClick()
	if (UnitInRaid("player")) then
		HeadCount:RAID_ROSTER_UPDATE(true)	-- update attendance and the UI immediately
	end
	
	HeadCount:ToggleUserInterface()
end

-- LDB support
function HeadCount:SetupBroker()
	local DataBroker = LibStub:GetLibrary("LibDataBroker-1.1",true)
	if DataBroker then
		local launcher = DataBroker:NewDataObject("HeadCount", {
		    type = "launcher",
			OnTooltipShow = function(tooltip)
				if not tooltip or not tooltip.AddLine then return end
				tooltip:AddLine("|cFF9999FF" .. HeadCount.TITLE)
				tooltip:AddLine("")
				tooltip:AddLine(L["minimap.frame"], 0.2, 1, 0.2)
				tooltip:AddLine(L["minimap.configuration"], 0.2, 1, 0.2)
			end,
		    icon = "Interface\\Icons\\INV_Misc_Bone_HumanSkull_01",
		    OnClick = function(clickedframe, button) 
				if button == "LeftButton" then
					HeadCount:OnClick() 
				end
				if button == "RightButton" then
					HeadCount:OpenMenu(clickedframe)
				end
			end,
		})
	end
end