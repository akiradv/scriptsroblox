local FTF_Eazy = loadstring(game:HttpGet("https://raw.githubusercontent.com/akiradv/eazyuilib/refs/heads/main/eazyui.lua"))()
local FTF_Version = "1.3.8"
local FTF_UIVersion = FTF_Eazy.Version

local FTF_Players = game:GetService("Players")
local FTF_LocalPlayer = FTF_Players.LocalPlayer
local FTF_Workspace = game:GetService("Workspace")
local FTF_ReplicatedStorage = game:GetService("ReplicatedStorage")
local FTF_TeleportService = game:GetService("TeleportService")

local FTF_Options = {}
local FTF_ActiveHighlights = { Computer = {}, FreezePod = {}, ExitDoor = {}, Closet = {}, Vent = {} }
local FTF_AntiFailHackEnabled = true

local FTF_Window = FTF_Eazy:CreateWindow({
    Name = "FTF Hub",
    SubTitle = "by AkiraDev",
    Size = UDim2.fromOffset(580, 460),
    MinimizeKey = Enum.KeyCode.RightShift,
    ConfigId = "FTF_Premium",
    LoadingTitle = "FTF Hub",
    LoadingSubtitle = "Loading FTF Hub...",
    Discord = {
        Enabled = true,
        Invite = "9VE4PXFDSg",
    },
    AutoLoad = true,
    NotifyPosition = "BottomRight",
})

local FTF_Tabs = {
    Main = FTF_Window:AddTab({ Title = "Main", Icon = "house" }),
    Visual = FTF_Window:AddTab({ Title = "Visual", Icon = "eye" }),
    Combat = FTF_Window:AddTab({ Title = "Combat", Icon = "target" }),
    Teleport = FTF_Window:AddTab({ Title = "Teleport", Icon = "navigation" }),
    Player = FTF_Window:AddTab({ Title = "Player", Icon = "user" }),
    Settings = FTF_Window:AddTab({ Title = "Settings", Icon = "settings" }),
    Credits = FTF_Window:AddTab({ Title = "Credits", Icon = "info" })
}

FTF_Tabs.Main:AddSection({ Title = "about" })
FTF_Tabs.Main:AddParagraph({
    Title = "Objective",
    Content = "Provide a casual, lightweight, and undetectable utility for Flee the Facility, focused on quality of life without breaking the game experience."
})
FTF_Tabs.Main:AddParagraph({
    Title = "Local & Security",
    Content = "This script is 100% Open Source and runs locally on your executor. The code is open to ensure total transparency, security, and community trust."
})
FTF_Tabs.Main:AddSection({ Title = "information" })
FTF_Tabs.Main:AddParagraph({
    Title = "Version Info",
    Content = "Script: v" .. FTF_Version .. "\nUI Library: Eazy UI " .. FTF_UIVersion .. "\nDeveloper: AkiraDev\nGitHub: github.com/akiradv"
})
FTF_Tabs.Main:AddSection({ Title = "community" })
FTF_Tabs.Main:AddButton({
    Title = "Join Discord",
    Description = "Copy the invite link to join the server",
    ButtonText = "Copy Link",
    Callback = function()
        local inviteUrl = "https://discord.gg/9VE4PXFDSg"
        if setclipboard then
            setclipboard(inviteUrl)
            FTF_Eazy:Notify({ Title = "Discord", Content = "Invite link copied to clipboard!", Duration = 3, Style = "Success" })
        else
            FTF_Eazy:Notify({ Title = "Discord", Content = "Copy this link: " .. inviteUrl, Duration = 10, Style = "Info" })
        end
    end
})

local function FTF_ClearHighlights(category)
    for _, hl in ipairs(FTF_ActiveHighlights[category]) do
        if hl then hl:Destroy() end
    end
    FTF_ActiveHighlights[category] = {}
end

