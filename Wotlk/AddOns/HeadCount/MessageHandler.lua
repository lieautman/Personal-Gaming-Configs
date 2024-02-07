--[[
Project name: HeadCount
Developed by: seppyk
Website: http://www.wowace.com/projects/head-count/
Description: Manages tracking of raid attendance and more.
License: All Rights Reserved unless otherwise explicitly stated. 
File: MessageHandler.lua
File description: Manages message requests and responses.
]]

local AceOO = AceLibrary("AceOO-2.0")
local L = AceLibrary("AceLocale-2.2"):new("HeadCount")
local HeadCount = HeadCount

HeadCount.MessageHandler = AceOO.Class()

local REGEX_WAITLIST = "^%s*wl"
--local REGEX_WAITLIST_COMMAND = "^%s*wl%s+(%a+)%s*$"
local REGEX_WAITLIST_COMMAND = "^%s*wl%s+(%a+)%s*(.*)$"
local REGEX_OUTGOING = "^%s*%[HeadCount%]"
local MESSAGE_TYPE_WAITLIST = "wl"
local COMMAND_WAITLIST_STATUS = "status"
local COMMAND_WAITLIST_ADD = "add"
local COMMAND_WAITLIST_REMOVE = "remove"
local COMMAND_WAITLIST_CONTACT = "contact"

function HeadCount.MessageHandler.prototype:init()
    self.class.super.prototype.init(self)

	self.type = "HeadCountMessageHandler-1.0"
end

-- Processes an incoming message.
-- @param raid The raid.
-- @param isWaitlistAcceptanceEnabled The wait list acceptance status
-- @param message The message.
-- @param author The message author.
-- @return boolean Returns true if an attendance update is needed and false otherwise.
-- @return boolean Returns true if the message is supported and false otherwise.
-- @return table Returns the ordered list of response messages.
function HeadCount.MessageHandler.prototype:processIncomingMessage(raid, isWaitlistAcceptanceEnabled, message, author)
	assert(raid, "Unable to process message because the raid is nil.")
	assert(message, "Unable to process message because the message is nil.")
	assert(author, "Unable to process message because the author is nil.")
	
	local isUpdateRequired = false
	local isSupportedMessage = false
	local messageList = nil
	
	local formattedMessage = string.lower(message)
	local initialPosition = string.find(formattedMessage, REGEX_WAITLIST)
	
	if (initialPosition) then
		-- waitlist message
		local _, _, command, waitlistNote = string.find(formattedMessage, REGEX_WAITLIST_COMMAND)
		if (command) then 
			if (COMMAND_WAITLIST_STATUS == command) then
				messageList = self:processWaitlistStatusMessage(raid, author)
				isSupportedMessage = true	
			elseif (COMMAND_WAITLIST_ADD == command) then 
				if (isWaitlistAcceptanceEnabled) then 
					isUpdateRequired, messageList = self:processWaitlistAddMessage(raid, author, waitlistNote)
					isSupportedMessage = true	
				end
			elseif (COMMAND_WAITLIST_REMOVE == command) then 
				if (isWaitlistAcceptanceEnabled) then 
					isUpdateRequired, messageList = self:processWaitlistRemoveMessage(raid, author)
					isSupportedMessage = true	
				end
			elseif (COMMAND_WAITLIST_CONTACT == command) then 
				isUpdateRequired, messageList = self:processWaitlistContactMessage(raid, author, waitlistNote)
				isSupportedMessage = true
			else
				if (isWaitlistAcceptanceEnabled) then 
					-- Only display invalid message during wait list acceptance to reduce spam
					messageList = self:processWaitlistInvalidMessage(author)
					isSupportedMessage = true	
				end
			end
		else
			messageList = self:processWaitlistMessage(isWaitlistAcceptanceEnabled, author)
			isSupportedMessage = true	
		end
	end
	
	return isUpdateRequired, isSupportedMessage, messageList
end

-- Determines if an outgoing message is supported.
-- @param message The message.
-- @return boolean Returns true if the message is supported and false otherwise.
function HeadCount.MessageHandler.prototype:IsSupportedIncomingMessage(message) 
	assert(message, "Unable to determine if incoming message is supported because the message is nil.")
	
	local isSupportedMessage = false

	-- Does the message begin with the HeadCount message prefix?
	-- Yes: Message is a supported outgoing message.
	-- No: Message is not a supported outgoing message.
	
	local formattedMessage = string.lower(message)
	local initialPosition = string.find(formattedMessage, REGEX_WAITLIST)
	if (initialPosition) then 
		-- wait list message
		isSupportedMessage = true
	end	
	
	return isSupportedMessage
