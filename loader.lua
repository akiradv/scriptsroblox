local LOADERS = {
    [893973440] = "https://akiradv.github.io/scriptsroblox/scripts/ftfp.lua",
    [3623096087] = "https://akiradv.github.io/scriptsroblox/scripts/ml.lua",
}

local ID = game.PlaceId
local URL = LOADERS[ID]

if not URL then
    local msg = "Game not supported (PlaceId: " .. ID .. ")"
    warn(msg)
    
    local CoreGui = game:GetService("CoreGui")
    local gui = Instance.new("ScreenGui")
    gui.Name = "LoaderUnsupported"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.DisplayOrder = 999
    gui.Parent = CoreGui
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.fromOffset(420, 200)
    frame.Position = UDim2.new(0.5, -210, 0.5, -100)
    frame.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
    frame.BorderSizePixel = 0
    frame.Parent = gui
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(239, 68, 68)
    stroke.Thickness = 2
    stroke.Parent = frame
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = frame
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -40, 0, 24)
    title.Position = UDim2.fromOffset(20, 20)
    title.BackgroundTransparency = 1
    title.Text = "❌ Game Not Supported"
    title.Font = Enum.Font.GothamBold
    title.TextSize = 16
    title.TextColor3 = Color3.fromRGB(238, 238, 238)
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = frame
    
    local sub = Instance.new("TextLabel")
    sub.Size = UDim2.new(1, -40, 0, 16)
    sub.Position = UDim2.fromOffset(20, 50)
    sub.BackgroundTransparency = 1
    sub.Text = "This game is not in our supported list yet."
    sub.Font = Enum.Font.Gotham
    sub.TextSize = 12
    sub.TextColor3 = Color3.fromRGB(132, 132, 132)
    sub.TextXAlignment = Enum.TextXAlignment.Left
    sub.Parent = frame
    
    local placeId = Instance.new("TextLabel")
    placeId.Size = UDim2.new(1, -40, 0, 16)
    placeId.Position = UDim2.fromOffset(20, 74)
    placeId.BackgroundTransparency = 1
    placeId.Text = "PlaceId: " .. ID
    placeId.Font = Enum.Font.Code
    placeId.TextSize = 12
    placeId.TextColor3 = Color3.fromRGB(245, 158, 11)
    placeId.TextXAlignment = Enum.TextXAlignment.Left
    placeId.Parent = frame
    
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.fromOffset(80, 32)
    closeBtn.Position = UDim2.new(0.5, -40, 1, -50)
    closeBtn.BackgroundColor3 = Color3.fromRGB(239, 68, 68)
    closeBtn.BorderSizePixel = 0
    closeBtn.Text = "Close"
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 13
    closeBtn.TextColor3 = Color3.fromRGB(22, 22, 22)
    closeBtn.AutoButtonColor = false
    closeBtn.Parent = frame
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 6)
    closeCorner.Parent = closeBtn
    
    closeBtn.MouseButton1Click:Connect(function()
        gui:Destroy()
    end)
    
    task.delay(5, function()
        if gui.Parent then gui:Destroy() end
    end)
    
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