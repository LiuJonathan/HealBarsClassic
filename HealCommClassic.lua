--[[
	Table of contents, in order:
		- *General settings
		- RaidPulloutButton_OnLoadHook
		- UnitFrameHealthBar_OnValueChangedHook
		- UnitFrameHealthBar_OnUpdateHook
		- CompactUnitFrame_UpdateHealthHook
		- CompactUnitFrame_UpdateMaxHealthHook
		- CompactUnitFrame_SetUnitHook
		- CompactUnitFrame_UpdateStatusTextHook
		- OnInitialize
		- CreateBars
		- UpdateColors
		- UpdateHealthValuesLoop
		- UNIT_PET
		- PLAYER_TARGET_CHANGED
		- PLAYER_ROLES_ASSIGNED
		- HealComm_HealUpdated
		- HealComm_HealStopped
		- HealComm_ModifierChanged
		- HealComm_GUIDDisappeared
		- UpdateIncoming
		- UpdateFrame
		- CreateConfigs
		- *Event registration
--]]


local libCHC = LibStub("LibHealComm-4.0", true)

HealCommClassic = LibStub("AceAddon-3.0"):NewAddon("HealCommClassic")
--Remember to update version number!!
--Curseforge release starting from 1.1.7
HealCommClassic.version = "1.3.2"

local hpBars = {} --incoming castedHeals
local hotBars={} --incoming HoTs
local healColor,hotColor

local frames = {
				["player"] = { bar = getglobal("PlayerFrameHealthBar"), frame = _G["PlayerFrame"] },
				["pet"] = { bar = getglobal("PetFrameHealthBar"), frame = _G["PetFrame"] },
				["target"] = { bar = getglobal("TargetFrameHealthBar"), frame = _G["TargetFrame"] },
				["party1"] = { bar = getglobal("PartyMemberFrame1HealthBar"), frame = _G["PartyMemberFrame1"] },
				["partypet1"] = { bar = getglobal("PartyMemberFrame1PetFrameHealthBar"), frame = _G["PartyMemberFrame1PetFrame"] },
				["party2"] = { bar = getglobal("PartyMemberFrame2HealthBar"), frame = _G["PartyMemberFrame2"] },
				["partypet2"] = { bar = getglobal("PartyMemberFrame2PetFrameHealthBar"), frame = _G["PartyMemberFrame2PetFrame"] },
				["party3"] = { bar = getglobal("PartyMemberFrame3HealthBar"), frame = _G["PartyMemberFrame3"] },
				["partypet3"] = { bar = getglobal("PartyMemberFrame3PetFrameHealthBar"), frame = _G["PartyMemberFrame3PetFrame"] },
				["party4"] = { bar = getglobal("PartyMemberFrame4HealthBar"), frame = _G["PartyMemberFrame4"] },
				["partypet4"] = { bar = getglobal("PartyMemberFrame4PetFrameHealthBar"), frame = _G["PartyMemberFrame4PetFrame"] },
				}

local partyGUIDs = {
	[UnitGUID("player")] = "player",
}
local currentHeals = {}
local currentHots ={}

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

local HCCdb = {}

--[[
	Function: RaidPulloutButton_OnLoadHook
	Purpose: Creates heal bars for raid members upon joining a raid
	Inputs: self
		Where self is a unit frame to update
]]--
local function RaidPulloutButton_OnLoadHook(self)
	if not hpBars[self] then
		hpBars[getglobal(self:GetParent():GetName().."HealthBar")] = CreateFrame("StatusBar", self:GetName().."HealthBarIncHeal" , self)
		hpBars[getglobal(self:GetParent():GetName().."HealthBar")]:SetFrameStrata("LOW")
		hpBars[getglobal(self:GetParent():GetName().."HealthBar")]:SetFrameLevel(hpBars[getglobal(self:GetParent():GetName().."HealthBar")]:GetFrameLevel()-1)
		hpBars[getglobal(self:GetParent():GetName().."HealthBar")]:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
		hpBars[getglobal(self:GetParent():GetName().."HealthBar")]:SetMinMaxValues(0, 1)
		hpBars[getglobal(self:GetParent():GetName().."HealthBar")]:SetValue(1)
		hpBars[getglobal(self:GetParent():GetName().."HealthBar")]:SetStatusBarColor(unpack(HCCdb.global.healColor))
	end
	if not hotBars[self] then
		hotBars[getglobal(self:GetParent():GetName().."HealthBar")] = CreateFrame("StatusBar", self:GetName().."HotBarIncHeal" , self)
		hotBars[getglobal(self:GetParent():GetName().."HealthBar")]:SetFrameStrata("LOW")
		hotBars[getglobal(self:GetParent():GetName().."HealthBar")]:SetFrameLevel(hotBars[getglobal(self:GetParent():GetName().."HealthBar")]:GetFrameLevel()-1)
		hotBars[getglobal(self:GetParent():GetName().."HealthBar")]:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
		hotBars[getglobal(self:GetParent():GetName().."HealthBar")]:SetMinMaxValues(0, 1)
		hotBars[getglobal(self:GetParent():GetName().."HealthBar")]:SetValue(1)
		hotBars[getglobal(self:GetParent():GetName().."HealthBar")]:SetStatusBarColor(unpack(HCCdb.global.hotColor))
	end