local function FTF_ApplyHighlight(obj, category, color)
    local FTF_Prefix = "FTF_" .. category .. "_HL"
    if obj:FindFirstChild(FTF_Prefix) then return end
    local FTF_HL = Instance.new("Highlight")
    FTF_HL.Name = FTF_Prefix
    FTF_HL.Adornee = obj
    FTF_HL.FillColor = color
    FTF_HL.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    FTF_HL.Parent = obj
    table.insert(FTF_ActiveHighlights[category], FTF_HL)
end

local function FTF_GetComputerColor(screen)
    if not screen then return Color3.fromRGB(0, 255, 0) end
    if screen.BrickColor == BrickColor.new("Bright blue") then
        return Color3.fromRGB(0, 150, 255)
    elseif screen.BrickColor == BrickColor.new("Dark green") then
        return Color3.fromRGB(0, 255, 0)
    end
    local FTF_C = screen.Color
    return (FTF_C.B > 0.5 and FTF_C.R < 0.5) and Color3.fromRGB(0, 150, 255) or Color3.fromRGB(0, 255, 0)
end

local function FTF_IsComputerIncomplete(screen)
    if not screen then return false end
    if screen.BrickColor == BrickColor.new("Bright blue") then return true end
    local FTF_C = screen.Color
    return (FTF_C.B > 0.5 and FTF_C.R < 0.5)
end

local function FTF_ScanMap(category, colorFunc)
    FTF_ClearHighlights(category)
    for _, obj in ipairs(FTF_Workspace:GetDescendants()) do
        if category == "Computer" and obj.Name == "ComputerTable" then
            local FTF_Screen = obj:FindFirstChild("Screen")
            local FTF_Color = FTF_GetComputerColor(FTF_Screen)
            FTF_ApplyHighlight(obj, category, FTF_Color)
        elseif category == "FreezePod" and obj.Name == "FreezePod" then
            FTF_ApplyHighlight(obj, category, colorFunc())
        elseif category == "ExitDoor" and obj.Name == "ExitDoor" then
            FTF_ApplyHighlight(obj, category, colorFunc())
        elseif category == "Closet" and (obj.Name == "Closet" or obj.Name == "Locker" or obj.Name == "Wardrobe") then
            FTF_ApplyHighlight(obj, category, colorFunc())
        elseif category == "Vent" and (obj.Name == "AirVent" or obj.Name == "Vent") then
            FTF_ApplyHighlight(obj, category, colorFunc())
        end
    end
end

local function FTF_ApplyPlayerHighlight(player)
    if player == FTF_LocalPlayer or not player.Character then return end
    local FTF_Char = player.Character
    local FTF_HL = FTF_Char:FindFirstChild("FTF_HL")
    if not FTF_HL then
        FTF_HL = Instance.new("Highlight")
        FTF_HL.Name = "FTF_HL"
        FTF_HL.Adornee = FTF_Char
        FTF_HL.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        FTF_HL.Parent = FTF_Char
    end
    local FTF_IsBeast = false
    local FTF_Stats = player:FindFirstChild("TempPlayerStatsModule") or FTF_Char:FindFirstChild("TempPlayerStatsModule")
    if FTF_Stats and FTF_Stats:FindFirstChild("IsBeast") then
        FTF_IsBeast = FTF_Stats.IsBeast.Value
    end
    if FTF_IsBeast then
        FTF_HL.FillColor = Color3.fromRGB(255, 0, 0)
        FTF_HL.OutlineColor = Color3.fromRGB(255, 0, 0)
    else
        FTF_HL.FillColor = Color3.fromRGB(255, 255, 255)
        FTF_HL.OutlineColor = Color3.fromRGB(255, 255, 255)
    end
end

local function FTF_UpdatePlayerESP()
    if FTF_Options.FTF_PlayerESP and FTF_Options.FTF_PlayerESP.Value then
        for _, player in ipairs(FTF_Players:GetPlayers()) do
            FTF_ApplyPlayerHighlight(player)
        end
    else
        for _, player in ipairs(FTF_Players:GetPlayers()) do
            if player.Character then
                local FTF_HL = player.Character:FindFirstChild("FTF_HL")
                if FTF_HL then FTF_HL:Destroy() end
            end
        end
    end
