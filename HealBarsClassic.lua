local libCHC = LibStub("LibHealComm-4.0-Custom", true)

HealBarsClassic = LibStub("AceAddon-3.0"):NewAddon("HealBarsClassic")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceConsole = LibStub("AceConsole-3.0")

local healBarTable = {} 
local masterFrameTable = {}
local statusGUIDs = {}
local barTypes = {['flat']={}, ['hot']={}, ['ownFlat']={}, ['ownHot']={}, ['afterOwnFlat']={}}
local currentHeals = {}
local playerGUID = UnitGUID('player')
HBCdb = {}


local partyGUIDs = {
	[UnitGUID("player")] = "player",
}

local globalFrameList = {
				["player"] = _G["PlayerFrame"] ,
				["pet"] =  _G["PetFrame"],
				["target"] = _G["TargetFrame"],
				["focus"] = _G["FocusFrame"],
				["party1"] = _G["PartyMemberFrame1"],
				["partypet1"] = _G["PartyMemberFrame1PetFrame"],
				["party2"] = _G["PartyMemberFrame2"],
				["partypet2"] = _G["PartyMemberFrame2PetFrame"],
				["party3"] = _G["PartyMemberFrame3"],
				["partypet3"] = _G["PartyMemberFrame3PetFrame"],
				["party4"] = _G["PartyMemberFrame4"],
				["partypet4"] = _G["PartyMemberFrame4PetFrame"],
				}

HBCDefaultColors = {
	['flat'] = {0, 1, 0, 1.0},
	['hot'] = {110/255, 230/255, 55/255, 0.7},
	['ownFlat']	= {255/255, 0/255, 135/255, 1},
	['ownHot'] = {230/255, 76/255, 105/255, 0.7},
}	
HealBarsClassic.invulStatusTextConfigList = {
	['DIVSHLD'] = 'Divine Shield - DIVSHLD',
	['DIVPROT'] = 'Divine Protection - DIVPROT',
	['BLSPROT'] = 'Blessing of Protection - BLSPROT',
	['ICEBLCK'] = 'Ice Block - ICEBLCK',
	['DIVINTR'] = 'Divine Intervention - DIVINTR',
}
HealBarsClassic.strongMitStatusTextConfigList = {
	['EVASION'] = 'Evasion - EVASION',
	['SHDWALL'] = 'Shield Wall - SHDWALL',
	['CHEATDTH'] = 'Cheat Death - CHEATDTH'
}
HealBarsClassic.softMitStatusTextConfigList = {
	['BARKSKIN'] = 'Barkskin - BARKSKIN',
	['PAINSPR'] = 'Pain Supression - PAINSPR',
	['SHMRAGE'] = 'Shamanistic Rage - SHMRAGE'
}
HealBarsClassic.miscStatusTextConfigList = {
	-- ['INERVTE'] = 'Innervate - INERVTE', 
	-- ['SPIRIT'] = 'Spirit of Redemption - SPIRIT'
}

local defensiveSpells = {
	[642] = {name = 'DIVSHLD',duration = 12, priority = 2} -- Divine Shield Rank 1
	, [1020] = {name = 'DIVSHLD',duration = 12, priority = 2} -- Divine Shield Rank 2
	, [1022] = {name = 'BLSPROT',duration = 6, priority = 10} -- Blessing of Protection Rank 1
	, [5599] = {name = 'BLSPROT',duration = 6, priority = 10} -- Blessing of Protection Rank 2
	, [10278] = {name = 'BLSPROT',duration = 6, priority = 10} -- Blessing of Protection Rank 3
	, [498] = {name = 'DIVPROT',duration = 6, priority = 2} -- Divine Protection Rank 1
	, [5573] = {name = 'DIVPROT',duration = 6, priority = 2} -- Divine Protection Rank 2
	, [45438] = {name = 'ICEBLCK',duration = 10, priority = 2} -- Ice Block
	, [19753] = {name = 'DIVINTR',duration = 45, priority = 1} -- Divine Intervention 
								-- (Rarely held for full duration & frequently breaks from release->res)							
	
	, [26669] = {name = 'EVASION', duration = 15, priority = 20} -- Evasion Rank 2
	, [5277] = {name = 'EVASION', duration = 15, priority = 20} -- Evasion Rank 1
	, [871] = {name = 'SHDWALL', duration = 10, priority = 5} -- Shield Wall
	, [45182] = {name = 'CHEATDTH', duration = 3, priority = 5} -- Cheat Death
	
	, [22812] = {name = 'BARKSKIN', duration = 12, priority = 30} -- Bark Skin
	, [30823] = {name = 'SHMRGE', duration = 15, priority = 30} -- Shamanistic Rage
	, [33206] = {name = 'PAINSPR', duration = 8, priority = 25} -- Pain Suppression
	
	--, [20711] = {name = 'SPIRIT', duration = 15, priority = 1} -- Spirit of Redemption
	--, [29166] = {name = 'INERVTE', duration = 20, priority = 40} -- Innervate 
	} 
