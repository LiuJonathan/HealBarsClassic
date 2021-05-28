local libCHC = LibStub("LibHealComm-4.0", true)

HealCommClassic = LibStub("AceAddon-3.0"):NewAddon("HealCommClassic")

--move initalization to doinit
local healBarTable = {} --when init initalize heal bar type
local masterFrameTable = {}
local healBarTypeList = {}
local healBarColors = {}
local healBarTypeOrder = {}
local activeBarTypes = {['flat']={}, ['hot']={}}
local currentHeals = {}
healBarTypeOrder[1]='flat'
healBarTypeOrder[2]='hot'
HCCdb = {}


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


local HCCdefault = {
	global = {
		overhealPercent = 20,
		timeframe = 6,
		showHots = true,
		seperateHots = true,
		healColor = {0, 1, 50/255, 1},
		hotColor = {120/255, 210/255, 65/255, 0.7},
		feignIndicator = true,
		predictiveHealthLost = false,
		fastUpdate = false,
		fastUpdateDuration = 0.1, --10 updates per second
	}
}

function HealCommClassic:getHealColor(healType)
	return unpack(healBarColors[healType])
end

function HealCommClassic:CreateAllHealBars()
	for name,unitFrame in pairs(globalFrameList) do
		HealCommClassic:createHealBars(unitFrame)
	end

end



--[[x

--]]
function HealCommClassic:createHealBars(unitFrame, textureType)
	local displayedUnit = HealCommClassic:GetFrameInfo(unitFrame)
	if not unitFrame or not unitFrame:GetName() then return end
	
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
			currentBarList[healType]:SetStatusBarColor(HealCommClassic:getHealColor(healType))
		end
	end
end

function HealCommClassic:UpdateGUIDHeals(GUID)
	
	if partyGUIDs[targetGUID] then
		if globalFrameList[partyGUIDs[targetGUID]] then
			print('frame updated for party member')
			HealCommClassic:UpdateFrameHeals(globalFrameList[partyGUIDs[targetGUID]])
		end
	end
	
	for frameName, unitFrame in pairs(masterFrameTable) do
		displayedUnit = HealCommClassic:GetFrameInfo(unitFrame)
		if displayedUnit and UnitGUID(displayedUnit) == GUID then
			HealCommClassic:UpdateFrameHeals(unitFrame)
			if unitFrame.statusText then
				CompactUnitFrame_UpdateStatusText(unitFrame)
			end
		
		end
	
	end 

end

function HealCommClassic:GetFrameInfo(unitFrame)
	
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
function HealCommClassic:UpdateFrameHeals(unitFrame)
	
	if not unitFrame then return end
	
	local displayedUnit, healthBar = HealCommClassic:GetFrameInfo(unitFrame)
	if not healBarTable[unitFrame] or not displayedUnit or not UnitExists(displayedUnit) then return end

	local unit = displayedUnit
	local maxHealth= UnitHealthMax(unit)
	local health= UnitHealth(unit)
	local healthWidth=healthBar:GetWidth() * (health / maxHealth)
	local maxWidth = healthBar:GetWidth() * ( 1 + (HCCdb.global.overhealPercent/100))
	
	local healWidthTotal = 0
	local currentHealsForFrame = currentHeals[UnitGUID(displayedUnit)]
	
	for index, barType in pairs(healBarTypeOrder) do
		local barFrame = healBarTable[unitFrame][barType]
		if barFrame then 

			if currentHealsForFrame then
				local amount = currentHealsForFrame[barType]
				if amount and amount > 0 and (health < maxHealth or HCCdb.global.overhealPercent > 0 )
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

local function UnitFrame_SetUnit(unitFrame)
	HealCommClassic:UpdateFrameHeals(unitFrameHealthBar:GetParent())
end


--[[x
	Function: UnitFrameHealthBar_OnValueChangedHook
	Purpose: Updates unit frames when a unit's max health changes
]]--
local function UnitFrameHealthBar_OnValueChangedHook(unitFrameHealthBar)
	HealCommClassic:UpdateFrameHeals(unitFrameHealthBar:GetParent())
end


