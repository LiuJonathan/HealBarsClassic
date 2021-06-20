local libCHC = LibStub("LibHealComm-4.0", true)

HealBarsClassic = LibStub("AceAddon-3.0"):NewAddon("HealBarsClassic")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceConsole = LibStub("AceConsole-3.0")

local healBarTable = {} 
local masterFrameTable = {}
local invulGUIDs = {}
local healBarTypeList = {}
local healBarTypeOrder = {}
local activeBarTypes = {['flat']={}, ['hot']={}}
local currentHeals = {}
healBarTypeOrder[1]='flat'
healBarTypeOrder[2]='hot'
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


local HBCdefault = {
	global = {
		overhealPercent = 20,
		timeframe = 3,
		healTimeframe = 4,
		showHots = true,
		seperateHots = true,
		healColor = {0, 1, 0, 1.0},
		hotColor = {110/255, 230/255, 55/255, 0.7},
		defensiveIndicator = true,
		predictiveHealthLost = false,
		fastUpdate = false,
		fastUpdateDuration = 0.03, --~30 updates per second
	}
}

function HealBarsClassic:getHealColor(healType)
	local colorVarName, colorTable
	if healType =='flat' then 
		colorTable = HBCdb.global.healColor
	else
		colorTable = HBCdb.global.hotColor
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


	
	
	for healType, properties in pairs(activeBarTypes) do
		if not currentBarList[healType] then
			currentBarList[healType] = CreateFrame("StatusBar"
				, "HealBarsClassicIncHealBar"..unitFrame:GetName()..healType, unitFrame)
			currentBarList[healType]:SetFrameStrata("LOW")
			if(unitFrame:GetName() == 'FocusFrame') then
				currentBarList[healType]:SetFrameLevel(currentBarList[healType]:GetFrameLevel())
			end
			currentBarList[healType]:SetFrameLevel(currentBarList[healType]:GetFrameLevel()-1)
			if textureType == 'raid' then
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
	eventFrame:SetScript("OnEvent",function(self) HealBarsClassic:UpdateFrameHeals(self:GetParent()) end)

end


function HealBarsClassic:UpdateGUIDHeals(GUID)

	if partyGUIDs[targetGUID] then
		if globalFrameList[partyGUIDs[targetGUID]] then
			HealBarsClassic:UpdateFrameHeals(globalFrameList[partyGUIDs[targetGUID]])
		end
	end
	
	for frameName, unitFrame in pairs(masterFrameTable) do
		local displayedUnit = HealBarsClassic:GetFrameInfo(unitFrame)
		if displayedUnit and UnitGUID(displayedUnit) == GUID then
			HealBarsClassic:UpdateFrameHeals(unitFrame)
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


function HealBarsClassic:UpdateFrameHeals(unitFrame)
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
	local currentHealsForFrame = currentHeals[UnitGUID(displayedUnit)]
	for index, barType in pairs(healBarTypeOrder) do
		local barFrame = healBarTable[unitFrame][barType]
		if barFrame then 

			if currentHealsForFrame then
				local amount = currentHealsForFrame[barType]
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
			else
				barFrame:Hide()
			end
		end
	
	
	end
end

local function UnitFrame_SetUnitHook(unitFrame)
	HealBarsClassic:UnRegisterAllInactiveFrames()
	HealBarsClassic:UpdateFrameHeals(unitFrame)
end

hooksecurefunc("UnitFrame_SetUnit", UnitFrame_SetUnitHook) -- This needs early hooking

local function CompactUnitFrame_SetUnitHook(unitFrame)
	HealBarsClassic:createHealBars(unitFrame,'raid')
end
hooksecurefunc("CompactUnitFrame_SetUnit", CompactUnitFrame_SetUnitHook) -- This needs early hooking

local invulSpells = {
	[642] = {name = 'DIVSHLD',duration = 12} -- Divine Shield Rank 1
	, [1020] = {name = 'DIVSHLD',duration = 12} -- Divine Shield Rank 2
	, [1022] = {name = 'BLSPROT',duration = 6} -- Blessing of Protection Rank 1
	, [5599] = {name = 'BLSPROT',duration = 6} -- Blessing of Protection Rank 2
	, [10278] = {name = 'BLSPROT',duration = 6} -- Blessing of Protection Rank 3
	, [498] = {name = 'DIVPROT',duration = 6} -- Divine Protection Rank 1
	, [5573] = {name = 'DIVPROT',duration = 6} -- Divine Protection Rank 2
	, [19752] = {name = 'DIVINTR',duration = 6} -- Divine Intervention
	, [45438] = {name = 'ICEBLCK',duration = 10} -- Ice Block
	--, [22812] = {name = 'BARKSKN',duration = 12} -- Ice Block
	--, [5384] = {name = 'FEIGN',duration = 30} -- Feign Death
	} 
	
