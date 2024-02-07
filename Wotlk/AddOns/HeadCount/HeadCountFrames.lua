--[[
Project name: HeadCount
Developed by: seppyk
Website: http://www.wowace.com/projects/head-count/
Description: Manages tracking of raid attendance and more.
License: All Rights Reserved unless otherwise explicitly stated. 
File: HeadCountFrames.lua
File description: GUI application logic
]]


local L = AceLibrary("AceLocale-2.2"):new("HeadCount")
local dewdrop = AceLibrary("Dewdrop-2.0")
local HeadCount = HeadCount

local content = {
	["boss"] = "Raid bosses", 
	["raid"] = "Raid members",
	["waitlist"] = "Wait list", 
	["loot"] = "Raid loot", 
	["player"] = "Player", 
	["snapshot"] = "Snapshot", 
	["default"] = "Default", 
}

local confirmType = {
	["boss"] = "boss", 
	["raid"] = "raid", 
	["member"] = "member", 
	["waitlist"] = "waitlist", 
	["loot"] = "loot", 
	["endraid"] = "endraid", 
	["removeall"] = "removeall", 
	["snapshot"] = "snapshot", 
}

-- ***********************************
-- MAIN FUNCTIONS
-- ***********************************
-- Main update process
function HeadCount:HeadCountFrame_Update()
	-- Update everything
	HeadCount:HeadCountFrameRaidHistoryContentScroll_Update()

	if (HeadCountFrame.contentType == content["raid"]) then
		-- members
		HeadCount:HeadCountFrameContentMembersScroll_Update()
		HeadCountFrameContentPlayer:Hide()
		HeadCountFrameContentWaitList:Hide()
		HeadCountFrameContentBoss:Hide()
		HeadCountFrameContentSnapshot:Hide() 			
		HeadCountFrameContentLoot:Hide()		
		HeadCountFrameContentMembers:Show()		
	elseif (HeadCountFrame.contentType == content["boss"]) then 
		-- bosses
		HeadCount:HeadCountFrameContentBossScroll_Update()		
		HeadCountFrameContentMembers:Hide()		
		HeadCountFrameContentPlayer:Hide()
		HeadCountFrameContentWaitList:Hide()
		HeadCountFrameContentSnapshot:Hide() 			
		HeadCountFrameContentLoot:Hide()				
		HeadCountFrameContentBoss:Show()		
	elseif (HeadCountFrame.contentType == content["loot"]) then 
		-- loot
		HeadCount:HeadCountFrameContentLootScroll_Update()		
		HeadCountFrameContentMembers:Hide()		
		HeadCountFrameContentPlayer:Hide()
		HeadCountFrameContentWaitList:Hide()
		HeadCountFrameContentBoss:Hide()		
		HeadCountFrameContentSnapshot:Hide() 			
		HeadCountFrameContentLoot:Show()		
	elseif (HeadCountFrame.contentType == content["waitlist"]) then
		-- wait list
		HeadCount:HeadCountFrameContentWaitListScroll_Update()		
		HeadCountFrameContentMembers:Hide()
		HeadCountFrameContentPlayer:Hide() 		
		HeadCountFrameContentBoss:Hide()		
		HeadCountFrameContentSnapshot:Hide() 			
		HeadCountFrameContentLoot:Hide()			
		HeadCountFrameContentWaitList:Show()
	elseif (HeadCountFrame.contentType == content["player"]) then
		-- player information
		HeadCount:HeadCountFrameContentPlayerScroll_Update()		
		HeadCountFrameContentMembers:Hide()
		HeadCountFrameContentWaitList:Hide()
		HeadCountFrameContentBoss:Hide()		
		HeadCountFrameContentSnapshot:Hide() 			
		HeadCountFrameContentLoot:Hide()			
		HeadCountFrameContentPlayer:Show() 
	elseif (HeadCountFrame.contentType == content["snapshot"]) then
		HeadCount:HeadCountFrameContentSnapshotScroll_Update()		
		HeadCountFrameContentMembers:Hide()
		HeadCountFrameContentPlayer:Hide() 	
		HeadCountFrameContentWaitList:Hide()
		HeadCountFrameContentBoss:Hide()		
		HeadCountFrameContentLoot:Hide()				
		HeadCountFrameContentSnapshot:Show() 	
	else
		-- default, hide all content frames
		HeadCountFrameContentMembers:Hide()
		HeadCountFrameContentPlayer:Hide()
		HeadCountFrameContentWaitList:Hide()
		HeadCountFrameContentBoss:Hide()
		HeadCountFrameContentSnapshot:Hide() 			
		HeadCountFrameContentLoot:Hide()							 	
		HeadCount:HeadCountFrameContentTitleString_Show()
	end
end

-- Hide the user interface
function HeadCount:HideUserInterface()
	HeadCount:DisableModalFrame()
	
	-- close all frames	
	HeadCountFrame:Hide()	-- close the main frame
	dewdrop:Close()			-- close menus
end

-- Show the user interface
function HeadCount:ShowUserInterface()
	-- show the main frame
	HeadCountFrame:Show()
end

-- Toggle the user interface
function HeadCount:ToggleUserInterface()
	if (HeadCountFrame:IsVisible()) then
		-- frame is visible, hide it
		HeadCount:HideUserInterface()
	else
		HeadCount:ShowUserInterface()
	end
end

-- Enable to modal frame (remove/export)
function HeadCount:EnableModalFrame() 
	HeadCountFrame.isDialogDisplayed = true		
end

-- Disable to modal frame (remove/export)
function HeadCount:DisableModalFrame() 
	HeadCountFrame.isDialogDisplayed = false
	HeadCountFrameConfirm:Hide()
	HeadCountFrameExport:Hide()
	HeadCountFrameLootManagement:Hide()
	HeadCountFrameAnnouncement:Hide()
	
	dewdrop:Close() -- close menus
end


-- ***********************************
-- ON LOAD FUNCTIONS
-- ***********************************
-- ON LOAD: Main frame
function HeadCount:HeadCountFrame_Load()	

end

-- ON LOAD: Loot management popup
function HeadCount:HeadCountFrameLootManagementPopup_Load()
	HeadCountFrame.isLootPopupDisplayed = false
	HeadCountFrame.lootPopupQueue = {} 
	
	getglobal(this:GetName() .. "LooterLabel"):SetText(L["Looted by"] .. ": ")
	getglobal(this:GetName() .. "SourceLabel"):SetText(L["Loot source"] .. ": ")
	getglobal(this:GetName() .. "CostLabel"):SetText(L["Loot cost"] .. ": ")
	getglobal(this:GetName() .. "NoteLabel"):SetText(L["Loot note"] .. ": ")	
	getglobal(this:GetName() .. "SaveButton"):SetText(L["Save"])
	getglobal(this:GetName() .. "CancelButton"):SetText(L["Close"])	
end

-- ON LOAD: Confirm frame
function HeadCount:HeadCountFrameConfirm_Load()
	HeadCountFrameConfirmConfirmButton:SetText(L["Remove"])
	HeadCountFrameConfirmCancelButton:SetText(L["Cancel"]) 
end

-- ON LOAD: Export frame
function HeadCount:HeadCountFrameExport_Load() 
	HeadCountFrameExportRefreshButton:SetText(L["Refresh"])
	HeadCountFrameExportCloseButton:SetText(L["Close"])
end

-- ON LOAD: Loot management frame
function HeadCount:HeadCountFrameLootManagementTemplate_Load()
	getglobal(this:GetName() .. "LooterLabel"):SetText(L["Looted by"] .. ": ")
	getglobal(this:GetName() .. "SourceLabel"):SetText(L["Loot source"] .. ": ")
	getglobal(this:GetName() .. "CostLabel"):SetText(L["Loot cost"] .. ": ")
	getglobal(this:GetName() .. "NoteLabel"):SetText(L["Loot note"] .. ": ")		
	getglobal(this:GetName() .. "SaveButton"):SetText(L["Save"])
	getglobal(this:GetName() .. "CancelButton"):SetText(L["Cancel"])		
end

-- ON LOAD: Raid announcement frame
function HeadCount:HeadCountFrameAnnouncement_Load()
	HeadCountFrameAnnouncementTitleString:SetText(L["Raid announcement"])
	HeadCountFrameAnnouncementTypeLabel:SetText(L["Type"] .. ": ")
	HeadCountFrameAnnouncementChannelLabel:SetText(L["Channel"] .. ": ")
	HeadCountFrameAnnouncementAnnounceButton:SetText(L["Announce"])
	HeadCountFrameAnnouncementCancelButton:SetText(L["Cancel"])
end

-- ON LOAD: Main frame
function HeadCount:HeadCountFrame_Load()
	HeadCountFrame.isRaidSelected = false
	HeadCountFrame.selectedRaidId = 0	
	HeadCountFrame.isDialogDisplayed = false
end

-- ON LOAD: Raid history frame
function HeadCount:HeadCountFrameRaidHistory_Load()
	HeadCountFrameRaidHistory:SetBackdropBorderColor(0.8, 0.8, 0.8, 0.8)
	HeadCountFrameRaidHistoryTitleString:SetText(string.format(L["info.raidhistory"], 0))
end

-- ON LOAD: Raid history content frame
function HeadCount:HeadCountFrameRaidHistoryContent_Load()

end

-- ON LOAD: Content frame
function HeadCount:HeadCountFrameContent_Load() 
	HeadCountFrameContent:SetBackdropBorderColor(0.8, 0.8, 0.8, 0.8)
	HeadCountFrame.contentType = content["raid"]
	HeadCountFrameContentTitleString:Hide()
end

-- ON LOAD: Raid members
function HeadCount:HeadCountFrameContentMembers_Load()
	HeadCountFrameContentMembersNameButtonText:SetText(L["Name"])	
	HeadCountFrameContentMembersStartTimeButtonText:SetText(L["Start"])	
	HeadCountFrameContentMembersEndTimeButtonText:SetText(L["End"])	
	HeadCountFrameContentMembersTotalTimeButtonText:SetText(L["Total time"])
	
	HeadCountFrameContentMembers.sortType = "Start"
	HeadCountFrameContentMembers.isDescending = true
end

-- ON LOAD: Player information
function HeadCount:HeadCountFrameContentPlayer_Load() 
	HeadCountFrameContentPlayerBackButtonText:SetText(L["Go back"])
end

-- ON LOAD: Wait list
function HeadCount:HeadCountFrameContentWaitList_Load()
	HeadCountFrameContentWaitListNameButtonText:SetText(L["Name"])	
	HeadCountFrameContentWaitListTimeButtonText:SetText(L["Time"])	
	HeadCountFrameContentWaitListNoteButtonText:SetText(L["Note"])	
	
	HeadCountFrameContentWaitList.sortType = "Waitlist"
	HeadCountFrameContentWaitList.isDescending = true	
end

-- ON LOAD: Raid bosses
function HeadCount:HeadCountFrameContentBoss_Load()
	HeadCountFrameContentBossTimeButtonText:SetText(L["Time"])
	HeadCountFrameContentBossMembersButtonText:SetText(L["Members"])
	HeadCountFrameContentBossNameButtonText:SetText(L["Name"])
end

-- ON LOAD: Snapshot information
function HeadCount:HeadCountFrameContentSnapshot_Load()
	HeadCountFrameContentSnapshotBackButtonText:SetText(L["Go back"])
end

-- ON LOAD: Title head
function HeadCount:HeadCountFrameTitleHeader_Load()
	HeadCountFrameTitleHeaderString:SetText(HeadCount.TITLE)
end

-- ON LOAD: Raid history template
function HeadCount:HeadCountFrameRaidHistoryContentTemplate_Load()
	getglobal(this:GetName() .. "MouseOver"):SetAlpha(0.3)
	getglobal(this:GetName() .. "MouseOver"):SetVertexColor(0.4, 0.4, 1.0)
				
	getglobal(this:GetName() .. "MouseSelect"):SetAlpha(0.6)
	getglobal(this:GetName() .. "MouseSelect"):SetVertexColor(0.4, 0.4, 1.0)
end

-- ON LOAD: Raid members template
function HeadCount:HeadCountFrameContentMembersTemplate_Load()
	getglobal(this:GetName() .. "MouseOver"):SetAlpha(0.3)
	getglobal(this:GetName() .. "MouseOver"):SetVertexColor(0.4, 0.4, 1.0)
end

-- ON LOAD: Raid bosses templates
function HeadCount:HeadCountFrameContentBossTemplate_Load()
	getglobal(this:GetName() .. "MouseOver"):SetAlpha(0.3)
	getglobal(this:GetName() .. "MouseOver"):SetVertexColor(0.4, 0.4, 1.0)
end
   
-- ***********************************
-- SCROLL UPDATE FUNCTIONS
-- ***********************************
-- ON UPDATE: Raid history content frame scroller
function HeadCount:HeadCountFrameRaidHistoryContentScroll_Update()
	local lineNumber
	local lineNumberOffset
	--FauxScrollFrame_Update(FRAME, NUMBER_OF_ENTRIES, NUMBER_OF_ENTRIES_DISPLAYED, ENTRY_PIXEL_HEIGHT, button, smallWidth, bigWidtth, highlightFrame, smallHighlightWidth, bigHighlightWidth) 

	local raidTracker = HeadCount:getRaidTracker() 
	local numberOfRaids = raidTracker:getNumberOfRaids()
	FauxScrollFrame_Update(HeadCountFrameRaidHistoryContentScroll, numberOfRaids, 5, 16)
	
	if (numberOfRaids > 0) then	
		local orderedRaidList = raidTracker:retrieveOrderedRaidList(true)	
		
		for lineNumber=1,5 do
			lineNumberOffset = lineNumber + FauxScrollFrame_GetOffset(HeadCountFrameRaidHistoryContentScroll)
			if (lineNumberOffset <= numberOfRaids) then				
				getglobal("HeadCountFrameRaidHistoryContentEntry" .. lineNumber .. "MouseOver"):Hide()
				getglobal("HeadCountFrameRaidHistoryContentEntry" .. lineNumber .. "HitArea"):Show()

				-- Set the raid history line text
				local position = (numberOfRaids + 1) - lineNumberOffset			
				local raid = orderedRaidList[position]
				local raidId = raid:retrieveStartingTime():getUTCDateTimeInSeconds() 
				getglobal("HeadCountFrameRaidHistoryContentEntry" .. lineNumber .. "Id"):SetText(raidId)
				getglobal("HeadCountFrameRaidHistoryContentEntry" .. lineNumber .. "Number"):SetText(position)
				getglobal("HeadCountFrameRaidHistoryContentEntry" .. lineNumber .. "Time"):SetText(HeadCount:getDateTimeAsString(raid:retrieveStartingTime()))
				
				-- Display if the active raid text if it exists
				local zone = raid:getZone()				
				local difficulty = raid:getDifficulty()
				local difficultyString = HeadCount.INSTANCE_DIFFICULTY[difficulty]
				if ((zone) and HeadCount.INSTANCES[zone].hasMultiDifficulty and (difficultyString)) then 
					-- track heroic and above only for display
					zone = zone .. " (" .. difficultyString .. ")"
				end
				
				-- Add active label to zone
				if ((not raid:getIsFinalized()) and (raidTracker:getIsCurrentRaidActive())) then 
					-- raid is not finalized and raid is active
					if (zone) then
						zone = zone .. " (" .. L["Active"] .. ")"
					else
						zone = "(" .. L["Active"] .. ")"
					end
				end
				
				getglobal("HeadCountFrameRaidHistoryContentEntry" .. lineNumber .. "Zone"):SetText(zone)				
				getglobal("HeadCountFrameRaidHistoryContentEntry" .. lineNumber):Show()
				
				-- Set the selected color bar if this raid is selected
				if (HeadCountFrame.selectedRaidId == raidId) then
					-- This line is equivalent to the currently selected raid id
					getglobal("HeadCountFrameRaidHistoryContentEntry" .. lineNumber .. "MouseSelect"):Show()
				else
					-- This line is not equivalent to the currently selected raid id, don't select it
					getglobal("HeadCountFrameRaidHistoryContentEntry" .. lineNumber .. "MouseSelect"):Hide()
				end
			else
				getglobal("HeadCountFrameRaidHistoryContentEntry" .. lineNumber):Hide()
			end
		end
		
		getglobal("HeadCountFrameRaidHistoryContent"):Show()
	else
		-- No raids exist
		getglobal("HeadCountFrameRaidHistoryContent"):Hide()	-- hide the raid history content frame
	end
	
	HeadCountFrameRaidHistoryTitleString:SetText(string.format(L["info.raidhistory"], numberOfRaids))	-- update the amount of raids text string	
end