--[[x
	Function: UnitFrameHealthBar_OnUpdateHook
	Purpose: Updates unit frames when a unit's health changes
]]--
local function UnitFrameHealthBar_OnUpdateHook(unitFrameHealthBar)
	if unitFrameHealthBar.unit ~= "player" then return end
	HealCommClassic:UpdateFrameHeals(unitFrameHealthBar:GetParent())
end
hooksecurefunc("UnitFrameHealthBar_OnUpdate", UnitFrameHealthBar_OnUpdateHook) -- This needs early hooking


--[[x
	Function: CompactUnitFrame_UpdateHealthHook
	Purpose: Update heal bars when a unit's health changes
]]--
local function CompactUnitFrame_UpdateHealthHook(unitFrame)
	HealCommClassic:UpdateFrameHeals(unitFrame)
end


--[[x
	Function: CompactUnitFrame_UpdateMaxHealthHook
	Purpose: Update heal calculations after a max health change
	Inputs: self
		Where self is a unit frame to update
]]--
local function CompactUnitFrame_UpdateMaxHealthHook(unitFrame)
	HealCommClassic:UpdateFrameHeals(unitFrame)
end


--[[x
	Function: CompactUnitFrame_SetUnitHook
	Purpose: Create a new heal bar whenever any frame is assigned a new unit
]]--
local function CompactUnitFrame_SetUnitHook(unitFrame)
	HealCommClassic:createHealBars(unitFrame,'raid')
end
hooksecurefunc("CompactUnitFrame_SetUnit", CompactUnitFrame_SetUnitHook) -- This needs early hooking

--[[x
	Function: CompactUnitFrame_UpdateStatusTextHook
	Purpose: Handle status text features
--]]
function CompactUnitFrame_UpdateStatusTextHook(unitFrame)
	if (not unitFrame.statusText or not unitFrame.optionTable.displayStatusText 
		or not UnitIsConnected(unitFrame.unit) or UnitIsDeadOrGhost(unitFrame.displayedUnit)) then return end
	
	if (UnitIsFeignDeath(unitFrame.displayedUnit) and HCCdb.global.feignIndicator) then
		unitFrame.statusText:SetText('FEIGN')
	end

	--predictive health lost feature
	if ( unitFrame.optionTable.healthText == "losthealth" and HCCdb.global.predictiveHealthLost ) then
		local currentHeals = currentHeals[UnitGUID(unitFrame.displayedUnit)] or 0
		local currentHots = currentHots[UnitGUID(unitFrame.displayedUnit)] or 0
		local healthLost = UnitHealthMax(unitFrame.displayedUnit) - UnitHealth(unitFrame.displayedUnit)
		local healthDelta = (currentHeals + currentHots) - healthLost
		
		if healthDelta >= 0 then
			unitFrame.statusText:Hide()
		else
			unitFrame.statusText:SetFormattedText("%d", healthDelta)
		end
		
		
	end 
end

