local HS_Eazy = loadstring(game:HttpGet("https://raw.githubusercontent.com/akiradv/eazyuilib/refs/heads/main/eazyui.lua"))()
local HS_Version = "1.0.7"
local HS_UIVersion = HS_Eazy.Version

local HS_Players = game:GetService("Players")
local HS_LocalPlayer = HS_Players.LocalPlayer
local HS_RunService = game:GetService("RunService")
local HS_UserInputService = game:GetService("UserInputService")
local HS_Workspace = game:GetService("Workspace")
local HS_TeleportService = game:GetService("TeleportService")
local HS_HttpService = game:GetService("HttpService")

local HS_Flags = {
    WalkSpeed = 16,
    JumpPower = 50,
    Fly = false,
    FlySpeed = 60,
    Noclip = false,
    InfJump = false,
    AutoCollect = false,
    ESPPlayers = false,
    ESPNames = false,
    ESPDistance = false,
    ESPCredits = false,
    ESPColor = Color3.fromRGB(0, 255, 120),
    ESPITColor = Color3.fromRGB(255, 60, 60),
    ESPCreditColor = Color3.fromRGB(255, 215, 0),
}

local HS_FlyBV, HS_FlyBG, HS_FlyConn
local HS_AutoCollectRunning = false

local function HS_GetHRP()
    local c = HS_LocalPlayer.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function HS_GetHum()
    local c = HS_LocalPlayer.Character
    return c and c:FindFirstChildOfClass("Humanoid")
end

local function HS_Teleport(targetCFrame)
    local hrp = HS_GetHRP()
    if not hrp then return false end
    hrp.CFrame = targetCFrame
    hrp.Velocity = Vector3.zero
    hrp.RotVelocity = Vector3.zero
    return true
end

local function HS_IsSeeker(plr)
    if not plr or not plr.Character then return false end
    local playerData = plr:FindFirstChild("PlayerData")
    if playerData and playerData:FindFirstChild("It") then
        return playerData.It.Value == true
    end
    return false
end

local function HS_UpdateESP()
    for _, plr in ipairs(HS_Players:GetPlayers()) do
        if plr ~= HS_LocalPlayer and plr.Character then
            local char = plr.Character
            local hl = char:FindFirstChild("HS_Highlight")
            local bb = char:FindFirstChild("HS_Billboard")
            local isIt = HS_IsSeeker(plr)
            local color = isIt and HS_Flags.ESPITColor or HS_Flags.ESPColor

            if HS_Flags.ESPPlayers then
                if not hl then
                    hl = Instance.new("Highlight")
                    hl.Name = "HS_Highlight"
                    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    hl.FillTransparency = 1
                    hl.OutlineTransparency = 0
                    hl.Parent = char
                end
                hl.OutlineColor = color
            elseif hl then
                hl:Destroy()
            end

            if HS_Flags.ESPNames or HS_Flags.ESPDistance then
                if not bb then
                    bb = Instance.new("BillboardGui")
                    bb.Name = "HS_Billboard"
                    bb.Size = UDim2.new(0, 200, 0, 50)
                    bb.StudsOffset = Vector3.new(0, 3, 0)
                    bb.AlwaysOnTop = true
                    
                    local nameLbl = Instance.new("TextLabel")
                    nameLbl.Name = "NameLabel"
                    nameLbl.Size = UDim2.new(1, 0, 0, 20)
                    nameLbl.BackgroundTransparency = 1
                    nameLbl.TextStrokeTransparency = 0
                    nameLbl.Font = Enum.Font.GothamBold
                    nameLbl.TextSize = 14
                    nameLbl.Parent = bb
                    
                    local distLbl = Instance.new("TextLabel")
                    distLbl.Name = "DistLabel"
                    distLbl.Size = UDim2.new(1, 0, 0, 15)
                    distLbl.Position = UDim2.new(0, 0, 0, 20)
                    distLbl.BackgroundTransparency = 1
                    distLbl.TextStrokeTransparency = 0
                    distLbl.Font = Enum.Font.Gotham
                    distLbl.TextSize = 12
                    distLbl.Parent = bb
                    
                    bb.Parent = char
                end
                bb.Enabled = true
                
                local nameLbl = bb:FindFirstChild("NameLabel")
                local distLbl = bb:FindFirstChild("DistLabel")
                local hrp = HS_GetHRP()
                
                if hrp and char:FindFirstChild("HumanoidRootPart") then
                    local dist = math.floor((hrp.Position - char.HumanoidRootPart.Position).Magnitude)
                    
                    if nameLbl then
                        nameLbl.Text = HS_Flags.ESPNames and plr.Name or ""
                        nameLbl.Visible = HS_Flags.ESPNames
                        nameLbl.TextColor3 = color
                    end
                    
                    if distLbl then
                        distLbl.Text = HS_Flags.ESPDistance and (dist .. "m") or ""
                        distLbl.Visible = HS_Flags.ESPDistance
                        distLbl.TextColor3 = color
                    end
                end
            elseif bb then
                bb:Destroy()
            end
        end
    end

    for _, obj in ipairs(HS_Workspace:GetDescendants()) do
        if obj.Name == "Credit" and obj:IsA("BasePart") then
            local hl = obj:FindFirstChild("HS_Highlight")
            if HS_Flags.ESPCredits then
                if not hl then
                    hl = Instance.new("Highlight")
                    hl.Name = "HS_Highlight"
                    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    hl.FillTransparency = 1
                    hl.OutlineTransparency = 0
                    hl.OutlineColor = HS_Flags.ESPCreditColor
                    hl.Parent = obj
                end
            elseif hl then
                hl:Destroy()
            end
        end
    end
