
local linkSpellsAddonPrefix = "LinkSpells"
local addonMsgSep = "="
local prevClickedLink = ""
local stopSpellAutoInsert = ""
local spellCache = {}

-- The chat channels where chat links can be sent,
-- these are the channels where SendAddonMessage works.
local chatChannels = {
	"PARTY",
	"PARTY_LEADER",
	"RAID",
	"RAID_LEADER",
	"GUILD",
	"OFFICER",
	"INSTANCE_CHAT",
	"INSTANCE_CHAT_LEADER",
	"WHISPER",
	"WHISPER_INFORM",
	"SAY",
	"YELL"
}

-- Save a spell to the spell cache, which holds spell info to
-- be shown in the spell link tooltips.
local function SaveToSpellCache(name, rank, requires, powerCost, range, castTime, cooldown, tools, percentText)
	local identifier = name
	local rankNumber = rank
	
	if rankNumber ~= "None" then
		
		if rankNumber:find("Rank") then
			rankNumber = rankNumber:sub(6, rank:len())
			
			local a, b = rankNumber:find("/")
			
			if a ~= nil then
				rankNumber = rankNumber:sub(0, a - 1)
			end
			
		end
		
	end
	
	if tonumber(rankNumber) ~= nil then
		identifier = identifier .. ":" .. rankNumber
	end
	
	if spellCache[identifier] == nil then
		spellCache[identifier] = {}
		spellCache[identifier].numClones = 0
	else
		spellCache[identifier].numClones = spellCache[identifier].numClones + 1
		identifier = identifier .. "#" .. spellCache[identifier].numClones
		spellCache[identifier] = {}
	end
	
	spellCache[identifier].rank = rank
	spellCache[identifier].requires = requires
	spellCache[identifier].powerCost = powerCost
	spellCache[identifier].range = range
	spellCache[identifier].castTime = castTime
	spellCache[identifier].cooldown = cooldown
	spellCache[identifier].tools = tools
	spellCache[identifier].percentText = percentText
end

-- Set or append to the description of a spell in the spell cache.
local function AddSpellCacheDesc(name, rank, desc)
	local identifier = name
	local rankNumber = rank
	
	if rankNumber ~= "None" then
		
		if rankNumber:find("Rank") then
			rankNumber = rankNumber:sub(6, rankNumber:len())
			
			local a, b = rankNumber:find("/")
			
			if a ~= nil then
				rankNumber = rankNumber:sub(0, a - 1)
			end
			
		end
		
	end
	
	if tonumber(rankNumber) ~= nil then
		identifier = identifier .. ":" .. rankNumber
	end
	
	if spellCache[identifier].numClones ~= 0 then
		identifier = identifier .. "#" .. spellCache[identifier].numClones
	end
	
	if spellCache[identifier].desc == nil then
		spellCache[identifier].desc = desc
	elseif spellCache[identifier].desc:find(desc) == nil then
		spellCache[identifier].desc = spellCache[identifier].desc .. desc
	end
	
end

-- Send spell data to other people using the addon.
local function SendSpellData(name, rank, cloneNum, chatChannel, whisperTarget)	
	local identifier = name
	
	if tonumber(rank) ~= nil then
		identifier = identifier .. ":" .. rank
	end
	
	if tonumber(cloneNum) ~= 0 and cloneNum ~= nil then
		identifier = identifier .. "#" .. cloneNum
	end
	
	local spellData = spellCache[identifier]
	
	local addonMsgHeader = 
		"spellDataHeader" .. addonMsgSep ..
		name .. addonMsgSep .. spellData.rank .. addonMsgSep ..
		spellData.requires .. addonMsgSep .. spellData.powerCost .. addonMsgSep ..
		spellData.range .. addonMsgSep .. spellData.castTime .. addonMsgSep ..
		spellData.cooldown .. addonMsgSep .. spellData.tools .. addonMsgSep ..
		spellData.percentText
		
	local addonMsgDesc = 
		"spellDataDesc" .. addonMsgSep .. 
		name .. addonMsgSep .. spellData.rank .. addonMsgSep ..
		spellData.desc
		
	C_ChatInfo.SendAddonMessage(linkSpellsAddonPrefix, addonMsgHeader, chatChannel, whisperTarget)
		
	local moreToSend = true
	local maxIterations = 10
	local count = 0
	
	-- The character limit for an addon msg is 250 characters,
	-- so we split spell data description messages into several parts.
	while moreToSend do
		local x, y = addonMsgDesc:find(".*=")

		if addonMsgDesc:len() > 250 then
			C_ChatInfo.SendAddonMessage(linkSpellsAddonPrefix, addonMsgDesc:sub(0, 250), chatChannel, whisperTarget)
			addonMsgDesc = addonMsgDesc:sub(0, y) .. addonMsgDesc:sub(addonMsgDesc:len() - (addonMsgDesc:len() - 250) + 1, addonMsgDesc:len())
		else
			C_ChatInfo.SendAddonMessage(linkSpellsAddonPrefix, addonMsgDesc, chatChannel, whisperTarget)
			moreToSend = false
		end
	
		count = count + 1
		if count > maxIterations then break end
	end