-- ON UPDATE: Members content frame scroller
function HeadCount:HeadCountFrameContentMembersScroll_Update()
	local lineNumber
	local lineNumberOffset
	local numberOfPlayers = 0
	
	local raidId = HeadCountFrame.selectedRaidId
	local raidTracker = HeadCount:getRaidTracker()
	local raid = raidTracker:getRaidById(raidId)
	
	if (raid) then
		-- raid exists
		numberOfPlayers = raid:getNumberOfPlayers()
		FauxScrollFrame_Update(HeadCountFrameContentMembersScroll, numberOfPlayers, 10, 16)	                                     
		
		if (numberOfPlayers > 0) then	
			-- players exist in this raid
			local orderedPlayerList = raid:retrieveOrderedPlayerList(HeadCount:getRAID_MEMBER_SORT()[HeadCountFrameContentMembers.sortType], true, true, true, false, false, HeadCountFrameContentMembers.isDescending)		

			for lineNumber=1,10 do
				lineNumberOffset = lineNumber + FauxScrollFrame_GetOffset(HeadCountFrameContentMembersScroll)
				if (lineNumberOffset <= numberOfPlayers) then				
					getglobal("HeadCountFrameContentMembersEntry" .. lineNumber .. "MouseOver"):Hide()
					getglobal("HeadCountFrameContentMembersEntry" .. lineNumber .. "HitArea"):Show()
					local player = orderedPlayerList[lineNumberOffset]
					
					getglobal("HeadCountFrameContentMembersEntry" .. lineNumber .. "Number"):SetText(lineNumberOffset)
					getglobal("HeadCountFrameContentMembersEntry" .. lineNumber .. "Name"):SetText(player:getName())
					getglobal("HeadCountFrameContentMembersEntry" .. lineNumber .. "BeginTime"):SetText(HeadCount:getTimeAsString(player:retrieveStartingTime()))
					
					if (player:retrieveEndingTime()) then
						-- end time exists
						getglobal("HeadCountFrameContentMembersEntry" .. lineNumber .. "EndTime"):SetText(HeadCount:getTimeAsString(player:retrieveEndingTime()))
					else
						-- end time not yet set, show nothing
						getglobal("HeadCountFrameContentMembersEntry" .. lineNumber .. "EndTime"):SetText("")
					end
					
					if (raid:getIsFinalized()) then
						-- raid is finalized, show total time
						getglobal("HeadCountFrameContentMembersEntry" .. lineNumber .. "TotalTime"):SetText(HeadCount:getSecondsAsString(player:getTotalTime()))
					else
						-- raid is not finalized show nothing
						getglobal("HeadCountFrameContentMembersEntry" .. lineNumber .. "TotalTime"):SetText("")
					end
					
					getglobal("HeadCountFrameContentMembersEntry" .. lineNumber):Show()
				else
					getglobal("HeadCountFrameContentMembersEntry" .. lineNumber):Hide()
				end
			end
			
			HeadCount:HeadCountFrameContentMembers_Show(true)
		else
			-- players do not exist
			for lineNumber=1,10 do 
				getglobal("HeadCountFrameContentMembersEntry" .. lineNumber):Hide()
			end
			
			HeadCount:HeadCountFrameContentMembers_Show(false)	-- hide the members content frame
		end		
	else
		-- no raid exists under this id
		for lineNumber=1,10 do 
			getglobal("HeadCountFrameContentMembersEntry" .. lineNumber):Hide()
		end
			
		HeadCountFrame.isRaidSelected = false
		HeadCountFrame.selectedRaidId = 0			
		HeadCount:HeadCountFrameContentMembers_Show(false)		-- hide the members content frame
	end
	
	HeadCount:HeadCountFrameContentTitleString_Show()
end

-- ON UPDATE: Raid wait list frame scroller
function HeadCount:HeadCountFrameContentWaitListScroll_Update()
	local lineNumber
	local lineNumberOffset
	local numberOfPlayers = 0
	
	local raidId = HeadCountFrame.selectedRaidId
	local raidTracker = HeadCount:getRaidTracker()
	local raid = raidTracker:getRaidById(raidId)

	if (raid) then
		-- raid exists
		numberOfPlayers = raid:getNumberOfWaitlistPlayers()
		FauxScrollFrame_Update(HeadCountFrameContentWaitListScroll, numberOfPlayers, 10, 16)	 	

		if (numberOfPlayers > 0) then
			-- players exist 
			--HeadCount:LogInformation("Updating wait list: " .. HeadCountFrameContentWaitList.sortType .. " (" .. HeadCount:convertBooleanToString(HeadCountFrameContentWaitList.isDescending) .. ")")
			local orderedPlayerList = raid:retrieveOrderedPlayerList(HeadCount:getRAID_MEMBER_SORT()[HeadCountFrameContentWaitList.sortType], false, false, false, true, false, HeadCountFrameContentWaitList.isDescending)		
		
			for lineNumber=1,10 do
				lineNumberOffset = lineNumber + FauxScrollFrame_GetOffset(HeadCountFrameContentWaitListScroll)
				if (lineNumberOffset <= numberOfPlayers) then			
					local player = orderedPlayerList[lineNumberOffset]
					
					getglobal("HeadCountFrameContentWaitListEntry" .. lineNumber .. "Number"):SetText(lineNumberOffset)
					getglobal("HeadCountFrameContentWaitListEntry" .. lineNumber .. "Name"):SetText(player:getName())
					getglobal("HeadCountFrameContentWaitListEntry" .. lineNumber .. "Time"):SetText(HeadCount:getTimeAsString(player:getWaitlistActivityTime()))
					getglobal("HeadCountFrameContentWaitListEntry" .. lineNumber .. "Note"):SetText(player:getWaitlistNote())
					getglobal("HeadCountFrameContentWaitListEntry" .. lineNumber):Show()
				else
					getglobal("HeadCountFrameContentWaitListEntry" .. lineNumber):Hide()
				end
			end
			
			HeadCount:HeadCountFrameContentWaitList_Show(true)				
		else
			-- no players are present in the wait list
			for lineNumber=1,10 do 
				getglobal("HeadCountFrameContentWaitListEntry" .. lineNumber):Hide()
			end
			
			HeadCount:HeadCountFrameContentWaitList_Show(false)	-- hide the members content frame			
		end
	else
		-- no raid exists under this id
		for lineNumber=1,10 do 
			getglobal("HeadCountFrameContentWaitListEntry" .. lineNumber):Hide()
		end
			
		HeadCountFrame.isRaidSelected = false
		HeadCountFrame.selectedRaidId = 0			
		HeadCount:HeadCountFrameContentWaitList_Show(false)		-- hide the wait list content frame	
	end
	
	HeadCount:HeadCountFrameContentTitleString_Show()
end

-- ON UPDATE: Raid bosses frame scroller
function HeadCount:HeadCountFrameContentBossScroll_Update()
	local lineNumber
	local lineNumberOffset
	local numberOfBosses = 0
	
	local raidId = HeadCountFrame.selectedRaidId
	local raidTracker = HeadCount:getRaidTracker()
	local raid = raidTracker:getRaidById(raidId)
	
	if (raid) then
		-- raid exists
		numberOfBosses = raid:getNumberOfBosses()
		FauxScrollFrame_Update(HeadCountFrameContentBossScroll, numberOfBosses, 10, 16)	                                     
		
		if (numberOfBosses > 0) then	
			-- boss kills exist in this raid
			local orderedBossList = raid:retrieveOrderedBossList()		
			
			for lineNumber=1,10 do
				lineNumberOffset = lineNumber + FauxScrollFrame_GetOffset(HeadCountFrameContentBossScroll)
				if (lineNumberOffset <= numberOfBosses) then				
					getglobal("HeadCountFrameContentBossEntry" .. lineNumber .. "MouseOver"):Hide()
					getglobal("HeadCountFrameContentBossEntry" .. lineNumber .. "HitArea"):Show()
					local boss = orderedBossList[lineNumberOffset]
					
					getglobal("HeadCountFrameContentBossEntry" .. lineNumber .. "Number"):SetText(lineNumberOffset)
					getglobal("HeadCountFrameContentBossEntry" .. lineNumber .. "Time"):SetText(HeadCount:getTimeAsString(boss:getActivityTime()))					
					getglobal("HeadCountFrameContentBossEntry" .. lineNumber .. "Members"):SetText(boss:numberOfPlayers())
					getglobal("HeadCountFrameContentBossEntry" .. lineNumber .. "Name"):SetText(boss:getName())

					getglobal("HeadCountFrameContentBossEntry" .. lineNumber):Show()
				else
					getglobal("HeadCountFrameContentBossEntry" .. lineNumber):Hide()
				end
			end
			
			HeadCount:HeadCountFrameContentBoss_Show(true)
		else
			-- players do not exist
			for lineNumber=1,10 do 
				getglobal("HeadCountFrameContentBossEntry" .. lineNumber):Hide()
			end
			
			HeadCount:HeadCountFrameContentBoss_Show(false)	-- hide the members content frame
		end		
	else
		-- no raid exists under this id
		for lineNumber=1,10 do 
			getglobal("HeadCountFrameContentBossEntry" .. lineNumber):Hide()
		end		
		
		HeadCountFrame.isRaidSelected = false
		HeadCountFrame.selectedRaidId = 0			
		HeadCount:HeadCountFrameContentBoss_Show(false)		-- hide the members content frame
	end
	
	HeadCount:HeadCountFrameContentTitleString_Show()
end

-- ON UPDATE: Loot content frame scroller
function HeadCount:HeadCountFrameContentLootScroll_Update() 
	local lineNumber
	local lineNumberOffset
	
	local raidId = HeadCountFrame.selectedRaidId
	local raidTracker = HeadCount:getRaidTracker()
	local selectedRaid = raidTracker:getRaidById(raidId)
	
	if (selectedRaid) then 
		-- raid exists 
		local numberOfLoots = selectedRaid:numberOfLoots() 
		FauxScrollFrame_Update(HeadCountFrameContentLootScroll, numberOfLoots, 5, 40)	 
		
		if (numberOfLoots > 0) then 
			local lootList = selectedRaid:getLootList() 	
						
			for lineNumber=1,5 do
				lineNumberOffset = lineNumber + FauxScrollFrame_GetOffset(HeadCountFrameContentLootScroll)
				if (lineNumberOffset <= numberOfLoots) then 
					local loot = lootList[lineNumberOffset]
					
					getglobal("HeadCountFrameContentLootEntry" .. lineNumber .. "Id"):SetText(loot:getItemId())
					
					local texture = loot:getTexture()
					if (texture) then
						getglobal("HeadCountFrameContentLootEntry" .. lineNumber .. "TextureButton"):SetNormalTexture(texture)
					else
						getglobal("HeadCountFrameContentLootEntry" .. lineNumber .. "TextureButton"):SetNormalTexture("Interface\Icons\INV_Misc_QuestionMark")
					end
					
					getglobal("HeadCountFrameContentLootEntry" .. lineNumber .. "Number"):SetText(lineNumberOffset)
					
					local link = loot:getLink()
					if (link) then		
						getglobal("HeadCountFrameContentLootEntry" .. lineNumber .. "NameButtonText"):SetText(link)
					else
						getglobal("HeadCountFrameContentLootEntry" .. lineNumber .. "NameButtonText"):SetText(L["Item unavailable"]) 																								 
					end
					
					getglobal("HeadCountFrameContentLootEntry" .. lineNumber .. "Looter"):SetText(L["Looted by"] .. " " .. loot:getPlayerName() .. " (" .. HeadCount:getDateTimeAsString(loot:getActivityTime())  .. ")")
				
					getglobal("HeadCountFrameContentLootEntry" .. lineNumber):Show()
				else
					getglobal("HeadCountFrameContentLootEntry" .. lineNumber):Hide()
				end
			end
			
			HeadCount:HeadCountFrameContentLoot_Show(true)
		else
			for lineNumber=1,5 do 
				getglobal("HeadCountFrameContentLootEntry" .. lineNumber):Hide()
			end
			
			HeadCount:HeadCountFrameContentLoot_Show(false)
		end		
	else
		-- no raid exists under this id 
		for lineNumber=1,5 do 
			getglobal("HeadCountFrameContentLootEntry" .. lineNumber):Hide()
		end		
		
		HeadCountFrame.isRaidSelected = false
		HeadCountFrame.selectedRaidId = 0
		HeadCount:HeadCountFrameContentLoot_Show(false)
	end
	
	HeadCount:HeadCountFrameContentTitleString_Show()
end

-- ON UPDATE: Player content frame scroller
function HeadCount:HeadCountFrameContentPlayerScroll_Update() 
	local lineNumber
	local lineNumberOffset

	local raidId = HeadCountFrame.selectedRaidId
	local raidTracker = HeadCount:getRaidTracker()
	local selectedRaid = raidTracker:getRaidById(raidId)

	if (selectedRaid) then 
		-- raid exists
		local player = selectedRaid:retrievePlayer(HeadCountFrame.playerName)	
		local lootList = selectedRaid:getLootListByPlayer(HeadCountFrame.playerName)
		if ((player) and (lootList)) then 
			local args = { ["player"] = player, ["lootList"] = lootList, }			-- player information object arguments
			local playerInformation = AceLibrary("HeadCountPlayerInformation-1.0"):new(args)	-- create a player information object
		
			local playerInformationList, numberOfPlayerInformationListLines = playerInformation:retrieveInformationList()
		
			FauxScrollFrame_Update(HeadCountFrameContentPlayerScroll, numberOfPlayerInformationListLines, 10, 16)		
		
			for lineNumber=1,10 do
				lineNumberOffset = lineNumber + FauxScrollFrame_GetOffset(HeadCountFrameContentPlayerScroll)
				if (lineNumberOffset <= numberOfPlayerInformationListLines) then			
					getglobal("HeadCountFrameContentPlayerEntry" .. lineNumber .. "SimpleHTML"):SetText(playerInformationList[lineNumberOffset])			
					getglobal("HeadCountFrameContentPlayerEntry" .. lineNumber):Show()
				else
					getglobal("HeadCountFrameContentPlayerEntry" .. lineNumber):Hide()
				end
			end
			
			HeadCountFrameContentPlayerNameString:SetText(player:getName())
			HeadCount:HeadCountFrameContentPlayer_Show(true)			
		else
			-- player does not exist
			for lineNumber=1,10 do 
				getglobal("HeadCountFrameContentPlayerEntry" .. lineNumber):Hide()
			end	
			
			HeadCount:HeadCountFrameContentPlayer_Show(false)		
		end		
	else
		-- raid does not exist
		for lineNumber=1,10 do 
			getglobal("HeadCountFrameContentPlayerEntry" .. lineNumber):Hide()
		end	
		
		HeadCountFrame.isRaidSelected = false
		HeadCountFrame.selectedRaidId = 0					
		HeadCount:HeadCountFrameContentPlayer_Show(false)
	end
	
	HeadCount:HeadCountFrameContentTitleString_Show()
end

-- ON UPDATE: Boss/snapshot frame scroller
function HeadCount:HeadCountFrameContentSnapshotScroll_Update()
	local lineNumber
	local lineNumberOffset

	local raidId = HeadCountFrame.selectedRaidId
	local raidTracker = HeadCount:getRaidTracker()
	local selectedRaid = raidTracker:getRaidById(raidId)	

	if (selectedRaid) then 
		-- raid exists
		local boss = selectedRaid:retrieveBoss(HeadCountFrame.bossName)
		if (boss) then
			local numberOfPlayers = boss:numberOfPlayers()
			local snapshotList = boss:getPlayerList()
			if (numberOfPlayers > 0) then
				FauxScrollFrame_Update(HeadCountFrameContentSnapshotScroll, numberOfPlayers, 10, 16)		
			
				for lineNumber=1,10 do
					lineNumberOffset = lineNumber + FauxScrollFrame_GetOffset(HeadCountFrameContentSnapshotScroll)
					if (lineNumberOffset <= numberOfPlayers) then			
						getglobal("HeadCountFrameContentSnapshotEntry" .. lineNumber .. "Number"):SetText(lineNumberOffset)
						getglobal("HeadCountFrameContentSnapshotEntry" .. lineNumber .. "Name"):SetText(snapshotList[lineNumberOffset])
						getglobal("HeadCountFrameContentSnapshotEntry" .. lineNumber):Show()
					else
						getglobal("HeadCountFrameContentSnapshotEntry" .. lineNumber):Hide()
					end
				end
				
				local description = boss:getName() .. " (" .. HeadCount:getDateTimeAsString(boss:getActivityTime()) .. ")"
				HeadCountFrameContentSnapshotNameString:SetText(description)
				HeadCount:HeadCountFrameContentSnapshot_Show(true)		
			else
				-- no attendees for this boss, show the header (boss name and go back, but show no entries)
				for lineNumber=1,10 do 
					getglobal("HeadCountFrameContentSnapshotEntry" .. lineNumber):Hide()
				end					
			
				local description = boss:getName() .. " (" .. HeadCount:getDateTimeAsString(boss:getActivityTime()) .. ")"
				HeadCountFrameContentSnapshotNameString:SetText(description)			
				HeadCount:HeadCountFrameContentSnapshot_Show(true)					
			end
		else
			-- boss does not exist
			for lineNumber=1,10 do 
				getglobal("HeadCountFrameContentSnapshotEntry" .. lineNumber):Hide()
			end	
			
			HeadCount:HeadCountFrameContentSnapshot_Show(false)		
		end		
	else
		-- raid does not exist
		for lineNumber=1,10 do 
			getglobal("HeadCountFrameContentSnapshotEntry" .. lineNumber):Hide()
		end	
		
		HeadCountFrame.isRaidSelected = false
		HeadCountFrame.selectedRaidId = 0					
		HeadCount:HeadCountFrameContentSnapshot_Show(false)
	end
	
	HeadCount:HeadCountFrameContentTitleString_Show()	
end

-- ***********************************
-- SHOW FUNCTIONS
-- ***********************************
-- SHOW: Toggle display of members content frame
function HeadCount:HeadCountFrameContentMembers_Show(isShowing)
	if (isShowing) then
		getglobal("HeadCountFrameContentMembersNameButton"):Show()			
		getglobal("HeadCountFrameContentMembersStartTimeButton"):Show()			
		getglobal("HeadCountFrameContentMembersEndTimeButton"):Show()				
		getglobal("HeadCountFrameContentMembersTotalTimeButton"):Show()				
	
		getglobal("HeadCountFrameContentMembers"):Show()	
	else
		for lineNumber=1,10 do 
			getglobal("HeadCountFrameContentMembersEntry" .. lineNumber):Hide()
		end
		
		getglobal("HeadCountFrameContentMembersNameButton"):Hide()			
		getglobal("HeadCountFrameContentMembersStartTimeButton"):Hide()			
		getglobal("HeadCountFrameContentMembersEndTimeButton"):Hide()				
		getglobal("HeadCountFrameContentMembersTotalTimeButton"):Hide()				
		
		getglobal("HeadCountFrameContentMembers"):Hide()	
	end
end

-- SHOW: Toggle display of the wait list content frame
function HeadCount:HeadCountFrameContentWaitList_Show(isShowing)
	if (isShowing) then
		getglobal("HeadCountFrameContentWaitListNameButton"):Show()			
		getglobal("HeadCountFrameContentWaitListTimeButton"):Show()			
		getglobal("HeadCountFrameContentWaitListNoteButton"):Show()
	
		getglobal("HeadCountFrameContentWaitList"):Show()	
	else
		for lineNumber=1,10 do 
			getglobal("HeadCountFrameContentWaitListEntry" .. lineNumber):Hide()
		end
		
		getglobal("HeadCountFrameContentWaitListNameButton"):Hide()			
		getglobal("HeadCountFrameContentWaitListTimeButton"):Hide()			
		getglobal("HeadCountFrameContentWaitListNoteButton"):Hide()
		
		getglobal("HeadCountFrameContentWaitList"):Hide()	
	end
