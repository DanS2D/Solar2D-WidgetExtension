local cwd = (...):match("(.+)%.[^%.]+$") or (...)
local widget = require("widget")
local transitionExtension = require("transition-extension.transition-extension.extension-transition")
local carousel = require(cwd .. ".carousel")
local topNavigationBar = require(cwd .. ".topNavigationBar")
local slidingMenu = require(cwd .. ".sliding-menu")

local M = {}

widget.newCarousel = carousel.new
widget.newTopNavigationBar = topNavigationBar.new
widget.newSlidingMenu = slidingMenu.new

return M
