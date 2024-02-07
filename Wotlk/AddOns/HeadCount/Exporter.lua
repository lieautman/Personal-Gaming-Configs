--[[
Project name: HeadCount
Developed by: seppyk
Website: http://www.wowace.com/projects/head-count/
Description: Manages tracking of raid attendance and more.
License: All Rights Reserved unless otherwise explicitly stated. 
File: Exporter.lua
File description: Raid exporting
]]

local L = AceLibrary("AceLocale-2.2"):new("HeadCount")
local HeadCount = HeadCount

-- Exports a given raid in the configured format
-- @param raid The raid
-- @return string Returns the exported raid string
function HeadCount:exportRaid(raid)
	assert(raid, "Unable to export the raid because the raid is nil.")
	
	local exportString = nil
	
	local exportFormat = HeadCount:GetExportFormat()
	assert(exportFormat, "Unable to export raid because the export format is nil.")

	-- TODO: May want to convert this into a hash table of functions for better lookup time eventually to avoid an ever-growing switch-case statement
	if ("EQdkp" == exportFormat) then
		-- EQdkp
		exportString = HeadCount:exportEQdkp(raid) 
	elseif ("DKPBoard" == exportFormat) then
		exportString = HeadCount:exportDKPBoard(raid)
	elseif ("phpBB_ItemStats" == exportFormat) then
		exportString = HeadCount:exportPhpBBItemStats(raid)
	elseif ("CSV" == exportFormat) then
		exportString = HeadCount:exportCSV(raid)
	elseif ("Text" == exportFormat) then 
		exportString = HeadCount:exportText(raid)
	elseif ("XML" == exportFormat) then
		exportString = HeadCount:exportXML(raid)
	else
		-- phpBB
		exportString = HeadCount:exportPhpBB(raid) 
	end
	
	return exportString
end