end

-- Determines if an outgoing message is supported.
-- @param message The message.
-- @return boolean Returns true if the message is supported and false otherwise.
function HeadCount.MessageHandler.prototype:IsSupportedOutgoingMessage(message) 
	assert(message, "Unable to determine if the outgoing message is supported because the message is nil.")
	
	local isSupportedMessage = false

	-- Does the message begin with the HeadCount message prefix?
	-- Yes: Message is a supported outgoing message.
	-- No: Message is not a supported outgoing message.
	
	local initialPosition = string.find(message, REGEX_OUTGOING)
	if (initialPosition) then 
		-- wait list message
		isSupportedMessage = true
	end	
	
	return isSupportedMessage
end

-- Processes a waitlist message
-- @param isWaitlistAcceptanceEnabled The wait list acceptance status
-- @param recipient The recipient.
-- @return table Returns the ordered list of response messages.
function HeadCount.MessageHandler.prototype:processWaitlistMessage(isWaitlistAcceptanceEnabled, recipient)
	local messageList = { }
	
	HeadCount:LogDebug(string.format(L["debug.message.wl"], HeadCount.TITLE, HeadCount.VERSION))
	
	table.insert(messageList, HeadCount.MESSAGE_PREFIX .. " " .. L["message.waitlist.commands"])
	table.insert(messageList, HeadCount.MESSAGE_PREFIX .. " " .. L["message.waitlist.commands.wl"])
	table.insert(messageList, HeadCount.MESSAGE_PREFIX .. " " .. L["message.waitlist.commands.wl.status"])
	table.insert(messageList, HeadCount.MESSAGE_PREFIX .. " " .. L["message.waitlist.commands.wl.contact"])
	
	if (isWaitlistAcceptanceEnabled) then 
		table.insert(messageList, HeadCount.MESSAGE_PREFIX .. " " .. L["message.waitlist.commands.wl.add"])
		table.insert(messageList, HeadCount.MESSAGE_PREFIX .. " " .. L["message.waitlist.commands.wl.remove"])
	end
	
	return messageList
end

-- Processes a waitlist invalid message.
-- @param recipient The recipient.
-- @return table Returns the ordered list of response messages.
function HeadCount.MessageHandler.prototype:processWaitlistInvalidMessage(recipient)
	local messageList = { }
	
	HeadCount:LogDebug(string.format(L["debug.message.wl.invalid"], HeadCount.TITLE, HeadCount.VERSION))
	
	table.insert(messageList, HeadCount.MESSAGE_PREFIX .. " " .. L["message.waitlist.invalid"])

	return messageList
end

-- Processes a waitlist status message.
-- @param raid The raid.
-- @param recipient The recipient.
-- @return table Returns the ordered list of response messages.
function HeadCount.MessageHandler.prototype:processWaitlistStatusMessage(raid, recipient)
	local messageList = { }
	
	HeadCount:LogDebug(string.format(L["debug.message.wl.status"], HeadCount.TITLE, HeadCount.VERSION))
	
	if (raid:isPlayerPresent(recipient)) then 
		-- player is in the raid
		local player = raid:retrievePlayer(recipient)
		if (player:getIsWaitlisted()) then 		
			 table.insert(messageList, HeadCount.MESSAGE_PREFIX .. " " .. L["message.waitlist.commands.wl.status.inwaitlist"])
		else
			 table.insert(messageList, HeadCount.MESSAGE_PREFIX .. " " .. L["message.waitlist.commands.wl.status.notinwaitlist"])
		end
	else
		-- player is not present in the raid
		table.insert(messageList, HeadCount.MESSAGE_PREFIX .. " " .. L["message.waitlist.commands.wl.status.notinraid"])
	end
	
	return messageList
end

