local FTF_Eazy = loadstring(game:HttpGet("https://raw.githubusercontent.com/akiradv/eazyuilib/refs/heads/main/eazyui.lua"))()
local FTF_Version = "1.5.3"
local FTF_UIVersion = FTF_Eazy.Version

local FTF_Players = game:GetService("Players")
local FTF_LocalPlayer = FTF_Players.LocalPlayer
local FTF_Workspace = game:GetService("Workspace")
local FTF_ReplicatedStorage = game:GetService("ReplicatedStorage")
local FTF_TeleportService = game:GetService("TeleportService")
local FTF_RunService = game:GetService("RunService")

local FTF_Options = {}
local FTF_ActiveHighlights = { Computer = {}, FreezePod = {}, ExitDoor = {}, Closet = {}, Vent = {} }
local FTF_AntiFailHackEnabled = true
local FTF_ComputerCooldown = 2.5
local FTF_LastComputerTP = 0
local FTF_LastPCComplete = 0
local FTF_MinPCInterval = 1.9
local FTF_FastCrawlSpeed = 26
local FTF_AntiRopeEnabled = false
local FTF_FastCrawlEnabled = false
local FTF_CachedPods = {}
local FTF_LastPodScan = 0

local FTF_ClosetNameKeys = { "closet", "locker", "wardrobe", "cabinet" }

local function FTF_GetHRP()
    local c = FTF_LocalPlayer.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function FTF_IsLocalBeast()
    local stats = FTF_LocalPlayer:FindFirstChild("TempPlayerStatsModule") or (FTF_LocalPlayer.Character and FTF_LocalPlayer.Character:FindFirstChild("TempPlayerStatsModule"))
    if stats and stats:FindFirstChild("IsBeast") then
        return stats.IsBeast.Value
    end
    return false
end

local function FTF_Teleport(targetCFrame)
    local hrp = FTF_GetHRP()
    if not hrp then return false end
    hrp.CFrame = targetCFrame
    hrp.Velocity = Vector3.zero
    hrp.RotVelocity = Vector3.zero
    return true
end

local function FTF_TeleportToComputer(targetCFrame)
    local now = tick()
    local sincePC = now - FTF_LastPCComplete
    if sincePC < FTF_MinPCInterval then
        local waitTime = FTF_MinPCInterval - sincePC
        FTF_Eazy:Notify({
            Title = "Cooldown",
            Content = string.format("Wait %.1fs after completing a PC.", waitTime),
            Style = "Warning",
            Duration = 2,
        })
        return false
    end
    local remaining = FTF_ComputerCooldown - (now - FTF_LastComputerTP)
    if remaining > 0 then
        FTF_Eazy:Notify({
            Title = "Cooldown",
            Content = string.format("Wait %.1fs before teleporting to another computer.", remaining),
            Style = "Warning",
            Duration = 2,
        })
        return false
    end
    local hrp = FTF_GetHRP()
    if not hrp then return false end
    task.wait(0.8)
    hrp.CFrame = targetCFrame
    hrp.Velocity = Vector3.zero
    hrp.RotVelocity = Vector3.zero
    task.wait(0.3)
    hrp.CFrame = targetCFrame
    hrp.Velocity = Vector3.zero
    FTF_LastComputerTP = tick()
    return true
end

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

local function FTF_IsComputerActuallyIncomplete(computer)
    if not computer then return false end
    local att = computer:GetAttribute("Completed") or computer:GetAttribute("Done") or computer:GetAttribute("IsComplete")
    if att ~= nil then return not att end
    local attProg = computer:GetAttribute("Progress")
    if attProg ~= nil then return attProg < 100 end
    local fire = computer:FindFirstChild("Fire") or computer:FindFirstChild("FirePart")
    if fire then
        if fire:IsA("Fire") and fire.Enabled then return true end
        if fire:IsA("BasePart") and fire.Transparency < 1 then return true end
    end
    local screen = computer:FindFirstChild("Screen")
    if not screen then return false end
    if screen.BrickColor == BrickColor.new("Bright blue") then return true end
    if screen.BrickColor == BrickColor.new("Dark green") then return false end
    local c = screen.Color
    return (c.B > 0.5 and c.R < 0.5)
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