end

task.spawn(function()
    while task.wait(2) do
        if FTF_Options.FTF_ComputerESP and FTF_Options.FTF_ComputerESP.Value then
            for _, hl in ipairs(FTF_ActiveHighlights.Computer) do
                if hl and hl.Parent then
                    local FTF_Screen = hl.Parent:FindFirstChild("Screen")
                    if FTF_Screen and FTF_Screen:IsA("BasePart") then
                        hl.FillColor = FTF_GetComputerColor(FTF_Screen)
                    end
                end
            end
        end
    end
end)

FTF_Workspace.DescendantAdded:Connect(function(obj)
    if FTF_Options.FTF_ComputerESP and FTF_Options.FTF_ComputerESP.Value and obj.Name == "ComputerTable" then
        local FTF_Screen = obj:FindFirstChild("Screen")
        local FTF_Color = FTF_GetComputerColor(FTF_Screen)
        FTF_ApplyHighlight(obj, "Computer", FTF_Color)
    elseif FTF_Options.FTF_FreezePodESP and FTF_Options.FTF_FreezePodESP.Value and obj.Name == "FreezePod" then
        FTF_ApplyHighlight(obj, "FreezePod", Color3.fromRGB(0, 200, 255))
    elseif FTF_Options.FTF_ExitESP and FTF_Options.FTF_ExitESP.Value and obj.Name == "ExitDoor" then
        FTF_ApplyHighlight(obj, "ExitDoor", Color3.fromRGB(255, 255, 0))
    elseif FTF_Options.FTF_ClosetESP and FTF_Options.FTF_ClosetESP.Value and (obj.Name == "Closet" or obj.Name == "Locker" or obj.Name == "Wardrobe") then
        FTF_ApplyHighlight(obj, "Closet", Color3.fromRGB(139, 69, 19))
    elseif FTF_Options.FTF_VentESP and FTF_Options.FTF_VentESP.Value and (obj.Name == "AirVent" or obj.Name == "Vent") then
        FTF_ApplyHighlight(obj, "Vent", Color3.fromRGB(128, 128, 128))
    end
end)

FTF_Workspace.DescendantRemoving:Connect(function(obj)
    for _, category in ipairs({ "Computer", "FreezePod", "ExitDoor", "Closet", "Vent" }) do
        for i = #FTF_ActiveHighlights[category], 1, -1 do
            if FTF_ActiveHighlights[category][i].Parent == obj then
                table.remove(FTF_ActiveHighlights[category], i)
            end
        end
    end
end)

FTF_Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        task.wait(1.5)
        if FTF_Options.FTF_PlayerESP and FTF_Options.FTF_PlayerESP.Value then
            FTF_ApplyPlayerHighlight(player)
        end
    end)
end)

task.spawn(function()
    while task.wait(2) do
        if FTF_Options.FTF_PlayerESP and FTF_Options.FTF_PlayerESP.Value then
            for _, player in ipairs(FTF_Players:GetPlayers()) do
                if player ~= FTF_LocalPlayer and player.Character then
                    local FTF_HL = player.Character:FindFirstChild("FTF_HL")
                    if FTF_HL then
                        local FTF_IsBeast = false
                        local FTF_Stats = player:FindFirstChild("TempPlayerStatsModule") or player.Character:FindFirstChild("TempPlayerStatsModule")
                        if FTF_Stats and FTF_Stats:FindFirstChild("IsBeast") then
                            FTF_IsBeast = FTF_Stats.IsBeast.Value
                        end
                        if FTF_IsBeast then
                            FTF_HL.FillColor = Color3.fromRGB(255, 0, 0)
                            FTF_HL.OutlineColor = Color3.fromRGB(255, 0, 0)
                        else
                            FTF_HL.FillColor = Color3.fromRGB(255, 255, 255)
                            FTF_HL.OutlineColor = Color3.fromRGB(255, 255, 255)
                        end
                    end
                end
            end
        end
    end
end)

