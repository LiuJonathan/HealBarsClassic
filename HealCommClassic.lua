--[[
	Author: Aviana
	Last modified by: SideFlanker
	Notes: 
		Documentation by SideFlanker.
		If the documentation mentions a "non-functional" variable/parameter, it means it has no use in that specific function
	Table of contents, in order:
		- General settings
		- RaidPulloutButton_OnLoadHook
		- UnitFrameHealthBar_OnValueChangedHook
		- UnitFrameHealthBar_OnUpdateHook
		- CompactUnitFrame_UpdateHealthHook
		- CompactUnitFrame_UpdateMaxHealthHook
		- CompactUnitFrame_SetUnitHook
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
		- Options menu
--]]


local libCHC = LibStub("LibHealComm-4.0", true)

if not HealCommSettings then
	HealCommSettings = {
		overhealpercent = 20,
		timeframe = 6,
		showHots = true,
		seperateHots=true,
		--color needs to be a 0-1 range for setstatusbarcolor
		healColor = {red=0,green=1,blue=50/255,alpha=1},
		hotColor={red=120/255,green=210/255,blue=65/255,alpha=0.7}
	}
end

HealCommClassic = select(2, ...)
--Remember to update version number!!
--Curseforge release starting from 1.1.7
HealCommClassic.version = "1.2.0"

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

