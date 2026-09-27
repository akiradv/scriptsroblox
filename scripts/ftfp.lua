local FTF_Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local FTF_SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local FTF_InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()
local FTF_Options = FTF_Fluent.Options

local FTF_Window = FTF_Fluent:CreateWindow({
    Title = "FTF Premium Hub",
    SubTitle = "by AkiraDev",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.RightShift
})

local FTF_Tabs = {
    Main = FTF_Window:AddTab({ Title = "Main", Icon = "home" }),
    Visual = FTF_Window:AddTab({ Title = "Visual", Icon = "eye" }),
    Combat = FTF_Window:AddTab({ Title = "Combat", Icon = "swords" }),
    Teleport = FTF_Window:AddTab({ Title = "Teleport", Icon = "map-pin" }),
    Player = FTF_Window:AddTab({ Title = "Player", Icon = "user" }),
    Settings = FTF_Window:AddTab({ Title = "Settings", Icon = "settings" }),
    Credits = FTF_Window:AddTab({ Title = "Credits", Icon = "info" })
}

local FTF_Players = game:GetService("Players")
local FTF_LocalPlayer = FTF_Players.LocalPlayer
local FTF_Workspace = game:GetService("Workspace")
local FTF_ReplicatedStorage = game:GetService("ReplicatedStorage")
local FTF_TeleportService = game:GetService("TeleportService")

FTF_Tabs.Main:AddParagraph({ Title = "Objective", Content = "Provide a casual, lightweight, and undetectable utility for Flee the Facility, focused on quality of life without breaking the game experience." })
FTF_Tabs.Main:AddParagraph({ Title = "Local & Security", Content = "This script is 100% Open Source and runs locally on your executor. The code is open to ensure total transparency, security, and community trust." })
FTF_Tabs.Main:AddParagraph({ Title = "Information", Content = "Version: 1.2.9 (Closet TP & Translation)\nDeveloper: AkiraDev\nLink: github.com/akiradv" })

local FTF_ActiveHighlights = { Computer = {}, FreezePod = {}, ExitDoor = {}, Closet = {}, Vent = {} }

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
    for _, category in ipairs({"Computer", "FreezePod", "ExitDoor", "Closet", "Vent"}) do
        for i = #FTF_ActiveHighlights[category], 1, -1 do
            if FTF_ActiveHighlights[category][i].Parent == obj then
                table.remove(FTF_ActiveHighlights[category], i)
            end
        end
    end
end)

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

FTF_Tabs.Visual:AddToggle("FTF_PlayerESP", { Title = "Player ESP", Description = "Red = Beast, White = Survivor", Default = false, Callback = function() FTF_UpdatePlayerESP() end })

FTF_Tabs.Visual:AddToggle("FTF_ComputerESP", { 
    Title = "Computer ESP", 
    Description = "Blue = Incomplete, Green = Complete", 
    Default = false, 
    Callback = function(state)
        if state then 
            FTF_ScanMap("Computer", function(screen)
                return FTF_GetComputerColor(screen)
            end) 
        else 
            FTF_ClearHighlights("Computer") 
        end
    end
})

FTF_Tabs.Visual:AddToggle("FTF_FreezePodESP", { Title = "Freeze Pod ESP", Description = "Cyan highlight on Freeze Pods", Default = false, Callback = function(state)
    if state then FTF_ScanMap("FreezePod", function() return Color3.fromRGB(0, 200, 255) end) else FTF_ClearHighlights("FreezePod") end
end})

FTF_Tabs.Visual:AddToggle("FTF_ExitESP", { Title = "Exit Door ESP", Description = "Yellow highlight on Exit Doors", Default = false, Callback = function(state)
    if state then FTF_ScanMap("ExitDoor", function() return Color3.fromRGB(255, 255, 0) end) else FTF_ClearHighlights("ExitDoor") end
end})

FTF_Tabs.Visual:AddToggle("FTF_ClosetESP", { Title = "Closet / Locker ESP", Description = "Brown highlight on Closets/Lockers", Default = false, Callback = function(state)
    if state then FTF_ScanMap("Closet", function() return Color3.fromRGB(139, 69, 19) end) else FTF_ClearHighlights("Closet") end
end})