local function FTF_GetClosetCFrame(obj)
    local cframe = nil

    for _, desc in ipairs(obj:GetDescendants()) do
        if desc:IsA("ProximityPrompt") then
            local parent = desc.Parent
            if parent and parent:IsA("BasePart") then
                cframe = parent.CFrame
                break
            elseif parent and parent:IsA("Attachment") and parent.Parent and parent.Parent:IsA("BasePart") then
                cframe = parent.Parent.CFrame
                break
            end
        end
    end

    if not cframe then
        local preferredNames = { "Handle", "Door", "Front", "Entry", "Open", "Face", "Panel" }
        for _, name in ipairs(preferredNames) do
            local part = obj:FindFirstChild(name, true)
            if part and part:IsA("BasePart") then
                cframe = part.CFrame
                break
            end
        end
    end

    if not cframe and obj:IsA("Model") and obj.PrimaryPart then
        cframe = obj.PrimaryPart.CFrame
    end
    if not cframe and obj:IsA("Model") then
        local ok, pivot = pcall(function() return obj:GetPivot() end)
        if ok and pivot then cframe = pivot end
    end
    if not cframe and obj:IsA("BasePart") then
        cframe = obj.CFrame
    end
    if not cframe then
        local base = obj:FindFirstChildWhichIsA("BasePart", true)
        if base then cframe = base.CFrame end
    end
    if not cframe then return nil end

    local look = Vector3.new(cframe.LookVector.X, 0, cframe.LookVector.Z)
    if look.Magnitude < 0.01 then look = Vector3.new(0, 0, 1) end
    look = look.Unit
    local origin = cframe.Position + Vector3.new(0, 3, 0)
    return CFrame.lookAt(origin, origin + look)
end

local function FTF_NameMatchesCloset(name)
    local n = name:lower()
    for _, k in ipairs(FTF_ClosetNameKeys) do
        if n:find(k, 1, true) then return true end
    end
    return false
end

local function FTF_FindHidePromptOwner(prompt)
    local parent = prompt.Parent
    if not parent then return nil end
    if parent:IsA("Model") then return parent end
    local cur = parent
    for _ = 1, 4 do
        cur = cur.Parent
        if not cur or cur == FTF_Workspace then break end
        if cur:IsA("Model") then return cur end
    end
    if parent:IsA("BasePart") then return parent end
    return nil
end

local function FTF_FindAllClosets()
    local result = {}
    local seen = {}

    for _, obj in ipairs(FTF_Workspace:GetDescendants()) do
        if (obj:IsA("Model") or obj:IsA("BasePart")) and not seen[obj] and FTF_NameMatchesCloset(obj.Name) then
            local cframe = FTF_GetClosetCFrame(obj)
            if cframe then
                seen[obj] = true
                table.insert(result, { model = obj, cframe = cframe })
            end
        end
    end

    if #result == 0 then
        for _, obj in ipairs(FTF_Workspace:GetDescendants()) do
            if obj:IsA("ProximityPrompt") then
                local action = (obj.ActionText or ""):lower()
                local objectText = (obj.ObjectText or ""):lower()
                local isHide = action:find("hide", 1, true) or objectText:find("locker", 1, true) or objectText:find("closet", 1, true)
                if isHide then
                    local owner = FTF_FindHidePromptOwner(obj)
                    if owner and not seen[owner] then
                        local cframe = FTF_GetClosetCFrame(owner)
                        if cframe then
                            seen[owner] = true
                            table.insert(result, { model = owner, cframe = cframe })
                        end
                    end
                end
            end
        end
    end

    return result
end

local function FTF_ScanClosetsESP()
    FTF_ClearHighlights("Closet")
    local color = Color3.fromRGB(139, 69, 19)
    local closets = FTF_FindAllClosets()
    for _, c in ipairs(closets) do
        FTF_ApplyHighlight(c.model, "Closet", color)
    end
end

