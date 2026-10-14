local EZ = loadstring(game:HttpGet("https://raw.githubusercontent.com/akiradv/eazyuilib/main/eazyui.lua"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local VERSION = "1.2.4"
local DISCORD = "2ksQSAnnW6"

local CONFIG = {
    SilentAim = false,
    RapidFire = false,
    Triggerbot = false,
    TriggerDelay = 0.05,
    Wallcheck = true,
    ThreeSixty = false,
    TargetPart = "Head",
    FOV = 150,
    ShowFOV = true,
    FOVColor = Color3.fromRGB(0, 255, 140),
    ESPEnabled = true,
    ShowBox = false,
    ShowCorners = true,
    ShowSkeleton = true,
    ShowHealth = true,
    ShowName = true,
    ShowWeapon = true,
    ShowDistance = true,
    ESPColor = Color3.fromRGB(255, 80, 80),
    RainbowESP = false,
}

local SignalManager = require(ReplicatedStorage:WaitForChild("SignalManager"))

local BulletHandler = _G.__SA_BulletHandler
if not BulletHandler then
    BulletHandler = require(ReplicatedStorage.ModuleScripts.GunModules.BulletHandler)
    _G.__SA_BulletHandler = BulletHandler
end
assert(type(BulletHandler) == "table", "[SA] BulletHandler not a table")
assert(type(BulletHandler.Fire) == "function", "[SA] BulletHandler.Fire not a function")

if _G.__SA_HookInstalled and _G.__SA_OriginalBulletFire then
    BulletHandler.Fire = _G.__SA_OriginalBulletFire
    _G.__SA_HookInstalled = false
end

local originalFire = BulletHandler.Fire
_G.__SA_OriginalBulletFire = originalFire
_G.__SA_HookInstalled = true

local fovCircle = Drawing.new("Circle")
fovCircle.Thickness = 1.5
fovCircle.Transparency = 0.6
fovCircle.Filled = false
fovCircle.NumSides = 64
fovCircle.Visible = false

RunService.RenderStepped:Connect(function()
    fovCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    fovCircle.Radius = CONFIG.FOV
    fovCircle.Visible = CONFIG.ShowFOV and (CONFIG.SilentAim or CONFIG.Triggerbot) and not CONFIG.ThreeSixty
    fovCircle.Color = CONFIG.SilentAim and CONFIG.FOVColor or Color3.fromRGB(255, 70, 70)
end)

local PART_PRIORITY = { "HumanoidRootPart", "UpperTorso", "Torso", "LowerTorso", "Head" }
local ANGLE_TOLERANCE = 20
local MAX_SHOTS_PER_CALL = 15
local MIN_TARGET_DIST = 5

local function findPart(char, partName)
    local p = char:FindFirstChild(partName)
    if p and p:IsA("BasePart") then return p end
    for _, d in ipairs(char:GetDescendants()) do
        if d.Name == partName and d:IsA("BasePart") then return d end
    end
end

local function hasLineOfSight(originPos, partPos, ignoreChar)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { LocalPlayer.Character, Camera, ignoreChar }
    params.IgnoreWater = true
    local dir = partPos - originPos
    local dist = dir.Magnitude
    if dist <= 0 then return false end
    local result = workspace:Raycast(originPos, dir, params)
    if not result then return true end
    return result.Distance >= dist - 0.5
end

local function buildTargetFromChar(char, originPos)
    if not char or not char.Parent then return nil end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return nil end
    local chosenPart, chosenPos
    if CONFIG.Wallcheck then
        local primary = findPart(char, CONFIG.TargetPart)
        if primary and hasLineOfSight(originPos, primary.Position, char) then
            chosenPart, chosenPos = primary, primary.Position
        end
        if not chosenPart then
            for _, pName in ipairs(PART_PRIORITY) do
                if pName ~= CONFIG.TargetPart then
                    local p = findPart(char, pName)
                    if p and hasLineOfSight(originPos, p.Position, char) then
                        chosenPart, chosenPos = p, p.Position
                        break
                    end
                end
            end
        end
        if not chosenPart then return nil end
    else
        local primary = findPart(char, CONFIG.TargetPart)
        if primary then
            chosenPart, chosenPos = primary, primary.Position
        else
            for _, pName in ipairs(PART_PRIORITY) do
                local p = findPart(char, pName)
                if p then chosenPart, chosenPos = p, p.Position break end
            end
        end
        if not chosenPart then return nil end
    end
    return { character = char, humanoid = hum, part = chosenPart, partPos = chosenPos }
end

local function buildSkipSet()
    local skip = {}
    for _, obj in ipairs(Camera:GetChildren()) do
        skip[obj] = true
        for _, d in ipairs(obj:GetDescendants()) do skip[d] = true end
    end
    local function markVM(root, depth)
        depth = depth or 0
        if depth > 3 then return end
        for _, obj in ipairs(root:GetChildren()) do
            if obj.Name == "ViewModel" or obj.Name == "Viewmodel" or obj.Name == "viewModel" then
                skip[obj] = true
                for _, d in ipairs(obj:GetDescendants()) do skip[d] = true end
            end
            markVM(obj, depth + 1)
        end
    end
    markVM(workspace, 0)
    if LocalPlayer.Character then
        skip[LocalPlayer.Character] = true
        for _, d in ipairs(LocalPlayer.Character:GetDescendants()) do skip[d] = true end
    end
    return skip
end

local function getTarget(origin)
    if not CONFIG.SilentAim then return nil end
    local targets = {}
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local seenChars = {}
    local skipSet = buildSkipSet()
    local myChar = LocalPlayer.Character

    local function evaluate(char)
        if char == myChar or skipSet[char] or seenChars[char] then return end
        seenChars[char] = true
        local info = buildTargetFromChar(char, origin)
        if not info then return end
        local pos = info.partPos
        if CONFIG.ThreeSixty and not hasLineOfSight(origin, pos, char) then return end
        local sp, onScreen = Camera:WorldToViewportPoint(pos)
        local screenDist = onScreen and (Vector2.new(sp.X, sp.Y) - screenCenter).Magnitude or 99999
        if not CONFIG.ThreeSixty then
            if not onScreen then return end
            if screenDist > CONFIG.FOV then return end
        end
        local dist3D = (pos - origin).Magnitude
        if dist3D < MIN_TARGET_DIST then return end
        table.insert(targets, { position = pos, dist = screenDist, dist3D = dist3D, onScreen = onScreen, part = info.part, character = char })
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then evaluate(player.Character) end
    end

    table.sort(targets, function(a, b)
        if a.onScreen ~= b.onScreen then return a.onScreen end
        if a.onScreen and b.onScreen then
            if math.abs(a.dist - b.dist) < 30 then return a.dist3D < b.dist3D end
            return a.dist < b.dist
        end
        return a.dist3D < b.dist3D
    end)
    return targets[1]
end

local shotsTotal = 0

local function fireRapidCopies(payload, n)
    for i = 2, n do
        local copy = {}
        for k, v in pairs(payload) do copy[k] = v end
        if type(payload.Misc) == "table" then
            local newMisc = {}
            for k, v in pairs(payload.Misc) do newMisc[k] = v end
            copy.Misc = newMisc
        end
        local newId = tick() + (i * 0.0001)
        if copy.Misc then
            copy.Misc.ShotID = newId
            copy.Misc.NewSeed = (copy.Misc.NewSeed or 0) + 11
        end
        copy.BulletId = newId
        pcall(function() originalFire(copy) end)
        shotsTotal = shotsTotal + 1
    end
end

BulletHandler.Fire = function(payload)
    if type(payload) ~= "table" then return originalFire(payload) end
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local isAirborne = hum and hum.FloorMaterial == Enum.Material.Air

    if isAirborne and hrp and typeof(payload.Origin) == "Vector3" then
        payload.Origin = hrp.Position + Vector3.new(0, 1.5, 0)
        if typeof(payload.VisualOrigin) == "Vector3" then payload.VisualOrigin = payload.Origin end
    end

    local originPos = typeof(payload.Origin) == "Vector3" and payload.Origin or nil
    local needsCameraSpoof = false
    local spoofCF = nil

    if originPos then
        local target = getTarget(originPos)
        if target then
            local newDir = (target.position - originPos).Unit
            payload.Direction = newDir
            if type(payload.Misc) == "table" and typeof(payload.Misc.CamCFrame) == "CFrame" then
                payload.Misc.CamCFrame = CFrame.lookAt(originPos, originPos + newDir)
            end
            if type(payload.Misc) == "table" then payload.Misc.Spread = 0 end

            local realLook = Camera.CFrame.LookVector
            local dot = math.clamp(realLook:Dot(newDir), -1, 1)
            local angle = math.deg(math.acos(dot))
            if CONFIG.ThreeSixty then
                needsCameraSpoof = true
                spoofCF = CFrame.lookAt(originPos, originPos + newDir)
            elseif angle > ANGLE_TOLERANCE and not isAirborne then
                needsCameraSpoof = true
                spoofCF = CFrame.lookAt(originPos, originPos + newDir)
            end
        end
    end

    local n = CONFIG.RapidFire and MAX_SHOTS_PER_CALL or 1
    shotsTotal = shotsTotal + 1
    local oldCF = nil
    if needsCameraSpoof then oldCF = Camera.CFrame; Camera.CFrame = spoofCF end
    local result = originalFire(payload)
    if n > 1 then fireRapidCopies(payload, n) end
    if needsCameraSpoof and oldCF then Camera.CFrame = oldCF end
    return result
end

local lastTrigger = 0
RunService.Heartbeat:Connect(function()
    if not CONFIG.Triggerbot then return end
    if not LocalPlayer.Character then return end
    local now = tick()
    if now - lastTrigger < CONFIG.TriggerDelay then return end
    local tool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
    if not tool then return end
    local target = getTarget(Camera.CFrame.Position)
    if not target then return end
    lastTrigger = now
    pcall(function() SignalManager.Fire("FireWeapon", Enum.UserInputState.Begin) end)
    pcall(function() SignalManager.Fire("FireWeapon", Enum.UserInputState.End) end)
end)

local ESP = { players = {} }
local BONES_R15 = {
    { "Head", "UpperTorso" }, { "UpperTorso", "LowerTorso" },
    { "UpperTorso", "LeftUpperArm" }, { "UpperTorso", "RightUpperArm" },
    { "LowerTorso", "LeftUpperLeg" }, { "LowerTorso", "RightUpperLeg" },
}
local BONES_R6 = {
    { "Head", "Torso" }, { "Torso", "Left Arm" }, { "Torso", "Right Arm" },
    { "Torso", "Left Leg" }, { "Torso", "Right Leg" },
}

local function newLine()
    local l = Drawing.new("Line") l.Thickness = 1.0 l.Visible = false l.Transparency = 1 return l
end
local function newText()
    local t = Drawing.new("Text") t.Size = 13 t.Center = true t.Outline = true t.OutlineColor = Color3.new(0, 0, 0) t.Visible = false t.Font = 2 return t
end
local function newSquare()
    local s = Drawing.new("Square") s.Thickness = 1 s.Filled = false s.Visible = false return s
end
local function isR15(char) return char:FindFirstChild("UpperTorso") ~= nil end
local function getBones(char) return isR15(char) and BONES_R15 or BONES_R6 end

local function buildESP()
    local tbl = {
        lines = {},
        box = newSquare(),
        boxOutline = newSquare(),
        cornerTL = newLine(), cornerTR = newLine(),
        cornerBL = newLine(), cornerBR = newLine(),
        healthBg = newLine(), healthFg = newLine(),
    }
    for i = 1, 15 do tbl.lines[i] = newLine() end
    tbl.nameText = newText()
    tbl.weaponText = newText()
    tbl.distanceText = newText()
    tbl.healthText = newText()
    return tbl
end

local function clearESP(player)
    local tbl = ESP.players[player]
    if not tbl then return end
    for _, l in ipairs(tbl.lines) do pcall(function() l:Remove() end) end
    for _, k in ipairs({ "box", "boxOutline", "cornerTL", "cornerTR", "cornerBL", "cornerBR", "healthBg", "healthFg" }) do
        pcall(function() tbl[k]:Remove() end)
    end
    for _, k in ipairs({ "nameText", "weaponText", "distanceText", "healthText" }) do
        pcall(function() tbl[k]:Remove() end)
    end
    ESP.players[player] = nil
end

local function setupPlayer(player)
    if player == LocalPlayer then return end
    if not ESP.players[player] then ESP.players[player] = buildESP() end
end

for _, p in ipairs(Players:GetPlayers()) do setupPlayer(p) end
Players.PlayerAdded:Connect(setupPlayer)
Players.PlayerRemoving:Connect(function(p) clearESP(p) end)

local function getWeaponName(char)
    local tool = char:FindFirstChildOfClass("Tool")
    return tool and tool.Name or nil
end

RunService.RenderStepped:Connect(function()
    if not CONFIG.ESPEnabled then
        for _, tbl in pairs(ESP.players) do
            for _, l in ipairs(tbl.lines) do l.Visible = false end
            for _, k in ipairs({ "box", "boxOutline", "cornerTL", "cornerTR", "cornerBL", "cornerBR", "healthBg", "healthFg", "nameText", "weaponText", "distanceText", "healthText" }) do
                tbl[k].Visible = false
            end
        end
        return
    end

    for player, tbl in pairs(ESP.players) do
        local char = player.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local root = char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso"))

        if not (char and hum and root and hum.Health > 0) then
            for _, l in ipairs(tbl.lines) do l.Visible = false end
            for _, k in ipairs({ "box", "boxOutline", "cornerTL", "cornerTR", "cornerBL", "cornerBR", "healthBg", "healthFg", "nameText", "weaponText", "distanceText", "healthText" }) do
                tbl[k].Visible = false
            end
            continue
        end

        local baseColor = (player.Team == LocalPlayer.Team) and Color3.fromRGB(0, 200, 255) or CONFIG.ESPColor
        if CONFIG.RainbowESP then
            baseColor = Color3.fromHSV(tick() * 0.3 % 1, 0.8, 1)
        end

        if CONFIG.ShowSkeleton then
            local bones = getBones(char)
            local i = 0
            local distFromCam = (Camera.CFrame.Position - root.Position).Magnitude
            local thick = math.clamp(1.0 - (distFromCam - 20) / 200, 0.3, 1.0)
            for _, pair in ipairs(bones) do
                local a = char:FindFirstChild(pair[1])
                local b = char:FindFirstChild(pair[2])
                i = i + 1
                if a and b then
                    local a3, aOn = Camera:WorldToViewportPoint(a.Position)
                    local b3, bOn = Camera:WorldToViewportPoint(b.Position)
                    if aOn and bOn then
                        local ln = tbl.lines[i]
                        ln.From = Vector2.new(a3.X, a3.Y)
                        ln.To = Vector2.new(b3.X, b3.Y)
                        ln.Color = baseColor
                        ln.Thickness = thick
                        ln.Visible = true
                    else tbl.lines[i].Visible = false end
                else tbl.lines[i].Visible = false end
            end
            for j = i + 1, #tbl.lines do tbl.lines[j].Visible = false end
        else
            for _, l in ipairs(tbl.lines) do l.Visible = false end
        end

        local head = char:FindFirstChild("Head")
        local boxVisible = false
        local boxW, boxH, boxPos

        if (CONFIG.ShowBox or CONFIG.ShowCorners) and head and root then
            local headTop = head.Position + Vector3.new(0, head.Size.Y / 2, 0)
            local feetPos = root.Position - Vector3.new(0, 3, 0)
            local topScreen, topOn = Camera:WorldToViewportPoint(headTop)
            local botScreen, botOn = Camera:WorldToViewportPoint(feetPos)
            if topOn and botOn then
                boxH = math.abs(botScreen.Y - topScreen.Y)
                boxW = boxH * 0.55
                boxPos = Vector2.new(topScreen.X - boxW / 2, topScreen.Y)
                boxVisible = true

                if CONFIG.ShowBox then
                    tbl.box.Size = Vector2.new(boxW, boxH)
                    tbl.box.Position = boxPos
                    tbl.box.Color = baseColor
                    tbl.box.Visible = true
                    tbl.boxOutline.Size = Vector2.new(boxW, boxH)
                    tbl.boxOutline.Position = boxPos
                    tbl.boxOutline.Color = Color3.new(0, 0, 0)
                    tbl.boxOutline.Visible = true
                else
                    tbl.box.Visible = false
                    tbl.boxOutline.Visible = false
                end

                if CONFIG.ShowCorners then
                    local cl = math.min(boxW, boxH) / 4
                    local x, y = boxPos.X, boxPos.Y
                    tbl.cornerTL.From = Vector2.new(x, y) tbl.cornerTL.To = Vector2.new(x + cl, y) tbl.cornerTL.Color = baseColor tbl.cornerTL.Thickness = 2 tbl.cornerTL.Visible = true
                    tbl.cornerTR.From = Vector2.new(x + boxW, y) tbl.cornerTR.To = Vector2.new(x + boxW - cl, y) tbl.cornerTR.Color = baseColor tbl.cornerTR.Thickness = 2 tbl.cornerTR.Visible = true
                    tbl.cornerBL.From = Vector2.new(x, y + boxH) tbl.cornerBL.To = Vector2.new(x + cl, y + boxH) tbl.cornerBL.Color = baseColor tbl.cornerBL.Thickness = 2 tbl.cornerBL.Visible = true
                    tbl.cornerBR.From = Vector2.new(x + boxW, y + boxH) tbl.cornerBR.To = Vector2.new(x + boxW - cl, y + boxH) tbl.cornerBR.Color = baseColor tbl.cornerBR.Thickness = 2 tbl.cornerBR.Visible = true
                else
                    tbl.cornerTL.Visible = false tbl.cornerTR.Visible = false
                    tbl.cornerBL.Visible = false tbl.cornerBR.Visible = false
                end
            else
                boxVisible = false
                tbl.box.Visible = false tbl.boxOutline.Visible = false
                tbl.cornerTL.Visible = false tbl.cornerTR.Visible = false
                tbl.cornerBL.Visible = false tbl.cornerBR.Visible = false
            end
        else
            tbl.box.Visible = false tbl.boxOutline.Visible = false
            tbl.cornerTL.Visible = false tbl.cornerTR.Visible = false
            tbl.cornerBL.Visible = false tbl.cornerBR.Visible = false
        end

        if CONFIG.ShowHealth and boxVisible then
            local pct = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
            local barX = boxPos.X - 8
            tbl.healthBg.From = Vector2.new(barX, boxPos.Y)
            tbl.healthBg.To = Vector2.new(barX, boxPos.Y + boxH)
            tbl.healthBg.Color = Color3.fromRGB(30, 30, 30)
            tbl.healthBg.Thickness = 4
            tbl.healthBg.Visible = true
            local fillH = boxH * pct
            tbl.healthFg.From = Vector2.new(barX, boxPos.Y + (boxH - fillH))
            tbl.healthFg.To = Vector2.new(barX, boxPos.Y + boxH)
            tbl.healthFg.Color = pct > 0.5 and Color3.fromRGB(0, 255, 80) or pct > 0.25 and Color3.fromRGB(255, 200, 0) or Color3.fromRGB(255, 50, 50)
            tbl.healthFg.Thickness = 3
            tbl.healthFg.Visible = true
        else
            tbl.healthBg.Visible = false
            tbl.healthFg.Visible = false
        end

        if not head then continue end
        local headTop = head.Position + Vector3.new(0, head.Size.Y / 2, 0)
        local screenHead, onHead = Camera:WorldToViewportPoint(headTop)
        if not onHead then
            tbl.nameText.Visible = false tbl.weaponText.Visible = false
            tbl.distanceText.Visible = false tbl.healthText.Visible = false
            continue
        end

        local yCursor = screenHead.Y - 20
        if CONFIG.ShowName then
            tbl.nameText.Text = player.Name
            tbl.nameText.Position = Vector2.new(screenHead.X, yCursor)
            tbl.nameText.Color = baseColor
            tbl.nameText.Visible = true
            yCursor = yCursor - 16
        else tbl.nameText.Visible = false end

        if CONFIG.ShowWeapon then
            local w = getWeaponName(char)
            if w then
                tbl.weaponText.Text = "[" .. w .. "]"
                tbl.weaponText.Position = Vector2.new(screenHead.X, yCursor)
                tbl.weaponText.Color = Color3.fromRGB(255, 220, 100)
                tbl.weaponText.Visible = true
                yCursor = yCursor - 16
            else tbl.weaponText.Visible = false end
        else tbl.weaponText.Visible = false end

        if CONFIG.ShowDistance then
            local dist = (Camera.CFrame.Position - head.Position).Magnitude
            tbl.distanceText.Text = string.format("%d studs", math.floor(dist))
            tbl.distanceText.Position = Vector2.new(screenHead.X, yCursor)
            tbl.distanceText.Color = dist < 100 and Color3.fromRGB(255, 100, 100) or dist < 300 and Color3.fromRGB(255, 255, 100) or Color3.fromRGB(100, 200, 255)
            tbl.distanceText.Visible = true
        else tbl.distanceText.Visible = false end

        if CONFIG.ShowHealth and boxVisible then
            local pct = math.floor(hum.Health / hum.MaxHealth * 100)
            tbl.healthText.Text = pct .. "%"
            tbl.healthText.Position = Vector2.new(screenHead.X, screenHead.Y + 4)
            tbl.healthText.Color = pct > 50 and Color3.fromRGB(0, 255, 80) or pct > 25 and Color3.fromRGB(255, 200, 0) or Color3.fromRGB(255, 50, 50)
            tbl.healthText.Visible = true
        else
            tbl.healthText.Visible = false
        end
    end
end)

local Window = EZ:CreateWindow({
    Name = "Flick Hub",
    SubTitle = "by AkiraDev",
    Size = UDim2.fromOffset(660, 520),
    MinimizeKey = Enum.KeyCode.RightShift,
    ConfigId = "Flick_Hub",
    AutoLoad = true,
    NotifyPosition = "BottomRight",
    LoadingTitle = "Flick Hub",
    LoadingSubtitle = "Loading...",
    LoadingDuration = 1,
    Discord = { Enabled = true, Invite = DISCORD },
})

local MainTab = Window:AddTab({ Title = "Main", Icon = "house" })
local CombatTab = Window:AddTab({ Title = "Combat", Icon = "crosshair" })
local VisualsTab = Window:AddTab({ Title = "Visuals", Icon = "eye" })
local ConfigTab = Window:AddTab({ Title = "Config", Icon = "sliders" })
local CreditsTab = Window:AddTab({ Title = "Credits", Icon = "info" })

MainTab:AddSection({ Title = "about" })
MainTab:AddParagraph({
    Title = "Objective",
    Content = "Provide a casual, lightweight, and undetectable utility for [FPS] Flick, focused on quality of life without breaking the game experience.",
})
MainTab:AddParagraph({
    Title = "Local & Security",
    Content = "This script is 100% Open Source and runs locally on your executor. The code is open to ensure total transparency, security, and community trust.",
})

MainTab:AddSection({ Title = "information" })
MainTab:AddParagraph({
    Title = "Version Info",
    Content = "Script: v" .. VERSION .. "\nUI Library: Eazy UI " .. EZ.Version .. "\nDeveloper: AkiraDev\nGitHub: github.com/akiradv",
})

MainTab:AddSection({ Title = "community" })
MainTab:AddButton({
    Title = "Join Discord",
    Description = "Copy the invite link to join the server",
    ButtonText = "Copy Link",
    Callback = function()
        local invite = "https://discord.gg/" .. DISCORD
        if setclipboard then
            setclipboard(invite)
            EZ:Notify({ Title = "Discord", Content = "Invite link copied to clipboard!", Duration = 3, Style = "Success" })
        else
            EZ:Notify({ Title = "Discord", Content = "Copy this link: " .. invite, Duration = 10, Style = "Info" })
        end
    end,
})

CombatTab:AddSection({ Title = "aim" })
local silentAimToggle = CombatTab:AddToggle({
    Title = "Silent Aim",
    Description = "Redirects your shots to the nearest enemy",
    Flag = "SilentAim",
    Default = false,
    Callback = function(v) CONFIG.SilentAim = v end,
})
CombatTab:AddKeybind({
    Title = "Silent Aim Toggle",
    Description = "Key to toggle silent aim",
    Default = Enum.KeyCode.X,
    Flag = "SilentAimKey",
    Callback = function()
        local new = not CONFIG.SilentAim
        silentAimToggle:Set(new, true)
        CONFIG.SilentAim = new
    end,
})
CombatTab:AddDropdown({
    Title = "Target Part",
    Description = "Which body part to aim at",
    Values = { "Head", "HumanoidRootPart", "UpperTorso", "LowerTorso", "Torso" },
    Default = "Head",
    Flag = "TargetPart",
    Callback = function(v) CONFIG.TargetPart = v end,
})

CombatTab:AddSection({ Title = "fire" })
local rapidFireToggle = CombatTab:AddToggle({
    Title = "Rapid Fire",
    Description = "Fires multiple copies of each shot",
    Flag = "RapidFire",
    Default = false,
    Callback = function(v) CONFIG.RapidFire = v end,
})
CombatTab:AddKeybind({
    Title = "Rapid Fire Toggle",
    Description = "Key to toggle rapid fire",
    Default = Enum.KeyCode.R,
    Flag = "RapidFireKey",
    Callback = function()
        local new = not CONFIG.RapidFire
        rapidFireToggle:Set(new, true)
        CONFIG.RapidFire = new
    end,
})
local triggerbotToggle = CombatTab:AddToggle({
    Title = "Triggerbot",
    Description = "Auto fires when an enemy enters the FOV",
    Flag = "Triggerbot",
    Default = false,
    Callback = function(v) CONFIG.Triggerbot = v end,
})
CombatTab:AddKeybind({
    Title = "Triggerbot Toggle",
    Description = "Key to toggle triggerbot",
    Default = Enum.KeyCode.T,
    Flag = "TriggerbotKey",
    Callback = function()
        local new = not CONFIG.Triggerbot
        triggerbotToggle:Set(new, true)
        CONFIG.Triggerbot = new
    end,
})
CombatTab:AddSlider({
    Title = "Trigger Delay",
    Description = "Delay between trigger shots",
    Min = 1, Max = 50, Default = 5, Step = 1,
    Flag = "TriggerDelay",
    Callback = function(v) CONFIG.TriggerDelay = v / 100 end,
})

CombatTab:AddSection({ Title = "advanced" })
CombatTab:AddToggle({
    Title = "Wallcheck",
    Description = "Only aims at visible targets",
    Flag = "Wallcheck",
    Default = true,
    Callback = function(v) CONFIG.Wallcheck = v end,
})
local threeSixtyToggle = CombatTab:AddToggle({
    Title = "360 Aim",
    Description = "Removes FOV restriction and aims at any angle",
    Flag = "ThreeSixty",
    Default = false,
    Callback = function(v) CONFIG.ThreeSixty = v end,
})
CombatTab:AddKeybind({
    Title = "360 Aim Toggle",
    Description = "Key to toggle 360 aim",
    Default = Enum.KeyCode.G,
    Flag = "ThreeSixtyKey",
    Callback = function()
        local new = not CONFIG.ThreeSixty
        threeSixtyToggle:Set(new, true)
        CONFIG.ThreeSixty = new
    end,
})
CombatTab:AddToggle({
    Title = "Show FOV Circle",
    Description = "Draws a circle at the screen center showing the aim range",
    Flag = "ShowFOV",
    Default = true,
    Callback = function(v) CONFIG.ShowFOV = v end,
})
CombatTab:AddSlider({
    Title = "FOV",
    Description = "Aim range in pixels",
    Min = 25, Max = 500, Default = 150, Step = 5,
    Flag = "FOV",
    Callback = function(v) CONFIG.FOV = v end,
})
CombatTab:AddColorPicker({
    Title = "FOV Color",
    Description = "Color of the FOV circle when silent aim is active",
    Default = Color3.fromRGB(0, 255, 140),
    Flag = "FOVColor",
    Callback = function(c) CONFIG.FOVColor = c end,
})

VisualsTab:AddSection({ Title = "esp" })
VisualsTab:AddToggle({
    Title = "ESP Enabled",
    Description = "Master toggle for all ESP elements",
    Flag = "ESP",
    Default = true,
    Callback = function(v) CONFIG.ESPEnabled = v end,
})
VisualsTab:AddToggle({
    Title = "Box",
    Description = "Draws a box around enemies",
    Flag = "ESPBox",
    Default = false,
    Callback = function(v) CONFIG.ShowBox = v end,
})
VisualsTab:AddToggle({
    Title = "Corners",
    Description = "Draws corner brackets around enemies",
    Flag = "ESPCorners",
    Default = true,
    Callback = function(v) CONFIG.ShowCorners = v end,
})
VisualsTab:AddToggle({
    Title = "Skeleton",
    Description = "Draws lines between the enemy's bones",
    Flag = "ESPSkel",
    Default = true,
    Callback = function(v) CONFIG.ShowSkeleton = v end,
})
VisualsTab:AddToggle({
    Title = "Health Bar",
    Description = "Shows a health bar next to the box",
    Flag = "ESPHealth",
    Default = true,
    Callback = function(v) CONFIG.ShowHealth = v end,
})
VisualsTab:AddToggle({
    Title = "Name",
    Description = "Shows the player name above the head",
    Flag = "ESPName",
    Default = true,
    Callback = function(v) CONFIG.ShowName = v end,
})
VisualsTab:AddToggle({
    Title = "Weapon",
    Description = "Shows the currently held weapon",
    Flag = "ESPWeapon",
    Default = true,
    Callback = function(v) CONFIG.ShowWeapon = v end,
})
VisualsTab:AddToggle({
    Title = "Distance",
    Description = "Shows the distance in studs",
    Flag = "ESPDist",
    Default = true,
    Callback = function(v) CONFIG.ShowDistance = v end,
})
VisualsTab:AddToggle({
    Title = "Rainbow ESP",
    Description = "Cycles ESP colors through a rainbow effect",
    Flag = "Rainbow",
    Default = false,
    Callback = function(v) CONFIG.RainbowESP = v end,
})
VisualsTab:AddColorPicker({
    Title = "ESP Color",
    Description = "Base color of all ESP elements",
    Default = Color3.fromRGB(255, 80, 80),
    Flag = "ESPColor",
    Callback = function(c) CONFIG.ESPColor = c end,
})

Window:BuildConfigSection(ConfigTab)

CreditsTab:AddSection({ Title = "about" })
CreditsTab:AddParagraph({
    Title = "Flick Hub v" .. VERSION,
    Content = "A personal project for [FPS] Flick.\nFocused on stability and staying low-profile.",
})
CreditsTab:AddParagraph({
    Title = "Developer",
    Content = "AkiraDev — github.com/akiradv",
})
CreditsTab:AddParagraph({
    Title = "UI Library",
    Content = "Eazy UI " .. EZ.Version .. " by AkiraDev",
})

CreditsTab:AddSection({ Title = "community" })
CreditsTab:AddButton({
    Title = "Join Discord",
    Description = "Copy the invite link to join the server",
    ButtonText = "Copy Link",
    Callback = function()
        local invite = "https://discord.gg/" .. DISCORD
        if setclipboard then
            setclipboard(invite)
            EZ:Notify({ Title = "Discord", Content = "Invite link copied to clipboard!", Duration = 3, Style = "Success" })
        else
            EZ:Notify({ Title = "Discord", Content = "Copy this link: " .. invite, Duration = 10, Style = "Info" })
        end
    end,
})

EZ:Notify({ Title = "Flick Hub", Content = "Loaded v" .. VERSION, Style = "Success", Duration = 3 })