end

local function HS_CollectCredits()
    local hrp = HS_GetHRP()
    if not hrp then return 0 end
    local original = hrp.CFrame
    local count = 0
    for _, obj in ipairs(HS_Workspace:GetDescendants()) do
        if obj.Name == "Credit" and obj:IsA("BasePart") then
            hrp.CFrame = obj.CFrame + Vector3.new(0, 3, 0)
            task.wait(0.1)
            count = count + 1
        end
    end
    hrp.CFrame = original
    return count
end

local function HS_StartAutoCollect()
    if HS_AutoCollectRunning then return end
    HS_AutoCollectRunning = true
    task.spawn(function()
        while HS_Flags.AutoCollect do
            HS_CollectCredits()
            task.wait(1)
        end
        HS_AutoCollectRunning = false
    end)
end

local function HS_KillAll()
    if not HS_IsSeeker(HS_LocalPlayer) then
        return HS_Eazy:Notify({ Title = "Seeker", Content = "You must be IT to use Kill All.", Style = "Warning", Duration = 3 })
    end
    local hrp = HS_GetHRP()
    if not hrp then return end
    for _, plr in ipairs(HS_Players:GetPlayers()) do
        if plr ~= HS_LocalPlayer and plr.Character then
            local targetHRP = plr.Character:FindFirstChild("HumanoidRootPart")
            if targetHRP then
                hrp.CFrame = targetHRP.CFrame + Vector3.new(0, 3, 0)
                task.wait(0.1)
            end
        end
    end
    HS_Eazy:Notify({ Title = "Seeker", Content = "Kill All executed.", Style = "Success", Duration = 2 })
end

local function HS_TouchAll()
    local hrp = HS_GetHRP()
    if not hrp then return end
    for _, plr in ipairs(HS_Players:GetPlayers()) do
        if plr ~= HS_LocalPlayer and plr.Character then
            local targetHRP = plr.Character:FindFirstChild("HumanoidRootPart")
            if targetHRP then
                hrp.CFrame = targetHRP.CFrame + Vector3.new(0, 3, 0)
                task.wait(0.1)
            end
        end
    end
    HS_Eazy:Notify({ Title = "Seeker", Content = "Touched all players.", Style = "Success", Duration = 2 })
end

