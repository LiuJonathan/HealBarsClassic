--[[
	Function: CreateConfigs
	Purpose: Create and attach options page
	Notes: 
		For convenience, order is incremented in steps of two so new options can be squeezed between them.
]]--
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
				name = 'Heal Predictions for Blizzard\'s UI\n'
			},
			button0 = {
				order = 20,
				type = 'execute',
				name = 'Reset addon to defaults',
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
			seperateOwnHeal = {
				order = 40,
				type = 'toggle',
				name = 'Separate Color For Own Heals (Smart Order)',
				desc = 'Heals are shown in the order they\'ll land. \nHoTs always shown last.',
				width = 'full',
				get = function() return HBCdb.global.seperateOwnColor end,
				set = function(_, value) HBCdb.global.seperateOwnColor = value; HealBarsClassic:ResetHealBars() end,
			},
			spacer1 = {
				order = 41,
				type = 'description',
				name = '\n',
			},
			hotToggle = {
				order = 60,
				type = 'toggle',
				name = 'Show HoTs',
				desc = 'Include HoTs in healing predictions.',
				width = 'full',
				get = function() return HBCdb.global.showHots end,
				set = function(_, value) HBCdb.global.showHots = value; HealBarsClassic:ResetHealBars() end,
			},
			seperateHot = {
				order = 130,
				type = 'toggle',
				name = 'Seperate HoT Color',
				disabled = function() return not HBCdb.global.showHots end,
				desc = 'Color HoTs as a seperate color.'..
					'\n\nWhen \'Separate Color For Own Heals\' is enabled, this option makes both HoTs show as the same color.',
				width = 'full',
				get = function() return HBCdb.global.showHots and HBCdb.global.seperateHots end,
				set = function(_, value) HBCdb.global.seperateHots = value
										 HealBarsClassic:ResetHealBars() end,
			},
			spacer2 = {
				order = 131,
				type = 'description',
				name = '\n',
			},
			raidCheckInfo = {
				order = 150,
				type = 'description',
				fontSize = 'medium',
				name = '\n\n\n\n\n|cFFFFD100Chat Commands|r \n'..
						'/HealBarsClassic help\n'..
						'/hbc help\n\n',
				descStyle = 'inline',
				desc = 'test'
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
						desc = 'Timeframe for casted heals. \n'
							..'At lower settings, delayed heals won\'t show until they\'re within the timeframe.',
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
			textureGroup = {
				name = 'Textures',
				type = 'group',
				order = 15,
				args = {
					unitFrameTextures = {
						order = 140,
						type = 'toggle',
						name = 'Alternative Heal Texture (Unit Frames Only)',
						desc = 'Requires /reload. Improves contrast.',
						descStyle = 'inline',
						width = 'full',
						get = function() return HBCdb.global.alternativeTexture end,
						set = function(_,value) HBCdb.global.alternativeTexture = value end
					},
				}
			},
			statusTextGroup = {
				name = 'Raid Status Text',
				type = 'group',
				order = 20,
				args = {
					defensiveToggle = {
						order = 10,
						type = 'toggle',
						name = 'Enabled',
						desc = 'Enable custom status text display.',
						get = function() return HBCdb.global.defensiveIndicator end,
						set = function(_, value) HBCdb.global.defensiveIndicator = value end,
					},
					invulDefensiveToggles = {
						order = 20,
						type = 'multiselect',
						name = 'Invulnerability Indicators',
						width = 'full',
						disabled = function() return not HBCdb.global.defensiveIndicator end,
						values = HealBarsClassic.invulStatusTextConfigList,
						get = function(_,key) return HBCdb.global.enabledStatusTexts[key] end,
						set = function(_,key,state) HBCdb.global.enabledStatusTexts[key] = state end,
					},
					strongDefensiveToggles = {
						order = 25,
						type = 'multiselect',
						name = 'Strong Mitigation Indicators',
						width = 'full',
						disabled = function() return not HBCdb.global.defensiveIndicator end,
						values = HealBarsClassic.strongMitStatusTextConfigList,
						get = function(_,key) return HBCdb.global.enabledStatusTexts[key] end,
						set = function(_,key,state) HBCdb.global.enabledStatusTexts[key] = state end,
					},
					weakDefensiveToggles = {
						order = 25,
						type = 'multiselect',
						name = 'Weak Mitigation Indicators',
						width = 'full',
						disabled = function() return not HBCdb.global.defensiveIndicator end,
						values = HealBarsClassic.softMitStatusTextConfigList,
						get = function(_,key) return HBCdb.global.enabledStatusTexts[key] end,
						set = function(_,key,state) HBCdb.global.enabledStatusTexts[key] = state end,
					},
					miscToggles = {
						order = 40,
						type = 'multiselect',
						name = 'Miscellaneous Indicators',
						width = 'full',
						disabled = function() return not HBCdb.global.defensiveIndicator end,
						values = HealBarsClassic.miscStatusTextConfigList,
						get = function(_,key) return HBCdb.global.enabledStatusTexts[key] end,
						set = function(_,key,state) HBCdb.global.enabledStatusTexts[key] = state end,
					}
				},
			},
			healthTextGroup = {
				name = 'Raid Health Text',
				type = 'group',
				order = 30,
				args = {
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
				}
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
			}
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
				get = function() return unpack(HBCdb.global.hotColor) end,
				set = function (_,r, g, b, a) HBCdb.global.hotColor = {r,g,b,a}; 
											HealBarsClassic.UpdateColors() end,
			},
			spacer2 = {
				order = 141,
				type = 'description',
				name = '\n',
			},
			ownHealColor = { 
				order = 150,
				type = 'color',
				name = 'Own Heal Color',
				hasAlpha = true,
				get = function() return unpack(HBCdb.global.ownHealColor) end,
				set = function (_, r, g, b, a) HBCdb.global.ownHealColor = {r,g,b,a}; 
												HealBarsClassic.UpdateColors() end,
			},
			spacer3 = {
				order = 151,
				type = 'description',
				name = '\n',
			},
			ownHotColor = { 
				order = 160,
				type = 'color',
				name = 'Own HoT Color',
				hasAlpha = true,
				get = function() return unpack(HBCdb.global.ownHotColor) end,
				set = function (_, r, g, b, a) HBCdb.global.ownHotColor = {r,g,b,a}; 
												HealBarsClassic.UpdateColors() end,
			},
			spacer4 = {
				order = 161,
				type = 'description',
				name = '\n',
			},
			flipColors = {
				order = 170,
				type = 'execute',
				name = 'Flip Colors',
				desc = 'Flips regular and own heal colors.',
				func = function() 
					HBCdb.global.healColor, HBCdb.global.ownHealColor = HBCdb.global.ownHealColor, HBCdb.global.healColor
					HBCdb.global.hotColor, HBCdb.global.ownHotColor = HBCdb.global.ownHotColor, HBCdb.global.hotColor
					HealBarsClassic.UpdateColors()
				end,
			},
			spacer5 = {
				order = 171,
				type = 'description',
				name = '\n',
			},
			resetColors = {
				order = 180,
				type = 'execute',
				confirm = true,
				name = 'Reset Colors',
				desc = 'Resets colors back to the defaults.',
				func = function() 
					HBCdb.global.healColor = HBCDefaultColors.flat
					HBCdb.global.hotColor = HBCDefaultColors.hot 
					HBCdb.global.ownHealColor = HBCDefaultColors.ownFlat 
					HBCdb.global.ownHotColor = HBCDefaultColors.ownHot
					HealBarsClassic.UpdateColors()
				end,
			},
			spacer6 = {
				order = 181,
				type = 'description',
				name = '\n',
			},
			--[[
			resetHighContrastColors = {
				order = 190,
				type = 'execute',
				confirm = true,
				name = 'Reset Colors (Contrast)',
				desc = 'Resets colors back to the high contrast defaults.',
				func = function() 
					HBCdb.global.healColor = HBCHighContrastDefaultColors.flat
					HBCdb.global.hotColor = HBCHighContrastDefaultColors.hot 
					HBCdb.global.ownHealColor = HBCHighContrastDefaultColors.ownFlat 
					HBCdb.global.ownHotColor = HBCHighContrastDefaultColors.ownHot
					HealBarsClassic.UpdateColors()
				end,
			},--]]
		}
	}

	
	LibStub("AceConfig-3.0"):RegisterOptionsTable("HBCOptions", options)
	LibStub("AceConfigDialog-3.0"):AddToBlizOptions("HBCOptions","HealBarsClassic")

end