-- Processes a waitlist contact message
-- @param raid The raid.
-- @param recipient The recipient.
-- @param waitlistNote The wait list note.
-- @return table Returns the ordered list of response messages.
function HeadCount.MessageHandler.prototype:processWaitlistContactMessage(raid, recipient, waitlistNote)
	local isUpdateRequired = false
	local messageList = { }
	
	HeadCount:LogDebug(string.format(L["debug.message.wl.contact"], HeadCount.TITLE, HeadCount.VERSION))
	
	if (raid:isPlayerPresent(recipient)) then 
		local player = raid:retrievePlayer(recipient)
		if (player:getIsWaitlisted()) then 
			-- player is on the wait list, add the contact message
			if (waitlistNote) then 
				player:setWaitlistNote(waitlistNote)	-- set the new contact note
				
				isUpdateRequired = true
				
				table.insert(messageList, HeadCount.MESSAGE_PREFIX .. " " .. L["message.waitlist.commands.wl.contact.success"])
			else
				table.insert(messageList, HeadCount.MESSAGE_PREFIX .. " " .. L["message.waitlist.commands.wl.contact.invalid"])
			end
		else
			-- player is not on the wait list
			table.insert(messageList, HeadCount.MESSAGE_PREFIX .. " " .. L["message.waitlist.commands.wl.contact.notinwaitlist"])
		end
	else
		-- player is not present in the raid
		table.insert(messageList, HeadCount.MESSAGE_PREFIX .. " " .. L["message.waitlist.commands.wl.contact.notinraid"])
	end
	
	return isUpdateRequired, messageList
end

-- Processes a waitlist add message.
-- @param raid The raid.
-- @param recipient The recipient.
-- @param waitlistNote The wait list note.
-- @return boolean Returns true if an attendance update is needed and false otherwise.
-- @return table Returns the ordered list of response messages.
function HeadCount.MessageHandler.prototype:processWaitlistAddMessage(raid, recipient, waitlistNote)
	local isUpdateRequired = false
	local messageList = { }
	
	HeadCount:LogDebug(string.format(L["debug.message.wl.add"], HeadCount.TITLE, HeadCount.VERSION))
	
	if (raid:isPlayerPresent(recipient)) then 
		-- player is present, check if they are already waitlisted
		local player = raid:retrievePlayer(recipient) 
		if (player:getIsWaitlisted()) then 		
			-- respond that player is already on the waitlist
			table.insert(messageList, HeadCount.MESSAGE_PREFIX .. " " .. L["message.waitlist.commands.wl.add.inwaitlist"])
		else
			-- player is not on the waitlist, if player is in a non-raid list group, set their waitlist flags
			if (player:getIsPresentInRaidList()) then 
				table.insert(messageList, HeadCount.MESSAGE_PREFIX .. " " .. L["message.waitlist.commands.wl.add.inraidlist"])
			else
				local utcDateTimeInSeconds = HeadCount:getUTCDateTimeInSeconds()
				local activityTime = AceLibrary("HeadCountTime-1.0"):new({ ["utcDateTimeInSeconds"] = utcDateTimeInSeconds })	
				
				player:setIsWaitlisted(true)			
				player:setWaitlistActivityTime(activityTime)
				
				if (waitlistNote) then 
					player:setWaitlistNote(waitlistNote)	-- set the new contact note
				end
				
				if (HeadCount:IsWaitlistNotifyEnabled()) then 
					HeadCount:LogInformation(string.format(L["info.waitlist.add.success"], HeadCount.TITLE, HeadCount.VERSION, recipient))
				end
				
				isUpdateRequired = true
			
				table.insert(messageList, HeadCount.MESSAGE_PREFIX .. " " .. L["message.waitlist.commands.wl.add.success"])			
			end
		end
	else
		-- player is not present, add them!
		local utcDateTimeInSeconds = HeadCount:getUTCDateTimeInSeconds()
		local activityTime = AceLibrary("HeadCountTime-1.0"):new({ ["utcDateTimeInSeconds"] = utcDateTimeInSeconds })			
		
		local args = {
			["name"] = recipient, 
			["className"] = nil, 	-- workaround needed
			["fileName"] = nil, 	-- workaround needed
			["race"] = nil, 		-- workaround needed
			["guild"] = nil, 		-- workaround needed
			["sex"] = nil, 			-- workaround needed
			["level"] = HeadCount.DEFAULT_LEVEL, 
			["isPresentInRaidList"] = false, 
			["isPresentInWaitList"] = false, 		
			["isOnline"] = true, 
			["isWaitlisted"] = true, 
			["waitlistActivityTime"] = activityTime, 
			["waitlistNote"] = waitlistNote, 
			["raidListTime"] = 0, 
			["waitListTime"] = 0, 
			["offlineTime"] = 0, 
			["timeList"] = { }, 
			["lastActivityTime"] = activityTime, 
			["isFinalized"] = false	
		}
		
		local timePair = AceLibrary("HeadCountTimePair-1.0"):new({ ["beginTime"] = nil, ["endTime"] = nil, ["note"] = nil })		
		timePair:setBeginTime(activityTime) 		
		timePair:setNote(L["No list"])
		table.insert(args["timeList"], timePair)	-- insert the first time pair (includes begin time with no end time)			
		
		player = AceLibrary("HeadCountPlayer-1.0"):new(args)	-- create an online player, starting in no list
		HeadCount:LogDebug(string.format(L["debug.raid.update.addmember.whisper"], HeadCount.TITLE, HeadCount.VERSION, recipient))
		
		raid:addPlayer(player)	-- add the player
		
		if (HeadCount:IsWaitlistNotifyEnabled()) then 
			HeadCount:LogInformation(string.format(L["info.waitlist.add.success"], HeadCount.TITLE, HeadCount.VERSION, recipient))
		end
		
		isUpdateRequired = true
		
		table.insert(messageList, HeadCount.MESSAGE_PREFIX .. " " .. L["message.waitlist.commands.wl.add.success"])					
	end
	
	return isUpdateRequired, messageList
