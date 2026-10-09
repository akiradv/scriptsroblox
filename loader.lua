-- scripts.dev universal loader
local URL = "https://raw.githubusercontent.com/akiradv/scriptsroblox/main/scripts.json"
local ID = game.PlaceId

local ok, raw = pcall(function() return game:HttpGet(URL) end)
if not ok or not raw or #raw == 0 then
    warn("loader: failed to fetch scripts.json")
    return
end

local scripts = nil
pcall(function()
    local data = game:GetService("HttpService"):JSONDecode(raw)
    scripts = data.scripts or {}
end)

if not scripts then
    warn("loader: invalid scripts.json")
    return
end

local map = {}
for _, s in ipairs(scripts) do
    if s.available and s.placeId and s.loadstring then
        map[s.placeId] = s
    end
end

local match = map[ID]
if match then
    local ok2, code = pcall(function() return game:HttpGet(match.loadstring:match("https?://[^'\"]+")) end)
    if ok2 and code and #code > 0 then
        loadstring(code)()
    else
        warn("loader: failed to download " .. match.name)
    end
    return
end

local CoreGui = game:GetService("CoreGui")
local TS = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")

for _, c in ipairs(CoreGui:GetChildren()) do
    if c.Name == "loader_unsupported" then c:Destroy() end
end

local gui = Instance.new("ScreenGui")
gui.Name = "loader_unsupported"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = 999
gui.IgnoreGuiInset = true
gui.Parent = CoreGui

local bg = Instance.new("Frame")
bg.Size = UDim2.fromScale(1, 1)
bg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
bg.BackgroundTransparency = 0.55
bg.BorderSizePixel = 0
bg.Parent = gui


local card = Instance.new("Frame")
card.Size = UDim2.fromOffset(360, 0)
card.AutomaticSize = Enum.AutomaticSize.Y
card.AnchorPoint = Vector2.new(0.5, 0.5)
card.Position = UDim2.fromScale(0.5, 0.5)
card.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
card.BorderSizePixel = 0
card.Parent = gui

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(40, 40, 40)
stroke.Thickness = 1
stroke.Parent = card

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 6)
corner.Parent = card

local pad = Instance.new("UIPadding")
pad.PaddingLeft = UDim.new(0, 20)
pad.PaddingRight = UDim.new(0, 20)
pad.PaddingTop = UDim.new(0, 18)
pad.PaddingBottom = UDim.new(0, 18)
pad.Parent = card

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 10)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = card

local title = Instance.new("TextLabel")
title.LayoutOrder = 1
title.Size = UDim2.fromOffset(0, 18)
title.AutomaticSize = Enum.AutomaticSize.X
title.BackgroundTransparency = 1
title.Text = "game not supported"
title.Font = Enum.Font.GothamMedium
title.TextSize = 13
title.TextColor3 = Color3.fromRGB(225, 225, 225)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = card

local sub = Instance.new("TextLabel")
sub.LayoutOrder = 2
sub.Size = UDim2.new(1, 0, 0, 14)
sub.BackgroundTransparency = 1
sub.Text = "this place isn't on our supported list yet."
sub.Font = Enum.Font.Gotham
sub.TextSize = 11
sub.TextColor3 = Color3.fromRGB(130, 130, 130)
sub.TextXAlignment = Enum.TextXAlignment.Left
sub.Parent = card

local pidBox = Instance.new("Frame")
pidBox.LayoutOrder = 3
pidBox.Size = UDim2.new(1, 0, 0, 28)
pidBox.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
pidBox.BorderSizePixel = 0
pidBox.Parent = card

local pidCorner = Instance.new("UICorner")
pidCorner.CornerRadius = UDim.new(0, 4)
pidCorner.Parent = pidBox

local pidText = Instance.new("TextLabel")
pidText.Size = UDim2.fromScale(1, 1)
pidText.BackgroundTransparency = 1
pidText.Text = "placeId: " .. tostring(ID)
pidText.Font = Enum.Font.Code
pidText.TextSize = 11
pidText.TextColor3 = Color3.fromRGB(160, 160, 160)
pidText.TextXAlignment = Enum.TextXAlignment.Center
pidText.Parent = pidBox

local div = Instance.new("Frame")
div.LayoutOrder = 4
div.Size = UDim2.new(1, 0, 0, 1)
div.BackgroundColor3 = Color3.fromRGB(36, 36, 36)
div.BorderSizePixel = 0
div.Parent = card

local supLabel = Instance.new("TextLabel")
supLabel.LayoutOrder = 5
supLabel.Size = UDim2.fromOffset(0, 12)
supLabel.AutomaticSize = Enum.AutomaticSize.X
supLabel.BackgroundTransparency = 1
supLabel.Text = "supported"
supLabel.Font = Enum.Font.GothamMedium
supLabel.TextSize = 10
supLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
supLabel.TextXAlignment = Enum.TextXAlignment.Left
supLabel.Parent = card

