--[[
Project name: HeadCount
Developed by: seppyk
Website: http://www.wowace.com/projects/head-count/
Description: Manages tracking of raid attendance and more.
License: All Rights Reserved unless otherwise explicitly stated. 
File: Player.lua
File description: Player object
]]

local AceOO = AceLibrary("AceOO-2.0")
local L = AceLibrary("AceLocale-2.2"):new("HeadCount")
local HeadCount = HeadCount

HeadCount.Player = AceOO.Class()

HeadCount.Player.prototype.name = nil
HeadCount.Player.prototype.className = nil
HeadCount.Player.prototype.fileName = nil
HeadCount.Player.prototype.race = nil
HeadCount.Player.prototype.guild = nil
HeadCount.Player.prototype.sex = nil
HeadCount.Player.prototype.level = nil
HeadCount.Player.prototype.isPresentInRaidList = nil	-- raid list raid group
HeadCount.Player.prototype.isPresentInWaitList = nil	-- wait list raid group
HeadCount.Player.prototype.isOnline = nil
HeadCount.Player.prototype.isWaitlisted = nil			-- artificial wait list
HeadCount.Player.prototype.waitlistActivityTime = nil	-- artificial wait list activity time
HeadCount.Player.prototype.waitlistNote = nil			-- artificial wait list note
HeadCount.Player.prototype.raidListTime = nil
HeadCount.Player.prototype.waitListTime = nil
HeadCount.Player.prototype.offlineTime = nil
HeadCount.Player.prototype.timeList = nil
HeadCount.Player.prototype.lastActivityTime = nil
HeadCount.Player.prototype.isFinalized = nil

function HeadCount.Player.prototype:init(args)
    self.class.super.prototype.init(self)

	self.type = "HeadCountPlayer-1.0"
	self.name = args["name"]
	self.className = args["className"]
	self.fileName = args["fileName"]
	self.race = args["race"]
	self.guild = args["guild"]
	self.sex = args["sex"]
	self.level = args["level"]
	self.isPresentInRaidList = args["isPresentInRaidList"]
	self.isPresentInWaitList = args["isPresentInWaitList"]
	self:setIsOnline(args["isOnline"]) 
	self.isWaitlisted = args["isWaitlisted"]	
	self.waitlistActivityTime = args["waitlistActivityTime"]
	self.waitlistNote = args["waitlistNote"]
	self.raidListTime = args["raidListTime"]
	self.waitListTime = args["waitListTime"]
	self.offlineTime = args["offlineTime"]
	self.timeList = args["timeList"]
	self:setLastActivityTime(args["lastActivityTime"]) 
	self:setIsFinalized(args["isFinalized"])
end

-- Gets the race.
-- @return string Returns the race.
function HeadCount.Player.prototype:getRace() 
	return self.race
end

-- Gets the guild.
-- @return string Returns the guild.
function HeadCount.Player.prototype:getGuild() 
	return self.guild
end

-- Gets the sex
-- @return number Returns the sex
function HeadCount.Player.prototype:getSex() 
	return self.sex
end

-- Gets the real sex.
-- 1 = Unknown
-- 2 = Male
-- 3 = Female
-- @return string Returns the real sex.
function HeadCount.Player.prototype:getRealSex() 
	local realSex = nil
	
	if (2 == self.sex) then 
		realSex = L["Male"]
	elseif (3 == self.sex) then
		realSex = L["Female"]
	else
		realSex = L["Unknown"]		
	end
	
	return realSex
end	
	
-- Gets the level
-- @return number Returns the level
function HeadCount.Player.prototype:getLevel() 
	return self.level
end

-- Moves a player to the raid list.
-- @param activityTime The activity time.
-- @return boolean Returns true if the player was moved, false otherwise
function HeadCount.Player.prototype:moveToRaidList(activityTime) 
	local isChanged = false
	local timeDifference = HeadCount:computeTimeDifference(activityTime, self.lastActivityTime)
	local isWaitlistAutoremovalEnabled = HeadCount:IsWaitlistAutoremovalEnabled()			
	
	if (self.isPresentInWaitList) then 
		-- player was in the wait list, now in the raid list
		self:setIsPresentInRaidList(true)
		self:addToWaitListTime(timeDifference)
		self:processEndTime(activityTime) 
		self:processBeginTime(activityTime, L["Raid list"]) 
		self:setLastActivityTime(activityTime)	
		self:setIsFinalized(false)
		isChanged = true
	elseif (self:getIsPresentInNoList()) then 
		-- player was in no list, now in the raid list
		self:setIsPresentInRaidList(true)		
		
		if (not self.isOnline) then
			-- player was offline
			self:addToOfflineTime(timeDifference)
			self:setIsOnline(true)
		end
		
		self:processEndTime(activityTime) 
		self:processBeginTime(activityTime, L["Raid list"]) 		
		self:setLastActivityTime(activityTime)	
		self:setIsFinalized(false)
		isChanged = true
	end
	-- do nothing if player is in the raid list (no change) or both lists (error)

	if (isWaitlistAutoremovalEnabled) then 
		self:setIsWaitlisted(false)			-- wait list group players are automatically removed from the wait list when joining a raid list group
		self:setWaitlistActivityTime(nil)
	end
		
	return isChanged