end

-- Processes a waitlist remove message.
-- @param raid The raid.
-- @param recipient The recipient.
-- @return boolean Returns true if an attendance update is needed and false otherwise.
-- @return table Returns the ordered list of response messages.
function HeadCount.MessageHandler.prototype:processWaitlistRemoveMessage(raid, recipient)
	local isUpdateRequired = false
	local messageList = { }
	
	HeadCount:LogDebug(string.format(L["debug.message.wl.remove"], HeadCount.TITLE, HeadCount.VERSION))
	
	if (raid:isPlayerPresent(recipient)) then 
		local player = raid:retrievePlayer(recipient) 
		if (player:getIsWaitlisted()) then 
			player:setIsWaitlisted(false)
			player:setWaitlistActivityTime(nil)

			table.insert(messageList, HeadCount.MESSAGE_PREFIX .. " " .. L["message.waitlist.commands.wl.remove.success"])
			isUpdateRequired = true
		else
			table.insert(messageList, HeadCount.MESSAGE_PREFIX .. " " .. L["message.waitlist.commands.wl.remove.notinwaitlist"])
		end
	else
		-- player is not present in the raid
		table.insert(messageList, HeadCount.MESSAGE_PREFIX .. " " .. L["message.waitlist.commands.wl.remove.notinraid"])
	end
	
	return isUpdateRequired, messageList
end

-- Processes a list waitlist message
function HeadCount.MessageHandler.prototype:processListWaitlistMessage(raid, channel)
	assert(raid, "Unable to process list wait list message because the raid is nil.")
	assert(channel, "Unable to process list wait list message because the channel is nil.")	
	
	local listMessage = ""
	local orderedPlayerList = raid:retrieveOrderedPlayerList("Waitlist", false, false, false, true, false, true)
	local numberOfWaitlistPlayers = # orderedPlayerList
	
	HeadCount:LogDebug(string.format(L["debug.message.listwaitlist"], HeadCount.TITLE, HeadCount.VERSION))
	
	if (numberOfWaitlistPlayers > 0) then 
		local messageList = { }
		local playerCount = 0
		local message = nil
		for k,v in ipairs(orderedPlayerList) do
			if (0 == (playerCount % HeadCount.MAX_PLAYER_NAMES_PER_LINE)) then 
				message = HeadCount.MESSAGE_PREFIX .. " " .. L["Wait list"] .. ": " .. v:getName()
			else
				message = message .. ", " .. v:getName()
			end
			
			playerCount = playerCount + 1
			
			if ((0 == (playerCount % HeadCount.MAX_PLAYER_NAMES_PER_LINE)) or (playerCount == numberOfWaitlistPlayers)) then 
				table.insert(messageList, message)
			end
		end		
		
		for k,v in ipairs(messageList) do 
			HeadCount:SendMessage(v, channel)
		end
		
	else
		-- No wait list players
		HeadCount:SendMessage(HeadCount.MESSAGE_PREFIX .. " " .. L["info.waitlist.noplayers"], channel)
	end
end

-- To String
-- @return string Returns the string description for this object.
function HeadCount.MessageHandler.prototype:ToString()
	return L["object.MessageHandler"]
end

AceLibrary:Register(HeadCount.MessageHandler, "HeadCountMessageHandler-1.0", 1)