end

-- Receive spell data from other people using the addon.
local function ReceiveSpellData(addonMsg, isHeader)

	if isHeader then
		local msgType, name, rank, requires, powerCost,
			range, castTime, cooldown, tools, percentText = strsplit(addonMsgSep, addonMsg)

		SaveToSpellCache(name, rank, requires, powerCost, range, castTime, cooldown, tools, percentText)
	else
		local msgType, name, rank, desc = strsplit(addonMsgSep, addonMsg)
		AddSpellCacheDesc(name, rank, desc)
	end
	
end

-- Retrieves spell data from the currently displayed tooltip.
local function ReadSpellDataFromTooltip(clickedElement)

	local name, rank, requires, percentText, 
		powerCost, range, castTime, cooldown, 
		tools, desc = 
		"None", "None", "None", "None",
		"None", "None", "None", "None",
		"None", "None"

	for i = 1, GameTooltip:NumLines() do 
		local textLeft = _G["GameTooltipTextLeft" .. i]
		local textRight = _G["GameTooltipTextRight" .. i]
		textLeft = textLeft:GetText()
		textRight = textRight:GetText()
		
		local skipDesc = false
		
		if textLeft ~= nil then 
			wordOne, wordTwo, wordThree = strsplit(" ", textLeft)
			
			if i == 1 then
				name = textLeft
			else
				
				if wordOne == "Rank" or wordOne == "Passive" then 
					rank = textLeft
					skipDesc = true
				end
				
				if i == 2 and rank == "None" then
					local subText = _G[clickedElement:GetName() .. "SubSpellName"]:GetText()
					
					if subText == nil then
						rank = "None"
					else
						rank = subText
					end
					
				end
				
				if wordOne == "Cooldown" and wordTwo == "remaining:" then
					-- Just skip this one
				elseif wordOne == "Requires" then
					
					if requires == "None" then
						requires = textLeft
					else
						requires = requires .. "\n" .. textLeft
					end
					
				elseif wordTwo == "Mana" or wordTwo == "Rage" or wordTwo == "Energy" or wordTwo == "Focus" or wordTwo == "Health" or wordThree == "range" then
					powerCost = textLeft
				elseif wordOne == "Instant" or (wordTwo == "sec" and wordThree == "cast") or textLeft == "Channeled" or textLeft == "Attack speed" or textLeft == "Next melee" then
					castTime = textLeft
				elseif wordOne == "Tools:" then
				
					if tools == "None" then
						tools = textLeft
					else
						tools = tools .. "\n" .. textLeft
					end
					
				elseif wordOne == "Reagents:" then
					tools = textLeft
				elseif (wordOne:find("%%") and wordTwo == "chance" and wordThree == "to") then
					percentText = textLeft
				elseif skipDesc == false then
				
					if desc == "None" then
						desc = textLeft
					else
						desc = desc .. textLeft
					end
					
				end
				
			end
			
		end
		
		if textRight ~= nil then
			wordOne, wordTwo, wordThree = strsplit(" ", textRight)
			
			if textRight == "Melee Range" or textRight == "Unlimited range" or wordThree == "range" then
				range = textRight
			elseif wordThree == "cooldown" then
				cooldown = textRight
			end
			
		end
		
	end
	
	SaveToSpellCache(name, rank, requires, powerCost, range, castTime, cooldown, tools, percentText)
	AddSpellCacheDesc(name, rank, desc)

	if rank ~= "None" then
		
		if rank:find("Rank") then
			rank = rank:sub(6, rank:len())
			
			local a, b = rank:find("/")
			
			if a ~= nil then
				rank = rank:sub(0, a - 1)
			end
			
		end
		
	end

	local identifier = name
	
	if tonumber(rank) ~= nil then
		identifier = identifier .. ":" .. rank
	end
	
	stopSpellAutoInsert = name
	ChatFrame1EditBox:Insert("!Link[" .. identifier .. "]")