local HBCdefault = {
	global = {
		overhealPercent = 20,
		timeframe = 3,
		healTimeframe = 8,
		showHots = true,
		seperateHots = true,
		seperateOwnHeals = false,
		healColor = HBCDefaultColors.flat,
		hotColor = HBCDefaultColors.hot,
		ownHealColor = HBCDefaultColors.ownFlat,
		ownHotColor = HBCDefaultColors.ownHot,
		defensiveIndicator = true,
		enabledStatusTexts = {
			['*'] = false,
			['DIVSHLD'] = true,
			['DIVPROT'] = true,
			['BLSPROT'] = true,
			['DIVINTR'] = true,
			['ICEBLCK'] = true,
			['SHDWALL'] = true,
			['EVASION'] = true,
			['CHEATDTH'] = true,
			--['SPIRIT'] = true,
		},
		predictiveHealthLost = false,
		alternativeTexture = true,
		fastUpdate = false,
		fastUpdateDuration = 0.03, --~30 updates per second
	}
}
function HealBarsClassic:ColorTest(case)
	if not currentHeals[playerGUID] then
		currentHeals[playerGUID] = {}
	end
	local playerHeals = currentHeals[playerGUID]
	
	if not case or case == 1 then
		table.insert(playerHeals,{healType = 'ownFlat',amount = 700})
		table.insert(playerHeals,{healType = 'flat',amount = 800})
		table.insert(playerHeals,{healType = 'ownHot',amount = 500})
		table.insert(playerHeals,{healType = 'hot',amount = 500})
	elseif case == 2 then
		table.insert(playerHeals,{healType = 'ownFlat',amount = 500})
		table.insert(playerHeals,{healType = 'flat',amount = 500})
	elseif case == 3 then
		table.insert(playerHeals,{healType = 'flat',amount = 500})
		table.insert(playerHeals,{healType = 'ownFlat',amount = 500})
	end
	HealBarsClassic:UpdateGUIDHeals(playerGUID)
end

function HealBarsClassic:getHealColor(healType)
	local colorVarName, colorTable
	if healType == 'flat' or healType == 'afterOwnFlat' then 
		colorTable = HBCdb.global.healColor
	elseif healType == 'hot' then
		colorTable = HBCdb.global.hotColor
	elseif healType == 'ownFlat' then
		colorTable = HBCdb.global.ownHealColor
	else
		colorTable = HBCdb.global.ownHotColor
	end
	if colorTable then 
		return unpack(colorTable)
	end
end

function HealBarsClassic:CreateDefaultHealBars()
	for name,unitFrame in pairs(globalFrameList) do
		HealBarsClassic:createHealBars(unitFrame)
	end
end



function HealBarsClassic:createHealBars(unitFrame, textureType)
	if not unitFrame or unitFrame:IsForbidden() or not unitFrame:GetName() then return end
	
	if masterFrameTable[unitFrame:GetName()] then return end
	
	masterFrameTable[unitFrame:GetName()]=unitFrame
	
	if not healBarTable[unitFrame] then
		healBarTable[unitFrame] = {}
	end
	local currentBarList = healBarTable[unitFrame]


	
	
	for healType, properties in pairs(barTypes) do
		if not currentBarList[healType] then
			currentBarList[healType] = CreateFrame("StatusBar"
				, "HBCIncHealBar"..unitFrame:GetName()..healType, unitFrame)
			currentBarList[healType]:SetFrameStrata("LOW")
			if(unitFrame:GetName() == 'FocusFrame') then
				currentBarList[healType]:SetFrameLevel(currentBarList[healType]:GetFrameLevel())
			end
			currentBarList[healType]:SetFrameLevel(currentBarList[healType]:GetFrameLevel()-1)
			if textureType == 'raid' or HBCdb.global.alternativeTexture then
				currentBarList[healType]:SetStatusBarTexture("Interface\\RaidFrame\\Raid-Bar-Hp-Fill")
			else 
				currentBarList[healType]:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
			end
			currentBarList[healType]:SetMinMaxValues(0, 1)
			currentBarList[healType]:SetValue(1)
			currentBarList[healType]:SetStatusBarColor(HealBarsClassic:getHealColor(healType))
		end
	end
	
	local eventFrame = CreateFrame("Frame","HealBarsClassicEventFrame"..unitFrame:GetName(), unitFrame)
	eventFrame:SetScript("OnEvent",function(self) HealBarsClassic:UpdateHealBars(self:GetParent()) end)