--[[
	Function: OnInitialize
	Purpose: Initalize necessary functions, variables and set hooks, callbacks
]]--
function HealCommClassic:OnInitialize()

	--convert options from earlier than 1.3.0
	if HealCommSettings and HealCommSettings.timeframe then
		settings = HCCdefault.global
		settings.overhealPercent = HealCommSettings.overhealpercent or settings.overhealPercent
		settings.timeframe = HealCommSettings.timeframe or settings.timeframe
		if HealCommSettings.showHots then
			settings.showHots = HealCommSettings.showHots
		end
		if HealCommSettings.seperateHots then
			settings.seperateHots = HealCommSettings.seperateHots
		end
		settings.feignIndicator = settings.feignIndicator
		settings.predictiveHealthLost = settings.predictiveHealthLost
		if HealCommSettings.healColor then
			settings.healColor = {HealCommSettings.healColor.red, HealCommSettings.healColor.green, HealCommSettings.healColor.blue, HealCommSettings.healColor.alpha or settings.healColor[4]}
		end
		if HealCommSettings.hotColor then
			settings.hotColor = {HealCommSettings.hotColor.red, HealCommSettings.hotColor.green, HealCommSettings.hotColor.blue, HealCommSettings.hotColor.alpha or settings.hotColor[4]}
		end
		settings.statusText = HealCommSettings.statusText or settings.predictiveHealthLost
		HealCommSettings=nil
	end
	HCCdb = LibStub("AceDB-3.0"):New("HealCommSettings", HCCdefault)
	
	healBarColors['flat']=HCCdb.global.healColor
	healBarColors['hot']=HCCdb.global.hotColor
	

	HealCommClassic:CreateAllHealBars()
	HealCommClassic:CreateConfigs()
	--hooksecurefunc("RaidPullout_Update", RaidPullout_UpdateTargetHook)
	hooksecurefunc("UnitFrameHealthBar_OnValueChanged", UnitFrameHealthBar_OnValueChangedHook)
	hooksecurefunc("CompactUnitFrame_UpdateHealth", CompactUnitFrame_UpdateHealthHook)
	hooksecurefunc("CompactUnitFrame_UpdateMaxHealth", CompactUnitFrame_UpdateMaxHealthHook)
	hooksecurefunc("CompactUnitFrame_UpdateStatusText", CompactUnitFrame_UpdateStatusTextHook)
	libCHC.RegisterCallback(HealCommClassic, "HealComm_HealStarted", "HealComm_HealUpdated")
	libCHC.RegisterCallback(HealCommClassic, "HealComm_HealStopped")
	libCHC.RegisterCallback(HealCommClassic, "HealComm_HealDelayed", "HealComm_HealUpdated")
	libCHC.RegisterCallback(HealCommClassic, "HealComm_HealUpdated")
	libCHC.RegisterCallback(HealCommClassic, "HealComm_ModifierChanged")
	libCHC.RegisterCallback(HealCommClassic, "HealComm_GUIDDisappeared")
		
end

--[[x
	Function: UpdateColors
	Purpose: Update the color of all heal bars
]]--
function HealCommClassic:UpdateColors()
	for unitFrame, barTable in pairs(healBarTable) do
	
		for barType in ipairs(activeBarTypes) do
			local barFrame = barTable[barType]
			barFrame:SetStatusBarColor(HealCommClassic:getHealColor(healType))
		
		end
	end
end

--[[
	Function: UpdateHealthValuesLoop
	Purpose: Force health and max health value update
		Experimental - may not actually work
--]]
function HealCommClassic:UpdateHealthValuesLoop()
	if UnitInRaid("player") and HCCdb.global.fastUpdate then
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
		for k=1, NUM_RAID_PULLOUT_FRAMES do
			frame = getglobal("RaidPullout"..k)
			for z=1, frame.numPulloutButtons do
				unitFrame = getglobal(frame:GetName().."Button"..z)
				if unitFrame.unit and UnitExists(unitFrame.unit) then
					CompactUnitFrame_UpdateMaxHealth(unitFrame.healthBar:GetParent())
					CompactUnitFrame_UpdateHealth(unitFrame.healthBar:GetParent())
				end
			end
		end
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
		C_Timer.After(HCCdb.global.fastUpdateDuration,HealCommClassic.UpdateHealthValuesLoop)
	end
end

