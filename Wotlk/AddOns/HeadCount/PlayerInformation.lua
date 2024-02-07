--[[
Project name: HeadCount
Developed by: seppyk
Website: http://www.wowace.com/projects/head-count/
Description: Manages tracking of raid attendance and more.
License: All Rights Reserved unless otherwise explicitly stated. 
File: PlayerInformation.lua
File description: Player information object
]]

local AceOO = AceLibrary("AceOO-2.0")
local L = AceLibrary("AceLocale-2.2"):new("HeadCount")
local HeadCount = HeadCount

HeadCount.PlayerInformation = AceOO.Class()

HeadCount.PlayerInformation.prototype.player = nil
HeadCount.PlayerInformation.prototype.lootList = nil

function HeadCount.PlayerInformation.prototype:init(args)
	self.class.super.prototype.init(self)
	
	self.type = "HeadCountPlayerInformation-1.0"
	self.player = args["player"]
	self.lootList = args["lootList"]
end

-- Retrieves the information list.
-- @return table Returns the information list.
-- @return number Returns the number of information lines.
function HeadCount.PlayerInformation.prototype:retrieveInformationList() 
	local numberOfLines = 0
	local informationList = { } 
	
	-- General information
	table.insert(informationList, "|cFF9999FF" .. L["General information"] .. "|r")
	table.insert(informationList, "|cFFCCCCFF" .. L["Name"] .. ":|r " .. self.player.name)
	if (self.player.guild) then
		table.insert(informationList, "|cFFCCCCFF" .. L["Guild"] .. ":|r " .. self.player.guild)
	else
		table.insert(informationList, "|cFFCCCCFF" .. L["Guild"] .. ":|r " .. L["Unknown"])
	end

	if (self.player.level > 0) then 
		table.insert(informationList, "|cFFCCCCFF" .. L["Level"] .. ":|r " .. self.player.level)
	else
		table.insert(informationList, "|cFFCCCCFF" .. L["Level"] .. ":|r " .. L["Unknown"])
	end
	
	table.insert(informationList, "|cFFCCCCFF" .. L["Gender"] .. ":|r " .. self.player:getRealSex())
	
	if (self.player.race) then 
		table.insert(informationList, "|cFFCCCCFF" .. L["Race"] .. ":|r " .. self.player.race)
	else
		table.insert(informationList, "|cFFCCCCFF" .. L["Race"] .. ":|r " .. L["Unknown"])
	end
	
	if (self.player.className) then 
		if (self.player.fileName) then 
			table.insert(informationList, "|cFFCCCCFF" .. L["Class"] .. ":|r " .. self.player.className .. " (" .. self.player.fileName .. ")")	
		else
			table.insert(informationList, "|cFFCCCCFF" .. L["Class"] .. ":|r " .. self.player.className)
		end
	else
		table.insert(informationList, "|cFFCCCCFF" .. L["Class"] .. ":|r " .. L["Unknown"])
	end
	table.insert(informationList, "")
	
	-- Loot
	table.insert(informationList, "|cFF9999FF" .. L["Loot"] .. "|r")
	if ((self.lootList) and (# self.lootList > 0)) then 
		for k,v in ipairs(self.lootList) do 
			local lootTexture = v:getTexture()		
			local lootLink = v:getLink()
			local lootCost = v:getCost()
			
			local lootString = ""
			if (lootTexture) then
				lootString = lootString .. "|T" .. lootTexture .. ":16:16|t "
			else
				lootString = lootString .. "|TInterface\\Icons\\INV_Misc_QuestionMark:16:16|t "
			end
			
			if (lootLink) then
				lootString = lootString .. lootLink .. " "
			else
				lootString = lootString .. L["Item unavailable"] .. " "
			end
			
			if (lootCost) then
				lootString = lootString .. " (" .. L["Cost"] .. ": " .. lootCost .. ")"
			else
				lootString = lootString .. " (" .. L["Cost"] .. ": 0)"
			end
			
			table.insert(informationList, lootString)
		end	
	else
		table.insert(informationList, "|cFFCCCCFF" .. L["None"] .. "|r")
	end
	table.insert(informationList, "")
	
	-- Presence
	table.insert(informationList, "|cFF9999FF" .. L["Presence"] .. "|r")
	table.insert(informationList, "|cFFCCCCFF" .. L["Raid list group"] .. ":|r " .. HeadCount:convertBooleanToYesNoString(self.player.isPresentInRaidList))
	table.insert(informationList, "|cFFCCCCFF" .. L["Wait list group"] .. ":|r " .. HeadCount:convertBooleanToYesNoString(self.player.isPresentInWaitList))
	table.insert(informationList, "|cFFCCCCFF" .. L["Offline"] .. ":|r " .. HeadCount:convertBooleanToYesNoString(not self.player.isOnline)) 
	
	local isWaitlisted = self.player:getIsWaitlisted()
	if (isWaitlisted) then 
		table.insert(informationList, "|cFFCCCCFF" .. L["Wait list"] .. ":|r " .. HeadCount:convertBooleanToYesNoString(isWaitlisted) .. " (" .. HeadCount:getDateTimeAsString(self.player:getWaitlistActivityTime()) .. ")")
	else
		table.insert(informationList, "|cFFCCCCFF" .. L["Wait list"] .. ":|r " .. HeadCount:convertBooleanToYesNoString(isWaitlisted))
	end
	
	table.insert(informationList, "")
	
	-- Times
	table.insert(informationList, "|cFF9999FF" .. L["Time information"] .. "|r")
	table.insert(informationList, "|cFFCCCCFF" .. L["Raid list time"] .. ":|r " .. HeadCount:getSecondsAsString(self.player.raidListTime))
	table.insert(informationList, "|cFFCCCCFF" .. L["Wait list time"] .. ":|r " .. HeadCount:getSecondsAsString(self.player.waitListTime))
	table.insert(informationList, "|cFFCCCCFF" .. L["Offline time"] .. ":|r " .. HeadCount:getSecondsAsString(self.player.offlineTime))
	table.insert(informationList, "|cFFCCCCFF" .. L["Total time"] .. ":|r " .. HeadCount:getSecondsAsString(self.player:getTotalTime()))
	table.insert(informationList, "") 
	
	-- Time history 
	table.insert(informationList, "|cFF9999FF" .. L["Time history"] .. "|r") 
	local numberOfTimePairs = # self.player.timeList 
	for i=1,numberOfTimePairs do 
		local beginTime = self.player.timeList[i]:getBeginTime() 
		local endTime = self.player.timeList[i]:getEndTime() 
		local note = self.player.timeList[i]:getNote() 
		
		if (beginTime) then 
			-- time pair has a begin time
			if (endTime) then 
				-- time pair has an end time 
				table.insert(informationList, "|cFFCCCCFF" .. i .. ".|r  " .. HeadCount:getDateTimeAsString(beginTime) .. " - " .. HeadCount:getDateTimeAsString(endTime) .. " (" .. note .. ")")
			else
				-- time pair has no end time 
				table.insert(informationList, "|cFFCCCCFF" .. i .. ".|r  " .. HeadCount:getDateTimeAsString(beginTime) .. " - " .. L["Current"] .. " (" .. note .. ")")
			end			
		end
	end
	table.insert(informationList, "")
	
	-- Last activity time
	table.insert(informationList, "|cFF9999FF" .. L["Last activity"] .. "|r") 
	table.insert(informationList, "|cFFCCCCFF" .. L["Last activity time"] .. ":|r " .. HeadCount:getDateTimeAsString(self.player.lastActivityTime))
	numberOfLines = # informationList 
	
	return informationList, numberOfLines
end

-- Gets the player.
-- @return table Returns the player.
function HeadCount.PlayerInformation.prototype:getPlayer() 
	return self.player
end

-- Gets the loot list.
-- @return table Returns the loot list.
function HeadCount.PlayerInformation.prototype:getLootList() 
	return self.lootList
end

-- To String
-- @return string Returns the string description for this object.
function HeadCount.PlayerInformation.prototype:ToString()
	return L["object.PlayerInformation"]
end

AceLibrary:Register(HeadCount.PlayerInformation, "HeadCountPlayerInformation-1.0", 1)

