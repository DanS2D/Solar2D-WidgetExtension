local M = {}
local sFormat = string.format
local isAndroid = (system.getInfo("platform") == "android")
local isSimulator = (system.getInfo("environment") == "simulator")

function M:colorFromRGB(r, g, b)
	return {r / 255, g / 255, b / 255}
end

function M:checkFileExists(filePath, baseDir, key)
	local path = system.pathForFile(filePath, baseDir)
	local errorMessage = sFormat("%s file not found at path %s", key, filePath)

	-- we can't check for file existence in the resourceDirectory on Android, so just return exists
	if (baseDir == system.ResourceDirectory and isAndroid and not isSimulator) then
		return true
	end

	if (path == nil) then
		return error(errorMessage)
	end

	local file = io.open(path, "r")
	local exists = false

	if (file) then
		exists = true
		io.close(file)
	else
		return error(errorMessage)
	end

	return exists
end

return M
