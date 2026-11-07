local BB_Eazy = loadstring(game:HttpGet("https://raw.githubusercontent.com/akiradv/eazyuilib/refs/heads/main/eazyui.lua"))()
local BB_Version = "1.1.58"
local BB_UIVersion = BB_Eazy.Version

local BB_Players = cloneref(game:GetService("Players"))
local BB_LocalPlayer = BB_Players.LocalPlayer
local BB_RunService = cloneref(game:GetService("RunService"))
local BB_UserInputService = cloneref(game:GetService("UserInputService"))
local BB_Workspace = cloneref(game:GetService("Workspace"))
local BB_TeleportService = cloneref(game:GetService("TeleportService"))
local BB_HttpService = cloneref(game:GetService("HttpService"))
local BB_ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
local BB_Stats = cloneref(game:GetService("Stats"))

local BB_Alive = BB_Workspace:FindFirstChild("Alive") or BB_Workspace:WaitForChild("Alive", 15)
local BB_Runtime = BB_Workspace:FindFirstChild("Runtime")

local BB_Config = {
    MovementMods = false, WalkSpeed = 36, JumpPower = 50,
    Fly = false, FlySpeed = 60,
    PlayerESP = false, PlayerESPNames = true, PlayerESPDistance = true,
    PlayerESPColor = Color3.fromRGB(216, 160, 255),
    AbilityESP = false, AbilityESPColor = Color3.fromRGB(0, 255, 200),
    Headless = false, Korblox = false,
}

local BB_SwordsModule, BB_AnimationController, BB_SwordApi
pcall(function()
    BB_SwordsModule = require(BB_ReplicatedStorage.Shared.ReplicatedInstances.Swords)
    BB_AnimationController = require(BB_ReplicatedStorage.Controllers.AnimationController)
    BB_SwordApi = require(BB_ReplicatedStorage.Shared.SwordAPI)
end)

local BB_DataAbilities = BB_ReplicatedStorage:FindFirstChild("Misc") and BB_ReplicatedStorage.Misc:FindFirstChild("DataAbilities")
if not BB_DataAbilities then
    task.spawn(function()
        local ok, misc = pcall(function() return BB_ReplicatedStorage:WaitForChild("Misc", 15) end)
        if ok and misc then
            local ok2, da = pcall(function() return misc:WaitForChild("DataAbilities", 15) end)
            if ok2 then BB_DataAbilities = da end
        end
    end)
end

local BB_AbilityTranslations = {
    ["Sorte"] = "Luck",
    ["Bola de Ouro"] = "Golden Ball",
    ["Mártir"] = "Martyrdom",
    ["Maldição"] = "Misfortune",
    ["Ceifador"] = "Reaper",
    ["Tato"] = "Tact",
    ["Escopofobia"] = "Scopophobia",
    ["Recompensa"] = "Bounty",
    ["Carga Qi"] = "Qi-Charge",
    ["Anjo da Guarda"] = "Guardian Angel",
    ["Vírus"] = "Virus",
    ["Salto Quádruplo"] = "Quad Jump",
    ["Deflexão Calma"] = "Calming Deflection",
    ["Deflexão Furiosa"] = "Raging Deflection",
    ["Arrebatamento"] = "Rapture",
    ["Corte Aerodinâmico"] = "Aerodynamic Slash",
    ["Campo de Força"] = "Forcefield",
    ["Infinito"] = "Infinity",
    ["Fratura"] = "Fracture",
    ["Corte da Morte"] = "Death Slash",
    ["Cortes da Fúria"] = "Slashes of Fury",
    ["Fantasma"] = "Phantom",
    ["Necromante"] = "Necromancer",
    ["Arena Quântica"] = "Quantum Arena",
    ["Espírito do Dragão"] = "Dragon Spirit",
    ["Drible"] = "Dribble",
    ["Combo"] = "Combo",
    ["Ganância"] = "Greed",
    ["Troca"] = "Swap",
    ["Escudo"] = "Shield",
    ["Singularidade"] = "Singularity",
    ["Queda"] = "Fall",
    ["Laser"] = "Laser",
    ["Puxão"] = "Pull",
    ["Empurrão"] = "Push",
    ["Teletransporte"] = "Teleport",
    ["Corrida Ninja"] = "Ninja Run",
    ["Congelar"] = "Freeze",
    ["Kamikaze"] = "Kamikaze",
    ["Bola de Fogo"] = "Fireball",
    ["Meteoro"] = "Meteor",
    ["Arremesso"] = "Throw",
    ["Salto"] = "Jump",
    ["Buraco Negro"] = "Black Hole",
    ["Tempestade"] = "Storm",
    ["Raio"] = "Lightning",
    ["Gelo"] = "Ice",
    ["Fogo"] = "Fire",
    ["Água"] = "Water",
    ["Vento"] = "Wind",
    ["Terra"] = "Earth",
    ["Luz"] = "Light",
    ["Trevas"] = "Darkness",
    ["Tempo"] = "Time",
    ["Espaço"] = "Space",
    ["Realidade"] = "Reality",
    ["Mente"] = "Mind",
    ["Alma"] = "Soul",
    ["Poder"] = "Power",
    ["Força"] = "Strength",
    ["Velocidade"] = "Speed",
    ["Voo"] = "Flight",
    ["Invisibilidade"] = "Invisibility",
    ["Cura"] = "Heal",
    ["Ressurreição"] = "Resurrection",
    ["Imortalidade"] = "Immortality",
}

local BB_Token
local BB_TokenFound = false
pcall(function()
    for _, Function in getgc(true) do
        if type(Function) ~= 'function' or not debug.info(Function, 's'):find('PRY', 1, true) then
            continue
        end
        for _, value in debug.getupvalues(Function) do
            if type(value) == 'function' then
                BB_Token = value
                BB_TokenFound = true
                break
            end
        end
        if BB_Token then break end
    end
end)

if not BB_TokenFound then
    BB_Eazy:Notify({ Title = "Blade Ball Hub", Content = "Remote not found or executor not supported.", Style = "Error", Duration = 5 })
    return
end

local BB_OriginalFireServer
local BB_CapturedRemote = nil
local BB_CapturedArgs = nil

pcall(function()
    BB_OriginalFireServer = hookfunction(Instance.new("RemoteEvent").FireServer, newcclosure(function(self, ...)
        if not checkcaller() and not BB_CapturedRemote then
            local args = {...}
            if #args >= 8 and type(args[1]) == "string" and typeof(args[5]) == "CFrame" then
                BB_CapturedRemote = self
                BB_CapturedArgs = args
            end
        end
        return BB_OriginalFireServer(self, ...)
    end))
end)

local BB_CurveNames = {"Camera", "Random", "Accelerated", "Backwards", "Slow", "High", "Normal", "Speed", "Down", "Left", "Right"}
local BB_LegitCurveNames = {"Right", "Left", "Backwards", "Normal"}
local BB_SelectedCurve = "Camera"

local function BB_GetCurveCFrame()
    local cam = BB_Workspace.CurrentCamera
    local char = BB_LocalPlayer.Character
    local root = char and (char.PrimaryPart or char:FindFirstChild("HumanoidRootPart"))
    local rootPos = root and root.Position or cam.CFrame.Position
    local targetPart
    do
        local bestDist = math.huge
        local mouseLoc = BB_UserInputService:GetMouseLocation()
        if BB_Alive then
            for _, v in ipairs(BB_Alive:GetChildren()) do
                if v ~= char and v.PrimaryPart then
                    local screenPos, onScreen = cam:WorldToScreenPoint(v.PrimaryPart.Position)
                    if onScreen then
                        local d = (Vector2.new(screenPos.X, screenPos.Y) - mouseLoc).Magnitude
                        if d < bestDist then bestDist = d; targetPart = v.PrimaryPart end
                    end
                end
            end
        end
    end
    local targetPos = targetPart and targetPart.Position or (rootPos + cam.CFrame.LookVector * 100)
    local t = BB_SelectedCurve
    if t == "Camera" then return cam.CFrame
    elseif t == "Random" then
        local direction = (targetPos - rootPos).Unit
        local offset
        local attempts = 0
        repeat
            offset = Vector3.new(math.random(-4000, 4000), math.random(-4000, 4000), math.random(-4000, 4000))
            attempts = attempts + 1
        until direction:Dot((targetPos + offset - rootPos).Unit) < 0.95 or attempts > 10
        return CFrame.new(rootPos, targetPos + offset)
    elseif t == "Accelerated" then return CFrame.new(rootPos, targetPos + Vector3.new(0, 5, 0))
    elseif t == "Backwards" then
        local direction = (rootPos - targetPos).Unit
        return CFrame.new(cam.CFrame.Position, rootPos + direction * 10000 + Vector3.new(0, 1000, 0))
    elseif t == "Slow" then return CFrame.new(rootPos, targetPos + Vector3.new(0, -9e18, 0))
    elseif t == "High" then return CFrame.new(rootPos, targetPos + Vector3.new(0, 9e18, 0))
    elseif t == "Normal" then return CFrame.new(rootPos, rootPos + (root and root.CFrame.LookVector or cam.CFrame.LookVector))
    elseif t == "Speed" then return CFrame.new(cam.CFrame.Position, cam.CFrame.Position + cam.CFrame.UpVector * 5)
    elseif t == "Down" then return CFrame.new(cam.CFrame.Position, cam.CFrame.Position + cam.CFrame.UpVector * -9e9)
    elseif t == "Left" then return CFrame.new(cam.CFrame.Position, cam.CFrame.Position - cam.CFrame.RightVector * 9e9)
    elseif t == "Right" then return CFrame.new(cam.CFrame.Position, cam.CFrame.Position + cam.CFrame.RightVector * 9e9)
    end
    return cam.CFrame
