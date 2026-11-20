local IS_Eazy = loadstring(game:HttpGet("https://raw.githubusercontent.com/akiradv/eazyuilib/refs/heads/main/eazyui.lua"))()
local IS_Version = "1.0.0"
local IS_UIVersion = IS_Eazy.Version

local IS_Players = game:GetService("Players")
local IS_LocalPlayer = IS_Players.LocalPlayer
local IS_Workspace = game:GetService("Workspace")
local IS_RunService = game:GetService("RunService")
local IS_TeleportService = game:GetService("TeleportService")
local IS_ReplicatedStorage = game:GetService("ReplicatedStorage")
local IS_VirtualUser = game:GetService("VirtualUser")

if not game:IsLoaded() then game.Loaded:Wait() end

local IS_Env = _G
pcall(function()
    local g = getgenv()
    if type(g) == "table" then IS_Env = g end
end)

if type(IS_Env.IS_HubCleanup) == "function" then pcall(IS_Env.IS_HubCleanup) end

local IS_Shared = IS_Env.IS_HubShared
if type(IS_Shared) ~= "table" then
    IS_Shared = { Restores = {} }
    IS_Env.IS_HubShared = IS_Shared
end
if type(IS_Shared.Restores) ~= "table" then IS_Shared.Restores = {} end

local IS_CurveSchema = 2

local IS_Config = IS_Shared.Config
if type(IS_Config) ~= "table" then
    IS_Config = {
        InfStamina = false,
        AntiAFK = true,
        CurveAssist = false,
        CurveSide = "Right",
        CurveRandomSide = false,
        CurveRandomPower = false,
        AutoDribble = false,
    }
    IS_Shared.Config = IS_Config
end
if IS_Config.CurveSide ~= "Left" and IS_Config.CurveSide ~= "Right" then
    IS_Config.CurveSide = "Right"
end

local IS_Roll = IS_Shared.Roll
if type(IS_Roll) ~= "table" then
    IS_Roll = { active = false, sign = 1, scale = 1, streak = 0, lastSign = 0 }
    IS_Shared.Roll = IS_Roll
end

local IS_Tune = {
    Scan = 0.008,
    FireGap = 0.35,
    QualifyPadding = 5,
    ContactPadding = 1.2,
    CloseNow = 2,
    ScanRange = 44,
    InterceptSteps = 12,
    FireLead = 0.10,
    FireGrace = 0.06,
    RearAim = 0.55,
    RearBehind = 0.20,
    KickRange = 24,
    KickAim = 0.45,
    KickFlight = 0.40,
    KickRecordLife = 1.4,
    PowerFloor = 0.5,
    MaxStreak = 2,
    CooldownFloor = 0.02,
}

local IS_Running = true
local IS_Connections = {}
local IS_Window

local function IS_Track(connection)
    table.insert(IS_Connections, connection)
    return connection
end

local function IS_Notify(title, content, style, duration)
    task.defer(function()
        pcall(function()
            IS_Eazy:Notify({ Title = title, Content = content, Style = style or "Info", Duration = duration or 4 })
        end)
    end)
end

local function IS_Finite(n)
    return type(n) == "number" and n == n and math.abs(n) < math.huge
end

local function IS_Flat(v)
    return Vector3.new(v.X, 0, v.Z)
end

local function IS_Root(character): any
    return character and character:FindFirstChild("HumanoidRootPart")
end

local function IS_Humanoid(character): any
    return character and character:FindFirstChildOfClass("Humanoid")
end

local function IS_Require(obj)
    local done, ok, value = false, false, nil
    task.spawn(function()
        ok, value = pcall(require, obj)
        done = true
    end)
    local deadline = os.clock() + 8
    while not done and os.clock() < deadline do task.wait(0.02) end
    if done and ok then return value end
    return nil
end

local function IS_LoadModule(path)
    local obj = IS_ReplicatedStorage
    for name in string.gmatch(path, "[^%.]+") do
        obj = obj:WaitForChild(name, 5)
        if not obj then return nil end
    end
    local result = IS_Require(obj)
    if type(result) == "table" then return result end
    return nil
end

local IS_M: { [string]: any } = {}
local IS_ModulePaths = {
    ShootClient = "Client.Gameplay.Actions.Shoot",
    KickCore = "Modules.Actions.KickCore",
    CurvedKicks = "Modules.CurvedKicks",
    Sprint = "Client.Gameplay.Player.Sprint",
    Controls = "Modules.Gameplay.Controls",
    Dodge = "Client.Gameplay.Actions.Dodge",
    Match = "Modules.Gameplay.MatchSettings",
    Teams = "Client.Gameplay.ActorTeams",
    Actors = "Modules.Characters.Actors",
    Ragdoll = "Modules.Characters.Ragdoll",
    SlideTackle = "Modules.Actions.SlideTackle",
    Hitboxes = "Modules.Gameplay.HitboxSettings",
}