end

-- SHOW: Toggle display of the bosses content frame
function HeadCount:HeadCountFrameContentBoss_Show(isShowing)
	if (isShowing) then
		getglobal("HeadCountFrameContentBossTimeButton"):Show()	
		getglobal("HeadCountFrameContentBossMembersButton"):Show()	
		getglobal("HeadCountFrameContentBossNameButton"):Show()	
	
		getglobal("HeadCountFrameContentBoss"):Show()		
	else
		getglobal("HeadCountFrameContentBossTimeButton"):Hide()	
		getglobal("HeadCountFrameContentBossMembersButton"):Hide()	
		getglobal("HeadCountFrameContentBossNameButton"):Hide()	
	
		getglobal("HeadCountFrameContentBoss"):Hide()	
	end
end

-- SHOW: Toggle display of loot content frame
function HeadCount:HeadCountFrameContentLoot_Show(isShowing)  
	if (isShowing) then 
		getglobal("HeadCountFrameContentLoot"):Show()
	else
		getglobal("HeadCountFrameContentLoot"):Hide()
	end
end

-- SHOW: Toggle display of player content frame
function HeadCount:HeadCountFrameContentPlayer_Show(isShowing) 
	if (isShowing) then
		getglobal("HeadCountFrameContentPlayerNameString"):Show()
		getglobal("HeadCountFrameContentPlayerBackButton"):Show()
		
		getglobal("HeadCountFrameContentPlayer"):Show()	
	else
		getglobal("HeadCountFrameContentPlayerNameString"):Hide()
		getglobal("HeadCountFrameContentPlayerBackButton"):Hide()
		
		getglobal("HeadCountFrameContentPlayer"):Hide()	
	end
end

-- SHOW: Toggle display of the snapshot content frame
function HeadCount:HeadCountFrameContentSnapshot_Show(isShowing)
	if (isShowing) then
		getglobal("HeadCountFrameContentSnapshotNameString"):Show()
		getglobal("HeadCountFrameContentSnapshotBackButton"):Show()
	
		getglobal("HeadCountFrameContentSnapshot"):Show()	
	else
		getglobal("HeadCountFrameContentSnapshotNameString"):Hide()
		getglobal("HeadCountFrameContentSnapshotBackButton"):Hide()
		
		getglobal("HeadCountFrameContentSnapshot"):Hide()	
	end
end

-- SHOW: Display the correct content title string
function HeadCount:HeadCountFrameContentTitleString_Show()
	local titleString

	local raidTracker = HeadCount:getRaidTracker()
	local numberOfRaids = raidTracker:getNumberOfRaids()

	if (numberOfRaids > 0) then
		if (HeadCountFrame.isRaidSelected) then 
			local raid = raidTracker:getRaidById(HeadCountFrame.selectedRaidId)
			
			if (content["raid"] == HeadCountFrame.contentType) then
				local numberOfPlayers = raid:getNumberOfPlayers()
				
				titleString = string.format(L["info.raidmembers"], numberOfPlayers)

				HeadCountFrameContentTitleString:Show()
				HeadCountFrameContentTitleString:SetText(titleString)			
				HeadCountFrameContentMembersButton:Show()
				HeadCountFrameContentWaitListButton:Show()
				HeadCountFrameContentBossButton:Show()		
				HeadCountFrameContentLootButton:Show()		
			elseif (content["player"] == HeadCountFrame.contentType) then 
				titleString = L["info.raidplayer"]
				
				HeadCountFrameContentTitleString:Show()
				HeadCountFrameContentTitleString:SetText(titleString)			
				HeadCountFrameContentMembersButton:Show()
				HeadCountFrameContentWaitListButton:Show()
				HeadCountFrameContentBossButton:Show()						
				HeadCountFrameContentLootButton:Show()					
			elseif (content["waitlist"] == HeadCountFrame.contentType) then
				local numberOfMembers = raid:getNumberOfWaitlistPlayers()
				
				titleString = string.format(L["info.waitlist"], numberOfMembers)
				
				HeadCountFrameContentTitleString:Show()
				HeadCountFrameContentTitleString:SetText(titleString)				
				HeadCountFrameContentMembersButton:Show()
				HeadCountFrameContentWaitListButton:Show()
				HeadCountFrameContentBossButton:Show()						
				HeadCountFrameContentLootButton:Show()																	
			elseif (content["boss"] == HeadCountFrame.contentType) then
				local numberOfBosses = raid:getNumberOfBosses()
				
				titleString = string.format(L["info.raidbosses"], numberOfBosses)
				
				HeadCountFrameContentTitleString:Show()
				HeadCountFrameContentTitleString:SetText(titleString)
				HeadCountFrameContentMembersButton:Show()
				HeadCountFrameContentWaitListButton:Show()
				HeadCountFrameContentBossButton:Show()						
				HeadCountFrameContentLootButton:Show()													
			elseif (content["snapshot"] == HeadCountFrame.contentType) then 
				local boss = raid:retrieveBoss(HeadCountFrame.bossName)
				local numberOfPlayers = boss:numberOfPlayers()

				titleString = string.format(L["info.boss.snapshot"], numberOfPlayers) 
				
				HeadCountFrameContentTitleString:Show()
				HeadCountFrameContentTitleString:SetText(titleString)				
				HeadCountFrameContentMembersButton:Show()
				HeadCountFrameContentWaitListButton:Show()
				HeadCountFrameContentBossButton:Show()						
				HeadCountFrameContentLootButton:Show()		
			elseif (content["loot"] == HeadCountFrame.contentType) then
				local numberOfLoots = raid:numberOfLoots() 
				
				titleString = string.format(L["info.raidloot"], numberOfLoots) 
				
				HeadCountFrameContentTitleString:Show()
				HeadCountFrameContentTitleString:SetText(titleString)
				HeadCountFrameContentMembersButton:Show()
				HeadCountFrameContentWaitListButton:Show()
				HeadCountFrameContentBossButton:Show()						
				HeadCountFrameContentLootButton:Show()		
			else
				HeadCountFrameContentTitleString:Hide()
			end	
		else
			-- raids exist, but none are selected
			titleString = L["info.noraidsselected"]
			HeadCountFrameContentTitleString:Show()
			HeadCountFrameContentTitleString:SetText(titleString)		
			HeadCountFrameContentMembersButton:Hide()
			HeadCountFrameContentWaitListButton:Hide()
			HeadCountFrameContentBossButton:Hide()					
			HeadCountFrameContentLootButton:Hide()		
		end
	else
		titleString = L["info.noraidsexist"]
		HeadCountFrameContentTitleString:Show()
		HeadCountFrameContentTitleString:SetText(titleString)		
		HeadCountFrameContentMembersButton:Hide()
		HeadCountFrameContentWaitListButton:Hide()
		HeadCountFrameContentBossButton:Hide()		
		HeadCountFrameContentLootButton:Hide()		
	end
end

-- SHOW: Display the confirm frame
-- @param frameType The frame type
-- @param raidId The raid id
function HeadCount:HeadCountFrameConfirm_Show(frameType, raidId) 
	if (not HeadCountFrame.isDialogDisplayed) then
		-- only allow display of the remove frame is it is current not being displayed	
		if (confirmType[frameType]) then
			-- removal type is valid
			local isDisplayingConfirmFrame = false								
			local raidTracker = HeadCount:getRaidTracker()
			
			if (confirmType["raid"] == frameType) then
				-- remove raid
				HeadCountFrameConfirm.frameType = confirmType["raid"]
				HeadCountFrameConfirmHeaderTitleString:SetText(L["Remove raid"])		
				HeadCountFrameConfirmInfo:SetText(L["info.remove.raid"])						
				HeadCountFrameConfirmConfirmButton:SetText(L["Remove"])
				HeadCountFrameConfirmCancelButton:SetText(L["Cancel"])				

				local selectedRaid = raidTracker:getRaidById(raidId)
				local zone = selectedRaid:getZone()
				
				HeadCountFrameConfirm.description = HeadCount:getDateTimeAsString(selectedRaid:retrieveStartingTime())
				if (zone) then
					HeadCountFrameConfirm.description = HeadCountFrameConfirm.description .. " - " .. zone
				end
					
				isDisplayingConfirmFrame = true
			elseif (confirmType["member"] == frameType) then
				-- remove member
				HeadCountFrameConfirm.frameType = confirmType["member"]
				HeadCountFrameConfirmHeaderTitleString:SetText(L["Remove member"])
				HeadCountFrameConfirmInfo:SetText(L["info.remove.member"])		
				HeadCountFrameConfirmConfirmButton:SetText(L["Remove"])
				HeadCountFrameConfirmCancelButton:SetText(L["Cancel"])				
				
				isDisplayingConfirmFrame = true
			elseif (confirmType["waitlist"] == frameType) then 
				HeadCountFrameConfirm.frameType = confirmType["waitlist"]
				HeadCountFrameConfirmHeaderTitleString:SetText(L["Remove wait list member"])
				HeadCountFrameConfirmInfo:SetText(L["info.remove.waitlist"])		
				HeadCountFrameConfirmConfirmButton:SetText(L["Remove"])
				HeadCountFrameConfirmCancelButton:SetText(L["Cancel"])				
				
				isDisplayingConfirmFrame = true			
			elseif (confirmType["boss"] == frameType) then 
				-- remove boss
				HeadCountFrameConfirm.frameType = confirmType["boss"]
				HeadCountFrameConfirmHeaderTitleString:SetText(L["Remove boss"])
				HeadCountFrameConfirmInfo:SetText(L["info.remove.boss"])		
				HeadCountFrameConfirmConfirmButton:SetText(L["Remove"])
				HeadCountFrameConfirmCancelButton:SetText(L["Cancel"])				
				
				isDisplayingConfirmFrame = true			
			elseif (confirmType["snapshot"] == frameType) then 
				HeadCountFrameConfirm.frameType = confirmType["snapshot"]
				HeadCountFrameConfirmHeaderTitleString:SetText(L["Remove attendee"])
				HeadCountFrameConfirmInfo:SetText(L["info.remove.attendee"])		
				HeadCountFrameConfirmConfirmButton:SetText(L["Remove"])
				HeadCountFrameConfirmCancelButton:SetText(L["Cancel"])				
				
				isDisplayingConfirmFrame = true					
			elseif (confirmType["endraid"] == frameType) then
				-- end the active raid
				if (raidTracker:isRaidActive()) then
					local currentRaid = raidTracker:retrieveMostRecentRaid()
					local zone = currentRaid:getZone()
					
					HeadCountFrameConfirm.description = HeadCount:getDateTimeAsString(currentRaid:retrieveStartingTime())
					if (zone) then
						HeadCountFrameConfirm.description = HeadCountFrameConfirm.description .. " - " .. zone
					end
					
					HeadCountFrameConfirm.frameType = confirmType["endraid"]
					HeadCountFrameConfirmHeaderTitleString:SetText(L["End raid"])
					HeadCountFrameConfirmInfo:SetText(L["info.end.raid"])
					HeadCountFrameConfirmConfirmButton:SetText(L["End raid"])
					HeadCountFrameConfirmCancelButton:SetText(L["Cancel"])

					isDisplayingConfirmFrame = true	
				else
					HeadCount:LogInformation(string.format(L["info.end.raid.noraidsexists"], HeadCount.TITLE, HeadCount.VERSION))
				end
			elseif (confirmType["removeall"] == frameType) then 
				-- remove all raids
				HeadCountFrameConfirm.frameType = confirmType["removeall"]
				HeadCountFrameConfirmHeaderTitleString:SetText(L["Remove all"])
				HeadCountFrameConfirmInfo:SetText(L["info.remove.allraids"])
				HeadCountFrameConfirmConfirmButton:SetText(L["Remove"])
				HeadCountFrameConfirmCancelButton:SetText(L["Cancel"])				
				HeadCountFrameConfirm.description = L["info.remove.allraids.warning"]
				
				isDisplayingConfirmFrame = true				
			elseif (confirmType["loot"] == frameType) then 
				-- remove loot
				HeadCountFrameConfirm.frameType = confirmType["loot"]
				HeadCountFrameConfirmHeaderTitleString:SetText(L["Remove loot"])
				HeadCountFrameConfirmInfo:SetText(L["info.remove.loot"])		
				HeadCountFrameConfirmConfirmButton:SetText(L["Remove"])
				HeadCountFrameConfirmCancelButton:SetText(L["Cancel"])				
				
				isDisplayingConfirmFrame = true
			end				

			if (isDisplayingConfirmFrame) then
				-- display the frame
				HeadCountFrameConfirm.raidId = raidId
				HeadCountFrameConfirmDescription:SetText(HeadCountFrameConfirm.description)						
			
				HeadCount:EnableModalFrame() 
				HeadCountFrameConfirm:Show()
			else
				-- do not display (hide) the frame
				HeadCount:DisableModalFrame() 		
			end
		end
	end
end

-- SHOW: Display the raid announcement frame.
function HeadCount:HeadCountFrameAnnouncement_Show()
	if (not HeadCountFrame.isDialogDisplayed) then
		HeadCountFrameAnnouncementTypeEditBoxButtonText:SetText(L["Announce wait list"])
		HeadCountFrameAnnouncementChannelEditBoxButtonText:SetText(L["Guild"])	
	
		HeadCount:EnableModalFrame()
		HeadCountFrameAnnouncement:Show()	
	end
end

-- SHOW: Display the export frame
-- @param raidId The raid id
-- @param isRefresh The refresh operation
function HeadCount:HeadCountFrameExport_Show(raidId, isRefresh) 
	if ((not HeadCountFrame.isDialogDisplayed) or (isRefresh)) then
		-- only allow display of the remove frame is it is current not being displayed	
		local raidTracker = HeadCount:getRaidTracker()
		local raid = raidTracker:getRaidById(raidId)
		
		local exportString = HeadCount:exportRaid(raid)
		
		HeadCountFrameExportHeaderTitleString:SetText(L["Export raid"])
		HeadCountFrameExportInfo:SetText(string.format(L["info.export.raid"], HeadCount:GetExportFormat()))
		
		HeadCountFrameExportDescription:SetText(HeadCount:getDateTimeAsString(raid:retrieveStartingTime()))
		HeadCountFrameExportScrollContent:SetText(exportString)
		HeadCountFrameExportId:SetText(raidId)
		HeadCountFrameExportScrollContent:HighlightText()		
		
		HeadCount:EnableModalFrame() 
		HeadCountFrameExport:Show()		
	end
end

-- SHOW: Display the loot management frame
-- @param raidId The raid id.
-- @param lootId The lootId
function HeadCount:HeadCountFrameLootManagement_Show(raidId, lootId)
	if (not HeadCountFrame.isDialogDisplayed) then
		if ((raidId) and (lootId)) then
			HeadCountFrameLootManagement.raidId = raidId
			HeadCountFrameLootManagement.lootId = lootId
			
			local raidTracker = HeadCount:getRaidTracker()
			local raid = raidTracker:getRaidById(raidId)

			HeadCountFrameLootManagementHeaderTitleString:SetText(L["Manage loot"])
			HeadCountFrameLootManagementInfo:SetText(L["info.loot.manage"])

			local raidDescription = HeadCount:getDateTimeAsString(raid:retrieveStartingTime())
			local zone = raid:getZone()		
			if (zone) then
				-- raid zone exists
				raidDescription = raidDescription .. " - " .. zone
			end		
			HeadCountFrameLootManagementRaidDescription:SetText(raidDescription)
			
			local loot = raid:retrieveLoot(lootId)
			if (loot) then
				local link = loot:getLink()
				if (link) then		
					HeadCountFrameLootManagementLootDescription:SetText(link)
				else
					HeadCountFrameLootManagementLootDescription:SetText(L["Item unavailable"])
				end			
				
				HeadCountFrameLootManagementLooterEditBox:SetText(loot:getPlayerName())
				HeadCountFrameLootManagementSourceEditBox:SetText(loot:getSource())
				
				local lootCost = loot:getCost()
				if (lootCost) then
					HeadCountFrameLootManagementCostEditBox:SetText(lootCost)
				else
					HeadCountFrameLootManagementCostEditBox:SetText("0")
				end
				
				local lootNote = loot:getNote()
				if (lootNote) then
					HeadCountFrameLootManagementNoteEditBox:SetText(lootNote)
				else
					HeadCountFrameLootManagementNoteEditBox:SetText("")
				end
			else
				error("Unable to show loot management frame because the selected loot does not exist.")
			end
			
			HeadCount:EnableModalFrame()
			HeadCountFrameLootManagement:Show()
		end
	end
end

-- SHOW: Display the loot management frame popup
-- @param raidId The raid id.
-- @param lootId The lootId
function HeadCount:HeadCountFrameLootManagementPopup_Show(raidId, lootId)	
	if ((raidId) and (lootId)) then
		if (HeadCountFrame.isLootPopupDisplayed) then
			-- loot popup is currently being displayed
			-- add item to loot popup queue
			table.insert(HeadCountFrame.lootPopupQueue, { ["raidId"] = raidId, ["lootId"] = lootId })
		else
			-- loot popup is currently NOT being displayed
			-- fill the popup frame values
			HeadCountFrame.lootManagementPopupRaidId = raidId
			HeadCountFrame.lootManagementPopupLootId = lootId
			
			local raidTracker = HeadCount:getRaidTracker()
			local raid = raidTracker:getRaidById(raidId)

			HeadCountFrameLootManagementPopupHeaderTitleString:SetText(L["Manage loot"])
			HeadCountFrameLootManagementPopupInfo:SetText(L["info.loot.manage"])			
			
			local raidDescription = HeadCount:getDateTimeAsString(raid:retrieveStartingTime())
			local zone = raid:getZone()		
			if (zone) then
				-- raid zone exists
				raidDescription = raidDescription .. " - " .. zone
			end		
			HeadCountFrameLootManagementPopupRaidDescription:SetText(raidDescription)
			
			local loot = raid:retrieveLoot(lootId)
			if (loot) then
				local link = loot:getLink()
				if (link) then		
					HeadCountFrameLootManagementPopupLootDescription:SetText(link)
				else
					HeadCountFrameLootManagementPopupLootDescription:SetText(L["Item unavailable"])
				end			
				
				HeadCountFrameLootManagementPopupLooterEditBox:SetText(loot:getPlayerName())
				HeadCountFrameLootManagementPopupSourceEditBox:SetText(loot:getSource())
				
				local lootCost = loot:getCost()
				if (lootCost) then
					HeadCountFrameLootManagementPopupCostEditBox:SetText(lootCost)
				else
					HeadCountFrameLootManagementPopupCostEditBox:SetText("0")
				end
				
				local lootNote = loot:getNote()
				if (lootNote) then
					HeadCountFrameLootManagementPopupNoteEditBox:SetText(lootNote)
				else
					HeadCountFrameLootManagementPopupNoteEditBox:SetText("")
				end
			else
				error("Unable to show loot management popup frame because the selected loot does not exist.")
			end			
			
			HeadCountFrame.isLootPopupDisplayed = true

			-- display the popup frame
			HeadCountFrameLootManagementPopup:Show()			
		end
	end
