local LOADERS = {
    [893973440] = "https://akiradv.github.io/scriptsroblox/scripts/ftfp.lua",
    [3623096087] = "https://akiradv.github.io/scriptsroblox/scripts/ml.lua",
}

local ID = game.PlaceId
local URL = LOADERS[ID]

if not URL then
    local msg = "Game not supported (PlaceId: " .. ID .. ")"
    if game:GetService("CoreGui"):FindFirstChild("EazyUI") then
        warn(msg)
    else
        error(msg)
    end
    return
end

local ok, code = pcall(function()
    return game:HttpGet(URL)
end)

if not ok or not code or #code == 0 then
    error("Failed to load script for PlaceId " .. ID)
    return
end

loadstring(code)()