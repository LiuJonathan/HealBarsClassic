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
		- UpdateBars
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
HealCommClassic.version = "1.2.4"

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
	profile = {
		general = {
			overhealPercent = 20,
			timeframe = 6,
			showHots = true,
			seperateHots = true,
			healColor = {0, 1, 50/255, 1},
			hotColor = {120/255, 210/255, 65/255, 0.7},
			statusText = false
		}
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
		hpBars[getglobal(self:GetParent():GetName().."HealthBar")]:SetStatusBarColor(unpack(HCCdb.profile.general.healColor))
	end
	if not hotBars[self] then
		hotBars[getglobal(self:GetParent():GetName().."HealthBar")] = CreateFrame("StatusBar", self:GetName().."HotBarIncHeal" , self)
		hotBars[getglobal(self:GetParent():GetName().."HealthBar")]:SetFrameStrata("LOW")
		hotBars[getglobal(self:GetParent():GetName().."HealthBar")]:SetFrameLevel(hotBars[getglobal(self:GetParent():GetName().."HealthBar")]:GetFrameLevel()-1)
		hotBars[getglobal(self:GetParent():GetName().."HealthBar")]:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
		hotBars[getglobal(self:GetParent():GetName().."HealthBar")]:SetMinMaxValues(0, 1)
		hotBars[getglobal(self:GetParent():GetName().."HealthBar")]:SetValue(1)
		hotBars[getglobal(self:GetParent():GetName().."HealthBar")]:SetStatusBarColor(unpack(HCCdb.profile.general.hotColor))
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
	CompactUnitFrame_UpdateAll(self)
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
		hpBars[self.healthBar]:SetStatusBarColor(unpack(HCCdb.profile.general.healColor))
	end
	if not hotBars[self.healthBar] then
		hotBars[self.healthBar] = CreateFrame("StatusBar", nil, self)
		hotBars[self.healthBar]:SetFrameStrata("LOW")
		hotBars[self.healthBar]:SetFrameLevel(hotBars[self.healthBar]:GetFrameLevel()-1)
		hotBars[self.healthBar]:SetStatusBarTexture("Interface\\RaidFrame\\Raid-Bar-Hp-Fill")
		hotBars[self.healthBar]:SetMinMaxValues(0, 1)
		hotBars[self.healthBar]:SetValue(1)
		hotBars[self.healthBar]:SetStatusBarColor(unpack(HCCdb.profile.general.hotColor))
	end
end
hooksecurefunc("CompactUnitFrame_SetUnit", CompactUnitFrame_SetUnitHook) -- This needs early hooking

--[[
	Function: CompactUnitFrame_UpdateStatusTextHook
	Purpose: Handle status text features
--]]
function CompactUnitFrame_UpdateStatusTextHook(frame)
	if (not frame.statusText) then return end
	if (UnitIsFeignDeath(frame.displayedUnit)) then
		frame.statusText:SetText('FEIGN')
	end
		
	--[[
	if ( not frame.statusText ) then
		return;
	end
	if ( not frame.optionTable.displayStatusText ) then
		frame.statusText:Hide();
		return;
	end

	local currentHeals = currentHeals[UnitGUID(frame.displayedUnit)] or 0
	local currentHots = currentHots[UnitGUID(frame.displayedUnit)] or 0

	if ( not UnitIsConnected(frame.unit) ) then
		frame.statusText:SetTextColor(0.5, 0.5, 0.5)
		frame.statusText:SetText(PLAYER_OFFLINE)
		frame.statusText:Show();
	elseif ( UnitIsDeadOrGhost(frame.displayedUnit) ) then
		frame.statusText:SetTextColor(0.5, 0.5, 0.5)
		frame.statusText:SetText(DEAD);
		frame.statusText:Show();
	elseif ( frame.optionTable.healthText == "losthealth" or HCCdb.profile.general.statusText ) then
		local healthLost = UnitHealthMax(frame.displayedUnit) - UnitHealth(frame.displayedUnit)
		local healthDelta = (currentHeals + currentHots) - healthLost
		-- Default behavior with option turned off
		if (not HCCdb.profile.general.statusText) then
			if ( healthLost > 0 ) then
				frame.statusText:SetTextColor(0.5, 0.5, 0.5)
				frame.statusText:SetFormattedText(LOST_HEALTH, healthLost);
				frame.statusText:Show();
			else
				frame.statusText:Hide();
			end			
			return
		end

		-- New behavior with option turned on
		if (healthDelta > 0) then
			frame.statusText:SetTextColor(unpack(HCCdb.profile.general.healColor))
		else
			frame.statusText:SetTextColor(0.5, 0.5, 0.5)
		end

		if (healthLost == 0) then
			frame.statusText:Hide();
		else
			frame.statusText:SetFormattedText("%d", healthDelta);
			frame.statusText:Show();
		end
	elseif ( frame.optionTable.healthText == "health" ) then
		frame.statusText:SetTextColor(0.5, 0.5, 0.5)
		frame.statusText:SetText(UnitHealth(frame.displayedUnit));
		frame.statusText:Show();
	elseif ( (frame.optionTable.healthText == "perc") and (UnitHealthMax(frame.displayedUnit) > 0) ) then
		frame.statusText:SetTextColor(0.5, 0.5, 0.5)
		local perc = math.ceil(100 * (UnitHealth(frame.displayedUnit)/UnitHealthMax(frame.displayedUnit)));
		frame.statusText:SetFormattedText("%d%%", perc);
		frame.statusText:Show();
	else
		frame.statusText:Hide();
	end 
	--]]
end

--[[
	Function: OnInitialize
	Purpose: Initalize necessary functions, variables and set hooks, callbacks
]]--
function HealCommClassic:OnInitialize()

	--convert options from earlier than 1.2.4
	if HealCommSettings and HealCommSettings.timeframe then
		general = HCCdefault.profile.general
		general.overhealPercent = HealCommSettings.overhealPercent or general.overhealPercent
		general.timeframe = HealCommSettings.timeframe or general.timeframe
		general.showHots = HealCommSettings.showHots or general.showHots
		general.seperateHots = HealCommSettings.seperateHots or general.seperateHots
		if HealCommSettings.healColor then
			general.healColor = {HealCommSettings.healColor.red, HealCommSettings.healColor.green, HealCommSettings.healColor.blue, HealCommSettings.healColor.alpha or general.healColor[4]}
		end
		if HealCommSettings.hotColor then
			general.hotColor = {HealCommSettings.hotColor.red, HealCommSettings.hotColor.green, HealCommSettings.hotColor.blue, HealCommSettings.hotColor.alpha or general.hotColor[4]}
		end
		general.statusText = HealCommSettings.statusText or general.statusText
		HealCommSettings=nil
	end
	HCCdb = LibStub("AceDB-3.0"):New("HealCommSettings", HCCdefault)
	healColor=HCCdb.profile.general.healColor 
	hotColor=HCCdb.profile.general.hotColor
	

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
			hpBars[v.bar]:SetStatusBarColor(unpack(HCCdb.profile.general.healColor))
		end
		if not hotBars[v] then
			hotBars[v.bar] = CreateFrame("StatusBar", "IncHotBar"..unit, v.frame)
			hotBars[v.bar]:SetFrameStrata("LOW")
			hotBars[v.bar]:SetFrameLevel(hotBars[v.bar]:GetFrameLevel()-1)
			hotBars[v.bar]:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
			hotBars[v.bar]:SetMinMaxValues(0, 1)
			hotBars[v.bar]:SetValue(1)
			hotBars[v.bar]:SetStatusBarColor(unpack(HCCdb.profile.general.hotColor))
		end
	end
end


--[[
	Function: UpdateBars
	Purpose: Update the color of all heal bars
]]--
function HealCommClassic:UpdateBars()
	for unit,v in pairs(hpBars) do
		if hpBars[unit] then
			HCCdb.profile.general.healColor=healColor
			hpBars[unit]:SetStatusBarColor(unpack(HCCdb.profile.general.healColor))
		end
		if hotBars[unit] then
			HCCdb.profile.general.hotColor=hotColor
			hotBars[unit]:SetStatusBarColor(unpack(HCCdb.profile.general.hotColor))
		end
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
	if HCCdb.profile.general.showHots and not HCCdb.profile.general.seperateHots then
		healType = libCHC.ALL_HEALS
	else
		healType = libCHC.CASTED_HEALS
	end
	for i=1, select("#", ...) do
		local amount, hotAmount
		targetGUID = select(i, ...)
		amount = (libCHC:GetHealAmount(targetGUID, healType, GetTime()+ HCCdb.profile.general.timeframe) or 0) * (libCHC:GetHealModifier(targetGUID) or 1)
		if HCCdb.profile.general.seperateHots and HCCdb.profile.general.showHots then
			hotAmount= (libCHC:GetHealAmount(targetGUID, hotType, GetTime()+HCCdb.profile.general.timeframe) or 0) * (libCHC:GetHealModifier(targetGUID) or 1)
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

	if( amount and amount > 0 and (health < maxHealth or HCCdb.profile.general.overhealPercent > 0 )) and frame:IsVisible() then
		hpBars[frame]:Show()
		incWidth = frame:GetWidth() * (amount / maxHealth)
		if (healthWidth + incWidth) > (frame:GetWidth() * (1+(HCCdb.profile.general.overhealPercent/100)) ) then
			incWidth = frame:GetWidth() * (1+(HCCdb.profile.general.overhealPercent/100)) - healthWidth
		end
		hpBars[frame]:SetWidth(incWidth)
		hpBars[frame]:SetHeight(frame:GetHeight())
		hpBars[frame]:ClearAllPoints()
		hpBars[frame]:SetPoint("TOPLEFT", frame, "TOPLEFT", healthWidth, 0)
	else
		hpBars[frame]:Hide()
	end

	if( hotAmount and hotAmount > 0 and (health < maxHealth or HCCdb.profile.general.overhealPercent > 0 )) and frame:IsVisible() then
		hotBars[frame]:Show()
		local hotWidth = frame:GetWidth() * (hotAmount / maxHealth)
		if (healthWidth + hotWidth + incWidth) > (frame:GetWidth() * (1+(HCCdb.profile.general.overhealPercent/100)) ) then -- can be compressed with better math
			hotWidth = frame:GetWidth() * (1+(HCCdb.profile.general.overhealPercent/100)) - healthWidth - incWidth
			if hotWidth < 0 then
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
]]--
function HealCommClassic:CreateConfigs()
	HCCSelectedProfile = 1 --currently selected profile index for profile specific settings
	local options = {
		name = 'HealCommClassic Options',
		type = 'group',
		args = {
			desc = {
				order = 0,
				type = 'description',
				width = 'full',
				name = 'Version '..HealCommClassic.version,
			},
		},
	}
	options.args['general'] = {
		name = 'General Settings',
		type = 'group',
		args = {
			profile = {
				order = 2,
				type = 'select',
				name = 'Raid profile',
				values = function() 
							local profileTable = {'General'}
							for i=1, GetNumRaidProfiles() do
								table.insert(profileTable,GetRaidProfileName(i))
							end
						return profileTable end,
				get = function() return HCCSelectedProfile end,
				set = function(_,value) HCCSelectedProfile = value end,
			},
			hotToggle = {
				order = 4,
				type = 'toggle',
				name = 'Show HoTs',
				desc = 'Include HoTs in healing prediction',
				width = 'full',
				get = function() return HCCdb.profile.general.showHots end,
				set = function(_, value) HCCdb.profile.general.showHots = value end,
			},
			seperateHot = {
				order = 6,
				type = 'toggle',
				name = 'Seperate HoT Color',
				desc = 'Show HoTs as a seperate color',
				width = 'full',
				get = function() return HCCdb.profile.general.seperateHots end,
				set = function(_, value) HCCdb.profile.general.seperateHots = value end,
			},
			overheal = {
				order = 8,
				type = 'range',
				name = 'Extend Overheal',
				desc = 'How far heals can extend on overhealing, in percentage of the health bar size',
				min = 0,
				max = 50,
				step = 1,
				get = function() return HCCdb.profile.general.overhealPercent end,
				set = function(_,value) HCCdb.profile.general.overhealPercent = value end,
			},
			timeframe = {
				order = 10,
				type = 'range',
				name = 'Timeframe',
				desc = 'How many seconds into the future to predict heals',
				min = 0,
				max = 23,
				step = 1,
				get = function() return HCCdb.profile.general.timeframe end,
				set = function(info,value) HCCdb.profile.general.timeframe = value end,
			},
			healColor = { 
				order = 12,
				type = 'color',
				name = 'Color',
				hasAlpha = true,
				width = 'full',
				get = function() return unpack(HCCdb.profile.general.healColor) end,
				set = function (_, r, g, b, a) HCCdb.profile.general.healColor = {r,g,b,a} end,
			},
			hotColor = { 
				order = 14,
				type = 'color',
				name = 'HoT Color',
				hasAlpha = true,
				width = 'full',
				get = function() return unpack(HCCdb.profile.general.hotColor) end,
				set = function (_,r, g, b, a) HCCdb.profile.general.hotColor = {r,g,b,a} end,
			},
		},
	}
	options.args.profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(HCCdb)
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