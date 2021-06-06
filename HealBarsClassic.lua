local libCHC = LibStub("LibHealComm-4.0", true)

HealBarsClassic = LibStub("AceAddon-3.0"):NewAddon("HealBarsClassic")

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
		timeframe = 6,
		healTimeframe = 4,
		showHots = true,
		seperateHots = true,
		healColor = {0, 1, 50/255, 1},
		hotColor = {120/255, 210/255, 65/255, 0.7},
		feignIndicator = true,
		predictiveHealthLost = false,
		fastUpdate = false,
		fastUpdateDuration = 0.03, --~30 updates per second
	}
}

function HealBarsClassic:getHealColor(healType)
	return unpack(healBarColors[healType])
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

--[[x
	Function: CompactUnitFrame_UpdateStatusTextHook
	Purpose: Handle status text features
--]]
function CompactUnitFrame_UpdateStatusTextHook(unitFrame)
	if (not unitFrame.statusText or not unitFrame.optionTable.displayStatusText 
		or not UnitIsConnected(unitFrame.unit) or UnitIsDeadOrGhost(unitFrame.displayedUnit)) then return end
	
	if (UnitIsFeignDeath(unitFrame.displayedUnit) and HBCdb.global.feignIndicator) then
		unitFrame.statusText:SetText('FEIGN')
	end

	--predictive health lost feature
	if ( unitFrame.optionTable.healthText == "losthealth" and HBCdb.global.predictiveHealthLost ) then
		local currentHeals = (currentHots and currentHeals[UnitGUID(unitFrame.displayedUnit)]) or 0
		local currentHots = (currentHots and currentHots[UnitGUID(unitFrame.displayedUnit)]) or 0
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
function HealBarsClassic:OnInitialize()

	HBCdb = LibStub("AceDB-3.0"):New("HealBarSettings", HBCdefault)
	
	healBarColors['flat']=HBCdb.global.healColor
	healBarColors['hot']=HBCdb.global.hotColor
	

	HealBarsClassic:CreateAllHealBars()
	HealBarsClassic:CreateConfigs()
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
		
		
	C_Timer.After(HBCdb.global.fastUpdateDuration,HealBarsClassic.UpdateHealthValuesLoop)
		
end

--[[x
	Function: UpdateColors
	Purpose: Update the color of all heal bars
]]--
function HealBarsClassic:UpdateColors()
	for unitFrame, barTable in pairs(healBarTable) do
	
		for barType in ipairs(activeBarTypes) do
			local barFrame = barTable[barType]
			barFrame:SetStatusBarColor(HealBarsClassic:getHealColor(healType))
		
		end
	end
end

--[[
	Function: UpdateHealthValuesLoop
	Purpose: Force health and max health value update
		Experimental - may not actually work
--]]
function HealBarsClassic:UpdateHealthValuesLoop()
	if UnitInRaid("player") and HBCdb.global.fastUpdate then
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
	end
	C_Timer.After(HBCdb.global.fastUpdateDuration,HealBarsClassic.UpdateHealthValuesLoop)
end

--[[`
	Function: UNIT_PET
	Purpose: Update pet heal bars
	Inputs: Unit
		Where Unit is the UnitID of the pet being updated
]]--
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

--[[
	Function: PLAYER_TARGET_CHANGED
	Purpose: Update player target heal bars
]]--
function HealBarsClassic:PLAYER_TARGET_CHANGED(frame)
	self:UpdateFrameHeals(frame)
end


--[[x
	Function: PLAYER_ROLES_ASSIGNED
	Purpose: Update party and raid heal bars after a raid role assignment
]]--
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


--[[x
	Function: HealBarsClassic_HealUpdated
	Purpose: HealCommLib callback handler
			Redirect callback
	Inputs: event, casterGUID, spellID, healType, interrupted, args
			Where event, casterGUID, spellID, etc. are non-functional
			Where args is a table of GUIDs to update
--]]
function HealBarsClassic:HealComm_HealUpdated(event, casterGUID, spellID, healType, endTime, ...)
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
function HealBarsClassic:HealComm_HealStopped(event, casterGUID, spellID, healType, interrupted, ...)
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
function HealBarsClassic:HealComm_ModifierChanged(event, guid)
	self:UpdateIncoming(guid)
end


--[[x
	Function: HealComm_GUIDDisappeared
	Purpose: Update heal bars after a GUID disappears from view
	Inputs: Event, GUID
			Where Event is non-functional
			Where GUID is the GUID that disappeared
--]]
function HealBarsClassic:HealComm_GUIDDisappeared(event, guid)
	self:UpdateIncoming(guid)
end


--[[x
	Function: UpdateIncoming
	Purpose: Stores incoming healing information from healcomm library
	Inputs: args
			A table of GUIDs to update
--]]
function HealBarsClassic:UpdateIncoming(...)
	local targetGUID, num, frame, unitFrame, healType
	local hotType= bit.bor(libCHC.HOT_HEALS,libCHC.BOMB_HEALS)
	if HBCdb.global.showHots and not HBCdb.global.seperateHots then
		healType = libCHC.ALL_HEALS
	else
		healType = libCHC.CASTED_HEALS
	end
	for i=1, select("#", ...) do
		local amountTable = {}
		targetGUID = select(i, ...)
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

end




--[[
	Code section: Event Registration
	Purpose: Set event to initalize HealBarsClassic on first login and 
			update targets after target/pet/raid role change
--]]
local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_TARGET_CHANGED")
frame:RegisterEvent("PLAYER_ROLES_ASSIGNED")
frame:RegisterEvent("UNIT_PET")
frame:SetScript("OnEvent", function(self, event, ...)
		HealBarsClassic[event](HealBarsClassic, ...)
end)


--[[ End of "Event Registration" code section ]]--