end

--[[
	Function: UnitFrameHealthBar_OnValueChangedHook
	Purpose: Updates unit frames when a unit's max health changes
	Inputs: self
		Where self is a unit frame to update
]]--
local function UnitFrameHealthBar_OnValueChangedHook(self)
	HealCommClassic:UpdateFrame(self, self.unit, currentHeals[UnitGUID(self.unit)] or 0, currentHots[UnitGUID(self.unit)] or 0)
end


--[[
	Function: UnitFrameHealthBar_OnUpdateHook
	Purpose: Updates unit frames when a unit's health changes
	Inputs: self
		Where self is a unit frame to update
	Notes: 
		Function hook happens immediately after function definition	
]]--
local function UnitFrameHealthBar_OnUpdateHook(self)
	if self.unit ~= "player" then return end
	HealCommClassic:UpdateFrame(self, self.unit, currentHeals[UnitGUID(self.unit)] or 0, currentHots[UnitGUID(self.unit)] or 0)
end
hooksecurefunc("UnitFrameHealthBar_OnUpdate", UnitFrameHealthBar_OnUpdateHook) -- This needs early hooking


--[[
	Function: CompactUnitFrame_UpdateHealthHook
	Purpose: Update heal bars when a unit's health changes
	Inputs: self
		Where self is a unit frame to update
]]--
local function CompactUnitFrame_UpdateHealthHook(self)
	if not hpBars[self.healthBar] and not hotBars[self.healthBar] then return end
	HealCommClassic:UpdateFrame(self.healthBar, self.displayedUnit, currentHeals[UnitGUID(self.displayedUnit)] or 0, currentHots[UnitGUID(self.displayedUnit)] or 0)
end


--[[
	Function: CompactUnitFrame_UpdateMaxHealthHook
	Purpose: Update heal calculations after a max health change
	Inputs: self
		Where self is a unit frame to update
]]--
local function CompactUnitFrame_UpdateMaxHealthHook(self)
	if not hpBars[self.healthBar] and not hotBars[self.healthBar] then return end
	HealCommClassic:UpdateFrame(self.healthBar, self.displayedUnit, currentHeals[UnitGUID(self.displayedUnit)] or 0, currentHots[UnitGUID(self.displayedUnit)] or 0)
end


--[[
	Function: CompactUnitFrame_SetUnitHook
	Purpose: Create a new heal bar whenever any frame is assigned a new unit
	Inputs: self, Unit
		Where self is a parent frame to attach to
		Where Unit is the UnitID of the unit being added
	Notes: 
		Function hook happens immediately after function definition	
]]--
local function CompactUnitFrame_SetUnitHook(self, unit)
	if (self:IsForbidden()) then return end --Catch for forbidden nameplates in dungeons/raids
	if not hpBars[self.healthBar] then
		hpBars[self.healthBar] = CreateFrame("StatusBar", nil, self)
		hpBars[self.healthBar]:SetFrameStrata("LOW")
		hpBars[self.healthBar]:SetFrameLevel(hpBars[self.healthBar]:GetFrameLevel()-1)
		hpBars[self.healthBar]:SetStatusBarTexture("Interface\\RaidFrame\\Raid-Bar-Hp-Fill")
		hpBars[self.healthBar]:SetMinMaxValues(0, 1)
		hpBars[self.healthBar]:SetValue(1)
		hpBars[self.healthBar]:SetStatusBarColor(unpack(HCCdb.global.healColor))
	end
	if not hotBars[self.healthBar] then
		hotBars[self.healthBar] = CreateFrame("StatusBar", nil, self)
		hotBars[self.healthBar]:SetFrameStrata("LOW")
		hotBars[self.healthBar]:SetFrameLevel(hotBars[self.healthBar]:GetFrameLevel()-1)
		hotBars[self.healthBar]:SetStatusBarTexture("Interface\\RaidFrame\\Raid-Bar-Hp-Fill")
		hotBars[self.healthBar]:SetMinMaxValues(0, 1)
		hotBars[self.healthBar]:SetValue(1)
		hotBars[self.healthBar]:SetStatusBarColor(unpack(HCCdb.global.hotColor))
	end
