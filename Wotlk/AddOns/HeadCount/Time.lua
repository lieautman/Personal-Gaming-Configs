--[[
Project name: HeadCount
Developed by: seppyk
Website: http://www.wowace.com/projects/head-count/
Description: Manages tracking of raid attendance and more.
License: All Rights Reserved unless otherwise explicitly stated. 
File: Time.lua
File description: Time object.
]]

local AceOO = AceLibrary("AceOO-2.0")
local L = AceLibrary("AceLocale-2.2"):new("HeadCount")
local HeadCount = HeadCount

HeadCount.Time = AceOO.Class()

HeadCount.Time.prototype.utcDateTimeInSeconds = nil

function HeadCount.Time.prototype:init(args)
	self.class.super.prototype.init(self)
    
	self.utcDateTimeInSeconds = args["utcDateTimeInSeconds"]
end

-- Gets the UTC date and time in seconds.
-- @return table Returns the UTC date and time in seconds.
function HeadCount.Time.prototype:getUTCDateTimeInSeconds() 
	return self.utcDateTimeInSeconds
end

-- Sets the UTC date and time in seconds.
-- @param utcDateTime The UTC date and time in seconds.
function HeadCount.Time.prototype:setUTCDateTimeInSeconds(utcDateTimeInSeconds) 
	self.utcDateTimeInSeconds = utcDateTimeInSeconds
end

-- Gets the month.
-- @return number Returns the month.
function HeadCount.Time.prototype:getMonth()
	local utcDateTime = date("*t", self.utcDateTimeInSeconds)
	
	return utcDateTime.month
end

-- Gets the day.
-- @return number Returns the day.
function HeadCount.Time.prototype:getDay()
	local utcDateTime = date("*t", self.utcDateTimeInSeconds)
	
	return utcDateTime.day
end

-- Add weeks to the time.
-- A positive number of weeks will add weeks to the time whereas a negative number of weeks will subtract weeks from the time.
-- @param numberOfWeeks The number of weeks.
function HeadCount.Time.prototype:addWeeks(numberOfWeeks)
	assert(type(numberOfWeeks) == "number", "Unable to add weeks to the given time because the number of weeks is not a number.")
	
	local flooredNumberOfWeeks = math.floor(numberOfWeeks)
	local flooredNumberOfSeconds = flooredNumberOfWeeks * 7 * 24 * 60 * 60	-- 7 days per week / 24 hours per day / 60 minutes per hour / 60 seconds per minute

	local modifiedDateTime = self.utcDateTimeInSeconds + flooredNumberOfSeconds	
	
	self.utcDateTimeInSeconds = modifiedDateTime
end

-- Add days to the time.
-- A positive number of days will add days to the time whereas a negative number of days will subtract days from the time.
-- @param numberOfDays The number of days.
function HeadCount.Time.prototype:addDays(numberOfDays)
	assert(type(numberOfDays) == "number", "Unable to add days to the given time because the number of days is not a number.")
	
	local flooredNumberOfDays = math.floor(numberOfDays)
	local flooredNumberOfSeconds = flooredNumberOfDays * 24 * 60 * 60	-- 24 hours per day / 60 minutes per hour / 60 seconds per minute

	local modifiedDateTime = self.utcDateTimeInSeconds + flooredNumberOfSeconds	
	
	self.utcDateTimeInSeconds = modifiedDateTime
end

-- Gets the year.
-- @return number Returns the year.
function HeadCount.Time.prototype:getYear()
	local utcDateTime = date("*t", self.utcDateTimeInSeconds)
	
	return utcDateTime.year
end

-- Gets the hour.
-- @return number Returns the hour.
function HeadCount.Time.prototype:getHour()
	local utcDateTime = date("*t", self.utcDateTimeInSeconds)
	
	return utcDateTime.hour
end

-- Gets the minute.
-- @return number Returns the minute.
function HeadCount.Time.prototype:getMinute()
	local utcDateTime = date("*t", self.utcDateTimeInSeconds)
	
	return utcDateTime.min
end

-- Gets the second.
-- @return number Returns the second.
function HeadCount.Time.prototype:getSecond()
	local utcDateTime = date("*t", self.utcDateTimeInSeconds)
	
	return utcDateTime.sec
end

-- Serialization method.
function HeadCount.Time.prototype:Serialize() 
	local s = { }
	
	for k,v in pairs(self) do
		if type(v) ~= "function" and type(v) ~= "userdata" and k ~= "header" and k ~= "btnframe" and k ~= "temp" and k ~= "theme" and k ~= "base" and k ~= "curState" then
			s[k] = v
		end
	end
	
	return s
end

-- Deserialization method.
function HeadCount.Time:Deserialize(t) 
	return self:new(t)
end

-- To String
-- @return string Returns the string description for this object.
function HeadCount.Time.prototype:ToString()
	return L["object.Time"]
end

AceLibrary:Register(HeadCount.Time, "HeadCountTime-1.0", 1) 
