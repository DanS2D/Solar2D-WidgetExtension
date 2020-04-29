local cwd = (...):match("(.+)%.[^%.]+$") or (...)
local widget = require("widget")
local utils = require(cwd .. ".widget-utils")

local M = {}
local mAbs = math.abs
local mMin = math.min
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
		background = "background",
		topSection = "topSection",
		listItems = "listItems"
	}
	local backgroundParamName = "options.background"
	local topSectionParamName = {
		background = "options.topSection.background",
		icon = "options.topSection.icon",
		heading = "options.topSection.heading",
		subHeading = "options.topSection.subHeading"
	}
	local listItemParamName = {
		label = "options.listItem.label",
		icon = "options.listItem.icon",
		bottomSeparatorLine = "options.listItem.bottomSeparatorLine",
		onPress = "options.listItem.onPress"
	}
	-- check to ensure required options tables/subtables exist
	assert(type(options) == "table", sFormat("options (table) expected, got %s", type(options)))
	assert(
		type(options.topSection) == "table",
		sFormat("options.topSection (table) expected, got %s", type(options.topSection))
	)
	assert(
		type(options.topSection.heading) == "table",
		sFormat("options.topSection.heading (table) expected, got %s", type(options.topSection.heading))
	)
	assert(
		type(options.listItems) == "table",
		sFormat("options.listItems (table) expected, got %s", type(options.listItems))
	)

	local y = options.y or 0
	local screenWidthFifth = (dWidth / 5)
	local side = options.side or "left"
	local width = options.width or (dWidth - screenWidthFifth)
	local height = options.height or dHeight
	local onOpening = options.onOpening
	local onOpened = options.onOpened
	local onClosing = options.onClosing
	local onClosed = options.onClosed
	local parentGroup = options.parentGroup or display.currentStage
	local group = display.newGroup()
	local background = nil
	local listItemTableView = nil
	local topSection = {
		background = nil,
		icon = nil,
		heading = nil,
		subHeading = nil
	}

	local function createBackgroundOptions(params, name)
		return {
			fill = params and params.fill or utils:colorFromRGB(48, 48, 48),
			fillEffect = params and params.fillEffect,
			stroke = params and params.stroke or {0, 0, 0},
			strokeWidth = params and params.strokeWidth or 0,
			strokeEffect = params and params.strokeEffect,
			rounding = params and params.rounding or false,
			cornerRadius = params and params.cornerRadius or 0
		}
	end

	local function createTextOptions(params, name)
		return {
			text = params and params.text,
			font = params and params.font or native.systemFontBold,
			fontSize = params and params.fontSize or 18,
			fontColor = params and params.fontColor or {1, 1, 1},
			align = params and params.align or "center",
			widthPadding = params and params.widthPadding or 0,
			heightPadding = params and params.heightPadding or 0
		}
	end

	local function createIconOptions(params, name)
		return {
			filePath = params and params.filePath,
			baseDirectory = params and params.baseDirectory or system.ResourceDirectory,
			centerIconHorizontally = params and params.centerHorizontally or false,
			width = params and params.width or (width / 4),
			height = params and params.height or (width / 4),
			xOffset = params and params.xOffset or 10,
			yOffset = params and params.yOffset or 10
		}
	end

	local function dispatchSlidingMenuEvent(phase)
		local slidingMenuEvent = {
			name = "slidingMenu",
			phase = phase
		}

		Runtime:dispatchEvent(slidingMenuEvent)
	end

	local backgroundOptions = createBackgroundOptions(options.background, backgroundParamName)
	local topSectionOptions = {
		background = createBackgroundOptions(options.topSection.background, topSectionParamName.background),
		icon = createIconOptions(options.topSection.icon, topSectionParamName.icon),
		heading = createTextOptions(options.topSection.heading, topSectionParamName.heading),
		subHeading = createTextOptions(options.topSection.subHeading, topSectionParamName.subHeading)
	}
	-- some options need to be manually defined due to the generic nature of the option creator functions
	topSectionOptions.background.fill = options.topSection.background.fill or utils:colorFromRGB(51, 181, 229)
	topSectionOptions.heading.placeUnderIcon = options.topSection.icon.placeUnderIcon or false
	local listItemOptions = {}

	for i = 1, #options.listItems do
		listItemOptions[i] = {
			label = createTextOptions(options.listItems[i].label, sFormat("%s[%d]", listItemParamName.label, i)),
			icon = createIconOptions(options.listItems[i].icon, sFormat("%s[%d]", listItemParamName.icon, i)),
			bottomSeparatorLine = options.listItems[i].bottomSeparatorLine,
			onPress = options.listItems[i].onPress
		}
	end

	-- group members
	group.isOpen = false
	group.isTransitioning = false

	-- group methods

	function group:show(options, side)
		local opt = options or {}
		local targetX = side == "right" and (-width / 2) or (width / 2)
		self.isTransitioning = true

		dispatchSlidingMenuEvent("opening")

		if (type(onOpening) == "function") then
			onOpening()
		end

		local targetOptions = {
			x = targetX,
			time = opt.time or 500,
			transition = opt.transition or easing.inOutQuad,
			onComplete = function()
				self.isOpen = true
				self.isTransitioning = false

				if (type(onOpened) == "function") then
					onOpened()
				end
			end
		}

		transition.to(self, targetOptions)
	end

	function group:hide(options, side)
		local opt = options or {}
		local targetX = side == "right" and (width / 2) or (-width / 2)
		self.isTransitioning = true

		dispatchSlidingMenuEvent("closing")

		if (type(onClosing) == "function") then
			onClosing()
		end

		local targetOptions = {
			x = targetX,
			time = opt.time or 500,
			transition = opt.transition or easing.inOutQuad,
			onComplete = function()
				self.isOpen = false
				self.isTransitioning = false
				listItemTableView:reloadData()

				if (type(onClosed) == "function") then
					onClosed()
				end
			end
		}

		transition.to(self, targetOptions)
	end

	local function touch(event)
		local phase = event.phase
		local target = group
		local targetHalfWidth = (target.contentWidth * 0.5)

		-- if we started the touch outside of the sliding menu don't do anything (not doing this breaks the swiping)
		if (phase == "moved" and event.xStart > width) then
			return false
		end

		if (target.isOpen and not target.isTransitioning) then
			if (phase == "began" or phase == "moved") then
				if (target.isRow) then
					local dx = event.x - event.xStart
					local dy = event.y - event.yStart
					local moveThresh = 20

					if (dy > 0) then
						listItemTableView:setIsLocked(true)
						listItemTableView:scrollToIndex(1, 150)
					else
						listItemTableView:setIsLocked(false)
					end

					if (dx > moveThresh) then
						listItemTableView._view.y = 0
					end
				end

				target.x = mFloor(mMin(targetHalfWidth + (event.x - event.xStart), width / 2))
			elseif (phase == "ended" or phase == "canceled") then
				listItemTableView:setIsLocked(false)
				listItemTableView:reloadData()

				if (target.x + (targetHalfWidth / 1.25) >= targetHalfWidth) then
					target:show()
				else
					target.closeInitiated = true
					target:hide()
				end
			end
		end

		return true
	end

	local function topNavigationBarEvent(event)
		local phase = event.phase

		if (group.isOpen and phase == "began") then
			group:hide()
		end
	end

	-- create and setup the background
	if (backgroundOptions.rounding) then
		background = display.newRoundedRect(group, 0, 0, width, height, backgroundOptions.cornerRadius)
	else
		background = display.newRect(group, 0, 0, width, height)
	end

	background.fill = backgroundOptions.fill
	background.fill.effect = backgroundOptions.fillEffect
	background.stroke = backgroundOptions.stroke
	background.strokeWidth = backgroundOptions.strokeWidth
	background.strokeEffect = backgroundOptions.strokeEffect

	-- create and setup the top section background
	topSection.background = display.newRect(group, 0, 0, width, height / 4)
	topSection.background.x = background.x
	topSection.background.y =
		(background.y - (background.contentHeight * 0.5) + (topSection.background.contentHeight * 0.5))
	topSection.background.fill = topSectionOptions.background.fill
	topSection.background.fill.effect = topSectionOptions.fillEffect
	topSection.background.stroke = topSectionOptions.background.stroke
	topSection.background.strokeWidth = topSectionOptions.background.strokeWidth
	topSection.background.strokeEffect = topSectionOptions.background.strokeEffect
	topSection.background:addEventListener("touch", touch)

	-- create and setup the top section icon
	utils:checkFileExists(topSectionOptions.icon.filePath, topSectionOptions.icon.baseDirectory, "options.topSection.icon")
	topSection.icon =
		display.newImageRect(
		group,
		topSectionOptions.icon.filePath,
		topSectionOptions.icon.baseDirectory,
		topSectionOptions.icon.width,
		topSectionOptions.icon.height
	)
	topSection.icon.x =
		(background.x - (background.contentWidth * 0.5) + (topSection.icon.contentWidth * 0.5) +
		topSectionOptions.icon.xOffset)
	topSection.icon.y =
		(background.y - (background.contentHeight * 0.5) + (topSection.icon.contentHeight * 0.5) +
		topSectionOptions.icon.yOffset)

	-- place the top section icon in the center if requested
	if (topSectionOptions.icon.centerIconHorizontally) then
		topSection.icon.x = background.x
	end

	-- create the top section heading
	topSection.heading =
		display.newText(
		{
			parent = group,
			text = topSectionOptions.heading.text,
			font = topSectionOptions.heading.font,
			fontSize = topSectionOptions.heading.fontSize,
			align = topSectionOptions.heading.align
		}
	)
	topSection.heading.x =
		(topSection.icon.x + topSection.icon.contentWidth + (topSection.heading.contentWidth * 0.5) +
		topSectionOptions.heading.widthPadding)
	topSection.heading.y =
		(topSection.icon.y - (topSection.icon.contentHeight * 0.5) + (topSection.heading.contentHeight * 0.5) +
		topSectionOptions.heading.heightPadding)
	topSection.heading:setFillColor(uPack(topSectionOptions.heading.fontColor))

	-- change position of heading text if placeUnderIcon is set
	if (topSectionOptions.heading.placeUnderIcon) then
		topSection.heading.x = (topSection.icon.x)
		topSection.heading.y =
			(topSection.icon.y + (topSection.icon.contentHeight * 0.5) + (topSection.heading.contentHeight * 0.5) +
			topSectionOptions.heading.heightPadding +
			10)
	end

	-- create the top section sub-heading
	if (options.topSection.subHeading) then
		topSection.subHeading =
			display.newText(
			{
				parent = group,
				width = not topSectionOptions.heading.placeUnderIcon and
					width - topSectionOptions.icon.width - topSectionOptions.icon.xOffset - topSectionOptions.icon.xOffset - 10,
				text = topSectionOptions.subHeading.text,
				font = topSectionOptions.subHeading.font,
				fontSize = topSectionOptions.subHeading.fontSize,
				align = topSectionOptions.subHeading.align
			}
		)
		topSection.subHeading.x = topSection.heading.x + topSectionOptions.subHeading.widthPadding
		topSection.subHeading.y =
			topSection.heading.y + topSection.subHeading.contentHeight + topSectionOptions.subHeading.heightPadding
		topSection.subHeading:setFillColor(uPack(topSectionOptions.subHeading.fontColor))
	end

	-- create the list item tableView
	listItemTableView =
		widget.newTableView(
		{
			left = -(background.contentWidth * 0.5),
			top = (topSection.background.y + (topSection.background.contentHeight * 0.5)),
			width = background.contentWidth,
			height = (dHeight - (topSection.background.y + (topSection.background.contentHeight * 0.5))),
			isBounceEnabled = false,
			scrollStopThreshold = 1,
			backgroundColor = backgroundOptions.fill,
			onRowRender = function(event)
				local phase = event.phase
				local row = event.row
				local rowContentHeight = row.contentHeight
				local params = row.params
				local labelParams = params.label
				local iconParams = params.icon
				event.row.isRow = true

				utils:checkFileExists(
					iconParams.filePath,
					iconParams.baseDirectory,
					sFormat("%s[%d].%s", "listItems.icon", row.index, "filePath")
				)
				local icon =
					display.newImageRect(row, iconParams.filePath, iconParams.baseDirectory, iconParams.width, iconParams.height)
				icon.x = 15 + iconParams.xOffset
				icon.y = ((rowContentHeight * 0.5) + iconParams.yOffset - 10)

				local labelText =
					display.newText(
					{
						text = labelParams.text,
						font = labelParams.font,
						fontSize = labelParams.fontSize,
						fontColor = labelParams.fontColor,
						align = labelParams.align
					}
				)
				labelText.anchorX = 0
				labelText.x = icon.x + icon.contentWidth + labelParams.widthPadding
				labelText.y = (rowContentHeight * 0.5) + labelParams.heightPadding
				row:insert(labelText)

				row:addEventListener(
					"tap",
					function(event)
						if (type(params.onPress) == "function") then
							params.onPress(event)
						end

						return true
					end
				)
				row:addEventListener("touch", touch)
			end
		}
	)
	group:insert(listItemTableView)
	listItemTableView._view._background:addEventListener("touch", touch)

	-- populate the list item tableView
	for i = 1, #listItemOptions do
		local default = {
			default = backgroundOptions.fill,
			over = {1, 1, 1, 0.1}
		}
		local lineColor = {
			backgroundOptions.fill[1] + 10,
			backgroundOptions.fill[2] + 10,
			backgroundOptions.fill[3] + 10,
			0.2
		}

		listItemTableView:insertRow(
			{
				rowHeight = 40,
				rowColor = default,
				lineColor = listItemOptions[i].bottomSeparatorLine and lineColor or default.default,
				params = {
					label = {
						text = listItemOptions[i].label.text,
						font = listItemOptions[i].label.font,
						fontSize = listItemOptions[i].label.fontSize,
						fontColor = listItemOptions[i].label.fontColor,
						align = listItemOptions[i].label.align,
						widthPadding = listItemOptions[i].label.widthPadding,
						heightPadding = listItemOptions[i].label.heightPadding
					},
					icon = {
						filePath = listItemOptions[i].icon.filePath,
						baseDirectory = listItemOptions[i].icon.baseDirectory,
						width = listItemOptions[i].icon.width,
						height = listItemOptions[i].icon.height,
						xOffset = listItemOptions[i].icon.xOffset,
						yOffset = listItemOptions[i].icon.yOffset
					},
					onPress = listItemOptions[i].onPress
				}
			}
		)
	end

	Runtime:addEventListener("topNavigationBar", topNavigationBarEvent)
	parentGroup:insert(group)

	-- set the groups position
	group.anchorChildren = false
	group.anchorX = 0.5
	group.anchorY = 0.5
	group.x = -(width / 2)
	group.y = (height / 2) + y

	return group
end

return M
