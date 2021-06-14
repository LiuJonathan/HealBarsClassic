local libCHC = LibStub("LibHealComm-4.0", true)

HealBarsClassic = LibStub("AceAddon-3.0"):NewAddon("HealBarsClassic")
AceConfigDialog = LibStub("AceConfigDialog-3.0")
AceConsole = LibStub("AceConsole-3.0")

--move initalization to doinit
local healBarTable = {} --when init initalize heal bar type
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

function HealBarsClassic:CreateAllHealBars()
	for name,unitFrame in pairs(globalFrameList) do
		HealBarsClassic:createHealBars(unitFrame)
	end

end



--[[x

--]]
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
				, "IncHealBar"..unitFrame:GetName()..healType, unitFrame)
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
end


function HealBarsClassic:UpdateGUIDHeals(GUID)
	
	if partyGUIDs[targetGUID] then
		if globalFrameList[partyGUIDs[targetGUID]] then
			HealBarsClassic:UpdateFrameHeals(globalFrameList[partyGUIDs[targetGUID]])
		end
	end
	
	for frameName, unitFrame in pairs(masterFrameTable) do
		displayedUnit = HealBarsClassic:GetFrameInfo(unitFrame)
		if displayedUnit and UnitGUID(displayedUnit) == GUID then
			HealBarsClassic:UpdateFrameHeals(unitFrame)
			if unitFrame.statusText then
				CompactUnitFrame_UpdateStatusText(unitFrame)
			end
		
		end
	
	end 

end

function HealBarsClassic:GetFrameInfo(unitFrame)
	
	if not unitFrame then return end
		displayedUnit = unitFrame.displayedUnit
		healthBar = unitFrame.healthBar
	if displayedUnit == nil then 
		displayedUnit = unitFrame.unit
	end
	if healthBar == nil then
		healthBar = unitFrame.healthbar
	end
	return displayedUnit,healthBar

end


--[[x
	Function: UpdateFrame
	Purpose: Updates heal bars for a single unit frame after a non-healing event
--]]
function HealBarsClassic:UpdateFrameHeals(unitFrame)
	
	if not unitFrame then return end
	
	local displayedUnit, healthBar = HealBarsClassic:GetFrameInfo(unitFrame)
	if not healBarTable[unitFrame] or not displayedUnit or not UnitExists(displayedUnit) then return end

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
	HealBarsClassic:UpdateFrameHeals(unitFrame)
end


--[[x
	Function: UnitFrameHealthBar_OnValueChangedHook
	Purpose: Updates unit frames when a unit's max health changes
]]--
local function UnitFrameHealthBar_OnValueChangedHook(unitFrameHealthBar)
	HealBarsClassic:UpdateFrameHeals(unitFrameHealthBar:GetParent())
end


--[[x
	Function: UnitFrameHealthBar_OnUpdateHook
	Purpose: Updates unit frames when a unit's health changes
]]--
local function UnitFrameHealthBar_OnUpdateHook(unitFrameHealthBar)
	if unitFrameHealthBar.unit ~= "player" then return end
	HealBarsClassic:UpdateFrameHeals(unitFrameHealthBar:GetParent())
end
hooksecurefunc("UnitFrameHealthBar_OnUpdate", UnitFrameHealthBar_OnUpdateHook) -- This needs early hooking


--[[x
	Function: CompactUnitFrame_UpdateHealthHook
	Purpose: Update heal bars when a unit's health changes
]]--
local function CompactUnitFrame_UpdateHealthHook(unitFrame)
	HealBarsClassic:UpdateFrameHeals(unitFrame)
end


--[[x
	Function: CompactUnitFrame_UpdateMaxHealthHook
	Purpose: Update heal calculations after a max health change
	Inputs: self
		Where self is a unit frame to update
]]--
local function CompactUnitFrame_UpdateMaxHealthHook(unitFrame)
	HealBarsClassic:UpdateFrameHeals(unitFrame)
end


--[[x
	Function: CompactUnitFrame_SetUnitHook
	Purpose: Create a new heal bar whenever any frame is assigned a new unit
]]--
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
	--, [5384] = {name = 'FEIGN',duration = 30} -- Feign Death
	} 
	
function HealBarsClassic:COMBAT_LOG_EVENT_UNFILTERED(timestamp, eventType, hideCaster, sourceGUID, sourceName
													, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, ...)
	
	if (not UnitInParty("player") and not UnitInRaid("player")) or not HBCdb.global.defensiveIndicator then return end
	if bit.band(sourceFlags,0x00000C00) ~= 0x00000400 then return end --check if caster is a player
	if not eventType == 'SPELL_AURA_APPLIED' and not eventType == 'SPELL_AURA_REMOVED' then return end
		
	local spellId = select(1,...)
	local invulSpell = invulSpells[spellId]
	
	if not invulSpell then return end 
	
	local invulGUID = destGUID or SourceGUID
	if eventType == 'SPELL_AURA_APPLIED' then 
		invulGUIDs[invulGUID] = invulSpell.name
		C_Timer.After(invulSpell.duration,function() 
				if invulGUIDs[invulGUID] == name then
					invulSpells[invulGUID] = nil
				end end) --fallback in case target moves out of combat log range
	else
		invulGUIDs[invulGUID] = nil
	end
	
	--blind update all frames to trigger status text updates. Inefficient but happens rarely
	HealBarsClassic:UpdateGUIDHeals(invulGUID)
	
			
end