FTF_Tabs.Visual:AddSection({ Title = "player esp" })
FTF_Tabs.Visual:AddToggle({
    Title = "Player ESP",
    Description = "Highlights players (Red = Beast, White = Survivor)",
    Flag = "FTF_PlayerESP",
    Default = false,
    Callback = function(state)
        FTF_Options.FTF_PlayerESP = { Value = state }
        FTF_UpdatePlayerESP()
    end
})

FTF_Tabs.Visual:AddSection({ Title = "map esp" })
FTF_Tabs.Visual:AddToggle({
    Title = "Computer ESP",
    Description = "Highlights computers (Blue = Incomplete, Green = Complete)",
    Flag = "FTF_ComputerESP",
    Default = false,
    Callback = function(state)
        FTF_Options.FTF_ComputerESP = { Value = state }
        if state then
            FTF_ScanMap("Computer", function(screen) return FTF_GetComputerColor(screen) end)
        else
            FTF_ClearHighlights("Computer")
        end
    end
})

FTF_Tabs.Visual:AddToggle({
    Title = "Freeze Pod ESP",
    Description = "Highlights freeze pods in cyan",
    Flag = "FTF_FreezePodESP",
    Default = false,
    Callback = function(state)
        FTF_Options.FTF_FreezePodESP = { Value = state }
        if state then
            FTF_ScanMap("FreezePod", function() return Color3.fromRGB(0, 200, 255) end)
        else
            FTF_ClearHighlights("FreezePod")
        end
    end
})

FTF_Tabs.Visual:AddToggle({
    Title = "Exit Door ESP",
    Description = "Highlights exit doors in yellow",
    Flag = "FTF_ExitESP",
    Default = false,
    Callback = function(state)
        FTF_Options.FTF_ExitESP = { Value = state }
        if state then
            FTF_ScanMap("ExitDoor", function() return Color3.fromRGB(255, 255, 0) end)
        else
            FTF_ClearHighlights("ExitDoor")
        end
    end
})

FTF_Tabs.Visual:AddToggle({
    Title = "Closet / Locker ESP",
    Description = "Highlights hiding spots in brown",
    Flag = "FTF_ClosetESP",
    Default = false,
    Callback = function(state)
        FTF_Options.FTF_ClosetESP = { Value = state }
        if state then
            FTF_ScanMap("Closet", function() return Color3.fromRGB(139, 69, 19) end)
        else
            FTF_ClearHighlights("Closet")
        end
    end
})

FTF_Tabs.Visual:AddToggle({
    Title = "Air Vent ESP",
    Description = "Highlights air vents in gray",
    Flag = "FTF_VentESP",
    Default = false,
    Callback = function(state)
        FTF_Options.FTF_VentESP = { Value = state }
        if state then
            FTF_ScanMap("Vent", function() return Color3.fromRGB(128, 128, 128) end)
        else
            FTF_ClearHighlights("Vent")
        end
    end
})

FTF_Tabs.Combat:AddSection({ Title = "minigame" })
FTF_Tabs.Combat:AddToggle({
    Title = "Anti-Fail / Auto Hack",
    Description = "Automatically completes minigames and prevents failures",
    Flag = "FTF_AutoHack",
    Default = true,
    Callback = function(state)
        FTF_AntiFailHackEnabled = state
    end
})

FTF_Tabs.Teleport:AddSection({ Title = "quick teleport" })
FTF_Tabs.Teleport:AddButton({
    Title = "Teleport to Available Computer",
    Description = "Teleports you to the nearest incomplete computer",
    ButtonText = "Teleport",
    Callback = function()
        local FTF_Char = FTF_LocalPlayer.Character
        if not FTF_Char or not FTF_Char:FindFirstChild("HumanoidRootPart") then return end
        local FTF_Pos = FTF_Char.HumanoidRootPart.Position
        local FTF_Comps = {}
        for _, obj in ipairs(FTF_Workspace:GetDescendants()) do
            if obj.Name == "ComputerTable" and obj:FindFirstChild("Screen") then
                if FTF_IsComputerIncomplete(obj.Screen) then
                    table.insert(FTF_Comps, { part = obj.Screen, dist = (FTF_Pos - obj.Screen.Position).Magnitude })
                end
            end
        end
        table.sort(FTF_Comps, function(a, b) return a.dist < b.dist end)
        if #FTF_Comps > 0 then
            FTF_Char.HumanoidRootPart.CFrame = CFrame.new(FTF_Comps[1].part.Position + Vector3.new(0, 2, 2.5))
            FTF_Eazy:Notify({ Title = "Teleport", Content = "Teleporting to computer!", Duration = 2, Style = "Success" })
        else
            FTF_Eazy:Notify({ Title = "Warning", Content = "All computers are already complete!", Duration = 2, Style = "Warning" })
        end
    end
})