end
hooksecurefunc("CompactUnitFrame_SetUnit", CompactUnitFrame_SetUnitHook) -- This needs early hooking

--[[
	Function: CompactUnitFrame_UpdateStatusTextHook
	Purpose: Handle status text features
--]]
function CompactUnitFrame_UpdateStatusTextHook(frame)
	if (not frame.statusText or not frame.optionTable.displayStatusText or not UnitIsConnected(frame.unit) or UnitIsDeadOrGhost(frame.displayedUnit)) then return end
	
	if (UnitIsFeignDeath(frame.displayedUnit) and HCCdb.global.feignIndicator) then
		frame.statusText:SetText('FEIGN')
	end

	if ( frame.optionTable.healthText == "losthealth" and HCCdb.global.predictiveHealthLost ) then
		local currentHeals = currentHeals[UnitGUID(frame.displayedUnit)] or 0
		local currentHots = currentHots[UnitGUID(frame.displayedUnit)] or 0
		local healthLost = UnitHealthMax(frame.displayedUnit) - UnitHealth(frame.displayedUnit)
		local healthDelta = (currentHeals + currentHots) - healthLost
		
		if healthDelta >= 0 then
			frame.statusText:Hide()
		else
			frame.statusText:SetFormattedText("%d", healthDelta)
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
	healColor=HCCdb.global.healColor 
	hotColor=HCCdb.global.hotColor
	

	self:CreateBars()
	self:CreateConfigs()
	hooksecurefunc("RaidPulloutButton_OnLoad", RaidPulloutButton_OnLoadHook)
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


--[[
	Function: CreateBars
	Purpose: Create and initalize heal bars for all frames
]]--
function HealCommClassic:CreateBars()
	for unit,v in pairs(frames) do
		if not hpBars[v] then
			hpBars[v.bar] = CreateFrame("StatusBar", "IncHealBar"..unit, v.frame)
			hpBars[v.bar]:SetFrameStrata("LOW")
			hpBars[v.bar]:SetFrameLevel(hpBars[v.bar]:GetFrameLevel()-1)
			hpBars[v.bar]:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
			hpBars[v.bar]:SetMinMaxValues(0, 1)
			hpBars[v.bar]:SetValue(1)
			hpBars[v.bar]:SetStatusBarColor(unpack(HCCdb.global.healColor))
		end
		if not hotBars[v] then
			hotBars[v.bar] = CreateFrame("StatusBar", "IncHotBar"..unit, v.frame)
			hotBars[v.bar]:SetFrameStrata("LOW")
			hotBars[v.bar]:SetFrameLevel(hotBars[v.bar]:GetFrameLevel()-1)
			hotBars[v.bar]:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
			hotBars[v.bar]:SetMinMaxValues(0, 1)
			hotBars[v.bar]:SetValue(1)
			hotBars[v.bar]:SetStatusBarColor(unpack(HCCdb.global.hotColor))
		end
	end
end


--[[
	Function: UpdateColors
	Purpose: Update the color of all heal bars
]]--
function HealCommClassic:UpdateColors()
	for unit,v in pairs(hpBars) do
		if hpBars[unit] then
			hpBars[unit]:SetStatusBarColor(unpack(HCCdb.global.healColor))
		end
		if hotBars[unit] then
			hotBars[unit]:SetStatusBarColor(unpack(HCCdb.global.hotColor))
		end
	end
end