end

-- Moves a player to the wait list
-- @param activityTime The activity time.
-- @return boolean Returns true if the player was moved, false otherwise
function HeadCount.Player.prototype:moveToWaitList(activityTime) 
	local isChanged = false
	local timeDifference = HeadCount:computeTimeDifference(activityTime, self.lastActivityTime)

	self:setIsWaitlisted(true)			-- wait list group players are automatically on wait list
	self:setWaitlistActivityTime(activityTime)

	if (self.isPresentInRaidList) then 
		-- player was in the raid list, now in the wait list 
		self:setIsPresentInWaitList(true)	-- player is in the wait list group
		self:addToRaidListTime(timeDifference)
		self:processEndTime(activityTime) 
		self:processBeginTime(activityTime, L["Wait list"])
		self:setLastActivityTime(activityTime)
		self:setIsFinalized(false)
		isChanged = true
	elseif (self:getIsPresentInNoList()) then
		-- player was in no list, now in the wait list 
		self:setIsPresentInWaitList(true)	-- player is in the wait list group		
		
		if (not self.isOnline) then 
			-- player was offline
			self:addToOfflineTime(timeDifference)
			self:setIsOnline(true)
		end
		
		self:processEndTime(activityTime)
		self:processBeginTime(activityTime, L["Wait list"])
		self:setLastActivityTime(activityTime) 
		self:setIsFinalized(false)
		isChanged = true
	end
	-- do nothing if player is in the wait list (no change) or both lists (error)
	
	return isChanged
end

-- Moves a player to no list
-- @param activityTime The activity time.
-- @param isOnline The online status
function HeadCount.Player.prototype:moveToNoList(activityTime, isOnline) 
	local isChanged = false
	local timeDifference = HeadCount:computeTimeDifference(activityTime, self.lastActivityTime)

	if (isOnline) then 
		-- player is currently online
		if (self.isPresentInRaidList) then 		
			self:clearPresenceLists()	
			self:addToRaidListTime(timeDifference)
			self:processEndTime(activityTime) 
			self:processBeginTime(activityTime, L["No list"]) 
			self:setLastActivityTime(activityTime) 
			self:setIsFinalized(false)
			isChanged = true
		elseif (self.isPresentInWaitList) then 
			self:clearPresenceLists()									
			self:addToWaitListTime(timeDifference)
			self:processEndTime(activityTime) 
			self:processBeginTime(activityTime, L["No list"]) 
			self:setLastActivityTime(activityTime) 
			self:setIsFinalized(false)
			isChanged = true 
		elseif (self:getIsPresentInNoList()) then 
			if (not self.isOnline) then 
				-- player was offline, now is online
				self:clearPresenceLists() 				
				self:addToOfflineTime(timeDifference)		
				self:setIsOnline(true)
				self:processEndTime(activityTime) 
				self:processBeginTime(activityTime, L["No list"]) 
				self:setLastActivityTime(activityTime) 
				self:setIsFinalized(false)
				isChanged = true 						
			end			
		end
	else
		-- player is currently offline 
		if (self.isOnline) then 
			-- player was online, now is offline
			if (self.isPresentInRaidList) then 
				self:clearPresenceLists()
				self:addToRaidListTime(timeDifference)
				self:setIsOnline(false)
				self:processEndTime(activityTime) 
				self:processBeginTime(activityTime, L["Offline"]) 
				self:setLastActivityTime(activityTime) 
				self:setIsFinalized(false)
				isChanged = true 
			elseif (self.isPresentInWaitList) then 
				self:clearPresenceLists()
				self:addToWaitListTime(timeDifference)
				self:setIsOnline(false)
				self:processEndTime(activityTime) 
				self:processBeginTime(activityTime, L["Offline"]) 
				self:setLastActivityTime(activityTime) 
				self:setIsFinalized(false)
				isChanged = true 
			end
		end	
	end
	
	return isChanged
end

