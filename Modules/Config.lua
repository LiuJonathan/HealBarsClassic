--[[
	Function: CreateConfigs
	Purpose: Create and attach options page
	Notes: 
		For convenience, order is incremented in steps of two so new options can be squeezed between them.
]]--
function HealBarsClassic:RegisterChatCommands()
	--AceConsole:RegisterChatCommand('hbc 

end
function HealBarsClassic:CreateConfigs()
	local options = {
		name = 'HealBarsClassic',
		type = 'group',
		childGroups = 'tab',
		args = {
			desc2 = {
				order = 10,
				type = 'description',
				width = 'full',
				name = 'HealComm for Blizzard\'s default unit frames.\n'
			},
			button0 = {
				order = 20,
				type = 'execute',
				name = 'Reset to defaults',
				confirm = true,
				func = function() HBCdb:ResetDB() end
			}
		},
	}
	options.args['basicFeatures'] = {
		name = 'Basic Features',
		type = 'group',
		order = 10,
		args = {
			header0 = {
				order = 10,
				type = 'header',
				name = 'Basic Settings',
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
			hotToggle = {
				order = 60,
				type = 'toggle',
				name = 'Show HoTs',
				desc = 'Include HoTs in healing prediction',
				width = 'full',
				get = function() return HBCdb.global.showHots end,
				set = function(_, value) HBCdb.global.showHots = value end,
			},
			seperateHot = {
				order = 130,
				type = 'toggle',
				name = 'Seperate HoT Color',
				disabled = function() return not HBCdb.global.showHots end,
				desc = 'Color HoTs as a seperate color.',
				width = 'full',
				get = function() return HBCdb.global.seperateHots end,
				set = function(_, value) HBCdb.global.seperateHots = value end,
			},
			raidCheckInfo = {
				order = 150,
				type = 'description',
				fontSize = 'medium',
				name = '\n\n\n\n\n|cFFFFD100Healing Addon Raid Check|r \n'..
						'/HealBarsClassic rc\n'..
						'/hbc rc\n\n'
			},
			raidCheckDesc = {
				order = 160,
				type = 'description',
				name = 'Shows which players in the raid have any compatible heal prediction addon. '..
						'Players only show if you\'ve seen them cast a heal since you\'ve last logged in.'		
			}
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
			timeframeGroup = {
				order = 10,
				type = 'group',
				name = 'Timeframes',
				args = {
					description = {
						order = 11,
						type = 'description',
						name = 'How many seconds into the future to show heals.\n',
					},
					headerSpacer = {
						order = 12,
						type = 'description',
						name = '\n',
					},
					healTimeframe = {
						order = 35,
						type = 'range',
						name = 'Heal Timeframe',
						desc = 'Timeframe for casted heals.',
						min = 0.5,
						max = 8,
						step = 0.5,
						get = function() return HBCdb.global.healTimeframe end,
						set = function(info,value) HBCdb.global.healTimeframe = value end,
					},
					spacer3 = {
						order = 40,
						type = 'description',
						name = '\n',
					},
					timeframe = {
						order = 70,
						type = 'range',
						name = 'HoT Timeframe',
						desc = 'Timeframe for HoTs.',
						min = 3,
						max = 8,
						step = 1,
						get = function() return HBCdb.global.timeframe end,
						set = function(info,value) HBCdb.global.timeframe = value end,
					}
				}
			},
			statusTextGroup = {
				name = 'Raid Status Text',
				type = 'group',
				order = 20,
				args = {
					feignToggle = {
						order = 20,
						type = 'toggle',
						name = 'Invulnerability Spell Indicator',
						descStyle = 'inline',
						desc = 'Displays text when certain invulnerability spells are used. \nCurrently supported spells:\n\n'..
								'Divine Shield - DIVSHLD\n' ..
								'Divine Protection - DIVPROT\n' ..
								'Divine Intervention - DIVINTR\n' ..
								'Blessing of Protection - BLSPROT\n' ..
								'Ice Block - ICEBLCK',
						width = 'full',
						get = function() return HBCdb.global.defensiveIndicator end,
						set = function(_, value) HBCdb.global.defensiveIndicator = value end,
					},
					spacer = {
						order = 30,
						type = 'description',
						name = '\n',
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
					}
				},
			},
			miscGroup = {
				name = 'Miscellaneous',
				type = 'group',
				order = 40,
				args = {
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
			},
			todoGroup = {
				order = 60,
				type = 'group',
				name = 'More options coming soon!',
				disabled = true,
				args = {
				}
			},
		}
	}
	options.args['colorSettings'] = {
		name = 'Color Settings',
		type = 'group',
		order = 30,
		args = {
			header0 = {
				order = 10,
				type = 'header',
				name = 'Color Settings',
			},
			desc1 = {
				order = 100,
				type = 'description',
				name = 'The plus and minus slider sets transparency.'
			},
			spacer0 = {
				order = 101,
				type = 'description',
				name = '\n',
			},
			healColor = { 
				order = 110,
				type = 'color',
				name = 'Heal Color',
				hasAlpha = true,
				width = 'full',
				get = function() return unpack(HBCdb.global.healColor) end,
				set = function (_, r, g, b, a) HBCdb.global.healColor = {r,g,b,a}; 
												HealBarsClassic.UpdateColors() end,
			},
			spacer1 = {
				order = 111,
				type = 'description',
				name = '\n',
			},
			hotColor = { 
				order = 140,
				type = 'color',
				name = 'HoT Color',
				hasAlpha = true,
				width = 'full',
				get = function() return unpack(HBCdb.global.hotColor) end,
				set = function (_,r, g, b, a) HBCdb.global.hotColor = {r,g,b,a}; 
											HealBarsClassic.UpdateColors() end,
			}
		}
	}

	
	LibStub("AceConfig-3.0"):RegisterOptionsTable("HBCOptions", options)
	AceConfigDialog:AddToBlizOptions("HBCOptions","HealBarsClassic")

end