--[[
	Function: RaidPulloutButton_OnLoadHook
	Purpose: Creates heal bars for raid members upon joining a raid
	Created by: Aviana
	Last modified by: SideFlanker
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
		hpBars[getglobal(self:GetParent():GetName().."HealthBar")]:SetStatusBarColor(HealCommSettings.healColor.red, HealCommSettings.healColor.green, HealCommSettings.healColor.blue, HealCommSettings.healColor.alpha)
	end
	if not hotBars[self] then
		hotBars[getglobal(self:GetParent():GetName().."HealthBar")] = CreateFrame("StatusBar", self:GetName().."HotBarIncHeal" , self)
		hotBars[getglobal(self:GetParent():GetName().."HealthBar")]:SetFrameStrata("LOW")
		hotBars[getglobal(self:GetParent():GetName().."HealthBar")]:SetFrameLevel(hotBars[getglobal(self:GetParent():GetName().."HealthBar")]:GetFrameLevel()-1)
		hotBars[getglobal(self:GetParent():GetName().."HealthBar")]:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
		hotBars[getglobal(self:GetParent():GetName().."HealthBar")]:SetMinMaxValues(0, 1)
		hotBars[getglobal(self:GetParent():GetName().."HealthBar")]:SetValue(1)
		hotBars[getglobal(self:GetParent():GetName().."HealthBar")]:SetStatusBarColor(HealCommSettings.hotColor.red, HealCommSettings.hotColor.green, HealCommSettings.hotColor.blue, HealCommSettings.hotColor.alpha)
	end
end

--[[
	Function: UnitFrameHealthBar_OnValueChangedHook
	Purpose: Updates unit frames when a unit's max health changes
	Created by: Aviana
	Last modified by: SideFlanker
	Inputs: self
		Where self is a unit frame to update
]]--
local function UnitFrameHealthBar_OnValueChangedHook(self)
	HealCommClassic:UpdateFrame(self, self.unit, currentHeals[UnitGUID(self.unit)] or 0, currentHots[UnitGUID(self.unit)] or 0)
end


--[[
	Function: UnitFrameHealthBar_OnUpdateHook
	Purpose: Updates unit frames when a unit's health changes
	Created by: Aviana
	Last modified by: SideFlanker
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
	Created by: Aviana
	Last modified by: SideFlanker
	Inputs: self
		Where self is a unit frame to update
]]--
local function CompactUnitFrame_UpdateHealthHook(self)
	if not hpBars[self.healthBar] and not hotBars[self.healthBar] then return end
	HealCommClassic:UpdateFrame(self.healthBar, self.displayedUnit, currentHeals[UnitGUID(self.displayedUnit)] or 0, currentHots[UnitGUID(self.unit)] or 0)
end


--[[
	Function: CompactUnitFrame_UpdateMaxHealthHook
	Purpose: Update heal calculations after a max health change
	Created by: Aviana
	Last modified by: SideFlanker
	Inputs: self
		Where self is a unit frame to update
]]--
local function CompactUnitFrame_UpdateMaxHealthHook(self)
	if not hpBars[self.healthBar] and not hotBars[self.healthBar] then return end
	HealCommClassic:UpdateFrame(self.healthBar, self.displayedUnit, currentHeals[UnitGUID(self.displayedUnit)] or 0, currentHots[UnitGUID(self.unit)] or 0)
end


--[[
	Function: CompactUnitFrame_SetUnitHook
	Purpose: Create a new heal bar whenever any frame is assigned a new unit
	Created by: Aviana
	Last modified by: SideFlanker
	Inputs: self, Unit
		Where self is a parent frame to attach to
		Where Unit is the UnitID of the unit being added
	Notes: 
		Function hook happens immediately after function definition	
]]--
local function CompactUnitFrame_SetUnitHook(self, unit)
	if not hpBars[self.healthBar] then
		hpBars[self.healthBar] = CreateFrame("StatusBar", nil, self)
		hpBars[self.healthBar]:SetFrameStrata("LOW")
		hpBars[self.healthBar]:SetFrameLevel(hpBars[self.healthBar]:GetFrameLevel()-1)
		hpBars[self.healthBar]:SetStatusBarTexture("Interface\\RaidFrame\\Raid-Bar-Hp-Fill")
		hpBars[self.healthBar]:SetMinMaxValues(0, 1)
		hpBars[self.healthBar]:SetValue(1)
		hpBars[self.healthBar]:SetStatusBarColor(HealCommSettings.healColor.red, HealCommSettings.healColor.green, HealCommSettings.healColor.blue, HealCommSettings.healColor.alpha)
	end
	if not hotBars[self.healthBar] then
		hotBars[self.healthBar] = CreateFrame("StatusBar", nil, self)
		hotBars[self.healthBar]:SetFrameStrata("LOW")
		hotBars[self.healthBar]:SetFrameLevel(hotBars[self.healthBar]:GetFrameLevel()-1)
		hotBars[self.healthBar]:SetStatusBarTexture("Interface\\RaidFrame\\Raid-Bar-Hp-Fill")
		hotBars[self.healthBar]:SetMinMaxValues(0, 1)
		hotBars[self.healthBar]:SetValue(1)
		hotBars[self.healthBar]:SetStatusBarColor(HealCommSettings.healColor.red, HealCommSettings.healColor.green, HealCommSettings.healColor.blue, HealCommSettings.healColor.alpha)
	end
end
hooksecurefunc("CompactUnitFrame_SetUnit", CompactUnitFrame_SetUnitHook) -- This needs early hooking


--[[
	Function: OnInitialize
	Purpose: Initalize necessary functions and set hooks, callbacks
	Created by: Aviana
	Last modified by: SideFlanker
]]--
function HealCommClassic:OnInitialize()
	--Initalize new options for 1.1.0
	HealCommSettings.healColor = HealCommSettings.healColor or {red=0,green=1,blue=50/255,alpha=1}
	--Fix for users upgrading from 1.1.3 and earlier
	if HealCommSettings.healColor.alpha > 1 then
		HealCommSettings.healColor.alpha=1;
	end
	--Initalize new options for 1.2.0
	if HealCommSettings.seperateHots == nil then
		HealCommSettings.seperateHots=true;
	end
	HealCommSettings.hotColor = HealCommSettings.hotColor or {red=120/255,green=210/255,blue=65/255,alpha=0.7}
	
	
	healColor=HealCommSettings.healColor 
	hotColor=HealCommSettings.hotColor
	

	self:CreateBars()
	hooksecurefunc("RaidPulloutButton_OnLoad", RaidPulloutButton_OnLoadHook)
	hooksecurefunc("UnitFrameHealthBar_OnValueChanged", UnitFrameHealthBar_OnValueChangedHook)
	hooksecurefunc("CompactUnitFrame_UpdateHealth", CompactUnitFrame_UpdateHealthHook)
	hooksecurefunc("CompactUnitFrame_UpdateMaxHealth", CompactUnitFrame_UpdateMaxHealthHook)
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
	Created by: Aviana
	Last modified by: SideFlanker
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
			hpBars[v.bar]:SetStatusBarColor(HealCommSettings.healColor.red, HealCommSettings.healColor.green, HealCommSettings.healColor.blue, HealCommSettings.healColor.alpha)
		end
		if not hotBars[v] then
			hotBars[v.bar] = CreateFrame("StatusBar", "IncHotBar"..unit, v.frame)
			hotBars[v.bar]:SetFrameStrata("LOW")
			hotBars[v.bar]:SetFrameLevel(hotBars[v.bar]:GetFrameLevel()-1)
			hotBars[v.bar]:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
			hotBars[v.bar]:SetMinMaxValues(0, 1)
			hotBars[v.bar]:SetValue(1)
			hotBars[v.bar]:SetStatusBarColor(HealCommSettings.hotColor.red, HealCommSettings.hotColor.green, HealCommSettings.hotColor.blue, HealCommSettings.hotColor.alpha)
		end
	end
end


--[[
	Function: UpdateBars
	Purpose: Update the color of all heal bars
	Created by: SideFlanker
	Last modified by: SideFlanker
]]--
function HealCommClassic:UpdateBars()
	for unit,v in pairs(hpBars) do
		if hpBars[unit] then
			HealCommSettings.healColor=healColor
			hpBars[unit]:SetStatusBarColor(HealCommSettings.healColor.red, HealCommSettings.healColor.green, HealCommSettings.healColor.blue, HealCommSettings.healColor.alpha)
		end
		if hotBars[unit] then
			HealCommSettings.hotColor=hotColor
			hotBars[unit]:SetStatusBarColor(HealCommSettings.hotColor.red, HealCommSettings.hotColor.green, HealCommSettings.hotColor.blue, HealCommSettings.hotColor.alpha)
		end
	end
end


--[[`
	Function: UNIT_PET
	Purpose: Update pet heal bars
	Created by: Aviana
	Last modified by: SideFlanker
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
	Created by: Aviana
	Last modified by: SideFlanker
]]--
function HealCommClassic:PLAYER_TARGET_CHANGED()
	self:UpdateFrame(frames["target"].bar, "target", currentHeals[UnitGUID("target")] or 0, currentHots[UnitGUID("target")] or 0)
end


--[[
	Function: PLAYER_ROLES_ASSIGNED
	Purpose: Update party and raid heal bars after a raid role assignment
	Created by: Aviana
	Last modified by: SideFlanker
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
						self:UpdateFrame(unitframe.healthBar, unitframe.displayedUnit, currentHeals[UnitGUID(unitframe.displayedUnit)] or 0, currentHots[UnitGUID(unitframe.unit)] or 0)
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
	Created by: Aviana
	Last modified by: Aviana
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
	Created by: Aviana
	Last modified by: Aviana
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
	Created by: Aviana
	Last modified by: Aviana
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
	Created by: Aviana
	Last modified by: Aviana
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
	Created by: Aviana
	Last modified by: SideFlanker
	Inputs: args
			A table of GUIDs to update
--]]
function HealCommClassic:UpdateIncoming(...)
	local amount, targetGUID, num, frame, unitframe, healType
	local hotType=libCHC.HOT_HEALS
	if HealCommSettings.showHots and not HealCommSettings.seperateHots then
		healType = libCHC.ALL_HEALS
	else
		healType = libCHC.CASTED_HEALS
	end
	for i=1, select("#", ...) do
		targetGUID = select(i, ...)
		amount = (libCHC:GetHealAmount(targetGUID, healType, GetTime()+ HealCommSettings.timeframe) or 0) * (libCHC:GetHealModifier(targetGUID) or 1)
		if HealCommSettings.seperateHots and HealCommSettings.showHots then
			hotAmount= (libCHC:GetHealAmount(targetGUID, hotType, GetTime()+HealCommSettings.timeframe) or 0) * (libCHC:GetHealModifier(targetGUID) or 1)
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
	Created by: Aviana
	Last modified by: SideFlanker
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
	if( amount and amount > 0 and (health < maxHealth or HealCommSettings.overhealpercent > 0 )) and frame:IsVisible() then
		hpBars[frame]:Show()
		incWidth = frame:GetWidth() * (amount / maxHealth)
		if (healthWidth + incWidth) > (frame:GetWidth() * (1+(HealCommSettings.overhealpercent/100)) ) then
			incWidth = frame:GetWidth() * (1+(HealCommSettings.overhealpercent/100)) - healthWidth
		end
		hpBars[frame]:SetWidth(incWidth)
		hpBars[frame]:SetHeight(frame:GetHeight())
		hpBars[frame]:ClearAllPoints()
		hpBars[frame]:SetPoint("TOPLEFT", frame, "TOPLEFT", healthWidth, 0)
	else
		hpBars[frame]:Hide()
	end

	if( hotAmount and hotAmount > 0 and (health < maxHealth or HealCommSettings.overhealpercent > 0 )) and frame:IsVisible() then
		hotBars[frame]:Show()
		local hotWidth = frame:GetWidth() * (hotAmount / maxHealth)
		if (healthWidth + hotWidth + incWidth) > (frame:GetWidth() * (1+(HealCommSettings.overhealpercent/100)) ) then -- can be compressed with better math
			hotWidth = frame:GetWidth() * (1+(HealCommSettings.overhealpercent/100)) - healthWidth - incWidth
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
	Code section: Config: Main Options Tab
	Purpose: Add and attach options page
	Created by: Aviana
	Last modified by: SideFlanker
]]--

local options = CreateFrame("Frame", nil, InterfaceOptionsFramePanelContainer)
options.name = "HealCommClassic"
options:Hide()
options:SetScript("OnShow", function(self)

	
	--[[
		Function: BoxConstructor
		Purpose: Template for checkboxes
		Created by: Aviana
		Last modified by: Aviana
		Inputs: Name, Description, Function(frame_object, value)
				Where frame_object is a frame to attach to
				Where value is a variable to send checkbox value updates to
		Return: A new checkbox object
	--]]
	
	local function BoxConstructor(name, desc, clickFunc)
		local box = CreateFrame("CheckButton", "HealCommClassicOptionsBox" .. name, self, "InterfaceOptionsCheckButtonTemplate")
		box:SetScript("OnClick", function(thisBox)
			clickFunc(thisBox, thisBox:GetChecked())
		end)
		box.label = _G[box:GetName() .. "Text"]
		box.label:SetText(name)
		box.tooltipText = name
		box.tooltipRequirement = desc
		return box
	end
	
	
	--[[
		Function: SliderConstructor
		Purpose: Template for sliders
		Created by: Aviana
		Last modified by: SideFlanker
		Inputs: Name, Description, Function(frame_object, value)
				Where frame_object is a frame to attach to
				Where value is a variable to send slider value updates to
				Where percent is a boolean indicating whether or not show the value of the slider as 0.xx 
		Return: A new slider object
		Notes: 
			Blizzard sliders do not like having non-integer steps
	--]]
	
	local function SliderConstructor(name, desc, valueFunc, percent)
		local slider = CreateFrame("Slider", "HealCommClassicOptionsSlider" .. name, self, "OptionsSliderTemplate")
		if percent == false then
			slider:SetScript("OnValueChanged", function(thisSlider)
				valueFunc(thisSlider, thisSlider:GetValue())
				thisSlider.High:SetText(thisSlider:GetValue())
			end)
		else
			slider:SetScript("OnValueChanged", function(thisSlider)
				valueFunc(thisSlider, thisSlider:GetValue())
				thisSlider.High:SetText(thisSlider:GetValue()/100)
			end)
		end
		slider.label = _G[slider:GetName() .. "Text"]
		slider.label:SetText(name)
		slider.Low:Hide()
		slider.High:ClearAllPoints()
		slider.High:SetPoint("TOP", slider, "BOTTOM", 0, 0)
		slider.tooltipText = name
		slider.tooltipRequirement = desc
		return slider
	end

	-- Options and text to be added

	local header = self:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	header:SetPoint("TOPLEFT", 16, -16)
	header:SetText("HealCommClassic")

	local version = self:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	version:SetText("Version: "..HealCommClassic.version)
	version:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -16)

	local credit = self:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	credit:SetText("Originally created by Aviana")
	credit:SetPoint("TOPLEFT", version, "BOTTOMLEFT", 0, -16)

	local showHots = BoxConstructor("Show HoTs", "Show HoTs in the healing prediction", function(self, value) HealCommSettings.showHots = value end)
	showHots:SetChecked(HealCommSettings.showHots)
	showHots:SetPoint("TOPLEFT", credit, "BOTTOMLEFT", 0, -16)
	
	local seperateHots = BoxConstructor("Seperate HoT Color", "Show HoTs as a seperate color", function(self,value) HealCommSettings.seperateHots=value end)
	seperateHots:SetChecked(HealCommSettings.seperateHots)
	seperateHots:SetPoint("TOPLEFT", showHots,"BOTTOMLEFT",0,-8)

	local overhealSlider = SliderConstructor("Extend Overheal", "How many percent of the frame to go over it when showing heals", function(self, value) HealCommSettings.overhealpercent = value end, false)
	overhealSlider:SetMinMaxValues(0, 50)
	overhealSlider:SetValueStep(1)
	overhealSlider:SetObeyStepOnDrag(true)
	overhealSlider:SetValue(HealCommSettings.overhealpercent)
	overhealSlider:SetPoint("TOPLEFT", seperateHots, "BOTTOMLEFT", 0, -16)

	local timeframeSlider = SliderConstructor("Timeframe", "How many seconds to predict into the future", function(self, value) HealCommSettings.timeframe = value end, false)
	timeframeSlider:SetMinMaxValues(3, 22)
	timeframeSlider:SetValueStep(1)
	timeframeSlider:SetObeyStepOnDrag(true)
	timeframeSlider:SetValue(HealCommSettings.timeframe)
	timeframeSlider:SetPoint("TOPLEFT", overhealSlider, "BOTTOMLEFT", 0, -26)
	
	local colorLabel = self:CreateFontString(nil, "ARTWORK", "GameFontHighlightLarge")
	colorLabel:SetText("Heal Color:")
	colorLabel:SetPoint("TOPLEFT", timeframeSlider, "BOTTOMLEFT", 0, -36)
	
	local redSlider = SliderConstructor("Red", "What color to make the heal bars", function(self, value) healColor.red = value/255 end, false)
	redSlider:SetMinMaxValues(0, 255)
	redSlider:SetValueStep(1)
	redSlider:SetObeyStepOnDrag(true)
	redSlider:SetValue(healColor.red*255)
	redSlider:SetPoint("TOPLEFT", colorLabel, "BOTTOMLEFT", 0, -22)
	
	local greenSlider = SliderConstructor("Green", "What color to make the heal bars", function(self, value) healColor.green = value/255 end, false)
	greenSlider:SetMinMaxValues(0, 255)
	greenSlider:SetValueStep(1)
	greenSlider:SetObeyStepOnDrag(true)
	greenSlider:SetValue(healColor.green*255)
	greenSlider:SetPoint("TOPLEFT", redSlider, "BOTTOMLEFT", 0, -26)
	
	local blueSlider = SliderConstructor("Blue", "What color to make the heal bars", function(self, value) healColor.blue = value/255 end, false)
	blueSlider:SetMinMaxValues(0, 255)
	blueSlider:SetValueStep(1)
	blueSlider:SetObeyStepOnDrag(true)
	blueSlider:SetValue(healColor.blue*255)
	blueSlider:SetPoint("TOPLEFT", greenSlider, "BOTTOMLEFT", 0, -26)
	
	local alphaSlider = SliderConstructor("Alpha", "Set transparency of heal bars", function(self, value) healColor.alpha = value/100 end, true)
	alphaSlider:SetMinMaxValues(0, 100)
	alphaSlider:SetValueStep(1)
	alphaSlider:SetObeyStepOnDrag(true)
	alphaSlider:SetValue(healColor.alpha*100)
	alphaSlider:SetPoint("TOPLEFT", blueSlider, "BOTTOMLEFT", 0, -26)
	
	local updateColors = CreateFrame("Button", "updateHealColor", options, "UIPanelButtonTemplate")
	updateColors:SetSize(80 ,22) 
	updateColors:SetText("Apply colors")
	updateColors:SetPoint("TOPLEFT", alphaSlider, "BOTTOMLEFT", 0, -22)
	updateColors:SetScript("OnClick",function()HealCommClassic:UpdateBars() end)
	
	local redHotSlider = SliderConstructor("Red - HoT", "What color to make the heal bars", function(self, value) hotColor.red = value/255 end, false)
	redHotSlider:SetMinMaxValues(0, 255)
	redHotSlider:SetValueStep(1)
	redHotSlider:SetObeyStepOnDrag(true)
	redHotSlider:SetValue(hotColor.red*255)
	redHotSlider:SetPoint("TOPLEFT", colorLabel, "BOTTOMLEFT", 150, -22)
	
	local greenHotSlider = SliderConstructor("Green - HoT", "What color to make the heal bars", function(self, value) hotColor.green = value/255 end, false)
	greenHotSlider:SetMinMaxValues(0, 255)
	greenHotSlider:SetValueStep(1)
	greenHotSlider:SetObeyStepOnDrag(true)
	greenHotSlider:SetValue(hotColor.green*255)
	greenHotSlider:SetPoint("TOPLEFT", redHotSlider, "BOTTOMLEFT", 0, -26)
	
	local blueHotSlider = SliderConstructor("Blue - HoT", "What color to make the heal bars", function(self, value) hotColor.blue = value/255 end, false)
	blueHotSlider:SetMinMaxValues(0, 255)
	blueHotSlider:SetValueStep(1)
	blueHotSlider:SetObeyStepOnDrag(true)
	blueHotSlider:SetValue(hotColor.blue*255)
	blueHotSlider:SetPoint("TOPLEFT", greenHotSlider, "BOTTOMLEFT", 0, -26)
	
	local alphaHotSlider = SliderConstructor("Alpha - HoT", "Set transparency of heal bars", function(self, value) hotColor.alpha = value/100 end, true)
	alphaHotSlider:SetMinMaxValues(0, 100)
	alphaHotSlider:SetValueStep(1)
	alphaHotSlider:SetObeyStepOnDrag(true)
	alphaHotSlider:SetValue(hotColor.alpha*100)
	alphaHotSlider:SetPoint("TOPLEFT", blueHotSlider, "BOTTOMLEFT", 0, -26)


	self:SetScript("OnShow", nil)
end)
InterfaceOptions_AddCategory(options)


--[[End of "Config: Main Options Tab" code section]]--




--[[
	Code section: Event Registration
	Purpose: Set event to initalize HealCommClassic on first login and 
			update targets after target/pet/raid role change
	Created by: Aviana
	Last modified by: Aviana
--]]
local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_TARGET_CHANGED")
frame:RegisterEvent("PLAYER_ROLES_ASSIGNED")
frame:RegisterEvent("UNIT_PET")
frame:SetScript("OnEvent", function(self, event, ...)
	if( event == "PLAYER_LOGIN" ) then
		HealCommClassic:OnInitialize()
		self:UnregisterEvent("PLAYER_LOGIN")
	else
		HealCommClassic[event](HealCommClassic, ...)
	end
end)


--[[ End of "Event Registration" code section ]]--