local IS_OldCore = IS_Shared.Modules and IS_Shared.Modules.KickCore
for name, path in pairs(IS_ModulePaths) do
    IS_M[name] = IS_LoadModule(path)
end
if IS_OldCore ~= IS_M.KickCore then
    IS_Shared.CurveHooked = false
    IS_Shared.CurveSchema = nil
end
IS_Shared.Modules = IS_M

local IS_Slide = {
    delay = 0, active = 0, total = 0,
    travel = 0, dashDistance = 0, dashSeconds = 0,
    reachMax = 0, ready = false,
}
local IS_BoxHalf = 0
local IS_Kick = { maxCharge = 0, ready = false }

local function IS_LoadSlide()
    local tackle = IS_M.SlideTackle
    if type(tackle) ~= "table" then return false end
    if type(tackle.GetSlidingUntil) ~= "function" then return false end
    if type(tackle.GetTravel) ~= "function" then return false end
    local constants = tackle.Constants
    if type(constants) ~= "table" then return false end
    local delay = constants.HitboxDelaySeconds
    local active = constants.HitboxSeconds
    local total = constants.TotalMotionSeconds
    local travel = constants.Distance
    local dashDistance = constants.StartupDashDistance
    local dashSeconds = constants.StartupDashSeconds
    if not (IS_Finite(delay) and IS_Finite(active) and IS_Finite(total)
        and IS_Finite(travel) and IS_Finite(dashDistance) and IS_Finite(dashSeconds)) then
        return false
    end
    if dashSeconds <= 0 or total <= dashSeconds or dashDistance <= 0 then return false end
    local box = IS_M.Hitboxes and IS_M.Hitboxes.SlideTackle
    if type(box) ~= "table" or typeof(box.Size) ~= "Vector3" then return false end
    IS_Slide.delay = delay
    IS_Slide.active = active
    IS_Slide.total = total
    IS_Slide.travel = travel
    IS_Slide.dashDistance = dashDistance
    IS_Slide.dashSeconds = dashSeconds
    local reachMax = constants.TargetReachMaximumStuds
    if IS_Finite(reachMax) and reachMax > 0 then
        IS_Slide.reachMax = reachMax
    end
    IS_BoxHalf = math.max(box.Size.X, box.Size.Z) * 0.5
    IS_Slide.ready = true
    return true
end

local function IS_LoadKick()
    local core = IS_M.KickCore
    if type(core) ~= "table" then return false end
    local constants = core.Constants
    if type(constants) ~= "table" then return false end
    local maximum = constants.MaximumChargeSeconds
    if not IS_Finite(maximum) or maximum <= 0 then return false end
    IS_Kick.maxCharge = maximum
    IS_Kick.ready = true
    return true
end