end

-- ***********************************
-- ON CLICK FUNCTIONS
-- ***********************************
-- ON CLICK: Frame close button
function HeadCount:HeadCountFrameTitleCloseButton_Click()
	-- Main close button has been clicked
	HeadCount:HideUserInterface()
end

-- ON CLICK: Announce button
function HeadCount:HeadCountFrameRaidHistoryAnnounceButton_Click()
	HeadCount:HeadCountFrameAnnouncement_Show()
end

-- ON CLICK: End raid button
function HeadCount:HeadCountFrameRaidHistoryEndRaidButton_Click()
	local currentRaidId = HeadCount:getRaidTracker():retrieveCurrentRaidId()
	
	HeadCountFrameConfirm.description = ""
	HeadCount:HeadCountFrameConfirm_Show("endraid", currentRaidId)
end

-- ON CLICK: Remove all raids button
function HeadCount:HeadCountFrameRaidHistoryRemoveAllButton_Click() 
	HeadCountFrameConfirm.description = ""
	HeadCount:HeadCountFrameConfirm_Show("removeall", 0)
end

-- ON CLICK: Raid selected
function HeadCount:HeadCountFrameRaidHistoryContentTemplateHitArea_Click()
	local raidId = tonumber(getglobal(this:GetParent():GetName() .. "Id"):GetText())	-- save the selected raid id

	HeadCount:DisableModalFrame()
	
	HeadCountFrame.selectedRaidId = raidId 
	HeadCountFrame.isRaidSelected = true
	HeadCountFrame.contentType = content["raid"]	
	HeadCount:HeadCountFrame_Update()
end

-- ON CLICK: Raid export button
function HeadCount:HeadCountFrameRaidHistoryContentTemplateExportButton_Click() 
	local raidTracker = HeadCount:getRaidTracker() 
	local currentRaidId = raidTracker:retrieveCurrentRaidId()
	local isCurrentRaidActive = raidTracker:getIsCurrentRaidActive()
	
	local raidId = tonumber(getglobal(this:GetParent():GetName() .. "Id"):GetText())	

	if ((raidId == currentRaidId) and (isCurrentRaidActive)) then 
		-- user chose most recent raid and most recent raid is active
		HeadCount:LogInformation(string.format(L["warning.export.raid.currentraid"], HeadCount.TITLE, HeadCount.VERSION))	
	else
		-- user did not choose the most recent raid or the most recent raid is NOT active
		HeadCount:HeadCountFrameExport_Show(raidId, false)		
	end
end

-- ON CLICK: Raid delete button	
function HeadCount:HeadCountFrameRaidHistoryContentTemplateDeleteButton_Click()
	local raidId = tonumber(getglobal(this:GetParent():GetName() .. "Id"):GetText())
	HeadCount:HeadCountFrameConfirm_Show("raid", raidId)
end

-- ON CLICK: Raid members button
function HeadCount:HeadCountFrameContentMembersButton_Click() 
	HeadCount:DisableModalFrame() 
	
	HeadCountFrame.contentType = content["raid"]
	HeadCount:HeadCountFrame_Update()
end

-- ON CLICK: Raid wait list button
function HeadCount:HeadCountFrameContentWaitListButton_Click()
	HeadCount:DisableModalFrame()
	
	HeadCountFrame.contentType = content["waitlist"]
	HeadCount:HeadCountFrame_Update()		
end

-- ON CLICK: Raid boss kills button
function HeadCount:HeadCountFrameContentBossButton_Click()
	HeadCount:DisableModalFrame()
	
	HeadCountFrame.contentType = content["boss"]
	HeadCount:HeadCountFrame_Update()	
end

-- ON CLICK: Raid loot button
function HeadCount:HeadCountFrameContentLootButton_Click() 
	HeadCount:DisableModalFrame()
	
	HeadCountFrame.contentType = content["loot"]
	HeadCount:HeadCountFrame_Update()
end

-- ON CLICK: Player go back button
function HeadCount:HeadCountFrameContentPlayerBackButton_Click() 
	HeadCount:DisableModalFrame() 
	
	HeadCountFrame.contentType = content["raid"]
	HeadCount:HeadCountFrame_Update()
end

-- ON CLICK: Snapshot go back button
function HeadCount:HeadCountFrameContentSnapshotBackButton_Click()
	HeadCount:DisableModalFrame()
	
	HeadCountFrame.contentType = content["boss"]
	HeadCount:HeadCountFrame_Update()
end

-- ON CLICK: Raid member name sort button
function HeadCount:HeadCountFrameContentMembersNameButton_Click()
	local raidMemberSort = HeadCount:getRAID_MEMBER_SORT()
	
	if (raidMemberSort["Name"] == HeadCountFrameContentMembers.sortType) then
		-- Current column is sort column, switch direction
		HeadCountFrameContentMembers.isDescending = not HeadCountFrameContentMembers.isDescending
	else
		HeadCountFrameContentMembers.sortType = raidMemberSort["Name"]
		HeadCountFrameContentMembers.isDescending = true
	end	
	
	HeadCount:HeadCountFrame_Update()	
end

-- ON CLICK: Raid member start time sort button
function HeadCount:HeadCountFrameContentMembersStartTimeButton_Click() 
	local raidMemberSort = HeadCount:getRAID_MEMBER_SORT()
	
	if (raidMemberSort["Start"] == HeadCountFrameContentMembers.sortType) then
		-- Current column is sort column, switch direction
		HeadCountFrameContentMembers.isDescending = not HeadCountFrameContentMembers.isDescending
	else
		HeadCountFrameContentMembers.sortType = raidMemberSort["Start"]
		HeadCountFrameContentMembers.isDescending = true
	end	
	
	HeadCount:HeadCountFrame_Update()	
end

-- ON CLICK: Raid member end time sort button
function HeadCount:HeadCountFrameContentMembersEndTimeButton_Click() 
	local raidMemberSort = HeadCount:getRAID_MEMBER_SORT()
	
	if (raidMemberSort["End"] == HeadCountFrameContentMembers.sortType) then
		-- Current column is sort column, switch direction
		HeadCountFrameContentMembers.isDescending = not HeadCountFrameContentMembers.isDescending
	else
		HeadCountFrameContentMembers.sortType = raidMemberSort["End"]
		HeadCountFrameContentMembers.isDescending = true
	end	
	
	HeadCount:HeadCountFrame_Update()	
end

-- ON CLICK: Raid member total time sort button
function HeadCount:HeadCountFrameContentMembersTotalTimeButton_Click() 
	local raidMemberSort = HeadCount:getRAID_MEMBER_SORT()
	
	if (raidMemberSort["Total"] == HeadCountFrameContentMembers.sortType) then
		-- Current column is sort column, switch direction
		HeadCountFrameContentMembers.isDescending = not HeadCountFrameContentMembers.isDescending
	else
		HeadCountFrameContentMembers.sortType = raidMemberSort["Total"]
		HeadCountFrameContentMembers.isDescending = true
	end	
	
	HeadCount:HeadCountFrame_Update()
end

-- ON CLICK: Member selected
function HeadCount:HeadCountFrameContentMembersTemplateHitArea_Click() 
	HeadCount:DisableModalFrame()
	
	HeadCountFrame.playerName = getglobal(this:GetParent():GetName() .. "Name"):GetText()
	HeadCountFrame.contentType = content["player"]
	HeadCount:HeadCountFrame_Update()
end

-- ON CLICK: Member delete button
function HeadCount:HeadCountFrameContentMembersTemplateDeleteButton_Click()
	HeadCountFrameConfirm.playerId = tonumber(getglobal(this:GetParent():GetName() .. "Number"):GetText())
	HeadCountFrameConfirm.description = getglobal(this:GetParent():GetName() .. "Name"):GetText()
		
	HeadCount:HeadCountFrameConfirm_Show("member", HeadCountFrame.selectedRaidId)
end

-- ON CLICK: Raid wait list members name sort button
function HeadCount:HeadCountFrameContentWaitListNameButton_Click()
	local raidMemberSort = HeadCount:getRAID_MEMBER_SORT()
	
	if (raidMemberSort["Name"] == HeadCountFrameContentWaitList.sortType) then
		-- Current column is sort column, switch direction
		HeadCountFrameContentWaitList.isDescending = not HeadCountFrameContentWaitList.isDescending
	else
		HeadCountFrameContentWaitList.sortType = raidMemberSort["Name"]
		HeadCountFrameContentWaitList.isDescending = true
	end	
	
	HeadCount:HeadCountFrame_Update()	
end

-- ON CLICK: Raid wait list members time sort button
function HeadCount:HeadCountFrameContentWaitListTimeButton_Click()
	local raidMemberSort = HeadCount:getRAID_MEMBER_SORT()
	
	if (raidMemberSort["Waitlist"] == HeadCountFrameContentWaitList.sortType) then
		-- Current column is sort column, switch direction
		HeadCountFrameContentWaitList.isDescending = not HeadCountFrameContentWaitList.isDescending
	else
		HeadCountFrameContentWaitList.sortType = raidMemberSort["Waitlist"]
		HeadCountFrameContentWaitList.isDescending = true
	end	
	
	HeadCount:HeadCountFrame_Update()	
end

-- ON CLICK: Raid wait list members note sort button
function HeadCount:HeadCountFrameContentWaitListNoteButton_Click()
	local raidMemberSort = HeadCount:getRAID_MEMBER_SORT()
	
	if (raidMemberSort["WaitlistNote"] == HeadCountFrameContentWaitList.sortType) then 
		HeadCountFrameContentWaitList.isDescending = not HeadCountFrameContentWaitList.isDescending
	else
		HeadCountFrameContentWaitList.sortType = raidMemberSort["WaitlistNote"]
		HeadCountFrameContentWaitList.isDescending = true	
	end
	
	HeadCount:HeadCountFrame_Update()
end

-- ON CLICK: Wait list remove button
function HeadCount:HeadCountFrameContentWaitListTemplateRemoveButton_Click()
	HeadCountFrameConfirm.waitListId = tonumber(getglobal(this:GetParent():GetName() .. "Number"):GetText())
	HeadCountFrameConfirm.description = getglobal(this:GetParent():GetName() .. "Name"):GetText()
	
	HeadCount:HeadCountFrameConfirm_Show("waitlist", HeadCountFrame.selectedRaidId)
end

-- ON CLICK: Boss selected
function HeadCount:HeadCountFrameContentBossTemplateHitArea_Click() 
	HeadCount:DisableModalFrame()
	
	HeadCountFrame.bossName = getglobal(this:GetParent():GetName() .. "Name"):GetText()
	HeadCountFrame.contentType = content["snapshot"]
	HeadCount:HeadCountFrame_Update()
end

-- ON CLICK: Boss delete button
function HeadCount:HeadCountFrameContentBossTemplateDeleteButton_Click()
	HeadCountFrameConfirm.bossId = tonumber(getglobal(this:GetParent():GetName() .. "Number"):GetText())
	HeadCountFrameConfirm.description = getglobal(this:GetParent():GetName() .. "Name"):GetText()
	
	HeadCount:HeadCountFrameConfirm_Show("boss", HeadCountFrame.selectedRaidId)
end

-- ON CLICK: Boss snapshot attendee remove button
function HeadCount:HeadCountFrameContentSnapshotTemplateRemoveButton_Click()
	HeadCountFrameConfirm.attendeeId = tonumber(getglobal(this:GetParent():GetName() .. "Number"):GetText())
	HeadCountFrameConfirm.description = getglobal(this:GetParent():GetName() .. "Name"):GetText()
	
	HeadCount:HeadCountFrameConfirm_Show("snapshot", HeadCountFrame.selectedRaidId)
end

-- ON CLICK: Loot texture button
function HeadCount:HeadCountFrameContentLootTemplateTextureButton_Click()
	local itemId = getglobal(this:GetParent():GetName() .. "Id"):GetText()

	local itemName, itemLink, itemQuality, itemLevel, itemMinLevel, itemType, itemSubType, itemCount, itemEquipLoc, itemTexture = GetItemInfo(itemId)
	if (not itemName) then
		-- item info is not returning, query the server
		GameTooltip:SetHyperlink("item:".. itemId ..":0:0:0:0:0:0:0")
		HeadCount:HeadCountFrame_Update()	-- refresh
	else
		-- item info did return
		if (IsShiftKeyDown()) then
			-- shift key is held down, link the item
			ChatEdit_InsertLink(itemLink)
		else
			HeadCount:HeadCountFrame_Update()	-- refresh
		end
	end
end

-- ON CLICK: Loot link button
function HeadCount:HeadCountFrameContentLootTemplateNameButton_Click()
	local itemId = getglobal(this:GetParent():GetName() .. "Id"):GetText()

	local itemName, itemLink, itemQuality, itemLevel, itemMinLevel, itemType, itemSubType, itemCount, itemEquipLoc, itemTexture = GetItemInfo(itemId)
	if ((itemName) and (IsShiftKeyDown())) then
		-- item is valid and shift key is held down, link the item
		ChatEdit_InsertLink(itemLink)
	end
end

-- ON CLICK: Loot management button
function HeadCount:HeadCountFrameContentLootTemplateManagementButton_Click()
	local lootId = tonumber(getglobal(this:GetParent():GetName() .. "Number"):GetText())
	local raidId = HeadCountFrame.selectedRaidId	
	
	HeadCount:HeadCountFrameLootManagement_Show(raidId, lootId)
end

-- ON CLICK: Loot delete button
function HeadCount:HeadCountFrameContentLootTemplateDeleteButton_Click() 
	HeadCountFrameConfirm.lootId = tonumber(getglobal(this:GetParent():GetName() .. "Number"):GetText())
	HeadCountFrameConfirm.description = getglobal(this:GetParent():GetName() .. "NameButtonText"):GetText()	
	
	HeadCount:HeadCountFrameConfirm_Show("loot", HeadCountFrame.selectedRaidId)
end

-- ON CLICK: Confirm button
function HeadCount:HeadCountFrameConfirmConfirmButton_Click()		
	if (confirmType["raid"] == HeadCountFrameConfirm.frameType) then
		-- remove raid		
		if (HeadCountFrame.isLootPopupDisplayed) then
			-- loot management popup is displayed and it is for the same raid,  show warning
			HeadCount:LogInformation(string.format(L["warning.loot.popup.remove.raid"], HeadCount.TITLE, HeadCount.VERSION))	
		else
			-- loot management popup is NOT displayed, remove the raid
			HeadCount:DisableModalFrame()
			HeadCount:removeRaid(HeadCountFrameConfirm.raidId)		
		end
	elseif (confirmType["member"] == HeadCountFrameConfirm.frameType) then		                                               
		-- remove member
		HeadCount:DisableModalFrame()
		HeadCount:removePlayer(HeadCountFrameConfirm.raidId, HeadCountFrameConfirm.description)
	elseif (confirmType["waitlist"] == HeadCountFrameConfirm.frameType) then 
		HeadCount:DisableModalFrame()
		HeadCount:removeWaitlistPlayer(HeadCountFrameConfirm.raidId, HeadCountFrameConfirm.description)
	elseif (confirmType["boss"] == HeadCountFrameConfirm.frameType) then
		-- remove boss
		HeadCount:DisableModalFrame()
		HeadCount:removeBoss(HeadCountFrameConfirm.raidId, HeadCountFrameConfirm.description)
	elseif (confirmType["snapshot"] == HeadCountFrameConfirm.frameType) then
		-- remove snapshot attendee
		HeadCount:DisableModalFrame()
		HeadCount:removeEventAttendee(HeadCountFrameConfirm.raidId, HeadCountFrame.bossName, HeadCountFrameConfirm.attendeeId)
	elseif (confirmType["loot"] == HeadCountFrameConfirm.frameType) then 
		if (HeadCountFrame.isLootPopupDisplayed) then
			-- loot management popup is displayed and it is for the same raid,  show warning
			HeadCount:LogInformation(string.format(L["warning.loot.popup.remove.loot"], HeadCount.TITLE, HeadCount.VERSION))	
		else
			-- loot management popup is NOT displayed, remove the loot
			HeadCount:DisableModalFrame()
			HeadCount:removeLoot(HeadCountFrameConfirm.raidId, HeadCountFrameConfirm.lootId)	
		end
	elseif (confirmType["endraid"] == HeadCountFrameConfirm.frameType) then 
		-- end active raid
		HeadCount:DisableModalFrame()
		local utcDateTimeInSeconds = HeadCount:getUTCDateTimeInSeconds()
		local activityTime = AceLibrary("HeadCountTime-1.0"):new({ ["utcDateTimeInSeconds"] = utcDateTimeInSeconds })	
		HeadCount:endCurrentRaid(activityTime)
	elseif (confirmType["removeall"] == HeadCountFrameConfirm.frameType) then 
		-- remove all raids
		if (HeadCountFrame.isLootPopupDisplayed) then
			-- loot management popup is displayed, show warning
			HeadCount:LogInformation(string.format(L["warning.loot.popup.remove.removeall"], HeadCount.TITLE, HeadCount.VERSION))	
		else
			-- loot management popup is NOT displayed, remove all raids
			HeadCount:DisableModalFrame()
			HeadCountFrame.isRaidSelected = false
			HeadCountFrame.selectedRaidId = 0		
			HeadCountFrame.contentType = content["default"]
			HeadCount:removeAllRaids()
		end
	end
