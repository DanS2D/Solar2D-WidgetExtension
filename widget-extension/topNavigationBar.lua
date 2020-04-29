local cwd = (...):match("(.+)%.[^%.]+$") or (...)
local widget = require("widget")
local utils = require(cwd .. ".widget-utils")

local M = {}
local mFloor = math.floor
local sFormat = string.format
local uPack = unpack
local dScreenOriginX = display.screenOriginX
local dScreenOriginY = display.dScreenOriginY
local dCenterX = display.contentCenterX
local dCenterY = display.contentCenterY
local dWidth = display.contentWidth
local dHeight = display.contentHeight
local dActualWidth = display.actualContentWidth
local dActualHeight = display.actualContentHeight
local statusBarHeight = display.topStatusBarContentHeight

function M.new(options)
	local optionParamName = {
		options = "options",
		titleText = "titleText"
	}
	local buttonParamName = {
		leftButtons = "leftButtons",
		rightButtons = "rightButtons"
	}
	-- check to ensure required options tables/subtables exist
	assert(type(options) == "table", sFormat("options (table) expected, got %s", type(options)))
	assert(
		type(options.titleText) == "table",
		sFormat("options.titleText (table) expected, got %s", type(options.titleText))
	)

	local x = options.x or dCenterX
	local y = options.y or 0
	local width = options.width or dWidth
	local height = options.height or 56
	local fill = options.fill or {51 / 255, 181 / 255, 229 / 255}
	local fillEffect = options.fillEffect
	local stroke = options.stroke
	local strokeEffect = options.strokeEffect
	local strokeWidth = options.strokeWidth
	local xOffset = options.xOffset or 0
	local yOffset = options.yOffset or 0
	local buttonLeftXPadding = options.leftPadding or 15
	local parentGroup = options.parentGroup or display.currentStage
	local group = display.newGroup()
	local backgroundOverlay = nil
	local topBar = nil
	local titleText = nil
	local leftButtons = {}
	local rightButtons = {}
	local titleTextOptions = {
		text = options.titleText.text,
		font = options.titleText.font or native.systemFontBold,
		fontSize = options.titleText.fontSize or 16,
		fontColor = options.titleText.fontColor or {1, 1, 1},
		align = options.titleText.align or "left",
		xOffset = options.titleText.xOffset or 21,
		heightPadding = options.titleText.heightPadding or 0
	}

	-- group methods

	function group:updateTitle(text)
		titleText.text = text
	end

	local function createButtonOptions(params, index, side)
		local defaultOptions = {
			x = params and params.x or 0,
			width = params and params.width or 24,
			height = params and params.height or 24,
			xOffset = params and params.xOffset or 0,
			yOffset = params and params.yOffset or 0,
			defaultFile = params and params.defaultFile,
			overFile = params and params.overFile,
			baseDirectory = params and params.baseDirectory or system.ResourceDirectory,
			useTouchEffect = params and params.useTouchEffect or false,
			onPress = params and params.onPress,
			onRelease = params and params.onRelease
		}

		return defaultOptions
	end

	-- create a top-bar navigation button
	local function createNavigationButton(opt)
		local button =
			widget.newButton(
			{
				width = opt.width,
				height = opt.height,
				defaultFile = opt.defaultFile,
				overFile = opt.overFile,
				onPress = not opt.useTouchEffect and opt.onPress,
				onRelease = not opt.useTouchEffect and opt.onRelease
			}
		)
		button.x = opt.x + xOffset
		button.y = (topBar.contentHeight * 0.5)
		button.useTouchEffect = opt.useTouchEffect
		button.onPress = opt.onPress
		button.onRelease = opt.onRelease

		local function touch(event)
			local target = button
			local phase = event.phase

			if (phase == "began") then
				if (target.useTouchEffect) then
					target:showTouchEffect(true)
				end

				if (type(target.onPress) == "function") then
					target.onPress(event)
				end
			elseif (phase == "ended" or phase == "canceled") then
				if (target.useTouchEffect) then
					target:showTouchEffect(false)
				end

				if (type(target.onRelease) == "function") then
					target.onRelease(event)
				end
			end
		end

		-- create a bigger touch area for the button
		button.touchArea =
			widget.newButton(
			{
				shape = "rect",
				widget = opt.width,
				height = height,
				onPress = button.onPress,
				onRelease = button.onRelease
			}
		)
		button.touchArea.x = button.x
		button.touchArea.y = button.y
		button.touchArea.useTouchEffect = button.useTouchEffect
		button.touchArea.isVisible = false
		button.touchArea.isHitTestable = true
		group:insert(button.touchArea)
		group:insert(button)

		if (opt.useTouchEffect) then
			button._view:addEventListener("touch", touch)
			button.touchArea._view:addEventListener("touch", touch)
		end

		-- create the touch effect
		if (button.useTouchEffect) then
			button.touchEffect = display.newCircle(0, 0, button.width / 2 + 2)
			button.touchEffect.x = button.x
			button.touchEffect.y = button.y
			button.touchEffect.alpha = 0
			button.touchEffect.tag = "_button.clickEffect"
			button.touchEffect.fadeInComplete = false
			button.touchEffect.started = false
			button.touchEffect:setFillColor(0.18, 0.18, 0.18, 0.2)
			group:insert(group.numChildren, button.touchEffect)

			function button:showTouchEffect(show)
				if (show) then
					if (not self.touchEffect.started) then
						self.touchEffect.started = true
						transition.to(
							self.touchEffect,
							{
								tag = "_buttonClickEffect",
								alpha = 1,
								time = 300,
								transition = easing.inOutQuad,
								onComplete = function()
									self.touchEffect.started = false
								end
							}
						)
					end
				else
					if (not self.touchEffect.started) then
						transition.to(self.touchEffect, {alpha = 0, time = 300, transition = easing.inOutQuad})
					else
						transition.cancel(self.touchEffect.tag)
						transition.to(
							self.touchEffect,
							{
								alpha = 1,
								time = 300,
								transition = easing.inOutQuad,
								onComplete = function()
									transition.to(self.touchEffect, {alpha = 0, time = 300, transition = easing.inOutQuad})
								end
							}
						)
					end
				end
			end
		end

		return button
	end

	local function slidingMenuEvent(event)
		local phase = event.phase
		local targetAlpha = (phase == "opening") and 1 or 0

		transition.to(backgroundOverlay, {alpha = targetAlpha, transition = easing.inOutQuad})

		return true
	end

	local leftButtonsOptions = options.leftButtons or nil
	local rightButtonsOptions = options.rightButtons or nil

	-- create and setup the top bar
	topBar = display.newRect(group, 0, 0, width, height)
	topBar.x = x + xOffset
	topBar.y = y + yOffset + topBar.contentHeight * 0.5
	topBar.fill = fill
	topBar.fill.effect = fillEffect
	topBar.stroke = stroke
	topBar.strokeWidth = strokeWidth
	topBar.strokeEffect = strokeEffect

	-- create and setup the left buttons
	if (type(options.leftButtons) == "table") then
		for i = 1, #options.leftButtons do
			leftButtonsOptions[i] = createButtonOptions(options.leftButtons[i], i, "left")
			leftButtonsOptions[i].x =
				(i == 1 and 15 + leftButtonsOptions[i].xOffset) or
				((leftButtonsOptions[i].width * i) + leftButtonsOptions[i].xOffset)

			utils:checkFileExists(
				leftButtonsOptions[i].defaultFile,
				system.ResourceDirectory,
				sFormat("%s.%s", buttonParamName.leftButtons, "defaultFile")
			)
			leftButtons[#leftButtons + 1] = createNavigationButton(leftButtonsOptions[i])
		end
	end

	-- create and setup the right buttons
	if (type(options.rightButtons) == "table") then
		for i = 1, #options.rightButtons do
			rightButtonsOptions[i] = createButtonOptions(options.rightButtons[i], i, "right")
			rightButtonsOptions[i].x =
				(i == 1 and dWidth - 15 - rightButtonsOptions[i].xOffset) or
				((rightButtonsOptions[i].width * i) - rightButtonsOptions[i].xOffset)

			utils:checkFileExists(
				rightButtonsOptions[i].defaultFile,
				system.ResourceDirectory,
				sFormat("%s.%s", buttonParamName.rightButtons, "defaultFile")
			)
			leftButtons[#leftButtons + 1] = createNavigationButton(rightButtonsOptions[i])
		end
	end

	-- create and setup the title text
	titleText =
		display.newText(
		{
			parent = group,
			text = titleTextOptions.text,
			width = width - 20,
			font = titleTextOptions.font,
			fontSize = titleTextOptions.fontSize,
			align = titleTextOptions.align
		}
	)
	titleText.anchorX = 0
	titleText.anchorY = 0
	titleText.y = (topBar.y + titleTextOptions.heightPadding - (titleText.contentHeight * 0.5))
	titleText:setFillColor(uPack(titleTextOptions.fontColor))

	if (#leftButtons > 0) then
		titleText.x =
			(#leftButtons > 0) and leftButtons[#leftButtons].x + titleTextOptions.xOffset or titleTextOptions.xOffset
	else
		titleText.x = titleTextOptions.xOffset
	end

	-- create the background overlay
	backgroundOverlay = display.newRect(group, 0, 0, dWidth, dHeight)
	backgroundOverlay.x = dCenterX
	backgroundOverlay.y = dCenterY
	backgroundOverlay.alpha = 0
	backgroundOverlay.isHitTestable = true
	backgroundOverlay:addEventListener(
		"touch",
		function(event)
			local phase = event.phase
			local target = event.target

			if (phase == "began" and target.alpha > 0) then
				local topBarEvent = {
					name = "topNavigationBar",
					phase = "began"
				}

				Runtime:dispatchEvent(topBarEvent)
			end

			return (target.alpha > 0)
		end
	)
	backgroundOverlay:setFillColor(0, 0, 0, 0.3)

	Runtime:addEventListener("slidingMenu", slidingMenuEvent)
	parentGroup:insert(group)

	return group
end

return M
