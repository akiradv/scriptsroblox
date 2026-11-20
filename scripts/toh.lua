local TOH_Eazy = loadstring(game:HttpGet("https://raw.githubusercontent.com/akiradv/eazyuilib/refs/heads/main/eazyui.lua"))()
local TOH_Version = "1.0.0"
local TOH_UIVersion = TOH_Eazy.Version

local TOH_Players = game:GetService("Players")
local TOH_LocalPlayer = TOH_Players.LocalPlayer
local TOH_Workspace = game:GetService("Workspace")
local TOH_RunService = game:GetService("RunService")
local TOH_UserInput = game:GetService("UserInputService")
local TOH_Lighting = game:GetService("Lighting")
local TOH_TeleportService = game:GetService("TeleportService")
local TOH_CollectionService = game:GetService("CollectionService")
local TOH_VirtualUser = game:GetService("VirtualUser")

if not game:IsLoaded() then game.Loaded:Wait() end

local TOH_Env = _G
pcall(function()
    if type(getgenv) == "function" then
        local g = getgenv()
        if type(g) == "table" then TOH_Env = g end
    end
end)

if type(TOH_Env.TOH_Cleanup) == "function" then pcall(TOH_Env.TOH_Cleanup) end

local TOH_Config = TOH_Env.TOH_Config
if type(TOH_Config) ~= "table" then
    TOH_Config = {
        KillImmunity = false, InfJump = false, Noclip = false,
        WalkSpeed = 16, JumpPower = 50,
        FullBright = false, NoFog = false, FOV = 70,
        ESPPlayers = false, ESPKill = false,
        Headless = false, Korblox = false,
        AntiAFK = true,
    }
    TOH_Env.TOH_Config = TOH_Config
end
if TOH_Config.Noclip == nil then TOH_Config.Noclip = false end

local TOH_Running = true
local TOH_Connections = {}
local TOH_Window
local TOH_KillSaved = {}
local TOH_CollideSaved = {}
local TOH_LightSaved = nil
local TOH_ESPFolder = nil
local TOH_ESP = { players = {}, kill = {} }
local TOH_LookSaved = {}
local TOH_NextTick = 0
local TOH_KillESPRange = 25

local function TOH_Track(connection)
    table.insert(TOH_Connections, connection)
    return connection
end

local function TOH_Notify(title, content, style, duration)
    task.defer(function()
        pcall(function()
            TOH_Eazy:Notify({ Title = title, Content = content, Style = style or "Info", Duration = duration or 4 })
        end)
    end)
end

local function TOH_Character()
    return TOH_LocalPlayer.Character
end

local function TOH_Humanoid(): any
    local char = TOH_Character()
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function TOH_Root(): any
    local char = TOH_Character()
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function TOH_ApplyKill(part)
    if not part:IsA("BasePart") then return end
    if TOH_KillSaved[part] == nil then
        TOH_KillSaved[part] = { touch = part.CanTouch, query = part.CanQuery }
    end
    part.CanTouch = false
    part.CanQuery = false
end

local function TOH_ApplyAllKill()
    local count = 0
    for _, part in ipairs(TOH_CollectionService:GetTagged("KillBrick")) do
        if part:IsA("BasePart") then
            TOH_ApplyKill(part)
            count += 1
        end
    end
    return count
end

local function TOH_RestoreKill()
    for part, saved in pairs(TOH_KillSaved) do
        if part.Parent then
            part.CanTouch = saved.touch
            part.CanQuery = saved.query
        end
        TOH_KillSaved[part] = nil
    end
end

local function TOH_SetKillImmunity(state)
    TOH_Config.KillImmunity = state == true
    if TOH_Config.KillImmunity then
        TOH_Notify("Kill Brick Immunity", "Disabled " .. TOH_ApplyAllKill() .. " kill parts.", "Success", 3)
    else
        TOH_RestoreKill()
        TOH_Notify("Kill Brick Immunity", "Kill parts restored.", "Info", 3)
    end