end

-- ON CLICK: Cancel button
function HeadCount:HeadCountFrameConfirmCancelButton_Click()		
	HeadCount:DisableModalFrame() 
end

-- ON CLICK: Export refresh button
function HeadCount:HeadCountFrameExportRefreshButton_Click()	
	local raidId = tonumber(getglobal(this:GetParent():GetName() .. "Id"):GetText())	
	
	if (raidId) then
		HeadCount:HeadCountFrameExport_Show(raidId, true)
	end
end

-- ON CLICK: Export close button
function HeadCount:HeadCountFrameExportCloseButton_Click()	
	HeadCount:DisableModalFrame() 
end

-- ON CLICK: Loot management save button
function HeadCount:HeadCountFrameLootManagementSaveButton_Click()
	local looterString = HeadCountFrameLootManagementLooterEditBox:GetText()
	local sourceString = HeadCountFrameLootManagementSourceEditBox:GetText()
	local costString = HeadCountFrameLootManagementCostEditBox:GetText()
	local noteString = HeadCountFrameLootManagementNoteEditBox:GetText()
	
	local isLooterValid = HeadCount:isString(looterString)
	local isSourceValid = HeadCount:isString(sourceString)
	local isCostValid = HeadCount:isNumber(costString)
	-- no validation on the loot note
	
	if ((isLooterValid) and (isSourceValid) and (isCostValid)) then
		HeadCount:DisableModalFrame() 
		
		local cost = tonumber(costString)
		
		if (noteString) then 
			noteString = HeadCount:trim(noteString)	-- trim whitespace
		end
		
		HeadCount:lootManagementUpdate(HeadCountFrameLootManagement.raidId, HeadCountFrameLootManagement.lootId, looterString, sourceString, cost, noteString)
	else
		if (not isLooterValid) then
			HeadCount:LogInformation(string.format(L["warning.loot.manage.looter"], HeadCount.TITLE, HeadCount.VERSION))	
		end
		
		if (not isSourceValid) then
			HeadCount:LogInformation(string.format(L["warning.loot.manage.source"], HeadCount.TITLE, HeadCount.VERSION))	
		end
		
		if (not isCostValid) then
			HeadCount:LogInformation(string.format(L["warning.loot.manage.cost"], HeadCount.TITLE, HeadCount.VERSION))	
		end
	end
end

-- ON CLICK: Loot management cancel button
function HeadCount:HeadCountFrameLootManagementCancelButton_Click()
	HeadCount:DisableModalFrame() 
end

-- ON CLICK: Loot management looter button
function HeadCount:HeadCountFrameLootManagementLooterButton_Click() 	
	local looterButton = getglobal("HeadCountFrameLootManagementLooterButton")
	if (dewdrop:IsOpen(looterButton)) then
		dewdrop:Close()
		if (dewdrop:IsRegistered(looterButton)) then
			dewdrop:Unregister(looterButton)
		end
	else
		if (not dewdrop:IsRegistered(looterButton)) then
			dewdrop:Register(looterButton, 'children', function(level, value, raidId) HeadCount:HeadCountFrameLootManagementLooterButton_CreateMenu(level, value) end, 'dontHook', true)	
		end
		
		dewdrop:Open(looterButton)
	end	
end

-- ON CLICK: Loot management bank button
function HeadCount:HeadCountFrameLootManagementBankButton_Click() 
	HeadCount:HeadCountFrameLootManagementLooterButton_Set(L["Bank"])
end

-- ON CLICK: Loot management disenchanted button
function HeadCount:HeadCountFrameLootManagementDisenchantedButton_Click()
	HeadCount:HeadCountFrameLootManagementLooterButton_Set(L["Disenchanted"])
end

-- ON CLICK: Loot management offspec button
function HeadCount:HeadCountFrameLootManagementOffspecButton_Click()
	HeadCount:HeadCountFrameLootManagementLooterButton_Set(L["Offspec"])
end

-- Sets the looter text via the dropdown menu selection
-- @param looter The looter
function HeadCount:HeadCountFrameLootManagementLooterButton_Set(looter)
	if (looter) then	
		HeadCountFrameLootManagementLooterEditBox:SetText(looter)
	end
end

-- ON CLICK: Loot management source button   
function HeadCount:HeadCountFrameLootManagementSourceButton_Click()
	local sourceButton = getglobal("HeadCountFrameLootManagementSourceButton")
	if (dewdrop:IsOpen(sourceButton)) then
		dewdrop:Close()
		if (dewdrop:IsRegistered(sourceButton)) then
			dewdrop:Unregister(sourceButton)
		end
	else
		if (not dewdrop:IsRegistered(sourceButton)) then
			dewdrop:Register(sourceButton, 'children', function(level, value) HeadCount:HeadCountFrameLootManagementSourceButton_CreateMenu(level, value) end, 'dontHook', true)	
		end
		
		dewdrop:Open(sourceButton)
	end	
end

-- Sets the source text via the dropdown menu selection
-- @param source
function HeadCount:HeadCountFrameLootManagementSourceButton_Set(source)
	if (source) then	
		HeadCountFrameLootManagementSourceEditBox:SetText(source)
	end
end

-- ON CLICK: Loot management popup save button
function HeadCount:HeadCountFrameLootManagementPopupSaveButton_Click()
	local looterString = HeadCountFrameLootManagementPopupLooterEditBox:GetText()
	local sourceString = HeadCountFrameLootManagementPopupSourceEditBox:GetText()
	local costString = HeadCountFrameLootManagementPopupCostEditBox:GetText()
	local noteString = HeadCountFrameLootManagementPopupNoteEditBox:GetText()
	
	local isLooterValid = HeadCount:isString(looterString)
	local isSourceValid = HeadCount:isString(sourceString)
	local isCostValid = HeadCount:isNumber(costString)
	-- no validation on the note string
	
	if ((isLooterValid) and (isSourceValid) and (isCostValid)) then
		HeadCountFrame.isLootPopupDisplayed = false
		HeadCountFrameLootManagementPopup:Hide()
	
		dewdrop:Close() -- close menus	
		
		local cost = tonumber(costString)
		
		if (noteString) then 
			noteString = HeadCount:trim(noteString)	-- trim whitespace
		end
		
		HeadCount:lootManagementUpdate(HeadCountFrame.lootManagementPopupRaidId, HeadCountFrame.lootManagementPopupLootId, looterString, sourceString, cost, noteString)
	
		HeadCount:HeadCountFrameLootManagementPopup_ManageQueue()	
	else
		-- display validation warning messages
		if (not isLooterValid) then
			HeadCount:LogInformation(string.format(L["warning.loot.manage.looter"], HeadCount.TITLE, HeadCount.VERSION))	
		end
		
		if (not isSourceValid) then
			HeadCount:LogInformation(string.format(L["warning.loot.manage.source"], HeadCount.TITLE, HeadCount.VERSION))	
		end
		
		if (not isCostValid) then
			HeadCount:LogInformation(string.format(L["warning.loot.manage.cost"], HeadCount.TITLE, HeadCount.VERSION))	
		end
	end
end

-- ON CLICK: Loot management popup cancel button
function HeadCount:HeadCountFrameLootManagementPopupCancelButton_Click()
	HeadCountFrame.isLootPopupDisplayed = false
	HeadCountFrameLootManagementPopup:Hide()
	
	dewdrop:Close() -- close menus	
	
	HeadCount:HeadCountFrameLootManagementPopup_ManageQueue()
end

-- ON CLICK: Loot management popup queue management
function HeadCount:HeadCountFrameLootManagementPopup_ManageQueue()
	if (HeadCount:IsLootPopupEnabled()) then
		-- loot manamgement popup is still enabled
		
		---- are there more items in queue?
		if (HeadCountFrame.lootPopupQueue) then
			local numberOfQueuedItems = # HeadCountFrame.lootPopupQueue
			if (numberOfQueuedItems > 0) then
				------ get queued ids
				local raidId = HeadCountFrame.lootPopupQueue[1]["raidId"]
				local lootId = HeadCountFrame.lootPopupQueue[1]["lootId"]
			
				------ remove item from queue (first item)
				table.remove(HeadCountFrame.lootPopupQueue, 1)
				
				------ show loot management popup window for this item	
				HeadCount:HeadCountFrameLootManagementPopup_Show(raidId, lootId)	
			end
		end		
	else
		-- loot management popup is no longer enabled
		
		-- clear the current queue
		HeadCountFrame.lootPopupQueue = {}
	end
end

-- ON CLICK: Loot management popup looter button
function HeadCount:HeadCountFrameLootManagementPopupLooterButton_Click() 	
	local looterButton = getglobal("HeadCountFrameLootManagementPopupLooterButton")
	if (dewdrop:IsOpen(looterButton)) then
		dewdrop:Close()
		if (dewdrop:IsRegistered(looterButton)) then
			dewdrop:Unregister(looterButton)
		end
	else
		if (not dewdrop:IsRegistered(looterButton)) then
			dewdrop:Register(looterButton, 'children', function(level, value, raidId) HeadCount:HeadCountFrameLootManagementPopupLooterButton_CreateMenu(level, value) end, 'dontHook', true)	
		end
		
		dewdrop:Open(looterButton)
	end	
end

-- ON CLICK: Loot management popup bank button
function HeadCount:HeadCountFrameLootManagementPopupBankButton_Click()
	HeadCount:HeadCountFrameLootManagementPopupLooterButton_Set(L["Bank"])
end

-- ON CLICK: Loot management popup disenchanted button
function HeadCount:HeadCountFrameLootManagementPopupDisenchantedButton_Click()
	HeadCount:HeadCountFrameLootManagementPopupLooterButton_Set(L["Disenchanted"])
end

-- ON CLICK: Loot management popup offspec button
function HeadCount:HeadCountFrameLootManagementPopupOffspecButton_Click()
	HeadCount:HeadCountFrameLootManagementPopupLooterButton_Set(L["Offspec"])
end

-- Sets the loot management popup looter text via the dropdown menu selection
-- @param looter The looter
function HeadCount:HeadCountFrameLootManagementPopupLooterButton_Set(looter)
	if (looter) then	
		HeadCountFrameLootManagementPopupLooterEditBox:SetText(looter)
	end
end

-- ON CLICK: Loot management popup source button   
function HeadCount:HeadCountFrameLootManagementPopupSourceButton_Click()
	local sourceButton = getglobal("HeadCountFrameLootManagementPopupSourceButton")
	if (dewdrop:IsOpen(sourceButton)) then
		dewdrop:Close()
		if (dewdrop:IsRegistered(sourceButton)) then
			dewdrop:Unregister(sourceButton)
		end
	else
		if (not dewdrop:IsRegistered(sourceButton)) then
			dewdrop:Register(sourceButton, 'children', function(level, value) HeadCount:HeadCountFrameLootManagementPopupSourceButton_CreateMenu(level, value) end, 'dontHook', true)	
		end
		
		dewdrop:Open(sourceButton)
	end	
end

-- Sets the loot management popup source text via the dropdown menu selection
-- @param source
function HeadCount:HeadCountFrameLootManagementPopupSourceButton_Set(source)
	if (source) then	
		HeadCountFrameLootManagementPopupSourceEditBox:SetText(source)
	end
end

-- ON CLICK: Raid announcement type button
function HeadCount:HeadCountFrameAnnouncementTypeButton_Click()
	local announcementTypeButton = HeadCountFrameAnnouncementTypeButton
	if (dewdrop:IsOpen(announcementTypeButton)) then
		dewdrop:Close()
		if (dewdrop:IsRegistered(announcementTypeButton)) then
			dewdrop:Unregister(announcementTypeButton)
		end
	else
		if (not dewdrop:IsRegistered(announcementTypeButton)) then
			dewdrop:Register(announcementTypeButton, 'children', function(level, value) HeadCount:HeadCountFrameAnnouncementTypeButton_CreateMenu(level, value) end, 'dontHook', true)	
		end
		
		dewdrop:Open(announcementTypeButton)
	end	
end

-- ON CLICK: Raid announcement type button
function HeadCount:HeadCountFrameAnnouncementChannelButton_Click()
	local channelButton = HeadCountFrameAnnouncementChannelButton
	if (dewdrop:IsOpen(channelButton)) then
		dewdrop:Close()
		if (dewdrop:IsRegistered(channelButton)) then
			dewdrop:Unregister(channelButton)
		end
	else
		if (not dewdrop:IsRegistered(channelButton)) then
			dewdrop:Register(channelButton, 'children', function(level, value) HeadCount:HeadCountFrameAnnouncementChannelButton_CreateMenu(level, value) end, 'dontHook', true)	
		end
		
		dewdrop:Open(channelButton)
	end	
end

-- ON CLICK: Raid announcement announce button
function HeadCount:HeadCountFrameAnnouncementAnnounceButton_Click()
	local typeString = HeadCountFrameAnnouncementTypeEditBoxButtonText:GetText()
	local channelString = HeadCountFrameAnnouncementChannelEditBoxButtonText:GetText()
	local channel = HeadCount.CHAT_CHANNELS[channelString]

	if ((typeString) and (channel)) then 
		-- valid channel
		HeadCount:DisableModalFrame() 	
		
		if (typeString == L["Announce wait list"]) then 
			HeadCount:announceWaitlist(channel)
		elseif (typeString == L["List wait list"]) then 
			local raidTracker = HeadCount:getRaidTracker() 
			raidTracker:processListWaitlist(channel)
		else
			if (not typeString) then 
				HeadCount:LogInformation(string.format(L["warning.announce.type"], HeadCount.TITLE, HeadCount.VERSION))	
			end
			
			if (not channel) then 
				HeadCount:LogInformation(string.format(L["warning.announce.channel"], HeadCount.TITLE, HeadCount.VERSION))	
			end
		end
	end
end

-- ON CLICK: Raid announcement cancel button
function HeadCount:HeadCountFrameAnnouncementCancelButton_Click()
	HeadCount:DisableModalFrame() 
end

-- ***********************************
-- ON ENTER FUNCTIONS
-- ***********************************
-- ON ENTER: Announce button
function HeadCount:HeadCountFrameRaidHistoryAnnounceButton_Enter()
	GameTooltip:SetOwner(getglobal(this:GetName()), "ANCHOR_RIGHT", -6, 0)
	GameTooltip:ClearLines()
	GameTooltip:AddLine(L["Raid announcement"], 0.63, 0.63, 1.0)
	
	local raidTracker = HeadCount:getRaidTracker()	
	local isWaitlistAcceptanceEnabled = raidTracker:IsWaitlistAcceptanceEnabled()
	if (isWaitlistAcceptanceEnabled) then 
		GameTooltip:AddLine(L["Announce wait list"] .. ": " .. L["Active"], 1.0, 1.0, 1.0)
	else
		GameTooltip:AddLine(L["Announce wait list"] .. ": " .. L["Inactive"], 1.0, 1.0, 1.0)
	end
	
	GameTooltip:Show()
end

-- ON ENTER: End active raid button
function HeadCount:HeadCountFrameRaidHistoryEndRaidButton_Enter()
	GameTooltip:SetOwner(getglobal(this:GetName()), "ANCHOR_RIGHT", -6, 0)
	GameTooltip:ClearLines()
	GameTooltip:AddLine(L["End active raid"], 0.63, 0.63, 1.0)
	GameTooltip:Show()
end
	
-- ON ENTER: Remove all raids button
function HeadCount:HeadCountFrameRaidHistoryRemoveAllButton_Enter() 
	GameTooltip:SetOwner(getglobal(this:GetName()), "ANCHOR_RIGHT", -6, 0)
	GameTooltip:ClearLines()
	GameTooltip:AddLine(L["Remove all raids"], 0.63, 0.63, 1.0)
	GameTooltip:Show()
end
	
-- ON ENTER: Raid export button				
function HeadCount:HeadCountFrameRaidHistoryContentTemplateExportButton_Enter()
	local raidId = tonumber(getglobal(this:GetParent():GetName() .. "Id"):GetText())
	local orderedRaidId = getglobal(this:GetParent():GetName() .. "Number"):GetText()
	local raidTime = getglobal(this:GetParent():GetName() .. "Time"):GetText()
	local zone = getglobal(this:GetParent():GetName() .. "Zone"):GetText()

	local raidTracker = HeadCount:getRaidTracker()	
	local selectedRaid = raidTracker:getRaidById(raidId)
	local difficulty = selectedRaid:getDifficulty()
	
	GameTooltip:SetOwner(this, "ANCHOR_RIGHT", -6, 0)
	GameTooltip:ClearLines()
	GameTooltip:AddLine(L["Export raid"] .. " " .. orderedRaidId .. ": ", 0.63, 0.63, 1.0)
	GameTooltip:AddLine(raidTime, 1.0, 1.0, 1.0)
	GameTooltip:AddLine(zone, 1.0, 1.0, 1.0)
	
	GameTooltip:Show()
						
	getglobal(this:GetParent():GetName() .. "MouseOver"):Show()
end
	
-- ON ENTER: Raid is selected
function HeadCount:HeadCountFrameRaidHistoryContentTemplateHitArea_Enter()
	getglobal(this:GetParent():GetName() .. "MouseOver"):Show()
end
	
-- ON ENTER: Raid delete button
function HeadCount:HeadCountFrameRaidHistoryContentTemplateDeleteButton_Enter()
	local raidId = tonumber(getglobal(this:GetParent():GetName() .. "Id"):GetText())
	local raidNumber = getglobal(this:GetParent():GetName() .. "Number"):GetText()
	local raidTime = getglobal(this:GetParent():GetName() .. "Time"):GetText()
	local zone = getglobal(this:GetParent():GetName() .. "Zone"):GetText()

	local raidTracker = HeadCount:getRaidTracker()	
	local selectedRaid = raidTracker:getRaidById(raidId)
	local difficulty = selectedRaid:getDifficulty()
	
	GameTooltip:SetOwner(this, "ANCHOR_RIGHT", -6, 0)
	GameTooltip:ClearLines()
	GameTooltip:AddLine(L["Remove raid"] .. " " .. raidNumber .. ": ", 0.63, 0.63, 1.0)
	GameTooltip:AddLine(raidTime, 1.0, 1.0, 1.0)
	GameTooltip:AddLine(zone, 1.0, 1.0, 1.0)
	
	GameTooltip:Show()
	
	getglobal(this:GetParent():GetName() .. "MouseOver"):Show()