function HealBarsClassic:COMBAT_LOG_EVENT_UNFILTERED(...)
	
	if not HBCdb.global.defensiveIndicator or (not UnitInParty("player") and not UnitInRaid("player")) then return end
	
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
	local invulSpell = invulSpells[spellId]
	
	if not invulSpell then return end 
	
	local invulGUID = destGUID or SourceGUID
	if eventType == 'SPELL_AURA_APPLIED' then 
		invulGUIDs[invulGUID] = invulSpell.name
		C_Timer.After(invulSpell.duration,function() 
				if invulGUIDs[invulGUID] == invulSpell.name then
					invulGUIDs[invulGUID] = nil
				end end) --fallback in case target moves out of combat log range
	else --aura removed
		invulGUIDs[invulGUID] = nil
	end
	
	--blind update all frames to trigger status text updates. Inefficient but happens rarely
	HealBarsClassic:UpdateGUIDHeals(invulGUID)

		
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
		local invulGUID = invulGUIDs[guid]
		if invulGUID then
			unitFrame.statusText:SetFormattedText("%s", invulGUID)
			unitFrame.statusText:Show()
			return
		end
	end
	
	--predictive health lost feature
	if unitFrame.optionTable.healthText == "losthealth" and HBCdb.global.predictiveHealthLost and currentHeals then
		local currentHeals = currentHeals[UnitGUID(unitFrame.displayedUnit)] or {}
		local totalHeals = 0
		
		for healType, amount in pairs(currentHeals) do
			totalHeals = totalHeals + amount
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
		AceConsole:Print('|c42f581FFHealBarsClassic|r - /hbc /HealBarsClassic\n'..
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
	HealBarsClassic:UpdateFrameHeals(_G['TargetFrame'])
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
			HealBarsClassic:UpdateFrameHeals(unitFrame)
			num = num + 1
			unitFrame = _G["CompactPartyFrameMember"..num]
		end
		unitFrame = _G["CompactRaidFrame1"]
		num = 1
		while unitFrame do
			HealBarsClassic:UpdateFrameHeals(unitFrame)
			num = num + 1
			unitFrame = _G["CompactRaidFrame"..num]
		end
	end
	if UnitInRaid("player") then
		for k=1, NUM_RAID_PULLOUT_FRAMES do
			frame = _G["RaidPullout"..k]
			for z=1, frame.numPulloutButtons do
				unitFrame = _G[frame:GetName().."Button"..z]
				HealBarsClassic:UpdateFrameHeals(unitFrame)
			end
		end
		for i=1, 8 do
			local grpHeader = "CompactRaidGroup"..i
			if _G[grpHeader] then
				for k=1, 5 do
					unitFrame = _G[grpHeader.."Member"..k]
					HealBarsClassic:UpdateFrameHeals(unitFrame)
				end
			end
		end
	end
end

function HealBarsClassic:HealComm_HealUpdated(event, casterGUID, spellID, healType, endTime, ...)
	if (bit.band(healType,libCHC.CASTED_HEALS) > 0 or healType == libCHC.BOMB_HEALS) 
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



function HealBarsClassic:UpdateIncoming(callbackTime, ...)
	local targetGUID, healType
	local guidTable = {}
	
	local hotType= bit.bor(libCHC.HOT_HEALS,libCHC.BOMB_HEALS)
	if HBCdb.global.showHots and not HBCdb.global.seperateHots then
		healType = libCHC.ALL_HEALS
	else
		healType = libCHC.CASTED_HEALS
	end
	for i=1, select("#", ...) do
		local amountTable = {}
		targetGUID = select(i, ...)
		
		--[[
		--calc flat 
		if HBCdb.global.showOwnHeal then
			amountTable['flat'] = (libCHC:GetHealAmount(targetGUID, healType, GetTime() 
				+ HBCdb.global.healTimeframe) or 0) * (libCHC:GetHealModifier(targetGUID) or 1)
		
			--calc all flat
			--calc own flat
		--calc hot
			--calc all hot
			--calc own hot
		--]]
		
		amountTable['flat'] = (libCHC:GetHealAmount(targetGUID, healType, GetTime() + HBCdb.global.healTimeframe) or 0) * (libCHC:GetHealModifier(targetGUID) or 1)
		
		
		if HBCdb.global.showHots then
			local hotAmount = (libCHC:GetHealAmount(targetGUID, hotType, GetTime()+HBCdb.global.timeframe) or 0) * (libCHC:GetHealModifier(targetGUID) or 1)
			if HBCdb.global.seperateHots then
				amountTable['hot'] = hotAmount
			else
				amountTable['flat'] = amountTable['flat'] + hotAmount
			end
		end
		
		for healType, amount in pairs(amountTable) do
			if not currentHeals[targetGUID] then
				currentHeals[targetGUID] = {}
			end
			if not currentHeals[targetGUID][healType] then
				currentHeals[targetGUID][healType] = {}
			end
			currentHeals[targetGUID][healType] = amount	
		end
		
		HealBarsClassic:UpdateGUIDHeals(targetGUID)
		

	end
	if callbackTime then
		C_Timer.After(callbackTime, function()
			HealBarsClassic:UpdateIncoming(nil, unpack(arg))
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