--[[
Project name: HeadCount
Developed by: seppyk
Website: http://www.wowace.com/projects/head-count/
Description: Manages tracking of raid attendance and more.
License: Creative Common Attribution-NonCommercial-ShareAlike 3.0 Unported
File: HeadCountUtil.lua
File description: Utility functions
]]

local L = AceLibrary("AceLocale-2.2"):new("HeadCount")
local HeadCount = HeadCount

-- Converts a string to a proper name (first letter capitalized, remainder of string in lower case).
-- @param originalString The original string to convert.
function HeadCount:convertStringToProperName(originalString)
	return string.gsub(string.lower(originalString), "%a", string.upper, 1)	-- string in all lowercase except for first letter in uppercase
end

-- Splits a string by a given pattern.
-- @param originalString The original string.
-- @param pattern The delimiter pattern.
-- @return table Returns a table of the split string.
function HeadCount:split(originalString, pattern)
	local temp = {}
	local fPattern = "(.-)" .. pattern
	local lastEnd = 1
	local s, e, cap = originalString:find(fPattern, 1)
	while s do
		if ((s ~= 1) or (cap ~= "")) then
			table.insert(temp, cap)
		end

		lastEnd = e + 1
		s, e, cap = originalString:find(fPattern, lastEnd)
	end
   
	if (lastEnd <= # originalString) then
		cap = originalString:sub(lastEnd)
		table.insert(temp, cap)
	end
	
	return temp
end

-- Gets the current UTC date and time in seconds
-- @return number Returns the current UTC date and time in seconds.
function HeadCount:getUTCDateTimeInSeconds() 
	local utcDateTime = date("!*t")
	
	return time(utcDateTime)
end

-- Gets the display date and time as a string
-- @param activityTime The activity time.
-- @return string Returns the display date and time as a string
function HeadCount:getDateTimeAsString(activityTime) 
	-- TODO: Add locale to this method to display time in various localized formats
	local currentSeconds = activityTime:getUTCDateTimeInSeconds()	-- UTC date and time in seconds

	local displayTimezoneDifferenceInSeconds = HeadCount:GetTimezone() * 60 * 60 -- seconds
	currentSeconds = currentSeconds + displayTimezoneDifferenceInSeconds			 -- display time in seconds
	local displayDateTime = date("*t", currentSeconds)
	
	local formattedDate = HeadCount:formatDate(displayDateTime)	-- retrieve the formatted date
	local formattedTime = HeadCount:formatTime(displayDateTime) -- retrieve the formatted time

	local datetimeString = nil
	if ((formattedDate) and (formattedTime)) then
		datetimeString = formattedDate .. " " .. formattedTime
	else
		error("Unable to process date time string because the formatted date and/or time are not initialized.")
	end
	
	return datetimeString
end

-- Formats the date-time table by the given configuration option
-- @param dateTime The date time table.
-- @return string Returns the formatted time string.
function HeadCount:formatTime(dateTime) 
	local formattedTime = nil
	
	if (dateTime) then
		local isTimeFormatEnabled = HeadCount:IsTimeFormatEnabled()
		
		if (isTimeFormatEnabled) then
			-- 24 hour clock
			formattedTime = string.format("%02d", dateTime.hour) .. ":" .. string.format("%02d", dateTime.min) .. ":" .. string.format("%02d", dateTime.sec)
		else
			-- 12 hour clock
			local hour = dateTime.hour
			if (dateTime.hour <= 11) then 
				-- 00:00 - 11:59  (am) 
				if (0 == dateTime.hour) then 
					hour = dateTime.hour + 12 
				end 
				
				formattedTime = string.format("%d", hour) .. ":" .. string.format("%02d", dateTime.min) .. ":" .. string.format("%02d", dateTime.sec) .. L["am"]			
			else
				-- 12:00 - 23:59 (pm)
				if (dateTime.hour >= 13) then 
					hour = dateTime.hour - 12
				end
				
				formattedTime = string.format("%d", hour) .. ":" .. string.format("%02d", dateTime.min) .. ":" .. string.format("%02d", dateTime.sec) .. L["pm"]			
			end			
		end
	end
	
	return formattedTime
end

-- Formats the date-time table by the given configuration option
-- @param dateTime The date time table.
-- @return string Returns the formatted date string.
function HeadCount:formatDate(dateTime) 
	local formattedDate = nil
	
	if (dateTime) then
		local dateFormat = HeadCount:GetDateFormat() 
		
		if (L.dateFormatting[1] == dateFormat) then
			--dateFormatting[1] = "Day-Month-Year"
			formattedDate = dateTime.day .. "/" .. dateTime.month .. "/" .. dateTime.year
		elseif (L.dateFormatting[2] == dateFormat) then 
			--dateFormatting[2] = "Month-Day-Year"
			formattedDate = dateTime.month .. "/" .. dateTime.day .. "/" .. dateTime.year
		else
			--dateFormatting[3] = "Year-Day-Month"		
			formattedDate = dateTime.year .. "/" .. dateTime.month .. "/" .. dateTime.day
		end
	end
	
	return formattedDate
end

-- Gets the display date as a string
-- @param currentTime The current time.
-- @return Returns the display time as a string
function HeadCount:getDateAsString(currentTime) 
	-- TODO: Add locale to this method to display time in various localized formats
	local currentSeconds = currentTime:getUTCDateTimeInSeconds()		-- UTC date and time in seconds
	
	local displayTimezoneDifferenceInSeconds = HeadCount:GetTimezone() * 60 * 60 -- seconds
	currentSeconds = currentSeconds + displayTimezoneDifferenceInSeconds			 -- display time in seconds
	local displayDateTime = date("*t", currentSeconds)
	
	local formattedDate = HeadCount:formatDate(displayDateTime)	-- get the formatted date
	
	return formattedDate
end

-- Gets the display time as a string
-- @param activityTime The activity time.
-- @return Returns the display time as a string
function HeadCount:getTimeAsString(activityTime) 
	-- TODO: Add locale to this method to display time in various localized formats
	local timeString = "00:00:00"
	
	if (activityTime) then	
		local currentSeconds = activityTime:getUTCDateTimeInSeconds()		-- UTC date and time in seconds
	
		local displayTimezoneDifferenceInSeconds = HeadCount:GetTimezone() * 60 * 60 -- seconds
		currentSeconds = currentSeconds + displayTimezoneDifferenceInSeconds			 -- display time in seconds
		local displayDateTime = date("*t", currentSeconds)
		
		local formattedTime = HeadCount:formatTime(displayDateTime) 
		if (formattedTime) then
			timeString = formattedTime
		else
			error("Unable to process date time string because the formatted time is not initialized.")
		end
	end
	
	return timeString
end

-- Gets a time string based on number of seconds.
-- @param totalSeconds The total seconds.
function HeadCount:getSecondsAsString(totalSeconds) 
	local secondsString = nil
	local remainingSeconds
	
	if (totalSeconds > 0) then
		local numberOfHours = math.floor(totalSeconds / 3600)			
		remainingSeconds = totalSeconds - (numberOfHours * 3600)
	
		local numberOfMinutes = math.floor(remainingSeconds / 60)
		remainingSeconds = remainingSeconds - (numberOfMinutes * 60)
		
		secondsString = string.format("%02d:%02d:%02d", numberOfHours, numberOfMinutes, remainingSeconds)
	else
		secondsString = "00:00:00" 
	end
	
	return secondsString	
end

-- Computes the time difference between a current date and an original date.
-- @param currentTime The current time.
-- @param originalTime The original time.
-- @return number Returns the time difference in seconds between the current date and an original date.
function HeadCount:computeTimeDifference(currentTime, originalTime) 
	local timeDifference = 0
	
	if ((currentTime) and (originalTime)) then
		local currentSeconds = currentTime:getUTCDateTimeInSeconds()
		local originalSeconds = originalTime:getUTCDateTimeInSeconds()
			
		timeDifference = difftime(currentSeconds, originalSeconds)
	end
	
	return timeDifference
end
	
-- Converts a boolean value to its localized string equivalent.
-- @param booleanValue The boolean value.
-- @return string Returns "true" if the boolean value is true, "false" otherwise
function HeadCount:convertBooleanToString(booleanValue) 
	if (booleanValue) then
		-- boolean value is not nil -> true
		return L["True"]
	else
		-- boolean value is nil -> false
		return L["False"]		
	end
end

-- Converts a boolean value to its localized string equivalent.
-- @param booleanValue The boolean value.
-- @return string Returns "true" if the boolean value is true, "false" otherwise
function HeadCount:convertBooleanToYesNoString(booleanValue) 
	if (booleanValue) then
		-- boolean value is not nil -> true
		return L["Yes"]
	else
		-- boolean value is nil -> false
		return L["No"]		
	end
end

-- Trims leading and trailing whitespace from a given string.
-- @param value The string value.
function HeadCount:trim(value)
	local trimmedValue = nil
	
	if (value) then
		trimmedValue = string.gsub(value, "^%s*(.-)%s*$", "%1")	
	end
	
	return trimmedValue
end
	
-- Determines if a given string is a number
-- @param numberString The number string.
-- @return boolean Returns true if the string is a valid number and false otherwise.
function HeadCount:isNumber(numberString)
	local isValid = false
	
	if (numberString) then
		isValid = string.find(numberString, "^(%d+%.?%d*)$")
	end
	
	return isValid
end

-- Determines if the given string is non-empty
-- @param value The string.
-- @return boolean Returns true if the string is a valid string and false otherwise.
function HeadCount:isString(value)
	local isValid = false

	if ((value) and (string.len(value) > 0)) then
		-- string is not null and greater than 0 characters
		isValid = true
	end
	
	return isValid
end

-- Determines if the player is in a raid instance
-- @return boolean Returns true if the player is in a raid instance and false otherwise.
function HeadCount:isRaidInstance()
	local isPresent = false

	local isPresentInInstance, instanceType = IsInInstance()	
	if ((isPresentInInstance) and (instanceType == "raid")) then
		-- player is in a raid instance
		isPresent = true
	end
	
	return isPresent
end

-- Determines the boss encounter name
-- @param name The boss name
-- @return encounterName Returns the boss encounter name
function HeadCount:retrieveBossEncounterName(name)
	assert(name, "Unable to retrieve boss encounter name because the name is nil.")
	
	local encounterName = nil
	
	if (HeadCount.BOSS_ALIASES[name]) then
		-- special boss encounter name
		encounterName = HeadCount.BOSS_ALIASES[name]
	else
		-- encounter name is the boss
		encounterName = name
	end		
	
	return encounterName
end

-- Determines if the zone is a battleground/arena zone
function HeadCount:isBattlegroundZone(zone) 
	assert(zone, "Unable to determine if zone is a battleground because the zone is nil.")

	local isBattleground = false

	local inInstance, instanceType = IsInInstance()	
	if ((HeadCount.BATTLEGROUNDS[zone]) or (instanceType == "pvp") or (instanceType == "arena")) then 
		-- zone is a battleground or arena
		isBattleground = true
	end
	
	return isBattleground
end

-- Determines the difficulty level
-- 1 - 10 Player
-- 2 - 25 Player
-- 3 - 10 Player (Heroic)
-- 4 - 25 Player (Heroic)
-- @return number Returns the raid difficulty level or nil if not in a raid instance
function HeadCount:determineDifficulty() 
	local difficulty = nil
	
	local inInstance, instanceType = IsInInstance() 
	
	if (inInstance and instanceType == "raid") then 
		difficulty = GetRaidDifficulty()
	end
	
	return difficulty
end

-- Retrieves the item color based on item rarity
-- @param The item quality (rarity)
-- @return string Returns the item color
function HeadCount:retrieveItemColor(rarity)
	local color = HeadCount.DEFAULT_COLOR_NO_ALPHA
	
	if (rarity) then
		if ((rarity >= 0) and (rarity <= 6)) then
			local lookupRarity = rarity + 1	
			color = HeadCount.ITEM_COLORS_NO_ALPHA[lookupRarity]
		end
	end
	
	return color
end

-- Escape characters into XML entities
-- @param value The string to convert
-- @return string Returns the converted entity string
function HeadCount:convertToXMLEntities(value)
	local xmlString = nil
   
	if (value) then 
		xmlString = value
        xmlString = string.replace(xmlString, "&", "&amp;" )
        xmlString = string.replace(xmlString,  "<", "&lt;" )
        xmlString = string.replace(xmlString,  ">", "&gt;" )
        xmlString = string.replace(xmlString,  "\"", "&quot;" )
        xmlString = string.replace(xmlString,  "'", "&apos;" )
	end
   
	return xmlString   	
end

-- Converts a time to a W3C international standard date and time string  (ISO 8601)
-- @param activityTime The activity time.
-- @return string Returns the display date and time as a ISO 8601 string
function HeadCount:getDateTimeAsXMLString(activityTime)
   local dateTimeString = nil
      
	if (activityTime) then
		local currentSeconds = activityTime:getUTCDateTimeInSeconds()      -- UTC date and time in seconds

		local displayDateTime = date("*t", currentSeconds)

		-- Example: July 7, 2008 3:46:42 UTC is equivalent to 2008-07-07T03:46:42Z
		dateTimeString =  string.format("%04d", displayDateTime.year) .. "-" .. string.format("%02d", displayDateTime.month) .. "-" .. string.format("%02d", displayDateTime.day) .. "T" .. string.format("%02d", displayDateTime.hour) .. ":" .. string.format("%02d", displayDateTime.min) .. ":" .. string.format("%02d", displayDateTime.sec) .. "Z"
	end
   
	return dateTimeString
end 