--[[
	Function: UpdateHealthValuesLoop
	Purpose: Force health and max health value update
--]]
function HealCommClassic:UpdateHealthValuesLoop()
	if UnitInRaid("player") and HCCdb.global.fastUpdate then
		unitframe = _G["CompactRaidFrame1"]
		num = 1
		while unitframe do
			if unitframe.displayedUnit and UnitExists(unitframe.displayedUnit) then
				CompactUnitFrame_UpdateMaxHealth(unitframe.healthBar:GetParent())
				CompactUnitFrame_UpdateHealth(unitframe.healthBar:GetParent())
			end
			num = num + 1
			unitframe = _G["CompactRaidFrame"..num]
		end
		for k=1, NUM_RAID_PULLOUT_FRAMES do
			frame = getglobal("RaidPullout"..k)
			for z=1, frame.numPulloutButtons do
				unitframe = getglobal(frame:GetName().."Button"..z)
				if unitframe.unit and UnitExists(unitframe.unit) then
					CompactUnitFrame_UpdateMaxHealth(unitframe.healthBar:GetParent())
					CompactUnitFrame_UpdateHealth(unitframe.healthBar:GetParent())
				end
			end
		end
		for i=1, 8 do
			local grpHeader = "CompactRaidGroup"..i
			if _G[grpHeader] then
				for k=1, 5 do
					unitframe = _G[grpHeader.."Member"..k]
					if unitframe and unitframe.displayedUnit and UnitExists(unitframe.displayedUnit) then
						CompactUnitFrame_UpdateMaxHealth(unitframe.healthBar:GetParent())
						CompactUnitFrame_UpdateHealth(unitframe.healthBar:GetParent())				
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
	if hpBars[frames[petunit].bar] or hotBars[frames[petunit].bar] then
		self:UpdateFrame(frames[petunit].bar, petunit, currentHeals[UnitGUID("pet")] or 0, currentHots[UnitGUID("pet")] or 0)
	end
end

--[[
	Function: PLAYER_TARGET_CHANGED
	Purpose: Update player target heal bars
]]--
function HealCommClassic:PLAYER_TARGET_CHANGED()
	self:UpdateFrame(frames["target"].bar, "target", currentHeals[UnitGUID("target")] or 0, currentHots[UnitGUID("target")] or 0)
end


--[[
	Function: PLAYER_ROLES_ASSIGNED
	Purpose: Update party and raid heal bars after a raid role assignment
]]--
function HealCommClassic:PLAYER_ROLES_ASSIGNED() 
	local frame, unitframe, num
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
		unitframe = _G["CompactPartyFrameMember1"]
		num = 1
		while unitframe do
			if unitframe.displayedUnit and UnitExists(unitframe.displayedUnit) then
				self:UpdateFrame(unitframe.healthBar, unitframe.displayedUnit, amount, hotAmount) --no amount declaration? call just hides bars
			end
			num = num + 1
			unitframe = _G["CompactPartyFrameMember"..num]
		end
		unitframe = _G["CompactRaidFrame1"]
		num = 1
		while unitframe do
			if unitframe.displayedUnit and UnitExists(unitframe.displayedUnit) then
				self:UpdateFrame(unitframe.healthBar, unitframe.displayedUnit, amount, hotAmount)
			end
			num = num + 1
			unitframe = _G["CompactRaidFrame"..num]
		end
	end
	if UnitInRaid("player") then
		for k=1, NUM_RAID_PULLOUT_FRAMES do
			frame = getglobal("RaidPullout"..k)
			for z=1, frame.numPulloutButtons do
				unitframe = getglobal(frame:GetName().."Button"..z)
				if unitframe.unit and UnitExists(unitframe.unit) then
					self:UpdateFrame(getglobal(unitframe:GetName().."HealthBar"), unitframe.unit, currentHeals[UnitGUID(unitframe.unit)] or 0, currentHots[UnitGUID(unitframe.unit)] or 0)
				end
			end
		end
		for i=1, 8 do
			local grpHeader = "CompactRaidGroup"..i
			if _G[grpHeader] then
				for k=1, 5 do
					unitframe = _G[grpHeader.."Member"..k]
					if unitframe and unitframe.displayedUnit and UnitExists(unitframe.displayedUnit) then
						self:UpdateFrame(unitframe.healthBar, unitframe.displayedUnit, currentHeals[UnitGUID(unitframe.displayedUnit)] or 0, currentHots[UnitGUID(unitframe.displayedUnit)] or 0)
					end
				end
			end
		end
	end
