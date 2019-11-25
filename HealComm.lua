--[[
	Author: Aviana
	Last modified by: SideFlanker
	Notes: 
		Documentation by SideFlanker.
		If the documentation mentions a "non-functional" variable/parameter, it means it has no use in that specific function
		At some point, the ambiguous "self" parameter in some functions should be renamed to "frame"
--]]


local libCHC = LibStub("LibHealComm-4.0", true)

if not HealCommSettings then
	HealCommSettings = {
		overhealpercent = 20,
		timeframe = 4,
		showHots = true,
		healColor = {red=0,green=1,blue=0,alpha=1}
	}
end

HealComm = select(2, ...)
HealComm.version = "1.1.5"

local hpBars = {}

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

--[[
	Function: RaidPulloutButton_OnLoadHook
	Purpose:(???)
	Created by: Aviana
	Last modified by: SideFlanker
	Inputs: Frame
		Where Frame is a unit frame to update
	Notes: 
		Possibly removable without any functionality impact
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
end

--[[
	Function: UnitFrameHealthBar_OnValueChangedHook
	Purpose: Updates unit frames when a unit's max health changes
	Created by: Aviana
	Last modified by: Aviana
	Inputs: Frame
		Where Frame is a unit frame to update
]]--
local function UnitFrameHealthBar_OnValueChangedHook(self)
	HealComm:UpdateFrame(self, self.unit, currentHeals[UnitGUID(self.unit)] or 0)
end


--[[
	Function: UnitFrameHealthBar_OnUpdateHook
	Purpose: Updates unit frames when a unit's health changes
	Created by: Aviana
	Last modified by: Aviana
	Inputs: Frame
		Where Frame is a unit frame to update
	Notes: 
		Function hook happens immediately after function definition	
]]--
local function UnitFrameHealthBar_OnUpdateHook(self)
	if self.unit ~= "player" then return end
	HealComm:UpdateFrame(self, self.unit, currentHeals[UnitGUID(self.unit)] or 0)
end
hooksecurefunc("UnitFrameHealthBar_OnUpdate", UnitFrameHealthBar_OnUpdateHook) -- This needs early hooking


--[[
	Function: CompactUnitFrame_UpdateHealthHook
	Purpose: Update raid heal bars when a unit's health changes
	Created by: Aviana
	Last modified by: Aviana
	Inputs: Frame
		Where Frame is a unit frame to update
]]--
local function CompactUnitFrame_UpdateHealthHook(self)
	if not hpBars[self.healthBar] then return end
	HealComm:UpdateFrame(self.healthBar, self.displayedUnit, currentHeals[UnitGUID(self.displayedUnit)] or 0)
end


--[[
	Function: CompactUnitFrame_UpdateMaxHealthHook
	Purpose: Update heal calculations after a max health change
	Created by: Aviana
	Last modified by: Aviana
	Inputs: Frame
		Where Frame is a unit frame to update
]]--
local function CompactUnitFrame_UpdateMaxHealthHook(self)
	if not hpBars[self.healthBar] then return end
	HealComm:UpdateFrame(self.healthBar, self.displayedUnit, currentHeals[UnitGUID(self.displayedUnit)] or 0)
end


--[[
	Function: CompactUnitFrame_SetUnitHook
	Purpose: Create new heal bar when a new unit joins the raid (?)
	Created by: Aviana
	Last modified by: SideFlanker
	Inputs: Frame, Unit
		Where Frame is a parent frame to attach to
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
end
hooksecurefunc("CompactUnitFrame_SetUnit", CompactUnitFrame_SetUnitHook) -- This needs early hooking


--[[
	Function: OnInitialize
	Purpose: Initalize necessary functions and set hooks, callbacks
	Created by: Aviana
	Last modified by: SideFlanker
]]--
function HealComm:OnInitialize()
	--Initalize new options for 1.1.0
	HealCommSettings.healColor = HealCommSettings.healColor or {red=0,green=1,blue=0,alpha=1}
	--Fix for users upgrading from 1.1.3 and earlier
	if HealCommSettings.healColor.alpha > 1 then
		HealCommSettings.healColor.alpha=1;
	end

	self:CreateBars()
	hooksecurefunc("RaidPulloutButton_OnLoad", RaidPulloutButton_OnLoadHook)
	hooksecurefunc("UnitFrameHealthBar_OnValueChanged", UnitFrameHealthBar_OnValueChangedHook)
	hooksecurefunc("CompactUnitFrame_UpdateHealth", CompactUnitFrame_UpdateHealthHook)
	hooksecurefunc("CompactUnitFrame_UpdateMaxHealth", CompactUnitFrame_UpdateMaxHealthHook)
	libCHC.RegisterCallback(HealComm, "HealComm_HealStarted", "HealComm_HealUpdated")
	libCHC.RegisterCallback(HealComm, "HealComm_HealStopped")
	libCHC.RegisterCallback(HealComm, "HealComm_HealDelayed", "HealComm_HealUpdated")
	libCHC.RegisterCallback(HealComm, "HealComm_HealUpdated")
	libCHC.RegisterCallback(HealComm, "HealComm_ModifierChanged")
	libCHC.RegisterCallback(HealComm, "HealComm_GUIDDisappeared")
end


--[[
	Function: CreateBars
	Purpose: Create and initalize heal bars for all frames
	Created by: Aviana
	Last modified by: SideFlanker
]]--
function HealComm:CreateBars()
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
	end
end


--[[
	Function: UpdateBars
	Purpose: Update the color of all heal bars
	Created by: SideFlanker
	Last modified by: SideFlanker
]]--
function HealComm:UpdateBars()
	for unit,v in pairs(hpBars) do
		if hpBars[unit] then
			hpBars[unit]:SetStatusBarColor(HealCommSettings.healColor.red, HealCommSettings.healColor.green, HealCommSettings.healColor.blue, HealCommSettings.healColor.alpha)
		end
	end
end


--[[
	Function: UNIT_PET
	Purpose: Update pet heal bars
	Created by: Aviana
	Last modified by: Aviana
	Inputs: Unit
		Where Unit is the UnitID of the pet being updated
]]--
function HealComm:UNIT_PET(unit)
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
	if hpBars[frames[petunit].bar] then
		self:UpdateFrame(frames[petunit].bar, petunit, currentHeals[UnitGUID("pet")] or 0)
	end
end

function HealComm:PLAYER_TARGET_CHANGED()
	self:UpdateFrame(frames["target"].bar, "target", currentHeals[UnitGUID("target")] or 0)
end


--[[
	Function: PLAYER_ROLES_ASSIGNED
	Purpose: Update party and raid heal bars after a raid role assignment
	Created by: Aviana
	Last modified by: Aviana
]]--
function HealComm:PLAYER_ROLES_ASSIGNED() 
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
				self:UpdateFrame(unitframe.healthBar, unitframe.displayedUnit, amount)
			end
			num = num + 1
			unitframe = _G["CompactPartyFrameMember"..num]
		end
		unitframe = _G["CompactRaidFrame1"]
		num = 1
		while unitframe do
			if unitframe.displayedUnit and UnitExists(unitframe.displayedUnit) then
				self:UpdateFrame(unitframe.healthBar, unitframe.displayedUnit, amount)
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
					self:UpdateFrame(getglobal(unitframe:GetName().."HealthBar"), unitframe.unit, currentHeals[UnitGUID(unitframe.unit)] or 0)
				end
			end
		end
		for i=1, 8 do
			local grpHeader = "CompactRaidGroup"..i
			if _G[grpHeader] then
				for k=1, 5 do
					unitframe = _G[grpHeader.."Member"..k]
					if unitframe and unitframe.displayedUnit and UnitExists(unitframe.displayedUnit) then
						self:UpdateFrame(unitframe.healthBar, unitframe.displayedUnit, currentHeals[UnitGUID(unitframe.displayedUnit)] or 0)
					end
				end
			end
		end
	end
end


--[[
	Function: HealComm_HealUpdated
	Purpose: HealCommLib callback handler
			Redirect callback
	Created by: Aviana
	Last modified by: Aviana
	Inputs: event, casterGUID, spellID, healType, interrupted, args
			Where event, casterGUID, spellID, etc. are non-functional
			Where args is a table of GUIDs to update
--]]
function HealComm:HealComm_HealUpdated(event, casterGUID, spellID, healType, endTime, ...)
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
function HealComm:HealComm_HealStopped(event, casterGUID, spellID, healType, interrupted, ...)
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
function HealComm:HealComm_ModifierChanged(event, guid)
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
function HealComm:HealComm_GUIDDisappeared(event, guid)
	self:UpdateIncoming(guid)
end


--[[
	Function: UpdateIncoming
	Purpose: HealCommLib callback handler. Updates heal bars
	Created by: Aviana
	Last modified by: Aviana
	Inputs: args
			A table of GUIDs to update
--]]
function HealComm:UpdateIncoming(...)
	local amount, targetGUID, num, frame, unitframe, healType
	if HealCommSettings.showHots then
		healType = libCHC.ALL_HEALS
	else
		healType = libCHC.CASTED_HEALS
	end
	for i=1, select("#", ...) do
		targetGUID = select(i, ...)
		amount = (libCHC:GetHealAmount(targetGUID, healType, GetTime()+ HealCommSettings.timeframe) or 0) * (libCHC:GetHealModifier(targetGUID) or 1)
		currentHeals[targetGUID] = amount > 0 and amount
		if UnitGUID("target") == targetGUID then
			self:UpdateFrame(frames["target"].bar, "target", amount)
		end
		if partyGUIDs[targetGUID] then
			self:UpdateFrame(frames[partyGUIDs[targetGUID]].bar, partyGUIDs[targetGUID], amount)
		end
		if UnitInParty("player") then
			unitframe = _G["CompactPartyFrameMember1"]
			num = 1
			while unitframe do
				if unitframe.displayedUnit and UnitExists(unitframe.displayedUnit) and UnitGUID(unitframe.displayedUnit) == targetGUID then
					self:UpdateFrame(unitframe.healthBar, unitframe.displayedUnit, amount)
				end
				num = num + 1
				unitframe = _G["CompactPartyFrameMember"..num]
			end
			unitframe = _G["CompactRaidFrame1"]
			num = 1
			while unitframe do
				if unitframe.displayedUnit and UnitExists(unitframe.displayedUnit) and UnitGUID(unitframe.displayedUnit) == targetGUID then
					self:UpdateFrame(unitframe.healthBar, unitframe.displayedUnit, amount)
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
						self:UpdateFrame(getglobal(unitframe:GetName().."HealthBar"), unitframe.unit, amount)
					end
				end
			end
			for j=1, 8 do
				local grpHeader = "CompactRaidGroup"..j
				if _G[grpHeader] then
					for k=1, 5 do
						unitframe = _G[grpHeader.."Member"..k]
						if unitframe and unitframe.displayedUnit and UnitExists(unitframe.displayedUnit) and UnitGUID(unitframe.displayedUnit) == targetGUID then
							self:UpdateFrame(unitframe.healthBar, unitframe.displayedUnit, currentHeals[UnitGUID(unitframe.displayedUnit)] or 0)
						end
					end
				end
			end
		end
	end
end


--[[
	Function: UpdateFrame
	Purpose: HealCommLib callback handler. Updates heal bars
	Created by: Aviana
	Last modified by: Aviana
	Inputs: Frame, Unit, HealAmount
		Where Frame is the heal bar frame to update
		Where Unit is the UnitID that the heal bar references
		Where HealAmount is the amount of incoming healing
--]]
function HealComm:UpdateFrame(frame, unit, amount)
	local health, maxHealth = UnitHealth(unit), UnitHealthMax(unit)
	if( amount and amount > 0 and (health < maxHealth or HealCommSettings.overhealpercent > 0 )) and frame:IsVisible() then
		hpBars[frame]:Show()
		local healthWidth = frame:GetWidth() * (health / maxHealth)
		local incWidth = frame:GetWidth() * (amount / maxHealth)
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
end


--[[
	Code section: Config: Main Options Tab
	Purpose: Add and attach options page
	Created by: Aviana
	Last modified by: SideFlanker
]]--

local options = CreateFrame("Frame", nil, InterfaceOptionsFramePanelContainer)
options.name = "HealComm"
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
		local box = CreateFrame("CheckButton", "HealCommOptionsBox" .. name, self, "InterfaceOptionsCheckButtonTemplate")
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
		local slider = CreateFrame("Slider", "HealCommOptionsSlider" .. name, self, "OptionsSliderTemplate")
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
	header:SetText("HealComm")

	local version = self:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	version:SetText("Version: "..HealComm.version)
	version:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -16)

	local credit = self:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	credit:SetText("Originally created by Aviana")
	credit:SetPoint("TOPLEFT", version, "BOTTOMLEFT", 0, -16)

	local showHots = BoxConstructor("Show Hots", "Show hots in the healing prediction", function(self, value) HealCommSettings.showHots = value end)
	showHots:SetChecked(HealCommSettings.showHots)
	showHots:SetPoint("TOPLEFT", credit, "BOTTOMLEFT", 0, -16)

	local overhealSlider = SliderConstructor("Extend Overheal", "How many percent of the frame to go over it when showing heals", function(self, value) HealCommSettings.overhealpercent = value end, false)
	overhealSlider:SetMinMaxValues(0, 30)
	overhealSlider:SetValueStep(1)
	overhealSlider:SetObeyStepOnDrag(true)
	overhealSlider:SetValue(HealCommSettings.overhealpercent)
	overhealSlider:SetPoint("TOPLEFT", showHots, "BOTTOMLEFT", 0, -16)

	local timeframeSlider = SliderConstructor("Timeframe", "How many seconds to predict into the future", function(self, value) HealCommSettings.timeframe = value end, false)
	timeframeSlider:SetMinMaxValues(3, 10)
	timeframeSlider:SetValueStep(1)
	timeframeSlider:SetObeyStepOnDrag(true)
	timeframeSlider:SetValue(HealCommSettings.timeframe)
	timeframeSlider:SetPoint("TOPLEFT", overhealSlider, "BOTTOMLEFT", 0, -26)
	
	local colorLabel = self:CreateFontString(nil, "ARTWORK", "GameFontHighlightLarge")
	colorLabel:SetText("Heal Color:")
	colorLabel:SetPoint("TOPLEFT", timeframeSlider, "BOTTOMLEFT", 0, -36)
	
	local redSlider = SliderConstructor("Red", "What color to make the heal bars", function(self, value) HealCommSettings.healColor.red = value/255 end, false)
	redSlider:SetMinMaxValues(0, 255)
	redSlider:SetValueStep(1)
	redSlider:SetObeyStepOnDrag(true)
	redSlider:SetValue(HealCommSettings.healColor.red*255)
	redSlider:SetPoint("TOPLEFT", colorLabel, "BOTTOMLEFT", 0, -22)
	
	local greenSlider = SliderConstructor("Green", "What color to make the heal bars", function(self, value) HealCommSettings.healColor.green = value/255 end, false)
	greenSlider:SetMinMaxValues(0, 255)
	greenSlider:SetValueStep(1)
	greenSlider:SetObeyStepOnDrag(true)
	greenSlider:SetValue(HealCommSettings.healColor.green*255)
	greenSlider:SetPoint("TOPLEFT", redSlider, "BOTTOMLEFT", 0, -26)
	
	local blueSlider = SliderConstructor("Blue", "What color to make the heal bars", function(self, value) HealCommSettings.healColor.blue = value/255 end, false)
	blueSlider:SetMinMaxValues(0, 255)
	blueSlider:SetValueStep(1)
	blueSlider:SetObeyStepOnDrag(true)
	blueSlider:SetValue(HealCommSettings.healColor.blue*255)
	blueSlider:SetPoint("TOPLEFT", greenSlider, "BOTTOMLEFT", 0, -26)
	
	local alphaSlider = SliderConstructor("Alpha", "Set transparency of heal bars", function(self, value) HealCommSettings.healColor.alpha = value/100 end, true)
	alphaSlider:SetMinMaxValues(0, 100)
	alphaSlider:SetValueStep(1)
	alphaSlider:SetObeyStepOnDrag(true)
	alphaSlider:SetValue(HealCommSettings.healColor.alpha*100)
	alphaSlider:SetPoint("TOPLEFT", blueSlider, "BOTTOMLEFT", 0, -26)
	
	local updateColors = CreateFrame("Button", "updateHealColor", options, "UIPanelButtonTemplate")
	updateColors:SetSize(80 ,22) 
	updateColors:SetText("Apply color")
	updateColors:SetPoint("TOPLEFT", alphaSlider, "BOTTOMLEFT", 0, -22)
	updateColors:SetScript("OnClick",function()HealComm:UpdateBars() end)

	self:SetScript("OnShow", nil)
end)
InterfaceOptions_AddCategory(options)


--[[End of "Config: Main Options Tab" code section]]--




--[[
	Code section: Event Registration
	Purpose: Set event to initalize HealComm on first login and 
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
		HealComm:OnInitialize()
		self:UnregisterEvent("PLAYER_LOGIN")
	else
		HealComm[event](HealComm, ...)
	end
end)


--[[ End of "Event Registration" code section ]]--