end

local function TOH_ApplyNoclip()
    local char = TOH_Character()
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            if TOH_CollideSaved[part] == nil then
                TOH_CollideSaved[part] = part.CanCollide
            end
            if part.CanCollide then part.CanCollide = false end
        end
    end
end

local function TOH_RestoreNoclip()
    for part, saved in pairs(TOH_CollideSaved) do
        if part.Parent then part.CanCollide = saved end
        TOH_CollideSaved[part] = nil
    end
end

local function TOH_SetNoclip(state)
    TOH_Config.Noclip = state == true
    if TOH_Config.Noclip then
        TOH_ApplyNoclip()
    else
        TOH_RestoreNoclip()
    end
end

local function TOH_ApplyStats()
    local hum = TOH_Humanoid()
    if not hum then return end
    if TOH_Config.WalkSpeed > 16 and hum.WalkSpeed ~= TOH_Config.WalkSpeed then
        hum.WalkSpeed = TOH_Config.WalkSpeed
    end
    if TOH_Config.JumpPower > 50 and hum.JumpPower ~= TOH_Config.JumpPower then
        hum.JumpPower = TOH_Config.JumpPower
    end
end

local function TOH_SaveLighting()
    if TOH_LightSaved then return end
    TOH_LightSaved = {
        Brightness = TOH_Lighting.Brightness,
        ClockTime = TOH_Lighting.ClockTime,
        FogEnd = TOH_Lighting.FogEnd,
        FogStart = TOH_Lighting.FogStart,
        Ambient = TOH_Lighting.Ambient,
        OutdoorAmbient = TOH_Lighting.OutdoorAmbient,
        GlobalShadows = TOH_Lighting.GlobalShadows,
        atmosphere = {},
    }
    for _, child in ipairs(TOH_Lighting:GetChildren()) do
        if child:IsA("Atmosphere") then
            TOH_LightSaved.atmosphere[child] = {
                Density = child.Density, Haze = child.Haze, Glare = child.Glare,
            }
        end
    end
end

local function TOH_ApplyLighting()
    if not (TOH_Config.FullBright or TOH_Config.NoFog) then
        if TOH_LightSaved then
            TOH_Lighting.Brightness = TOH_LightSaved.Brightness
            TOH_Lighting.ClockTime = TOH_LightSaved.ClockTime
            TOH_Lighting.FogEnd = TOH_LightSaved.FogEnd
            TOH_Lighting.FogStart = TOH_LightSaved.FogStart
            TOH_Lighting.Ambient = TOH_LightSaved.Ambient
            TOH_Lighting.OutdoorAmbient = TOH_LightSaved.OutdoorAmbient
            TOH_Lighting.GlobalShadows = TOH_LightSaved.GlobalShadows
            for atm, saved in pairs(TOH_LightSaved.atmosphere) do
                if atm.Parent then
                    atm.Density = saved.Density
                    atm.Haze = saved.Haze
                    atm.Glare = saved.Glare
                end
            end
            TOH_LightSaved = nil
        end
        return
    end
    TOH_SaveLighting()
    if TOH_Config.FullBright then
        TOH_Lighting.Brightness = 2
        TOH_Lighting.ClockTime = 14
        TOH_Lighting.Ambient = Color3.fromRGB(180, 180, 180)
        TOH_Lighting.OutdoorAmbient = Color3.fromRGB(180, 180, 180)
        TOH_Lighting.GlobalShadows = false
    end
    if TOH_Config.NoFog then
        TOH_Lighting.FogEnd = 1e6
        TOH_Lighting.FogStart = 1e6
        for atm in pairs(TOH_LightSaved.atmosphere) do
            if atm.Parent then
                atm.Density = 0
                atm.Haze = 0
                atm.Glare = 0
            end
        end
    end
end

local function TOH_SetFOV(value)
    TOH_Config.FOV = value
    local cam = TOH_Workspace.CurrentCamera
    if cam then cam.FieldOfView = value end
end