-- Update location specific values
-- @param position The raid position
-- @param className The class name.
-- @param fileName The file name.
function HeadCount.Player.prototype:updateValues(position, className, fileName) 
	if (position) then
		if (not self.className) then 
			self.className = className
		end

		if (not self.fileName) then 
			self.fileName = fileName
		end
		
		if (0 == self.level) then 
			-- level is not set
			self.level = UnitLevel("raid" .. position)
		end

		if (not self.race) then 
			local _, race = UnitRace("raid" .. position)	
			self.race = race
		end
		
		if (not self.guild) then 
			-- guild is not set 
			self.guild = GetGuildInfo("raid" .. position)
		end
			
		if (not self.sex) then 
			self.sex = UnitSex("raid" .. position)
		end
	end
end


-- Gets the name.
-- @return string Returns the name.
function HeadCount.Player.prototype:getName()
	return self.name
end

-- Sets the name.
-- @param name The name.
function HeadCount.Player.prototype:setName(name)
	self.name = name
end

-- Gets the class name.
-- @return string Returns the class name.
function HeadCount.Player.prototype:getClassName()
	return self.className
end

-- Sets the class name.
-- @param className The class name.
function HeadCount.Player.prototype:setClassName(className)
	self.className = className
end

-- Gets the standard class name.
-- Death Knight
-- Druid
-- Hunter
-- Mage
-- Paladin
-- Priest
-- Rogue
-- Shaman
-- Warlock
-- Warrior
-- @return string Returns the standard class name.
function HeadCount.Player.prototype:getFileName()
	return self.fileName
end

-- Sets the standard class name.
-- @param fileName The standard class name.
function HeadCount.Player.prototype:setFileName(fileName)
	self.fileName = fileName
end

-- Gets the raid list presence status.
-- @return boolean Returns true if the player is in the raid list, false otherwise.
function HeadCount.Player.prototype:getIsPresentInRaidList()
	return self.isPresentInRaidList
end

-- Sets the raid list presence status.
-- @param isPresentInRaidList The raid list presence status.
function HeadCount.Player.prototype:setIsPresentInRaidList(isPresentInRaidList)
	self.isPresentInRaidList = isPresentInRaidList
	self.isPresentInWaitList = not isPresentInRaidList
end

-- Gets the wait list presence status.
-- @return boolean Returns true if the player is in the wait list, false otherwise.
function HeadCount.Player.prototype:getIsPresentInWaitList()
	return self.isPresentInWaitList
end

-- Sets the wait list presence status.
-- @param isPresentInWaitList The wait list presence status.
function HeadCount.Player.prototype:setIsPresentInWaitList(isPresentInWaitList)
	self.isPresentInWaitList = isPresentInWaitList
	self.isPresentInRaidList = not isPresentInWaitList
end

-- Gets the no list presence status.
-- @return boolean Returns true if the player is in no list, false otherwise.
function HeadCount.Player.prototype:getIsPresentInNoList()
	return not (self.isPresentInRaidList or self.isPresentInWaitList)	-- return nor operation
end

-- Clears the raid list presence and wait list presence statuses.
function HeadCount.Player.prototype:clearPresenceLists()
	self.isPresentInRaidList = false
	self.isPresentInWaitList = false
end

-- Gets the online status.
-- @return boolean Returns true if the player is online, false otherwise.
function HeadCount.Player.prototype:getIsOnline()
	return self.isOnline
end

-- Sets the online status.
-- @param isOnline The online status.
function HeadCount.Player.prototype:setIsOnline(isOnline)
	self.isOnline = isOnline
end

-- Gets the waitlisted status.
-- @return boolean Returns true if the player is waitlisted and false otherwise.
function HeadCount.Player.prototype:getIsWaitlisted()
	return self.isWaitlisted
end

-- Sets the waitlisted status.
-- @param isWaitlisted The waitlisted status.
function HeadCount.Player.prototype:setIsWaitlisted(isWaitlisted)
	self.isWaitlisted = isWaitlisted
end

-- Gets the wait list activity time
-- @return object Returns the wait list activity time.
function HeadCount.Player.prototype:getWaitlistActivityTime()
	return self.waitlistActivityTime
end

-- Sets the wait list activity time.
-- @param waitlistActivityTime The wait list activity time.
function HeadCount.Player.prototype:setWaitlistActivityTime(waitlistActivityTime)
	self.waitlistActivityTime = waitlistActivityTime
end

-- Gets the wait list note.
-- @return string Returns the wait list note.
function HeadCount.Player.prototype:getWaitlistNote()
	return self.waitlistNote
end

-- Sets the wait list note.
-- @param waitlistNote The wait list note.
function HeadCount.Player.prototype:setWaitlistNote(waitlistNote)
	self.waitlistNote = waitlistNote