local function FTF_RefreshPods()
    local now = tick()
    if now - FTF_LastPodScan < 1 then return FTF_CachedPods end
    FTF_LastPodScan = now
    local pods = {}
    for _, obj in ipairs(FTF_Workspace:GetDescendants()) do
        if obj.Name == "FreezePod" then
            local podRoot = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
            if podRoot then
                table.insert(pods, { model = obj, root = podRoot })
            end
        end
    end
    FTF_CachedPods = pods
    return pods
end

local function FTF_IsPlayerCaptured(plr)
    local char = plr.Character
    if not char then return false, nil end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp or hum.Health <= 0 then return false, nil end

    local isHeld = hrp.Anchored
    if not isHeld then
        for _, attr in ipairs({ "Frozen", "Captured", "IsFrozen", "IsCaptured", "FrozenPlayer" }) do
            local v = char:GetAttribute(attr) or hrp:GetAttribute(attr)
            if v == true then isHeld = true break end
        end
    end
    if not isHeld then
        local state = hum:GetState()
        if state == Enum.HumanoidStateType.Physics
            or state == Enum.HumanoidStateType.PlatformStanding
            or state == Enum.HumanoidStateType.GettingUp
            or state == Enum.HumanoidStateType.Ragdoll
            or hum.WalkSpeed <= 1 then
            isHeld = true
        end
    end
    if not isHeld then return false, nil end

    local pods = FTF_RefreshPods()
    for _, p in ipairs(pods) do
        local dist = (p.root.Position - hrp.Position).Magnitude
        if dist < 10 then
            return true, p.model
        end
    end
    return false, nil
end

local function FTF_FindCapturedPlayer()
    for _, plr in ipairs(FTF_Players:GetPlayers()) do
        if plr ~= FTF_LocalPlayer then
            local captured, pod = FTF_IsPlayerCaptured(plr)
            if captured then return plr, pod end
        end
    end
    return nil, nil
end

local function FTF_DoRescueFor(plr, pod)
    local hrp = FTF_GetHRP()
    if not hrp or not pod then return false end
    local podRoot = pod.PrimaryPart or pod:FindFirstChildWhichIsA("BasePart")
    if not podRoot then return false end

    local targetCF = CFrame.new(podRoot.Position + Vector3.new(0, 3, 0))
    hrp.CFrame = targetCF
    hrp.Velocity = Vector3.zero
    task.wait(0.2)
    hrp.CFrame = targetCF
    hrp.Velocity = Vector3.zero
    task.wait(0.15)

    local lookDir = podRoot.Position - hrp.Position
    if lookDir.Magnitude > 0.1 then
        lookDir = Vector3.new(lookDir.X, 0, lookDir.Z).Unit
        hrp.CFrame = CFrame.lookAt(hrp.Position, hrp.Position + lookDir)
    end

    local podTrigger = pod:FindFirstChild("PodTrigger", true)
    local didFireRemote = false
    if podTrigger then
        local ev = podTrigger:FindFirstChild("Event")
        if ev then
            local RE = FTF_ReplicatedStorage:FindFirstChild("RemoteEvent")
            if RE then
                pcall(function() RE:FireServer("Input", "Trigger", false, ev) end)
                didFireRemote = true
            end
        end
    end

    pcall(function() firetouchinterest(hrp, podRoot, 0) end)
    task.wait(0.05)
    pcall(function() firetouchinterest(hrp, podRoot, 1) end)
    task.wait(0.1)

    local firedPrompt = false
    for _, desc in ipairs(pod:GetDescendants()) do
        if desc:IsA("ProximityPrompt") then
            pcall(function() 
                desc.HoldDuration = 0
                desc.RequiresLineOfSight = false 
                fireproximityprompt(desc) 
            end)
            firedPrompt = true
        elseif desc:IsA("ClickDetector") then
            pcall(function() fireclickdetector(desc) end)
            firedPrompt = true
        end
    end

    task.wait(0.5)
    return firedPrompt or didFireRemote
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
    elseif FTF_Options.FTF_ClosetESP and FTF_Options.FTF_ClosetESP.Value then
        if (obj:IsA("Model") or obj:IsA("BasePart")) and FTF_NameMatchesCloset(obj.Name) then
            FTF_ApplyHighlight(obj, "Closet", Color3.fromRGB(139, 69, 19))
        elseif obj:IsA("ProximityPrompt") then
            local action = (obj.ActionText or ""):lower()
            local objectText = (obj.ObjectText or ""):lower()
            if action:find("hide", 1, true) or objectText:find("locker", 1, true) or objectText:find("closet", 1, true) then
                local owner = FTF_FindHidePromptOwner(obj)
                if owner then
                    FTF_ApplyHighlight(owner, "Closet", Color3.fromRGB(139, 69, 19))
                end
            end
        end
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