FTF_Tabs.Visual:AddToggle("FTF_VentESP", { Title = "Air Vent ESP", Description = "Gray highlight on Air Vents", Default = false, Callback = function(state)
    if state then FTF_ScanMap("Vent", function() return Color3.fromRGB(128, 128, 128) end) else FTF_ClearHighlights("Vent") end
end})

local FTF_AntiFailHackEnabled = true

local old_namecall
local hook_success, hook_err = pcall(function()
    old_namecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
        local method = getnamecallmethod()
        local args = {...}
        
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

FTF_Tabs.Combat:AddToggle("FTF_AutoHack", { 
    Title = "Anti-Fail / Auto Hack", 
    Description = "Instantly completes the minigame and prevents failures", 
    Default = true, 
    Callback = function(state) 
        FTF_AntiFailHackEnabled = state
    end 
})

FTF_Tabs.Teleport:AddButton({ Title = "Teleport to Available Computer", Description = "Teleports to the nearest incomplete computer", Callback = function()
    local FTF_Char = FTF_LocalPlayer.Character
    if not FTF_Char or not FTF_Char:FindFirstChild("HumanoidRootPart") then return end
    local FTF_Pos = FTF_Char.HumanoidRootPart.Position
    local FTF_Comps = {}
    for _, obj in ipairs(FTF_Workspace:GetDescendants()) do
        if obj.Name == "ComputerTable" and obj:FindFirstChild("Screen") then
            if FTF_IsComputerIncomplete(obj.Screen) then
                table.insert(FTF_Comps, {part = obj.Screen, dist = (FTF_Pos - obj.Screen.Position).Magnitude})
            end
        end
    end
    table.sort(FTF_Comps, function(a, b) return a.dist < b.dist end)
    if #FTF_Comps > 0 then
        if FTF_Char and FTF_Char:FindFirstChild("HumanoidRootPart") then
            FTF_Char.HumanoidRootPart.CFrame = CFrame.new(FTF_Comps[1].part.Position + Vector3.new(0, 2, 2.5))
            FTF_Fluent:Notify({Title = "Teleport", Content = "Teleporting to computer!", Duration = 2})
        end
    else
        FTF_Fluent:Notify({Title = "Warning", Content = "All computers are already complete!", Duration = 2})
    end
end})

FTF_Tabs.Teleport:AddButton({ Title = "Teleport to Nearest Closet", Description = "Teleports to the closest hiding spot", Callback = function()
    local FTF_Char = FTF_LocalPlayer.Character
    if not FTF_Char or not FTF_Char:FindFirstChild("HumanoidRootPart") then return end
    local FTF_Pos = FTF_Char.HumanoidRootPart.Position
    local FTF_Closets = {}
    for _, obj in ipairs(FTF_Workspace:GetDescendants()) do
        if obj.Name == "Closet" or obj.Name == "Locker" or obj.Name == "Wardrobe" then
            local FTF_PosTarget
            if obj:IsA("Model") then
                local cframe, size = obj:GetBoundingBox()
                FTF_PosTarget = cframe.Position
            elseif obj:IsA("BasePart") then
                FTF_PosTarget = obj.Position
            else
                local FTF_Target = obj:FindFirstChildWhichIsA("BasePart")
                if FTF_Target then FTF_PosTarget = FTF_Target.Position end
            end
            
            if FTF_PosTarget then
                table.insert(FTF_Closets, {pos = FTF_PosTarget, dist = (FTF_Pos - FTF_PosTarget).Magnitude})
            end
        end
    end
    table.sort(FTF_Closets, function(a, b) return a.dist < b.dist end)
    if #FTF_Closets > 0 then
        if FTF_Char and FTF_Char:FindFirstChild("HumanoidRootPart") then
            FTF_Char.HumanoidRootPart.CFrame = CFrame.new(FTF_Closets[1].pos + Vector3.new(0, 2, 0))
            FTF_Fluent:Notify({Title = "Teleport", Content = "Teleporting to closet!", Duration = 2})
        end
    else
        FTF_Fluent:Notify({Title = "Warning", Content = "No closets found!", Duration = 2})
    end
end})

FTF_Tabs.Teleport:AddButton({ Title = "Teleport to Exit", Description = "Teleports to the closest exit door", Callback = function()
    local FTF_Char = FTF_LocalPlayer.Character
    if not FTF_Char or not FTF_Char:FindFirstChild("HumanoidRootPart") then return end
    local FTF_Pos = FTF_Char.HumanoidRootPart.Position
    local FTF_Exits = {}
    for _, obj in ipairs(FTF_Workspace:GetDescendants()) do
        if obj.Name == "ExitDoor" and obj:FindFirstChild("ExitDoorTrigger") then
            table.insert(FTF_Exits, {part = obj.ExitDoorTrigger, dist = (FTF_Pos - obj.ExitDoorTrigger.Position).Magnitude})
        end
    end
    table.sort(FTF_Exits, function(a, b) return a.dist < b.dist end)
    if #FTF_Exits > 0 then
        if FTF_Char and FTF_Char:FindFirstChild("HumanoidRootPart") then
            FTF_Char.HumanoidRootPart.CFrame = CFrame.new(FTF_Exits[1].part.Position + Vector3.new(0, 3, 0))
            FTF_Fluent:Notify({Title = "Teleport", Content = "Teleporting to exit!", Duration = 2})
        end
    end
end})

FTF_Tabs.Teleport:AddButton({ Title = "Teleport to Freeze Pod", Description = "Teleports to the closest freezer", Callback = function()
    local FTF_Char = FTF_LocalPlayer.Character
    if not FTF_Char or not FTF_Char:FindFirstChild("HumanoidRootPart") then return end
    local FTF_Pos = FTF_Char.HumanoidRootPart.Position
    local FTF_Pods = {}
    for _, obj in ipairs(FTF_Workspace:GetDescendants()) do
        if obj.Name == "FreezePod" and obj:FindFirstChild("BasePart") then
            table.insert(FTF_Pods, {part = obj.BasePart, dist = (FTF_Pos - obj.BasePart.Position).Magnitude})
        end
    end
    table.sort(FTF_Pods, function(a, b) return a.dist < b.dist end)
    if #FTF_Pods > 0 then
        if FTF_Char and FTF_Char:FindFirstChild("HumanoidRootPart") then
            FTF_Char.HumanoidRootPart.CFrame = CFrame.new(FTF_Pods[1].part.Position + Vector3.new(0, 3, 0))
            FTF_Fluent:Notify({Title = "Teleport", Content = "Teleporting to freeze pod!", Duration = 2})
        end
    end
end})

FTF_Tabs.Player:AddToggle("FTF_AntiAFK", { Title = "Anti-AFK", Description = "Prevents being kicked for inactivity", Default = true, Callback = function() end })

FTF_LocalPlayer.Idled:Connect(function()
    if FTF_Options.FTF_AntiAFK and FTF_Options.FTF_AntiAFK.Value then
        game:GetService("VirtualUser"):CaptureController()
        game:GetService("VirtualUser"):ClickButton2(Vector2.new())
    end
end)

FTF_Tabs.Player:AddButton({ 
    Title = "Rejoin Server", 
    Description = "Rejoins the EXACT same current server (JobId)", 
    Callback = function()
        FTF_Fluent:Notify({Title = "System", Content = "Reconnecting to the same server...", Duration = 2})
        task.wait(0.5)
        pcall(function()
            FTF_TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, FTF_LocalPlayer)
        end)
    end
})

FTF_Tabs.Player:AddButton({ 
    Title = "Join Another Server", 
    Description = "Attempt to join a different server", 
    Callback = function()
        FTF_TeleportService:Teleport(game.PlaceId, FTF_LocalPlayer)
    end
})

FTF_SaveManager:SetLibrary(FTF_Fluent)
FTF_InterfaceManager:SetLibrary(FTF_Fluent)
FTF_InterfaceManager:SetFolder("AkiraDev_FTF_v2")
FTF_SaveManager:SetFolder("AkiraDev_FTF_v2")
FTF_SaveManager:SetIgnoreIndexes({})
FTF_InterfaceManager:BuildInterfaceSection(FTF_Tabs.Settings)
FTF_SaveManager:BuildConfigSection(FTF_Tabs.Settings)

FTF_Tabs.Credits:AddParagraph({ Title = "Credits", Content = "Developer: AkiraDev\nGitHub: github.com/akiradv\n\nUI Library: Fluent by dawid-scripts\nRenewed: ActualMasterOogway" })

FTF_Window:SelectTab(1)

FTF_Fluent:Notify({Title = "FTF Premium Hub", Content = "Version 1.2.9 loaded successfully.", Duration = 3})