FTF_Tabs.Teleport:AddButton({
    Title = "Teleport to Nearest Closet",
    Description = "Teleports you to the closest hiding spot",
    ButtonText = "Teleport",
    Callback = function()
        local FTF_Char = FTF_LocalPlayer.Character
        if not FTF_Char or not FTF_Char:FindFirstChild("HumanoidRootPart") then return end
        local FTF_Pos = FTF_Char.HumanoidRootPart.Position
        local FTF_Closets = {}
        for _, obj in ipairs(FTF_Workspace:GetDescendants()) do
            if obj.Name == "Closet" or obj.Name == "Locker" or obj.Name == "Wardrobe" then
                local FTF_PosTarget
                if obj:IsA("Model") then
                    local cframe = obj:GetBoundingBox()
                    FTF_PosTarget = cframe.Position
                elseif obj:IsA("BasePart") then
                    FTF_PosTarget = obj.Position
                else
                    local FTF_Target = obj:FindFirstChildWhichIsA("BasePart")
                    if FTF_Target then FTF_PosTarget = FTF_Target.Position end
                end
                if FTF_PosTarget then
                    table.insert(FTF_Closets, { pos = FTF_PosTarget, dist = (FTF_Pos - FTF_PosTarget).Magnitude })
                end
            end
        end
        table.sort(FTF_Closets, function(a, b) return a.dist < b.dist end)
        if #FTF_Closets > 0 then
            FTF_Char.HumanoidRootPart.CFrame = CFrame.new(FTF_Closets[1].pos + Vector3.new(0, 2, 0))
            FTF_Eazy:Notify({ Title = "Teleport", Content = "Teleporting to closet!", Duration = 2, Style = "Success" })
        else
            FTF_Eazy:Notify({ Title = "Warning", Content = "No closets found!", Duration = 2, Style = "Warning" })
        end
    end
})

FTF_Tabs.Teleport:AddButton({
    Title = "Teleport to Exit",
    Description = "Teleports you to the closest exit door",
    ButtonText = "Teleport",
    Callback = function()
        local FTF_Char = FTF_LocalPlayer.Character
        if not FTF_Char or not FTF_Char:FindFirstChild("HumanoidRootPart") then return end
        local FTF_Pos = FTF_Char.HumanoidRootPart.Position
        local FTF_Exits = {}
        for _, obj in ipairs(FTF_Workspace:GetDescendants()) do
            if obj.Name == "ExitDoor" and obj:FindFirstChild("ExitDoorTrigger") then
                table.insert(FTF_Exits, { part = obj.ExitDoorTrigger, dist = (FTF_Pos - obj.ExitDoorTrigger.Position).Magnitude })
            end
        end
        table.sort(FTF_Exits, function(a, b) return a.dist < b.dist end)
        if #FTF_Exits > 0 then
            FTF_Char.HumanoidRootPart.CFrame = CFrame.new(FTF_Exits[1].part.Position + Vector3.new(0, 3, 0))
            FTF_Eazy:Notify({ Title = "Teleport", Content = "Teleporting to exit!", Duration = 2, Style = "Success" })
        end
    end
})