local list = Instance.new("Frame")
list.LayoutOrder = 6
list.Size = UDim2.new(1, 0, 0, 0)
list.AutomaticSize = Enum.AutomaticSize.Y
list.BackgroundTransparency = 1
list.Parent = card

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 6)
listLayout.Parent = list

local count = 0
for placeId, s in pairs(map) do
    count = count + 1
    local item = Instance.new("Frame")
    item.Size = UDim2.new(1, 0, 0, 18)
    item.BackgroundTransparency = 1
    item.Parent = list

    local dot = Instance.new("Frame")
    dot.Size = UDim2.fromOffset(4, 4)
    dot.AnchorPoint = Vector2.new(0, 0.5)
    dot.Position = UDim2.new(0, 2, 0.5, 0)
    dot.BackgroundColor3 = Color3.fromRGB(90, 90, 90)
    dot.BorderSizePixel = 0
    dot.Parent = item
    local dc = Instance.new("UICorner"); dc.CornerRadius = UDim.new(1, 0); dc.Parent = dot

    local name = Instance.new("TextLabel")
    name.Size = UDim2.new(1, -80, 1, 0)
    name.Position = UDim2.fromOffset(14, 0)
    name.BackgroundTransparency = 1
    name.Text = s.name
    name.Font = Enum.Font.Gotham
    name.TextSize = 11
    name.TextColor3 = Color3.fromRGB(200, 200, 200)
    name.TextXAlignment = Enum.TextXAlignment.Left
    name.TextTruncate = Enum.TextTruncate.AtEnd
    name.Parent = item

    local gameName = Instance.new("TextLabel")
    gameName.Size = UDim2.new(0, 70, 1, 0)
    gameName.Position = UDim2.new(1, -70, 0, 0)
    gameName.BackgroundTransparency = 1
    gameName.Text = s.game
    gameName.Font = Enum.Font.Gotham
    gameName.TextSize = 10
    gameName.TextColor3 = Color3.fromRGB(110, 110, 110)
    gameName.TextXAlignment = Enum.TextXAlignment.Right
    gameName.TextTruncate = Enum.TextTruncate.AtEnd
    gameName.Parent = item
end

if count == 0 then
    local empty = Instance.new("TextLabel")
    empty.Size = UDim2.new(1, 0, 0, 16)
    empty.BackgroundTransparency = 1
    empty.Text = "no scripts available yet"
    empty.Font = Enum.Font.Gotham
    empty.TextSize = 11
    empty.TextColor3 = Color3.fromRGB(100, 100, 100)
    empty.TextXAlignment = Enum.TextXAlignment.Left
    empty.Parent = list
end

local footer = Instance.new("Frame")
footer.LayoutOrder = 7
footer.Size = UDim2.new(1, 0, 0, 14)
footer.BackgroundTransparency = 1
footer.Parent = card

local footText = Instance.new("TextLabel")
footText.Size = UDim2.fromScale(1, 1)
footText.BackgroundTransparency = 1
footText.Text = "scripts.dev · auto-close in 6s"
footText.Font = Enum.Font.Gotham
footText.TextSize = 10
footText.TextColor3 = Color3.fromRGB(80, 80, 80)
footText.TextXAlignment = Enum.TextXAlignment.Center
footText.Parent = footer

card.BackgroundTransparency = 1
stroke.Transparency = 1
bg.BackgroundTransparency = 1
TS:Create(bg, TweenInfo.new(0.25), { BackgroundTransparency = 0.55 }):Play()
TS:Create(card, TweenInfo.new(0.25), { BackgroundTransparency = 0 }):Play()
TS:Create(stroke, TweenInfo.new(0.25), { Transparency = 0 }):Play()

UIS.InputBegan:Connect(function(i, p)
    if p then return end
    if i.KeyCode == Enum.KeyCode.Escape or i.UserInputType == Enum.UserInputType.MouseButton2 then
        TS:Create(bg, TweenInfo.new(0.2), { BackgroundTransparency = 1 }):Play()
        TS:Create(card, TweenInfo.new(0.2), { BackgroundTransparency = 1 }):Play()
        TS:Create(stroke, TweenInfo.new(0.2), { Transparency = 1 }):Play()
        task.delay(0.22, function() gui:Destroy() end)
    end
end)


task.delay(6, function()
    if gui.Parent then
        TS:Create(bg, TweenInfo.new(0.25), { BackgroundTransparency = 1 }):Play()
        TS:Create(card, TweenInfo.new(0.25), { BackgroundTransparency = 1 }):Play()
        TS:Create(stroke, TweenInfo.new(0.25), { Transparency = 1 }):Play()
        task.delay(0.27, function() if gui.Parent then gui:Destroy() end end)
    end
end)