end


function HealBarsClassic:UpdateGUIDHeals(GUID)

	if partyGUIDs[targetGUID] then
		if globalFrameList[partyGUIDs[targetGUID]] then
			HealBarsClassic:UpdateHealBars(globalFrameList[partyGUIDs[targetGUID]])
		end
	end
	
	for frameName, unitFrame in pairs(masterFrameTable) do
		local displayedUnit = HealBarsClassic:GetFrameInfo(unitFrame)
		if displayedUnit and UnitGUID(displayedUnit) == GUID then
			HealBarsClassic:UpdateHealBars(unitFrame)
			if unitFrame.statusText then
				CompactUnitFrame_UpdateStatusText(unitFrame)
			end
		
		end
	
	end 

end

function HealBarsClassic:GetFrameInfo(unitFrame)
	local displayedUnit, healthBar
	if not unitFrame then return end
	
	if unitFrame.displayedUnit ~= nil then 
		displayedUnit = unitFrame.displayedUnit
	else
		displayedUnit = unitFrame.unit
	end
	if unitFrame.healthBar ~= nil then 
		healthBar = unitFrame.healthBar
	else
		healthBar = unitFrame.healthbar
	end
	
	return displayedUnit,healthBar

end


function HealBarsClassic:UpdateHealBars(unitFrame)
	if not unitFrame then return end
	local displayedUnit, healthBar = HealBarsClassic:GetFrameInfo(unitFrame)
	if not displayedUnit or not UnitExists(displayedUnit) or not healBarTable[unitFrame] then return end
	
	local eventFrame = _G['HealBarsClassicEventFrame'..unitFrame:GetName()]
	eventFrame:RegisterUnitEvent("UNIT_HEALTH",(HealBarsClassic:GetFrameInfo(unitFrame)))
	eventFrame:RegisterUnitEvent("UNIT_MAXHEALTH",(HealBarsClassic:GetFrameInfo(unitFrame)))
			
	
	
	local unit = displayedUnit
	local maxHealth= UnitHealthMax(unit)
	local health= UnitHealth(unit)
	local healthWidth=healthBar:GetWidth() * (health / maxHealth)
	local maxWidth = healthBar:GetWidth() * ( 1 + (HBCdb.global.overhealPercent/100))
	
	local healWidthTotal = 0
	local currentHealsForGUID = currentHeals[UnitGUID(displayedUnit)]
	
	if not currentHealsForGUID then 
		HealBarsClassic:ClearHealBar(unitFrame)
		return 
	end

	for index,healInfo in ipairs(currentHealsForGUID) do
		local healType = healInfo.healType
		local barFrame = healBarTable[unitFrame][healType]
		local amount = healInfo.amount
		if amount and amount > 0 and (health < maxHealth or HBCdb.global.overhealPercent > 0 )
				and healthBar:IsVisible() 
		then
			barFrame:Show()
			local healWidth = healthBar:GetWidth() * (amount / maxHealth)
			
			if healthWidth + healWidthTotal + healWidth >= maxWidth then
				healWidth = maxWidth - healthWidth - healWidthTotal
				if healWidth <= 0 then
					barFrame:Hide()
				end
			end
			barFrame:SetSize(healWidth,healthBar:GetHeight())
			barFrame:ClearAllPoints()
			barFrame:SetPoint("TOPLEFT", healthBar, "TOPLEFT", healthWidth + healWidthTotal, 0)

			
			healWidthTotal = healWidthTotal + healWidth
			
		else
			barFrame:Hide()
		end
	end
end

local function UnitFrame_SetUnitHook(unitFrame)
	HealBarsClassic:UnRegisterAllInactiveFrames()
	HealBarsClassic:UpdateHealBars(unitFrame)
end