local function HS_ToggleFly(state)
    HS_Flags.Fly = state
    local hrp = HS_GetHRP()
    local hum = HS_GetHum()
    
    if state then
        if not hrp or not hum then return end
        hum.PlatformStand = true
        
        HS_FlyBV = Instance.new("BodyVelocity")
        HS_FlyBV.Name = "HS_FlyBV"
        HS_FlyBV.MaxForce = Vector3.new(1e5, 1e5, 1e5)
        HS_FlyBV.Parent = hrp
        
        HS_FlyBG = Instance.new("BodyGyro")
        HS_FlyBG.Name = "HS_FlyBG"
        HS_FlyBG.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
        HS_FlyBG.P = 1e4
        HS_FlyBG.Parent = hrp
        
        HS_FlyConn = HS_RunService.RenderStepped:Connect(function()
            if not HS_Flags.Fly or not hrp or not hrp.Parent then return end
            local move = Vector3.zero
            local cam = HS_Workspace.CurrentCamera
            if HS_UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + cam.CFrame.LookVector end
            if HS_UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move - cam.CFrame.LookVector end
            if HS_UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move - cam.CFrame.RightVector end
            if HS_UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + cam.CFrame.RightVector end
            if HS_UserInputService:IsKeyDown(Enum.KeyCode.Space) then move = move + Vector3.yAxis end
            if HS_UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then move = move - Vector3.yAxis end
            
            HS_FlyBV.Velocity = move.Magnitude > 0 and move.Unit * HS_Flags.FlySpeed or Vector3.zero
            HS_FlyBG.CFrame = cam.CFrame
        end)
    else
        if HS_FlyConn then HS_FlyConn:Disconnect() HS_FlyConn = nil end
        if hrp then
            local bv = hrp:FindFirstChild("HS_FlyBV")
            local bg = hrp:FindFirstChild("HS_FlyBG")
            if bv then bv:Destroy() end
            if bg then bg:Destroy() end
        end
        if hum then hum.PlatformStand = false end
    end
end