local function TOH_ESPContainer()
    if TOH_ESPFolder and TOH_ESPFolder.Parent then return TOH_ESPFolder end
    TOH_ESPFolder = Instance.new("Folder")
    TOH_ESPFolder.Name = "TOH_ESP"
    TOH_ESPFolder.Parent = TOH_Workspace
    return TOH_ESPFolder
end

local function TOH_ClearESP(group)
    for target, highlight in pairs(TOH_ESP[group]) do
        if highlight then highlight:Destroy() end
        TOH_ESP[group][target] = nil
    end
end

local function TOH_SyncESP(group, wanted, color)
    local container = TOH_ESPContainer()
    for target, highlight in pairs(TOH_ESP[group]) do
        if not wanted[target] or not target.Parent then
            highlight:Destroy()
            TOH_ESP[group][target] = nil
        end
    end
    for target in pairs(wanted) do
        if not TOH_ESP[group][target] then
            local highlight = Instance.new("Highlight")
            highlight.Name = "TOH_Highlight"
            highlight.Adornee = target
            highlight.FillColor = color
            highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
            highlight.FillTransparency = 0.65
            highlight.OutlineTransparency = 0
            highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            highlight.Parent = container
            TOH_ESP[group][target] = highlight
        end
    end
end

local function TOH_UpdateESP()
    if TOH_Config.ESPPlayers then
        local wanted = {}
        for _, player in ipairs(TOH_Players:GetPlayers()) do
            if player ~= TOH_LocalPlayer and player.Character then
                wanted[player.Character] = true
            end
        end
        TOH_SyncESP("players", wanted, Color3.fromRGB(80, 220, 120))
    else
        TOH_ClearESP("players")
    end

    if TOH_Config.ESPKill then
        local root = TOH_Root()
        local origin = root and root.Position or Vector3.zero
        local list = {}
        for _, part in ipairs(TOH_CollectionService:GetTagged("KillBrick")) do
            if part:IsA("BasePart") and part.Parent then
                list[#list + 1] = { part = part, dist = (part.Position - origin).Magnitude }
            end
        end
        table.sort(list, function(a, b) return a.dist < b.dist end)
        local wanted = {}
        for index = 1, math.min(#list, TOH_KillESPRange) do
            wanted[list[index].part] = true
        end
        TOH_SyncESP("kill", wanted, Color3.fromRGB(235, 70, 70))
    else
        TOH_ClearESP("kill")
    end
end

local function TOH_ApplyAppearance()
    local char = TOH_Character()
    if not char then return end

    local head = char:FindFirstChild("Head")
    if head and head:IsA("BasePart") then
        if TOH_LookSaved[head] == nil then
            local face = head:FindFirstChild("face")
            TOH_LookSaved[head] = {
                transparency = head.Transparency,
                face = face,
                faceTransparency = face and face:IsA("Decal") and face.Transparency or nil,
            }
        end
        local saved = TOH_LookSaved[head]
        local mesh = head:FindFirstChild("TOH_HeadlessMesh")
        if TOH_Config.Headless then
            head.Transparency = 1
            if saved.face and saved.face.Parent and saved.face:IsA("Decal") then
                saved.face.Transparency = 1
            end
            if not mesh then
                mesh = Instance.new("SpecialMesh")
                mesh.Name = "TOH_HeadlessMesh"
                mesh.MeshType = Enum.MeshType.FileMesh
                mesh.MeshId = "rbxassetid://1095708"
                mesh.Scale = Vector3.new(0.001, 0.001, 0.001)
                mesh.Parent = head
            end
        else
            head.Transparency = saved.transparency
            if saved.face and saved.face.Parent and saved.face:IsA("Decal") and saved.faceTransparency then
                saved.face.Transparency = saved.faceTransparency
            end
            if mesh then mesh:Destroy() end
        end
    end

    local leg = char:FindFirstChild("Right Leg") or char:FindFirstChild("RightUpperLeg")
    if leg and leg:IsA("BasePart") then
        if TOH_LookSaved[leg] == nil then
            TOH_LookSaved[leg] = { color = leg.Color }
        end
        local mesh = leg:FindFirstChild("TOH_KorbloxMesh")
        if TOH_Config.Korblox then
            leg.Color = Color3.fromRGB(64, 64, 64)
            if not mesh then
                mesh = Instance.new("SpecialMesh")
                mesh.Name = "TOH_KorbloxMesh"
                mesh.MeshType = Enum.MeshType.FileMesh
                mesh.MeshId = "rbxassetid://101851696"
                mesh.Scale = Vector3.new(1.05, 1.05, 1.05)
                mesh.Parent = leg
            end
        else
            leg.Color = TOH_LookSaved[leg].color
            if mesh then mesh:Destroy() end
        end
    end
end

local function TOH_RestoreAppearance()
    for part, saved in pairs(TOH_LookSaved) do
        if part.Parent then
            if saved.transparency ~= nil then part.Transparency = saved.transparency end
            if saved.color then part.Color = saved.color end
            if saved.face and saved.face.Parent and saved.faceTransparency then
                saved.face.Transparency = saved.faceTransparency
            end
        end
        TOH_LookSaved[part] = nil
    end
    local char = TOH_Character()
    if char then
        for _, d in ipairs(char:GetDescendants()) do
            if d.Name == "TOH_HeadlessMesh" or d.Name == "TOH_KorbloxMesh" then
                d:Destroy()
            end
        end
    end
end

local function TOH_FindFinish(): any
    local tower = TOH_Workspace:FindFirstChild("tower") or TOH_Workspace:FindFirstChild("Tower")
    local scope = tower or TOH_Workspace
    local best, bestY = nil, -math.huge
    for _, d in ipairs(scope:GetDescendants()) do
        if d:IsA("BasePart") and d.Name == "ParticleBrick" and d.Position.Y > bestY then
            best, bestY = d, d.Position.Y
        end
    end
    return best
end

local function TOH_TeleportFinish()
    local root = TOH_Root()
    if not root then
        TOH_Notify("Teleport", "No character.", "Error", 3)
        return
    end
    local target = TOH_FindFinish()
    if not target then
        TOH_Notify("Teleport", "Finish not loaded yet. Climb closer first.", "Warning", 4)
        return
    end
    root.AssemblyLinearVelocity = Vector3.zero
    root.CFrame = target.CFrame + Vector3.new(0, 3, 0)
    TOH_Notify("Teleport", "Moved to the finish.", "Success", 3)
end

local function TOH_Unload()
    if not TOH_Running then return end
    TOH_Running = false
    TOH_Config.KillImmunity = false
    TOH_Config.InfJump = false
    TOH_Config.Noclip = false
    TOH_Config.FullBright = false
    TOH_Config.NoFog = false
    TOH_Config.ESPPlayers = false
    TOH_Config.ESPKill = false
    TOH_Config.Headless = false
    TOH_Config.Korblox = false
    TOH_Config.WalkSpeed = 16
    TOH_Config.JumpPower = 50
    TOH_RestoreKill()
    TOH_RestoreNoclip()
    TOH_ApplyLighting()
    TOH_ClearESP("players")
    TOH_ClearESP("kill")
    if TOH_ESPFolder then TOH_ESPFolder:Destroy() TOH_ESPFolder = nil end
    TOH_RestoreAppearance()
    local cam = TOH_Workspace.CurrentCamera
    if cam then cam.FieldOfView = 70 end
    local hum = TOH_Humanoid()
    if hum then
        pcall(function()
            hum.WalkSpeed = 16
            hum.JumpPower = 50
        end)
    end
    for _, connection in ipairs(TOH_Connections) do
        pcall(function() connection:Disconnect() end)
    end
    TOH_Connections = {}
    TOH_Env.TOH_Cleanup = nil
    TOH_Notify("ToH Hub", "Unloaded.", "Success", 3)
    task.delay(0.4, function() pcall(function() TOH_Window:Destroy() end) end)
end

TOH_Track(TOH_CollectionService:GetInstanceAddedSignal("KillBrick"):Connect(function(part)
    if TOH_Running and TOH_Config.KillImmunity then
        task.defer(TOH_ApplyKill, part)
    end
end))

TOH_Track(TOH_UserInput.JumpRequest:Connect(function()
    if not TOH_Running or not TOH_Config.InfJump then return end
    local hum = TOH_Humanoid()
    if hum and hum.Health > 0 then
        hum:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end))

TOH_Track(TOH_RunService.Stepped:Connect(function()
    if not TOH_Running or not TOH_Config.Noclip then return end
    TOH_ApplyNoclip()
end))

TOH_Track(TOH_LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    if not TOH_Running then return end
    TOH_LookSaved = {}
    TOH_CollideSaved = {}
    TOH_ApplyStats()
    TOH_ApplyAppearance()
    if TOH_Config.Noclip then TOH_ApplyNoclip() end
    if TOH_Config.KillImmunity then TOH_ApplyAllKill() end
end))

TOH_Track(TOH_LocalPlayer.Idled:Connect(function()
    if not TOH_Running or not TOH_Config.AntiAFK then return end
    pcall(function()
        TOH_VirtualUser:CaptureController()
        TOH_VirtualUser:ClickButton2(Vector2.new())
    end)
end))

TOH_Track(TOH_RunService.Heartbeat:Connect(function()
    if not TOH_Running then return end
    local now = os.clock()
    if now < TOH_NextTick then return end
    TOH_NextTick = now + 0.5
    if TOH_Config.KillImmunity then TOH_ApplyAllKill() end
    TOH_ApplyStats()
    TOH_UpdateESP()
    TOH_ApplyAppearance()
end))

TOH_Window = TOH_Eazy:CreateWindow({
    Name = "ToH Hub",
    SubTitle = "by AkiraDev",
    Size = UDim2.fromOffset(580, 460),
    MinimizeKey = Enum.KeyCode.RightShift,
    ConfigId = "ToH_Hub_v1",
    AutoLoad = true,
    NotifyPosition = "BottomRight",
    LoadingTitle = "ToH Hub",
    LoadingSubtitle = "Loading ToH Hub...",
    LoadingDuration = 1.2,
    Discord = { Enabled = false },
})

if type(TOH_Window) ~= "table" or type(TOH_Window.AddTab) ~= "function" then
    TOH_Notify("ToH Hub", "UI failed to open.", "Error", 8)
    return
end

local TOH_Tabs = {
    Main = TOH_Window:AddTab({ Title = "Main", Icon = "house" }),
    Movement = TOH_Window:AddTab({ Title = "Movement", Icon = "zap" }),
    Visuals = TOH_Window:AddTab({ Title = "Visuals", Icon = "eye" }),
    Server = TOH_Window:AddTab({ Title = "Server", Icon = "globe" }),
    Settings = TOH_Window:AddTab({ Title = "Settings", Icon = "settings" }),
    Credits = TOH_Window:AddTab({ Title = "Credits", Icon = "info" }),
}

TOH_Tabs.Main:AddSection({ Title = "about" })
TOH_Tabs.Main:AddParagraph({
    Title = "Objective",
    Content = "Kill brick immunity, movement and visual tools for Tower of Hell. Runs locally on your executor.",
})
TOH_Tabs.Main:AddParagraph({
    Title = "Local & Security",
    Content = "This script is 100% Open Source and runs locally on your executor. The code is open to ensure total transparency, security, and community trust.",
})

TOH_Tabs.Main:AddSection({ Title = "information" })
TOH_Tabs.Main:AddParagraph({
    Title = "Version Info",
    Content = "Script: v" .. TOH_Version .. "\nUI Library: Eazy UI " .. tostring(TOH_UIVersion) .. "\nDeveloper: AkiraDev\nGitHub: github.com/akiradv",
})

TOH_Tabs.Main:AddSection({ Title = "community" })
TOH_Tabs.Main:AddButton({
    Title = "Join Discord",
    Description = "Copy the invite link to join the server",
    ButtonText = "Copy Link",
    Callback = function()
        local invite = "https://discord.gg/9VE4PXFDSg"
        if type(setclipboard) == "function" then
            setclipboard(invite)
            TOH_Notify("Discord", "Invite link copied to clipboard!", "Success", 3)
        else
            TOH_Notify("Discord", "Copy this link: " .. invite, "Info", 10)
        end
    end,
})

TOH_Tabs.Main:AddSection({ Title = "protection" })
TOH_Tabs.Main:AddToggle({
    Title = "Kill Brick Immunity",
    Description = "Walk through red kill parts without dying",
    Flag = "TOH_KillImmunity",
    Default = TOH_Config.KillImmunity,
    Callback = function(state) TOH_SetKillImmunity(state) end,
})

TOH_Tabs.Movement:AddSection({ Title = "jump" })
TOH_Tabs.Movement:AddToggle({
    Title = "Infinite Jump",
    Description = "Jump again while in midair",
    Flag = "TOH_InfJump",
    Default = TOH_Config.InfJump,
    Callback = function(state) TOH_Config.InfJump = state end,
})
TOH_Tabs.Movement:AddSlider({
    Title = "Jump Power",
    Description = "How high each jump goes",
    Min = 50, Max = 120, Default = TOH_Config.JumpPower, Step = 1,
    Flag = "TOH_JumpPower",
    Callback = function(value)
        TOH_Config.JumpPower = value
        TOH_ApplyStats()
    end,
})

TOH_Tabs.Movement:AddSection({ Title = "speed" })
TOH_Tabs.Movement:AddSlider({
    Title = "Walk Speed",
    Description = "How fast you run",
    Min = 16, Max = 60, Default = TOH_Config.WalkSpeed, Step = 1,
    Flag = "TOH_WalkSpeed",
    Callback = function(value)
        TOH_Config.WalkSpeed = value
        TOH_ApplyStats()
    end,
})

TOH_Tabs.Movement:AddSection({ Title = "collision" })
TOH_Tabs.Movement:AddToggle({
    Title = "Noclip",
    Description = "Walk through walls and floors",
    Flag = "TOH_Noclip",
    Default = TOH_Config.Noclip,
    Callback = function(state) TOH_SetNoclip(state) end,
})

TOH_Tabs.Movement:AddSection({ Title = "finish" })
TOH_Tabs.Movement:AddParagraph({
    Title = "Warning",
    Content = "Teleporting is detected by the tower and can kick you from the server. Use an alternate account if you try this.",
})
TOH_Tabs.Movement:AddButton({
    Title = "Teleport to Finish",
    Description = "Moves you to the top of the tower",
    ButtonText = "Teleport",
    Callback = TOH_TeleportFinish,
})

TOH_Tabs.Visuals:AddSection({ Title = "lighting" })
TOH_Tabs.Visuals:AddToggle({
    Title = "Full Bright",
    Description = "Lights up the whole tower",
    Flag = "TOH_FullBright",
    Default = TOH_Config.FullBright,
    Callback = function(state)
        TOH_Config.FullBright = state
        TOH_ApplyLighting()
    end,
})
TOH_Tabs.Visuals:AddToggle({
    Title = "Remove Fog",
    Description = "Clears fog and atmosphere",
    Flag = "TOH_NoFog",
    Default = TOH_Config.NoFog,
    Callback = function(state)
        TOH_Config.NoFog = state
        TOH_ApplyLighting()
    end,
})
TOH_Tabs.Visuals:AddSlider({
    Title = "Field of View",
    Description = "Camera field of view",
    Min = 70, Max = 120, Default = TOH_Config.FOV, Step = 1,
    Flag = "TOH_FOV",
    Callback = function(value) TOH_SetFOV(value) end,
})

TOH_Tabs.Visuals:AddSection({ Title = "esp" })
TOH_Tabs.Visuals:AddToggle({
    Title = "ESP Players",
    Description = "Highlights other players through walls",
    Flag = "TOH_ESPPlayers",
    Default = TOH_Config.ESPPlayers,
    Callback = function(state)
        TOH_Config.ESPPlayers = state
        TOH_UpdateESP()
    end,
})
TOH_Tabs.Visuals:AddToggle({
    Title = "ESP Kill Bricks",
    Description = "Highlights the nearest kill parts through walls",
    Flag = "TOH_ESPKill",
    Default = TOH_Config.ESPKill,
    Callback = function(state)
        TOH_Config.ESPKill = state
        TOH_UpdateESP()
    end,
})

TOH_Tabs.Visuals:AddSection({ Title = "avatar" })
TOH_Tabs.Visuals:AddToggle({
    Title = "Headless",
    Description = "Hides your head",
    Flag = "TOH_Headless",
    Default = TOH_Config.Headless,
    Callback = function(state)
        TOH_Config.Headless = state
        TOH_ApplyAppearance()
    end,
})
TOH_Tabs.Visuals:AddToggle({
    Title = "Korblox",
    Description = "Korblox leg on your right leg",
    Flag = "TOH_Korblox",
    Default = TOH_Config.Korblox,
    Callback = function(state)
        TOH_Config.Korblox = state
        TOH_ApplyAppearance()
    end,
})

TOH_Tabs.Server:AddSection({ Title = "utility" })
TOH_Tabs.Server:AddToggle({
    Title = "Anti-AFK",
    Description = "Prevents you from being kicked for being AFK",
    Flag = "TOH_AntiAFK",
    Default = TOH_Config.AntiAFK,
    Callback = function(state) TOH_Config.AntiAFK = state end,
})

TOH_Tabs.Server:AddSection({ Title = "server" })
TOH_Tabs.Server:AddButton({
    Title = "Rejoin",
    Description = "Rejoins the same server you are in",
    ButtonText = "Rejoin",
    Callback = function()
        TOH_Notify("Server", "Reconnecting to the same server...", "Info", 2)
        task.delay(0.5, function()
            pcall(function() TOH_TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, TOH_LocalPlayer) end)
        end)
    end,
})
TOH_Tabs.Server:AddButton({
    Title = "Server Hop",
    Description = "Joins a different public server",
    ButtonText = "Join",
    Callback = function()
        TOH_Notify("Server", "Joining another server...", "Info", 2)
        task.delay(0.5, function()
            pcall(function() TOH_TeleportService:Teleport(game.PlaceId, TOH_LocalPlayer) end)
        end)
    end,
})