hooksecurefunc("UnitFrame_SetUnit", UnitFrame_SetUnitHook) -- This needs early hooking

local function CompactUnitFrame_SetUnitHook(unitFrame)
	HealBarsClassic:createHealBars(unitFrame,'raid')
end
hooksecurefunc("CompactUnitFrame_SetUnit", CompactUnitFrame_SetUnitHook) -- This needs early hooking

function HealBarsClassic:CheckAndApplySpellStatus(eventType,spell, targetGUID)
	if not spell or not HBCdb.global.enabledStatusTexts[spell.name] then return end
	if not statusGUIDs[targetGUID] then
		statusGUIDs[targetGUID] = {}
	end
	if eventType == 'SPELL_AURA_APPLIED' then 
		statusGUIDs[targetGUID][spell] = true
		C_Timer.After(spell.duration,function() 
				if statusGUIDs[targetGUID][spell] then
					statusGUIDs[targetGUID][spell] = nil
				end end) --fallback in case target moves out of combat log range
	else --aura removed
		statusGUIDs[targetGUID][spell] = nil
	end
end
function HealBarsClassic:COMBAT_LOG_EVENT_UNFILTERED(...)
	
	if not HBCdb.global.defensiveIndicator
		or (not UnitInParty("player") and not UnitInRaid("player")) then return end
	
	local timestamp, eventType, hideCaster, sourceGUID, sourceName
		, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, spellId = CombatLogGetCurrentEventInfo()
	if bit.band(sourceFlags,0x00000C00) ~= 0x00000400 then return end --check if caster is a player
	if not eventType == 'SPELL_AURA_APPLIED' 
		and not eventType == 'SPELL_AURA_REMOVED'
		and not eventType == 'SPELL_AURA_BROKEN'
		and not eventType == 'SPELL_AURA_BROKEN_SPELL' 
		and not eventType == 'UNIT_DIED'
		and not eventType == 'UNIT_DESTROYED'
		and not eventType == 'UNIT_DISSIPATES' then return end
	local targetGUID = destGUID or SourceGUID

	local spell = defensiveSpells[spellId]
	if spell then
		HealBarsClassic:CheckAndApplySpellStatus(eventType,spell,targetGUID)
	end

	HealBarsClassic:UpdateGUIDHeals(targetGUID)	
		
end

function HealBarsClassic:GROUP_ROSTER_UPDATE()
	HealBarsClassic:UnRegisterAllInactiveFrames()

end

function HealBarsClassic:UnRegisterAllInactiveFrames()

	for frameName, unitFrame in pairs(masterFrameTable) do
		local eventFrame = _G['HealBarsClassicEventFrame'..frameName]
		if eventFrame then  
			local displayedUnit = HealBarsClassic:GetFrameInfo(unitFrame)
			if frameName ~= 'target' and frameName ~= 'player' and frameName ~= 'focus' then 
				eventFrame:UnregisterAllEvents()
			end
		end
	end
end

function CompactUnitFrame_UpdateStatusTextHBCHook(unitFrame)
	if not unitFrame.statusText or not unitFrame.optionTable.displayStatusText 
		or not UnitIsConnected(unitFrame.displayedUnit) or UnitIsDeadOrGhost(unitFrame.displayedUnit) then return end
	

	local healthLost = UnitHealthMax(unitFrame.displayedUnit) - UnitHealth(unitFrame.displayedUnit)
		
	if HBCdb.global.defensiveIndicator then
		local guid = UnitGUID(unitFrame.displayedUnit)
		local statusEffects = statusGUIDs[guid] or {}
		local priorityEffect = {}
		for effect, _ in pairs(statusEffects) do
			if not priorityEffect.priority or (priorityEffect.priority > effect.priority) then
				priorityEffect.name = effect.name
				priorityEffect.priority = effect.priority
			end
		end
		if priorityEffect.name then
			unitFrame.statusText:SetFormattedText("%s", priorityEffect.name)
			unitFrame.statusText:Show()
			return
		end
	end
	
	--predictive health lost feature
	if unitFrame.optionTable.healthText == "losthealth" and HBCdb.global.predictiveHealthLost and currentHeals then
		local currentHeals = currentHeals[UnitGUID(unitFrame.displayedUnit)] or {}
		local totalHeals = 0
		
		for index, healInfo in ipairs(currentHeals) do
			totalHeals = totalHeals + healInfo.amount
		end
		local healthDelta = totalHeals - healthLost
		
		if healthDelta >= 0 then
			unitFrame.statusText:Hide()
		else
			unitFrame.statusText:SetFormattedText("%d", healthDelta)
			unitFrame.statusText:Show()
		end
	end 