end

-- When a spell button is clicked in the spellbook
local function OnSpellButtonClick(self, button)

	if (button == "LeftButton" and IsLeftShiftKeyDown()) or (button == "LeftButton" and IsRightShiftKeyDown()) then 
		ReadSpellDataFromTooltip(self)
	end
	
end

-- When a talent button is clicked in the talent tree
local function OnTalentButtonClick(self, button)

	if (IsLeftShiftKeyDown()) or (IsRightShiftKeyDown()) then 
		ReadSpellDataFromTooltip(self)
	end
	
end

-- Adds line breaks to a text string, used for tooltip spell descriptions.
local function AddLineBreaks(text, numChars)
	local checkForNewLines = true
	local lineIndex = 0
	local spaceIndex = 0
	local prevSpaceIndex = 0
	local maxIterations = 300
	local count = 0

	while checkForNewLines do
		spaceIndex = text:find(" ", spaceIndex + 1)
		
		if spaceIndex ~= nil then
				
			if spaceIndex - lineIndex == numChars then
				lineIndex = spaceIndex
				text = text:sub(0, spaceIndex - 1) .. "\n" .. text:sub(spaceIndex + 1, text:len())
			elseif spaceIndex - lineIndex > numChars then
				lineIndex = prevSpaceIndex
				text = text:sub(0, prevSpaceIndex - 1) .. "\n" .. text:sub(prevSpaceIndex + 1, text:len())
			end
		
			prevSpaceIndex = spaceIndex
		else
			checkForNewLines = false
		end
		
		count = count + 1
		if count > maxIterations then break end
	end
	
	return text
end

-- Show the proper tooltip for the spell if the link is a spell link.
local function OnChatLinkClick(chatFrame, link, text, button)
		
	if link:find("spell:0:0:") == nil then 
		prevClickedLink = "" 
		return 
	end
	
	if prevClickedLink == link .. text then
		ItemRefTooltip:Hide()
		prevClickedLink = ""
		return
	else
		prevClickedLink = link .. text
	end
	
	local x, y = link:find(":", 11)
	local spellRank = link:sub(11, x - 1)
	local numClones = link:sub(y + 1, link:len())
	
	local a, b = text:find("|h")
	text = text:sub(b + 2, text:len())
	local c, d = text:find("|h")
	text = text:sub(0, c - 2)
	
	local identifier = text
		
	if tonumber(spellRank) ~= nil then
		identifier = identifier .. ":" .. spellRank
	end
	
	if tonumber(numClones) ~= 0 then
		identifier = identifier .. "#" .. numClones
	end
	
	if (button == "LeftButton" and IsLeftShiftKeyDown()) or (button == "LeftButton" and IsRightShiftKeyDown()) then 
	
		if tonumber(numClones) == 0 then 
			identifier = identifier .. "#" .. numClones 
		end
		
		ChatFrame1EditBox:Insert("!Link[" .. identifier .. "]")
		return
	end
	
	if spellCache[identifier] == nil then 
		ItemRefTooltip:SetOwner(chatFrame, "ANCHOR_PRESERVE")
		ItemRefTooltip:AddLine("No spell data available.", 1, 0, 0)
		ItemRefTooltip:AddLine("Try clicking again or send a bug report!", 1, 0, 0)
		ItemRefTooltip:SetPadding(25, 0)
		ItemRefTooltip:Show()
	else
		ItemRefTooltip:SetOwner(chatFrame, "ANCHOR_PRESERVE")
		ItemRefTooltip:AddLine(text, 1, 1, 1)
		
		local rank, requires, powerCost, 
			range, castTime, cooldown, tools,
			percentText, desc = 
			"None", "None", "None", "None",
			"None", "None", "None", "None",
			"None", "None"
		
		for key, value in pairs(spellCache[identifier]) do
			if key == "rank" then rank = value end
			if key == "requires" then requires = value end
			if key == "powerCost" then powerCost = value end
			if key == "range" then range = value end
			if key == "castTime" then castTime = value end
			if key == "cooldown" then cooldown = value end
			if key == "tools" then tools = value end
			if key == "percentText" then percentText = value end
			if key == "desc" then desc = value end
		end
		
		if rank ~= "None" then
			ItemRefTooltip:AddLine(rank, 1, 1, 1)
		end
		
		if requires ~= "None" then
			ItemRefTooltip:AddLine(requires, 1, 0.12, 0.12)
		end
		
		if powerCost ~= "None" then
			if range == "None" then range = "" end
			ItemRefTooltip:AddDoubleLine(powerCost, range, 1, 1, 1, 1, 1, 1)
		end
		
		if castTime ~= "None" then
			if cooldown == "None" then cooldown = "" end
			ItemRefTooltip:AddDoubleLine(castTime, cooldown, 1, 1, 1, 1, 1, 1)
		end
		
		if tools ~= "None" then
			ItemRefTooltip:AddLine(tools, 1, 1, 1)
		end
		
		if percentText ~= "None" then
			ItemRefTooltip:AddLine(percentText, 1, 1, 1)
		end
		
		if desc ~= "None" then			
			local x, y = desc:find("Next rank:")
			
			if x ~= nil then
				local descPartOne = AddLineBreaks(desc:sub(0, x - 1), 40)
				local descPartTwo = AddLineBreaks(desc:sub(y + 1, desc:len()), 40)
				ItemRefTooltip:AddLine(descPartOne, 1, 0.82, 0)
				ItemRefTooltip:AddLine(" ", 1, 1, 1)
				ItemRefTooltip:AddLine("Next rank:", 1, 1, 1)
				ItemRefTooltip:AddLine(descPartTwo, 1, 0.82, 0)
			else 
				desc = AddLineBreaks(desc, 40)
				ItemRefTooltip:AddLine(desc, 1, 0.82, 0)
			end
			
		end
		
		ItemRefTooltip:SetPadding(25, 0)
		ItemRefTooltip:Show()
	end
	