-- Export a given raid in plain text format
-- @param raid The raid
-- @return string Returns the exported plain text string
function HeadCount:exportText(raid)
	assert(raid, "Unable to export the raid into plain text format because the raid is nil.")
	
	local exportString = ""   -- initialize as empty string	
	
	local zone = raid:getZone()
    local difficulty = raid:getDifficulty()
	local difficultyString = HeadCount.INSTANCE_DIFFICULTY[difficulty]	

	if (zone) then
		if (difficultyString and HeadCount.INSTANCES[zone].hasMultiDifficulty) then
			exportString = exportString .. zone .. " (" .. difficultyString .. ")\r\n"   
		else
			exportString = exportString .. zone .. "\r\n"   
		end
	end 
	
    local raidStartTime = raid:retrieveStartingTime()
    local raidEndTime = raid:retrieveEndingTime()		
	exportString = exportString .. HeadCount:getDateTimeAsString(raidStartTime) .. " - " .. HeadCount:getDateTimeAsString(raidEndTime) .. "\r\n\r\n"
	
    local orderedPlayerList = raid:retrieveOrderedPlayerList("Name", true, true, true, false, false, true)	
    exportString = exportString .. L["Players"] .. ":\r\n"
	if ((# orderedPlayerList) > 0) then 
		for k,v in ipairs(orderedPlayerList) do
			local waitTime = v:getWaitListTime()
			local offlineTime = v:getOfflineTime()		
			local className = v:getClassName()
			if (className) then 
				exportString = exportString .. v:getName() .. " (" .. className .. ")\r\n"
			else
				exportString = exportString .. v:getName() .. "\r\n"
			end
			exportString = exportString .. L["Raid"] .. ": " .. HeadCount:getSecondsAsString(v:getRaidListTime()) .. ", "
			exportString = exportString .. L["Standby"] .. ": " .. HeadCount:getSecondsAsString(v:getWaitListTime()) .. ", "
			exportString = exportString .. L["Offline"] .. ": " .. HeadCount:getSecondsAsString(v:getOfflineTime()) .. "\r\n"
		end
		exportString = exportString .. "\r\n"
	else
		exportString = exportString .. L["None"] .. "\r\n\r\n"
	end

    if (raid:getBossList()) then
        -- boss list is present	
		exportString = exportString .. L["Boss kills"] .. ":\r\n"
        local orderedBossList = raid:retrieveOrderedBossList()
		
		if ((# orderedBossList) > 0) then
			for k,v in ipairs(orderedBossList) do
				exportString = exportString .. v:getName() .. " at " .. HeadCount:getDateTimeAsString(v:getActivityTime()) .. "\r\n"
			end
			exportString = exportString .. "\r\n"
		else
			exportString = exportString .. L["None"] .. "\r\n\r\n"
		end
    end

	local lootList = raid:getLootList()
    exportString = exportString .. L["Loot"] .. ":\r\n"
    
	if ((# lootList) > 0) then
	    for k,v in ipairs(raid:getLootList()) do
			local lootName = v:getName()
			
			local cost = v:getCost()
			if (not cost) then
				cost = 0
			end
			
			local color = HeadCount:retrieveItemColor(v:getRarity())
			if (lootName) then
				exportString = exportString .. lootName .. " by " .. v:getPlayerName() .. " (Cost: " .. cost .. ")"
			else
				exportString = exportString .. L["Item unavailable"] .. " by " .. v:getPlayerName() .. " (Cost: " .. cost.. ")"		
			end	
			
			local lootNote = v:getNote()
			if ((lootNote) and (HeadCount:isString(lootNote))) then
				exportString = exportString .. " - " .. lootNote
			end
			
			exportString = exportString .. "\r\n"
	    end
	else
		exportString = exportString .. L["None"] .. "\r\n"	
	end
	
	return exportString
end

-- Export a given raid in XML format
-- @param raid The raid
-- @return string Returns the exported XML string
function HeadCount:exportXML(raid)
	assert(raid, "Unable to export the raid into XML format because the raid is nil.")

	local exportString = ""   -- initialize as empty string	
	
	-- <raid>
	local zone = HeadCount:convertToXMLEntities(raid:getZone())
	local difficulty = HeadCount:convertToXMLEntities(raid:getDifficulty())
	local difficultyString = HeadCount.INSTANCE_DIFFICULTY[tonumber(difficulty)]	
	local startTime = HeadCount:getDateTimeAsXMLString(raid:retrieveStartingTime())
	local endTime = HeadCount:getDateTimeAsXMLString(raid:retrieveEndingTime())

    local playerList = raid:retrieveOrderedPlayerList("Name", true, true, true, false, false, true)   
    local bossList = raid:retrieveOrderedBossList()
	local lootList = raid:getLootList()

	-- export raid information
	-- <raid>
	exportString = exportString .. '<raid generatedFrom="' .. HeadCount.TITLE .. '" version="' .. HeadCount.VERSION .. '">' .. "\r\n"
	if (zone) then
		exportString = exportString .. "\t<zone>" .. zone .. "</zone>\r\n"
	else
		exportString = exportString .. "\t<zone />\r\n"
	end
	
	if (difficultyString and HeadCount.INSTANCES[raid:getZone()].hasMultiDifficulty) then
		exportString = exportString .. "\t<difficulty>" .. difficultyString .. "</difficulty>\r\n"
	else
		exportString = exportString .. "\t<difficulty />\r\n"
	end
	
	exportString = exportString .. "\t<start>" .. startTime .. "</start>\r\n"
	exportString = exportString .. "\t<end>" .. endTime .. "</end>\r\n"   

	-- export player information
	-- <players>
	if ((playerList) and (# playerList > 0))then
		exportString = exportString .. "\t<players>\r\n"
      
		for k,v in ipairs(playerList) do			
			local name = HeadCount:convertToXMLEntities(v:getName())			
			local className = HeadCount:convertToXMLEntities(v:getClassName())			
			local guild = HeadCount:convertToXMLEntities(v:getGuild())			
			local race = HeadCount:convertToXMLEntities(v:getRace())			
			local sex = HeadCount:convertToXMLEntities(v:getRealSex())			
			local level = HeadCount:convertToXMLEntities(v:getLevel())			
			local raidDuration = HeadCount:convertToXMLEntities(v:getRaidListTime())			
			local waitDuration = HeadCount:convertToXMLEntities(v:getWaitListTime())			
			local offlineDuration = HeadCount:convertToXMLEntities(v:getOfflineTime())
			local waitlistStatus = v:getIsWaitlisted()
			local waitlistActivityTime = HeadCount:getDateTimeAsXMLString(v:getWaitlistActivityTime())
			local waitlistNote = HeadCount:convertToXMLEntities(v:getWaitlistNote())			
			local timeList = v:getTimeList()

			exportString = exportString .. "\t\t<player>" .. "\r\n"
			exportString = exportString .. "\t\t\t<name>" .. name .. "</name>\r\n"
			
			if (className) then 
				exportString = exportString .. "\t\t\t<class>" .. className .. "</class>\r\n"
			else
				exportString = exportString .. "\t\t\t<class />\r\n"
			end
			
			if (guild) then
				exportString = exportString .. "\t\t\t<guild>" .. guild.. "</guild>\r\n"
			else
				exportString = exportString .. "\t\t\t<guild />\r\n"
			end
			
			if (race) then 
				exportString = exportString .. "\t\t\t<race>" .. race .. "</race>\r\n"
			else
				exportString = exportString .. "\t\t\t<race />\r\n"
			end
			
			exportString = exportString .. "\t\t\t<sex>" .. sex.. "</sex>\r\n"
			
			if (level) then
				exportString = exportString .. "\t\t\t<level>" .. level .. "</level>\r\n"
			else
				exportString = exportString .. "\t\t\t<level />\r\n"
			end
			
			exportString = exportString .. "\t\t\t<raidDuration>" .. raidDuration .. "</raidDuration>\r\n"   
			exportString = exportString .. "\t\t\t<waitDuration>" .. waitDuration .. "</waitDuration>\r\n"   
			exportString = exportString .. "\t\t\t<offlineDuration>" .. offlineDuration .. "</offlineDuration>\r\n"   

			exportString = exportString .. "\t\t\t<waitlist>" .. "\r\n"
			exportString = exportString .. "\t\t\t\t<status>" .. HeadCount:convertBooleanToString(waitlistStatus) .. "</status>\r\n"
			if (waitlistActivityTime) then 
				exportString = exportString .. "\t\t\t\t<start>" .. waitlistActivityTime .. "</start>\r\n"
			else
				exportString = exportString .. "\t\t\t\t<start />\r\n"
			end
			if ((waitlistNote) and (string.len(waitlistNote) > 0)) then 
				exportString = exportString .. "\t\t\t\t<note>" .. waitlistNote .. "</note>\r\n"
			else
				exportString = exportString .. "\t\t\t\t<note />\r\n"
			end
			exportString = exportString .. "\t\t\t</waitlist>" .. "\r\n"
			
			if (timeList and (# timeList > 0)) then
				exportString = exportString .. "\t\t\t<attendance>" .. "\r\n"
           
				for r,s in ipairs(timeList) do
					local beginTime = HeadCount:getDateTimeAsXMLString(s:getBeginTime())
					local endTime = HeadCount:getDateTimeAsXMLString(s:getEndTime())					
					local note = HeadCount:convertToXMLEntities(s:getNote())
               
					if ((beginTime) and (endTime)) then
						exportString = exportString .. "\t\t\t\t<event>\r\n"
						exportString = exportString .. "\t\t\t\t\t<note>" .. note .. "</note>\r\n"
						exportString = exportString .. "\t\t\t\t\t<start>" .. beginTime .. "</start>\r\n"   
						exportString = exportString .. "\t\t\t\t\t<end>" .. endTime .. "</end>\r\n"                 
						exportString = exportString .. "\t\t\t\t</event>\r\n"
					end
				end
           
				exportString = exportString .. "\t\t\t</attendance>\r\n"
			else
				exportString = exportString .. "\t\t\t<attendance />\r\n"   
			end
			
			exportString = exportString .. "\t\t</player>\r\n"
		end
      
		exportString = exportString .. "\t</players>\r\n"
	else
		exportString = exportString .. "\t<players />\r\n"
	end

	-- export boss information
	-- <bossKills>
	if ((bossList) and (# bossList > 0)) then
		exportString = exportString .. "\t<bossKills>\r\n"
		
		for k,v in ipairs(bossList) do		
			local bossName = HeadCount:convertToXMLEntities(v:getName())		 
			local bossZone = HeadCount:convertToXMLEntities(v:getZone())
			local bossDifficulty = HeadCount:convertToXMLEntities(v:getDifficulty())
			local bossDifficultyString = HeadCount.INSTANCE_DIFFICULTY[tonumber(bossDifficulty)]
			local bossTime = HeadCount:getDateTimeAsXMLString(v:getActivityTime())
			local bossPlayerList = v:getPlayerList()
         
			exportString = exportString .. "\t\t<boss>\r\n"
			exportString = exportString .. "\t\t\t<name>" .. bossName .. "</name>\r\n"
			
			if (bossZone) then 
				exportString = exportString .. "\t\t\t<zone>" .. bossZone .. "</zone>\r\n"
			else
				exportString = exportString .. "\t\t\t<zone />\r\n"
			end
			
			if (bossDifficultyString) then
				exportString = exportString .. "\t\t\t<difficulty>" .. bossDifficultyString .. "</difficulty>\r\n"
			else
				exportString = exportString .. "\t\t\t<difficulty />\r\n"
			end
			
			exportString = exportString .. "\t\t\t<time>" .. bossTime .. "</time>\r\n"

			if ((bossPlayerList) and (# bossPlayerList > 0)) then
				exportString = exportString .. "\t\t\t<players>\r\n"
   
				for r,s in ipairs(bossPlayerList) do			
					exportString = exportString .. "\t\t\t\t<player>" .. HeadCount:convertToXMLEntities(s) .. "</player>\r\n"
				end
           
				exportString = exportString .. "\t\t\t</players>\r\n"   
			else
				exportString = exportString .. "\t\t\t<players />\r\n"
			end
         
			exportString = exportString .. "\t\t</boss>\r\n"   
		end
		
		exportString = exportString .. "\t</bossKills>\r\n"
	else
		exportString = exportString .. "\t<bossKills />\r\n"
	end

	-- export loot information
	-- <loot>
	if ((lootList) and (# lootList > 0)) then
		exportString = exportString .. "\t<loot>\r\n"
     
		for k,v in ipairs(lootList) do
			local itemId  = HeadCount:convertToXMLEntities(v:getItemId())
			local lootZone = HeadCount:convertToXMLEntities(v:getZone())		 
			local itemQuantity = HeadCount:convertToXMLEntities(v:getQuantity())
			local itemLooter = HeadCount:convertToXMLEntities(v:getPlayerName())
			local lootTime = HeadCount:getDateTimeAsXMLString(v:getActivityTime())		 
			local itemCost = HeadCount:convertToXMLEntities(v:getCost())
			local lootSource = HeadCount:convertToXMLEntities(v:getSource())
			local lootNote = HeadCount:convertToXMLEntities(v:getNote())
			
			local itemName = HeadCount:convertToXMLEntities(v:getName())			
			local itemRarity = HeadCount:convertToXMLEntities(v:getRarity())
			local itemLevel = HeadCount:convertToXMLEntities(v:getLevel()) 
			local itemType = HeadCount:convertToXMLEntities(v:getItemType())  
			local itemSubType = HeadCount:convertToXMLEntities(v:getItemSubType())  
			local itemTexture = HeadCount:convertToXMLEntities(v:getTexture())  
			
			exportString = exportString .. "\t\t<item>\r\n"
			exportString = exportString .. "\t\t\t<id>" .. itemId .. "</id>\r\n"     
			
			if (itemName) then
				exportString = exportString .. "\t\t\t<name>" .. itemName .. "</name>\r\n"         
			else
				exportString = exportString .. "\t\t\t<name>" .. L["Item unavailable"] .. "</name>\r\n"         
			end
			
			exportString = exportString .. "\t\t\t<looter>" .. itemLooter .. "</looter>\r\n"

			if (lootSource) then
				exportString = exportString .. "\t\t\t<source>" .. lootSource.. "</source>\r\n"
			else
				exportString = exportString .. "\t\t\t<source />\r\n"
			end
			
			exportString = exportString .. "\t\t\t<time>" .. lootTime .. "</time>\r\n"
			
			if (lootZone) then
				exportString = exportString .. "\t\t\t<zone>" .. lootZone .. "</zone>\r\n"     
			else
				exportString = exportString .. "\t\t\t<zone />\r\n"
			end
			
			exportString = exportString .. "\t\t\t<quantity>" .. itemQuantity .. "</quantity>\r\n"   			
			exportString = exportString .. "\t\t\t<cost>" .. itemCost .. "</cost>\r\n"         

			if (lootNote) then
				exportString = exportString .. "\t\t\t<note>" .. lootNote .. "</note>\r\n"     
			else
				exportString = exportString .. "\t\t\t<note />\r\n"
			end
			
			if (itemRarity) then
				exportString = exportString .. "\t\t\t<rarity>" .. itemRarity .. "</rarity>\r\n"
			else
				exportString = exportString .. "\t\t\t<rarity />\r\n"
			end
			
			if (itemLevel) then
				exportString = exportString .. "\t\t\t<level>" .. itemLevel .. "</level>\r\n"
			else
				exportString = exportString .. "\t\t\t<level />\r\n"
			end
			
			if (itemType) then
				exportString = exportString .. "\t\t\t<type>" .. itemType .. "</type>\r\n"
			else
				exportString = exportString .. "\t\t\t<type />\r\n"
			end

			if (itemSubType) then
				exportString = exportString .. "\t\t\t<subType>" .. itemSubType .. "</subType>\r\n"
			else
				exportString = exportString .. "\t\t\t<subType />\r\n"
			end

			if (itemTexture) then
				exportString = exportString .. "\t\t\t<texture>" .. itemTexture .. "</texture>\r\n"
			else
				exportString = exportString .. "\t\t\t<texture />\r\n"
			end
			
			exportString = exportString .. "\t\t</item>\r\n"
		end     
	
		exportString = exportString .. "\t</loot>\r\n"
	else
		exportString = exportString .. "\t<loot />\r\n"
	end
   
	exportString = exportString .. "</raid>\r\n" 	
	
	return exportString
end

-- Export a given raid in CSV format
-- @param raid The raid
-- @return string Returns the exported CSV string
function HeadCount:exportCSV(raid)
	assert(raid, "Unable to export the raid into CSV format because the raid is nil.")
   
	local exportString = ""   -- initialize as empty string
   
	local zone = raid:getZone()
    local difficulty = raid:getDifficulty()
	local difficultyString = HeadCount.INSTANCE_DIFFICULTY[difficulty]
	
    local raidStartTime = raid:retrieveStartingTime()
    local raidEndTime = raid:retrieveEndingTime()      

    -- output the field list
    exportString = L["Zone"] .. "," .. L["Difficulty"] .. "," .. L["Date"] .. "," .. L["Length"] .. "," .. L["Player"] .. "," .. L["Raid list time"] .. "," .. L["Wait list time"] .. "," .. L["Offline time"] .. "," .. L["Loot"] .. "\r\n"
   
    local orderedPlayerList = raid:retrieveOrderedPlayerList("Name", true, true, true, false, false, true)   
	if ((# orderedPlayerList) > 0) then
		for k,v in ipairs(orderedPlayerList) do
			local raidListTime = v:getRaidListTime()
			local waitListTime = v:getWaitListTime()
			local offlineTime = v:getOfflineTime()  
			local playerName = v:getName()
			
			-- zone
			if (zone) then
				exportString = exportString .. "\"" .. zone .. "\","
			else
				exportString = exportString .. "\"" .. L["None"] .. "\","
			end
			
			-- difficulty
			if (difficultyString and HeadCount.INSTANCES[zone].hasMultiDifficulty) then 
				exportString = exportString .. "\"" .. difficultyString .. "\","
			else
				exportString = exportString .. "\"" .. L["None"] .. "\","
			end

			-- date
			exportString = exportString .. HeadCount:getDateAsString(raidStartTime) .. ","
			
			-- length
			local timeDifference = HeadCount:computeTimeDifference(raidEndTime, raidStartTime)
			exportString = exportString .. HeadCount:getSecondsAsString(timeDifference) .. ","

			-- player name
			exportString = exportString .. "\"" .. playerName .. "\","
			
			-- raid list time
			exportString = exportString .. HeadCount:getSecondsAsString(raidListTime) .. ","
			
			-- wait list time
			exportString = exportString .. HeadCount:getSecondsAsString(waitListTime) .. ","
			
			-- offline time
			exportString = exportString .. HeadCount:getSecondsAsString(offlineTime) .. ","
			
			-- loot
			--"Loot,cost;Loot,cost;Loot,cost"
			local lootList = raid:getLootListByPlayer(playerName)
			if ((lootList) and (# lootList > 0)) then
				exportString = exportString .. "\""
				for k,v in ipairs(lootList) do 	
					local lootName = v:getName()
					local lootCost = v:getCost()

					if (lootName) then 
						if (lootCost) then
							exportString = exportString .. lootName .. "," .. lootCost .. ";"
						else
							exportString = exportString .. lootName .. ",0;"
						end
					end
				end
				exportString = exportString .. "\"\r\n"
			else
				exportString = exportString .. "\"" .. L["None"] .. "\"\r\n"
			end			
      end
   end   
   
   return exportString
end 

-- Export a given raid in phpBB format with item stats
-- @param raid The raid
-- @return string Returns the exported phpBB string
function HeadCount:exportPhpBBItemStats(raid) 
    assert(raid, "Unable to export the raid into phpBB format because the raid is nil.")
	
	local exportString = ""	-- initialize as empty string
	
	local zone = raid:getZone()
    local difficulty = raid:getDifficulty()
	local difficultyString = HeadCount.INSTANCE_DIFFICULTY[difficulty]
	if (zone) then
		if (difficultyString and HeadCount.INSTANCES[zone].hasMultiDifficulty) then
			exportString = exportString .. "[b][u]" .. zone .. " (" .. difficultyString .. ")[/u][/b]\r\n"   
		else
			exportString = exportString .. "[b][u]" .. zone .. "[/u][/b]\r\n"   
		end
	end 
		
    local raidStartTime = raid:retrieveStartingTime()
    local raidEndTime = raid:retrieveEndingTime()		
	exportString = exportString .. "[i]" .. HeadCount:getDateTimeAsString(raidStartTime) .. " - " .. HeadCount:getDateTimeAsString(raidEndTime) .."[/i]\r\n\r\n"
	
    local orderedPlayerList = raid:retrieveOrderedPlayerList("Name", true, true, true, false, false, true)	
    exportString = exportString .. "[b]" .. L["Players"] .. ":[/b]\r\n"
	if ((# orderedPlayerList) > 0) then 
		exportString = exportString .. "[list]\r\n"
		for k,v in ipairs(orderedPlayerList) do
			local waitTime = v:getWaitListTime()
			local offlineTime = v:getOfflineTime()		
			local className = v:getClassName()
			if (className) then 
				exportString = exportString .. "[*]" .. v:getName() .. " [i](" .. className .. ")[/i]\r\n"
			else
				exportString = exportString .. "[*]" .. v:getName() .. "\r\n"
			end			
			exportString = exportString .. "[i]" .. L["Raid"] .. ": " .. HeadCount:getSecondsAsString(v:getRaidListTime()) .. ", [/i]"
			exportString = exportString .. "[i]" .. L["Standby"] .. ": " .. HeadCount:getSecondsAsString(v:getWaitListTime()) .. ", [/i]"
			exportString = exportString .. "[i]" .. L["Offline"] .. ": " .. HeadCount:getSecondsAsString(v:getOfflineTime()) .. "[/i]\r\n"
		end
		exportString = exportString .. "[/list]\r\n\r\n"
	else
		exportString = exportString .. L["None"] .. "\r\n\r\n"
	end

    if (raid:getBossList()) then
        -- boss list is present	
		exportString = exportString .. "[b]" .. L["Boss kills"] .. ":[/b]\r\n"
        local orderedBossList = raid:retrieveOrderedBossList()
		
		if ((# orderedBossList) > 0) then
			exportString = exportString .. "[list]\r\n"		
			for k,v in ipairs(orderedBossList) do
				exportString = exportString .. "[*]" .. v:getName() .. " at " .. HeadCount:getDateTimeAsString(v:getActivityTime()) .. "\r\n"
			end
			exportString = exportString .. "[/list]\r\n\r\n"
		else
			exportString = exportString .. L["None"] .. "\r\n\r\n"
		end
    end

	local lootList = raid:getLootList()
    exportString = exportString .. "[b]" .. L["Loot"] .. ":[/b]\r\n"
    
	if ((# lootList) > 0) then
		exportString = exportString .. "[list]\r\n"	
	    for k,v in ipairs(raid:getLootList()) do
			local lootName = v:getName()
			
			local cost = v:getCost()
			if (not cost) then
				cost = 0
			end
			
			local color = HeadCount:retrieveItemColor(v:getRarity())
			if (lootName) then
				exportString = exportString .. "[*] [item]" .. lootName .. "[/item] by " .. v:getPlayerName() .. " (Cost: " .. cost .. ")"
			else
				exportString = exportString .. "[*] " .. L["Item unavailable"] .. " by " .. v:getPlayerName() .. " (Cost: " .. cost.. ")"		
			end	
			
			local lootNote = v:getNote()
			if ((lootNote) and (HeadCount:isString(lootNote))) then
				exportString = exportString .. " - " .. lootNote
			end
			
			exportString = exportString .. "\r\n"
	    end
	    exportString = exportString .. "[/list]\r\n"	
	else
		exportString = exportString .. L["None"] .. "\r\n"	
	end
	
	return exportString
end

-- Export a given raid in phpBB format
-- @param raid The raid
-- @return string Returns the exported phpBB string
function HeadCount:exportPhpBB(raid) 
	assert(raid, "Unable to export the raid into phpBB format because the raid is nil.")
	
	local exportString = ""	-- initialize as empty string
	
	local zone = raid:getZone()
    local difficulty = raid:getDifficulty()
	local difficultyString = HeadCount.INSTANCE_DIFFICULTY[difficulty]
	if (zone) then
		if (difficultyString and HeadCount.INSTANCES[zone].hasMultiDifficulty) then
			exportString = exportString .. "[b][u]" .. zone .. " (" .. difficultyString .. ")[/u][/b]\r\n"   
		else
			exportString = exportString .. "[b][u]" .. zone .. "[/u][/b]\r\n"   
		end
	end 		
		
    local raidStartTime = raid:retrieveStartingTime()
    local raidEndTime = raid:retrieveEndingTime()		
	exportString = exportString .. "[i]" .. HeadCount:getDateTimeAsString(raidStartTime) .. " - " .. HeadCount:getDateTimeAsString(raidEndTime) .."[/i]\r\n\r\n"
	
    local orderedPlayerList = raid:retrieveOrderedPlayerList("Name", true, true, true, false, false, true)	
    exportString = exportString .. "[b]" .. L["Players"] .. ":[/b]\r\n"
	if ((# orderedPlayerList) > 0) then 
		exportString = exportString .. "[list]\r\n"
		for k,v in ipairs(orderedPlayerList) do
			local waitTime = v:getWaitListTime()
			local offlineTime = v:getOfflineTime()	
			local className = v:getClassName()
			
			if (className) then 
				exportString = exportString .. "[*]" .. v:getName() .. " [i](" .. className .. ")[/i]\r\n"
			else
				exportString = exportString .. "[*]" .. v:getName() .. "\r\n"
			end			
			exportString = exportString .. "[i]" .. L["Raid"] .. ": " .. HeadCount:getSecondsAsString(v:getRaidListTime()) .. ", [/i]"
			exportString = exportString .. "[i]" .. L["Standby"] .. ": " .. HeadCount:getSecondsAsString(v:getWaitListTime()) .. ", [/i]"
			exportString = exportString .. "[i]" .. L["Offline"] .. ": " .. HeadCount:getSecondsAsString(v:getOfflineTime()) .. "[/i]\r\n"
		end
		exportString = exportString .. "[/list]\r\n\r\n"
	else
		exportString = exportString .. L["None"] .. "\r\n\r\n"
	end

    if (raid:getBossList()) then
        -- boss list is present	
		exportString = exportString .. "[b]" .. L["Boss kills"] .. ":[/b]\r\n"
        local orderedBossList = raid:retrieveOrderedBossList()
		
		if ((# orderedBossList) > 0) then
			exportString = exportString .. "[list]\r\n"		
			for k,v in ipairs(orderedBossList) do
				exportString = exportString .. "[*]" .. v:getName() .. " at " .. HeadCount:getDateTimeAsString(v:getActivityTime()) .. "\r\n"
			end
			exportString = exportString .. "[/list]\r\n\r\n"
		else
			exportString = exportString .. L["None"] .. "\r\n\r\n"
		end
    end

	local lootList = raid:getLootList()
    exportString = exportString .. "[b]" .. L["Loot"] .. ":[/b]\r\n"
    
	if ((# lootList) > 0) then
		exportString = exportString .. "[list]\r\n"	
	    for k,v in ipairs(raid:getLootList()) do
			local lootName = v:getName()
			
			local cost = v:getCost()
			if (not cost) then
				cost = 0
			end
			
			local color = HeadCount:retrieveItemColor(v:getRarity())
			if (lootName) then
				exportString = exportString .. "[*] [url=http://www.wowhead.com/?item=" .. v:getItemId() .. "][color=#" .. color .. "][b]" .. lootName .. "[/b][/color][/url] by " .. v:getPlayerName() .. " (Cost: " .. cost .. ")"
			else
				exportString = exportString .. "[*] [url=http://www.wowhead.com/?item=" .. v:getItemId() .. "][b]" .. L["Item unavailable"] .. "[/b][/url] by " .. v:getPlayerName() .. " (Cost: " .. cost .. ")"		
			end	
			
			local lootNote = v:getNote()
			if ((lootNote) and (HeadCount:isString(lootNote))) then
				exportString = exportString .. " - " .. lootNote
			end
			
			exportString = exportString .. "\r\n"			
	    end
	    exportString = exportString .. "[/list]\r\n"	
	else
		exportString = exportString .. L["None"] .. "\r\n"	
	end
	
	return exportString
end

-- Export a given raid into DKPBoard format.
-- @param raid The raid.
-- @return string Returns the exported DKPBoard string
function HeadCount:exportDKPBoard(raid)
	assert(raid, "Unable to export the raid into DKPBoard format because the raid is nil.")
	
	local exportString = ""   -- initialize as empty string	
	
    local raidStartTime = raid:retrieveStartingTime()    -- raid start time
    local raidEndTime = raid:retrieveEndingTime()        -- raid end time

    local exportString = "<RaidInfo>"    
    exportString = exportString .. "<key>" .. HeadCount:getEQdkpDateTimeAsString(raidStartTime) .. "</key>"
    exportString = exportString .. "<start>" .. HeadCount:getEQdkpDateTimeAsString(raidStartTime)  .. "</start>"
    exportString = exportString .. "<end>" .. HeadCount:getEQdkpDateTimeAsString(raidEndTime) .. "</end>"        

    local orderedPlayerList = raid:retrieveOrderedPlayerList("Name", true, true, true, false, false, true)         
    exportString = exportString .. "<Raiders>"
    for k,v in ipairs(orderedPlayerList) do
		local race = v:getRace()
		local guild = v:getGuild()
		local sex = v:getSex()
		
        exportString = exportString .. "<Raider>"
        exportString = exportString .. "<name>" .. v:getName() .. "</name>"
		if (race) then 
			exportString = exportString .. "<race>" .. race .. "</race>"
		end        
        if (guild) then
            exportString = exportString .. "<guild>" .. guild .. "</guild>"
        end
		if (sex) then
			exportString = exportString .. "<sex>" .. sex .. "</sex>"
		end
		
		local convertedClassName = HeadCount:convertToEQdkpClassName(v:getClassName()) 
        exportString = exportString .. "<class>" ..  convertedClassName .. "</class>"
        if (v:getLevel() > 0) then
            exportString = exportString .. "<level>" .. v:getLevel() .. "</level>"
        else
            exportString = exportString .. "<level>" .. HeadCount.DEFAULT_LEVEL .. "</level>"
        end
            
        exportString = exportString .. "<join>" ..HeadCount:getEQdkpDateTimeAsString(v:retrieveStartingTime()) .. "</join>"
        exportString = exportString .. "<leave>" .. HeadCount:getEQdkpDateTimeAsString(v:retrieveEndingTime()) .. "</leave>"
        
        local waitListTime = v:getWaitListTime()
        local offlineTime = v:getOfflineTime()
        local raidListTime = v:getRaidListTime()
        
        exportString = exportString .. "<offlinetime>" .. HeadCount:getSecondsAsString(offlineTime) .. "</offlinetime>"
        exportString = exportString .. "<waittime>" .. HeadCount:getSecondsAsString(waitListTime) .. "</waittime>"
        exportString = exportString .. "<onlinetime>" .. HeadCount:getSecondsAsString(raidListTime) .. "</onlinetime>"
        
        exportString = exportString .. "</Raider>"
    end
    exportString = exportString .. "</Raiders>"

    exportString = exportString .. "<BossKills>"
    if (raid:getBossList()) then
        -- boss list is present
        local orderedBossList = raid:retrieveOrderedBossList()
        for k,v in ipairs(orderedBossList) do
            exportString = exportString .. "<Boss>"
            exportString = exportString .. "<name>" .. v:getName() .. "</name>"
            exportString = exportString .. "<time>" .. HeadCount:getEQdkpDateTimeAsString(v:getActivityTime()) .. "</time>"
            exportString = exportString .. "<participants>"
            
            local attendeeList = v:getPlayerList()
            for attendeeIndex,attendeeName in ipairs(attendeeList) do
                exportString = exportString .. "<participant>".. attendeeName .."</participant>"
            end
            
            exportString = exportString .. "</participants>"
            exportString = exportString .. "</Boss>"
        end
    end
    exportString = exportString .. "</BossKills>"
        
    exportString = exportString .. "<Loots>"
    for k,v in ipairs(raid:getLootList()) do
        exportString = exportString .. "<Loot>"
        
        local lootName = v:getName()
        if (lootName) then
            exportString = exportString .. "<ItemName>" .. lootName .. "</ItemName>"
        end
        
        local lootColor = v:retrieveColor()
        if (lootColor) then
            exportString = exportString .. "<Color>" .. lootColor .. "</Color>"
        end
        
        local lootId = v:getItemId()
        if (lootId) then
            exportString = exportString .. "<ItemID>" .. lootId .. "</ItemID>"
        end
        exportString = exportString .. "<Count>" .. v:getQuantity() .. "</Count>"
        exportString = exportString .. "<Buyer>" .. v:getPlayerName() .. "</Buyer>"
        
        local lootCost = v:getCost()
        if (not lootCost) then
            lootCost = 0
        end                
        exportString = exportString .. "<Cost>" .. lootCost .. "</Cost>"
        exportString = exportString .. "<Time>" .. HeadCount:getEQdkpDateTimeAsString(v:getActivityTime()) .. "</Time>"
        
        local lootSource = v:getSource()
        if (lootSource) then
            exportString = exportString .. "<Drop>" .. lootSource .. "</Drop>"
        end
        exportString = exportString .. "</Loot>"            
    end        
    exportString = exportString .. "</Loots>"
        
    exportString = exportString .. "</RaidInfo>"
    
    return exportString    
end 

-- Export a given raid in EQdkp format
-- @param raid The raid
-- @return string Returns the exported EQdkp string
function HeadCount:exportEQdkp(raid) 
	assert(raid, "Unable to export the raid into EQdkp format because the raid is nil.")
	
	local raidStartTime = raid:retrieveStartingTime()	-- raid start time
	local raidEndTime = raid:retrieveEndingTime()		-- raid end time

	local exportString = "<RaidInfo>"	
	exportString = exportString .. "<key>" .. HeadCount:getEQdkpDateTimeAsString(raidStartTime) .. "</key>"
	exportString = exportString .. "<start>" .. HeadCount:getEQdkpDateTimeAsString(raidStartTime)  .. "</start>"
	exportString = exportString .. "<end>" .. HeadCount:getEQdkpDateTimeAsString(raidEndTime) .. "</end>"		
	
	local zone = raid:getZone()	-- raid zone
	local difficulty = raid:getDifficulty()	-- raid difficulty
	
	local convertedZone = HeadCount:convertToEQdkpZoneName(zone, difficulty) 
	if (convertedZone) then 
		exportString = exportString .. "<zone>" .. convertedZone .. "</zone>"		
	end

	local orderedPlayerList = raid:retrieveOrderedPlayerList("Name", true, true, true, false, false, true) 		
	exportString = exportString .. "<PlayerInfos>"
	for k,v in ipairs(orderedPlayerList) do
		local race = v:getRace() 
		local sex = v:getSex()
		
		exportString = exportString .. "<key" .. k .. ">"
		exportString = exportString .. "<name>" .. v:getName() .. "</name>"
		if (race) then 
			exportString = exportString .. "<race>" .. race .. "</race>"
		else
			exportString = exportString .. "<race></race>"
		end
		
		if (v:getGuild()) then
			exportString = exportString .. "<guild>" .. v:getGuild() .. "</guild>"
		end
		
		if (sex) then 
			exportString = exportString .. "<sex>" .. v:getSex() .. "</sex>"
		else
			exportString = exportString .. "<sex></sex>"
		end
		
		if (v:getFileName()) then 
			-- new internal class name reference
			exportString = exportString .. "<class>" .. v:getFileName() .. "</class>"
		else
			-- backwards compatibility class name reference
			local convertedClassName = HeadCount:convertToEQdkpClassName(v:getClassName()) 
			exportString = exportString .. "<class>" .. convertedClassName .. "</class>"
		end
		
		if (v:getLevel() > 0) then
			exportString = exportString .. "<level>" .. v:getLevel() .. "</level>"
		else
			exportString = exportString .. "<level>" .. HeadCount.DEFAULT_LEVEL .. "</level>"
		end
		
		exportString = exportString .. "</key" .. k .. ">"
	end
	exportString = exportString .. "</PlayerInfos>"

	-- <BossKills>
	-- 	<key1><name>%bossname%</name><time>%date%</time><attendees><key1><name>%playername1%</name><name>%playername2%</name></key1></attendees></key1>
	-- 	<key2><name>%bossname%</name><time>%date%</time><attendees><key1><name>%playername1%</name><name>%playername2%</name></key1></attendees></key2>	
	-- </BossKills>	
	exportString = exportString .. "<BossKills>"
	if (raid:getBossList()) then 
		-- boss list is present
		local orderedBossList = raid:retrieveOrderedBossList()
		for k,v in ipairs(orderedBossList) do 
			exportString = exportString .. "<key" .. k .. ">"
			exportString = exportString .. "<name>" .. v:getName() .. "</name>"
			exportString = exportString .. "<time>" .. HeadCount:getEQdkpDateTimeAsString(v:getActivityTime()) .. "</time>"
			exportString = exportString .. "<attendees>"
			
			local attendeeList = v:getPlayerList()
			for attendeeIndex,attendeeName in ipairs(attendeeList) do
				exportString = exportString .. "<key" .. attendeeIndex .. ">"
				exportString = exportString .. "<name>" .. attendeeName .. "</name>"
				exportString = exportString .. "</key" .. attendeeIndex .. ">"
			end
			
			exportString = exportString .. "</attendees>"
			exportString = exportString .. "</key" .. k .. ">"
		end
	end
	exportString = exportString .. "</BossKills>"		
		
	if (convertedZone) then 
		exportString = exportString .. "<note><![CDATA[ - Zone: " .. convertedZone .. "]]></note>"	
	else
		exportString = exportString .. "<note></note>"
	end
		
	exportString = exportString .. "<Join>"
	for k,v in ipairs(orderedPlayerList) do
		local race = v:getRace()
		local sex = v:getSex()

		exportString = exportString .. "<key" .. k .. ">"
		exportString = exportString .. "<player>" .. v:getName() .. "</player>"
		if (race) then 
			exportString = exportString .. "<race>" .. race .. "</race>"
		else
			exportString = exportString .. "<race></race>"
		end
		
		if (v:getFileName()) then 
			-- new internal class name reference
			exportString = exportString .. "<class>" .. v:getFileName() .. "</class>"
		else
			-- backwards compatibility class name reference
			local convertedClassName = HeadCount:convertToEQdkpClassName(v:getClassName()) 
			exportString = exportString .. "<class>" .. convertedClassName .. "</class>"
		end
	
		if (sex) then 
			exportString = exportString .. "<sex>" .. sex .. "</sex>"			
		else
			exportString = exportString .. "<sex></sex>"			
		end
		
		if (v:getLevel() > 0) then
			exportString = exportString .. "<level>" .. v:getLevel() .. "</level>"
		else
			exportString = exportString .. "<level>" .. HeadCount.DEFAULT_LEVEL .. "</level>"
		end
		
		exportString = exportString .. "<time>" ..HeadCount:getEQdkpDateTimeAsString(v:retrieveStartingTime()) .. "</time>"			
		exportString = exportString .. "</key" .. k .. ">"
	end		
	exportString = exportString .. "</Join>"

	exportString = exportString .. "<Leave>"
	for k,v in ipairs(orderedPlayerList) do
		exportString = exportString .. "<key" .. k .. ">"
		exportString = exportString .. "<player>" .. v:getName() .. "</player>"			
		exportString = exportString .. "<time>" .. HeadCount:getEQdkpDateTimeAsString(v:retrieveEndingTime()) .. "</time>"
		exportString = exportString .. "</key" .. k .. ">"
	end		
	exportString = exportString .. "</Leave>"
		
	exportString = exportString .. "<Loot>"
	for k,v in ipairs(raid:getLootList()) do
		exportString = exportString .. "<key" .. k .. ">"
		
		local lootName = v:getName()
		if (lootName) then
			exportString = exportString .. "<ItemName>" .. lootName .. "</ItemName>"
		end
		
		local lootId = v:getItemId() 
		if (lootId) then
			exportString = exportString .. "<ItemID>" .. lootId .. "</ItemID>" 
		end
		
		local textureIcon = v:retrieveTextureIcon()
		if (textureIcon) then 
			exportString = exportString .. "<Icon>" .. textureIcon .. "</Icon>" 
		end
		
		local lootItemType = v:getItemType()
		if (lootItemType) then
			exportString = exportString .. "<Class>" .. lootItemType .. "</Class>"
		end
		
		local lootItemSubType = v:getItemSubType()
		if (lootItemSubType) then
			exportString = exportString .. "<SubClass>" .. lootItemSubType .. "</SubClass>"
		end
		
		local lootColor = v:retrieveColor()
		if (lootColor) then
			exportString = exportString .. "<Color>" .. lootColor .. "</Color>"
		end
		exportString = exportString .. "<Count>" .. v:getQuantity() .. "</Count>"
		exportString = exportString .. "<Player>" .. v:getPlayerName() .. "</Player>"
		
		local lootCost = v:getCost()
		if (not lootCost) then
			lootCost = 0
		end				
		exportString = exportString .. "<Costs>" .. lootCost .. "</Costs>"
		exportString = exportString .. "<Time>" .. HeadCount:getEQdkpDateTimeAsString(v:getActivityTime()) .. "</Time>"
		
		local noteElementContent = "<![CDATA["	
		local lootNote = v:getNote()
		if ((lootNote) and (HeadCount:isString(lootNote))) then
			-- loot note is present
			noteElementContent = noteElementContent .. lootNote
		end
		
		local lootZone = v:getZone()	-- ignore for now, difficulty should be determined when loot zone is determined
		if (convertedZone) then 
			-- loot zone present
			noteElementContent = noteElementContent .. " - Zone: " .. convertedZone	-- add to note
			exportString = exportString .. "<Zone>" .. convertedZone .. "</Zone>"	
		else
			exportString = exportString .. "<Zone />"
		end			
		
		local lootSource = v:getSource()
		if (lootSource) then
			-- loot source present
			noteElementContent = noteElementContent .. " - Boss: " .. lootSource -- add to note
			exportString = exportString .. "<Boss>" .. lootSource .. "</Boss>"
		else
			exportString = exportString .. "<Boss />"
		end
		
		noteElementContent = noteElementContent .. " - " .. lootCost .. " DKP]]>"	-- add cost to note
		exportString = exportString .. "<Note>" .. noteElementContent .. "</Note>"
		exportString = exportString .. "</key" .. k .. ">"			
	end		
	exportString = exportString .. "</Loot>"
		
	exportString = exportString .. "</RaidInfo>"
	
	return exportString	
end

-- Gets the date and time as a EQdkp string
-- @param activityTime The activity time.
-- @return string Returns the display date and time as a EQdkp string
function HeadCount:getEQdkpDateTimeAsString(activityTime) 
	local dateTimeString = nil
		
	if (activityTime) then 
		local currentSeconds = activityTime:getUTCDateTimeInSeconds()		-- UTC date and time in seconds

		local displayTimezoneDifferenceInSeconds = HeadCount:GetTimezone() * 60 * 60 -- seconds
		currentSeconds = currentSeconds + displayTimezoneDifferenceInSeconds			 -- display time in seconds
		local displayDateTime = date("*t", currentSeconds)
		
		assert(displayDateTime.year >= 1000, "HeadCount does not support low-value years.")
		local millenium = math.floor(displayDateTime.year / 1000)
		local year = displayDateTime.year - (millenium * 1000)

		dateTimeString =  string.format("%02d", displayDateTime.month) .. "/" .. string.format("%02d", displayDateTime.day) .. "/" .. string.format("%02d", year) .. " " .. string.format("%02d", displayDateTime.hour) .. ":" .. string.format("%02d", displayDateTime.min) .. ":" .. string.format("%02d", displayDateTime.sec)			
	end
	
	return dateTimeString
end

-- Converts the zone name to a zone name with a difficulty label if applicable.
-- @param zone The zone name.
-- @param difficulty The difficulty level
-- @return string Returns the converted zone name or the zone name if no conversion could be made
function HeadCount:convertToEQdkpZoneName(zone, difficulty) 
	local convertedZone = nil
	local isDifficultyLabelEnabled = HeadCount:IsEQDKPDifficultyEnabled()
	
	if (zone) then
		-- zone is valid
		local isDifficultyLabelValid = (difficulty) and (HeadCount.INSTANCES[zone]) and (HeadCount.INSTANCES[zone].players[difficulty]) and (isDifficultyLabelEnabled)
		if (isDifficultyLabelValid) then 
			-- difficulty is valid
			-- zone is in the supported instances list
			-- zone is a heroic-enabled raid
			-- EQdkp difficulty label is enabled
			if (HeadCount.INSTANCES[zone].hasMultiDifficulty) then
				convertedZone = zone .. " (" .. HeadCount.INSTANCES[zone].players[difficulty] .. ")"
			else
				convertedZone = zone
			end
		else
			-- converted zone is the zone name
			convertedZone = zone
		end
	end
	
	return convertedZone
end

-- Converts the class name to an EQdkp class name
-- @param className The class name.
-- @return string Returns the EQdkp class name
function HeadCount:convertToEQdkpClassName(className) 
	local convertedClassName = ""
	
	if (className) then
		local trimmedClassName = string.gsub(className, "%s", "")	-- trim all whitespace (leading, internal, trailing)
		convertedClassName = string.upper(trimmedClassName)			-- convert the string to uppercase
	end	
	
	return convertedClassName
end