end

function HealBarsClassic:OnInitialize()
	HBCdb = LibStub("AceDB-3.0"):New("HealBarSettings", HBCdefault)
	HBCdb.RegisterCallback(HealBarsClassic, "OnProfileChanged", "UpdateColors")
	HealBarsClassic:CreateDefaultHealBars()
	HealBarsClassic:CreateConfigs()
	hooksecurefunc("CompactUnitFrame_UpdateStatusText", CompactUnitFrame_UpdateStatusTextHBCHook)
	libCHC.RegisterCallback(HealBarsClassic, "HealComm_HealStarted", "HealComm_HealUpdated")
	libCHC.RegisterCallback(HealBarsClassic, "HealComm_HealStopped")
	libCHC.RegisterCallback(HealBarsClassic, "HealComm_HealDelayed", "HealComm_HealUpdated")
	libCHC.RegisterCallback(HealBarsClassic, "HealComm_HealUpdated")
	libCHC.RegisterCallback(HealBarsClassic, "HealComm_ModifierChanged")
	libCHC.RegisterCallback(HealBarsClassic, "HealComm_GUIDDisappeared")
	AceConsole:RegisterChatCommand(
		'hbc'
		,function(args) HealBarsClassic:ChatCommand(args) end)
	AceConsole:RegisterChatCommand(
		'HealBarsClassic'
		,function(args) HealBarsClassic:ChatCommand(args) end)
		
	C_Timer.After(HBCdb.global.fastUpdateDuration,HealBarsClassic.UpdateHealthValuesLoop)
end

function HealBarsClassic:ChatCommand(args)
	if args ~= nil then 
		arg = AceConsole:GetArgs(args,1)
	end
	if arg == nil then
		AceConfigDialog:Open('HBCOptions') 
	elseif arg == 'rc' then
		AceConsole:Print('|c42f581FFHealBarsClassic|r - These players have casted a heal while using a compatible healing addon:\n')
		local nameSet = {}
		for frameName, unitFrame in pairs(masterFrameTable) do
			displayedUnit = HealBarsClassic:GetFrameInfo(unitFrame)
			if displayedUnit and UnitGUID(displayedUnit) 
				and libCHC:GUIDHasHealed(UnitGUID(displayedUnit)) then
				nameSet[(UnitName(displayedUnit))] = true
			end
		
		end 
		for name,_ in pairs(nameSet) do
			AceConsole:Print(name)
		end
	
	
	else
		AceConsole:Print('|c42f581FFHealBarsClassic|r\n'..
						'|c42f5daFF/hbc|r - Open settings menu.\n'..
						'|c42f5daFF/hbc rc|r - Raid Check. Players only show if you\'ve seen them cast'..
						' a heal since they\'ve joined the raid. Cross-addon compatible.')
	end
end

function HealBarsClassic:UpdateColors()

	for unitFrame, unitFrameBars in pairs(healBarTable) do
		for barType, barFrame in pairs(unitFrameBars) do
			barFrame:SetStatusBarColor(HealBarsClassic:getHealColor(barType))
		end
	end
end

function HealBarsClassic:UpdateHealthValuesLoop()
	if HBCdb.global.fastUpdate and (UnitInParty("player") or UnitInRaid("player")) then
		local unitFrame = _G["CompactRaidFrame1"]
		local num = 1
		while unitFrame do
			if unitFrame.displayedUnit and UnitExists(unitFrame.displayedUnit) then
				CompactUnitFrame_UpdateMaxHealth(unitFrame.healthBar:GetParent())
				CompactUnitFrame_UpdateHealth(unitFrame.healthBar:GetParent())
			end
			num = num + 1
			unitFrame = _G["CompactRaidFrame"..num]
		end
		--[[
		for k=1, NUM_RAID_PULLOUT_FRAMES do
			frame = getglobal("RaidPullout"..k)
			for z=1, frame.numPulloutButtons do
				unitFrame = getglobal(frame:GetName().."Button"..z)
				if unitFrame.unit and UnitExists(unitFrame.unit) then
					CompactUnitFrame_UpdateMaxHealth(unitFrame.healthBar:GetParent())
					CompactUnitFrame_UpdateHealth(unitFrame.healthBar:GetParent())
				end
			end
		end--]]
		for i=1, 8 do
			local grpHeader = "CompactRaidGroup"..i
			if _G[grpHeader] then
				for k=1, 5 do
					unitFrame = _G[grpHeader.."Member"..k]
					if unitFrame and unitFrame.displayedUnit and UnitExists(unitFrame.displayedUnit) then
						CompactUnitFrame_UpdateMaxHealth(unitFrame.healthBar:GetParent())
						CompactUnitFrame_UpdateHealth(unitFrame.healthBar:GetParent())				
					end
				end
			end
		end
		C_Timer.After(HBCdb.global.fastUpdateDuration,HealBarsClassic.UpdateHealthValuesLoop)
	else
		C_Timer.After(1,HealBarsClassic.UpdateHealthValuesLoop)
	end