end

-- Check for dummy spell links in the chat, and replace them
-- with an actual clickable link for that spell.
local function CheckForSpellLinks(self, event, text, author, ...)
	local chatChannel = event:sub(10, event:len())
	if event == "CHAT_MSG_PARTY_LEADER" then chatChannel = "PARTY" end
	if event == "CHAT_MSG_RAID_LEADER" then chatChannel = "RAID" end
	if event == "CHAT_MSG_INSTANCE_CHAT_LEADER" then chatChannel = "INSTANCE_CHAT" end

	-- Remove realm from author name
	local i, j = author:find('-')
	local authorNoRealm = nil
	local _, _, whisperTarget = nil
	
	if event == "CHAT_MSG_WHISPER_INFORM" then 
		chatChannel = "WHISPER"
		authorNoRealm = UnitName("player")
		_, _, whisperTarget = ...
	else
	
		if i ~= nil then
			authorNoRealm = author:sub(0, j - 1)
		else
			authorNoRealm = author
		end
	
	end

	-- Have to put a % infront of the brackets for it to search properly	
	local linkBegin = "!link%["
	local linkEnd = "%]"

	local a, b = text:lower():find(linkBegin)
	local c, d = text:lower():find(linkEnd, b)

	local maxIterations = 20
	local count = 0

	while a ~= nil and c ~= nil do
	
		-- Read the dummy chat link
		local spellNameAndRank = text:sub(b + 1, c - 1)
		local e, f = spellNameAndRank:find(":")
		local x, y = spellNameAndRank:find("#")
		
		local spellName = "None"
		local spellRank = "p"
		local cloneNum = nil
		
		if e ~= nil then
			spellName = spellNameAndRank:sub(0, e - 1)
			spellRank = spellNameAndRank:sub(f + 1, spellNameAndRank:len())
		else
			spellName = spellNameAndRank
		end
		
		if x ~= nil then
			
			if e ~= nil then
				spellRank = spellNameAndRank:sub(f + 1, x - 1)
			else
				spellName = spellNameAndRank:sub(0, x - 1)
			end
			
			cloneNum = spellNameAndRank:sub(x + 1, spellNameAndRank:len()) 
		end
					
		-- If the link was sent by this player, then send spell data to other players
		if authorNoRealm == UnitName("player") then			
			SendSpellData(spellName, spellRank, cloneNum, chatChannel, whisperTarget)
		end
		
		local identifier = spellName
	
		if tonumber(spellRank) ~= nil then
			identifier = identifier .. ":" .. spellRank
		end
		
		local numClones = 0
			
		if spellCache[identifier] ~= nil then
		
			if authorNoRealm == UnitName("player") then
				numClones = spellCache[identifier].numClones
			else
				numClones = spellCache[identifier].numClones + 1
			end
			
		end
		
		if cloneNum ~= nil then numClones = cloneNum end
		
		-- Replace the dummy chat link with a real, clickable one
		textPartOne = text:sub(0, a - 1)
		textPartTwo = text:sub(d + 1, text:len())
		text = textPartOne .. "|cFF71D5FF|Hspell:0:0:" .. spellRank .. ":" .. numClones .. "|h[" .. spellName .. "]|h|r" .. textPartTwo
		
		a, b = text:lower():find(linkBegin)
		c, d = text:lower():find(linkEnd, b)
	
		-- Safety check
		count = count + 1
		if count > maxIterations then break end
	end
	
	return false, text, author, ...