--[[`
	Function: UNIT_PET
	Purpose: Update pet heal bars
	Inputs: Unit
		Where Unit is the UnitID of the pet being updated
]]--
function HealCommClassic:UNIT_PET(unit)
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
		HealCommClassic:UpdateFrameHeals(globalFrameList[petunit])
	end
end

--[[
	Function: PLAYER_TARGET_CHANGED
	Purpose: Update player target heal bars
]]--
function HealCommClassic:PLAYER_TARGET_CHANGED(frame)
	self:UpdateFrameHeals(frame)
end


--[[x
	Function: PLAYER_ROLES_ASSIGNED
	Purpose: Update party and raid heal bars after a raid role assignment
]]--
function HealCommClassic:PLAYER_ROLES_ASSIGNED() 
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
			HealCommClassic:UpdateFrameHeals(unitFrame)
			num = num + 1
			unitFrame = _G["CompactPartyFrameMember"..num]
		end
		unitFrame = _G["CompactRaidFrame1"]
		num = 1
		while unitFrame do
			HealCommClassic:UpdateFrameHeals(unitFrame)
			num = num + 1
			unitFrame = _G["CompactRaidFrame"..num]
		end
	end
	if UnitInRaid("player") then
		for k=1, NUM_RAID_PULLOUT_FRAMES do
			frame = _G["RaidPullout"..k]
			for z=1, frame.numPulloutButtons do
				unitFrame = _G[frame:GetName().."Button"..z]
				HealCommClassic:UpdateFrameHeals(unitFrame)
			end
		end
		for i=1, 8 do
			local grpHeader = "CompactRaidGroup"..i
			if _G[grpHeader] then
				for k=1, 5 do
					unitFrame = _G[grpHeader.."Member"..k]
					HealCommClassic:UpdateFrameHeals(unitFrame)
				end
			end
		end
	end
end


--[[x
	Function: HealCommClassic_HealUpdated
	Purpose: HealCommLib callback handler
			Redirect callback
	Inputs: event, casterGUID, spellID, healType, interrupted, args
			Where event, casterGUID, spellID, etc. are non-functional
			Where args is a table of GUIDs to update
--]]
function HealCommClassic:HealComm_HealUpdated(event, casterGUID, spellID, healType, endTime, ...)
	self:UpdateIncoming(...)
end


--[[x
	Function: HealComm_HealStopped
	Purpose: HealCommLib callback handler
			Redirect callback
	Inputs: event, casterGUID, spellID, healType, interrupted, args
			Where event, casterGUID, spellID, etc. are non-functional
			Where args is a table of GUIDs to update
--]]
function HealCommClassic:HealComm_HealStopped(event, casterGUID, spellID, healType, interrupted, ...)
	self:UpdateIncoming(...)
end


--[[x
	Function: HealComm_ModifierChanged
	Purpose: HealCommLib callback handler
			Redirect callback
	Inputs: Event, GUID
			Where Event is non-functional
			Where GUID is the GUID to update
--]]
function HealCommClassic:HealComm_ModifierChanged(event, guid)
	self:UpdateIncoming(guid)
end


--[[x
	Function: HealComm_GUIDDisappeared
	Purpose: Update heal bars after a GUID disappears from view
	Inputs: Event, GUID
			Where Event is non-functional
			Where GUID is the GUID that disappeared
--]]
function HealCommClassic:HealComm_GUIDDisappeared(event, guid)
	self:UpdateIncoming(guid)
end


--[[x
	Function: UpdateIncoming
	Purpose: Stores incoming healing information from healcomm library
	Inputs: args
			A table of GUIDs to update
--]]
function HealCommClassic:UpdateIncoming(...)
	local targetGUID, num, frame, unitFrame, healType
	local hotType=libCHC.HOT_HEALS
	if HCCdb.global.showHots and not HCCdb.global.seperateHots then
		healType = libCHC.ALL_HEALS
	else
		healType = bit.bor(libCHC.CASTED_HEALS,libCHC.BOMB_HEALS)
	end
	for i=1, select("#", ...) do
		local amountTable = {}
		targetGUID = select(i, ...)
		amountTable['flat'] = (libCHC:GetHealAmount(targetGUID, healType, nil) or 0) * (libCHC:GetHealModifier(targetGUID) or 1)
		if HCCdb.global.seperateHots and HCCdb.global.showHots then
			amountTable['hot']= (libCHC:GetHealAmount(targetGUID, hotType, GetTime()+HCCdb.global.timeframe) or 0) * (libCHC:GetHealModifier(targetGUID) or 1)
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
		
		HealCommClassic:UpdateGUIDHeals(targetGUID)
		

	end

end




--[[
	Code section: Event Registration
	Purpose: Set event to initalize HealCommClassic on first login and 
			update targets after target/pet/raid role change
--]]
local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_TARGET_CHANGED")
frame:RegisterEvent("PLAYER_ROLES_ASSIGNED")
frame:RegisterEvent("UNIT_PET")
frame:SetScript("OnEvent", function(self, event, ...)
		HealCommClassic[event](HealCommClassic, ...)
end)


--[[ End of "Event Registration" code section ]]--