end

function HealBarsClassic:PLAYER_TARGET_CHANGED(frame)
	HealBarsClassic:UpdateHealBars(_G['TargetFrame'])
end

function HealBarsClassic:PLAYER_ROLES_ASSIGNED() 

	local frame, unitFrame, num
	for guid,unit in pairs(partyGUIDs) do
		if strsub(unit,1,5) == "party" then
			partyGUIDs[guid] = nil
		end
	end
	
	if UnitInParty("player") then
		for i=1, MAX_PARTY_MEMBERS do
			local p = "party"..i
			if UnitExists(p) then
				partyGUIDs[UnitGUID(p)] = p
			else
				break
			end
		end
		unitFrame = _G["CompactPartyFrameMember1"]
		num = 1
		while unitFrame do
			HealBarsClassic:UpdateHealBars(unitFrame)
			num = num + 1
			unitFrame = _G["CompactPartyFrameMember"..num]
		end
		unitFrame = _G["CompactRaidFrame1"]
		num = 1
		while unitFrame do
			HealBarsClassic:UpdateHealBars(unitFrame)
			num = num + 1
			unitFrame = _G["CompactRaidFrame"..num]
		end
	end
	if UnitInRaid("player") then
		for k=1, NUM_RAID_PULLOUT_FRAMES do
			frame = _G["RaidPullout"..k]
			for z=1, frame.numPulloutButtons do
				unitFrame = _G[frame:GetName().."Button"..z]
				HealBarsClassic:UpdateHealBars(unitFrame)
			end
		end
		for i=1, 8 do
			local grpHeader = "CompactRaidGroup"..i
			if _G[grpHeader] then
				for k=1, 5 do
					unitFrame = _G[grpHeader.."Member"..k]
					HealBarsClassic:UpdateHealBars(unitFrame)
				end
			end
		end
	end
end

function HealBarsClassic:HealComm_HealUpdated(event, casterGUID, spellID, healType, endTime, ...)
	if (bit.band(healType,libCHC.DIRECT_HEALS) > 0 or healType == libCHC.BOMB_HEALS) 
		and (endTime - GetTime()) > HBCdb.global.healTimeframe then
		self:UpdateIncoming(endTime - GetTime() - HBCdb.global.healTimeframe , ...)
	--[[
	elseif HBCdb.global.timeframe < 4 and healType == libCHC.HOT_HEALS then 
		self:UpdateIncoming(0.5, ...)
		--]]
	else
		self:UpdateIncoming(nil, ...)
	end
end

function HealBarsClassic:HealComm_HealStopped(event, casterGUID, spellID, healType, interrupted, ...)
	self:UpdateIncoming(nil, ...)
end



function HealBarsClassic:HealComm_ModifierChanged(event, guid)
	self:UpdateIncoming(nil, guid)
end



function HealBarsClassic:HealComm_GUIDDisappeared(event, guid)
	self:UpdateIncoming(nil,guid)
end

function HealBarsClassic:ResetHealBars()
	wipe(currentHeals)
	for unitFrame, _ in pairs(healBarTable) do
		HealBarsClassic:ClearHealBar(unitFrame)
	end
end

function HealBarsClassic:ClearHealBar(unitFrame)
	for _,barFrame in pairs(healBarTable[unitFrame]) do
		barFrame:SetWidth(0)
		barFrame:Hide()
	end
end