HS_UserInputService.JumpRequest:Connect(function()
    if HS_Flags.InfJump and HS_GetHum() then
        HS_GetHum():ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

HS_RunService.Stepped:Connect(function()
    if not HS_Flags.Noclip then return end
    local c = HS_LocalPlayer.Character
    if not c then return end
    for _, p in ipairs(c:GetDescendants()) do
        if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end
    end
end)

HS_RunService.RenderStepped:Connect(function()
    pcall(HS_UpdateESP)
end)

local HS_Window = HS_Eazy:CreateWindow({
    Name = "Hide and Seek Hub",
    SubTitle = "by AkiraDev | v" .. HS_Version,
    Size = UDim2.fromOffset(580, 460),
    MinimizeKey = Enum.KeyCode.RightShift,
    ConfigId = "HS_Hub_v1",
    AutoLoad = true,
    NotifyPosition = "BottomRight",
    LoadingTitle = "Hide and Seek Hub",
    LoadingSubtitle = "Loading...",
    LoadingDuration = 1.2,
    Discord = { Enabled = true, Invite = "2ksQSAnnW6" },
})

local HS_Tabs = {
    Main = HS_Window:AddTab({ Title = "Main", Icon = "house" }),
    ESP = HS_Window:AddTab({ Title = "ESP", Icon = "eye" }),
    Teleport = HS_Window:AddTab({ Title = "Teleport", Icon = "navigation" }),
    Hider = HS_Window:AddTab({ Title = "Hider", Icon = "shield" }),
    Seeker = HS_Window:AddTab({ Title = "Seeker", Icon = "target" }),
    Player = HS_Window:AddTab({ Title = "Player", Icon = "user" }),
    Settings = HS_Window:AddTab({ Title = "Settings", Icon = "settings" }),
    Credits = HS_Window:AddTab({ Title = "Credits", Icon = "info" }),
}

HS_Tabs.Main:AddSection({ Title = "about" })
HS_Tabs.Main:AddParagraph({
    Title = "Objective",
    Content = "Provide a casual, lightweight, and undetectable utility for Hide and Seek Extreme, focused on quality of life without breaking the game experience."
})
HS_Tabs.Main:AddParagraph({
    Title = "Local & Security",
    Content = "This script is 100% Open Source and runs locally on your executor. The code is open to ensure total transparency, security, and community trust."
})
HS_Tabs.Main:AddSection({ Title = "information" })
HS_Tabs.Main:AddParagraph({
    Title = "Version Info",
    Content = "Script: v" .. HS_Version .. "\nUI Library: Eazy UI " .. HS_UIVersion .. "\nDeveloper: AkiraDev\nGitHub: github.com/akiradv"
})
HS_Tabs.Main:AddSection({ Title = "community" })
HS_Tabs.Main:AddButton({
    Title = "Join Discord",
    Description = "Copy the invite link to join the server",
    ButtonText = "Copy Link",
    Callback = function()
        local inviteUrl = "https://discord.gg/2ksQSAnnW6"
        if setclipboard then
            setclipboard(inviteUrl)
            HS_Eazy:Notify({ Title = "Discord", Content = "Invite link copied to clipboard!", Duration = 3, Style = "Success" })
        else
            HS_Eazy:Notify({ Title = "Discord", Content = "Copy this link: " .. inviteUrl, Duration = 10, Style = "Info" })
        end
    end
})

HS_Tabs.Main:AddSection({ Title = "movement" })
HS_Tabs.Main:AddSlider({ Title = "Walk Speed", Description = "Character walking speed", Min = 16, Max = 500, Default = 16, Step = 1, Flag = "HS_WalkSpeed", Callback = function(v)
    HS_Flags.WalkSpeed = v
    local hum = HS_GetHum()
    if hum then hum.WalkSpeed = v end
end })

HS_Tabs.Main:AddSlider({ Title = "Jump Power", Description = "Character jump power", Min = 50, Max = 500, Default = 50, Step = 1, Flag = "HS_JumpPower", Callback = function(v)
    HS_Flags.JumpPower = v
    local hum = HS_GetHum()
    if hum then hum.JumpPower = v end
end })

HS_Tabs.Main:AddSlider({ Title = "Fly Speed", Description = "Fly velocity", Min = 20, Max = 300, Default = 60, Step = 5, Flag = "HS_FlySpeed", Callback = function(v)
    HS_Flags.FlySpeed = v
end })

HS_Tabs.Main:AddSection({ Title = "toggles" })
HS_Tabs.Main:AddToggle({ Title = "Fly", Description = "WASD to move, Space up, Ctrl down", Flag = "HS_Fly", Default = false, Callback = function(v)
    HS_ToggleFly(v)
end })

HS_Tabs.Main:AddToggle({ Title = "Noclip", Description = "Walk through walls", Flag = "HS_Noclip", Default = false, Callback = function(v)
    HS_Flags.Noclip = v
end })

HS_Tabs.Main:AddToggle({ Title = "Infinite Jump", Description = "Jump in midair", Flag = "HS_InfJump", Default = false, Callback = function(v)
    HS_Flags.InfJump = v
end })

HS_Tabs.ESP:AddSection({ Title = "players" })
HS_Tabs.ESP:AddToggle({ Title = "Player ESP", Description = "Show all players through walls (Red = IT)", Flag = "HS_ESPPlayers", Default = false, Callback = function(v)
    HS_Flags.ESPPlayers = v
end })

HS_Tabs.ESP:AddToggle({ Title = "Player Names", Description = "Show player names above their heads", Flag = "HS_ESPNames", Default = false, Callback = function(v)
    HS_Flags.ESPNames = v
end })

HS_Tabs.ESP:AddToggle({ Title = "Player Distance", Description = "Show distance to players", Flag = "HS_ESPDistance", Default = false, Callback = function(v)
    HS_Flags.ESPDistance = v
end })

HS_Tabs.ESP:AddSection({ Title = "credits" })
HS_Tabs.ESP:AddToggle({ Title = "Credit ESP", Description = "Show all credits on the map", Flag = "HS_ESPCredits", Default = false, Callback = function(v)
    HS_Flags.ESPCredits = v
end })

HS_Tabs.ESP:AddSection({ Title = "colors" })
HS_Tabs.ESP:AddColorPicker({ Title = "Player Color", Description = "Color for normal players", Default = Color3.fromRGB(0, 255, 120), Flag = "HS_ESPColor", Callback = function(c)
    HS_Flags.ESPColor = c
end })

HS_Tabs.ESP:AddColorPicker({ Title = "IT Color", Description = "Color for the seeker", Default = Color3.fromRGB(255, 60, 60), Flag = "HS_ESPITColor", Callback = function(c)
    HS_Flags.ESPITColor = c
end })

HS_Tabs.Teleport:AddSection({ Title = "actions" })
HS_Tabs.Teleport:AddButton({ Title = "Teleport to Nearest Player (Non-IT)", Description = "Go to the closest player, excluding the seeker", ButtonText = "Go", Callback = function()
    local hrp = HS_GetHRP()
    if not hrp then return end
    local nearest, dist = nil, math.huge
    for _, plr in ipairs(HS_Players:GetPlayers()) do
        if plr ~= HS_LocalPlayer and plr.Character then
            if HS_IsSeeker(plr) then continue end
            local targetHRP = plr.Character:FindFirstChild("HumanoidRootPart")
            if targetHRP then
                local d = (targetHRP.Position - hrp.Position).Magnitude
                if d < dist then nearest = targetHRP dist = d end
            end
        end
    end
    if nearest then
        HS_Teleport(nearest.CFrame + Vector3.new(0, 3, 0))
        HS_Eazy:Notify({ Title = "Teleport", Content = "Teleported to nearest player.", Style = "Success", Duration = 2 })
    else
        HS_Eazy:Notify({ Title = "Teleport", Content = "No non-IT players found.", Style = "Warning", Duration = 2 })
    end
end })

HS_Tabs.Teleport:AddButton({ Title = "Teleport to Seeker", Description = "Go to the seeker (use with caution)", ButtonText = "Go", Callback = function()
    for _, plr in ipairs(HS_Players:GetPlayers()) do
        if plr ~= HS_LocalPlayer and HS_IsSeeker(plr) then
            local targetHRP = plr.Character:FindFirstChild("HumanoidRootPart")
            if targetHRP then
                HS_Teleport(targetHRP.CFrame + Vector3.new(0, 3, 0))
                HS_Eazy:Notify({ Title = "Teleport", Content = "Teleported to seeker.", Style = "Success", Duration = 2 })
                return
            end
        end
    end
    HS_Eazy:Notify({ Title = "Teleport", Content = "Seeker not found.", Style = "Warning", Duration = 2 })
end })

HS_Tabs.Teleport:AddButton({ Title = "Teleport to Sky Spot", Description = "Teleport high into the sky", ButtonText = "Go", Callback = function()
    local hrp = HS_GetHRP()
    if hrp then
        HS_Teleport(hrp.CFrame + Vector3.new(0, 500, 0))
        HS_Eazy:Notify({ Title = "Teleport", Content = "Teleported to sky spot.", Style = "Success", Duration = 2 })
    end
end })

HS_Tabs.Hider:AddSection({ Title = "credits" })
HS_Tabs.Hider:AddButton({ Title = "Collect All Credits", Description = "Collect every credit on the map once", ButtonText = "Collect", Callback = function()
    local count = HS_CollectCredits()
    HS_Eazy:Notify({ Title = "Hider", Content = "Collected " .. count .. " credits.", Style = "Success", Duration = 2 })
end })

HS_Tabs.Hider:AddToggle({ Title = "Auto Collect Credits", Description = "Continuously collect credits every second", Flag = "HS_AutoCollect", Default = false, Callback = function(v)
    HS_Flags.AutoCollect = v
    if v then HS_StartAutoCollect() end
end })

HS_Tabs.Seeker:AddSection({ Title = "actions" })
HS_Tabs.Seeker:AddButton({ Title = "Kill All", Description = "Teleport to every player and tag them (requires IT)", ButtonText = "Kill", Callback = function()
    HS_KillAll()
end })

HS_Tabs.Seeker:AddButton({ Title = "Touch All", Description = "Teleport to every player (useful as IT)", ButtonText = "Touch", Callback = function()
    HS_TouchAll()
end })

HS_Tabs.Player:AddSection({ Title = "server" })
HS_Tabs.Player:AddButton({ Title = "Rejoin Server", Description = "Reconnect to this server", ButtonText = "Rejoin", Callback = function()
    HS_Eazy:Notify({ Title = "System", Content = "Reconnecting to the same server...", Duration = 2, Style = "Info" })
    task.wait(0.5)
    pcall(function() HS_TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, HS_LocalPlayer) end)
end })

