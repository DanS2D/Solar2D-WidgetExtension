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

local function pageErrorMessage(index, message)
	error(sFormat("pages[%d] %s", index, message))
end

function M.new(options)
	local optionParamName = {
		options = "options",
		pages = "pages"
	}
	local buttonParamName = {
		mainButton = "mainButton",
		leftButton = "leftButton",
		rightButton = "rightButton"
	}
	-- check to ensure required options tables/subtables exist
	assert(type(options) == "table", sFormat("options (table) expected, got %s", type(options)))
	assert(type(options.pages) == "table", sFormat("options.pages (table) expected, got %s", type(options.pages)))

	local x = options.x or dCenterX
	local y = options.y or dCenterY
	local width = options.width or dWidth - 20
	local height = options.height or dHeight - 100
	local xOffset = options.xOffset or 0
	local yOffset = options.yOffset or 0
	local hide = options.hide or false
	local onClose = options.onClose
	local parentGroup = options.parentGroup or display.currentStage
	local group = display.newGroup()
	local pages = {}
	-- group members
	group.currentPage = 1
	group.isOpen = true
	group.changingPages = false

	local function createButtonOptions(params, label)
		local iconParams = params and params.icon
		local iconAnimationParams = iconParams and iconParams.animation
		local labelParams = params and params.label
		local labelFillParams = labelParams and labelParams.fill
		local fillParams = params and params.fill
		local strokeParams = params and params.stroke

		local defaultOptions = {
			isCloseButton = params and params.isCloseButton or false,
			isBackwardButton = params and params.isBackwardButton or false,
			isForwardButton = params and params.isForwardButton or false,
			closeEffect = params and params.closeEffect or "slideToLeft",
			onPress = params and params.onPress,
			onRelease = params and params.onRelease,
			icon = {
				filePath = iconParams and iconParams.filePath,
				baseDirectory = iconParams and iconParams.baseDirectory or system.ResourceDirectory,
				width = iconParams and iconParams.width or 35,
				height = iconParams and iconParams.height or 35,
				xOffset = iconParams and iconParams.xOffset or 0,
				yOffset = iconParams and iconParams.yOffset or 0,
				animation = {
					style = iconAnimationParams and iconAnimationParams.style or "pingpong",
					initialDelay = iconAnimationParams and iconAnimationParams.initialDelay or 0
				}
			},
			label = {
				text = labelParams and labelParams.text or label,
				font = labelParams and labelParams.font or native.systemFontBold,
				fontSize = labelParams and labelParams.fontSize or 18,
				emboss = labelParams and labelParams.emboss or false,
				xOffset = labelParams and labelParams.xOffset or nil,
				yOffset = labelParams and labelParams.yOffset or nil,
				fill = {
					default = labelFillParams and labelFillParams.default or {1, 1, 1},
					over = labelFillParams and labelFillParams.over or {1, 1, 1, 0.5}
				}
			},
			fill = {
				default = fillParams and fillParams.default or {0, 0, 0, 1},
				over = fillParams and fillParams.over or {0.1, 0.1, 0.1, 1}
			},
			stroke = {
				width = strokeParams and strokeParams.width or 0,
				default = strokeParams and strokeParams.default or {1, 0.4, 1, 1},
				over = strokeParams and strokeParams.over or {0.8, 0.8, 1, 1}
			}
		}

		return defaultOptions
	end

	-- group methods

	function group:show(presentation, options)
		local opt = options or {}
		local presentationType = presentation or "slideFromLeft"
		local targetOptions = {
			x = self.x,
			y = self.y,
			alpha = self.alpha,
			time = opt.time or 1000,
			transition = opt.transition or easing.inOutQuad,
			onComplete = function()
				self.isOpen = true

				if (type(opt.onComplete) == "function") then
					opt.onComplete()
				end
			end
		}
		self.isVisible = true

		if (presentationType:lower() == "slidefromleft") then
			self.x = (self.x - xOffset - (self.contentWidth * 0.5))
			targetOptions.x = targetOptions.x
			targetOptions.y = nil
		elseif (presentationType:lower() == "slidefromright") then
			self.x = (self.x + xOffset + (self.contentWidth * 0.5))
			targetOptions.x = targetOptions.x
			targetOptions.y = nil
		elseif (presentationType:lower() == "slidefromtop") then
			self.y = (self.y - yOffset - self.contentHeight)
			targetOptions.x = nil
			targetOptions.y = targetOptions.y
		elseif (presentationType:lower() == "slidefrombottom") then
			self.y = (self.y + yOffset + self.contentHeight)
			targetOptions.x = nil
			targetOptions.y = targetOptions.y
		elseif (presentationType:lower() == "fadein") then
			self.alpha = 0
			targetOptions.x = nil
			targetOptions.y = nil
		end

		transition.to(self, targetOptions)
	end

	function group:_dismiss(presentation, options)
		local opt = options or {}
		local presentationType = presentation or "slidetoleft"
		local targetOptions = {
			x = self.x,
			y = self.y,
			alpha = self.alpha,
			time = opt.time or 1000,
			transition = opt.transition or easing.inOutQuad,
			onComplete = function()
				self.isOpen = true

				if (type(opt.onComplete) == "function") then
					opt.onComplete()
				end
			end
		}
		self.isVisible = true

		if (presentationType:lower() == "slidetoleft") then
			targetOptions.x = (self.x - xOffset - (self.contentWidth * 0.5))
			targetOptions.y = nil
		elseif (presentationType:lower() == "slidetoright") then
			targetOptions.x = (self.x + xOffset + (self.contentWidth * 0.5))
			targetOptions.y = nil
		elseif (presentationType:lower() == "slidetotop") then
			targetOptions.x = nil
			targetOptions.y = (self.y - yOffset - self.contentHeight)
		elseif (presentationType:lower() == "slidetobottom") then
			targetOptions.x = nil
			targetOptions.y = (self.y + yOffset + self.contentHeight)
		elseif (presentationType:lower() == "fadeout") then
			targetOptions.x = nil
			targetOptions.y = nil
			targetOptions.alpha = 0
		end

		transition.to(self, targetOptions)
	end

	function group:close(presentation)
		if (presentation == "immediate") then
			self.y = dHeight + self.contentHeight
			self.isVisible = false
			return
		end

		local opt = {
			transition = easing.inOutQuad,
			onComplete = function()
				self.isOpen = false
				self.isVisible = false

				if (type(onClose) == "function") then
					onClose()
				end
			end
		}

		self:_dismiss(presentation, opt)
	end

	-- create pages
	for i = 1, #options.pages do
		local opt = options.pages[i]
		pages[i] = display.newGroup()

		-- handle required params
		if (opt.titleText == nil) then
			pageErrorMessage(i, "titleText: (table) expected, got nil.")
		end

		local backgroundParams = opt.background
		local mainButtonParams = opt.mainButton
		local leftButtonParams = opt.leftButton
		local rightButtonParams = opt.rightButton
		local backgroundOptions = {
			fill = backgroundParams and backgroundParams.fill or {0.18, 0.18, 0.18},
			fillEffect = backgroundParams and backgroundParams.fillEffect or nil,
			stroke = backgroundParams and backgroundParams.stroke or {0, 0, 0},
			strokeWidth = backgroundParams and backgroundParams.strokeWidth or 0,
			strokeEffect = backgroundParams and backgroundParams.strokeEffect or nil,
			rounding = backgroundParams and backgroundParams.rounding or false,
			cornerRadius = backgroundParams and backgroundParams.cornerRadius or 0
		}
		local topIconParams = opt.topIcon
		local titleTextParams = opt.titleText
		local bodyTextParams = opt.bodyText
		local imageParams = opt.image
		local background = nil
		local topIcon = nil
		local titleText = nil
		local bodyText = nil
		local bodyImage = nil
		local mainButton = nil
		local leftButton = nil
		local rightButton = nil
		local topIconOptions = {
			filePath = topIconParams and topIconParams.filePath or
				topIconParams ~= nil and pageErrorMessage(i, "topIcon.filePath: (string) expected, got nil."),
			baseDirectory = topIconParams and topIconParams.baseDirectory or system.ResourceDirectory,
			x = topIconParams and topIconParams.x or nil,
			y = topIconParams and topIconParams.y or nil,
			width = topIconParams and topIconParams.width or
				topIconParams ~= nil and pageErrorMessage(i, "topIcon.width: (number) expected, got nil."),
			height = topIconParams and topIconParams.height or
				topIconParams ~= nil and pageErrorMessage(i, "topIcon.height: (number) expected, got nil."),
			xOffset = topIconParams and topIconParams.xOffset or 0,
			yOffset = topIconParams and topIconParams.yOffset or 0
		}
		local titleTextOptions = {
			text = titleTextParams and titleTextParams.text or pageErrorMessage(i, "titleText.text (string) expected, got nil."),
			font = titleTextParams and titleTextParams.font or native.systemFontBold,
			fontSize = titleTextParams and titleTextParams.fontSize or 18,
			fontColor = titleTextParams and titleTextParams.fontColor or {1, 1, 1},
			align = titleTextParams and titleTextParams.align or "center",
			heightPadding = titleTextParams and titleTextParams.heightPadding or 0
		}
		local bodyTextOptions = {
			text = bodyTextParams and bodyTextParams.text or
				bodyTextParams ~= nil and pageErrorMessage(i, "bodyText.text: (string) expected, got nil."),
			font = bodyTextParams and bodyTextParams.font or native.systemFontBold,
			fontSize = bodyTextParams and bodyTextParams.fontSize or 14,
			fontColor = bodyTextParams and bodyTextParams.fontColor or {1, 1, 1},
			align = bodyTextParams and bodyTextParams.align or "center",
			heightPadding = bodyTextParams and bodyTextParams.heightPadding or 20
		}
		local bodyImageOptions = {
			filePath = imageParams and imageParams.filePath or
				imageParams ~= nil and pageErrorMessage(i, "image.filePath: (string) expected, got nil."),
			baseDirectory = imageParams and imageParams.baseDirectory or system.ResourceDirectory,
			x = imageParams and imageParams.x or 0,
			y = imageParams and imageParams.y or 0,
			width = imageParams and imageParams.width or
				imageParams ~= nil and pageErrorMessage(i, "image.width: (number) expected, got nil."),
			height = imageParams and imageParams.height or
				imageParams ~= nil and pageErrorMessage(i, "image.height: (number) expected, got nil."),
			xOffset = imageParams and imageParams.xOffset or 0,
			yOffset = imageParams and imageParams.xOffset or 0
		}
		local buttonOptions = {
			mainButton = createButtonOptions(mainButtonParams, "Continue"),
			leftButton = createButtonOptions(leftButtonParams, "Back"),
			rightButton = createButtonOptions(rightButtonParams, "Next")
		}

		-- handle page forward navigation
		local function onPageForward()
			if (not group.changingPages) then
				if (group.currentPage + 1 > #pages) then
					return
				end

				pages[group.currentPage + 1].isVisible = true

				transition.to(pages[group.currentPage], {x = -dWidth, transition = easing.inOutQuad})
				transition.to(
					pages[group.currentPage + 1],
					{
						x = 0,
						transition = easing.inOutQuad,
						onComplete = function()
							group.currentPage = group.currentPage + 1
							group.changingPages = false

							if (group.currentPage > 0) then
								pages[group.currentPage - 1].isVisible = false
							end
						end
					}
				)
			end

			group.changingPages = true
		end

		-- handle page backward navigation
		local function onPageBackward()
			if (not group.changingPages) then
				if (group.currentPage - 1 < 1) then
					return
				end

				pages[group.currentPage - 1].isVisible = true

				transition.to(pages[group.currentPage], {x = dWidth, transition = easing.inOutQuad})
				transition.to(
					pages[group.currentPage - 1],
					{
						x = 0,
						transition = easing.inOutQuad,
						onComplete = function()
							group.currentPage = group.currentPage - 1
							group.changingPages = false

							if (group.currentPage > 0) then
								pages[group.currentPage + 1].isVisible = false
							end
						end
					}
				)

				group.changingPages = true
			end
		end

		-- setup a buttons icon for a transition
		local function setupIconTransitionEffect(button, userParams, animationOptions)
			local animParams = userParams.icon.animation

			for k, v in pairs(animParams) do
				animationOptions[k] = v

				if (k == "x" or k == "y") then
					animationOptions[k] = button.icon[k] + animParams[k]
				end
			end
		end

		-- create a carousel navigation button
		local function createNavigationButton(buttonParams, userParams, name)
			local button =
				widget.newButton(
				{
					x = background.x,
					width = (name == "main" and width) or (width * 0.5 - 1),
					height = 50,
					shape = "rect",
					label = buttonParams.label.text,
					font = buttonParams.label.font,
					fontSize = buttonParams.label.fontSize,
					labelXOffset = buttonParams.label.xOffset,
					labelYOffset = buttonParams.label.yOffset,
					emboss = buttonParams.label.emboss,
					labelColor = {
						default = buttonParams.label.fill.default,
						over = buttonParams.label.fill.over
					},
					fillColor = {
						default = buttonParams.fill.default,
						over = buttonParams.fill.over
					},
					strokeColor = {
						default = buttonParams.stroke.default,
						over = buttonParams.stroke.over
					},
					onPress = function(event)
						local target = event.target

						if (target.isForwardButton) then
							onPageForward()
						elseif (target.isBackwardButton) then
							onPageBackward()
						else
							group:close(target.closeEffect)
						end

						if (type(target.onPress) == "function") then
							target.onPress(event)
						end
					end,
					onRelease = function(event)
						local target = event.target

						if (type(target.onRelease) == "function") then
							target.onRelease(event)
						end
					end
				}
			)
			button.anchorY = 1
			button.x = background.x
			button.y = (background.y + (background.contentHeight * 0.5))
			button.isCloseButton = buttonParams.isCloseButton
			button.isBackwardButton = buttonParams.isBackwardButton
			button.isForwardButton = buttonParams.isForwardButton
			button.closeEffect = buttonParams.closeEffect
			button.onPress = buttonParams.onPress
			button.onRelease = buttonParams.onRelease
			pages[i]:insert(button)

			-- setup the correct x position per button type
			if (name == "left") then
				button.anchorX = 0
				button.x = (background.x - (background.contentWidth * 0.5))
			elseif (name == "right") then
				button.anchorX = 1
				button.x = (background.x + (background.contentWidth * 0.5))
			end

			-- sanity check for button types
			if (button.isCloseButton and button.isBackwardButton) then
				pageErrorMessage(
					i,
					sFormat("%sButton: a button cannot be both a close and backward button. It's either one or the other.", name)
				)
			elseif (button.isCloseButton and button.isForwardButton) then
				pageErrorMessage(
					i,
					sFormat("%sButton: a button cannot be both a close and forward button. It's either one or the other.", name)
				)
			end

			if (button.isBackwardButton and button.isForwardButton) then
				pageErrorMessage(
					i,
					sFormat("%sButton: a button cannot be both a backward and forward button. It's either one or the other.", name)
				)
			elseif (button.isForwardButton and button.isBackwardButton) then
				pageErrorMessage(
					i,
					sFormat("%sButton: a button cannot be both a forward and backward button. It's either one or the other.", name)
				)
			end

			-- create the main button icon
			if (buttonParams.icon.filePath) then
				-- ensure the icon file exists
				if (not system.pathForFile(buttonParams.icon.filePath, buttonParams.icon.baseDirectory)) then
					pageErrorMessage(
						i,
						sFormat("%sButton icon.filePath: file not found at path: %s", name, buttonParams.icon.filePath)
					)
				end

				button.icon =
					display.newImageRect(
					buttonParams.icon.filePath,
					buttonParams.icon.baseDirectory,
					buttonParams.icon.width,
					buttonParams.icon.height
				)
				button.icon.x =
					(button.contentWidth * 0.5) + (button._view._label.contentWidth * 0.5) + (button.icon.contentWidth * 0.5) +
					buttonParams.icon.xOffset
				button.icon.y = (button.contentHeight * 0.5) + buttonParams.icon.yOffset
				button:insert(button.icon)

				if (buttonParams.icon.animation) then
					local animationOptions = buttonParams.icon.animation
					if (animationOptions.style:lower() == "pingpong") then
						setupIconTransitionEffect(button, userParams, animationOptions)
						transition.pingPong(button.icon, animationOptions)
					else
						setupIconTransitionEffect(button, userParams, animationOptions)
						timer.performWithDelay(
							animationOptions.initialDelay,
							function()
								transition.to(button.icon, animationOptions)
							end
						)
					end
				end
			end

			return button
		end
		-- create and setup the background
		if (backgroundOptions.rounding) then
			background = display.newRoundedRect(pages[i], 0, 0, width, height, backgroundOptions.cornerRadius)
		else
			background = display.newRect(pages[i], 0, 0, width, height)
		end

		background.fill = backgroundOptions.fill
		background.fill.effect = backgroundOptions.fillEffect
		background.stroke = backgroundOptions.stroke
		background.strokeWidth = backgroundOptions.strokeWidth
		background.strokeEffect = backgroundOptions.strokeEffect

		-- create and setup the top icon
		if (opt.topIcon) then
			-- ensure the icon file exists
			utils:checkFileExists(topIconOptions.filePath, topIconOptions.baseDirectory, "topIcon.filePath")

			topIcon =
				display.newImageRect(
				pages[i],
				topIconOptions.filePath,
				topIconOptions.baseDirectory,
				topIconOptions.width,
				topIconOptions.height
			)
			topIcon.x = topIconOptions.x and topIconOptions.x + topIconOptions.xOffset or background.x + topIconOptions.xOffset
			topIcon.y =
				topIconOptions.y and topIconOptions.y + topIconOptions.yOffset or
				(background.y - (background.contentHeight * 0.5) + topIconOptions.yOffset)
		end

		-- create and setup the title text
		titleText =
			display.newText(
			{
				parent = pages[i],
				text = titleTextOptions.text,
				width = width - 20,
				font = titleTextOptions.font,
				fontSize = titleTextOptions.fontSize,
				align = titleTextOptions.align
			}
		)
		titleText.anchorY = 0
		titleText.x = background.x
		titleText.y = ((background.y - (background.contentHeight * 0.5)) + titleTextOptions.heightPadding + 10)
		titleText:setFillColor(uPack(titleTextOptions.fontColor))

		if (topIcon) then
			titleText.y = ((topIcon.y + (topIcon.contentHeight * 0.5)) + titleTextOptions.heightPadding + 20)
		end

		-- create and setup the body text
		if (opt.bodyText) then
			bodyText =
				display.newText(
				{
					parent = pages[i],
					text = bodyTextOptions.text,
					width = width - 20,
					font = bodyTextOptions.font,
					fontSize = bodyTextOptions.fontSize,
					align = bodyTextOptions.align
				}
			)
			bodyText.anchorY = 0
			bodyText.x = background.x
			bodyText.y = (titleText.y + titleText.contentHeight + bodyTextOptions.heightPadding)
			bodyText:setFillColor(uPack(bodyTextOptions.fontColor))
		end

		-- create and setup the body image
		if (opt.image) then
			-- ensure the image file exists
			utils:checkFileExists(bodyImageOptions.filePath, bodyImageOptions.baseDirectory, "image.filePath")

			bodyImage =
				display.newImageRect(
				pages[i],
				bodyImageOptions.filePath,
				bodyImageOptions.baseDirectory,
				bodyImageOptions.width,
				bodyImageOptions.height
			)
			bodyImage.x =
				bodyImageOptions.x and bodyImageOptions.x + bodyImageOptions.xOffset or background.x + bodyImageOptions.xOffset
			bodyImage.y =
				bodyImageOptions.y and bodyImageOptions.y + bodyImageOptions.yOffset or
				(background.y - (background.contentHeight * 0.5) + bodyImageOptions.yOffset)

			if (bodyText) then
				bodyImage.y =
					(bodyText.y + bodyText.contentHeight + bodyImageOptions.yOffset + 10 + (bodyImage.contentHeight * 0.5))
			end
		end

		-- create and setup the buttons
		if (mainButtonParams) then
			mainButton = createNavigationButton(buttonOptions.mainButton, mainButtonParams, "main")
		end

		if (leftButtonParams and rightButtonParams) then
			leftButton = createNavigationButton(buttonOptions.leftButton, leftButtonParams, "left")
			rightButton = createNavigationButton(buttonOptions.rightButton, rightButtonParams, "right")
		end

		if (i > 1) then
			pages[i].x = dWidth
			pages[i].isVisible = false
		end

		group:insert(pages[i])
	end

	-- hide upon creation if requested
	if (hide) then
		group:close("immediate")
	end

	parentGroup:insert(group)

	-- set the groups position
	group.anchorChildren = false
	group.anchorX = 0.5
	group.anchorY = 0.5
	group.x = x + xOffset
	group.y = y + yOffset

	return group
end

return M