local function IS_Hook(object, key, build)
    if not (object and type(object[key]) == "function") then return false end
    local original = object[key]
    if type(hookfunction) == "function" then
        local callOriginal
        local wrapper = build(function(...) return callOriginal(...) end)
        local ok, restored = pcall(hookfunction, original, wrapper)
        if ok then
            callOriginal = restored
            return true
        end
    end
    local wrapper = build(original)
    local ok = pcall(function() object[key] = wrapper end)
    if ok and object[key] == wrapper then
        IS_Shared.Restores[#IS_Shared.Restores + 1] = function()
            if object[key] == wrapper then object[key] = original end
        end
        return true
    end
    return false
end

local function IS_LocalCharging()
    local client = IS_M.ShootClient
    if not (client and type(client.IsCharging) == "function") then return false end
    local ok, charging = pcall(client.IsCharging)
    if not (ok and charging == true) then return false end
    if type(client.IsForcedClearCharging) == "function" then
        local okClear, clearing = pcall(client.IsForcedClearCharging)
        if okClear and clearing == true then return false end
    end
    return true
end

local function IS_CurvePower()
    local curves = IS_M.CurvedKicks
    if type(curves) ~= "table" then return 0 end
    if type(curves.IsEnabled) == "function" then
        local ok, enabled = pcall(curves.IsEnabled)
        if ok and enabled ~= true then return 0 end
    end
    if type(curves.GetPower) ~= "function" then return 0 end
    local ok, value = pcall(curves.GetPower)
    if ok and IS_Finite(value) then return math.clamp(value, 0, 1) end
    return 0
end

local function IS_RollCurve()
    local sign
    if IS_Config.CurveRandomSide then
        sign = math.random(0, 1) == 1 and 1 or -1
        if IS_Roll.streak >= IS_Tune.MaxStreak and sign == IS_Roll.lastSign then
            sign = -sign
        end
    else
        sign = IS_Config.CurveSide == "Left" and -1 or 1
    end
    local scale = 1
    if IS_Config.CurveRandomPower then
        scale = IS_Tune.PowerFloor + math.random() * (1 - IS_Tune.PowerFloor)
    end
    IS_Roll.sign = sign
    IS_Roll.scale = scale
    IS_Roll.active = true
    IS_Roll.streak = sign == IS_Roll.lastSign and IS_Roll.streak + 1 or 1
    IS_Roll.lastSign = sign
end

local function IS_CurveTarget()
    if not IS_Config.CurveAssist then return nil end
    if not IS_LocalCharging() then
        IS_Roll.active = false
        return nil
    end
    local power = IS_CurvePower()
    if power <= 0 then return nil end
    if not IS_Roll.active then IS_RollCurve() end
    return IS_Roll.sign * IS_Roll.scale * power
end

local IS_CurveWatch = { charging = false }

local function IS_CurveTick()
    local charging = IS_LocalCharging()
    if charging ~= IS_CurveWatch.charging then
        IS_CurveWatch.charging = charging
        IS_Roll.active = false
    end
    if not charging then IS_Roll.active = false end
end

local function IS_InstallCurveHook()
    if IS_Shared.CurveHooked then
        return IS_Shared.CurveSchema == IS_CurveSchema
    end
    local core = IS_M.KickCore
    if not (core and type(core.LimitCurveChange) == "function") then return false end
    local ok = IS_Hook(core, "LimitCurveChange", function(callOriginal)
        return function(current, target, dt)
            if type(current) == "number" and type(target) == "number" then
                local resolve = IS_Shared.CurveResolve
                local desired = nil
                if type(resolve) == "function" then
                    local okResolve, value = pcall(resolve)
                    if okResolve then desired = value end
                end
                if desired then
                    return callOriginal(current, desired, dt)
                end
            end
            return callOriginal(current, target, dt)
        end
    end)
    if ok then
        IS_Shared.CurveHooked = true
        IS_Shared.CurveSchema = IS_CurveSchema
    end
    return ok
end

local IS_StaminaToken = 0

local function IS_SetStamina(on)
    local sprint = IS_M.Sprint
    if not (sprint and type(sprint.SetUnlimitedStamina) == "function") then return false end
    return pcall(sprint.SetUnlimitedStamina, "IS_Hub_InfStamina", on == true)
end

local function IS_ToggleInfStamina(enable)
    IS_Config.InfStamina = enable == true
    if not enable then
        IS_SetStamina(false)
        return true
    end
    if not IS_SetStamina(true) then
        IS_Config.InfStamina = false
        IS_Notify("Infinite Stamina", "Sprint module not found in this game build.", "Error", 6)
        return false
    end
    IS_StaminaToken += 1
    local token = IS_StaminaToken
    task.spawn(function()
        while IS_Running and IS_Config.InfStamina and token == IS_StaminaToken do
            IS_SetStamina(true)
            task.wait(1)
        end
    end)
    return true
end

local function IS_IsKeeper(character)
    local match = IS_M.Match
    if not (match and type(match.IsGoalkeeperCharacter) == "function") then return false end
    local ok, value = pcall(match.IsGoalkeeperCharacter, character)
    return ok and value == true
end

local function IS_IsRagdolled()
    local ragdoll = IS_M.Ragdoll
    if not (ragdoll and type(ragdoll.IsLocallyRagdolled) == "function") then return false end
    local ok, value = pcall(ragdoll.IsLocallyRagdolled, IS_LocalPlayer)
    return ok and value == true
end

local function IS_DodgeActive()
    local dodge = IS_M.Dodge
    if not (dodge and type(dodge.IsDribbling) == "function") then return false end
    local ok, value = pcall(dodge.IsDribbling)
    return ok and value == true
end

local function IS_SameTeam(actor)
    local teams = IS_M.Teams
    if not (teams and type(teams.GetActorTeamName) == "function") then return false end
    local okMine, mine = pcall(teams.GetActorTeamName, IS_LocalPlayer)
    local okTheirs, theirs = pcall(teams.GetActorTeamName, actor)
    return okMine and okTheirs and mine ~= nil and theirs == mine
end

local function IS_ResolveByUserId(userId)
    local actors = IS_M.Actors
    if actors and type(actors.GetByUserId) == "function" then
        local ok, actor = pcall(actors.GetByUserId, userId)
        if ok and actor then
            if type(actors.GetCharacter) == "function" then
                local okChar, character = pcall(actors.GetCharacter, actor)
                if okChar and character then return character end
            end
            local okField, character = pcall(function() return actor.Character end)
            if okField and character then return character end
        end
    end
    for _, player in ipairs(IS_Players:GetPlayers()) do
        if player.UserId == userId then return player.Character end
    end
    return nil
end

local function IS_Candidates()
    local list, seen = {}, {}
    local mine = IS_LocalPlayer.Character
    local function add(character, actor)
        if not character or seen[character] or character == mine then return end
        if not character:IsA("Model") then return end
        local root = IS_Root(character)
        local hum = IS_Humanoid(character)
        if root and hum and hum.Health > 0 then
            seen[character] = true
            list[#list + 1] = { root = root, character = character, actor = actor or character }
        end
    end
    for _, player in ipairs(IS_Players:GetPlayers()) do
        if player ~= IS_LocalPlayer then add(player.Character, player) end
    end
    local folder = IS_Workspace:FindFirstChild("Characters")
    if folder then
        for _, child in ipairs(folder:GetChildren()) do add(child, child) end
        local npcs = folder:FindFirstChild("NPCs")
        if npcs then
            for _, child in ipairs(npcs:GetChildren()) do add(child, child) end
        end
    end
    return list
end

local IS_Slides = {}
local IS_Kicks = {}
local IS_Dodge = { startedAt = 0, durations = {} }
local IS_Dribble = { nextScan = 0, lastFire = 0, firedKey = nil }
local IS_DribbleTick

local function IS_SlideAge(character)
    local ok, untilTime = pcall(IS_M.SlideTackle.GetSlidingUntil, character)
    if not (ok and IS_Finite(untilTime)) then return nil end
    return IS_Workspace:GetServerTimeNow() - (untilTime - IS_Slide.total)
end

local function IS_TravelAt(age)
    if age <= 0 then return 0 end
    local ok, value = pcall(IS_M.SlideTackle.GetTravel, age)
    if ok and IS_Finite(value) then return value end
    local dashSpeed = IS_Slide.dashDistance / IS_Slide.dashSeconds
    if age <= IS_Slide.dashSeconds then return dashSpeed * age end
    local rest = math.max(0, IS_Slide.travel - IS_Slide.dashDistance)
    local restTime = IS_Slide.total - IS_Slide.dashSeconds
    return IS_Slide.dashDistance + rest * math.clamp((age - IS_Slide.dashSeconds) / restTime, 0, 1)
end

local function IS_DodgeSpan()
    local list = IS_Dodge.durations
    if #list == 0 then return 0 end
    local shortest = math.huge
    for _, value in ipairs(list) do
        if value < shortest then shortest = value end
    end
    return shortest
end

local function IS_PacketDirection(...)
    for index = 1, select("#", ...) do
        local value = select(index, ...)
        if typeof(value) == "Vector3" and math.abs(value.Magnitude - 1) < 0.05 then
            local flat = IS_Flat(value)
            if flat.Magnitude > 0.01 then return flat.Unit end
        end
    end
    return nil
end

local function IS_PacketPassKind(...)
    local shot, other = false, false
    for index = 1, select("#", ...) do
        local value = select(index, ...)
        if type(value) == "string" then
            if value == "Shot" then
                shot = true
            elseif string.find(value, "Pass") or string.find(value, "Lob") or value == "Clear" then
                other = true
            end
        end
    end
    if shot then return "SHOT" end
    if other then return "OTHER" end
    return "UNKNOWN"
end

local function IS_ConnectAttackWatch()
    local remotes = IS_ReplicatedStorage:FindFirstChild("Remotes")
    local ball = remotes and remotes:FindFirstChild("Ball")
    if not ball then return end
    for _, child in ipairs(ball:GetChildren()) do
        local remote: any = child
        if remote.Name ~= "State" and (remote:IsA("RemoteEvent") or remote:IsA("UnreliableRemoteEvent")) then
            local ok, connection = pcall(function()
                return remote.OnClientEvent:Connect(function(kind, userId, ...)
                    if type(kind) ~= "string" then return end
                    if not IS_Finite(userId) or userId == IS_LocalPlayer.UserId then return end
                    if kind ~= "TackleStarted" and kind ~= "KickChargeStarted"
                        and kind ~= "KickChargeUpdated" and kind ~= "KickReleased"
                        and kind ~= "KickChargeCanceled" then
                        return
                    end
                    local character = IS_ResolveByUserId(userId)
                    if not character then return end
                    local now = IS_Workspace:GetServerTimeNow()

                    if kind == "TackleStarted" then
                        local started
                        for index = 1, select("#", ...) do
                            local value = select(index, ...)
                            if type(value) == "number" and math.abs(value - now) < 3 then
                                started = value
                                break
                            end
                        end
                        IS_Slides[character] = {
                            started = started or now,
                            seen = now,
                            direction = IS_PacketDirection(...),
                        }
                    elseif kind == "KickChargeCanceled" then
                        IS_Kicks[character] = nil
                    elseif kind == "KickReleased" then
                        local record = IS_Kicks[character]
                        if not record then
                            record = {}
                            IS_Kicks[character] = record
                        end
                        record.releasedAt = now
                        record.seen = now
                        local direction = IS_PacketDirection(...)
                        if direction then record.direction = direction end
                    else
                        if IS_PacketPassKind(...) == "OTHER" then
                            IS_Kicks[character] = nil
                            return
                        end
                        local record = IS_Kicks[character]
                        if not record then
                            record = {}
                            IS_Kicks[character] = record
                        end
                        record.seen = now
                        record.releasedAt = nil
                        local direction = IS_PacketDirection(...)
                        if direction then record.direction = direction end
                    end

                    if IS_DribbleTick then pcall(IS_DribbleTick, true) end
                end)
            end)
            if ok and connection then IS_Track(connection) end
        end
    end
end

local function IS_ConnectDodgeSignal()
    local ok, connection = pcall(function()
        return IS_M.Dodge.DribblingChanged.Event:Connect(function(active)
            if active == true then
                IS_Dodge.startedAt = os.clock()
            elseif IS_Dodge.startedAt > 0 then
                local span = os.clock() - IS_Dodge.startedAt
                if span > 0.05 and span < 2 then
                    table.insert(IS_Dodge.durations, span)
                    if #IS_Dodge.durations > 8 then table.remove(IS_Dodge.durations, 1) end
                end
                IS_Dodge.startedAt = 0
            end
        end)
    end)
    if ok and connection then IS_Track(connection) end
end

local function IS_KickThreat(hrp, entry, now)
    if not IS_Kick.ready then return nil end
    local record = IS_Kicks[entry.character]
    if not record or now - record.seen > IS_Tune.KickRecordLife then return nil end
    local root = entry.root
    local offset = IS_Flat(hrp.Position - root.Position)
    local distance = offset.Magnitude
    if distance > IS_Tune.KickRange or distance < 0.05 then return nil end
    local direction = record.direction
    if not direction then
        local look = IS_Flat(root.CFrame.LookVector)
        if look.Magnitude > 0.01 then direction = look.Unit end
    end
    if not direction then return nil end
    if direction:Dot(offset.Unit) < IS_Tune.KickAim then return nil end
    if record.releasedAt then
        if now - record.releasedAt > IS_Tune.KickFlight then return nil end
        return { root = root, kind = "KICK", fireAt = 0, score = 0 }
    end
    return { root = root, kind = "KICK", fireAt = 0, score = 0.02 }
end

local function IS_SlideThreat(hrp, entry, now, lead)
    local root, character = entry.root, entry.character
    local qualify = IS_BoxHalf + IS_Tune.QualifyPadding
    local contact = IS_BoxHalf + IS_Tune.ContactPadding
    local windowStart = IS_Slide.delay
    local windowEnd = IS_Slide.delay + IS_Slide.active
    local offset = IS_Flat(hrp.Position - root.Position)
    local distance = offset.Magnitude
    if distance > IS_Tune.ScanRange or distance < 0.05 then return nil end

    local age = IS_SlideAge(character)
    local direction
    local record = IS_Slides[character]
    if record and now - record.seen < 2.5 then
        local packetAge = now - record.started
        if not age or packetAge < age then age = packetAge end
        direction = record.direction
    end
    if not age or age < -0.06 or age > windowEnd + IS_Tune.FireGrace then return nil end
    if not direction then
        local look = IS_Flat(root.CFrame.LookVector)
        if look.Magnitude > 0.01 then direction = look.Unit end
    end
    if not direction then return nil end

    local myVelocity = IS_Flat(hrp.AssemblyLinearVelocity)
    local travelNow = IS_TravelAt(age)
    local from = math.max(age, windowStart)
    local contactAt, closestAt, closest = nil, nil, distance
    local steps = IS_Tune.InterceptSteps
    for index = 0, steps do
        local moment = from + (windowEnd - from) * (index / steps)
        if moment >= age then
            local advance = math.max(0, IS_TravelAt(moment) - travelNow)
            local theirPoint = IS_Flat(root.Position + direction * advance)
            local myPoint = IS_Flat(hrp.Position + myVelocity * (moment - age))
            local gap = (myPoint - theirPoint).Magnitude
            if gap < closest then
                closest, closestAt = gap, moment
            end
            if contactAt == nil and gap <= contact then
                contactAt = moment
            end
        end
    end

    local alreadyOnTop = distance <= contact + IS_Tune.CloseNow
    if distance <= contact then
        contactAt = math.max(age, windowStart)
        if closestAt == nil then closestAt = contactAt end
    end

    local target = contactAt
    if target == nil and closestAt ~= nil and closest <= qualify then
        target = closestAt
    end

    local rear = false
    if target == nil and IS_Slide.reachMax > 0 and distance <= IS_Slide.reachMax then
        local heading = myVelocity
        if heading.Magnitude < 2 then heading = IS_Flat(hrp.CFrame.LookVector) end
        if heading.Magnitude > 0.01 then
            local trailing = offset.Unit:Dot(heading.Unit)
            local aim = direction:Dot(offset.Unit)
            if trailing >= IS_Tune.RearBehind and aim >= IS_Tune.RearAim then
                target = math.max(age, windowStart)
                rear = true
            end
        end
    end

    if target == nil then return nil end
    if age > target + IS_Tune.FireGrace and not alreadyOnTop and not rear then return nil end

    local fireAt = math.max(0, target - lead)
    if alreadyOnTop or rear then fireAt = 0 end

    return { root = root, kind = "SLIDE", fireAt = fireAt, score = target }
end

local function IS_FindThreat(hrp)
    local now = IS_Workspace:GetServerTimeNow()
    local span = IS_DodgeSpan()
    local lead = IS_Tune.FireLead
    if span > 0 then lead = math.min(lead, span * 0.25) end
    local best = nil
    for _, entry in ipairs(IS_Candidates()) do
        if not IS_SameTeam(entry.actor) then
            local kick = IS_KickThreat(hrp, entry, now)
            if kick and (not best or kick.score < best.score) then best = kick end
            local slide = IS_SlideThreat(hrp, entry, now, lead)
            if slide and (not best or slide.score < best.score) then best = slide end
        end
    end
    return best
end

IS_DribbleTick = function(immediate)
    if not IS_Running or not IS_Config.AutoDribble or not IS_Slide.ready then return end
    local now = os.clock()
    if not immediate and now < IS_Dribble.nextScan then return end
    IS_Dribble.nextScan = now + IS_Tune.Scan

    local character = IS_LocalPlayer.Character
    local hum = IS_Humanoid(character)
    local hrp = IS_Root(character)
    if not (character and hum and hum.Health > 0 and hrp) then return end
    if IS_IsKeeper(character) then return end
    if IS_LocalCharging() then return end
    if IS_IsRagdolled() then return end
    if IS_DodgeActive() then return end

    local threat = IS_FindThreat(hrp)
    if not threat then
        IS_Dribble.firedKey = nil
        return
    end

    local controls = IS_M.Controls
    local okAvailable, available = pcall(controls.IsAvailable, "Dribble")
    if not (okAvailable and available == true) then return end
    if type(controls.GetCooldownRemaining) == "function" then
        local okRemaining, remaining = pcall(controls.GetCooldownRemaining, "Dribble")
        if okRemaining and IS_Finite(remaining) and remaining > IS_Tune.CooldownFloor then return end
    elseif type(controls.IsOnCooldown) == "function" then
        local okCooling, cooling = pcall(controls.IsOnCooldown, "Dribble")
        if okCooling and cooling == true then return end
    end

    if now < threat.fireAt then return end
    local key = tostring(threat.root) .. ":" .. threat.kind
    if IS_Dribble.firedKey == key then return end
    if now - IS_Dribble.lastFire < IS_Tune.FireGap then return end

    local okInput, input = pcall(controls.CreateInput, "Dribble")
    if not (okInput and input) then return end
    if type(input) == "table" and input.UserInputState == nil then
        pcall(function() input.UserInputState = Enum.UserInputState.Begin end)
    end

    IS_Dribble.firedKey = key
    IS_Dribble.lastFire = now
    pcall(IS_M.Dodge.HandleInputBegan, input, false)
end

local function IS_Unload()
    if not IS_Running then return end
    IS_Running = false
    IS_Config.AutoDribble = false
    IS_Config.CurveAssist = false
    IS_Roll.active = false
    IS_Shared.CurveResolve = nil
    IS_ToggleInfStamina(false)
    for _, connection in ipairs(IS_Connections) do
        pcall(function() connection:Disconnect() end)
    end
    IS_Connections = {}
    for _, restore in ipairs(IS_Shared.Restores) do pcall(restore) end
    IS_Shared.Restores = {}
    IS_Env.IS_HubCleanup = nil
    IS_Notify("Illegal Soccer Hub", "Unloaded.", "Success", 3)
    task.delay(0.4, function() pcall(function() IS_Window:Destroy() end) end)
end

IS_Shared.CurveResolve = IS_CurveTarget
IS_LoadSlide()
IS_LoadKick()
IS_InstallCurveHook()
if IS_Slide.ready then
    IS_ConnectAttackWatch()
    IS_ConnectDodgeSignal()
end

IS_Window = IS_Eazy:CreateWindow({
    Name = "Illegal Soccer Hub",
    SubTitle = "by AkiraDev",
    Size = UDim2.fromOffset(580, 460),
    MinimizeKey = Enum.KeyCode.RightShift,
    ConfigId = "IS_Hub_v3",
    AutoLoad = true,
    NotifyPosition = "BottomRight",
    LoadingTitle = "Illegal Soccer Hub",
    LoadingSubtitle = "Loading Illegal Soccer Hub...",
    LoadingDuration = 1.2,
    Discord = { Enabled = false },
})

if type(IS_Window) ~= "table" or type(IS_Window.AddTab) ~= "function" then
    IS_Notify("Illegal Soccer Hub", "UI failed to open.", "Error", 8)
    return
end

local IS_Tabs = {
    Main = IS_Window:AddTab({ Title = "Main", Icon = "house" }),
    Striker = IS_Window:AddTab({ Title = "Striker", Icon = "target" }),
    Server = IS_Window:AddTab({ Title = "Server", Icon = "globe" }),
    Settings = IS_Window:AddTab({ Title = "Settings", Icon = "settings" }),
    Credits = IS_Window:AddTab({ Title = "Credits", Icon = "info" }),
}

IS_Tabs.Main:AddSection({ Title = "about" })
IS_Tabs.Main:AddParagraph({
    Title = "Objective",
    Content = "Shooting, curve, dribble and stamina for Illegal Soccer, focused on quality of life without breaking the game experience.",
})
IS_Tabs.Main:AddParagraph({
    Title = "Local & Security",
    Content = "This script is 100% Open Source and runs locally on your executor. The code is open to ensure total transparency, security, and community trust.",
})

IS_Tabs.Main:AddSection({ Title = "information" })
IS_Tabs.Main:AddParagraph({
    Title = "Version Info",
    Content = "Script: v" .. IS_Version .. "\nUI Library: Eazy UI " .. tostring(IS_UIVersion) .. "\nDeveloper: AkiraDev\nGitHub: github.com/akiradv",
})

IS_Tabs.Main:AddSection({ Title = "community" })
IS_Tabs.Main:AddButton({
    Title = "Join Discord",
    Description = "Copy the invite link to join the server",
    ButtonText = "Copy Link",
    Callback = function()
        local invite = "https://discord.gg/9VE4PXFDSg"
        if setclipboard then
            setclipboard(invite)
            IS_Notify("Discord", "Invite link copied to clipboard!", "Success", 3)
        else
            IS_Notify("Discord", "Copy this link: " .. invite, "Info", 10)
        end
    end,
})

IS_Tabs.Main:AddSection({ Title = "utility" })
IS_Tabs.Main:AddToggle({
    Title = "Infinite Stamina",
    Description = "Unlimited sprint stamina",
    Flag = "IS_InfStamina",
    Default = IS_Config.InfStamina,
    Callback = function(state) IS_ToggleInfStamina(state) end,
})

IS_Tabs.Striker:AddSection({ Title = "shooting" })
IS_Tabs.Striker:AddToggle({
    Title = "Curved shots",
    Description = "Bends the ball at full strength when you shoot",
    Flag = "IS_CurveAssist",
    Default = IS_Config.CurveAssist,
    Callback = function(state)
        IS_Config.CurveAssist = state
        IS_Roll.active = false
        if state and not IS_InstallCurveHook() then
            IS_Config.CurveAssist = false
            if IS_Shared.CurveHooked then
                IS_Notify("Curved shots", "Rejoin once to refresh the curve hook.", "Error", 8)
            else
                IS_Notify("Curved shots", "Not available in this game build.", "Error", 6)
            end
        end
    end,
})
IS_Tabs.Striker:AddDropdown({
    Title = "Curve side",
    Description = "Which way the ball bends",
    Values = { "Right", "Left" },
    Default = IS_Config.CurveSide,
    Flag = "IS_CurveSide",
    Callback = function(value)
        IS_Config.CurveSide = value
        IS_Roll.active = false
    end,
})
IS_Tabs.Striker:AddToggle({
    Title = "Random side",
    Description = "Changes the curve side every shot",
    Flag = "IS_CurveRandomSide",
    Default = IS_Config.CurveRandomSide,
    Callback = function(state)
        IS_Config.CurveRandomSide = state
        IS_Roll.active = false
    end,
})
IS_Tabs.Striker:AddToggle({
    Title = "Random strength",
    Description = "Varies the bend between half and full strength",
    Flag = "IS_CurveRandomPower",
    Default = IS_Config.CurveRandomPower,
    Callback = function(state)
        IS_Config.CurveRandomPower = state
        IS_Roll.active = false
    end,
})

IS_Tabs.Striker:AddSection({ Title = "dribble" })
IS_Tabs.Striker:AddToggle({
    Title = "Auto Dribble",
    Description = "Dodges slide tackles and shots aimed at you",
    Flag = "IS_AutoDribble",
    Default = IS_Config.AutoDribble,
    Callback = function(state)
        if state and not IS_Slide.ready then
            IS_Config.AutoDribble = false
            IS_Notify("Auto Dribble", "Tackle module not found in this game build.", "Error", 6)
            return
        end
        IS_Config.AutoDribble = state
    end,
})
IS_Tabs.Striker:AddParagraph({
    Title = "Dribble cooldown",
    Content = "The game blocks Dribble for a few seconds after each use, so back to back threats can still land.",
})

IS_Tabs.Server:AddSection({ Title = "utility" })
IS_Tabs.Server:AddToggle({
    Title = "Anti-AFK",
    Description = "Prevents you from being kicked for being AFK",
    Flag = "IS_AntiAFK",
    Default = IS_Config.AntiAFK,
    Callback = function(state) IS_Config.AntiAFK = state end,
})

IS_Tabs.Server:AddSection({ Title = "server" })
IS_Tabs.Server:AddButton({
    Title = "Rejoin",
    Description = "Rejoins the same server you are in",
    ButtonText = "Rejoin",
    Callback = function()
        IS_Notify("Server", "Reconnecting to the same server...", "Info", 2)
        task.delay(0.5, function()
            pcall(function() IS_TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, IS_LocalPlayer) end)
        end)
    end,
})
IS_Tabs.Server:AddButton({
    Title = "Server Hop",
    Description = "Joins a different public server",
    ButtonText = "Join",
    Callback = function()
        IS_Notify("Server", "Joining another server...", "Info", 2)
        task.delay(0.5, function()
            pcall(function() IS_TeleportService:Teleport(game.PlaceId, IS_LocalPlayer) end)
        end)
    end,
})

IS_Tabs.Settings:AddSection({ Title = "misc" })
IS_Tabs.Settings:AddButton({
    Title = "Unload",
    Description = "Stops every feature and closes the hub",
    ButtonText = "Unload",
    Callback = IS_Unload,
})
IS_Window:BuildConfigSection(IS_Tabs.Settings)

IS_Tabs.Credits:AddSection({ Title = "credits" })
IS_Tabs.Credits:AddParagraph({
    Title = "Development",
    Content = "Developer: AkiraDev\nGitHub: github.com/akiradv\nDiscord: discord.gg/9VE4PXFDSg\n\nUI Library: Eazy UI " .. tostring(IS_UIVersion) .. " by AkiraDev",
})

IS_Track(IS_LocalPlayer.Idled:Connect(function()
    if not IS_Running or not IS_Config.AntiAFK then return end
    pcall(function()
        IS_VirtualUser:CaptureController()
        IS_VirtualUser:ClickButton2(Vector2.new())
    end)
end))

IS_Track(IS_RunService.Heartbeat:Connect(function()
    if not IS_Running then return end
    pcall(IS_CurveTick)
    pcall(IS_DribbleTick, false)
end))

IS_Env.IS_HubCleanup = IS_Unload
IS_Env.IS_Unload = IS_Unload

if IS_Shared.CurveHooked and IS_Shared.CurveSchema ~= IS_CurveSchema then
    IS_Notify("Illegal Soccer Hub", "Rejoin once to refresh the curve hook.", "Warning", 8)
end

IS_Notify("Illegal Soccer Hub", "v" .. IS_Version .. " loaded successfully", "Success", 3)