end				
	
-- ON ENTER: Raid members button
function HeadCount:HeadCountFrameContentMembersButton_Enter() 
	local raidTracker = HeadCount:getRaidTracker()	
	local selectedRaid = raidTracker:getRaidById(HeadCountFrame.selectedRaidId)
	local raidZone = selectedRaid:getZone()
	local difficulty = selectedRaid:getDifficulty()
	
	GameTooltip:SetOwner(this, "ANCHOR_RIGHT", -6, 0)
	GameTooltip:ClearLines()
	GameTooltip:AddLine(L["View raid members"], 0.63, 0.63, 1.0)
	GameTooltip:AddLine(HeadCount:getDateTimeAsString(selectedRaid:retrieveStartingTime()), 1.0, 1.0, 1.0)
	
	if (raidZone) then
		GameTooltip:AddLine(raidZone, 1.0, 1.0, 1.0)
	end

	if (difficulty and HeadCount.INSTANCES[raidZone].hasMultiDifficulty) then
		local difficultyString = HeadCount.INSTANCE_DIFFICULTY[difficulty]
		GameTooltip:AddLine(L["Difficulty"] .. ": " .. difficultyString, 1.0, 1.0, 1.0)
	end	
	
	GameTooltip:AddLine(L["Number of members"] .. ": " .. selectedRaid:getNumberOfPlayers(), 1.0, 1.0, 1.0)	
	
	GameTooltip:Show()
end

-- ON ENTER: Raid wait list button
function HeadCount:HeadCountFrameContentWaitListButton_Enter()
	local raidTracker = HeadCount:getRaidTracker()	
	local selectedRaid = raidTracker:getRaidById(HeadCountFrame.selectedRaidId)
	local raidZone = selectedRaid:getZone()
	local difficulty = selectedRaid:getDifficulty()

	GameTooltip:SetOwner(this, "ANCHOR_RIGHT", -6, 0)
	GameTooltip:ClearLines()
	GameTooltip:AddLine(L["View wait list"], 0.63, 0.63, 1.0)
	GameTooltip:AddLine(HeadCount:getDateTimeAsString(selectedRaid:retrieveStartingTime()), 1.0, 1.0, 1.0)
	
	if (raidZone) then
		GameTooltip:AddLine(raidZone, 1.0, 1.0, 1.0)
	end

	if (difficulty and HeadCount.INSTANCES[raidZone].hasMultiDifficulty) then
		local difficultyString = HeadCount.INSTANCE_DIFFICULTY[difficulty]
		GameTooltip:AddLine(L["Difficulty"] .. ": " .. difficultyString, 1.0, 1.0, 1.0)
	end	
	
	GameTooltip:AddLine(L["Number of members"] .. ": " .. selectedRaid:getNumberOfWaitlistPlayers(), 1.0, 1.0, 1.0)		
	GameTooltip:AddLine()
	
	GameTooltip:Show()
end
	
-- ON ENTER: Raid boss button	
function HeadCount:HeadCountFrameContentBossButton_Enter() 
	local raidTracker = HeadCount:getRaidTracker()
	local selectedRaid = raidTracker:getRaidById(HeadCountFrame.selectedRaidId)
	local raidZone = selectedRaid:getZone()
	local difficulty = selectedRaid:getDifficulty()	
	
	GameTooltip:SetOwner(this, "ANCHOR_RIGHT", -6, 0)
	GameTooltip:ClearLines()
	GameTooltip:AddLine(L["View raid bosses"], 0.63, 0.63, 1.0)
	GameTooltip:AddLine(HeadCount:getDateTimeAsString(selectedRaid:retrieveStartingTime()), 1.0, 1.0, 1.0)
	if (raidZone) then
		GameTooltip:AddLine(raidZone, 1.0, 1.0, 1.0)
	end

	if (difficulty and HeadCount.INSTANCES[raidZone].hasMultiDifficulty) then
		local difficultyString = HeadCount.INSTANCE_DIFFICULTY[difficulty]
		GameTooltip:AddLine(L["Difficulty"] .. ": " .. difficultyString, 1.0, 1.0, 1.0)
	end	
	
	GameTooltip:AddLine(L["Number of bosses"] .. ": " .. selectedRaid:getNumberOfBosses(), 1.0, 1.0, 1.0)		
	
	GameTooltip:Show()
end

-- ON ENTER: Raid loot button
function HeadCount:HeadCountFrameContentLootButton_Enter() 
	local raidTracker = HeadCount:getRaidTracker()	
	local selectedRaid = raidTracker:getRaidById(HeadCountFrame.selectedRaidId)
	local raidZone = selectedRaid:getZone()
	local difficulty = selectedRaid:getDifficulty()
	
	GameTooltip:SetOwner(this, "ANCHOR_RIGHT", -6, 0)
	GameTooltip:ClearLines()
	GameTooltip:AddLine(L["View raid loot"], 0.63, 0.63, 1.0)
	GameTooltip:AddLine(HeadCount:getDateTimeAsString(selectedRaid:retrieveStartingTime()), 1.0, 1.0, 1.0)
	if (raidZone) then
		GameTooltip:AddLine(raidZone, 1.0, 1.0, 1.0)
	end

	if (difficulty and HeadCount.INSTANCES[raidZone].hasMultiDifficulty) then
		local difficultyString = HeadCount.INSTANCE_DIFFICULTY[difficulty]
		GameTooltip:AddLine(L["Difficulty"] .. ": " .. difficultyString, 1.0, 1.0, 1.0)
	end	
	
	GameTooltip:AddLine(L["Number of items"] .. ": " .. selectedRaid:numberOfLoots(), 1.0, 1.0, 1.0)	
	
	GameTooltip:Show()
end
	
-- ON ENTER: Raid member selection
function HeadCount:HeadCountFrameContentMembersTemplateHitArea_Enter()
	getglobal(this:GetParent():GetName() .. "MouseOver"):Show()
end
	
-- ON ENTER: Raid member delete button
function HeadCount:HeadCountFrameContentMembersTemplateDeleteButton_Enter()
	local raidTracker = HeadCount:getRaidTracker()	
	local selectedRaid = raidTracker:getRaidById(HeadCountFrame.selectedRaidId)
	local raidZone = selectedRaid:getZone()
	local difficulty = selectedRaid:getDifficulty()	
	
	local playerId = getglobal(this:GetParent():GetName() .. "Number"):GetText()
	local playerName = getglobal(this:GetParent():GetName() .. "Name"):GetText()

	GameTooltip:SetOwner(this, "ANCHOR_RIGHT", -6, 0)
	GameTooltip:ClearLines()
	GameTooltip:AddLine(L["Remove member"] .. " " .. playerId .. ": ", 0.63, 0.63, 1.0)
	GameTooltip:AddLine(playerName, 1.0, 1.0, 1.0)
	GameTooltip:AddLine(HeadCount:getDateTimeAsString(selectedRaid:retrieveStartingTime()), 1.0, 1.0, 1.0)
	
	if (raidZone) then
		GameTooltip:AddLine(raidZone, 1.0, 1.0, 1.0)
	end

	if (difficulty and HeadCount.INSTANCES[raidZone].hasMultiDifficulty) then
		local difficultyString = HeadCount.INSTANCE_DIFFICULTY[difficulty]
		GameTooltip:AddLine(L["Difficulty"] .. ": " .. difficultyString, 1.0, 1.0, 1.0)
	end	
	
	GameTooltip:Show()
						
	getglobal(this:GetParent():GetName() .. "MouseOver"):Show()
end

-- ON ENTER: Snapshot remove button	
function HeadCount:HeadCountFrameContentSnapshotTemplateRemoveButton_Enter()
	local raidTracker = HeadCount:getRaidTracker()	
	local selectedRaid = raidTracker:getRaidById(HeadCountFrame.selectedRaidId)
	local raidZone = selectedRaid:getZone()
	local difficulty = selectedRaid:getDifficulty()	
	
	local playerId = getglobal(this:GetParent():GetName() .. "Number"):GetText()
	local playerName = getglobal(this:GetParent():GetName() .. "Name"):GetText()

	GameTooltip:SetOwner(this, "ANCHOR_RIGHT", -6, 0)
	GameTooltip:ClearLines()
	GameTooltip:AddLine(L["Remove attendee"] .. " " .. playerId .. ": ", 0.63, 0.63, 1.0)
	GameTooltip:AddLine(playerName, 1.0, 1.0, 1.0)
	GameTooltip:AddLine(HeadCount:getDateTimeAsString(selectedRaid:retrieveStartingTime()), 1.0, 1.0, 1.0)
	
	if (raidZone) then
		GameTooltip:AddLine(raidZone, 1.0, 1.0, 1.0)
	end

	if (difficulty and HeadCount.INSTANCES[raidZone].hasMultiDifficulty) then
		local difficultyString = HeadCount.INSTANCE_DIFFICULTY[difficulty]
		GameTooltip:AddLine(L["Difficulty"] .. ": " .. difficultyString, 1.0, 1.0, 1.0)
	end	
	
	if (HeadCountFrame.bossName) then 
		GameTooltip:AddLine(L["Boss"] .. ": " .. HeadCountFrame.bossName, 1.0, 1.0, 1.0)
	end
	
	GameTooltip:Show()
end

-- ON ENTER: Raid wait list remove button
function HeadCount:HeadCountFrameContentWaitListTemplateRemoveButton_Enter()
	local raidTracker = HeadCount:getRaidTracker()	
	local selectedRaid = raidTracker:getRaidById(HeadCountFrame.selectedRaidId)
	local raidZone = selectedRaid:getZone()
	
	local waitListId = getglobal(this:GetParent():GetName() .. "Number"):GetText()
	local name = getglobal(this:GetParent():GetName() .. "Name"):GetText()

	GameTooltip:SetOwner(this, "ANCHOR_RIGHT", -6, 0)
	GameTooltip:ClearLines()
	GameTooltip:AddLine(L["Remove wait list member"] .. " " .. waitListId .. ": ", 0.63, 0.63, 1.0)
	GameTooltip:AddLine(name, 1.0, 1.0, 1.0)

	if (raidZone) then
		GameTooltip:AddLine(raidZone, 1.0, 1.0, 1.0)
	end

	GameTooltip:Show()	
end
	
-- ON ENTER: Raid boss selection	
function HeadCount:HeadCountFrameContentBossTemplateHitArea_Enter()
	getglobal(this:GetParent():GetName() .. "MouseOver"):Show()
end

-- ON ENTER: Raid boss delete button
function HeadCount:HeadCountFrameContentBossTemplateDeleteButton_Enter()
	local raidTracker = HeadCount:getRaidTracker()	
	local selectedRaid = raidTracker:getRaidById(HeadCountFrame.selectedRaidId)
	local raidZone = selectedRaid:getZone()
	local difficulty = selectedRaid:getDifficulty()
	
	local bossId = getglobal(this:GetParent():GetName() .. "Number"):GetText()
	local bossName = getglobal(this:GetParent():GetName() .. "Name"):GetText()

	GameTooltip:SetOwner(this, "ANCHOR_RIGHT", -6, 0)
	GameTooltip:ClearLines()
	GameTooltip:AddLine(L["Remove boss"] .. " " .. bossId .. ": ", 0.63, 0.63, 1.0)
	GameTooltip:AddLine(bossName, 1.0, 1.0, 1.0)
	GameTooltip:AddLine(HeadCount:getDateTimeAsString(selectedRaid:retrieveStartingTime()), 1.0, 1.0, 1.0)
	
	if (raidZone) then
		GameTooltip:AddLine(raidZone, 1.0, 1.0, 1.0)
	end
	
	if (difficulty and HeadCount.INSTANCES[raidZone].hasMultiDifficulty) then
		local difficultyString = HeadCount.INSTANCE_DIFFICULTY[difficulty]
		GameTooltip:AddLine(L["Difficulty"] .. ": " .. difficultyString, 1.0, 1.0, 1.0)
	end	
	
	GameTooltip:Show()
						
	getglobal(this:GetParent():GetName() .. "MouseOver"):Show()	
end

-- ON ENTER: Raid loot texture button.
function HeadCount:HeadCountFrameContentLootTemplateTextureButton_Enter() 
	local link = getglobal(this:GetParent():GetName() .. "NameButtonText"):GetText()
	local itemId = getglobal(this:GetParent():GetName() .. "Id"):GetText()
	
	local itemName, itemLink, itemQuality, itemLevel, itemMinLevel, itemType, itemSubType, itemCount, itemEquipLoc, itemTexture = GetItemInfo(itemId)

	if ((link) and (link ~= L["Item unavailable"])) then
		GameTooltip:SetOwner(this, "ANCHOR_RIGHT", -6, 0)
		GameTooltip:ClearLines()
		GameTooltip:SetHyperlink(link)
		GameTooltip:AddLine(L["Item level"] .. ": " .. itemLevel, 1.0, 1.0, 1.0)				
		GameTooltip:Show()
	else
		GameTooltip:SetOwner(this, "ANCHOR_RIGHT", -6, 0)
		GameTooltip:ClearLines()
		GameTooltip:AddLine(L["Item unavailable"], 0.63, 0.63, 1.0)
		GameTooltip:AddLine(L["info.item.unsafe"] .. " (" .. itemId .. ")", 1.0, 1.0, 1.0)		
		GameTooltip:AddLine(L["info.item.query"], 1.0, 1.0, 1.0)
		GameTooltip:AddLine(L["info.item.requery"], 1.0, 1.0, 1.0)		
		GameTooltip:Show()	
	end
end	

-- ON ENTER: Raid loot management button	
function HeadCount:HeadCountFrameContentLootTemplateManagementButton_Enter() 
	local raidTracker = HeadCount:getRaidTracker()	
	local selectedRaid = raidTracker:getRaidById(HeadCountFrame.selectedRaidId)

	local lootName = getglobal(this:GetParent():GetName() .. "NameButtonText"):GetText()
	local lootId = tonumber(getglobal(this:GetParent():GetName() .. "Number"):GetText())
	local loot = selectedRaid:retrieveLoot(lootId)
	
	local cost = loot:getCost()
	if (not cost) then
		cost = 0
	end

	GameTooltip:SetOwner(this, "ANCHOR_RIGHT", -6, 0)
	GameTooltip:ClearLines()
	GameTooltip:AddLine(L["Manage loot"] .. ": ", 0.63, 0.63, 1.0)	
	GameTooltip:AddLine(lootName)
	GameTooltip:AddLine(L["Looted by"] .. ": " .. loot:getPlayerName(), 1.0, 1.0, 1.0)	
	
	local lootSource = loot:getSource()
	if (lootSource) then
		GameTooltip:AddLine(L["Source"] .. ": " .. lootSource, 1.0, 1.0, 1.0)	
	else
		GameTooltip:AddLine(L["Source"] .. ": " .. L["Trash mob"], 1.0, 1.0, 1.0)	
	end
	
	GameTooltip:AddLine(L["Loot cost"] .. ": " .. cost, 1.0, 1.0, 1.0)	

	local lootNote = loot:getNote()	
	if ((lootNote) and (HeadCount:isString(lootNote))) then
		GameTooltip:AddLine(L["Note"] .. ": " .. lootNote, 1.0, 1.0, 1.0)	
	end
	
	GameTooltip:Show()	
end

-- ON ENTER: Raid loot delete button	
function HeadCount:HeadCountFrameContentLootTemplateDeleteButton_Enter() 
	local raidTracker = HeadCount:getRaidTracker()	
	local selectedRaid = raidTracker:getRaidById(HeadCountFrame.selectedRaidId)
	
	local lootName = getglobal(this:GetParent():GetName() .. "NameButtonText"):GetText()
	local lootId = tonumber(getglobal(this:GetParent():GetName() .. "Number"):GetText())
	local loot = selectedRaid:retrieveLoot(lootId)

	local cost = loot:getCost()
	if (not cost) then
		cost = 0
	end
	
	GameTooltip:SetOwner(this, "ANCHOR_RIGHT", -6, 0)
	GameTooltip:ClearLines()
	GameTooltip:AddLine(L["Remove loot"] .. ": ", 0.63, 0.63, 1.0)
	GameTooltip:AddLine(lootName)
	GameTooltip:AddLine(L["Looted by"] .. ": " .. loot:getPlayerName(), 1.0, 1.0, 1.0)	
	
	local lootSource = loot:getSource()
	if (lootSource) then
		GameTooltip:AddLine(L["Source"] .. ": " .. lootSource, 1.0, 1.0, 1.0)	
	else
		GameTooltip:AddLine(L["Source"] .. ": " .. L["Trash mob"], 1.0, 1.0, 1.0)	
	end
	
	GameTooltip:AddLine(L["Loot cost"] .. ": " .. cost, 1.0, 1.0, 1.0)	
	
	local lootNote = loot:getNote()	
	if ((lootNote) and (HeadCount:isString(lootNote))) then
		GameTooltip:AddLine(L["Note"] .. ": " .. lootNote, 1.0, 1.0, 1.0)	
	end
	
	GameTooltip:Show()
end
	
-- ON ENTER: Loot management bank button
function HeadCount:HeadCountFrameLootManagementBankButton_Enter()
	GameTooltip:SetOwner(this, "ANCHOR_RIGHT", -6, 0)
	GameTooltip:ClearLines()
	GameTooltip:AddLine(L["Assign loot to bank"], 0.63, 0.63, 1.0)
	GameTooltip:Show()
end

-- ON ENTER: Loot management disenchanted button
function HeadCount:HeadCountFrameLootManagementDisenchantedButton_Enter()
	GameTooltip:SetOwner(this, "ANCHOR_RIGHT", -6, 0)
	GameTooltip:ClearLines()
	GameTooltip:AddLine(L["Assign loot as disenchanted"], 0.63, 0.63, 1.0)
	GameTooltip:Show()
end

-- ON ENTER: Loot management offspec button
function HeadCount:HeadCountFrameLootManagementOffspecButton_Enter()
	GameTooltip:SetOwner(this, "ANCHOR_RIGHT", -6, 0)
	GameTooltip:ClearLines()
	GameTooltip:AddLine(L["Assign loot as offspec"], 0.63, 0.63, 1.0)
	GameTooltip:Show()