end

-- Removes the spell name that is automatically added to the
-- chat edit box when you shift-click a spell in the spellbook.
-- This spell name is added after our spell link is added.
local function OnChatEditBoxChanged(self)

	if stopSpellAutoInsert == "" then return end

	local x, y = self:GetText():find("]" .. stopSpellAutoInsert)
	
	if x ~= nil then
		self:SetText(self:GetText():sub(0, x))
	end
	
end

-- Set up our frame
local frame = CreateFrame("Frame", "LinkSpellsClassicFrame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("CHAT_MSG_ADDON")

-- Handle events
frame:SetScript("OnEvent", function(self, event, ...)
			
	if event == "ADDON_LOADED" then
		local addon = ...
		
		-- Hook the talent tree buttons once Blizzard's Talent UI has been loaded.
		if addon == "Blizzard_TalentUI" then
			
			for index = 1, 100 do
			
				if _G["TalentFrameTalent" .. index] ~= nil then
					_G["TalentFrameTalent" .. index]:HookScript("OnMouseDown", OnTalentButtonClick)
				else
					break
				end
				
			end
						
		end
		
		if addon == "LinkSpellsClassic" then					
			C_ChatInfo.RegisterAddonMessagePrefix(linkSpellsAddonPrefix)

			-- Add a chat filter that checks for spell links from this addon.
			for key, value in pairs(chatChannels) do
				ChatFrame_AddMessageEventFilter("CHAT_MSG_" .. value, CheckForSpellLinks)
			end
			
			-- There's a maximum of 10 different chat frames, we need to hook them all.
			for i = 1, 10 do
				_G["ChatFrame" .. i]:HookScript("OnHyperlinkClick", OnChatLinkClick)
			end
			
			-- Hook each of the 12 spell buttons in the spellbook.
			for i = 1, 12 do
				_G["SpellButton" .. i]:HookScript("OnMouseDown", OnSpellButtonClick)
			end
			
			ChatFrame1EditBox:HookScript("OnTextChanged", OnChatEditBoxChanged)
			
			if LSC_MSG == nil then
				LSC_MSG = 1
			end
			
			if LSC_MSG == 1 then
				print("|c002F2F2A*|r   |cFFFFFFFFLinkSpellsClassic loaded.|r")
				print("|c002F2F2A*|r   |cFFFFFFFFType /link msg to hide this.|r")
				print("|c002F2F2A*|r   |cFFFFFFFFSource: github.com/techiew/LinkSpellsClassic|r")
			end
			
		end
		
	end
	
	-- Watch for addon messages from other people using the addon.
	if event == "CHAT_MSG_ADDON" then
		local prefix, msg, channel, sender = ...
				
		if prefix == linkSpellsAddonPrefix then	
			local i, j = sender:find('-')
			
			if i ~= nil then
				sender = sender:sub(0, j - 1)
			end
			
			if sender == UnitName("player") then return end

			ReceiveSpellData(msg, msg:sub(0, 15) == "spellDataHeader")
		end
		
	end

end)