--[[x
	Function: CompactUnitFrame_UpdateStatusTextHook
	Purpose: Handle status text features
--]]
function CompactUnitFrame_UpdateStatusTextHook(unitFrame)
	if not unitFrame.statusText or not unitFrame.optionTable.displayStatusText 
		or not UnitIsConnected(unitFrame.displayedUnit) or UnitIsDeadOrGhost(unitFrame.displayedUnit) then return end
	

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
		local healthLost = UnitHealthMax(unitFrame.displayedUnit) - UnitHealth(unitFrame.displayedUnit)
		local healthDelta = totalHeals - healthLost
		
		if healthDelta >= 0 then
			unitFrame.statusText:Hide()
		else
			unitFrame.statusText:SetFormattedText("%d", healthDelta)
			unitFrame.statusText:Show()
		end
	end 
end

--[[
	Function: OnInitialize
	Purpose: Initalize necessary functions, variables and set hooks, callbacks
]]--
function HealBarsClassic:OnInitialize()

	HBCdb = LibStub("AceDB-3.0"):New("HealBarSettings", HBCdefault)
	HBCdb.RegisterCallback(HealBarsClassic, "OnProfileChanged", "UpdateColors")

	HealBarsClassic:CreateAllHealBars()
	HealBarsClassic:CreateConfigs()
	HealBarsClassic:RegisterChatCommands()
	--hooksecurefunc("RaidPullout_Update", RaidPullout_UpdateTargetHook)
	hooksecurefunc("UnitFrameHealthBar_OnValueChanged", UnitFrameHealthBar_OnValueChangedHook)
	hooksecurefunc("CompactUnitFrame_UpdateHealth", CompactUnitFrame_UpdateHealthHook)
	hooksecurefunc("CompactUnitFrame_UpdateMaxHealth", CompactUnitFrame_UpdateMaxHealthHook)
	hooksecurefunc("CompactUnitFrame_UpdateStatusText", CompactUnitFrame_UpdateStatusTextHook)
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
		AceConsole:Print('|c42f581FFHealBarsClassic|r - These players have a compatible healing addon:\n')
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
						' a heal since you\'ve last logged in. Cross-addon compatible.')
	end
end

--[[x
	Function: UpdateColors
	Purpose: Update the color of all heal bars
]]--
function HealBarsClassic:UpdateColors()

	for unitFrame, unitFrameBars in pairs(healBarTable) do
		for barType, barFrame in pairs(unitFrameBars) do
			barFrame:SetStatusBarColor(HealBarsClassic:getHealColor(barType))
		end
	end
end

--[[
	Function: UpdateHealthValuesLoop
	Purpose: Force health and max health value update
		Experimental - may not actually work
--]]
function HealBarsClassic:UpdateHealthValuesLoop()
	if (UnitInParty("player") or UnitInRaid("player")) and HBCdb.global.fastUpdate then
		unitFrame = _G["CompactRaidFrame1"]
		num = 1
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
	end
	C_Timer.After(HBCdb.global.fastUpdateDuration,HealBarsClassic.UpdateHealthValuesLoop)
end

function HealBarsClassic:UNIT_PET(unit)
	if unit ~= "player" and strsub(unit,1,5) ~= "party" then return end
	petunit = unit == "player" and "pet" or "partypet"..strsub(unit,6)
	for guid,unit in pairs(partyGUIDs) do
		if unit == petunit then
			partyGUIDs[guid] = nil
			break
		end
	end
	if UnitExists(petunit) then
		partyGUIDs[UnitGUID(petunit)] = petunit
	end
	if petunit and globalFrameList[petunit] then
		HealBarsClassic:UpdateFrameHeals(globalFrameList[petunit])
	end
end

function HealBarsClassic:PLAYER_TARGET_CHANGED(frame)
	HealBarsClassic:UpdateFrameHeals(frame)
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


--[[x
	Function: HealComm_ModifierChanged
	Purpose: HealCommLib callback handler
			Redirect callback
	Inputs: Event, GUID
			Where Event is non-functional
			Where GUID is the GUID to update
--]]
function HealBarsClassic:HealComm_ModifierChanged(event, guid)
	self:UpdateIncoming(nil, guid)
end


--[[x
	Function: HealComm_GUIDDisappeared
	Purpose: Update heal bars after a GUID disappears from view
	Inputs: Event, GUID
			Where Event is non-functional
			Where GUID is the GUID that disappeared
--]]
function HealBarsClassic:HealComm_GUIDDisappeared(event, guid)
	self:UpdateIncoming(nil,guid)
end


--[[x
	Function: UpdateIncoming
	Purpose: Stores incoming healing information from healcomm library
	Inputs: args
			A table of GUIDs to update
--]]
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
		table.insert(guidTable, targetGUID) --repack data for callback
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
		
		if callbackTime then
			C_Timer.After(callbackTime, function()
				HealBarsClassic:UpdateIncoming(nil, unpack(guidTable))
				end)
		end

	end

end




--[[
	Code section: Event Registration
	Purpose: Set event to initalize HealBarsClassic on first login and 
			update targets after target/pet/raid role change
--]]
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
eventFrame:RegisterEvent("PLAYER_ROLES_ASSIGNED")
eventFrame:RegisterEvent("UNIT_PET")
eventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
eventFrame:SetScript("OnEvent", function(self, event, ...)
		if event == 'COMBAT_LOG_EVENT_UNFILTERED' then
			HealBarsClassic[event](self, CombatLogGetCurrentEventInfo())
		else
			HealBarsClassic[event](self, ...)
		end end)


--[[ End of "Event Registration" code section ]]--