end
	
-- ***********************************
-- ON LEAVE FUNCTIONS
-- ***********************************
-- ON LEAVE: Generic function to hide tooltip 
function HeadCount:HideUITooltip()
	GameTooltip:Hide()
end

-- ON LEAVE: Generic function to hide mouse over
function HeadCount:HideMouseOver()
	getglobal(this:GetParent():GetName() .. "MouseOver"):Hide()
end

-- ***********************************
-- ON VERTICAL SCROLL FUNCTIONS
-- ***********************************
-- ON VERTICAL SCROLL: Raid history content scroll
function HeadCount:HeadCountFrameRaidHistoryContentScroll_VerticalScroll(self, offset)
	FauxScrollFrame_OnVerticalScroll(self, offset, 16, function() HeadCount:HeadCountFrameRaidHistoryContentScroll_Update() end)
end

-- ON VERTICAL SCROLL: Content members scroll
function HeadCount:HeadCountFrameContentMembersScroll_VerticalScroll(self, offset)
	FauxScrollFrame_OnVerticalScroll(self, offset, 16, function() HeadCount:HeadCountFrameContentMembersScroll_Update() end)
end

-- ON VERTICAL SCROLL: Content wait list scroll
function HeadCount:HeadCountFrameContentWaitListScroll_VerticalScroll(self, offset)
	FauxScrollFrame_OnVerticalScroll(self, offset, 16, function() HeadCount:HeadCountFrameContentWaitListScroll_Update() end)
end

-- ON VERTICAL SCROLL: Content boss scroll
function HeadCount:HeadCountFrameContentBossScroll_VerticalScroll(self, offset)
	FauxScrollFrame_OnVerticalScroll(self, offset, 16, function() HeadCount:HeadCountFrameContentBossScroll_Update() end)
end

-- ON VERTICAL SCROLL: Content loot scroll
function HeadCount:HeadCountFrameContentLootScroll_VerticalScroll(self, offset)
	FauxScrollFrame_OnVerticalScroll(self, offset, 40, function() HeadCount:HeadCountFrameContentLootScroll_Update() end)
end

-- ON VERTICAL SCROLL: Content snapshot scroll
function HeadCount:HeadCountFrameContentSnapshotScroll_VerticalScroll(self, offset)
	FauxScrollFrame_OnVerticalScroll(self, offset, 16, function() HeadCount:HeadCountFrameContentSnapshotScroll_Update() end)
end

-- ON VERTICAL SCROLL: Content player scroll
function HeadCount:HeadCountFrameContentPlayerScroll_VerticalScroll(self, offset)
	FauxScrollFrame_OnVerticalScroll(self, offset, 16, function() HeadCount:HeadCountFrameContentPlayerScroll_Update() end)
end

-- ***********************************
-- ON HYPERLINK ENTER FUNCTIONS
-- ***********************************
-- ON HYPERLINK ENTER: Player information template line
function HeadCount:HeadCountFrameContentPlayerTemplateSimpleHTML_HyperlinkEnter(frame, link, ...)
	if (link) then
		if ((string.match(link,"item:")) or (string.match(link,"enchant:"))) then
			GameTooltip:SetOwner(this, "ANCHOR_CURSOR", 0, 0)
			GameTooltip:ClearLines()
			GameTooltip:SetHyperlink(link)
			GameTooltip:Show()
		end
	end
end

-- ***********************************
-- ON HYPERLINK ENTER CLICK
-- ***********************************
-- ON HYPERLINK CLICK: Player information template line
function HeadCount:HeadCountFrameContentPlayerTemplateSimpleHTML_HyperlinkClick(frame, link, ...)
	if (link) then 
		if ((string.match(link,"item:")) or (string.match(link,"enchant:"))) then
			-- item info did return
			if (IsShiftKeyDown()) then
				-- shift key is held down, link the item
				ChatEdit_InsertLink(link)
			else
				HeadCount:HeadCountFrame_Update()	-- refresh
			end	
		end
	else
		GameTooltip:SetHyperlink(link)
		HeadCount:HeadCountFrame_Update()	-- refresh
	end
end

-- ***********************************
-- DROP DOWN MENUS
-- ***********************************
-- CREATE MENU: Raid announcement type menu
-- @param level The drop down menu level
-- @param value The drop down menu value
function HeadCount:HeadCountFrameAnnouncementTypeButton_CreateMenu(level, value)
	if (1 == level) then
		dewdrop:AddLine('text', L["Type"] .. ":", 'isTitle', true)	
		dewdrop:AddLine()					
		dewdrop:AddLine('text', L["Announce wait list"],
						'hasArrow', false,
						'closeWhenClicked', true, 
						'value', "announcewaitlist",
						'tooltipTitle', L["Announce wait list"],
						'tooltipText', L["info.announce.type.announcewaitlist"], 
						'func', function(announcementType) HeadCountFrameAnnouncementTypeEditBoxButtonText:SetText(announcementType) end, 
						'arg1', L["Announce wait list"]
						)						
		dewdrop:AddLine('text', L["List wait list"],
						'hasArrow', false,
						'closeWhenClicked', true, 
						'value', "listwaitlist",
						'tooltipTitle', L["List wait list"],
						'tooltipText', L["info.announce.type.listwaitlist"], 
						'func', function(announcementType) HeadCountFrameAnnouncementTypeEditBoxButtonText:SetText(announcementType) end, 
						'arg1', L["List wait list"]
						)	
		dewdrop:AddLine()
		dewdrop:AddLine('text', L["Close menu"], 
						'closeWhenClicked', true, 
						'tooltipTitle', L["Close menu"],
						'tooltipText', L["Close the menu"]
						)	
	end 
end

-- CREATE MENU: Raid announcement channel menu
-- @param level The drop down menu level
-- @param value The drop down menu value
function HeadCount:HeadCountFrameAnnouncementChannelButton_CreateMenu(level, value)
	if (1 == level) then
		dewdrop:AddLine('text', L["Channel"] .. ":", 'isTitle', true)	
		dewdrop:AddLine()	
		dewdrop:AddLine('text', L["Guild"],
						'hasArrow', false,
						'closeWhenClicked', true, 
						'value', "channel",
						'tooltipTitle', L["Guild"],
						'tooltipText', L["info.channel.guild"], 
						'func', function(channel) HeadCountFrameAnnouncementChannelEditBoxButtonText:SetText(channel) end, 
						'arg1', L["Guild"]
						)			
		dewdrop:AddLine('text', L["Officer"],
						'hasArrow', false,
						'closeWhenClicked', true, 
						'value', "channel",
						'tooltipTitle', L["Officer"],
						'tooltipText', L["info.channel.officer"], 
						'func', function(channel) HeadCountFrameAnnouncementChannelEditBoxButtonText:SetText(channel) end, 
						'arg1', L["Officer"]
						)			
		dewdrop:AddLine('text', L["Party"],
						'hasArrow', false,
						'closeWhenClicked', true, 
						'value', "channel",
						'tooltipTitle', L["Party"],
						'tooltipText', L["info.channel.party"], 
						'func', function(channel) HeadCountFrameAnnouncementChannelEditBoxButtonText:SetText(channel) end, 
						'arg1', L["Party"]
						)
		dewdrop:AddLine('text', L["Raid"],
						'hasArrow', false,
						'closeWhenClicked', true, 
						'value', "channel",
						'tooltipTitle', L["Raid"],
						'tooltipText', L["info.channel.raid"], 
						'func', function(channel) HeadCountFrameAnnouncementChannelEditBoxButtonText:SetText(channel) end, 
						'arg1', L["Raid"]
						)
		dewdrop:AddLine('text', L["Say"],
						'hasArrow', false,
						'closeWhenClicked', true, 
						'value', "channel",
						'tooltipTitle', L["Say"],
						'tooltipText', L["info.channel.say"], 
						'func', function(channel) HeadCountFrameAnnouncementChannelEditBoxButtonText:SetText(channel) end, 
						'arg1', L["Say"]
						)
		dewdrop:AddLine('text', L["Yell"],
						'hasArrow', false,
						'closeWhenClicked', true, 
						'value', "channel",
						'tooltipTitle', L["Yell"],
						'tooltipText', L["info.channel.yell"], 
						'func', function(channel) HeadCountFrameAnnouncementChannelEditBoxButtonText:SetText(channel) end, 
						'arg1', L["Yell"]
						)						
		dewdrop:AddLine()
		dewdrop:AddLine('text', L["Close menu"], 
						'closeWhenClicked', true, 
						'tooltipTitle', L["Close menu"],
						'tooltipText', L["Close the menu"]
						)			
	end
end