function HealBarsClassic:UpdateIncoming(callbackTime, ...)
	local targetGUID, healType
	local guidTable = {}
	local currentTime =GetTime()
	
	local hotType= bit.bor(libCHC.HOT_HEALS,libCHC.BOMB_HEALS)
	local channelType = libCHC.CHANNEL_HEALS
	if HBCdb.global.showHots and not HBCdb.global.seperateHots then
		healType = bit.bor(hotType,libCHC.DIRECT_HEALS)
	else
		healType = libCHC.DIRECT_HEALS
	end
	for i=1, select("#", ...) do
		local amountTable = {}
		targetGUID = select(i, ...)
		local targetHealMod = (libCHC:GetHealModifier(targetGUID) or 1)
		if not currentHeals[targetGUID] then
			currentHeals[targetGUID] = {}
		else
			wipe(currentHeals[targetGUID])
		end
		
		if not HBCdb.global.seperateOwnColor then
			local flatAmount = (libCHC:GetHealAmount(targetGUID, healType, currentTime + HBCdb.global.healTimeframe) or 0) +
						(libCHC:GetHealAmount(targetGUID, channelType, currentTime + 3) or 0)
			--calc flat/all heals
			table.insert(currentHeals[targetGUID],{healType = 'flat'
									, amount = flatAmount * targetHealMod})
			--calc hot heals
			if HBCdb.global.showHots and HBCdb.global.seperateHots then
				table.insert(currentHeals[targetGUID],{healType = 'hot'
									, amount = (libCHC:GetHealAmount(targetGUID, hotType, currentTime + HBCdb.global.timeframe) or 0) * targetHealMod})
			end
		
		else
			local ownHealAmount,_,ownHealTime = libCHC:GetTimeframeHealAmount(targetGUID,
							healType,currentTime,currentTime + HBCdb.global.healTimeframe,nil,playerGUID) 
							+ libCHC:GetTimeframeHealAmount(targetGUID,
								channelType,currentTime,currentTime + 3,nil,playerGUID)
			ownHealAmount = ownHealAmount * targetHealMod
			local beforeHealAmount = 0
			if ownHealTime then
				beforeHealAmount = libCHC:GetTimeframeHealAmount(targetGUID,
							healType,currentTime, ownHealTime - 0.001, playerGUID) 
							+ libCHC:GetTimeframeHealAmount(targetGUID,
							channelType,currentTime, ownHealTime - 0.001, playerGUID) 	
				beforeHealAmount = beforeHealAmount * targetHealMod
			else
				ownHealTime = 0
			end
			local afterHealAmount = libCHC:GetTimeframeHealAmount(targetGUID,
							healType,ownHealTime,currentTime + HBCdb.global.healTimeframe, playerGUID) 
							+ libCHC:GetTimeframeHealAmount(targetGUID,
							channelType,ownHealTime,currentTime + 3, playerGUID) 
			afterHealAmount = afterHealAmount * targetHealMod
			table.insert(currentHeals[targetGUID],{healType = 'flat', amount = beforeHealAmount})
			table.insert(currentHeals[targetGUID],{healType = 'ownFlat', amount = ownHealAmount})
			table.insert(currentHeals[targetGUID],{healType = 'afterOwnFlat', amount = afterHealAmount})
			
			if HBCdb.global.showHots then
				if HBCdb.global.seperateHots then
					table.insert(currentHeals[targetGUID],{healType = 'ownHot'
										, amount = (libCHC:GetHealAmount(targetGUID, hotType, GetTime() + HBCdb.global.timeframe, playerGUID) or 0) * targetHealMod})
					table.insert(currentHeals[targetGUID],{healType = 'hot'
										, amount = (libCHC:GetOthersHealAmount(targetGUID, hotType, GetTime() + HBCdb.global.timeframe) or 0) * targetHealMod})
				else
					table.insert(currentHeals[targetGUID],{healType = 'hot'
										, amount = (libCHC:GetHealAmount(targetGUID, hotType, currentTime + HBCdb.global.timeframe) or 0) * targetHealMod})
				end
			end
			
			
		
		end
		
		HealBarsClassic:UpdateGUIDHeals(targetGUID)
		

	end
	if callbackTime then
		local args = {...}
		C_Timer.After(callbackTime, function()
			HealBarsClassic:UpdateIncoming(nil, unpack(args))
			end)
	end

end




local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
eventFrame:RegisterEvent("PLAYER_ROLES_ASSIGNED")
eventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
eventFrame:SetScript("OnEvent", function(self, event, ...)
			HealBarsClassic[event](self, ...) end)


--[[ End of "Event Registration" code section ]]--