FTF_Tabs.Teleport:AddButton({
    Title = "Teleport to Freeze Pod",
    Description = "Teleports you to the closest freezer",
    ButtonText = "Teleport",
    Callback = function()
        local FTF_Char = FTF_LocalPlayer.Character
        if not FTF_Char or not FTF_Char:FindFirstChild("HumanoidRootPart") then return end
        local FTF_Pos = FTF_Char.HumanoidRootPart.Position
        local FTF_Pods = {}
        for _, obj in ipairs(FTF_Workspace:GetDescendants()) do
            if obj.Name == "FreezePod" and obj:FindFirstChild("BasePart") then
                table.insert(FTF_Pods, { part = obj.BasePart, dist = (FTF_Pos - obj.BasePart.Position).Magnitude })
            end
        end
        table.sort(FTF_Pods, function(a, b) return a.dist < b.dist end)
        if #FTF_Pods > 0 then
            FTF_Char.HumanoidRootPart.CFrame = CFrame.new(FTF_Pods[1].part.Position + Vector3.new(0, 3, 0))
            FTF_Eazy:Notify({ Title = "Teleport", Content = "Teleporting to freeze pod!", Duration = 2, Style = "Success" })
        end
    end
})

FTF_Tabs.Player:AddSection({ Title = "utility" })
FTF_Tabs.Player:AddToggle({
    Title = "Anti-AFK",
    Description = "Prevents you from being kicked for being AFK",
    Flag = "FTF_AntiAFK",
    Default = true,
    Callback = function(state)
        FTF_Options.FTF_AntiAFK = { Value = state }
    end
})

FTF_LocalPlayer.Idled:Connect(function()
    if FTF_Options.FTF_AntiAFK and FTF_Options.FTF_AntiAFK.Value then
        game:GetService("VirtualUser"):CaptureController()
        game:GetService("VirtualUser"):ClickButton2(Vector2.new())
    end
end)

FTF_Tabs.Player:AddSection({ Title = "server" })
FTF_Tabs.Player:AddButton({
    Title = "Rejoin Server",
    Description = "Rejoins the same server you are in",
    ButtonText = "Rejoin",
    Callback = function()
        FTF_Eazy:Notify({ Title = "System", Content = "Reconnecting to the same server...", Duration = 2, Style = "Info" })
        task.wait(0.5)
        pcall(function()
            FTF_TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, FTF_LocalPlayer)
        end)
    end
})

FTF_Tabs.Player:AddButton({
    Title = "Join Another Server",
    Description = "Joins a different public server",
    ButtonText = "Join",
    Callback = function()
        FTF_TeleportService:Teleport(game.PlaceId, FTF_LocalPlayer)
    end
})

FTF_Window:BuildConfigSection(FTF_Tabs.Settings)

FTF_Tabs.Credits:AddSection({ Title = "credits" })
FTF_Tabs.Credits:AddParagraph({
    Title = "Development",
    Content = "Developer: AkiraDev\nGitHub: github.com/akiradv\nDiscord: discord.gg/9VE4PXFDSg\n\nUI Library: Eazy UI " .. FTF_UIVersion .. " by AkiraDev"
})

local old_namecall
local hook_success, hook_err = pcall(function()
    old_namecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
        local method = getnamecallmethod()
        local args = { ... }
        if FTF_AntiFailHackEnabled and not checkcaller() then
            if self.Name == "RemoteEvent" and method == "FireServer" then
                if args[1] == "SetPlayerMinigameResult" and args[2] == false then
                    args[2] = true
                    return self.FireServer(self, unpack(args))
                end
            end
        end
        return old_namecall(self, ...)
    end))
end)

task.spawn(function()
    while true do
        if FTF_AntiFailHackEnabled then
            local FTF_RE = FTF_ReplicatedStorage:FindFirstChild("RemoteEvent")
            if FTF_RE then
                pcall(function()
                    FTF_RE:FireServer("SetPlayerMinigameResult", true)
                end)
            end
        end
        task.wait(0.1)
    end
end)

FTF_Eazy:Notify({ Title = "FTF Hub", Content = "v" .. FTF_Version .. " loaded successfully", Style = "Success", Duration = 3 })