TOH_Tabs.Settings:AddSection({ Title = "misc" })
TOH_Tabs.Settings:AddButton({
    Title = "Unload",
    Description = "Restores everything and closes the hub",
    ButtonText = "Unload",
    Callback = TOH_Unload,
})
TOH_Window:BuildConfigSection(TOH_Tabs.Settings)

TOH_Tabs.Credits:AddSection({ Title = "credits" })
TOH_Tabs.Credits:AddParagraph({
    Title = "Development",
    Content = "Developer: AkiraDev\nGitHub: github.com/akiradv\nDiscord: discord.gg/9VE4PXFDSg\n\nUI Library: Eazy UI " .. tostring(TOH_UIVersion) .. " by AkiraDev",
})

TOH_Env.TOH_Cleanup = TOH_Unload
TOH_Env.TOH_Unload = TOH_Unload

if TOH_Config.KillImmunity then TOH_ApplyAllKill() end
if TOH_Config.Noclip then TOH_ApplyNoclip() end
TOH_ApplyStats()
TOH_ApplyLighting()
TOH_SetFOV(TOH_Config.FOV)
TOH_ApplyAppearance()
TOH_UpdateESP()

TOH_Notify("ToH Hub", "v" .. TOH_Version .. " loaded successfully", "Success", 3)