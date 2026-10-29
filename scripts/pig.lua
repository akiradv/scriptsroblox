local EZ = loadstring(game:HttpGet("https://raw.githubusercontent.com/akiradv/eazyuilib/main/eazyui.lua"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local MarketplaceService = game:GetService("MarketplaceService")
local SoundService = game:GetService("SoundService")

local LocalPlayer = Players.LocalPlayer
local playerGui = LocalPlayer:WaitForChild("PlayerGui")

local SCRIPT_VERSION = "1.1.6"
local DISCORD_AKIRA = "2ksQSAnnW6"

local function getGuiParent()
    if gethui then
        local ok, h = pcall(gethui)
        if ok and h then return h end
    end
    local ok, cg = pcall(function() return game:GetService("CoreGui") end)
    if ok and cg then return cg end
    return playerGui
end

local ESPGui = Instance.new("ScreenGui")
ESPGui.Name = "PiggyHubESP"
ESPGui.ResetOnSpawn = false
ESPGui.IgnoreGuiInset = true
ESPGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ESPGui.DisplayOrder = 5
pcall(function() ESPGui.Parent = getGuiParent() end)

local function isPiggy()
    local ok, info = pcall(function()
        return MarketplaceService:GetProductInfo(game.PlaceId, Enum.InfoType.Asset)
    end)
    if ok and info and info.Name then
        local n = info.Name:lower()
        if n:find("piggy", 1, true) or n:find("decay", 1, true) then return true end
    end
    if game.Name then
        local n = game.Name:lower()
        if n:find("piggy", 1, true) or n:find("decay", 1, true) then return true end
    end
    if workspace:FindFirstChild("Bots") or workspace:FindFirstChild("PiggyNPC") or workspace:FindFirstChild("LoadedMap") then return true end
    return false
end

if not isPiggy() then
    EZ:Notify({ Title = "Piggy Hub", Content = "This script only works in Piggy games.", Style = "Error", Duration = 5 })
    return
end

local EXIT_PATTERNS = {
    "exit", "escape", "door", "goal", "objective", "checkpoint",
    "elevator", "gate", "safe", "save zone", "finish", "end game", "portal", "barrier"
}

local STRICT_EXIT_PATTERNS = {
    "exit", "escape", "goal", "finish", "end game", "objective", "portal", "door", "gate"
}

local PIGGY_MAPS = {
    "House", "Station", "Forest", "School", "Metro", "Carnival", "City",
    "Mall", "Plant", "Ship", "Distraction", "Gallery", "Heist", "Breakout",
    "Phenna", "Temple", "Camp", "Mansion", "Docks", "Delirium", "Decay",
    "Port", "Store", "Hospital", "Lab",
}

local State = {
    WalkSpeed = false, WSpeed = 30,
    JumpPower = false, JPower = 60,
    InfiniteJump = false,
    Noclip = false,
    Fly = false, FlySpeed = 60,
    AntiVoid = false,
    AutoEvade = false, EvadeRange = 25,
    GodMode = false, GodObj = false, GodStun = false,
    AntiRagdoll = false, AntiSlow = false,
    AntiAFK = false, AntiJumpscare = false,
    PanicKey = true,
    AutoRejoin = false,
    UnESPSelf = false, SpinBots = false,
    PlayerESP = true, PiggyESP = true, TraitorESP = true,
    FriendlyESP = false, NpcESP = false,
    ItemESP = true, ExitESP = true, TrapESP = false,
    ESPHighlight = true,
    ESPBoxes = false, ESPNames = true, ESPDistances = true, ESPHealth = true,
    ESPLines = false, ESPMaxDist = 500,
    Fullbright = false, NoFog = false,
    Crosshair = false, CrosshairColor = Color3.fromRGB(0, 188, 168),
    ChinaHat = false, ChinaHatColor = Color3.fromRGB(255, 123, 123),
    FpsCounter = false,
    AutoVoteMap = "House",
}

local COLORS = {
    Player = Color3.fromRGB(60, 130, 255),
    Bot = Color3.fromRGB(255, 60, 60),
    Traitor = Color3.fromRGB(255, 140, 0),
    Friendly = Color3.fromRGB(100, 255, 100),
    Npc = Color3.fromRGB(180, 100, 255),
    Item = Color3.fromRGB(255, 215, 100),
    Key = Color3.fromRGB(0, 255, 255),
    Exit = Color3.fromRGB(120, 255, 120),
    Trap = Color3.fromRGB(255, 80, 80),
    HealthHigh = Color3.fromRGB(0, 255, 0),
    HealthMid = Color3.fromRGB(255, 255, 0),
    HealthLow = Color3.fromRGB(255, 0, 0),
}

local PanicToggles = {}
local function PT(t) table.insert(PanicToggles, t) return t end

local S = {
    flyBV = nil, flyBG = nil, flyConn = nil,
    voidConn = nil, safeCF = nil,
    hatParts = {},
    crossLines = {}, crossOutlines = {}, crossConn = nil, crossRot = 0,
    afkConn = nil,
    targets = { char = nil, root = nil, list = {}, hums = {}, kind = {} },
    world = {},
    itemFolder = nil, itemFolderCheck = 0,
    fpsGui = nil, fpsConn = nil,
    evadeDirection = nil,
    evadeTimer = 0,
    highlights = {},
}

local function HRP()
    local c = LocalPlayer.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end
local function Hum()
    local c = LocalPlayer.Character
    return c and c:FindFirstChildOfClass("Humanoid")
end
local function safeTeleport(pos)
    local hrp = HRP()
    if not hrp then return end
    local hum = Hum()
    if hum then hum.PlatformStand = false end
    hrp.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
    hrp.Velocity = Vector3.zero
    hrp.RotVelocity = Vector3.zero
end
local function matches(name, patterns)
    if not name then return false end
    local l = name:lower()
    for i = 1, #patterns do
        if l:find(patterns[i], 1, true) then return true end
    end
    return false
end

local function isKeyName(n)
    if not n then return false end
    local l = n:lower()
    return l:find("key", 1, true) or l:find("passcode", 1, true) or l:find("card", 1, true) or l:find("crowbar", 1, true) or l:find("screwdriver", 1, true)
end

local function getItemFolder()
    if S.itemFolder and S.itemFolder.Parent then return S.itemFolder end
    local now = tick()
    if now - S.itemFolderCheck < 2 then return S.itemFolder end
    S.itemFolderCheck = now
    local f = workspace:FindFirstChild("ItemFolder1")
    if f then S.itemFolder = f return f end
    f = workspace:FindFirstChild("ItemFolder")
    if f then
        pcall(function() f.Name = "ItemFolder1" end)
        S.itemFolder = f
        return f
    end
    for _, child in ipairs(workspace:GetChildren()) do
        if child:IsA("Folder") and child.Name:lower():find("item", 1, true) then
            S.itemFolder = child
            return child
        end
    end
    return nil
end

local function isInteractable(part)
    if not part or not part.Parent then return false end
    if part.Transparency == 1 then return false end
    if part:FindFirstChildOfClass("ClickDetector") then return true end
    if part:FindFirstChildOfClass("ProximityPrompt") then return true end
    local parent = part.Parent
    if parent and (parent:FindFirstChildOfClass("ClickDetector") or parent:FindFirstChildOfClass("ProximityPrompt")) then
        return true
    end
    return false
end

local function findPiggy()
    local myRoot = HRP()
    if not myRoot then return nil end
    local best, bd = nil, math.huge
    local function check(model)
        if not model:FindFirstChild("Enemy") then return end
        if model:FindFirstChild("ToolRequired") then return end
        local root = model:FindFirstChild("HumanoidRootPart")
        local hum = model:FindFirstChildOfClass("Humanoid")
        if root and hum and hum.Health > 0 then
            local d = (root.Position - myRoot.Position).Magnitude
            if d < bd then bd = d best = model end
        end
    end
    local npc = workspace:FindFirstChild("PiggyNPC")
    if npc then
        for _, obj in ipairs(npc:GetChildren()) do
            if obj:IsA("Model") then check(obj) end
        end
    end
    local bots = workspace:FindFirstChild("Bots")
    if bots then
        for _, obj in ipairs(bots:GetChildren()) do
            if obj:IsA("Model") then check(obj) end
        end
    end
    if not best then
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Model") and obj:FindFirstChild("Enemy") then check(obj) end
        end
    end
    return best
end

local function isTraitor(char)
    return char and char:FindFirstChild("Traitor") ~= nil
end

local function findTraitor()
    local myRoot = HRP()
    if not myRoot then return nil end
    local best, bd = nil, math.huge
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and isTraitor(plr.Character) then
            local root = plr.Character:FindFirstChild("HumanoidRootPart")
            if root then
                local d = (root.Position - myRoot.Position).Magnitude
                if d < bd then bd = d best = plr.Character end
            end
        end
    end
    return best
end

local function refreshTargets()
    local t = S.targets
    table.clear(t.list) table.clear(t.hums) table.clear(t.kind)
    local myChar = LocalPlayer.Character
    t.char = myChar
    t.root = myChar and myChar:FindFirstChild("HumanoidRootPart")

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local char = plr.Character
            local root = char:FindFirstChild("HumanoidRootPart")
            local hum = char:FindFirstChildOfClass("Humanoid")
            if root and hum and hum.Health > 0 then
                t.list[root] = char
                t.hums[root] = hum
                t.kind[root] = isTraitor(char) and "traitor" or "player"
            end
        end
    end

    local function registerBot(model)
        if not model or model == myChar then return end
        if Players:GetPlayerFromCharacter(model) then return end
        if not model:FindFirstChild("Enemy") then return end
        local root = model:FindFirstChild("HumanoidRootPart")
        local hum = model:FindFirstChildOfClass("Humanoid")
        if root and hum and hum.Health > 0 and not t.list[root] then
            t.list[root] = model
            t.hums[root] = hum
            t.kind[root] = model:FindFirstChild("ToolRequired") and "friendly" or "piggy"
        end
    end

    local npc = workspace:FindFirstChild("PiggyNPC")
    if npc then
        for _, obj in ipairs(npc:GetChildren()) do
            if obj:IsA("Model") then registerBot(obj) end
        end
    end
    local bots = workspace:FindFirstChild("Bots")
    if bots then
        for _, obj in ipairs(bots:GetChildren()) do
            if obj:IsA("Model") then registerBot(obj) end
        end
    end
    if not npc and not bots then
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Model") and obj:FindFirstChild("Enemy") then registerBot(obj) end
        end
    end

    local function registerNpc(model)
        if not model or model == myChar then return end
        if Players:GetPlayerFromCharacter(model) then return end
        if model:FindFirstChild("Enemy") then return end
        local root = model:FindFirstChild("HumanoidRootPart")
        local hum = model:FindFirstChildOfClass("Humanoid")
        if root and hum and hum.Health > 0 and not t.list[root] then
            t.list[root] = model
            t.hums[root] = hum
            t.kind[root] = "npc"
        end
    end
    local npcFolder = workspace:FindFirstChild("NPCs") or workspace:FindFirstChild("Npcs")
    if npcFolder then
        for _, obj in ipairs(npcFolder:GetChildren()) do
            if obj:IsA("Model") then registerNpc(obj) end
        end
    end
end

local function refreshWorld()
    local t = S.world
    table.clear(t)
    local myRoot = S.targets.root
    if not myRoot then return end
    if not (State.ItemESP or State.ExitESP or State.TrapESP) then return end
    local maxD = State.ESPMaxDist

    if State.ItemESP then
        local folder = getItemFolder()
        if folder then
            for _, obj in ipairs(folder:GetDescendants()) do
                local part = nil
                if obj:IsA("BasePart") then part = obj
                elseif obj:IsA("Model") and obj.PrimaryPart then part = obj.PrimaryPart end
                if part and isInteractable(part) then
                    local isTrap = part.Name:lower():find("trap", 1, true) ~= nil
                    local isKey = isKeyName(part.Name)
                    local isBackdoor = part.Name:lower():find("backdoor", 1, true) ~= nil or part.Name:lower():find("back door", 1, true) ~= nil
                    
                    if not isBackdoor then
                        if (isTrap and State.TrapESP) or (not isTrap) then
                            local d = (part.Position - myRoot.Position).Magnitude
                            if d <= maxD then
                                t[#t + 1] = {
                                    part = part, dist = d,
                                    category = isTrap and "TRAP" or "ITEM",
                                    name = part.Name, isKey = isKey,
                                }
                            end
                        end
                    end
                end
            end
        end
    end

    if State.ExitESP then
        local targetFolder = workspace:FindFirstChild("LoadedMap") or workspace
        for _, obj in ipairs(targetFolder:GetDescendants()) do
            if obj:IsA("BasePart") and obj.Name and obj.Name ~= "" and obj.Transparency ~= 1 then
                if matches(obj.Name, EXIT_PATTERNS) and not obj:FindFirstChildOfClass("Humanoid") then
                    local d = (obj.Position - myRoot.Position).Magnitude
                    if d <= maxD then
                        t[#t + 1] = { part = obj, dist = d, category = "EXIT", name = obj.Name }
                    end
                end
            end
        end
    end
end

local function findStrictExitRaw()
    local myRoot = HRP()
    if not myRoot then return nil end
    local best, bd = nil, math.huge
    local targetFolder = workspace:FindFirstChild("LoadedMap") or workspace

    for _, obj in ipairs(targetFolder:GetDescendants()) do
        local isExitCandidate = false
        local part = nil

        if obj:IsA("ProximityPrompt") then
            local action = (obj.ActionText or ""):lower()
            local objectTxt = (obj.ObjectText or ""):lower()
            if action:find("escape", 1, true) or action:find("exit", 1, true) or objectTxt:find("escape", 1, true) or (action:find("open", 1, true) and objectTxt:find("door", 1, true)) then
                isExitCandidate = true
                local par = obj.Parent
                if par then
                    part = par:IsA("BasePart") and par or par:FindFirstChildWhichIsA("BasePart")
                end
            end
        elseif obj:IsA("ClickDetector") then
            local par = obj.Parent
            if par then
                local pName = (par.Name or ""):lower()
                if pName:find("exit", 1, true) or pName:find("escape", 1, true) or pName:find("door", 1, true) then
                    isExitCandidate = true
                    part = par:IsA("BasePart") and par or par:FindFirstChildWhichIsA("BasePart")
                end
            end
        elseif obj:IsA("BasePart") then
            local n = (obj.Name or ""):lower()
            local par = obj.Parent
            local parentName = par and (par.Name or ""):lower() or ""
            if (matches(n, STRICT_EXIT_PATTERNS) or matches(parentName, STRICT_EXIT_PATTERNS)) and not obj:FindFirstChildOfClass("Humanoid") then
                isExitCandidate = true
                part = obj
            end
            if not isExitCandidate and obj:FindFirstChildOfClass("TouchTransmitter") then
                if n:find("door", 1, true) or n:find("exit", 1, true) or n:find("escape", 1, true) then
                    isExitCandidate = true
                    part = obj
                end
            end
        end

        if isExitCandidate and part and part.Parent then
            local d = (part.Position - myRoot.Position).Magnitude
            if d < bd then bd = d best = part end
        end
    end
    return best, bd
end

local function findNearestExit()
    local exit, dist = findStrictExitRaw()
    if exit then return exit, dist end

    local myRoot = HRP()
    if not myRoot then return nil end
    local best, bd = nil, math.huge
    local targetFolder = workspace:FindFirstChild("LoadedMap") or workspace
    for _, obj in ipairs(targetFolder:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Name and obj.Name ~= "" then
            if matches(obj.Name, EXIT_PATTERNS) and not obj:FindFirstChildOfClass("Humanoid") then
                local d = (obj.Position - myRoot.Position).Magnitude
                if d < bd then bd = d best = obj end
            end
        end
    end
    return best, bd
end

local function findSafeEscapeDirection(piggyPos, myPos, piggyVel)
    local away = (myPos - piggyPos)
    if away.Magnitude < 0.1 then away = Vector3.new(1, 0, 0) end
    away = away.Unit

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    local ignore = {}
    if LocalPlayer.Character then table.insert(ignore, LocalPlayer.Character) end
    params.FilterDescendantsInstances = ignore

    local best, bestScore = nil, -math.huge
    for i = 0, 15 do
        local angle = (i / 16) * math.pi * 2
        local dir = Vector3.new(math.cos(angle), 0, math.sin(angle))
        local score = 0
        local hit = workspace:Raycast(myPos, dir * 50, params)
        if not hit then
            score = score + 100
        else
            score = score - (50 - hit.Distance) * 2.5
        end
        score = score + dir:Dot(away) * 90

        if piggyVel and piggyVel.Magnitude > 2 then
            local pv = Vector3.new(piggyVel.X, 0, piggyVel.Z)
            if pv.Magnitude > 0.1 then
                score = score - dir:Dot(pv.Unit) * 30
            end
        end

        local floorHit = workspace:Raycast(myPos + dir * 30, Vector3.new(0, -60, 0), params)
        if floorHit then
            score = score + 30
        else
            score = score - 60
        end

        if score > bestScore then
            bestScore = score
            best = dir
        end
    end
    return best
end

local function getOrCreateHighlight(target)
    if not target or not target.Parent then return nil end
    local hl = S.highlights[target]
    if hl and hl.Parent then return hl end
    hl = Instance.new("Highlight")
    hl.Name = "PiggyHub_HL"
    hl.Adornee = target
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = target
    S.highlights[target] = hl
    return hl
end

local function removeHighlight(target)
    local hl = S.highlights[target]
    if hl then
        pcall(function() hl:Destroy() end)
        S.highlights[target] = nil
    end
end

local function clearAllHighlights()
    for target, hl in pairs(S.highlights) do
        pcall(function() hl:Destroy() end)
    end
    S.highlights = {}
end

local function applyHighlight(target, color)
    local hl = getOrCreateHighlight(target)
    if not hl then return end
    hl.FillColor = color
    hl.OutlineColor = color
end

local ESP = { pool = {}, active = {}, maxPool = 200 }

local function acquireEntry()
    local e = table.remove(ESP.pool)
    if e then return e end

    local box = Instance.new("Frame")
    box.BackgroundTransparency = 1
    box.BorderSizePixel = 0
    box.Visible = false
    box.ZIndex = 2
    box.Parent = ESPGui
    local boxStroke = Instance.new("UIStroke")
    boxStroke.Thickness = 1
    boxStroke.Parent = box

    local nameLbl = Instance.new("TextLabel")
    nameLbl.BackgroundTransparency = 1
    nameLbl.Font = Enum.Font.GothamBold
    nameLbl.TextSize = 12
    nameLbl.TextStrokeTransparency = 0
    nameLbl.TextStrokeColor3 = Color3.new(0, 0, 0)
    nameLbl.Size = UDim2.new(0, 240, 0, 14)
    nameLbl.TextXAlignment = Enum.TextXAlignment.Center
    nameLbl.Visible = false
    nameLbl.ZIndex = 2
    nameLbl.Parent = ESPGui

    local distLbl = Instance.new("TextLabel")
    distLbl.BackgroundTransparency = 1
    distLbl.Font = Enum.Font.Gotham
    distLbl.TextSize = 10
    distLbl.TextStrokeTransparency = 0
    distLbl.TextStrokeColor3 = Color3.new(0, 0, 0)
    distLbl.TextColor3 = Color3.fromRGB(180, 210, 205)
    distLbl.Size = UDim2.new(0, 120, 0, 12)
    distLbl.TextXAlignment = Enum.TextXAlignment.Center
    distLbl.Visible = false
    distLbl.ZIndex = 2
    distLbl.Parent = ESPGui

    local healthBg = Instance.new("Frame")
    healthBg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    healthBg.BorderSizePixel = 0
    healthBg.Visible = false
    healthBg.ZIndex = 2
    healthBg.Parent = ESPGui
    local healthBar = Instance.new("Frame")
    healthBar.BackgroundColor3 = COLORS.HealthHigh
    healthBar.BorderSizePixel = 0
    healthBar.Visible = false
    healthBar.ZIndex = 3
    healthBar.Parent = ESPGui

    local line = Instance.new("Frame")
    line.AnchorPoint = Vector2.new(0.5, 0.5)
    line.BorderSizePixel = 0
    line.Visible = false
    line.ZIndex = 1
    line.Parent = ESPGui

    return {
        Box = box, Stroke = boxStroke,
        Name = nameLbl, Dist = distLbl,
        HealthBg = healthBg, HealthBar = healthBar,
        Line = line,
    }
end

local function releaseEntry(entry)
    if not entry then return end
    entry.Box.Visible = false
    entry.Name.Visible = false
    entry.Dist.Visible = false
    entry.HealthBg.Visible = false
    entry.HealthBar.Visible = false
    entry.Line.Visible = false
    if #ESP.pool < ESP.maxPool then
        table.insert(ESP.pool, entry)
    else
        entry.Box:Destroy()
        entry.Name:Destroy() entry.Dist:Destroy()
        entry.HealthBg:Destroy() entry.HealthBar:Destroy() entry.Line:Destroy()
    end
end

local function hideEntry(entry)
    entry.Box.Visible = false
    entry.Name.Visible = false
    entry.Dist.Visible = false
    entry.HealthBg.Visible = false
    entry.HealthBar.Visible = false
    entry.Line.Visible = false
end

local function kindColor(kind)
    if kind == "piggy" then return COLORS.Bot
    elseif kind == "traitor" then return COLORS.Traitor
    elseif kind == "friendly" then return COLORS.Friendly
    elseif kind == "npc" then return COLORS.Npc
    else return COLORS.Player end
end

local function kindWanted(kind)
    if kind == "piggy" then return State.PiggyESP
    elseif kind == "traitor" then return State.TraitorESP
    elseif kind == "friendly" then return State.FriendlyESP
    elseif kind == "npc" then return State.NpcESP
    else return State.PlayerESP end
end

local function applyTargetHighlights()
    if not State.ESPHighlight then
        clearAllHighlights()
        return
    end
    local myRoot = S.targets.root
    if not myRoot then return end
    local maxD = State.ESPMaxDist
    local used = {}

    for root, char in pairs(S.targets.list) do
        if char and char.Parent and root and root.Parent then
            local hum = S.targets.hums[root]
            if hum and hum.Health > 0 then
                local kind = S.targets.kind[root] or "player"
                if kindWanted(kind) then
                    local dist = (root.Position - myRoot.Position).Magnitude
                    if dist <= maxD then
                        local col = kindColor(kind)
                        local target = char
                        used[target] = true
                        applyHighlight(target, col)
                    end
                end
            end
        end
    end

    for i = 1, #S.world do
        local info = S.world[i]
        local part = info.part
        if part and part.Parent then
            local col = COLORS.Item
            if info.isKey then col = COLORS.Key
            elseif info.category == "EXIT" then col = COLORS.Exit
            elseif info.category == "TRAP" then col = COLORS.Trap end
            used[part] = true
            applyHighlight(part, col)
        end
    end

    for target, hl in pairs(S.highlights) do
        if not used[target] or not target.Parent then
            removeHighlight(target)
        end
    end
end

local function renderTargetESP(used)
    local cam = workspace.CurrentCamera
    if not cam then return end
    local myRoot = S.targets.root
    if not myRoot or not myRoot.Parent then return end
    local maxD = State.ESPMaxDist
    local vp = cam.ViewportSize
    local showBox = State.ESPBoxes
    local showName = State.ESPNames
    local showDist = State.ESPDistances
    local showHP = State.ESPHealth
    local showLine = State.ESPLines
    local vpHalf = Vector2.new(vp.X / 2, vp.Y)
    for root, char in pairs(S.targets.list) do
        if char and char.Parent and root and root.Parent then
            local hum = S.targets.hums[root]
            if hum and hum.Health > 0 then
                local kind = S.targets.kind[root] or "player"
                if kindWanted(kind) then
                    local dist = (root.Position - myRoot.Position).Magnitude
                    if dist <= maxD then
                        local entry = ESP.active[root]
                        if not entry then
                            entry = acquireEntry()
                            ESP.active[root] = entry
                        end
                        used[root] = true
                        local pos, onScreen = cam:WorldToViewportPoint(root.Position)
                        if onScreen and pos.Z > 0
                            and pos.X > -100 and pos.X < vp.X + 100
                            and pos.Y > -100 and pos.Y < vp.Y + 100 then
                            local scale = 1000 / math.max(dist, 1)
                            local boxW = math.clamp(3 * scale, 12, 220)
                            local boxH = boxW * 1.5
                            local col = kindColor(kind)

                            if showBox then
                                entry.Box.Size = UDim2.new(0, boxW, 0, boxH)
                                entry.Box.Position = UDim2.new(0, pos.X - boxW * 0.5, 0, pos.Y - boxH * 0.5)
                                entry.Box.Visible = true
                                entry.Stroke.Color = col
                            else
                                entry.Box.Visible = false
                            end

                            local anchorTop = showBox and (boxH * 0.5) or 0
                            local anchorBot = anchorTop

                            if showName then
                                local prefix = ""
                                if kind == "piggy" then prefix = "[PIGGY] "
                                elseif kind == "traitor" then prefix = "[TRAITOR] "
                                elseif kind == "friendly" then prefix = "[ALLY] "
                                elseif kind == "npc" then prefix = "[NPC] " end
                                entry.Name.Text = prefix .. char.Name
                                entry.Name.TextColor3 = col
                                entry.Name.Position = UDim2.new(0, pos.X - 120, 0, pos.Y - anchorTop - 16)
                                entry.Name.Visible = true
                            else
                                entry.Name.Visible = false
                            end

                            if showDist then
                                entry.Dist.Text = string.format("%dm", math.floor(dist))
                                entry.Dist.TextColor3 = col
                                entry.Dist.Position = UDim2.new(0, pos.X - 60, 0, pos.Y + anchorBot + 2)
                                entry.Dist.Visible = true
                            else
                                entry.Dist.Visible = false
                            end

                            if showHP then
                                local pct = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
                                local barX = pos.X - boxW * 0.5 - 6
                                entry.HealthBg.Size = UDim2.new(0, 4, 0, boxH + 2)
                                entry.HealthBg.Position = UDim2.new(0, barX - 1, 0, pos.Y - boxH * 0.5 - 1)
                                entry.HealthBg.Visible = true
                                local hh = boxH * pct
                                entry.HealthBar.Size = UDim2.new(0, 4, 0, hh)
                                entry.HealthBar.Position = UDim2.new(0, barX, 0, pos.Y + boxH * 0.5 - hh)
                                entry.HealthBar.BackgroundColor3 = pct > 0.6 and COLORS.HealthHigh or pct > 0.3 and COLORS.HealthMid or COLORS.HealthLow
                                entry.HealthBar.Visible = true
                            else
                                entry.HealthBg.Visible = false
                                entry.HealthBar.Visible = false
                            end

                            if showLine then
                                local dx = pos.X - vpHalf.X
                                local dy = pos.Y - vpHalf.Y
                                local len = math.sqrt(dx * dx + dy * dy)
                                entry.Line.Size = UDim2.new(0, 1, 0, len)
                                entry.Line.Position = UDim2.new(0, (pos.X + vpHalf.X) / 2, 0, (pos.Y + vpHalf.Y) / 2)
                                entry.Line.Rotation = math.deg(math.atan2(dy, dx)) - 90
                                entry.Line.BackgroundColor3 = col
                                entry.Line.Visible = true
                            else
                                entry.Line.Visible = false
                            end
                        else
                            hideEntry(entry)
                        end
                    end
                end
            end
        end
    end
end

local function renderWorldESP(used)
    if not (State.ItemESP or State.ExitESP or State.TrapESP) then return end
    local cam = workspace.CurrentCamera
    if not cam then return end
    local vp = cam.ViewportSize
    local showBox = State.ESPBoxes
    local showName = State.ESPNames
    local showDist = State.ESPDistances
    for i = 1, #S.world do
        local info = S.world[i]
        local part = info.part
        if part and part.Parent then
            local entry = ESP.active[part]
            if not entry then
                entry = acquireEntry()
                ESP.active[part] = entry
            end
            used[part] = true
            local pos, onScreen = cam:WorldToViewportPoint(part.Position)
            if onScreen and pos.Z > 0
                and pos.X > -80 and pos.X < vp.X + 80
                and pos.Y > -80 and pos.Y < vp.Y + 80 then
                local scale = 1000 / math.max(info.dist, 1)
                local size = math.clamp(2 * scale, 10, 80)
                local col = COLORS.Item
                if info.isKey then col = COLORS.Key
                elseif info.category == "EXIT" then col = COLORS.Exit
                elseif info.category == "TRAP" then col = COLORS.Trap end

                if showBox then
                    entry.Box.Size = UDim2.new(0, size, 0, size)
                    entry.Box.Position = UDim2.new(0, pos.X - size * 0.5, 0, pos.Y - size * 0.5)
                    entry.Box.Visible = true
                    entry.Stroke.Color = col
                else
                    entry.Box.Visible = false
                end

                if showName then
                    entry.Name.Text = info.name or part.Name
                    entry.Name.TextColor3 = col
                    entry.Name.Position = UDim2.new(0, pos.X - 120, 0, pos.Y - size * 0.5 - 16)
                    entry.Name.Visible = true
                else
                    entry.Name.Visible = false
                end

                if showDist then
                    entry.Dist.Text = string.format("%dm", math.floor(info.dist))
                    entry.Dist.TextColor3 = col
                    entry.Dist.Position = UDim2.new(0, pos.X - 60, 0, pos.Y + size * 0.5 + 2)
                    entry.Dist.Visible = true
                else
                    entry.Dist.Visible = false
                end

                entry.HealthBg.Visible = false
                entry.HealthBar.Visible = false
                entry.Line.Visible = false
            else
                hideEntry(entry)
            end
        end
    end
end

local function getPlayerList()
    local names = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then names[#names + 1] = p.Name end
    end
    return names
end

local function setNoClip(state)
    local c = LocalPlayer.Character
    if not c then return end
    for _, p in ipairs(c:GetDescendants()) do
        if p:IsA("BasePart") then
            if state then
                p.CanCollide = false
            else
                if p.Name == "HumanoidRootPart" or p.Name == "Head" or p.Name == "Torso" or p.Name == "UpperTorso" or p.Name == "LowerTorso" then
                    p.CanCollide = true
                end
            end
        end
    end
end

local function startFly()
    if S.flyConn then return end
    local hrp = HRP()
    local hum = Hum()
    if not hrp or not hum then return end
    hum.PlatformStand = true
    S.flyBV = Instance.new("BodyVelocity")
    S.flyBV.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    S.flyBV.Parent = hrp
    S.flyBG = Instance.new("BodyGyro")
    S.flyBG.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
    S.flyBG.P = 1e4
    S.flyBG.Parent = hrp
    S.flyConn = RunService.Heartbeat:Connect(function()
        if not State.Fly then return end
        local cur = HRP()
        if not cur then return end
        if not S.flyBV or not S.flyBV.Parent then return end
        local mv = Vector3.zero
        local cam = workspace.CurrentCamera
        if not cam then return end
        local cf = cam.CFrame
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then mv = mv + cf.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then mv = mv - cf.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then mv = mv - cf.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then mv = mv + cf.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then mv = mv + Vector3.yAxis end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then mv = mv - Vector3.yAxis end
        S.flyBV.Velocity = mv.Magnitude > 0 and mv.Unit * State.FlySpeed or Vector3.zero
        S.flyBG.CFrame = cf
    end)
end

local function stopFly()
    if S.flyConn then S.flyConn:Disconnect() S.flyConn = nil end
    if S.flyBV then S.flyBV:Destroy() S.flyBV = nil end
    if S.flyBG then S.flyBG:Destroy() S.flyBG = nil end
    local hum = Hum()
    if hum then hum.PlatformStand = false end
end

local function startVoid()
    if S.voidConn then return end
    S.voidConn = RunService.Heartbeat:Connect(function()
        if not State.AntiVoid then return end
        local hrp = HRP()
        if not hrp then S.safeCF = nil return end
        if hrp.Position.Y >= 10 then S.safeCF = hrp.CFrame
        elseif hrp.Position.Y <= -30 and S.safeCF then
            hrp.CFrame = S.safeCF
            hrp.Velocity = Vector3.zero
        end
    end)
end

local function stopVoid()
    if S.voidConn then S.voidConn:Disconnect() S.voidConn = nil end
    S.safeCF = nil
end

local function setGodModeParts(state)
    local char = LocalPlayer.Character
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanTouch = not state
        end
    end
end

local function applyFullbright()
    if State.Fullbright then
        Lighting.Ambient = Color3.fromRGB(200, 200, 200)
        Lighting.OutdoorAmbient = Color3.fromRGB(200, 200, 200)
        Lighting.Brightness = 2
    else
        Lighting.Ambient = Color3.fromRGB(70, 70, 70)
        Lighting.OutdoorAmbient = Color3.fromRGB(70, 70, 70)
        Lighting.Brightness = 1
    end
end

local function applyChinaHat()
    for _, p in ipairs(S.hatParts) do pcall(function() p:Destroy() end) end
    S.hatParts = {}
    if not State.ChinaHat then return end
    local char = LocalPlayer.Character
    if not char then return end
    local head = char:FindFirstChild("Head")
    if not head then return end
    local hat = Instance.new("Part")
    hat.Name = "ChinaHat"
    hat.Size = Vector3.new(1, 1, 1)
    hat.Color = State.ChinaHatColor
    hat.Material = Enum.Material.Neon
    hat.Transparency = 0.2
    hat.CanCollide = false
    hat.Anchored = false
    hat.Parent = char
    table.insert(S.hatParts, hat)
    local mesh = Instance.new("SpecialMesh")
    mesh.MeshType = Enum.MeshType.FileMesh
    mesh.MeshId = "rbxassetid://1033714"
    mesh.Scale = Vector3.new(1.7, 1.1, 1.7)
    mesh.Parent = hat
    local weld = Instance.new("Weld")
    weld.Part0 = head
    weld.Part1 = hat
    weld.C0 = CFrame.new(0, 0.9, 0)
    weld.Parent = hat
    local light = Instance.new("PointLight")
    light.Color = State.ChinaHatColor
    light.Brightness = 1
    light.Range = 12
    light.Shadows = true
    light.Parent = hat
end

local function applyCrosshair()
    for _, l in ipairs(S.crossLines) do pcall(function() l:Remove() end) end
    for _, o in ipairs(S.crossOutlines) do pcall(function() o:Remove() end) end
    S.crossLines = {}
    S.crossOutlines = {}
    if S.crossConn then S.crossConn:Disconnect() S.crossConn = nil end
    if not State.Crosshair then
        UserInputService.MouseIconEnabled = true
        return
    end
    local hasDrawing = pcall(function() return Drawing.new("Line") end)
    if not hasDrawing then
        EZ:Notify({ Title = "Visuals", Content = "Crosshair needs Drawing API support.", Style = "Warning", Duration = 3 })
        State.Crosshair = false
        UserInputService.MouseIconEnabled = true
        return
    end
    UserInputService.MouseIconEnabled = false
    for i = 1, 4 do
        local outline = Drawing.new("Line")
        outline.Thickness = 3
        outline.Color = Color3.new(0, 0, 0)
        outline.Transparency = 1
        outline.Visible = true
        table.insert(S.crossOutlines, outline)
        local line = Drawing.new("Line")
        line.Thickness = 1.5
        line.Color = State.CrosshairColor
        line.Transparency = 1
        line.Visible = true
        table.insert(S.crossLines, line)
    end
    S.crossConn = RunService.RenderStepped:Connect(function()
        if not State.Crosshair or #S.crossLines < 4 then return end
        local mouse = UserInputService:GetMouseLocation()
        S.crossRot = S.crossRot + math.rad(2)
        if S.crossRot >= math.pi * 2 then S.crossRot = 0 end
        local gap, sz = 6, 12
        local dirs = {
            { from = Vector2.new(0, -gap - sz), to = Vector2.new(0, -gap) },
            { from = Vector2.new(0, gap), to = Vector2.new(0, gap + sz) },
            { from = Vector2.new(-gap - sz, 0), to = Vector2.new(-gap, 0) },
            { from = Vector2.new(gap, 0), to = Vector2.new(gap + sz, 0) },
        }
        local cosR, sinR = math.cos(S.crossRot), math.sin(S.crossRot)
        for i = 1, 4 do
            local ff = dirs[i].from + mouse
            local tt = dirs[i].to + mouse
            local rf = Vector2.new(mouse.X + (ff.X - mouse.X) * cosR - (ff.Y - mouse.Y) * sinR, mouse.Y + (ff.X - mouse.X) * sinR + (ff.Y - mouse.Y) * cosR)
            local rt = Vector2.new(mouse.X + (tt.X - mouse.X) * cosR - (tt.Y - mouse.Y) * sinR, mouse.Y + (tt.X - mouse.X) * sinR + (tt.Y - mouse.Y) * cosR)
            if S.crossOutlines[i] then S.crossOutlines[i].From = rf S.crossOutlines[i].To = rt end
            if S.crossLines[i] then S.crossLines[i].From = rf S.crossLines[i].To = rt end
        end
    end)
end

local function panicOff()
    for _, t in ipairs(PanicToggles) do
        pcall(function() t:Set(false, false) end)
    end
    State.Fly = false State.Noclip = false
    State.AutoEvade = false
    State.GodMode = false State.GodObj = false State.GodStun = false
    State.AntiRagdoll = false State.AntiSlow = false
    State.Crosshair = false State.ChinaHat = false
    State.PlayerESP = false State.PiggyESP = false State.TraitorESP = false
    State.FriendlyESP = false State.NpcESP = false State.ItemESP = false
    State.ExitESP = false State.TrapESP = false
    State.SpinBots = false State.UnESPSelf = false State.FpsCounter = false
    State.ESPHighlight = false
    stopFly() stopVoid() applyChinaHat() applyCrosshair()
    setGodModeParts(false)
    clearAllHighlights()
    if S.fpsGui then S.fpsGui:Destroy() S.fpsGui = nil end
    if S.fpsConn then S.fpsConn:Disconnect() S.fpsConn = nil end
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj.Name == "PiggyHubSpin" and obj:IsA("BodyAngularVelocity") then
            pcall(function() obj:Destroy() end)
        end
    end
    EZ:Notify({ Title = "Panic", Content = "All features disabled.", Style = "Warning", Duration = 3 })
end

task.spawn(function()
    while true do task.wait(0.5) pcall(refreshTargets) end
end)

task.spawn(function()
    while true do
        task.wait(1.2)
        if State.ItemESP or State.ExitESP or State.TrapESP then pcall(refreshWorld) end
    end
end)

task.spawn(function()
    while true do
        task.wait(0.3)
        if State.GodMode then
            setGodModeParts(true)
        end
        if State.GodObj or State.GodStun then
            local folder = getItemFolder()
            if folder then
                for _, obj in ipairs(folder:GetDescendants()) do
                    local isStun = obj:IsA("Model") and obj:FindFirstChild("ToolRequired") ~= nil
                    if (State.GodObj and not isStun) or (State.GodStun and isStun) then
                        for _, er in ipairs(obj:GetDescendants()) do
                            if er:IsA("TouchTransmitter") then er:Destroy() end
                        end
                    end
                end
            end
        end
        if State.AntiRagdoll then
            local hum = Hum()
            if hum then
                hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
                hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
            end
        end
        if State.UnESPSelf then
            local char = LocalPlayer.Character
            if char then
                for _, child in ipairs(char:GetChildren()) do
                    if child:IsA("Highlight") or child:IsA("BillboardGui") then
                        child:Destroy()
                    end
                end
            end
        end
    end
end)

RunService.Heartbeat:Connect(function()
    local hum = Hum()
    local hrp = HRP()

    if hum then
        if State.WalkSpeed and hum.WalkSpeed ~= State.WSpeed then
            hum.WalkSpeed = State.WSpeed
        end
        if State.JumpPower then
            hum.UseJumpPower = true
            if hum.JumpPower ~= State.JPower then hum.JumpPower = State.JPower end
        end
    end
    if not hum or not hrp then return end

    if State.AutoEvade then
        local piggy = findPiggy()
        if piggy then
            local proot = piggy:FindFirstChild("HumanoidRootPart")
            local phum = piggy:FindFirstChildOfClass("Humanoid")
            if proot then
                local d = (hrp.Position - proot.Position).Magnitude
                if d < State.EvadeRange then
                    S.evadeTimer = S.evadeTimer - 0.0166
                    if S.evadeTimer <= 0 or not S.evadeDirection then
                        local pvel = phum and phum.MoveDirection * (phum.WalkSpeed or 0) or proot.Velocity
                        S.evadeDirection = findSafeEscapeDirection(proot.Position, hrp.Position, pvel)
                        S.evadeTimer = 0.25
                    end
                    if S.evadeDirection then
                        hum:Move(S.evadeDirection, false)
                    end
                else
                    S.evadeDirection = nil
                    S.evadeTimer = 0
                end
            end
        else
            S.evadeDirection = nil
            S.evadeTimer = 0
        end
    end

    if State.AntiSlow then
        local hum2 = Hum()
        if hum2 and hum2.WalkSpeed < 16 then hum2.WalkSpeed = 16 end
    end
end)

RunService.RenderStepped:Connect(function()
    pcall(function()
        local cam = workspace.CurrentCamera
        if not cam then return end
        if not ESPGui.Parent then
            pcall(function() ESPGui.Parent = getGuiParent() end)
        end
        local used = {}
        renderTargetESP(used)
        renderWorldESP(used)
        for inst, entry in pairs(ESP.active) do
            if not used[inst] or not inst.Parent then
                releaseEntry(entry)
                ESP.active[inst] = nil
            end
        end
        applyTargetHighlights()
    end)
end)

RunService.Stepped:Connect(function()
    if not State.Noclip then return end
    local char = LocalPlayer.Character
    if not char then return end
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end
    end
end)

UserInputService.JumpRequest:Connect(function()
    if not State.InfiniteJump then return end
    local hum = Hum()
    if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
end)

task.spawn(function()
    while true do
        if State.AntiJumpscare then
            local guiParents = { playerGui }
            pcall(function() table.insert(guiParents, game:GetService("CoreGui")) end)
            for _, parent in ipairs(guiParents) do
                for _, g in ipairs(parent:GetChildren()) do
                    if g:IsA("ScreenGui") and g.Name ~= "PiggyHubESP" and g.Name ~= "PiggyHubFPS" then
                        local gn = g.Name:lower()
                        if gn:find("scare", 1, true) or gn:find("jump", 1, true) or gn:find("horror", 1, true) then
                            pcall(function() g.Enabled = false end)
                        else
                            for _, c in ipairs(g:GetDescendants()) do
                                if c:IsA("ImageLabel") or c:IsA("ImageButton") then
                                    local cn = (c.Name .. " " .. tostring(c.Image)):lower()
                                    if cn:find("scare", 1, true) or cn:find("jump", 1, true) or cn:find("scream", 1, true) then
                                        c.Visible = false
                                    end
                                end
                            end
                        end
                    end
                end
            end
            for _, s in ipairs(SoundService:GetDescendants()) do
                if s:IsA("Sound") and s.Playing then
                    local sn = s.Name:lower()
                    if sn:find("scare", 1, true) or sn:find("jump", 1, true) or sn:find("scream", 1, true) or sn:find("horror", 1, true) then
                        pcall(function() s:Stop() end)
                        pcall(function() s.Volume = 0 end)
                    end
                end
            end
            local cc = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
            if cc and cc.Enabled then
                cc.Enabled = false
            end
        end
        task.wait(0.25)
    end
end)

task.spawn(function()
    while true do
        if State.SpinBots then
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("Model") and obj:FindFirstChild("Enemy") and not obj:FindFirstChild("ToolRequired") then
                    local root = obj:FindFirstChild("HumanoidRootPart")
                    if root and not root:FindFirstChild("PiggyHubSpin") then
                        local spin = Instance.new("BodyAngularVelocity")
                        spin.Name = "PiggyHubSpin"
                        spin.Parent = root
                        spin.MaxTorque = Vector3.new(0, math.huge, 0)
                        spin.AngularVelocity = Vector3.new(0, 35, 0)
                    end
                end
            end
        end
        task.wait(1.5)
    end
end)

local function makeKillTool()
    local old = LocalPlayer.Backpack:FindFirstChild("Kill Piggy Tool") or (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Kill Piggy Tool"))
    if old then old:Destroy() end
    local tool = Instance.new("Tool")
    tool.Name = "Kill Piggy Tool"
    tool.RequiresHandle = false
    tool.ToolTip = "Click a Piggy bot to kill it"
    tool.Parent = LocalPlayer.Backpack
    tool.Activated:Connect(function()
        local mouse = LocalPlayer:GetMouse()
        local target = mouse and mouse.Target
        if not target then return end
        local model = target
        while model and model ~= workspace and not model:FindFirstChildOfClass("Humanoid") do
            model = model.Parent
        end
        if model and model:FindFirstChildOfClass("Humanoid") and model:FindFirstChild("Enemy") then
            local root = model:FindFirstChild("HumanoidRootPart")
            local hum = model:FindFirstChildOfClass("Humanoid")
            if root and hum then
                for _, v in ipairs(model:GetDescendants()) do
                    if v:IsA("BasePart") then v.CanCollide = false end
                end
                root.Anchored = false
                hum.PlatformStand = true
                local bv = Instance.new("BodyVelocity")
                bv.Velocity = Vector3.new(0, -1000, 0)
                bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                bv.P = math.huge
                bv.Parent = root
            end
        end
    end)
end

local function revealDoorCodes()
    local revealed = 0
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("SurfaceGui") then
            obj.Enabled = true
            revealed = revealed + 1
        end
        if obj:IsA("TextLabel") and (obj.Text:match("^%d%d%d%d$") or obj.Text:match("^%d%d%d$")) then
            obj.TextTransparency = 0
            obj.TextStrokeTransparency = 0
        end
    end
    EZ:Notify({ Title = "Reveal Codes", Content = "Revealed " .. revealed .. " panels. Codes on doors should now be visible.", Style = "Success", Duration = 3 })
end

local function fpsBoost()
    local count = 0
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("Part") or v:IsA("MeshPart") or v:IsA("UnionOperation") then
            pcall(function() v.Material = Enum.Material.SmoothPlastic end)
            count = count + 1
        end
    end
    EZ:Notify({ Title = "FPS Booster", Content = "Smoothed " .. count .. " parts.", Style = "Success", Duration = 3 })
end

local function toggleFpsCounter(state)
    if S.fpsGui then S.fpsGui:Destroy() S.fpsGui = nil end
    if S.fpsConn then S.fpsConn:Disconnect() S.fpsConn = nil end
    if not state then return end
    local gui = Instance.new("ScreenGui")
    gui.Name = "PiggyHubFPS"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 50
    pcall(function() gui.Parent = getGuiParent() end)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.fromOffset(170, 32)
    lbl.Position = UDim2.new(0, 12, 1, -44)
    lbl.BackgroundTransparency = 0.45
    lbl.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    lbl.TextColor3 = Color3.fromRGB(0, 255, 100)
    lbl.Font = Enum.Font.Code
    lbl.TextSize = 14
    lbl.Text = "FPS: 60 | Ping: 30ms"
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = gui
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = lbl
    local pad = Instance.new("UIPadding")
    pad.PaddingLeft = UDim.new(0, 8)
    pad.Parent = lbl
    S.fpsGui = gui
    S.fpsConn = RunService.RenderStepped:Connect(function(dt)
        if not lbl.Parent then return end
        local fps = math.round(1 / dt)
        local ping = 0
        pcall(function()
            ping = math.round(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue())
        end)
        lbl.Text = string.format("FPS: %d | Ping: %dms", fps, ping)
    end)
end

local vu
pcall(function() vu = game:GetService("VirtualUser") end)
if vu then
    S.afkConn = LocalPlayer.Idled:Connect(function()
        if not State.AntiAFK then return end
        vu:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
        task.wait(1)
        vu:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
    end)
end

local Window = EZ:CreateWindow({
    Name = "Piggy Hub",
    SubTitle = "by AkiraDev",
    Size = UDim2.fromOffset(660, 560),
    MinimizeKey = Enum.KeyCode.RightShift,
    ConfigId = "Piggy_Hub_v3",
    AutoLoad = true,
    NotifyPosition = "BottomRight",
    LoadingTitle = "Piggy Hub",
    LoadingSubtitle = "Loading...",
    LoadingDuration = 1.2,
    Discord = { Enabled = true, Invite = DISCORD_AKIRA },
})

local Main = Window:AddTab({ Title = "Main", Icon = "house" })
local MovementTab = Window:AddTab({ Title = "Movement", Icon = "zap" })
local ESPTab = Window:AddTab({ Title = "ESP", Icon = "eye" })
local TrollTab = Window:AddTab({ Title = "Troll", Icon = "skull" })
local TeleportTab = Window:AddTab({ Title = "Teleport", Icon = "navigation" })
local VisualsTab = Window:AddTab({ Title = "Visuals", Icon = "palette" })
local UtilityTab = Window:AddTab({ Title = "Utility", Icon = "settings" })
local Config = Window:AddTab({ Title = "Config", Icon = "sliders" })
local Credits = Window:AddTab({ Title = "Credits", Icon = "info" })

local flyToggle, noclipToggle, fullbrightToggle

Main:AddSection({ Title = "player" })
Main:AddSlider({ Title = "Walk Speed", Description = "Character walking speed", Min = 16, Max = 200, Default = 30, Step = 1, Flag = "WSpeed", Callback = function(v)
    State.WSpeed = v
    if State.WalkSpeed then local h = Hum() if h then h.WalkSpeed = v end end
end })
PT(Main:AddToggle({ Title = "Enable Walk Speed", Description = "Apply the walk speed value", Flag = "WalkSpeedOn", Default = false, Callback = function(v)
    State.WalkSpeed = v
    local h = Hum()
    if h then h.WalkSpeed = v and State.WSpeed or 16 end
end }))
Main:AddSlider({ Title = "Jump Power", Description = "Jump height", Min = 50, Max = 300, Default = 60, Step = 5, Flag = "JPower", Callback = function(v)
    State.JPower = v
    if State.JumpPower then local h = Hum() if h then h.JumpPower = v end end
end })
PT(Main:AddToggle({ Title = "Enable Jump Power", Description = "Apply the jump power value", Flag = "JumpPowerOn", Default = false, Callback = function(v)
    State.JumpPower = v
    local h = Hum()
    if h then h.UseJumpPower = true h.JumpPower = v and State.JPower or 50 end
end }))
PT(Main:AddToggle({ Title = "Infinite Jump", Description = "Jump again while airborne", Flag = "InfJump", Default = false, Callback = function(v) State.InfiniteJump = v end }))

Main:AddSection({ Title = "protection" })
PT(Main:AddToggle({ Title = "God Mode (Bots)", Description = "Blocks bot contact. Warning: You cannot escape with this on.", Flag = "GodMode", Default = false, Callback = function(v)
    State.GodMode = v
    setGodModeParts(v)
end }))
PT(Main:AddToggle({ Title = "God Mode (Objects)", Description = "Removes touch from traps and hazards", Flag = "GodObj", Default = false, Callback = function(v) State.GodObj = v end }))
PT(Main:AddToggle({ Title = "God Mode (Stunners)", Description = "Removes touch from ally bots that stun", Flag = "GodStun", Default = false, Callback = function(v) State.GodStun = v end }))
PT(Main:AddToggle({ Title = "Anti-Ragdoll", Description = "Prevents ragdoll and falling down states", Flag = "AntiRag", Default = false, Callback = function(v) State.AntiRagdoll = v end }))
PT(Main:AddToggle({ Title = "Anti-Slow", Description = "Restores walkspeed if traps reduce it", Flag = "AntiSlow", Default = false, Callback = function(v) State.AntiSlow = v end }))
PT(Main:AddToggle({ Title = "Anti-AFK", Description = "Block the idle kick", Flag = "AntiAFK", Default = false, Callback = function(v) State.AntiAFK = v end }))
PT(Main:AddToggle({ Title = "Anti-Jumpscare", Description = "Hides jumpscare screens and stops scream sounds", Flag = "AntiJS", Default = false, Callback = function(v) State.AntiJumpscare = v end }))

Main:AddSection({ Title = "keybinds" })
local panicKeybind = Main:AddKeybind({
    Title = "Panic Key",
    Default = Enum.KeyCode.P,
    Flag = "PanicBind",
    Callback = function()
        if State.PanicKey then
            panicOff()
        end
    end,
})
task.defer(function() pcall(function() panicKeybind:Set(Enum.KeyCode.P) end) end)

MovementTab:AddSection({ Title = "flight" })

flyToggle = PT(MovementTab:AddToggle({
    Title = "Fly",
    Description = "WASD to move, Space up, Ctrl down",
    Flag = "Fly",
    Default = false,
    Callback = function(v)
        State.Fly = v
        if v then
            startFly()
        else
            stopFly()
        end
    end,
}))

local flyKeybind = MovementTab:AddKeybind({
    Title = "Toggle Fly",
    Description = "Choose a key to turn Fly on or off",
    Default = Enum.KeyCode.G,
    Flag = "FlyKey",
    Callback = function()
        if flyToggle then
            flyToggle:Set(not flyToggle.Value)
        end
    end,
})
task.defer(function() pcall(function() flyKeybind:Set(Enum.KeyCode.G) end) end)

MovementTab:AddSlider({
    Title = "Fly Speed",
    Description = "Flight velocity",
    Min = 20,
    Max = 200,
    Default = 60,
    Step = 5,
    Flag = "FlySpeed",
    Callback = function(v)
        State.FlySpeed = v
    end,
})

MovementTab:AddSection({ Title = "modifiers" })

noclipToggle = PT(MovementTab:AddToggle({
    Title = "Noclip",
    Description = "Walk through solid objects",
    Flag = "Noclip",
    Default = false,
    Callback = function(v)
        State.Noclip = v
        if not v then
            setNoClip(false)
        end
    end,
}))

local noclipKeybind = MovementTab:AddKeybind({
    Title = "Toggle Noclip",
    Default = Enum.KeyCode.RightControl,
    Flag = "NoclipKey",
    Callback = function()
        if noclipToggle then
            noclipToggle:Set(not noclipToggle.Value)
        end
    end,
})
task.defer(function() pcall(function() noclipKeybind:Set(Enum.KeyCode.RightControl) end) end)

PT(MovementTab:AddToggle({ Title = "Anti-Void", Description = "Teleport back if you fall into the void", Flag = "AntiVoid", Default = false, Callback = function(v)
    State.AntiVoid = v
    if v then startVoid() else stopVoid() end
end }))
PT(MovementTab:AddToggle({ Title = "Auto Evade Piggy", Description = "Walk away when Piggy gets close (with wall avoidance)", Flag = "AutoEvade", Default = false, Callback = function(v)
    State.AutoEvade = v
    if not v then S.evadeDirection = nil end
end }))
MovementTab:AddSlider({ Title = "Evade Range", Description = "Distance that triggers the evade", Min = 10, Max = 80, Default = 25, Step = 5, Flag = "EvadeRange", Callback = function(v) State.EvadeRange = v end })

ESPTab:AddSection({ Title = "targets" })
PT(ESPTab:AddToggle({ Title = "Player ESP", Description = "Show regular players", Flag = "PlayerESP", Default = true, Callback = function(v) State.PlayerESP = v end }))
PT(ESPTab:AddToggle({ Title = "Piggy ESP", Description = "Show Piggy and hostile bots", Flag = "PiggyESP", Default = true, Callback = function(v) State.PiggyESP = v end }))
PT(ESPTab:AddToggle({ Title = "Traitor ESP", Description = "Show players with the Traitor tag", Flag = "TraitorESP", Default = true, Callback = function(v) State.TraitorESP = v end }))
PT(ESPTab:AddToggle({ Title = "Friendly Bots ESP", Description = "Show allied bots (Zizzy, Pony, etc.)", Flag = "FriendlyESP", Default = false, Callback = function(v) State.FriendlyESP = v end }))
PT(ESPTab:AddToggle({ Title = "NPC ESP", Description = "Show neutral NPCs (soldiers, special chars)", Flag = "NpcESP", Default = false, Callback = function(v) State.NpcESP = v end }))

ESPTab:AddSection({ Title = "world" })
PT(ESPTab:AddToggle({ Title = "Item ESP", Description = "Show collectible items", Flag = "ItemESP", Default = true, Callback = function(v)
    State.ItemESP = v
    if v then task.spawn(refreshWorld) end
end }))
PT(ESPTab:AddToggle({ Title = "Exit ESP", Description = "Show exits and objectives", Flag = "ExitESP", Default = true, Callback = function(v)
    State.ExitESP = v
    if v then task.spawn(refreshWorld) end
end }))
PT(ESPTab:AddToggle({ Title = "Trap ESP", Description = "Show traps and hazards", Flag = "TrapESP", Default = false, Callback = function(v)
    State.TrapESP = v
    if v then task.spawn(refreshWorld) end
end }))

ESPTab:AddSection({ Title = "display" })
PT(ESPTab:AddToggle({ Title = "Highlight ESP", Description = "Paints a bright outline on players, bots and items", Flag = "ESPHL", Default = true, Callback = function(v)
    State.ESPHighlight = v
    if not v then clearAllHighlights() end
end }))
PT(ESPTab:AddToggle({ Title = "Box ESP", Description = "Draw a box on screen around targets", Flag = "ESPBoxes", Default = false, Callback = function(v) State.ESPBoxes = v end }))
PT(ESPTab:AddToggle({ Title = "Names", Description = "Show names above targets", Flag = "ESPNames", Default = true, Callback = function(v) State.ESPNames = v end }))
PT(ESPTab:AddToggle({ Title = "Distances", Description = "Show distance below targets", Flag = "ESPDist", Default = true, Callback = function(v) State.ESPDistances = v end }))
PT(ESPTab:AddToggle({ Title = "Health Bars", Description = "Show health bar next to targets", Flag = "ESPHealth", Default = true, Callback = function(v) State.ESPHealth = v end }))
PT(ESPTab:AddToggle({ Title = "Lines", Description = "Draw lines from screen bottom to targets", Flag = "ESPLines", Default = false, Callback = function(v) State.ESPLines = v end }))

ESPTab:AddSection({ Title = "range" })
ESPTab:AddSlider({ Title = "Max Distance", Description = "ESP display range", Min = 50, Max = 2000, Default = 500, Step = 50, Flag = "ESPMaxDist", Callback = function(v) State.ESPMaxDist = v end })

ESPTab:AddSection({ Title = "colors" })
ESPTab:AddColorPicker({ Title = "Player Color", Description = "Color for player ESP", Default = COLORS.Player, Flag = "ColPlayer", Callback = function(c) COLORS.Player = c end })
ESPTab:AddColorPicker({ Title = "Piggy Color", Description = "Color for hostile bots", Default = COLORS.Bot, Flag = "ColBot", Callback = function(c) COLORS.Bot = c end })
ESPTab:AddColorPicker({ Title = "Traitor Color", Description = "Color for traitor players", Default = COLORS.Traitor, Flag = "ColTraitor", Callback = function(c) COLORS.Traitor = c end })
ESPTab:AddColorPicker({ Title = "Friendly Color", Description = "Color for allied bots", Default = COLORS.Friendly, Flag = "ColFriendly", Callback = function(c) COLORS.Friendly = c end })
ESPTab:AddColorPicker({ Title = "NPC Color", Description = "Color for neutral NPCs", Default = COLORS.Npc, Flag = "ColNpc", Callback = function(c) COLORS.Npc = c end })
ESPTab:AddColorPicker({ Title = "Item Color", Description = "Color for item ESP", Default = COLORS.Item, Flag = "ColItem", Callback = function(c) COLORS.Item = c end })
ESPTab:AddColorPicker({ Title = "Key Color", Description = "Color for key items", Default = COLORS.Key, Flag = "ColKey", Callback = function(c) COLORS.Key = c end })
ESPTab:AddColorPicker({ Title = "Exit Color", Description = "Color for exit ESP", Default = COLORS.Exit, Flag = "ColExit", Callback = function(c) COLORS.Exit = c end })
ESPTab:AddColorPicker({ Title = "Trap Color", Description = "Color for trap ESP", Default = COLORS.Trap, Flag = "ColTrap", Callback = function(c) COLORS.Trap = c end })

TrollTab:AddSection({ Title = "piggy bots" })
PT(TrollTab:AddToggle({ Title = "Spin Piggy Bots", Description = "Makes every hostile bot spin continuously", Flag = "SpinBots", Default = false, Callback = function(v)
    State.SpinBots = v
    if not v then
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj.Name == "PiggyHubSpin" and obj:IsA("BodyAngularVelocity") then
                obj:Destroy()
            end
        end
    end
end }))
TrollTab:AddButton({ Title = "Kill Nearest Piggy (FE)", Description = "Drops the nearest bot through the floor", ButtonText = "Kill", Callback = function()
    local piggy = findPiggy()
    if not piggy then
        EZ:Notify({ Title = "Troll", Content = "No Piggy bot found.", Style = "Warning", Duration = 2 })
        return
    end
    local root = piggy:FindFirstChild("HumanoidRootPart")
    local hum = piggy:FindFirstChildOfClass("Humanoid")
    if root and hum then
        for _, v in ipairs(piggy:GetDescendants()) do
            if v:IsA("BasePart") then v.CanCollide = false end
        end
        root.Anchored = false
        hum.PlatformStand = true
        local bv = Instance.new("BodyVelocity")
        bv.Velocity = Vector3.new(0, -1000, 0)
        bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        bv.P = math.huge
        bv.Parent = root
        EZ:Notify({ Title = "Troll", Content = "Killed nearest Piggy.", Style = "Success", Duration = 2 })
    end
end })
TrollTab:AddButton({ Title = "Delete Nearest Piggy", Description = "Removes the nearest bot from the map (client-side)", ButtonText = "Delete", Callback = function()
    local piggy = findPiggy()
    if piggy then
        piggy:Destroy()
        EZ:Notify({ Title = "Troll", Content = "Deleted nearest Piggy.", Style = "Success", Duration = 2 })
    else
        EZ:Notify({ Title = "Troll", Content = "No Piggy bot found.", Style = "Warning", Duration = 2 })
    end
end })
TrollTab:AddButton({ Title = "Give Kill Piggy Tool", Description = "Tool that kills Piggy bots on click", ButtonText = "Give", Callback = function()
    makeKillTool()
    EZ:Notify({ Title = "Troll", Content = "Tool added to backpack. Click any bot to kill.", Style = "Success", Duration = 3 })
end })
TrollTab:AddButton({ Title = "Bring Nearest Piggy", Description = "Teleports the nearest bot in front of you", ButtonText = "Bring", Callback = function()
    local myRoot = HRP()
    local piggy = findPiggy()
    if myRoot and piggy then
        local proot = piggy:FindFirstChild("HumanoidRootPart")
        if proot then
            proot.CFrame = myRoot.CFrame + myRoot.CFrame.LookVector * 5 + Vector3.new(0, 2, 0)
            EZ:Notify({ Title = "Troll", Content = "Brought Piggy in front.", Style = "Success", Duration = 2 })
        end
    else
        EZ:Notify({ Title = "Troll", Content = "No Piggy found.", Style = "Warning", Duration = 2 })
    end
end })

TrollTab:AddSection({ Title = "self" })
PT(TrollTab:AddToggle({ Title = "UnESP Yourself", Description = "Removes any highlight or billboard on your character", Flag = "UnESPSelf", Default = false, Callback = function(v)
    State.UnESPSelf = v
    if not v then
        local char = LocalPlayer.Character
        if char then
            for _, child in ipairs(char:GetChildren()) do
                if child:IsA("Highlight") or child:IsA("BillboardGui") then child:Destroy() end
            end
        end
    end
end }))

TeleportTab:AddSection({ Title = "world" })
TeleportTab:AddButton({ Title = "Teleport to Exit", Description = "Go to the nearest exit", ButtonText = "Go", Callback = function()
    local exit = findNearestExit()
    if exit then safeTeleport(exit.Position)
    else EZ:Notify({ Title = "Teleport", Content = "No exit found.", Style = "Warning", Duration = 2 }) end
end })
TeleportTab:AddButton({ Title = "Teleport to Piggy", Description = "Go next to the nearest bot", ButtonText = "Go", Callback = function()
    local piggy = findPiggy()
    if piggy then
        local root = piggy:FindFirstChild("HumanoidRootPart")
        if root then safeTeleport(root.Position + Vector3.new(4, 0, 4)) end
    else EZ:Notify({ Title = "Teleport", Content = "No Piggy found.", Style = "Warning", Duration = 2 }) end
end })
TeleportTab:AddButton({ Title = "Teleport to Traitor", Description = "Go next to the traitor player", ButtonText = "Go", Callback = function()
    local tr = findTraitor()
    if tr then
        local root = tr:FindFirstChild("HumanoidRootPart")
        if root then safeTeleport(root.Position + Vector3.new(4, 0, 4)) end
    else EZ:Notify({ Title = "Teleport", Content = "No traitor found.", Style = "Warning", Duration = 2 }) end
end })

TeleportTab:AddSection({ Title = "players" })
local playerDropdown = TeleportTab:AddDropdown({ Title = "Player", Description = "Pick a player to teleport to", Values = {}, Default = nil, Flag = "TPPlayer", Callback = function() end })
task.spawn(function()
    while true do
        task.wait(3)
        if playerDropdown then
            local list = getPlayerList()
            if #list > 0 then playerDropdown:SetValues(list) end
        end
    end
end)
TeleportTab:AddButton({ Title = "Teleport to Player", Description = "Go to the selected player", ButtonText = "Go", Callback = function()
    local name = playerDropdown.Value
    if not name then EZ:Notify({ Title = "Teleport", Content = "No player selected.", Style = "Warning", Duration = 2 }) return end
    local p = Players:FindFirstChild(name)
    if p and p.Character then
        local root = p.Character:FindFirstChild("HumanoidRootPart")
        if root then safeTeleport(root.Position + Vector3.new(4, 0, 4)) end
    end
end })

VisualsTab:AddSection({ Title = "environment" })

fullbrightToggle = PT(VisualsTab:AddToggle({
    Title = "Fullbright",
    Description = "Brighten the whole map",
    Flag = "Fullbright",
    Default = false,
    Callback = function(v)
        State.Fullbright = v
        applyFullbright()
    end,
}))

local fullbrightKeybind = VisualsTab:AddKeybind({
    Title = "Toggle Fullbright",
    Default = Enum.KeyCode.F,
    Flag = "FullbrightKey",
    Callback = function()
        if fullbrightToggle then
            fullbrightToggle:Set(not fullbrightToggle.Value)
        end
    end,
})
task.defer(function() pcall(function() fullbrightKeybind:Set(Enum.KeyCode.F) end) end)

PT(VisualsTab:AddToggle({ Title = "No Fog", Description = "Disable distance fog", Flag = "NoFog", Default = false, Callback = function(v)
    State.NoFog = v
    if v then Lighting.FogEnd = 1e6 Lighting.FogStart = 0
    else Lighting.FogEnd = 100000 Lighting.FogStart = 0 end
end }))

VisualsTab:AddSection({ Title = "character" })
PT(VisualsTab:AddToggle({ Title = "China Hat", Description = "Glowing cone hat on your head", Flag = "ChinaHat", Default = false, Callback = function(v)
    State.ChinaHat = v
    applyChinaHat()
end }))
VisualsTab:AddColorPicker({ Title = "China Hat Color", Description = "Color of the hat and its light", Default = Color3.fromRGB(255, 123, 123), Flag = "HatColor", Callback = function(c)
    State.ChinaHatColor = c
    if State.ChinaHat then applyChinaHat() end
end })

VisualsTab:AddSection({ Title = "crosshair" })
PT(VisualsTab:AddToggle({ Title = "Custom Crosshair", Description = "Rotating crosshair on screen center", Flag = "Crosshair", Default = false, Callback = function(v)
    State.Crosshair = v
    applyCrosshair()
end }))
VisualsTab:AddColorPicker({ Title = "Crosshair Color", Description = "Color of the crosshair", Default = Color3.fromRGB(0, 188, 168), Flag = "CrossColor", Callback = function(c)
    State.CrosshairColor = c
    for _, line in ipairs(S.crossLines) do if line then line.Color = c end end
end })

UtilityTab:AddSection({ Title = "server" })
UtilityTab:AddButton({ Title = "Rejoin Server", Description = "Reconnect to this server", ButtonText = "Rejoin", Callback = function()
    pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer) end)
end })
UtilityTab:AddButton({ Title = "Server Hop", Description = "Join the smallest available server", ButtonText = "Hop", Callback = function()
    local ok, result = pcall(function()
        local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
        return HttpService:JSONDecode(game:HttpGet(url))
    end)
    if not ok or not result or not result.data then return end
    for _, srv in ipairs(result.data) do
        if srv.playing < srv.maxPlayers and srv.id ~= game.JobId then
            TeleportService:TeleportToPlaceInstance(game.PlaceId, srv.id, LocalPlayer)
            return
        end
    end
end })
UtilityTab:AddButton({ Title = "Copy Job ID", Description = "Copy the current server id", ButtonText = "Copy", Callback = function()
    if setclipboard then
        pcall(setclipboard, game.JobId)
        EZ:Notify({ Title = "Utility", Content = "Job ID copied.", Style = "Success", Duration = 2 })
    end
end })
PT(UtilityTab:AddToggle({ Title = "Auto Rejoin", Description = "Reconnect automatically when kicked", Flag = "AutoRejoin", Default = false, Callback = function(v) State.AutoRejoin = v end }))

UtilityTab:AddSection({ Title = "map tools" })
UtilityTab:AddButton({ Title = "Reveal Door Codes", Description = "Reveals codes on basement keypads and doors", ButtonText = "Reveal", Callback = revealDoorCodes })
UtilityTab:AddDropdown({ Title = "Auto Vote Map", Description = "Pick a map to auto-vote next round", Values = PIGGY_MAPS, Default = "House", Flag = "VoteMap", Callback = function(v) State.AutoVoteMap = v end })
UtilityTab:AddButton({ Title = "Vote Now", Description = "Fires the vote remote with the selected map", ButtonText = "Vote", Callback = function()
    local ok = pcall(function()
        local rem = game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("NewVote")
        rem:FireServer("Map", State.AutoVoteMap)
    end)
    if ok then
        EZ:Notify({ Title = "Vote", Content = "Voted for " .. State.AutoVoteMap, Style = "Success", Duration = 2 })
    else
        EZ:Notify({ Title = "Vote", Content = "Vote remote not found on this map.", Style = "Error", Duration = 3 })
    end
end })

UtilityTab:AddSection({ Title = "performance" })
UtilityTab:AddButton({ Title = "FPS Booster", Description = "Changes every part material to SmoothPlastic", ButtonText = "Boost", Callback = fpsBoost })
PT(UtilityTab:AddToggle({ Title = "FPS Counter", Description = "Show FPS and Ping overlay", Flag = "FpsCounter", Default = false, Callback = function(v)
    State.FpsCounter = v
    toggleFpsCounter(v)
end }))

Window:BuildConfigSection(Config)

Credits:AddSection({ Title = "about" })
Credits:AddParagraph({
    Title = "Piggy Hub v" .. SCRIPT_VERSION,
    Content = "A personal project for Piggy.\nFocused on efficient item collection and survival automation.",
})
Credits:AddParagraph({
    Title = "Developer",
    Content = "AkiraDev — github.com/akiradv",
})
Credits:AddParagraph({
    Title = "Interface",
    Content = "Eazy UI " .. EZ.Version .. " by AkiraDev",
})
Credits:AddSection({ Title = "community" })
Credits:AddButton({
    Title = "Discord",
    Description = "Copy my Discord invite",
    ButtonText = "Copy",
    Callback = function()
        if setclipboard then
            pcall(setclipboard, "https://discord.gg/" .. DISCORD_AKIRA)
            EZ:Notify({ Title = "Community", Content = "Discord invite copied.", Style = "Success", Duration = 2 })
        end
    end,
})

Players.PlayerRemoving:Connect(function(p)
    if p == LocalPlayer and State.AutoRejoin then
        pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, p) end)
    end
end)

LocalPlayer.CharacterAdded:Connect(function(char)
    S.safeCF = nil
    if State.Fly then stopFly() task.wait(0.3) startFly() end
    if State.ChinaHat then task.wait(0.4) applyChinaHat() end
    local h = char:WaitForChild("Humanoid", 5)
    if h then
        h.WalkSpeed = State.WalkSpeed and State.WSpeed or 16
        if State.JumpPower then h.UseJumpPower = true h.JumpPower = State.JPower end
    end
    if State.GodMode then
        task.wait(0.3)
        setGodModeParts(true)
    end
end)

EZ:Notify({ Title = "Piggy Hub", Content = "Loaded v" .. SCRIPT_VERSION, Style = "Success", Duration = 3 })