end

-- Gets the raid list time.
-- @return number Returns the raid list time.
function HeadCount.Player.prototype:getRaidListTime()
	return self.raidListTime
end

-- Sets the raid list time.
-- @param raidListTime The raid list time.
function HeadCount.Player.prototype:setRaidListTime(raidListTime)
	self.raidListTime = raidListTime
end

-- Adds to the raid list time.
-- @param numberOfSeconds
function HeadCount.Player.prototype:addToRaidListTime(numberOfSeconds) 
	self.raidListTime = self.raidListTime + numberOfSeconds
end

-- Gets the wait list time.
-- @return number Returns the wait list time.
function HeadCount.Player.prototype:getWaitListTime()
	return self.waitListTime
end

-- Sets the wait list time.
-- @param waitListTime The wait list time.
function HeadCount.Player.prototype:setWaitListTime(waitListTime)
	self.waitListTime = waitListTime
end

-- Adds to the wait list time.
-- @param numberOfSeconds
function HeadCount.Player.prototype:addToWaitListTime(numberOfSeconds) 
	self.waitListTime = self.waitListTime + numberOfSeconds
end

-- Gets the offline time.
-- @return number Returns the offline time.
function HeadCount.Player.prototype:getOfflineTime()
	return self.offlineTime
end

-- Adds to the offline time.
-- @param numberOfSeconds
function HeadCount.Player.prototype:addToOfflineTime(numberOfSeconds) 
	self.offlineTime = self.offlineTime + numberOfSeconds 	
end

-- Gets the time list.
-- @return table Returns the time list.
function HeadCount.Player.prototype:getTimeList()
	return self.timeList
end

-- Sets the time list.
-- @param timeList The time list.
function HeadCount.Player.prototype:setTimeList(timeList)
	self.timeList = timeList
end

-- Processes a begin time
-- @param activityTime The activity time.
-- @param note The note
function HeadCount.Player.prototype:processBeginTime(activityTime, note) 
	if (activityTime) then
		local numberOfPlayerTimePairs = # self.timeList	-- get the total number of current time pairs
		local lastBeginTime = self.timeList[numberOfPlayerTimePairs]:getBeginTime()
		local lastEndTime = self.timeList[numberOfPlayerTimePairs]:getEndTime()

		if ((lastBeginTime) and (lastEndTime)) then 
			-- both time values exist for the most recent pair, start a new pair
			local timePair = AceLibrary("HeadCountTimePair-1.0"):new({ ["beginTime"] = nil, ["endTime"] = nil, ["note"] = nil })	
			timePair:setBeginTime(activityTime) 
			timePair:setNote(note)
			table.insert(self.timeList, timePair)
		elseif ((not lastBeginTime) and (not lastEndTime)) then
			-- most recent pair contains no time values
			self.timeList[numberOfPlayerTimePairs]:setBeginTime(activityTime)
			self.timeList[numberOfPlayerTimePairs]:setNote(note)
		end
	end
end

-- Processes an end time
-- @param activityTime The activity time.
function HeadCount.Player.prototype:processEndTime(activityTime) 
	if (activityTime) then
		local numberOfPlayerTimePairs = # self.timeList	-- get the total number of current time pairs
		local lastBeginTime = self.timeList[numberOfPlayerTimePairs]:getBeginTime()
		local lastEndTime = self.timeList[numberOfPlayerTimePairs]:getEndTime()
		
		if ((lastBeginTime) and (not lastEndTime)) then
			-- the most recent beginning time exists
			-- no recent end time exists, add it
			self.timeList[numberOfPlayerTimePairs]:setEndTime(activityTime)
		end		
	end
end

-- Gets the begin time for the player.
-- @return number Returns the player begin time
function HeadCount.Player.prototype:retrieveStartingTime()
	return self.timeList[1]:getBeginTime()
end

-- Gets the end time for the player.
-- @return number Returns the player begin time
function HeadCount.Player.prototype:retrieveEndingTime()
	local numberOfTimes = # self.timeList
	
	return self.timeList[numberOfTimes]:getEndTime()
end

-- Gets the last activity time.
-- @return object Returns the last activity time.
function HeadCount.Player.prototype:getLastActivityTime()
	return self.lastActivityTime
end

-- Sets the last activity time.
-- @param lastActivityTime The last activity time.
function HeadCount.Player.prototype:setLastActivityTime(lastActivityTime)
	self.lastActivityTime = lastActivityTime
end