HS_Tabs.Player:AddButton({ Title = "Server Hop", Description = "Join another server with players", ButtonText = "Hop", Callback = function()
    local ok, result = pcall(function()
        local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
        return HS_HttpService:JSONDecode(game:HttpGet(url))
    end)
    if not ok or not result or not result.data then return end
    for _, srv in ipairs(result.data) do
        if srv.playing < srv.maxPlayers and srv.id ~= game.JobId then
            HS_TeleportService:TeleportToPlaceInstance(game.PlaceId, srv.id, HS_LocalPlayer)
            return
        end
    end
    HS_Eazy:Notify({ Title = "Player", Content = "No servers found.", Style = "Warning", Duration = 3 })
end })

HS_Window:BuildConfigSection(HS_Tabs.Settings)

HS_Tabs.Credits:AddSection({ Title = "credits" })
HS_Tabs.Credits:AddParagraph({
    Title = "Development",
    Content = "Developer: AkiraDev\nGitHub: github.com/akiradv\nDiscord: discord.gg/2ksQSAnnW6\n\nUI Library: Eazy UI " .. HS_UIVersion .. " by AkiraDev"
})

HS_Eazy:Notify({ Title = "Hide and Seek Hub", Content = "v" .. HS_Version .. " loaded successfully", Style = "Success", Duration = 3 })