FTF_RunService.Heartbeat:Connect(function()
    local char = FTF_LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    if FTF_FastCrawlEnabled and hum.Health > 0 then
        local ws = hum.WalkSpeed
        local hip = hum.HipHeight
        local state = hum:GetState()
        local crawling = (ws > 0 and ws <= 12)
            or (hip > 0 and hip <= 1.5)
            or state == Enum.HumanoidStateType.Physics
            or state == Enum.HumanoidStateType.Ragdoll
            or state == Enum.HumanoidStateType.GettingUp
        if crawling and ws < FTF_FastCrawlSpeed then
            hum.WalkSpeed = FTF_FastCrawlSpeed
        end
    end

    if FTF_AntiRopeEnabled and not FTF_IsLocalBeast() then
        local state = hum:GetState()
        if state == Enum.HumanoidStateType.Physics or state == Enum.HumanoidStateType.PlatformStanding or state == Enum.HumanoidStateType.Ragdoll or state == Enum.HumanoidStateType.GettingUp then
            hum:ChangeState(Enum.HumanoidStateType.Running)
            hum.PlatformStand = false
            
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.Velocity = Vector3.zero
                hrp.RotVelocity = Vector3.zero
            end
        end

        for _, c in ipairs(char:GetDescendants()) do
            if c:IsA("RopeConstraint") or c:IsA("AlignPosition") or c:IsA("AlignOrientation") or c:IsA("BodyPosition") or c:IsA("BodyVelocity") then
                pcall(function() c:Destroy() end)
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
            FTF_ScanClosetsESP()
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

FTF_Tabs.Combat:AddSection({ Title = "protection" })
FTF_Tabs.Combat:AddToggle({
    Title = "Fast Crawl",
    Description = "Move faster while knocked down",
    Flag = "FTF_FastCrawl",
    Default = false,
    Callback = function(state)
        FTF_FastCrawlEnabled = state
    end
})

FTF_Tabs.Combat:AddSlider({
    Title = "Crawl Speed",
    Description = "WalkSpeed while crawling",
    Min = 10, Max = 60, Default = 26, Step = 1,
    Flag = "FTF_CrawlSpeed",
    Callback = function(v)
        FTF_FastCrawlSpeed = v
    end
})

FTF_Tabs.Combat:AddToggle({
    Title = "Anti Knockdown / Anti-Rope",
    Description = "Prevents the beast from knocking you down and breaks ropes",
    Flag = "FTF_AntiRope",
    Default = false,
    Callback = function(state)
        FTF_AntiRopeEnabled = state
    end
})

FTF_Tabs.Combat:AddSection({ Title = "rescue" })
FTF_Tabs.Combat:AddButton({
    Title = "Save Random Captured Player",
    Description = "Teleports to a random frozen player and rescues them",
    ButtonText = "Rescue",
    Callback = function()
        task.spawn(function()
            local targetPlr, targetPod = FTF_FindCapturedPlayer()
            if not targetPlr then
                FTF_Eazy:Notify({ Title = "Rescue", Content = "No captured player found.", Style = "Warning", Duration = 3 })
                return
            end
            local ok = FTF_DoRescueFor(targetPlr, targetPod)
            if ok then
                FTF_Eazy:Notify({ Title = "Rescue", Content = "Attempted to rescue " .. targetPlr.Name, Style = "Success", Duration = 3 })
            else
                FTF_Eazy:Notify({ Title = "Rescue", Content = "Reached " .. targetPlr.Name .. " but no interaction found.", Style = "Warning", Duration = 3 })
            end
        end)
    end
})

FTF_Tabs.Teleport:AddSection({ Title = "quick teleport" })

FTF_Tabs.Teleport:AddButton({
    Title = "Teleport to Candy Bucket",
    Description = "Teleports you to the Halloween Candy Bucket",
    ButtonText = "Teleport",
    Callback = function()
        local bucketModel = nil
        for _, obj in ipairs(FTF_Workspace:GetDescendants()) do
            if obj.Name == "Bucket" and obj:IsA("Model") then
                if obj:FindFirstChild("CandyBucketScript") or (obj.Parent and obj.Parent.Name:find("Facility")) then
                    bucketModel = obj
                    break
                end
            end
        end
        
        if bucketModel then
            local root = bucketModel.PrimaryPart or bucketModel:FindFirstChildWhichIsA("BasePart")
            if root then
                FTF_Teleport(CFrame.new(root.Position + Vector3.new(0, 3, 0)))
                FTF_Eazy:Notify({ Title = "Teleport", Content = "Teleported to Candy Bucket.", Style = "Success", Duration = 2 })
            else
                FTF_Eazy:Notify({ Title = "Teleport", Content = "Bucket model has no BasePart.", Style = "Warning", Duration = 2 })
            end
        else
            FTF_Eazy:Notify({ Title = "Teleport", Content = "Candy Bucket not found.", Style = "Warning", Duration = 2 })
        end
    end
})

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
                if FTF_IsComputerActuallyIncomplete(obj) then
                    table.insert(FTF_Comps, { part = obj.Screen, dist = (FTF_Pos - obj.Screen.Position).Magnitude })
                end
            end
        end
        table.sort(FTF_Comps, function(a, b) return a.dist < b.dist end)
        if #FTF_Comps > 0 then
            local ok = FTF_TeleportToComputer(CFrame.new(FTF_Comps[1].part.Position + Vector3.new(0, 2, 2.5)))
            if ok then
                FTF_Eazy:Notify({ Title = "Teleport", Content = "Teleported to computer.", Duration = 2, Style = "Success" })
            end
        else
            FTF_Eazy:Notify({ Title = "Warning", Content = "All computers are already complete!", Duration = 2, Style = "Warning" })
        end
    end
})