-- Gets the total time.
-- @return number Returns the total time.
function HeadCount.Player.prototype:getTotalTime() 
	local isRaidListTimeEnabled = HeadCount:IsRaidListTimeEnabled()
	local isWaitListTimeEnabled = HeadCount:IsWaitListTimeEnabled()
	local isOfflineTimeEnabled = HeadCount:IsOfflineTimeEnabled()

	local totalTime = 0
	
	if (isRaidListTimeEnabled) then 
		totalTime = totalTime + self.raidListTime
	end
	
	if (isWaitListTimeEnabled) then 
		totalTime = totalTime + self.waitListTime
	end
	
	if (isOfflineTimeEnabled) then 
		totalTime = totalTime + self.offlineTime
	end
	
	return totalTime
end

-- Gets the finalized status.
-- @return boolean Returns the finalized status.
function HeadCount.Player.prototype:getIsFinalized() 
	return self.isFinalized
end

-- Sets the finalized status.
-- @param isFinalized The finalized status
function HeadCount.Player.prototype:setIsFinalized(isFinalized) 
	self.isFinalized = isFinalized 
end

-- Finalizes the current player
-- @param currentTime The finalization time.
-- @return boolean Returns true if finalized and false otherwise.
function HeadCount.Player.prototype:finalize(currentTime) 
	if (not self.isFinalized) then 
		local numberOfPlayerTimePairs = # self.timeList
		local lastBeginTime = self.timeList[numberOfPlayerTimePairs]:getBeginTime()
		local lastEndTime = self.timeList[numberOfPlayerTimePairs]:getEndTime()
		if (not lastEndTime) then 
			-- ending player time is not yet set
			self.timeList[numberOfPlayerTimePairs]:setEndTime(currentTime)	
			
			local timeDifference = HeadCount:computeTimeDifference(currentTime, lastBeginTime)						

			if (self.isOnline) then
				-- player is online
				if (self.isPresentInRaidList) then
					-- player is online and in raid list
					self:addToRaidListTime(timeDifference)
				elseif (self.isPresentInWaitList) then
					-- player is online and in raid list
					self:addToWaitListTime(timeDifference)
				end			
			else
				-- player is offline
				self:addToOfflineTime(timeDifference)	
			end		
		end

		self:clearPresenceLists() 
		self:setIsOnline(true)
		self:setLastActivityTime(currentTime) 
		self:setIsFinalized(true)
	end 
	
	return self.isFinalized
end

-- Recover from a fault.
-- @param activityTime The activity time.
function HeadCount.Player.prototype:recover(activityTime, lastActivityTime) 
	local timeIndex = # self.timeList
	local lastBeginTime = self.timeList[timeIndex]:getBeginTime() 
	local lastEndTime = self.timeList[timeIndex]:getEndTime()
	
	if ((lastBeginTime) and (not lastEndTime)) then
		local timeDifference = HeadCount:computeTimeDifference(lastActivityTime, lastBeginTime)		
		if (self.isPresentInRaidList) then 
			-- player is in the raid list
			self:addToRaidListTime(timeDifference)
			self:processEndTime(lastActivityTime)
			self:processBeginTime(activityTime, L["Raid list"] .. " - " .. L["Recovery"])
		elseif (self.isPresentInWaitList) then 	
			-- player is in the wait list
			self:addToWaitListTime(timeDifference)
			self:processEndTime(lastActivityTime)
			self:processBeginTime(activityTime, L["Wait list"] .. " - " .. L["Recovery"])
		else
			-- player is in no list
			self:processEndTime(lastActivityTime)

			if (self.isOnline) then 
				-- player is online				
				self:processBeginTime(activityTime, L["No list"] .. " - " .. L["Recovery"])				
			else
				-- player is offline
				self:addToOfflineTime(timeDifference)
				self:processBeginTime(activityTime, L["Offline"] .. " - " .. L["Recovery"])
			end		
		end		
	end
	
	self:setLastActivityTime(activityTime)
	self:setIsFinalized(false)
end

-- Serialization method.
function HeadCount.Player.prototype:Serialize() 
	local s = { }
	
	for k,v in pairs(self) do
		if type(v) ~= "function" and type(v) ~= "userdata" and k ~= "header" and k ~= "btnframe" and k ~= "temp" and k ~= "theme" and k ~= "base" and k ~= "curState" then
			s[k] = v
		end
	end
	
	return s
end

-- Deserialization method.
function HeadCount.Player:Deserialize(t) 
	return self:new(t)
end

-- To String
-- @return string Returns the string description for this object.
function HeadCount.Player.prototype:ToString()
	return L["object.Player"]
end

AceLibrary:Register(HeadCount.Player, "HeadCountPlayer-1.0", 1)