end

local function BB_FireParryRemote(curveCF)
    if not BB_CapturedRemote or not BB_CapturedArgs then return false end
    local time = tostring(math.floor(BB_Workspace:GetServerTimeNow() * 100))
    local key = BB_Token(BB_CapturedArgs[2], 'TIME')
    local characters = table.create(#time)
    for index = 1, #time do
        characters[index] = string.char(bit32.bxor(
            (string.byte(time, index) + index) % 256,
            string.byte(key, (index - 1) % #key + 1)
        ))
    end
    local timeHash = table.concat(characters)

    local cam = BB_Workspace.CurrentCamera
    local mouse = BB_UserInputService:GetMouseLocation()
    local aimTarget = {math.floor(mouse.X), math.floor(mouse.Y)}
    local eventData = {}
    if BB_Alive then
        for _, entity in ipairs(BB_Alive:GetChildren()) do
            if entity.PrimaryPart then
                local ok, sp = pcall(function() return cam:WorldToScreenPoint(entity.PrimaryPart.Position) end)
                if ok then eventData[entity.Name] = sp end
            end
        end
    end
    local packet = {
        BB_CapturedArgs[1],
        BB_CapturedArgs[2],
        timeHash,
        0.5,
        curveCF or cam.CFrame,
        eventData,
        aimTarget,
        false
    }
    pcall(function()
        if BB_CapturedRemote:IsA('RemoteEvent') then
            BB_CapturedRemote:FireServer(unpack(packet))
        elseif BB_CapturedRemote:IsA('RemoteFunction') then
            BB_CapturedRemote:InvokeServer(unpack(packet))
        end
    end)
    return true
end

local function BB_TriggerBlockFallback()
    pcall(function()
        local pg = BB_LocalPlayer:FindFirstChild("PlayerGui")
        local hotbar = pg and pg:FindFirstChild("Hotbar")
        local blockButton = hotbar and hotbar:FindFirstChild("Block")
        if blockButton then
            for _, conn in pairs(getconnections(blockButton.Activated)) do
                pcall(function() conn:Fire() end)
            end
            for _, conn in pairs(getconnections(blockButton.MouseButton1Click)) do
                pcall(function() conn:Fire() end)
            end
            for _, conn in pairs(getconnections(blockButton.MouseButton1Down)) do
                pcall(function() conn:Fire() end)
            end
        end
    end)
end

local BB_System = {
    __properties = {
        __autoparry_enabled = false,
        __auto_spam_enabled = false,
        __play_animation = false,
        __accuracy = 50,
        __divisor_multiplier = 1.1,
        __parried = false,
        __spam_threshold = 1.5,
        __parries = 0,
        __grab_animation = nil,
        __tornado_time = tick(),
        __connections = {},
        __randomized_accuracy_enabled = false,
        __infinity_active = false,
        __deathslash_active = false,
        __timehole_active = false,
        __slashesoffury_active = false,
    },
    __config = {
        __detections = {__infinity = false, __deathslash = false, __timehole = false, __slashesoffury = false}
    },
}

local function BB_UpdateDivisor()
    BB_System.__properties.__divisor_multiplier = 0.7 + (BB_System.__properties.__accuracy - 1) * (0.9 / 99)
end

local function BB_UpdateRandomizedAccuracy()
    if not BB_System.__properties.__randomized_accuracy_enabled then return end
    local pingStr = BB_Stats.Network.ServerStatsItem["Data Ping"]:GetValueString()
    local ping = tonumber(pingStr:match("%d+")) or 0
    local newAccuracy
    if ping >= 90 then newAccuracy = 4
    elseif ping <= 50 then newAccuracy = math.random(70, 100)
    else newAccuracy = BB_System.__properties.__accuracy end
    if newAccuracy then BB_System.__properties.__accuracy = newAccuracy; BB_UpdateDivisor() end
end

task.spawn(function()
    while task.wait(1) do
        if BB_System.__properties.__randomized_accuracy_enabled then BB_UpdateRandomizedAccuracy() end
    end
end)

local BB_LastPlayed = 0
local BB_SwordCP = false
local BB_AnimCache = {}

local function BB_GetParryAnimation(swordName)
    if not swordName or swordName == "" then
        return BB_SwordApi and BB_SwordApi.Collection.Default:FindFirstChild("GrabParry")
    end
    if BB_AnimCache[swordName] then return BB_AnimCache[swordName] end
    local ok, swordData = pcall(function()
        return BB_ReplicatedStorage.Shared.ReplicatedInstances.Swords.GetSword:Invoke(swordName)
    end)
    if not ok or not swordData or type(swordData) ~= "table" or not swordData.AnimationType then
        BB_AnimCache[swordName] = BB_SwordApi.Collection.Default:FindFirstChild("GrabParry")
        return BB_AnimCache[swordName]
    end
    for _, obj in pairs(BB_SwordApi.Collection:GetChildren()) do
        if obj.Name == swordData.AnimationType then
            local anim = obj:FindFirstChild("GrabParry") or obj:FindFirstChild("Grab")
            if anim then
                BB_AnimCache[swordName] = anim
                return anim
            end
        end
    end
    BB_AnimCache[swordName] = BB_SwordApi.Collection.Default:FindFirstChild("GrabParry")
    return BB_AnimCache[swordName]
end

local function BB_PlayGrabParry()
    if not BB_System.__properties.__play_animation then return end
    if not ((os.clock() - BB_LastPlayed) >= 0.2 or BB_SwordCP) then return end
    BB_LastPlayed = os.clock()
    BB_SwordCP = false
    local char = BB_LocalPlayer.Character
    if not char then return end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    local currentSword = char:GetAttribute("CurrentlyEquippedSword")
    local animation = BB_GetParryAnimation(currentSword)
    if not animation then return end
    for _, track in pairs(humanoid.Animator:GetPlayingAnimationTracks()) do
        if track.Name == "GrabParry" or track.Name == "Grab" then
            track.TimePosition = 0
            pcall(function() track:Stop(0.1) end)
        elseif track.Name == "SuccessParry" or track.Name == "Success" then
            pcall(function() track:Stop(0.1) end)
        end
    end
    BB_System.__properties.__grab_animation = humanoid.Animator:LoadAnimation(animation)
    pcall(function() BB_System.__properties.__grab_animation:Play(0, 1, 1) end)
end

pcall(function()
    BB_ReplicatedStorage.Remotes.ParrySuccessAll.OnClientEvent:Connect(function()
        BB_SwordCP = true
        local char = BB_LocalPlayer.Character
        if not char then return end
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if not humanoid then return end
        for _, track in pairs(humanoid.Animator:GetPlayingAnimationTracks()) do
            if track.Name == "GrabParry" or track.Name == "Grab" then
                pcall(function() track:Stop(0.1) end)
            end
        end
    end)
end)

local BB_Ball = {}
function BB_Ball.get()
    local balls = BB_Workspace:FindFirstChild('Balls')
    if not balls then return nil end
    for _, ball in pairs(balls:GetChildren()) do
        if ball:GetAttribute('realBall') then pcall(function() ball.CanCollide = false end); return ball end
    end
    return nil
end
function BB_Ball.get_all()
    local t = {}
    local balls = BB_Workspace:FindFirstChild('Balls')
    if not balls then return t end
    for _, ball in pairs(balls:GetChildren()) do
        if ball:GetAttribute('realBall') then pcall(function() ball.CanCollide = false end); table.insert(t, ball) end
    end
    return t
end

local BB_ClosestEntity = nil
local BB_LastClosestCheck = 0
local function BB_GetClosest()
    local now = tick()
    if now - BB_LastClosestCheck < 0.1 then return BB_ClosestEntity end
    BB_LastClosestCheck = now
    local maxDist = math.huge
    local closest = nil
    if not BB_Alive then return nil end
    for _, entity in pairs(BB_Alive:GetChildren()) do
        if entity ~= BB_LocalPlayer.Character and entity.PrimaryPart then
            local d = BB_LocalPlayer:DistanceFromCharacter(entity.PrimaryPart.Position)
            if d < maxDist then maxDist = d; closest = entity end
        end
    end
    BB_ClosestEntity = closest
    return closest
end

local BB_Parry = {}
function BB_Parry.execute()
    if BB_System.__properties.__parries > 10000 or not BB_LocalPlayer.Character then return end
    local ok = BB_FireParryRemote(BB_GetCurveCFrame())
    if not ok then
        BB_TriggerBlockFallback()
    end
    BB_System.__properties.__parries = BB_System.__properties.__parries + 1
    task.delay(0.5, function()
        if BB_System.__properties.__parries > 0 then BB_System.__properties.__parries = BB_System.__properties.__parries - 1 end
    end)
end

function BB_Parry.keypress()
    if BB_System.__properties.__parries > 10000 or not BB_LocalPlayer.Character then return end
    local ok = BB_FireParryRemote(BB_GetCurveCFrame())
    if not ok then
        BB_TriggerBlockFallback()
    end
    BB_System.__properties.__parries = BB_System.__properties.__parries + 1
    task.delay(0.5, function()
        if BB_System.__properties.__parries > 0 then BB_System.__properties.__parries = BB_System.__properties.__parries - 1 end
    end)
end

function BB_Parry.execute_action()
    BB_PlayGrabParry()
    BB_Parry.execute()
end

local function BB_LinearPredict(a, b, t) return a + (b - a) * t end

local BB_Detection = {
    __ball_properties = {__last_warping = tick(), __lerp_radians = 0, __curving = tick()}
}

function BB_Detection.is_curved()
    local props = BB_Detection.__ball_properties
    local ball = BB_Ball.get(); if not ball then return false end
    local zoomies = ball:FindFirstChild("zoomies"); if not zoomies then return false end
    local velocity = zoomies.VectorVelocity; local speed = velocity.Magnitude
    if speed < 1 then return false end
    local ballDir = velocity.Unit; local char = BB_LocalPlayer.Character
    if not char or not char.PrimaryPart then return false end
    local pos = char.PrimaryPart.Position; local direction = (pos - ball.Position).Unit
    local dot = direction:Dot(ballDir)
    local ping = BB_Stats.Network.ServerStatsItem["Data Ping"]:GetValue() / 1000
    local distance = (pos - ball.Position).Magnitude; local reachTime = distance / speed - ping
    local dotThreshold = math.clamp(0.55 - (ping * 0.75), -1, 0.45)
    local speedThreshold = math.min(speed / 100, 45)
    local ballDistThreshold = 15 - math.min(distance / 1000, 15) + speedThreshold
    local clampedDot = math.clamp(dot, -1, 1); local radians = math.asin(clampedDot)
    props.__lerp_radians = BB_LinearPredict(props.__lerp_radians, radians, 0.85)
    if props.__lerp_radians < 0.016 then props.__last_warping = tick() end
    if distance < (ballDistThreshold * 0.85) then return false end
    if (tick() - props.__last_warping) < (reachTime / 1.4) then return true end
    if (tick() - props.__curving) < (reachTime / 1.1) then return true end
    return dot < dotThreshold
end

pcall(function()
    BB_ReplicatedStorage.Remotes.DeathBall.OnClientEvent:Connect(function(c, d)
        BB_System.__properties.__deathslash_active = d or false
    end)
    BB_ReplicatedStorage.Remotes.InfinityBall.OnClientEvent:Connect(function(a, b)
        BB_System.__properties.__infinity_active = b or false
    end)
    local net = BB_ReplicatedStorage.Packages._Index["sleitnick_net@0.1.0"].net
    net["RE/TimeHoleActivate"].OnClientEvent:Connect(function(...)
        local args = {...}; local p = args[1]
        if p == BB_LocalPlayer or p == BB_LocalPlayer.Name or (p and p.Name == BB_LocalPlayer.Name) then
            BB_System.__properties.__timehole_active = true
        end
    end)
    net["RE/TimeHoleDeactivate"].OnClientEvent:Connect(function()
        BB_System.__properties.__timehole_active = false
    end)
    net["RE/SlashesOfFuryActivate"].OnClientEvent:Connect(function(...)
        local args = {...}; local p = args[1]
        if p == BB_LocalPlayer or p == BB_LocalPlayer.Name or (p and p.Name == BB_LocalPlayer.Name) then
            BB_System.__properties.__slashesoffury_active = true
        end
    end)
    net["RE/SlashesOfFuryEnd"].OnClientEvent:Connect(function()
        BB_System.__properties.__slashesoffury_active = false
    end)
end)

local BB_AutoParry = {}
function BB_AutoParry.start()
    if BB_System.__properties.__connections.__autoparry then
        BB_System.__properties.__connections.__autoparry:Disconnect()
    end
    BB_System.__properties.__connections.__autoparry = BB_RunService.PreSimulation:Connect(function()
        if not BB_System.__properties.__autoparry_enabled or not BB_LocalPlayer.Character or
           not BB_LocalPlayer.Character.PrimaryPart then return end
        local balls = BB_Ball.get_all()
        local one_ball = BB_Ball.get()
        for _, ball in pairs(balls) do
            if not ball then continue end
            local zoomies = ball:FindFirstChild('zoomies'); if not zoomies then continue end
            ball:GetAttributeChangedSignal('target'):Once(function() BB_System.__properties.__parried = false end)
            if BB_System.__properties.__parried then continue end
            local ballTarget = ball:GetAttribute('target')
            local velocity = zoomies.VectorVelocity
            local distance = (BB_LocalPlayer.Character.PrimaryPart.Position - ball.Position).Magnitude
            local ping = BB_Stats.Network.ServerStatsItem['Data Ping']:GetValue() / 10
            local pingThreshold = math.clamp(ping / 10, 5, 17)
            local speed = velocity.Magnitude
            local cappedSpeedDiff = math.min(math.max(speed - 9.5, 0), 650)
            local speedDivisor = (2.4 + cappedSpeedDiff * 0.002) * BB_System.__properties.__divisor_multiplier
            local parryAccuracy = pingThreshold + math.max(speed / speedDivisor, 9.5)
            local curved = BB_Detection.is_curved()
            if ball:FindFirstChild('AeroDynamicSlashVFX') then
                ball.AeroDynamicSlashVFX:Destroy(); BB_System.__properties.__tornado_time = tick()
            end
            if BB_Runtime and BB_Runtime:FindFirstChild('Tornado') then
                if (tick() - BB_System.__properties.__tornado_time) <
                   (BB_Runtime.Tornado:GetAttribute('TornadoTime') or 1) + 0.314159 then continue end
            end
            if one_ball and one_ball:GetAttribute('target') == BB_LocalPlayer.Name and curved then continue end
            if ball:FindFirstChild('ComboCounter') then continue end
            if BB_LocalPlayer.Character.PrimaryPart:FindFirstChild('SingularityCape') then continue end
            if BB_System.__config.__detections.__infinity and BB_System.__properties.__infinity_active then continue end
            if BB_System.__config.__detections.__deathslash and BB_System.__properties.__deathslash_active then continue end
            if BB_System.__config.__detections.__timehole and BB_System.__properties.__timehole_active then continue end
            if BB_System.__config.__detections.__slashesoffury and BB_System.__properties.__slashesoffury_active then continue end
            if ballTarget == BB_LocalPlayer.Name and distance <= parryAccuracy then
                if getgenv().AutoParryMode == "Keypress" then BB_Parry.keypress()
                else BB_Parry.execute_action() end
                BB_System.__properties.__parried = true
            end
            local lastParrys = tick()
            repeat BB_RunService.Stepped:Wait()
            until (tick() - lastParrys) >= 1 or not BB_System.__properties.__parried
            BB_System.__properties.__parried = false
        end
    end)
end

function BB_AutoParry.stop()
    if BB_System.__properties.__connections.__autoparry then
        BB_System.__properties.__connections.__autoparry:Disconnect()
        BB_System.__properties.__connections.__autoparry = nil
    end
end

local BB_AutoSpam = {}

local function BB_GetEntityProperties()
    BB_GetClosest()
    if not BB_ClosestEntity or not BB_LocalPlayer.Character or not BB_LocalPlayer.Character.PrimaryPart or not BB_ClosestEntity.PrimaryPart then return false end
    local entityVelocity = BB_ClosestEntity.PrimaryPart.AssemblyLinearVelocity
    local entityDirection = (BB_LocalPlayer.Character.PrimaryPart.Position - BB_ClosestEntity.PrimaryPart.Position).Unit
    local entityDistance = (BB_LocalPlayer.Character.PrimaryPart.Position - BB_ClosestEntity.PrimaryPart.Position).Magnitude
    return {Velocity = entityVelocity, Direction = entityDirection, Distance = entityDistance}
end

local function BB_GetBallProperties()
    local ball = BB_Ball.get()
    if not ball or not BB_LocalPlayer.Character or not BB_LocalPlayer.Character.PrimaryPart then return false end
    local ballVelocity = ball.AssemblyLinearVelocity
    local ballDirection = (BB_LocalPlayer.Character.PrimaryPart.Position - ball.Position).Unit
    local ballDistance = (BB_LocalPlayer.Character.PrimaryPart.Position - ball.Position).Magnitude
    local ballDot = ballVelocity.Magnitude > 0 and ballDirection:Dot(ballVelocity.Unit) or 0
    return {Velocity = ballVelocity, Direction = ballDirection, Distance = ballDistance, Dot = ballDot}
end

local function BB_SpamService(self)
    local ball = BB_Ball.get()
    local entity = BB_GetClosest()
    if not ball or not entity or not entity.PrimaryPart or not BB_LocalPlayer.Character or not BB_LocalPlayer.Character.PrimaryPart then return 0 end
    local velocity = ball.AssemblyLinearVelocity
    local speed = velocity.Magnitude
    local direction = (BB_LocalPlayer.Character.PrimaryPart.Position - ball.Position).Unit
    local dot = speed > 0 and direction:Dot(velocity.Unit) or 0
    local targetDistance = BB_LocalPlayer:DistanceFromCharacter(entity.PrimaryPart.Position)
    local maximumSpamDistance = self.Ping + math.min(speed / 6, 255)
    if self.Entity_Properties.Distance > maximumSpamDistance or self.Ball_Properties.Distance > maximumSpamDistance or targetDistance > maximumSpamDistance then return 0 end
    local maximumSpeed = 5 - math.min(speed / 5, 5)
    local maximumDot = math.clamp(dot, -1, 0) * maximumSpeed
    return maximumSpamDistance - maximumDot
end

function BB_AutoSpam.start()
    if BB_System.__properties.__connections.__auto_spam then
        BB_System.__properties.__connections.__auto_spam:Disconnect()
    end
    BB_System.__properties.__auto_spam_enabled = true
    BB_System.__properties.__connections.__auto_spam = BB_RunService.PreSimulation:Connect(function()
        if not BB_System.__properties.__auto_spam_enabled then return end
        local ball = BB_Ball.get()
        if not ball or BB_System.__properties.__slashesoffury_active then return end
        local zoomies = ball:FindFirstChild("zoomies")
        if not zoomies then return end
        BB_GetClosest()
        local ballProps = BB_GetBallProperties()
        local entityProps = BB_GetEntityProperties()
        if not ballProps or not entityProps or not BB_ClosestEntity or not BB_ClosestEntity.PrimaryPart then return end
        local ping = BB_Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
        local pingThreshold = math.clamp(ping / 10, 1, 16)
        local spamAccuracy = BB_SpamService({
            Ball_Properties = ballProps,
            Entity_Properties = entityProps,
            Ping = pingThreshold
        })
        local targetDistance = BB_LocalPlayer:DistanceFromCharacter(BB_ClosestEntity.PrimaryPart.Position)
        local direction = (BB_LocalPlayer.Character.PrimaryPart.Position - ball.Position).Unit
        local ballDirection = zoomies.VectorVelocity.Magnitude > 0 and zoomies.VectorVelocity.Unit or Vector3.zero
        local dot = ballDirection.Magnitude > 0 and direction:Dot(ballDirection) or 0
        local distance = BB_LocalPlayer:DistanceFromCharacter(ball.Position)
        local ballTarget = ball:GetAttribute("target")
        if not ballTarget or targetDistance > spamAccuracy or distance > spamAccuracy then return end
        if BB_LocalPlayer.Character:GetAttribute("Pulsed") then return end
        if ballTarget == BB_LocalPlayer.Name and targetDistance > 30 and distance > 30 then return end
        if distance <= spamAccuracy and BB_System.__properties.__parries > BB_System.__properties.__spam_threshold then
            BB_Parry.execute()
        end
    end)
end

function BB_AutoSpam.stop()
    BB_System.__properties.__auto_spam_enabled = false
    if BB_System.__properties.__connections.__auto_spam then
        BB_System.__properties.__connections.__auto_spam:Disconnect()
        BB_System.__properties.__connections.__auto_spam = nil
    end
end

getgenv().AutoParryMode = getgenv().AutoParryMode or "Remote"

local BB_SkinsHooked = false
local BB_OriginalFindItems = nil
local BB_SwordsController = nil
local BB_EquippedSwordName = nil

local BB_LastExplosion = ""
local BB_Str10 = ""
local BB_ExplosionController = nil

local function BB_FindExplosionController()
    local function findVfxControllerModule()
        local controllers = BB_ReplicatedStorage:FindFirstChild("Controllers")
        if controllers then
            local vfx = controllers:FindFirstChild("VFXController")
            if vfx then
                if vfx:IsA("ModuleScript") then
                    return vfx
                end
                local nested = vfx:FindFirstChild("VFXController")
                if nested and nested:IsA("ModuleScript") then
                    return nested
                end
            end
        end
        for _, descendant in BB_ReplicatedStorage:GetDescendants() do
            if descendant.Name == "VFXController" and descendant:IsA("ModuleScript") then
                return descendant
            end
        end
    end
    local scriptModule = findVfxControllerModule()
    if not scriptModule then return nil end
    local ok, result = pcall(require, scriptModule)
    if ok and type(result) == "table" and type(result.PlayExplosion) == "function" then
        return result
    end
end

task.spawn(function()
    while not BB_ExplosionController do
        BB_ExplosionController = BB_FindExplosionController()
        if not BB_ExplosionController then
            task.wait(1)
        end
    end

    if BB_ExplosionController and type(BB_ExplosionController.PlayExplosion) == "function" and not BB_ExplosionController.__bb_explosion_hooked then
        BB_ExplosionController.__bb_explosion_hooked = true
        local originalPlayExplosion = BB_ExplosionController.PlayExplosion

        BB_ExplosionController.PlayExplosion = function(arg, arg2, arg3, arg4, arg5, arg6, arg7)
            if BB_Str10 and BB_Str10 ~= "" then
                if arg7 and arg6 == BB_LocalPlayer.Character then
                    arg2 = BB_Str10
                end
            end
            return originalPlayExplosion(arg, arg2, arg3, arg4, arg5, arg6, arg7)
        end
    end
end)

local function BB_GetSetSword()
    if BB_SwordsController then return BB_SwordsController end
    for _, connection in getconnections(BB_ReplicatedStorage.Remotes.ParrySuccess.OnClientEvent) do
        local values = connection.Function and (getupvalues or debug.getupvalues)(connection.Function)
        if type(values) == "table" then
            for _, value in values do
                if type(value) == "table" and type(rawget(value, "SetSword")) == "function" then
                    BB_SwordsController = value
                    return value
                end
            end
        end
    end
    return nil
end

local function BB_SetEquippedSword(swordName)
    BB_EquippedSwordName = swordName
    pcall(function() BB_LocalPlayer:SetAttribute("CurrentlyEquippedSword", swordName) end)
    if BB_SwordsModule then pcall(function() BB_SwordsModule:EquipSwordTo(BB_LocalPlayer.Character, swordName) end) end
    local controller = BB_GetSetSword()
    if controller then pcall(function() controller:SetSword(swordName) end) end
end

local function BB_SetEquippedExplosion(explosionName)
    BB_LastExplosion = explosionName
    BB_Str10 = explosionName
    pcall(function() BB_LocalPlayer:SetAttribute("CurrentlyEquippedExplosion", explosionName) end)
end

local function BB_BindCharacterCosmeticFixer(character)
    pcall(function()
        for _, conn in getconnections(character:GetAttributeChangedSignal("CurrentlyEquippedSword")) do
            pcall(function() conn:Disable() end)
        end
    end)
    
    character:GetAttributeChangedSignal("CurrentlyEquippedSword"):Connect(function()
        if not BB_SkinsHooked or not BB_EquippedSwordName then return end
        local attr = character:GetAttribute("CurrentlyEquippedSword")
        if attr ~= BB_EquippedSwordName then
            pcall(function() character:SetAttribute("CurrentlyEquippedSword", BB_EquippedSwordName) end)
            if BB_SwordsModule then pcall(function() BB_SwordsModule:EquipSwordTo(character, BB_EquippedSwordName) end) end
            local controller = BB_GetSetSword()
            if controller then pcall(function() controller:SetSword(BB_EquippedSwordName) end) end
        end
    end)

    if BB_EquippedSwordName and BB_SkinsHooked then
        task.wait(0.5)
        pcall(function()
            character:SetAttribute("CurrentlyEquippedSword", BB_EquippedSwordName)
            if BB_SwordsModule then BB_SwordsModule:EquipSwordTo(character, BB_EquippedSwordName) end
            local controller = BB_GetSetSword()
            if controller then controller:SetSword(BB_EquippedSwordName) end
        end)
    end
end

BB_LocalPlayer.CharacterAdded:Connect(BB_BindCharacterCosmeticFixer)
if BB_LocalPlayer.Character then BB_BindCharacterCosmeticFixer(BB_LocalPlayer.Character) end

local function BB_HookBuyButton()
    local shop = BB_LocalPlayer.PlayerGui:FindFirstChild("Shop")
    if not shop then task.delay(2, BB_HookBuyButton) return end
    local holder = shop:FindFirstChild("Holder")
    if not holder then task.delay(2, BB_HookBuyButton) return end
    local infoBG = holder:FindFirstChild("InfoBG")
    if not infoBG then task.delay(2, BB_HookBuyButton) return end
    local buyButton = infoBG:FindFirstChild("BuyButton")
    if not buyButton then task.delay(2, BB_HookBuyButton) return end

    if buyButton:GetAttribute("BB_Hooked") then return end
    buyButton:SetAttribute("BB_Hooked", true)

    buyButton.Activated:Connect(function()
        local ok, ShopController = pcall(require, BB_ReplicatedStorage.Controllers.UI.ShopController)
        if not ok or not ShopController then return end
        local selectedItem = ShopController._selectedItem
        if not selectedItem then return end

        if selectedItem.type == "Sword" then
            BB_SetEquippedSword(selectedItem.name)
            pcall(function() buyButton.PriceTag.TextLabel.Text = "Equipped" end)
        elseif selectedItem.type == "Explosion" then
            BB_SetEquippedExplosion(selectedItem.name)
            pcall(function() buyButton.PriceTag.TextLabel.Text = "Equipped" end)
        end
    end)
end

task.spawn(BB_HookBuyButton)

task.spawn(function()
    local ShopController
    while not ShopController do
        task.wait(1)
        pcall(function()
            ShopController = require(BB_ReplicatedStorage.Controllers.UI.ShopController)
        end)
    end

    if ShopController and ShopController.itemSelected then
        ShopController.itemSelected:Connect(function()
            task.defer(function()
                local selectedItem = ShopController._selectedItem
                if not selectedItem then return end
                local shop = BB_LocalPlayer.PlayerGui:FindFirstChild("Shop")
                if not shop then return end
                local holder = shop:FindFirstChild("Holder")
                if not holder then return end
                local infoBG = holder:FindFirstChild("InfoBG")
                if not infoBG then return end
                local buyButton = infoBG:FindFirstChild("BuyButton")
                if not buyButton then return end
                local priceTag = buyButton:FindFirstChild("PriceTag")
                if not priceTag then return end
                local textLabel = priceTag:FindFirstChild("TextLabel")
                if not textLabel then return end

                if selectedItem.type == "Sword" then
                    if selectedItem.name == BB_EquippedSwordName then
                        textLabel.Text = "Equipped"
                    end
                elseif selectedItem.type == "Explosion" then
                    if selectedItem.name == BB_LastExplosion then
                        textLabel.Text = "Equipped"
                    end
                end
            end)
        end)
    end
end)

local function BB_UnlockAllCosmetics(state)
    if state and not BB_SkinsHooked then
        BB_SkinsHooked = true

        BB_Str10 = BB_LastExplosion

        if not BB_ExplosionController then
            BB_ExplosionController = BB_FindExplosionController()
        end

        if BB_ExplosionController and type(BB_ExplosionController.PlayExplosion) == "function" and not BB_ExplosionController.__bb_explosion_hooked then
            BB_ExplosionController.__bb_explosion_hooked = true
            local originalPlayExplosion = BB_ExplosionController.PlayExplosion

            BB_ExplosionController.PlayExplosion = function(arg, arg2, arg3, arg4, arg5, arg6, arg7)
                if BB_Str10 and BB_Str10 ~= "" then
                    if arg7 and arg6 == BB_LocalPlayer.Character then
                        arg2 = BB_Str10
                    end
                end
                return originalPlayExplosion(arg, arg2, arg3, arg4, arg5, arg6, arg7)
            end
        end

        pcall(function()
            local Shared = require(BB_ReplicatedStorage.Shared.Inventory.Shared)
            BB_OriginalFindItems = hookfunction(Shared.FindItems, function(arg, arg2, arg3, arg4, arg5)
                local ok, result = pcall(BB_OriginalFindItems, arg, arg2, arg3, arg4, arg5)
                if string.find(tostring(arg3), "Abilit", 1, true) then
                    if ok then return result end
                    return {}
                end
                if ok and type(result) == "table" and #result > 0 then return result end
                if arg4 ~= nil then return { arg4 } end
                return {}
            end)

            local ok2, ShopController = pcall(require, BB_ReplicatedStorage.Controllers.UI.ShopController)
            if ok2 and ShopController and ShopController._virtualItems then
                for _, items in pairs(ShopController._virtualItems) do
                    if type(items) == "table" then
                        for _, shopItem in pairs(items) do
                            if shopItem and shopItem.OwnsItem and (shopItem.type == "Sword" or shopItem.type == "Explosion") then
                                pcall(function()
                                    shopItem.OwnsItem:Set(true)
                                    shopItem.Section = "Owned"
                                    shopItem.ForceHide = false
                                end)
                            end
                        end
                    end
                end
                if ShopController._inventoryPages then
                    for _, page in pairs(ShopController._inventoryPages) do
                        if page and page.MarkDirty then
                            pcall(function() page:MarkDirty(nil, false, true) end)
                        end
                    end
                end
            end
        end)

        task.spawn(function()
            task.wait(1)
            BB_HookBuyButton()
        end)

        BB_Eazy:Notify({ Title = "Cosmetics", Content = "Skins & explosions unlocked.", Style = "Success", Duration = 3 })
    elseif not state and BB_SkinsHooked then
        BB_SkinsHooked = false
        if BB_OriginalFindItems then
            pcall(function()
                local Shared = require(BB_ReplicatedStorage.Shared.Inventory.Shared)
                hookfunction(Shared.FindItems, BB_OriginalFindItems)
                BB_OriginalFindItems = nil
            end)
        end
    end
end

local BB_CombinedBillboards = setmetatable({}, {__mode = "k"})

local function BB_GetAbilityInfo(player, character)
    if not BB_DataAbilities then
        pcall(function()
            local misc = BB_ReplicatedStorage:FindFirstChild("Misc")
            BB_DataAbilities = misc and misc:FindFirstChild("DataAbilities")
        end)
    end

    local rawName = player:GetAttribute("EquippedAbility")
    if not rawName or rawName == "" then
        rawName = character:GetAttribute("EquippedAbility")
    end
    if not rawName or rawName == "" then
        rawName = character:GetAttribute("CurrentlyEquippedAbility")
    end
    if not rawName or rawName == "" then return nil, nil end

    local displayName = BB_AbilityTranslations[rawName]
    local icon = nil

    if BB_DataAbilities then
        local data = BB_DataAbilities:FindFirstChild(rawName)
        if not data and displayName then
            data = BB_DataAbilities:FindFirstChild(displayName)
        end

        if not data then
            for _, child in ipairs(BB_DataAbilities:GetChildren()) do
                local attrName = child:GetAttribute("Name")
                if child.Name == rawName or attrName == rawName or child.Name == displayName or attrName == displayName then
                    data = child
                    if not displayName then
                        displayName = attrName or child.Name
                    end
                    break
                end
            end
        end

        if data then
            if not displayName then
                displayName = data:GetAttribute("Name") or data.Name
            end
            icon = data:GetAttribute("Icon") or data:GetAttribute("Image") or data:GetAttribute("IconId")
            local icon1 = data:GetAttribute("Icon1")
            local upgrades = player:FindFirstChild("Upgrades")
            if upgrades then
                upgrades = upgrades:FindFirstChild(rawName) or upgrades:FindFirstChild(data.Name) or (displayName and upgrades:FindFirstChild(displayName))
            end
            upgrades = upgrades and upgrades.Value
            if upgrades and upgrades > 0 and icon1 and icon1 ~= "" then
                icon = icon1
            end
            if icon and type(icon) == "string" and icon:match("^%d+$") then
                icon = "rbxassetid://" .. icon
            end
        end
    end

    return displayName or rawName, icon
end

local function BB_RenderCombinedESP()
    local localRoot = BB_LocalPlayer.Character and BB_LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    for _, plr in ipairs(BB_Players:GetPlayers()) do
        if plr ~= BB_LocalPlayer then
            local char = plr.Character
            local head = char and (char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart"))

            local hl = char and char:FindFirstChild("BB_PlayerHL")
            if BB_Config.PlayerESP and char then
                if not hl then
                    hl = Instance.new("Highlight")
                    hl.Name = "BB_PlayerHL"
                    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    hl.FillTransparency = 0.5
                    hl.OutlineTransparency = 0
                    hl.Parent = char
                end
                if hl.OutlineColor ~= BB_Config.PlayerESPColor then hl.OutlineColor = BB_Config.PlayerESPColor end
                if hl.FillColor ~= BB_Config.PlayerESPColor then hl.FillColor = BB_Config.PlayerESPColor end
            elseif hl then
                hl:Destroy()
            end

            local showPlayer = BB_Config.PlayerESP
            local showAbility = BB_Config.AbilityESP
            local displayName, icon
            if showAbility and char then
                displayName, icon = BB_GetAbilityInfo(plr, char)
            end

            local abilityActive = (showAbility and displayName and displayName ~= "") and true or false
            local nameActive = (showPlayer and BB_Config.PlayerESPNames) and true or false
            local distActive = (showPlayer and BB_Config.PlayerESPDistance) and true or false

            if head and (abilityActive or nameActive or distActive) then
                local bb = BB_CombinedBillboards[plr]
                if not bb or not bb.Parent or bb.Adornee ~= head then
                    if bb then pcall(function() bb:Destroy() end) end
                    bb = Instance.new("BillboardGui")
                    bb.Name = "BB_CombinedBillboard"
                    bb.Size = UDim2.new(0, 200, 0, 200)
                    bb.StudsOffset = Vector3.new(0, 0, 0)
                    bb.AlwaysOnTop = true
                    bb.Parent = char
                    bb.Adornee = head

                    local mainFrame = Instance.new("Frame")
                    mainFrame.Name = "MainFrame"
                    mainFrame.BackgroundTransparency = 1
                    mainFrame.AnchorPoint = Vector2.new(0.5, 1)
                    mainFrame.Position = UDim2.new(0.5, 0, 0.5, -20)
                    mainFrame.Size = UDim2.new(0, 0, 0, 0)
                    mainFrame.AutomaticSize = Enum.AutomaticSize.XY
                    mainFrame.Parent = bb

                    local vLayout = Instance.new("UIListLayout")
                    vLayout.FillDirection = Enum.FillDirection.Vertical
                    vLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
                    vLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
                    vLayout.SortOrder = Enum.SortOrder.LayoutOrder
                    vLayout.Padding = UDim.new(0, 1)
                    vLayout.Parent = mainFrame

                    local abilityFrame = Instance.new("Frame")
                    abilityFrame.Name = "AbilityFrame"
                    abilityFrame.LayoutOrder = 1
                    abilityFrame.Size = UDim2.new(0, 0, 0, 22)
                    abilityFrame.AutomaticSize = Enum.AutomaticSize.X
                    abilityFrame.BackgroundTransparency = 1
                    abilityFrame.Parent = mainFrame

                    local hLayout = Instance.new("UIListLayout")
                    hLayout.FillDirection = Enum.FillDirection.Horizontal
                    hLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
                    hLayout.VerticalAlignment = Enum.VerticalAlignment.Center
                    hLayout.Padding = UDim.new(0, 4)
                    hLayout.Parent = abilityFrame

                    local img = Instance.new("ImageLabel")
                    img.Name = "AbilityImg"
                    img.LayoutOrder = 1
                    img.Size = UDim2.new(0, 22, 0, 22)
                    img.BackgroundTransparency = 1
                    img.Parent = abilityFrame

                    local abilityLbl = Instance.new("TextLabel")
                    abilityLbl.Name = "AbilityLbl"
                    abilityLbl.LayoutOrder = 2
                    abilityLbl.Size = UDim2.new(0, 0, 0, 20)
                    abilityLbl.AutomaticSize = Enum.AutomaticSize.X
                    abilityLbl.BackgroundTransparency = 1
                    abilityLbl.TextSize = 14
                    abilityLbl.Font = Enum.Font.GothamBold
                    abilityLbl.TextStrokeTransparency = 0
                    abilityLbl.Parent = abilityFrame

                    local nameLbl = Instance.new("TextLabel")
                    nameLbl.Name = "NameLbl"
                    nameLbl.LayoutOrder = 2
                    nameLbl.Size = UDim2.new(0, 0, 0, 20)
                    nameLbl.AutomaticSize = Enum.AutomaticSize.X
                    nameLbl.BackgroundTransparency = 1
                    nameLbl.TextSize = 14
                    nameLbl.Font = Enum.Font.GothamBold
                    nameLbl.TextStrokeTransparency = 0
                    nameLbl.Parent = mainFrame

                    local distLbl = Instance.new("TextLabel")
                    distLbl.Name = "DistLbl"
                    distLbl.LayoutOrder = 3
                    distLbl.Size = UDim2.new(0, 0, 0, 16)
                    distLbl.AutomaticSize = Enum.AutomaticSize.X
                    distLbl.BackgroundTransparency = 1
                    distLbl.TextSize = 12
                    distLbl.Font = Enum.Font.GothamMedium
                    distLbl.TextStrokeTransparency = 0
                    distLbl.Parent = mainFrame

                    BB_CombinedBillboards[plr] = bb
                end
                bb.Adornee = head
                bb.Enabled = true

                local mainFrame = bb:FindFirstChild("MainFrame")
                local abilityFrame = mainFrame and mainFrame:FindFirstChild("AbilityFrame")
                local nameLbl = mainFrame and mainFrame:FindFirstChild("NameLbl")
                local distLbl = mainFrame and mainFrame:FindFirstChild("DistLbl")

                if abilityFrame then
                    abilityFrame.Visible = abilityActive
                    if abilityActive then
                        local img = abilityFrame:FindFirstChild("AbilityImg")
                        local abilityLbl = abilityFrame:FindFirstChild("AbilityLbl")
                        if abilityLbl then
                            if abilityLbl.Text ~= displayName then abilityLbl.Text = displayName end
                            if abilityLbl.TextColor3 ~= BB_Config.AbilityESPColor then abilityLbl.TextColor3 = BB_Config.AbilityESPColor end
                        end
                        if img then
                            if icon and icon ~= "" then
                                if img.Image ~= icon then img.Image = icon end
                                if img.Size ~= UDim2.new(0, 22, 0, 22) then img.Size = UDim2.new(0, 22, 0, 22) end
                                if not img.Visible then img.Visible = true end
                            else
                                if img.Visible then img.Visible = false end
                            end
                        end
                    end
                end

                if nameLbl then
                    nameLbl.Visible = nameActive
                    if nameActive then
                        if nameLbl.Text ~= plr.DisplayName then nameLbl.Text = plr.DisplayName end
                        if nameLbl.TextColor3 ~= BB_Config.PlayerESPColor then nameLbl.TextColor3 = BB_Config.PlayerESPColor end
                    end
                end

                if distLbl then
                    distLbl.Visible = distActive
                    if distActive then
                        local dist = localRoot and math.floor((localRoot.Position - head.Position).Magnitude) or 0
                        local newText = dist .. "m"
                        if distLbl.Text ~= newText then distLbl.Text = newText end
                        if distLbl.TextColor3 ~= BB_Config.PlayerESPColor then distLbl.TextColor3 = BB_Config.PlayerESPColor end
                    end
                end
            else
                if BB_CombinedBillboards[plr] then
                    pcall(function() BB_CombinedBillboards[plr]:Destroy() end)
                    BB_CombinedBillboards[plr] = nil
                end
            end
        end
    end
end

BB_Players.PlayerAdded:Connect(function(plr)
    plr.CharacterAdded:Connect(function()
        if BB_CombinedBillboards[plr] then pcall(function() BB_CombinedBillboards[plr]:Destroy() end) BB_CombinedBillboards[plr] = nil end
    end)
end)

for _, plr in ipairs(BB_Players:GetPlayers()) do
    plr.CharacterAdded:Connect(function()
        if BB_CombinedBillboards[plr] then pcall(function() BB_CombinedBillboards[plr]:Destroy() end) BB_CombinedBillboards[plr] = nil end
    end)
end

local BB_LastESPUpdate = 0
BB_RunService.Heartbeat:Connect(function()
    local now = os.clock()
    if now - BB_LastESPUpdate >= 0.1 then
        BB_LastESPUpdate = now
        pcall(function()
            if BB_Config.PlayerESP or BB_Config.AbilityESP then
                BB_RenderCombinedESP()
            else
                if next(BB_CombinedBillboards) then
                    for plr, bb in pairs(BB_CombinedBillboards) do
                        if bb and bb.Parent then bb:Destroy() end
                    end
                    BB_CombinedBillboards = setmetatable({}, {__mode = "k"})
                end
                for _, plr in ipairs(BB_Players:GetPlayers()) do
                    if plr ~= BB_LocalPlayer then
                        local hl = plr.Character and plr.Character:FindFirstChild("BB_PlayerHL")
                        if hl then hl:Destroy() end
                    end
                end
            end
        end)
    end
end)

local BB_DefaultWS = 36
local BB_DefaultJP = 50
local BB_FlyBV, BB_FlyBG, BB_FlyConn

local function BB_GetHRP()
    local c = BB_LocalPlayer.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end
local function BB_GetHum()
    local c = BB_LocalPlayer.Character
    return c and c:FindFirstChildOfClass("Humanoid")
end

local function BB_ToggleFly(state)
    BB_Config.Fly = state
    local hrp = BB_GetHRP()
    local hum = BB_GetHum()
    if state then
        if not hrp or not hum then return end
        hum.PlatformStand = true
        BB_FlyBV = Instance.new("BodyVelocity")
        BB_FlyBV.MaxForce = Vector3.new(1e5, 1e5, 1e5)
        BB_FlyBV.Parent = hrp
        BB_FlyBG = Instance.new("BodyGyro")
        BB_FlyBG.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
        BB_FlyBG.P = 1e4
        BB_FlyBG.Parent = hrp
        BB_FlyConn = BB_RunService.Heartbeat:Connect(function()
            if not BB_Config.Fly or not BB_FlyBV or not BB_FlyBV.Parent then return end
            local move = Vector3.zero
            local cam = BB_Workspace.CurrentCamera
            if BB_UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + cam.CFrame.LookVector end
            if BB_UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move - cam.CFrame.LookVector end
            if BB_UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move - cam.CFrame.RightVector end
            if BB_UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + cam.CFrame.RightVector end
            if BB_UserInputService:IsKeyDown(Enum.KeyCode.Space) then move = move + Vector3.yAxis end
            if BB_UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then move = move - Vector3.yAxis end
            BB_FlyBV.Velocity = move.Magnitude > 0 and move.Unit * BB_Config.FlySpeed or Vector3.zero
            BB_FlyBG.CFrame = cam.CFrame
        end)
    else
        if BB_FlyConn then BB_FlyConn:Disconnect() BB_FlyConn = nil end
        if hrp then
            local bv = hrp:FindFirstChild("BodyVelocity")
            local bg = hrp:FindFirstChild("BodyGyro")
            if bv then bv:Destroy() end
            if bg then bg:Destroy() end
        end
        if hum then hum.PlatformStand = false end
    end
end

BB_RunService.Heartbeat:Connect(function()
    local hum = BB_GetHum()
    if not hum then return end
    if BB_Config.MovementMods then
        hum.WalkSpeed = BB_Config.WalkSpeed
        hum.JumpPower = BB_Config.JumpPower
        hum.UseJumpPower = true
    else
        hum.WalkSpeed = BB_DefaultWS
        hum.JumpPower = BB_DefaultJP
    end
end)

local BB_LastVisualUpdate = 0
BB_RunService.Heartbeat:Connect(function()
    local now = tick()
    if now - BB_LastVisualUpdate >= 0.5 then
        BB_LastVisualUpdate = now
        local char = BB_LocalPlayer.Character
        if not char then return end
        
        local head = char:FindFirstChild("Head")
        if head then
            local face = head:FindFirstChild("face")
            local mesh = head:FindFirstChild("BB_HeadlessMesh")
            if BB_Config.Headless then
                if head.Transparency ~= 1 then head.Transparency = 1 end
                if face then face:Destroy() end
                if not mesh then
                    mesh = Instance.new("SpecialMesh")
                    mesh.Name = "BB_HeadlessMesh"
                    mesh.MeshType = Enum.MeshType.FileMesh
                    mesh.MeshId = "rbxassetid://1095708"
                    mesh.Scale = Vector3.new(0.001, 0.001, 0.001)
                    mesh.Parent = head
                end
            else
                if head.Transparency ~= 0 then head.Transparency = 0 end
                if mesh then mesh:Destroy() end
            end
        end
        
        local rightLeg = char:FindFirstChild("Right Leg") or char:FindFirstChild("RightUpperLeg")
        if rightLeg then
            local mesh = rightLeg:FindFirstChild("BB_KorbloxMesh")
            if BB_Config.Korblox then
                if rightLeg.Color ~= Color3.fromRGB(64, 64, 64) then rightLeg.Color = Color3.fromRGB(64, 64, 64) end
                if not mesh then
                    mesh = Instance.new("SpecialMesh")
                    mesh.Name = "BB_KorbloxMesh"
                    mesh.MeshType = Enum.MeshType.FileMesh
                    mesh.MeshId = "rbxassetid://101851696"
                    mesh.Scale = Vector3.new(1.05, 1.05, 1.05)
                    mesh.Parent = rightLeg
                end
            else
                if rightLeg.Color ~= Color3.fromRGB(255, 255, 0) then rightLeg.Color = Color3.fromRGB(255, 255, 0) end
                if mesh then mesh:Destroy() end
            end
        end
    end
end)

local BB_Window = BB_Eazy:CreateWindow({
    Name = "Blade Ball Hub",
    SubTitle = "by AkiraDev | v" .. BB_Version,
    Size = UDim2.fromOffset(660, 560),
    MinimizeKey = Enum.KeyCode.RightShift,
    ConfigId = "BB_Hub_v2",
    AutoLoad = true,
    NotifyPosition = "BottomRight",
    LoadingTitle = "Blade Ball Hub",
    LoadingSubtitle = "Loading...",
    LoadingDuration = 1.2,
    Discord = { Enabled = true, Invite = "2ksQSAnnW6" },
})

local BB_Tabs = {
    Main = BB_Window:AddTab({ Title = "Main", Icon = "house" }),
    Curve = BB_Window:AddTab({ Title = "Curve", Icon = "wind" }),
    Visual = BB_Window:AddTab({ Title = "Visual", Icon = "eye" }),
    Player = BB_Window:AddTab({ Title = "Player", Icon = "user" }),
    Server = BB_Window:AddTab({ Title = "Server", Icon = "globe" }),
    Config = BB_Window:AddTab({ Title = "Config", Icon = "sliders" }),
    Credits = BB_Window:AddTab({ Title = "Credits", Icon = "info" }),
}

BB_Tabs.Main:AddSection({ Title = "welcome" })
BB_Tabs.Main:AddParagraph({ Title = "Blade Ball Hub", Content = "version: v" .. BB_Version .. "\ndeveloper: AkiraDev" })

BB_Tabs.Main:AddSection({ Title = "combat" })
BB_Tabs.Main:AddToggle({ Title = "Auto Parry", Description = "Parries the ball when it targets you", Flag = "BB_AutoParry", Default = true, Callback = function(v)
    BB_System.__properties.__autoparry_enabled = v
    BB_System.__properties.__play_animation = v
    if v then BB_AutoParry.start() else BB_AutoParry.stop() end
end })
BB_Tabs.Main:AddDropdown({ Title = "Parry Mode", Description = "Remote or Keypress", Values = {"Remote", "Keypress"}, Default = "Remote", Flag = "BB_ParryMode", Callback = function(v)
    getgenv().AutoParryMode = v
end })
BB_Tabs.Main:AddSlider({ Title = "Accuracy", Description = "Higher = parry earlier (50 = default)", Min = 1, Max = 100, Default = 50, Step = 1, Flag = "BB_Accuracy", Callback = function(v)
    BB_System.__properties.__accuracy = v
    BB_UpdateDivisor()
end })
BB_Tabs.Main:AddToggle({ Title = "Random Accuracy", Description = "Varies accuracy based on ping", Flag = "BB_RandomAcc", Default = false, Callback = function(v)
    BB_System.__properties.__randomized_accuracy_enabled = v
    if v then BB_UpdateRandomizedAccuracy() end
end })
BB_Tabs.Main:AddToggle({ Title = "Auto Spam", Description = "Retries parry when ball is close after a miss", Flag = "BB_AutoSpam", Default = true, Callback = function(v)
    if v then BB_AutoSpam.start() else BB_AutoSpam.stop() end
end })

BB_Tabs.Curve:AddSection({ Title = "parry curve" })
BB_Tabs.Curve:AddDropdown({ Title = "Curve Type", Description = "Camera = default", Values = BB_CurveNames, Default = "Camera", Flag = "BB_CurveType", Callback = function(v)
    BB_SelectedCurve = v
end })
BB_Tabs.Curve:AddToggle({ Title = "Random Curve", Description = "Randomizes curve each frame", Flag = "BB_RandomCurve", Default = false, Callback = function(v)
    if v then
        if not BB_System.__properties.__connections.__random_curve then
            BB_System.__properties.__connections.__random_curve = BB_RunService.PreSimulation:Connect(function()
                BB_SelectedCurve = BB_CurveNames[math.random(1, #BB_CurveNames)]
            end)
        end
    elseif BB_System.__properties.__connections.__random_curve then
        BB_System.__properties.__connections.__random_curve:Disconnect()
        BB_System.__properties.__connections.__random_curve = nil
        BB_SelectedCurve = "Camera"
    end
end })
BB_Tabs.Curve:AddToggle({ Title = "Legit Random Curve", Description = "Randomizes using legit curves only", Flag = "BB_LegitRandomCurve", Default = false, Callback = function(v)
    if v then
        if not BB_System.__properties.__connections.__legit_curve then
            BB_System.__properties.__connections.__legit_curve = BB_RunService.PreSimulation:Connect(function()
                BB_SelectedCurve = BB_LegitCurveNames[math.random(1, #BB_LegitCurveNames)]
            end)
        end
    elseif BB_System.__properties.__connections.__legit_curve then
        BB_System.__properties.__connections.__legit_curve:Disconnect()
        BB_System.__properties.__connections.__legit_curve = nil
        BB_SelectedCurve = "Camera"
    end
end })

BB_Tabs.Curve:AddSection({ Title = "detections" })
BB_Tabs.Curve:AddToggle({ Title = "Infinity Detection", Flag = "BB_DetInfinity", Default = false, Callback = function(v) BB_System.__config.__detections.__infinity = v end })
BB_Tabs.Curve:AddToggle({ Title = "Death Slash Detection", Flag = "BB_DetDeathSlash", Default = false, Callback = function(v) BB_System.__config.__detections.__deathslash = v end })
BB_Tabs.Curve:AddToggle({ Title = "Time Hole Detection", Flag = "BB_DetTimeHole", Default = false, Callback = function(v) BB_System.__config.__detections.__timehole = v end })
BB_Tabs.Curve:AddToggle({ Title = "Slashes Of Fury Detection", Flag = "BB_DetSlashesOfFury", Default = false, Callback = function(v) BB_System.__config.__detections.__slashesoffury = v end })

BB_Tabs.Visual:AddSection({ Title = "unlock all" })
BB_Tabs.Visual:AddToggle({ Title = "Unlock All Cosmetics", Description = "Unlocks skins and explosions", Flag = "BB_UnlockSkins", Default = false, Callback = function(v) BB_UnlockAllCosmetics(v) end })

BB_Tabs.Visual:AddSection({ Title = "player esp" })
BB_Tabs.Visual:AddToggle({ Title = "Player ESP", Flag = "BB_PlayerESP", Default = false, Callback = function(v) BB_Config.PlayerESP = v end })
BB_Tabs.Visual:AddToggle({ Title = "Show Names", Flag = "BB_ESPNames", Default = true, Callback = function(v) BB_Config.PlayerESPNames = v end })
BB_Tabs.Visual:AddToggle({ Title = "Show Distance", Flag = "BB_ESPDist", Default = true, Callback = function(v) BB_Config.PlayerESPDistance = v end })
BB_Tabs.Visual:AddColorPicker({ Title = "Player ESP Color", Default = Color3.fromRGB(216, 160, 255), Flag = "BB_ESPColor", Callback = function(c) BB_Config.PlayerESPColor = c end })

BB_Tabs.Visual:AddSection({ Title = "ability esp" })
BB_Tabs.Visual:AddToggle({ Title = "Ability ESP", Description = "Shows ability name", Flag = "BB_AbilityESP", Default = false, Callback = function(v) BB_Config.AbilityESP = v end })
BB_Tabs.Visual:AddColorPicker({ Title = "Ability ESP Color", Default = Color3.fromRGB(0, 255, 200), Flag = "BB_AbilityColor", Callback = function(c) BB_Config.AbilityESPColor = c end })

BB_Tabs.Visual:AddSection({ Title = "player visual" })
BB_Tabs.Visual:AddToggle({ Title = "Headless", Flag = "BB_Headless", Default = false, Callback = function(v) BB_Config.Headless = v end })
BB_Tabs.Visual:AddToggle({ Title = "Korblox", Flag = "BB_Korblox", Default = false, Callback = function(v) BB_Config.Korblox = v end })

BB_Tabs.Player:AddSection({ Title = "movement" })
BB_Tabs.Player:AddToggle({ Title = "Movement Modifiers", Flag = "BB_MoveMods", Default = false, Callback = function(v)
    BB_Config.MovementMods = v
    if not v then
        local hum = BB_GetHum()
        if hum then hum.WalkSpeed = BB_DefaultWS hum.JumpPower = BB_DefaultJP end
    end
end })
BB_Tabs.Player:AddSlider({ Title = "Walk Speed", Min = 16, Max = 120, Default = 36, Step = 1, Flag = "BB_WS", Callback = function(v) BB_Config.WalkSpeed = v end })
BB_Tabs.Player:AddSlider({ Title = "Jump Power", Min = 50, Max = 200, Default = 50, Step = 1, Flag = "BB_JP", Callback = function(v) BB_Config.JumpPower = v end })
BB_Tabs.Player:AddToggle({ Title = "Fly", Flag = "BB_Fly", Default = false, Callback = function(v) BB_ToggleFly(v) end })
BB_Tabs.Player:AddSlider({ Title = "Fly Speed", Min = 20, Max = 300, Default = 60, Step = 5, Flag = "BB_FlySpeed", Callback = function(v) BB_Config.FlySpeed = v end })

BB_Tabs.Server:AddSection({ Title = "server actions" })
BB_Tabs.Server:AddButton({ Title = "Rejoin Server", ButtonText = "Rejoin", Callback = function()
    pcall(function() BB_TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, BB_LocalPlayer) end)
end })
BB_Tabs.Server:AddButton({ Title = "Server Hop", ButtonText = "Hop", Callback = function()
    local ok, result = pcall(function()
        return BB_HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Desc&limit=100"))
    end)
    if not ok or not result or not result.data then return end
    for _, srv in ipairs(result.data) do
        if srv.playing < srv.maxPlayers and srv.id ~= game.JobId then
            BB_TeleportService:TeleportToPlaceInstance(game.PlaceId, srv.id, BB_LocalPlayer)
            return
        end
    end
    BB_Eazy:Notify({ Title = "Server", Content = "No servers found.", Style = "Warning", Duration = 3 })
end })

BB_Window:BuildConfigSection(BB_Tabs.Config)

BB_Tabs.Credits:AddSection({ Title = "about" })
BB_Tabs.Credits:AddParagraph({ Title = "Blade Ball Hub v" .. BB_Version, Content = "Auto Parry, ESP and automation for Blade Ball." })
BB_Tabs.Credits:AddParagraph({ Title = "Developer", Content = "AkiraDev — github.com/akiradv" })
BB_Tabs.Credits:AddParagraph({ Title = "Interface", Content = "Eazy UI " .. BB_UIVersion .. " by AkiraDev" })
BB_Tabs.Credits:AddParagraph({ Title = "Credits", Content = "Open source community." })

BB_System.__properties.__autoparry_enabled = true
BB_System.__properties.__play_animation = true
BB_AutoParry.start()
BB_AutoSpam.start()

BB_Eazy:Notify({ Title = "Blade Ball Hub", Content = "Loaded v" .. BB_Version, Style = "Success", Duration = 3 })