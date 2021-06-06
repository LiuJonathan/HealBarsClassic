--[[
	Function: CreateConfigs
	Purpose: Create and attach options page
	Notes: 
		For convenience, order is incremented in steps of two so new options can be squeezed between them.
]]--
local addon = HealBarsClassic
function addon:CreateConfigs()
	local options = {
		name = 'HealBarsClassic',
		type = 'group',
		args = {
			button0 = {
				order = 10,
				type = 'execute',
				name = 'Reset to defaults',
				confirm = true,
				func = function() HBCdb:ResetDB() end
			},
			desc2 = {
				order = 20,
				type = 'description',
				width = 'full',
				name = 'HealBarsClassic provides HealComm for Blizzard\'s default unit frames.'
			},
		},
	}
	options.args['basicFeatures'] = {
		name = 'Basic Features',
		type = 'group',
		order = 10,
		args = {
			header0 = {
				order = 20,
				type = 'header',
				name = 'General Settings',
			},
			overheal = {
				order = 30,
				type = 'range',
				name = 'Extend Overheals',
				desc = 'How far to extend overheals, in percentage of the health bar size',
				min = 0,
				max = 0.5,
				step = 0.01,
				isPercent = true,
				get = function() return HBCdb.global.overhealPercent / 100 end,
				set = function(_,value) HBCdb.global.overhealPercent = value * 100 end,
			},
			spacer0 = {
				order = 34,
				type = 'description',
				name = '\n',
			},
			healTimeframe = {
				order = 35,
				type = 'range',
				name = 'Heal Timeframe',
				desc = 'How many seconds into the future to predict Heals',
				min = 3,
				max = 23,
				step = 1,
				get = function() return HBCdb.global.healTimeframe end,
				set = function(info,value) HBCdb.global.healTimeframe = value end,
			},
			spacer1 = {
				order = 40,
				type = 'description',
				name = '\n',
			},
			header1 = {
				order = 50,
				type = 'header',
				name = 'Heal Over Times'
			},
			hotToggle = {
				order = 60,
				type = 'toggle',
				name = 'Show HoTs',
				desc = 'Include HoTs in healing prediction',
				width = 'full',
				get = function() return HBCdb.global.showHots end,
				set = function(_, value) HBCdb.global.showHots = value end,
			},
			timeframe = {
				order = 70,
				type = 'range',
				name = 'HoT Timeframe',
				desc = 'How many seconds into the future to predict HoTs',
				min = 3,
				max = 23,
				step = 1,
				get = function() return HBCdb.global.timeframe end,
				set = function(info,value) HBCdb.global.timeframe = value end,
			},
			spacer2 = {
				order = 80,
				type = 'description',
				name = '\n',
			},
			header2 = {
				order = 90,
				type = 'header',
				name = 'Color Options',
			},
			desc1 = {
				order = 100,
				type = 'description',
				name = 'Note: The plus and minus slider sets transparency.'
			},
			healColor = { 
				order = 110,
				type = 'color',
				name = 'Heal Color',
				hasAlpha = true,
				width = 'full',
				get = function() return unpack(HBCdb.global.healColor) end,
				set = function (_, r, g, b, a) HBCdb.global.healColor = {r,g,b,a}; self:UpdateColors() end,
			},
			spacer3 = {
				order = 120,
				type = 'description',
				name = '\n',
			},
			seperateHot = {
				order = 130,
				type = 'toggle',
				name = 'Seperate HoT Color',
				desc = 'Color HoTs as a seperate color.\n\'Show HoTs\' must be enabled.',
				width = 'full',
				get = function() return HBCdb.global.seperateHots end,
				set = function(_, value) HBCdb.global.seperateHots = value end,
			},
			hotColor = { 
				order = 140,
				type = 'color',
				name = 'HoT Color',
				hasAlpha = true,
				width = 'full',
				get = function() return unpack(HBCdb.global.hotColor) end,
				set = function (_,r, g, b, a) HBCdb.global.hotColor = {r,g,b,a}; self:UpdateColors() end,
			},
		},
	}
	
	options.args['advancedFeatures'] = {
		name = 'Advanced Features',
		type = 'group',
		order = 15,
		args = {
			header0 = {
				order = 10,
				type = 'header',
				name = 'Advanced Settings',
			},
			spacer = {
				order = 30,
				type = 'description',
				name = 'Check back in later versions for new features!',
			}
		}
	}
	options.args['statusText'] = {
		name = 'Status Text',
		type = 'group',
		order = 20,
		args = {
			header0 = {
				order = 10,
				type = 'header',
				name = 'General Settings',
			},
			feignToggle = {
				order = 20,
				type = 'toggle',
				name = 'Feign death indicator',
				descStyle = 'inline',
				desc = 'Shows the text \'FEIGN\' when a hunter feigns death.',
				width = 'full',
				get = function() return HBCdb.global.feignIndicator end,
				set = function(_, value) HBCdb.global.feignIndicator = value end,
			},
			spacer = {
				order = 30,
				type = 'description',
				name = '\n',
			},
			desc1 = {
				order = 40,
				type = 'header',
				name = 'Health Text Replacers',
			},
			desc2 = {
				order = 50,
				type = 'description',
				name = 'These options supplement the functionality of \'Display Health Text\' in Blizzard\'s Raid Profiles.\n\n',
			},
			predictiveHealthLostToggle = {
				order = 60,
				type = 'toggle',
				name = 'Predictive \'Health Lost\'',
				desc = 'Shows the amount of health missing after all shown heals go off. \nTo use this, set the \'Health Lost\' option in your Raid Profile.\n\n',
				descStyle = 'inline',
				width = 'full',
				get = function() return HBCdb.global.predictiveHealthLost end,
				set = function(_, value) HBCdb.global.predictiveHealthLost = value end,
			},
			continued = {
				order = 100,
				type = 'description',
				name = 'More options will be added in the future.',
			}
		},
	}
	options.args['misc']={
		name = 'Miscellaneous',
		type = 'group',
		order = 30,
		args = {
			header0 = {
				order = 10,
				type = 'header',
				name = 'General Settings',
			},
			fastUpdate = {
				order = 20,
				type = 'toggle',
				name = 'Fast Raid Health Update',
				desc = 'Adds extra health updates every second.\nMay impact framerate on low end machines.',
				descStyle = 'inline',
				width = 'full',
				get = function() return HBCdb.global.fastUpdate end,
				set = function(_, value) HBCdb.global.fastUpdate = value;  end,
			},
		}
	}

	LibStub("AceConfig-3.0"):RegisterOptionsTable("HBCOptions", options)
	LibStub("AceConfigDialog-3.0"):AddToBlizOptions("HBCOptions","HealBarsClassic")
end