-- CREATE MENU: The loot management looter menu
-- @param level The drop down menu level
-- @param value The drop down menu value
function HeadCount:HeadCountFrameLootManagementLooterButton_CreateMenu(level, value)
	local raidTracker = HeadCount:getRaidTracker()	
	local raid = raidTracker:getRaidById(HeadCountFrameLootManagement.raidId)
	local playerList = raid:retrievePlayerListByClass()
	--HeadCountFrameLootManagement.lootId = lootId	
	
	if (1 == level) then
		dewdrop:AddLine('text', L["Looted by"] .. ":", 'isTitle', true)	
		
		if ((# playerList["Death Knight"]) > 0) then
			dewdrop:AddLine('text', L["Death Knight"],
							'textR', HeadCount.CLASS_COLORS["Death Knight"].r, 
							'textG', HeadCount.CLASS_COLORS["Death Knight"].g, 
							'textB', HeadCount.CLASS_COLORS["Death Knight"].b, 
							'hasArrow', true,
							'value', "death knight",
							'tooltipTitle', L["Death Knight"],
							'tooltipText', L["Death Knight players"]
							)	
		else
			dewdrop:AddLine('text', L["Death Knight"],	'disabled', true, 'tooltipTitle', L["Death Knight"], 'tooltipText', L["Death Knight players"])			
		end

		
		if ((# playerList["Druid"]) > 0) then
			dewdrop:AddLine('text', L["Druid"],
							'textR', HeadCount.CLASS_COLORS["Druid"].r, 
							'textG', HeadCount.CLASS_COLORS["Druid"].g, 
							'textB', HeadCount.CLASS_COLORS["Druid"].b, 
							'hasArrow', true,
							'value', "druid",
							'tooltipTitle', L["Druid"],
							'tooltipText', L["Druid players"]
							)	
		else
			dewdrop:AddLine('text', L["Druid"],	'disabled', true, 'tooltipTitle', L["Druid"], 'tooltipText', L["Druid players"])			
		end

		if ((# playerList["Hunter"]) > 0) then		
			dewdrop:AddLine('text', L["Hunter"],
							'textR', HeadCount.CLASS_COLORS["Hunter"].r, 
							'textG', HeadCount.CLASS_COLORS["Hunter"].g, 
							'textB', HeadCount.CLASS_COLORS["Hunter"].b, 		
							'hasArrow', true,
							'value', "hunter",
							'tooltipTitle', L["Hunter"],
							'tooltipText', L["Hunter players"]
							)		
		else
			dewdrop:AddLine('text', L["Hunter"], 'disabled', true, 'tooltipTitle', L["Hunter"], 'tooltipText', L["Hunter players"])					
		end

		if ((# playerList["Mage"]) > 0) then				
			dewdrop:AddLine('text', L["Mage"],
							'textR', HeadCount.CLASS_COLORS["Mage"].r, 
							'textG', HeadCount.CLASS_COLORS["Mage"].g, 
							'textB', HeadCount.CLASS_COLORS["Mage"].b, 				
							'hasArrow', true,
							'value', "mage",
							'tooltipTitle', L["Mage"],
							'tooltipText', L["Mage players"]
							)
		else
			dewdrop:AddLine('text', L["Mage"], 'disabled', true, 'tooltipTitle', L["Mage"], 'tooltipText', L["Mage players"])					
		end
		
		if ((# playerList["Paladin"]) > 0) then								
			dewdrop:AddLine('text', L["Paladin"],
							'textR', HeadCount.CLASS_COLORS["Paladin"].r, 
							'textG', HeadCount.CLASS_COLORS["Paladin"].g, 
							'textB', HeadCount.CLASS_COLORS["Paladin"].b, 						
							'hasArrow', true,
							'value', "paladin",
							'tooltipTitle', L["Paladin"],
							'tooltipText', L["Paladin players"]
							)			
		else
			dewdrop:AddLine('text', L["Paladin"], 'disabled', true, 'tooltipTitle', L["Paladin"], 'tooltipText', L["Paladin players"])					
		end

		if ((# playerList["Priest"]) > 0) then								
			dewdrop:AddLine('text', L["Priest"],
							'textR', HeadCount.CLASS_COLORS["Priest"].r, 
							'textG', HeadCount.CLASS_COLORS["Priest"].g, 
							'textB', HeadCount.CLASS_COLORS["Priest"].b, 								
							'hasArrow', true,
							'value', "priest",
							'tooltipTitle', L["Priest"],
							'tooltipText', L["Priest players"]
							)		
		else
			dewdrop:AddLine('text', L["Priest"], 'disabled', true, 'tooltipTitle', L["Priest"], 'tooltipText', L["Priest players"])
		end

		if ((# playerList["Rogue"]) > 0) then								
		dewdrop:AddLine('text', L["Rogue"],
						'textR', HeadCount.CLASS_COLORS["Rogue"].r, 
						'textG', HeadCount.CLASS_COLORS["Rogue"].g, 
						'textB', HeadCount.CLASS_COLORS["Rogue"].b, 										
						'hasArrow', true,
						'value', "rogue",
						'tooltipTitle', L["Rogue"],
						'tooltipText', L["Rogue players"]
						)		
		else
			dewdrop:AddLine('text', L["Rogue"], 'disabled', true, 'tooltipTitle', L["Rogue"], 'tooltipText', L["Rogue players"])
		end

		if ((# playerList["Shaman"]) > 0) then								
			dewdrop:AddLine('text', L["Shaman"],
							'textR', HeadCount.CLASS_COLORS["Shaman"].r, 
							'textG', HeadCount.CLASS_COLORS["Shaman"].g, 
							'textB', HeadCount.CLASS_COLORS["Shaman"].b, 												
							'hasArrow', true,
							'value', "shaman",
							'tooltipTitle', L["Shaman"],
							'tooltipText', L["Shaman players"]
							)		
		else
			dewdrop:AddLine('text', L["Shaman"], 'disabled', true, 'tooltipTitle', L["Shaman"], 'tooltipText', L["Shaman players"])
		end

		if ((# playerList["Warlock"]) > 0) then								
			dewdrop:AddLine('text', L["Warlock"],
							'textR', HeadCount.CLASS_COLORS["Warlock"].r, 
							'textG', HeadCount.CLASS_COLORS["Warlock"].g, 
							'textB', HeadCount.CLASS_COLORS["Warlock"].b, 														
							'hasArrow', true,
							'value', "warlock",
							'tooltipTitle', L["Warlock"],
							'tooltipText', L["Warlock players"]
							)
		else
			dewdrop:AddLine('text', L["Warlock"], 'disabled', true, 'tooltipTitle', L["Warlock"], 'tooltipText', L["Warlock players"])
		end
						
		if ((# playerList["Warrior"]) > 0) then								
			dewdrop:AddLine('text', L["Warrior"],
							'textR', HeadCount.CLASS_COLORS["Warrior"].r, 
							'textG', HeadCount.CLASS_COLORS["Warrior"].g, 
							'textB', HeadCount.CLASS_COLORS["Warrior"].b, 																
							'hasArrow', true,
							'value', "warrior",
							'tooltipTitle', L["Warrior"],
							'tooltipText', L["Warrior players"]
							)
		else
			dewdrop:AddLine('text', L["Warrior"], 'disabled', true, 'tooltipTitle', L["Warrior"], 'tooltipText', L["Warrior players"])
		end
			
		if ((# playerList["Unknown"]) > 0) then								
			dewdrop:AddLine('text', L["Unknown"],
							'textR', HeadCount.CLASS_COLORS["Unknown"].r, 
							'textG', HeadCount.CLASS_COLORS["Unknown"].g, 
							'textB', HeadCount.CLASS_COLORS["Unknown"].b, 																
							'hasArrow', true,
							'value', "unknown",
							'tooltipTitle', L["Unknown"],
							'tooltipText', L["Unknown players"]
							)
		else
			dewdrop:AddLine('text', L["Unknown"], 'disabled', true, 'tooltipTitle', L["Unknown"], 'tooltipText', L["Unknown players"])
		end
		
		dewdrop:AddLine()					
		dewdrop:AddLine('text', L["Bank"],
						'hasArrow', false,
						'closeWhenClicked', true, 
						'value', "bank",
						'tooltipTitle', L["Bank"],
						'tooltipText', L["Assign loot to bank"], 
						'func', function(looter) HeadCount:HeadCountFrameLootManagementLooterButton_Set(looter) end, 
						'arg1', L["Bank"]						
						)
		dewdrop:AddLine('text', L["Disenchanted"],
						'hasArrow', false,
						'closeWhenClicked', true, 
						'value', "bank",
						'tooltipTitle', L["Disenchanted"],
						'tooltipText', L["Assign loot as disenchanted"], 
						'func', function(looter) HeadCount:HeadCountFrameLootManagementLooterButton_Set(looter) end, 
						'arg1', L["Disenchanted"]												
						)										
		dewdrop:AddLine('text', L["Offspec"],
						'hasArrow', false,
						'closeWhenClicked', true, 						
						'value', "bank",
						'tooltipTitle', L["Offspec"],
						'tooltipText', L["Assign loot as offspec"], 
						'func', function(looter) HeadCount:HeadCountFrameLootManagementLooterButton_Set(looter) end, 
						'arg1', L["Offspec"]
						)																
		dewdrop:AddLine()
		dewdrop:AddLine('text', L["Close menu"], 
						'closeWhenClicked', true, 
						'tooltipTitle', L["Close menu"],
						'tooltipText', L["Close the menu"]
						)		
	elseif (level == 2) then
		if (value == "death knight") then 
			for k,v in ipairs(playerList["Death Knight"]) do 
				HeadCount:HeadCountFrameLootManagementLooterButton_AddPlayerLine("Death Knight", v)			
			end
		elseif (value == "druid") then
			for k,v in ipairs(playerList["Druid"]) do
				HeadCount:HeadCountFrameLootManagementLooterButton_AddPlayerLine("Druid", v)			
			end		
		elseif (value == "hunter") then
			for k,v in ipairs(playerList["Hunter"]) do
				HeadCount:HeadCountFrameLootManagementLooterButton_AddPlayerLine("Hunter", v)			
			end		
		elseif (value == "mage") then
			for k,v in ipairs(playerList["Mage"]) do
				HeadCount:HeadCountFrameLootManagementLooterButton_AddPlayerLine("Mage", v)			
			end	
		elseif (value == "paladin") then
			for k,v in ipairs(playerList["Paladin"]) do
				HeadCount:HeadCountFrameLootManagementLooterButton_AddPlayerLine("Paladin", v)
			end				
		elseif (value == "priest") then
			for k,v in ipairs(playerList["Priest"]) do
				HeadCount:HeadCountFrameLootManagementLooterButton_AddPlayerLine("Priest", v)
			end				
		elseif (value == "rogue") then
			for k,v in ipairs(playerList["Rogue"]) do
				HeadCount:HeadCountFrameLootManagementLooterButton_AddPlayerLine("Rogue", v)			
			end				
		elseif (value == "shaman") then
			for k,v in ipairs(playerList["Shaman"]) do
				HeadCount:HeadCountFrameLootManagementLooterButton_AddPlayerLine("Shaman", v)
			end										
		elseif (value == "warlock") then
			for k,v in ipairs(playerList["Warlock"]) do
				HeadCount:HeadCountFrameLootManagementLooterButton_AddPlayerLine("Warlock", v)
			end							
		elseif (value == "warrior") then
			for k,v in ipairs(playerList["Warrior"]) do
				HeadCount:HeadCountFrameLootManagementLooterButton_AddPlayerLine("Warrior", v)
			end				
		elseif (value == "unknown") then
			for k,v in ipairs(playerList["Unknown"]) do 
				HeadCount:HeadCountFrameLootManagementLooterButton_AddPlayerLine("Unknown", v)
			end
		end
	end						
end

-- Add a player line to the looted by drop down menu
-- @param className The class name.
-- @param playerName The player name
function HeadCount:HeadCountFrameLootManagementLooterButton_AddPlayerLine(className, playerName)
	dewdrop:AddLine('text', playerName,
					'textR', HeadCount.CLASS_COLORS[className].r, 
					'textG', HeadCount.CLASS_COLORS[className].g, 
					'textB', HeadCount.CLASS_COLORS[className].b, 				
					'closeWhenClicked', true, 
					'tooltipTitle', L[className], 
					'tooltipText', playerName, 
					'func', function(looter) HeadCount:HeadCountFrameLootManagementLooterButton_Set(looter) end, 
					'arg1', playerName)			
end

function HeadCount:HeadCountFrameLootManagementPopupLooterButton_CreateMenu(level, value)
	local raidTracker = HeadCount:getRaidTracker()	
	local raid = raidTracker:getRaidById(HeadCountFrame.lootManagementPopupRaidId)
	local playerList = raid:retrievePlayerListByClass()
	--HeadCountFrameLootManagement.lootId = lootId	
	
	if (1 == level) then
		dewdrop:AddLine('text', L["Looted by"] .. ":", 'isTitle', true)	
		
		if ((# playerList["Death Knight"]) > 0) then
			dewdrop:AddLine('text', L["Death Knight"],
							'textR', HeadCount.CLASS_COLORS["Death Knight"].r, 
							'textG', HeadCount.CLASS_COLORS["Death Knight"].g, 
							'textB', HeadCount.CLASS_COLORS["Death Knight"].b, 
							'hasArrow', true,
							'value', "death knight",
							'tooltipTitle', L["Death Knight"],
							'tooltipText', L["Death Knight players"]
							)	
		else
			dewdrop:AddLine('text', L["Death Knight"],	'disabled', true, 'tooltipTitle', L["Death Knight"], 'tooltipText', L["Death Knight players"])			
		end
		
		if ((# playerList["Druid"]) > 0) then
			dewdrop:AddLine('text', L["Druid"],
							'textR', HeadCount.CLASS_COLORS["Druid"].r, 
							'textG', HeadCount.CLASS_COLORS["Druid"].g, 
							'textB', HeadCount.CLASS_COLORS["Druid"].b, 
							'hasArrow', true,
							'value', "druid",
							'tooltipTitle', L["Druid"],
							'tooltipText', L["Druid players"]
							)	
		else
			dewdrop:AddLine('text', L["Druid"],	'disabled', true, 'tooltipTitle', L["Druid"], 'tooltipText', L["Druid players"])			
		end

		if ((# playerList["Hunter"]) > 0) then		
			dewdrop:AddLine('text', L["Hunter"],
							'textR', HeadCount.CLASS_COLORS["Hunter"].r, 
							'textG', HeadCount.CLASS_COLORS["Hunter"].g, 
							'textB', HeadCount.CLASS_COLORS["Hunter"].b, 		
							'hasArrow', true,
							'value', "hunter",
							'tooltipTitle', L["Hunter"],
							'tooltipText', L["Hunter players"]
							)		
		else
			dewdrop:AddLine('text', L["Hunter"], 'disabled', true, 'tooltipTitle', L["Hunter"], 'tooltipText', L["Hunter players"])					
		end

		if ((# playerList["Mage"]) > 0) then				
			dewdrop:AddLine('text', L["Mage"],
							'textR', HeadCount.CLASS_COLORS["Mage"].r, 
							'textG', HeadCount.CLASS_COLORS["Mage"].g, 
							'textB', HeadCount.CLASS_COLORS["Mage"].b, 				
							'hasArrow', true,
							'value', "mage",
							'tooltipTitle', L["Mage"],
							'tooltipText', L["Mage players"]
							)
		else
			dewdrop:AddLine('text', L["Mage"], 'disabled', true, 'tooltipTitle', L["Mage"], 'tooltipText', L["Mage players"])					
		end
		
		if ((# playerList["Paladin"]) > 0) then								
			dewdrop:AddLine('text', L["Paladin"],
							'textR', HeadCount.CLASS_COLORS["Paladin"].r, 
							'textG', HeadCount.CLASS_COLORS["Paladin"].g, 
							'textB', HeadCount.CLASS_COLORS["Paladin"].b, 						
							'hasArrow', true,
							'value', "paladin",
							'tooltipTitle', L["Paladin"],
							'tooltipText', L["Paladin players"]
							)			
		else
			dewdrop:AddLine('text', L["Paladin"], 'disabled', true, 'tooltipTitle', L["Paladin"], 'tooltipText', L["Paladin players"])					
		end

		if ((# playerList["Priest"]) > 0) then								
			dewdrop:AddLine('text', L["Priest"],
							'textR', HeadCount.CLASS_COLORS["Priest"].r, 
							'textG', HeadCount.CLASS_COLORS["Priest"].g, 
							'textB', HeadCount.CLASS_COLORS["Priest"].b, 								
							'hasArrow', true,
							'value', "priest",
							'tooltipTitle', L["Priest"],
							'tooltipText', L["Priest players"]
							)		
		else
			dewdrop:AddLine('text', L["Priest"], 'disabled', true, 'tooltipTitle', L["Priest"], 'tooltipText', L["Priest players"])
		end

		if ((# playerList["Rogue"]) > 0) then								
		dewdrop:AddLine('text', L["Rogue"],
						'textR', HeadCount.CLASS_COLORS["Rogue"].r, 
						'textG', HeadCount.CLASS_COLORS["Rogue"].g, 
						'textB', HeadCount.CLASS_COLORS["Rogue"].b, 										
						'hasArrow', true,
						'value', "rogue",
						'tooltipTitle', L["Rogue"],
						'tooltipText', L["Rogue players"]
						)		
		else
			dewdrop:AddLine('text', L["Rogue"], 'disabled', true, 'tooltipTitle', L["Rogue"], 'tooltipText', L["Rogue players"])
		end

		if ((# playerList["Shaman"]) > 0) then								
			dewdrop:AddLine('text', L["Shaman"],
							'textR', HeadCount.CLASS_COLORS["Shaman"].r, 
							'textG', HeadCount.CLASS_COLORS["Shaman"].g, 
							'textB', HeadCount.CLASS_COLORS["Shaman"].b, 												
							'hasArrow', true,
							'value', "shaman",
							'tooltipTitle', L["Shaman"],
							'tooltipText', L["Shaman players"]
							)		
		else
			dewdrop:AddLine('text', L["Shaman"], 'disabled', true, 'tooltipTitle', L["Shaman"], 'tooltipText', L["Shaman players"])
		end

		if ((# playerList["Warlock"]) > 0) then								
			dewdrop:AddLine('text', L["Warlock"],
							'textR', HeadCount.CLASS_COLORS["Warlock"].r, 
							'textG', HeadCount.CLASS_COLORS["Warlock"].g, 
							'textB', HeadCount.CLASS_COLORS["Warlock"].b, 														
							'hasArrow', true,
							'value', "warlock",
							'tooltipTitle', L["Warlock"],
							'tooltipText', L["Warlock players"]
							)
		else
			dewdrop:AddLine('text', L["Warlock"], 'disabled', true, 'tooltipTitle', L["Warlock"], 'tooltipText', L["Warlock players"])
		end
						
		if ((# playerList["Warrior"]) > 0) then								
			dewdrop:AddLine('text', L["Warrior"],
							'textR', HeadCount.CLASS_COLORS["Warrior"].r, 
							'textG', HeadCount.CLASS_COLORS["Warrior"].g, 
							'textB', HeadCount.CLASS_COLORS["Warrior"].b, 																
							'hasArrow', true,
							'value', "warrior",
							'tooltipTitle', L["Warrior"],
							'tooltipText', L["Warrior players"]
							)
		else
			dewdrop:AddLine('text', L["Warrior"], 'disabled', true, 'tooltipTitle', L["Warrior"], 'tooltipText', L["Warrior players"])
		end
			
		if ((# playerList["Unknown"]) > 0) then								
			dewdrop:AddLine('text', L["Unknown"],
							'textR', HeadCount.CLASS_COLORS["Unknown"].r, 
							'textG', HeadCount.CLASS_COLORS["Unknown"].g, 
							'textB', HeadCount.CLASS_COLORS["Unknown"].b, 																
							'hasArrow', true,
							'value', "unknown",
							'tooltipTitle', L["Unknown"],
							'tooltipText', L["Unknown players"]
							)
		else
			dewdrop:AddLine('text', L["Unknown"], 'disabled', true, 'tooltipTitle', L["Unknown"], 'tooltipText', L["Unknown players"])
		end
		
		dewdrop:AddLine()					
		dewdrop:AddLine('text', L["Bank"],
						'hasArrow', false,
						'closeWhenClicked', true, 
						'value', "bank",
						'tooltipTitle', L["Bank"],
						'tooltipText', L["Assign loot to bank"], 
						'func', function(looter) HeadCount:HeadCountFrameLootManagementPopupLooterButton_Set(looter) end, 
						'arg1', L["Bank"]						
						)
		dewdrop:AddLine('text', L["Disenchanted"],
						'hasArrow', false,
						'closeWhenClicked', true, 
						'value', "bank",
						'tooltipTitle', L["Disenchanted"],
						'tooltipText', L["Assign loot as disenchanted"], 
						'func', function(looter) HeadCount:HeadCountFrameLootManagementPopupLooterButton_Set(looter) end, 
						'arg1', L["Disenchanted"]												
						)										
		dewdrop:AddLine('text', L["Offspec"],
						'hasArrow', false,
						'closeWhenClicked', true, 						
						'value', "bank",
						'tooltipTitle', L["Offspec"],
						'tooltipText', L["Assign loot as offspec"], 
						'func', function(looter) HeadCount:HeadCountFrameLootManagementPopupLooterButton_Set(looter) end, 
						'arg1', L["Offspec"]
						)																
		dewdrop:AddLine()
		dewdrop:AddLine('text', L["Close menu"], 
						'closeWhenClicked', true, 
						'tooltipTitle', L["Close menu"],
						'tooltipText', L["Close the menu"]
						)		
	elseif (level == 2) then
		if (value == "death knight") then
			for k,v in ipairs(playerList["Death Knight"]) do
				HeadCount:HeadCountFrameLootManagementPopupLooterButton_AddPlayerLine("Death Knight", v)			
			end		
		elseif (value == "druid") then
			for k,v in ipairs(playerList["Druid"]) do
				HeadCount:HeadCountFrameLootManagementPopupLooterButton_AddPlayerLine("Druid", v)			
			end		
		elseif (value == "hunter") then
			for k,v in ipairs(playerList["Hunter"]) do
				HeadCount:HeadCountFrameLootManagementPopupLooterButton_AddPlayerLine("Hunter", v)			
			end		
		elseif (value == "mage") then
			for k,v in ipairs(playerList["Mage"]) do
				HeadCount:HeadCountFrameLootManagementPopupLooterButton_AddPlayerLine("Mage", v)			
			end	
		elseif (value == "paladin") then
			for k,v in ipairs(playerList["Paladin"]) do
				HeadCount:HeadCountFrameLootManagementPopupLooterButton_AddPlayerLine("Paladin", v)
			end				
		elseif (value == "priest") then
			for k,v in ipairs(playerList["Priest"]) do
				HeadCount:HeadCountFrameLootManagementPopupLooterButton_AddPlayerLine("Priest", v)
			end				
		elseif (value == "rogue") then
			for k,v in ipairs(playerList["Rogue"]) do
				HeadCount:HeadCountFrameLootManagementPopupLooterButton_AddPlayerLine("Rogue", v)			
			end				
		elseif (value == "shaman") then
			for k,v in ipairs(playerList["Shaman"]) do
				HeadCount:HeadCountFrameLootManagementPopupLooterButton_AddPlayerLine("Shaman", v)
			end										
		elseif (value == "warlock") then
			for k,v in ipairs(playerList["Warlock"]) do
				HeadCount:HeadCountFrameLootManagementPopupLooterButton_AddPlayerLine("Warlock", v)
			end							
		elseif (value == "warrior") then
			for k,v in ipairs(playerList["Warrior"]) do
				HeadCount:HeadCountFrameLootManagementPopupLooterButton_AddPlayerLine("Warrior", v)
			end	
		elseif (value == "unknown") then 
			for k,v in ipairs(playerList["Unknown"]) do
				HeadCount:HeadCountFrameLootManagementPopupLooterButton_AddPlayerLine("Unknown", v)
			end	
		end
	end						
end

-- Add a player line to the looted by drop down menu
-- @param className The class name.
-- @param playerName The player name
function HeadCount:HeadCountFrameLootManagementPopupLooterButton_AddPlayerLine(className, playerName)
	dewdrop:AddLine('text', playerName,
					'textR', HeadCount.CLASS_COLORS[className].r, 
					'textG', HeadCount.CLASS_COLORS[className].g, 
					'textB', HeadCount.CLASS_COLORS[className].b, 				
					'closeWhenClicked', true, 
					'tooltipTitle', L[className], 
					'tooltipText', playerName, 
					'func', function(looter) HeadCount:HeadCountFrameLootManagementPopupLooterButton_Set(looter) end, 
					'arg1', playerName)			
end

-- CREATE MENU: The loot management source menu
function HeadCount:HeadCountFrameLootManagementSourceButton_CreateMenu(level, value)
	local raidTracker = HeadCount:getRaidTracker()	
	local raid = raidTracker:getRaidById(HeadCountFrameLootManagement.raidId)
	
	local bossList = raid:retrieveOrderedBossList() 
	
	if (1 == level) then
		dewdrop:AddLine('text', L["Loot source"] .. ":", 'isTitle', true)	
	
		for k,v in ipairs(bossList) do
			dewdrop:AddLine('text', v:getName(),		
							'closeWhenClicked', true, 
							'tooltipTitle', L["Boss"], 
							'tooltipText', v:getName(), 
							'func', function(source) HeadCount:HeadCountFrameLootManagementSourceButton_Set(source) end, 
							'arg1', v:getName())			
		end
		
		if (# bossList > 0) then
			dewdrop:AddLine()
		end
		
		dewdrop:AddLine('text', L["Trash mob"],		
						'closeWhenClicked', true, 
						'tooltipTitle', L["Trash mob"], 
						'tooltipText', L["Trash mob"], 
						'func', function(source) HeadCount:HeadCountFrameLootManagementSourceButton_Set(source) end, 
						'arg1', L["Trash mob"])	
		dewdrop:AddLine()
		
		dewdrop:AddLine('text', L["Close menu"], 
						'closeWhenClicked', true, 
						'tooltipTitle', L["Close menu"],
						'tooltipText', L["Close the menu"]
						)		
	end						
end

-- CREATE MENU: The loot management popup source menu
function HeadCount:HeadCountFrameLootManagementPopupSourceButton_CreateMenu(level, value)
	local raidTracker = HeadCount:getRaidTracker()	
	local raid = raidTracker:getRaidById(HeadCountFrame.lootManagementPopupRaidId)
	
	local bossList = raid:retrieveOrderedBossList() 
	
	if (1 == level) then
		dewdrop:AddLine('text', L["Loot source"] .. ":", 'isTitle', true)	
	
		for k,v in ipairs(bossList) do
			dewdrop:AddLine('text', v:getName(),		
							'closeWhenClicked', true, 
							'tooltipTitle', L["Boss"], 
							'tooltipText', v:getName(), 
							'func', function(source) HeadCount:HeadCountFrameLootManagementPopupSourceButton_Set(source) end, 
							'arg1', v:getName())			
		end
		
		if ((# bossList) > 0) then
			dewdrop:AddLine()
		end
		
		dewdrop:AddLine('text', L["Trash mob"],		
						'closeWhenClicked', true, 
						'tooltipTitle', L["Trash mob"], 
						'tooltipText', L["Trash mob"], 
						'func', function(source) HeadCount:HeadCountFrameLootManagementPopupSourceButton_Set(source) end, 
						'arg1', L["Trash mob"])	
		dewdrop:AddLine()
		
		dewdrop:AddLine('text', L["Close menu"], 
						'closeWhenClicked', true, 
						'tooltipTitle', L["Close menu"],
						'tooltipText', L["Close the menu"]
						)		
	end						
end
