--[[
Project name: HeadCount
Developed by: seppyk
Website: http://www.wowace.com/projects/head-count/
Description: Manages tracking of raid attendance and more.
License: All Rights Reserved unless otherwise explicitly stated. 
File: RaidListWrapper.lua
File description: Raid list wrapper object
]]

local AceOO = AceLibrary("AceOO-2.0")
local L = AceLibrary("AceLocale-2.2"):new("HeadCount")
local HeadCount = HeadCount

HeadCount.RaidListWrapper = AceOO.Class()

HeadCount.RaidListWrapper.prototype.raidList = nil				-- the raid list
HeadCount.RaidListWrapper.prototype.numberOfRaids = nil			-- number of raids

function HeadCount.RaidListWrapper.prototype:init(args)
    self.class.super.prototype.init(self)

	self.type = "HeadCountRaidListWrapper-1.0"
	self.raidList = args["raidList"]
	self.numberOfRaids = args["numberOfRaids"]
end

-- Retrieves the most recent raid.
-- @return object Returns the most recent raid or nil if none exists.
function HeadCount.RaidListWrapper.prototype:retrieveMostRecentRaid()
	local raid = nil

	local orderedRaidList = self:retrieveOrderedRaidList(true)
	local numberOfRaids = # orderedRaidList
	if (numberOfRaids > 0) then
		raid = orderedRaidList[numberOfRaids]		
	end
	
	return raid
end

function HeadCount.RaidListWrapper.prototype:retrieveMostRecentRaidId()
	local raidId = 0
	
	local raid = self:retrieveMostRecentRaid()
	if (raid) then
		raidId = raid:retrieveStartingTime():getUTCDateTimeInSeconds()
	end
	
	return raidId
end

-- Retrieves an ordered raid list.
-- @param isDescending The sort order.
-- @return table Returns an ordered raid list.
function HeadCount.RaidListWrapper.prototype:retrieveOrderedRaidList(isDescending) 
	local orderedRaidList = {}
	
	for k,v in pairs(self.raidList) do
		table.insert(orderedRaidList, v)
	end

	table.sort(orderedRaidList, function(a, b) 		
		local aKey = a:retrieveStartingTime():getUTCDateTimeInSeconds() 
		local bKey = b:retrieveStartingTime():getUTCDateTimeInSeconds() 
		
		if ((aKey) and (bKey)) then 
			if (isDescending) then
				return aKey < bKey
			else
				return bKey > aKey
			end		
		else
			HeadCount:LogError(string.format(L["error.sort.starttime"], HeadCount.TITLE))
			return true
		end
	end)

	return orderedRaidList
end

-- Adds a raid.
-- @param raid The raid.
function HeadCount.RaidListWrapper.prototype:addRaid(id, raid) 
	if (id and raid) then 
		self.raidList[id] = raid
		self.numberOfRaids = self.numberOfRaids + 1
	end
end

-- Remove a raid.
-- @param id The raid id.
-- @return boolean Returns true if the raid was removed and false otherwise.
function HeadCount.RaidListWrapper.prototype:removeRaid(id)
	local isRemoved = false

	if (self.raidList[id]) then
		-- the raid exists
		self.raidList[id] = nil
		self.numberOfRaids = self.numberOfRaids - 1
		isRemoved = true
	end

	return isRemoved
end

-- Remove all raids
function HeadCount.RaidListWrapper.prototype:removeAll()
	self.raidList = { }	-- empty out and GC
	self.numberOfRaids = 0
end

-- Remove old raids
-- @param number The pruning time, in number of weeks
function HeadCount.RaidListWrapper.prototype:pruneRaids(pruningTimeInWeeks)
	local pruningTimeType = type(pruningTimeInWeeks)
	
	if ((pruningTimeType == "number") and (pruningTimeInWeeks > 0)) then
		-- parameter is a valid number
		-- parameter is a number greater than zero (1 or more weeks)
		local utcDateTimeInSeconds = HeadCount:getUTCDateTimeInSeconds()		-- the current date and time
		local activityTime = AceLibrary("HeadCountTime-1.0"):new({ ["utcDateTimeInSeconds"] = utcDateTimeInSeconds })
		
		local pruningTime = -1 * pruningTimeInWeeks	-- multiply by -1 to look back in time
		activityTime:addWeeks(pruningTime)			
		
		HeadCount:LogDebug(string.format(L["debug.raid.prune.date"], HeadCount.TITLE, HeadCount.VERSION, HeadCount:getDateTimeAsString(activityTime)))
		
		for k,v in pairs(self.raidList) do
			local endingTime = v:retrieveEndingTime()
			local isFinalized = v:getIsFinalized()
			if ((endingTime) and (isFinalized)) then
				-- raid has an ending time and is finalized, candidate for automatical deletion
				-- activityTime:addDays(pruningTimeInDays)
				local endingTimeInSeconds = endingTime:getUTCDateTimeInSeconds()
				local activityTimeInSeconds = activityTime:getUTCDateTimeInSeconds()
				if (endingTimeInSeconds <= activityTimeInSeconds) then
					local startingTime = v:retrieveStartingTime()
					HeadCount:LogDebug(string.format(L["debug.raid.prune.delete"], HeadCount.TITLE, HeadCount.VERSION, HeadCount:getDateTimeAsString(startingTime), HeadCount:getDateTimeAsString(endingTime)))
					
					local startingTimeInSeconds = startingTime:getUTCDateTimeInSeconds()					
					self:removeRaid(startingTimeInSeconds)	-- remove the raid
				end
			end
		end		
	end
end

-- Determines if a raid is present.
-- @param id The raid id.
-- @return boolean Returns true if the raid is present and false otherwise.
function HeadCount.RaidListWrapper.prototype:isRaidPresent(id) 
	local isPresent = false
	
	if (self.raidList[id]) then
		isPresent = true
	end
	
	return isPresent
end

-- Gets a raid by its id.
-- @param id The raid id.
-- @return object Returns the raid if it exists or nil otherwise.
function HeadCount.RaidListWrapper.prototype:getRaidById(id) 
	local raid = nil
	
	if (self.raidList[id]) then 
		raid = self.raidList[id]
	end
	
	return raid
end

-- Retrieves the total number of raids.
-- @return number Returns the total number of raids.
function HeadCount.RaidListWrapper.prototype:getNumberOfRaids() 
	return self.numberOfRaids
end

-- Gets the raid list.
-- @return table Returns the raid list.			
function HeadCount.RaidListWrapper.prototype:getRaidList() 
	return self.raidList
end

-- Sets the raid list.
-- @param raidList The raid list.
function HeadCount.RaidListWrapper.prototype:setRaidList(raidList) 
	self.raidList = raidList
end

-- Serialization method.
function HeadCount.RaidListWrapper.prototype:Serialize() 
	local s = { }
	
	for k,v in pairs(self) do
		if type(v) ~= "function" and type(v) ~= "userdata" and k ~= "header" and k ~= "btnframe" and k ~= "temp" and k ~= "theme" and k ~= "base" and k ~= "curState" then
			s[k] = v
		end
	end
	
	return s
end

-- Deserialization method.
function HeadCount.RaidListWrapper:Deserialize(t) 
	return self:new(t)
end

-- To String
-- @return string Returns the string description for this object.
function HeadCount.RaidListWrapper.prototype:ToString()
	return L["object.RaidListWrapper"]
end

AceLibrary:Register(HeadCount.RaidListWrapper, "HeadCountRaidListWrapper-1.0", 1)