FTF_Tabs.Teleport:AddButton({
    Title = "Teleport to Nearest Closet",
    Description = "Teleports you inside the closest hiding spot, facing outward",
    ButtonText = "Teleport",
    Callback = function()
        local FTF_Char = FTF_LocalPlayer.Character
        if not FTF_Char or not FTF_Char:FindFirstChild("HumanoidRootPart") then return end
        local FTF_Pos = FTF_Char.HumanoidRootPart.Position
        local closets = FTF_FindAllClosets()
        local FTF_Closets = {}
        for _, c in ipairs(closets) do
            table.insert(FTF_Closets, { cframe = c.cframe, dist = (FTF_Pos - c.cframe.Position).Magnitude })
        end
        table.sort(FTF_Closets, function(a, b) return a.dist < b.dist end)
        if #FTF_Closets > 0 then
            local c = FTF_Closets[1].cframe
            FTF_Teleport(c)
            task.wait(0.15)
            FTF_Teleport(c)
            FTF_Eazy:Notify({ Title = "Teleport", Content = "Teleported inside the closet.", Duration = 2, Style = "Success" })
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
            FTF_Teleport(CFrame.new(FTF_Exits[1].part.Position + Vector3.new(0, 3, 0)))
            FTF_Eazy:Notify({ Title = "Teleport", Content = "Teleported to exit.", Duration = 2, Style = "Success" })
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
            FTF_Teleport(CFrame.new(FTF_Pods[1].part.Position + Vector3.new(0, 3, 0)))
            FTF_Eazy:Notify({ Title = "Teleport", Content = "Teleported to freeze pod.", Duration = 2, Style = "Success" })
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
        if not checkcaller() then
            if self.Name == "RemoteEvent" and method == "FireServer" then
                if args[1] == "SetPlayerMinigameResult" and FTF_AntiFailHackEnabled then
                    FTF_LastPCComplete = tick()
                    if args[2] == false then
                        args[2] = true
                        return self.FireServer(self, table.unpack(args))
                    end
                elseif args[1] == "Flop" and FTF_AntiRopeEnabled then
                    if not FTF_IsLocalBeast() then
                        return
                    end
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