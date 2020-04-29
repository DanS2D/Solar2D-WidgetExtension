-- widget extension - author: Danny Glover - copyright © Danny Glover 2020 - license: GNU General Public License v3.0

local widget = require("widget")
local strict = require("strict")
local widgetExtension = require("widget-extension.extension-widget")
local sFormat = string.format
local dScreenOriginX = display.screenOriginX
local dScreenOriginY = display.dScreenOriginY
local dCenterX = display.contentCenterX
local dCenterY = display.contentCenterY
local dWidth = display.contentWidth
local dHeight = display.contentHeight
local dStatusBarHeight = display.topStatusBarContentHeight
local showWidget = {
	topNavigationBar = true,
	carousel = false,
	slidingMenu = false
}
display.setStatusBar(display.HiddenStatusBar)

local slidingMenu =
	widget.newSlidingMenu(
	{
		--background = {},
		topSection = {
			background = {},
			icon = {
				filePath = "img/duck.png"
				--centerIconHorizontally = true
				--width = 35,
				--height = 35
				--baseDirectory
			},
			heading = {
				--placeUnderIcon = true,
				text = "John Peters"
			},
			subHeading = {
				text = "Some guy from Texas, U.S.A.\nLives with his mom."
			}
		},
		listItems = {
			{
				label = {
					text = "Home"
				},
				icon = {
					filePath = "img/buttons/home.png",
					width = 25,
					height = 25
					--baseDirectory
				},
				onPress = function(event)
					print("home pressed")
				end
			},
			{
				label = {
					text = "Shopping List"
				},
				icon = {
					filePath = "img/buttons/list.png",
					width = 25,
					height = 25
				},
				onPress = function(event)
					print("shopping list pressed")
				end
			},
			{
				label = {
					text = "Settings"
				},
				icon = {
					filePath = "img/buttons/settings.png",
					width = 25,
					height = 25
				},
				bottomSeparatorLine = true,
				onPress = function(event)
					print("settings pressed")
				end
			},
			{
				label = {
					text = "About"
				},
				icon = {
					filePath = "img/buttons/info.png",
					width = 25,
					height = 25
				},
				onPress = function(event)
					print("about pressed")
				end
			},
			{
				label = {
					text = "Help"
				},
				icon = {
					filePath = "img/buttons/help.png",
					width = 25,
					height = 25
				},
				onPress = function(event)
					print("help pressed")
				end
			},
			{
				label = {
					text = "Rate Us"
				},
				icon = {
					filePath = "img/buttons/star.png",
					width = 25,
					height = 25
				},
				onPress = function(event)
					print("rate us pressed")
				end
			}
		}
	}
)

local topNavigationBar =
	widget.newTopNavigationBar(
	{
		titleText = {
			text = "Dashboard"
		},
		leftButtons = {
			{
				defaultFile = "img/buttons/menu.png",
				overFile = "img/buttons/menu.png",
				useTouchEffect = true,
				onPress = function(event)
					slidingMenu:show()
				end
			}
		}
	}
)

display.currentStage:insert(slidingMenu)

local carousel =
	widget.newCarousel(
	{
		yOffset = 40,
		--hide = false,
		onClose = function(event)
			print("carousel closed!")
		end,
		pages = {
			-- page 1
			{
				topIcon = {
					filePath = "img/duck.png",
					width = 128,
					height = 128
				},
				titleText = {
					text = "Testing a title + body text page"
				},
				bodyText = {
					text = "This is an example of a page with title text and a body text.\n\nIt's pretty basic, but it looks nice."
				},
				mainButton = {
					isForwardButton = true,
					icon = {
						filePath = "img/arrow.png",
						xOffset = 15,
						animation = {
							initialDelay = 3000,
							x = 20 -- relative to the icons current x position (so in this case icon.x + 20)
						}
					},
					label = {
						xOffset = -15
					}
				}
			},
			-- page 2
			{
				topIcon = {
					filePath = "img/scroll.png",
					width = 128,
					height = 128
				},
				titleText = {
					text = "Testing a title + body text + image page"
				},
				bodyText = {
					text = "This is an example of a page with title text, body text and an image displayed below it.\n\nIt seems to work..."
				},
				image = {
					filePath = "img/test.jpg",
					width = 200,
					height = 200
				},
				leftButton = {
					isBackwardButton = true
				},
				rightButton = {
					isForwardButton = true
				}
			},
			-- page 2
			{
				topIcon = {
					filePath = "img/walk.png",
					width = 128,
					height = 128
				},
				titleText = {
					text = "Testing a title + body text + input field page"
				},
				bodyText = {
					text = "This is an example of a page with title text, body text and an input field.\n\nTry and enter something in the input field below."
				},
				leftButton = {
					isBackwardButton = true
				},
				rightButton = {
					isCloseButton = true,
					--closeEffect = "fadeOut",
					onPress = function(event)
					end,
					label = {
						text = "Close"
					}
				}
			}
		}
	}
)
--carousel.isVisible = false

carousel:show(
	"slidefromleft",
	{
		time = 500
	}
)

local demoEffects = false

if (demoEffects) then
	local t = 5000
	carousel:show(
		"slidefrombottom",
		{
			time = t,
			onComplete = function()
				carousel:show(
					"slidefromtop",
					{
						time = t,
						onComplete = function()
							carousel:show(
								"slidefromleft",
								{
									time = t,
									onComplete = function()
										carousel:show(
											"slidefromright",
											{
												time = t,
												onComplete = function()
													carousel:show(
														"fadein",
														{
															time = t,
															onComplete = function()
															end
														}
													)
												end
											}
										)
									end
								}
							)
						end
					}
				)
			end
		}
	)
end