end


--[[
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


--[[
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


--[[
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


--[[
	Function: HealComm_GUIDDisappeared
	Purpose: Update heal bars after a GUID disappears from view
	Inputs: Event, GUID
			Where Event is non-functional
			Where GUID is the GUID that disappeared
--]]
function HealCommClassic:HealComm_GUIDDisappeared(event, guid)
	self:UpdateIncoming(guid)
end


--[[
	Function: UpdateIncoming
	Purpose: Stores incoming healing information from healcomm library
	Inputs: args
			A table of GUIDs to update
--]]
function HealCommClassic:UpdateIncoming(...)
	local targetGUID, num, frame, unitframe, healType
	local hotType=libCHC.HOT_HEALS
	if HCCdb.global.showHots and not HCCdb.global.seperateHots then
		healType = libCHC.ALL_HEALS
	else
		healType = libCHC.CASTED_HEALS
	end
	for i=1, select("#", ...) do
		local amount, hotAmount
		targetGUID = select(i, ...)
		amount = (libCHC:GetHealAmount(targetGUID, healType, nil) or 0) * (libCHC:GetHealModifier(targetGUID) or 1)
		if HCCdb.global.seperateHots and HCCdb.global.showHots then
			hotAmount= (libCHC:GetHealAmount(targetGUID, hotType, GetTime()+HCCdb.global.timeframe) or 0) * (libCHC:GetHealModifier(targetGUID) or 1)
		end
		currentHots[targetGUID] = hotAmount 
		currentHeals[targetGUID] = amount 
		if UnitGUID("target") == targetGUID then 
			self:UpdateFrame(frames["target"].bar, "target", amount, hotAmount)
		end
		if partyGUIDs[targetGUID] then
			self:UpdateFrame(frames[partyGUIDs[targetGUID]].bar, partyGUIDs[targetGUID], amount,hotAmount)
		end
		if UnitInParty("player") then
			unitframe = _G["CompactPartyFrameMember1"]
			num = 1
			while unitframe do
				if unitframe.displayedUnit and UnitExists(unitframe.displayedUnit) and UnitGUID(unitframe.displayedUnit) == targetGUID then
					self:UpdateFrame(unitframe.healthBar, unitframe.displayedUnit, amount, hotAmount)
				end
				num = num + 1
				unitframe = _G["CompactPartyFrameMember"..num]
			end
			unitframe = _G["CompactRaidFrame1"]
			num = 1
			while unitframe do
				if unitframe.displayedUnit and UnitExists(unitframe.displayedUnit) and UnitGUID(unitframe.displayedUnit) == targetGUID then
					self:UpdateFrame(unitframe.healthBar, unitframe.displayedUnit, amount, hotAmount)
					CompactUnitFrame_UpdateStatusText(unitframe.healthBar:GetParent())
				end
				num = num + 1
				unitframe = _G["CompactRaidFrame"..num]
			end
		end
		if UnitInRaid("player") then
			for k=1, NUM_RAID_PULLOUT_FRAMES do
				frame = getglobal("RaidPullout"..k)
				for z=1, frame.numPulloutButtons do
					unitframe = getglobal(frame:GetName().."Button"..z)
					if unitframe.unit and UnitExists(unitframe.unit) and UnitGUID(unitframe.unit) == targetGUID then
						self:UpdateFrame(getglobal(unitframe:GetName().."HealthBar"), unitframe.unit, amount, hotAmount)
						CompactUnitFrame_UpdateStatusText(unitframe.healthBar:GetParent())
					end
				end
			end
			for j=1, 8 do
				local grpHeader = "CompactRaidGroup"..j
				if _G[grpHeader] then
					for k=1, 5 do
						unitframe = _G[grpHeader.."Member"..k]
						if unitframe and unitframe.displayedUnit and UnitExists(unitframe.displayedUnit) and UnitGUID(unitframe.displayedUnit) == targetGUID then
							self:UpdateFrame(unitframe.healthBar, unitframe.displayedUnit, currentHeals[UnitGUID(unitframe.displayedUnit)] or 0, currentHots[UnitGUID(unitframe.displayedUnit)] or 0)
							CompactUnitFrame_UpdateStatusText(unitframe.healthBar:GetParent())
						end
					end
				end
			end
		end
	end
end


--[[
	Function: UpdateFrame
	Purpose: Updates heal bar sizes based on incoming healing
	Inputs: Frame, Unit, Amount, hotAmount
		Where Frame is the heal bar frame to update
		Where Unit is the UnitID that the heal bar references
		Where Amount is the amount of incoming healing
		Where hotAmount is the amount of incoming HoTs
--]]
function HealCommClassic:UpdateFrame(frame, unit, amount, hotAmount)
	local health, maxHealth= UnitHealth(unit), UnitHealthMax(unit)
	local healthWidth=frame:GetWidth() * (health / maxHealth)
	local incWidth=0

	if( amount and amount > 0 and (health < maxHealth or HCCdb.global.overhealPercent > 0 )) and frame:IsVisible() then
		hpBars[frame]:Show()
		incWidth = frame:GetWidth() * (amount / maxHealth)
		if (healthWidth + incWidth) > (frame:GetWidth() * (1+(HCCdb.global.overhealPercent/100)) ) then
			incWidth = frame:GetWidth() * (1+(HCCdb.global.overhealPercent/100)) - healthWidth
		end
		hpBars[frame]:SetWidth(incWidth)
		hpBars[frame]:SetHeight(frame:GetHeight())
		hpBars[frame]:ClearAllPoints()
		hpBars[frame]:SetPoint("TOPLEFT", frame, "TOPLEFT", healthWidth, 0)
	else
		hpBars[frame]:Hide()
	end

	if( hotAmount and hotAmount > 0 and (health < maxHealth or HCCdb.global.overhealPercent > 0 )) and frame:IsVisible() then
		hotBars[frame]:Show()
		local hotWidth = frame:GetWidth() * (hotAmount / maxHealth)
		if (healthWidth + hotWidth + incWidth) > (frame:GetWidth() * (1+(HCCdb.global.overhealPercent/100)) ) then -- can be compressed with better math
			hotWidth = frame:GetWidth() * (1+(HCCdb.global.overhealPercent/100)) - healthWidth - incWidth
			if hotWidth <= 0 then
				hotBars[frame]:Hide() 
			end
		end
		
		hotBars[frame]:SetWidth(hotWidth)
		hotBars[frame]:SetHeight(frame:GetHeight())
		hotBars[frame]:ClearAllPoints()
		hotBars[frame]:SetPoint("TOPLEFT", frame, "TOPLEFT", healthWidth + incWidth, 0)
	else
		hotBars[frame]:Hide()
	end
end


--[[
	Function: CreateConfigs
	Purpose: Create and attach options page
	Notes: 
		For convenience, order is incremented in steps of two so new options can be squeezed between them.
]]--
function HealCommClassic:CreateConfigs()
	local options = {
		name = 'HealCommClassic Options',
		type = 'group',
		args = {
			desc1 = {
				order = 0,
				type = 'description',
				width = 2.5,
				name = 'Version '..HealCommClassic.version,
			},
			button0 = {
				order = 1,
				type = 'execute',
				name = 'Reset to defaults',
				confirm = true,
				func = function() HCCdb:ResetDB() end
			},
			desc2 = {
				order = 2,
				type = 'description',
				width = 'full',
				name = 'HealCommClassic is an implementation of HealComm (LibHealComm) for Blizzard\'s raid frames'
			},
		},
	}
	options.args['healthBars'] = {
		name = 'Health Bars',
		type = 'group',
		order = 0,
		args = {
			header0 = {
				order = 2,
				type = 'header',
				name = 'General Settings',
			},
			overheal = {
				order = 4,
				type = 'range',
				name = 'Extend Overheals',
				desc = 'How far heals can extend on overhealing, in percentage of the health bar size',
				min = 0,
				max = 0.5,
				step = 0.01,
				isPercent = true,
				get = function() return HCCdb.global.overhealPercent / 100 end,
				set = function(_,value) HCCdb.global.overhealPercent = value * 100 end,
			},
			spacer1 = {
				order = 6,
				type = 'description',
				name = '\n',
			},
			header1 = {
				order = 8,
				type = 'header',
				name = 'Heal Over Times'
			},
			hotToggle = {
				order = 10,
				type = 'toggle',
				name = 'Show HoTs',
				desc = 'Include HoTs in healing prediction',
				width = 'full',
				get = function() return HCCdb.global.showHots end,
				set = function(_, value) HCCdb.global.showHots = value end,
			},
			timeframe = {
				order = 12,
				type = 'range',
				name = 'Timeframe',
				desc = 'How many seconds into the future to predict HoTs',
				min = 3,
				max = 23,
				step = 1,
				get = function() return HCCdb.global.timeframe end,
				set = function(info,value) HCCdb.global.timeframe = value end,
			},
			spacer2 = {
				order = 14,
				type = 'description',
				name = '\n',
			},
			header2 = {
				order = 16,
				type = 'header',
				name = 'Color Options',
			},
			desc1 = {
				order = 17,
				type = 'description',
				name = 'Note: The plus and minus slider sets transparency.'
			},
			healColor = { 
				order = 18,
				type = 'color',
				name = 'Heal Color',
				hasAlpha = true,
				width = 'full',
				get = function() return unpack(HCCdb.global.healColor) end,
				set = function (_, r, g, b, a) HCCdb.global.healColor = {r,g,b,a}; self:UpdateColors() end,
			},
			spacer3 = {
				order = 20,
				type = 'description',
				name = '\n',
			},
			seperateHot = {
				order = 22,
				type = 'toggle',
				name = 'Seperate HoT Color',
				desc = 'Color HoTs as a seperate color.\n\'Show HoTs\' must be enabled.',
				width = 'full',
				get = function() return HCCdb.global.seperateHots end,
				set = function(_, value) HCCdb.global.seperateHots = value end,
			},
			hotColor = { 
				order = 24,
				type = 'color',
				name = 'HoT Color',
				hasAlpha = true,
				width = 'full',
				get = function() return unpack(HCCdb.global.hotColor) end,
				set = function (_,r, g, b, a) HCCdb.global.hotColor = {r,g,b,a}; self:UpdateColors() end,
			},
		},
	}
	options.args['statusText'] = {
		name = 'Status Text',
		type = 'group',
		order = 2,
		args = {
			header0 = {
				order = 0,
				type = 'header',
				name = 'General Settings',
			},
			feignToggle = {
				order = 2,
				type = 'toggle',
				name = 'Feign death indicator',
				descStyle = 'inline',
				desc = 'Shows the text \'FEIGN\' instead of \'DEAD\' when a hunter feigns death.',
				width = 'full',
				get = function() return HCCdb.global.feignIndicator end,
				set = function(_, value) HCCdb.global.feignIndicator = value end,
			},
			spacer = {
				order = 3,
				type = 'description',
				name = '\n',
			},
			desc1 = {
				order = 4,
				type = 'header',
				name = 'Health Text Replacers',
			},
			desc2 = {
				order = 6,
				type = 'description',
				name = 'These options replace the functionality of \'Display Health Text\' in Blizzard\'s Raid Profiles.\n\n',
			},
			predictiveHealthLostToggle = {
				order = 8,
				type = 'toggle',
				name = 'Predictive \'Health Lost\'',
				desc = 'Shows the amount of health missing after all shown heals go off. \nThis replaces the \'Health Lost\' option.',
				descStyle = 'inline',
				width = 'full',
				get = function() return HCCdb.global.predictiveHealthLost end,
				set = function(_, value) HCCdb.global.predictiveHealthLost = value end,
			},
			continued = {
				order = 20,
				type = 'description',
				name = '\n\nMore options will be added in the future.',
			}
		},
	}
	options.args['misc']={
		name = 'Miscellaneous',
		type = 'group',
		order = 4,
		args = {
			header0 = {
				order = 0,
				type = 'header',
				name = 'General Settings',
			},
			fastUpdate = {
				order = 2,
				type = 'toggle',
				name = 'Fast Raid Health Update',
				desc = 'Adds extra health updates every second.\nMay impact framerate on low end machines.',
				descStyle = 'inline',
				width = 'full',
				get = function() return HCCdb.global.fastUpdate end,
				set = function(_, value) HCCdb.global.fastUpdate = value; C_Timer.After(HCCdb.global.fastUpdateDuration, HealCommClassic.UpdateHealthValuesLoop) end,
			},
		}
	}

	LibStub("AceConfig-3.0"):RegisterOptionsTable("HCCOptions", options)
	LibStub("AceConfigDialog-3.0"):AddToBlizOptions("HCCOptions","HealCommClassic")
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