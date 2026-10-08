-- Muscle Legends Hub v1.0.3
-- Built with Eazy UI v0.9.35

local ML_EZ = loadstring(game:HttpGet("https://raw.githubusercontent.com/akiradv/eazyuilib/main/eazyui.lua"))()
local ML_Version = "1.0.3"
local ML_UIVersion = ML_EZ.Version

local ML_Players = game:GetService("Players")
local ML_ReplicatedStorage = game:GetService("ReplicatedStorage")
local ML_UserInputService = game:GetService("UserInputService")
local ML_VirtualUser = game:GetService("VirtualUser")
local ML_TeleportService = game:GetService("TeleportService")
local ML_HttpService = game:GetService("HttpService")
local ML_Lighting = game:GetService("Lighting")
local ML_LocalPlayer = ML_Players.LocalPlayer
local ML_rEvents = ML_ReplicatedStorage:WaitForChild("rEvents")

local ML_Options = {
    ML_Speed = { Value = 16 },
    ML_Jump = { Value = 50 },
    ML_AntiAFK = { Value = true },
}
local ML_WaterParts = {}
local ML_ServerHopVisited = {}
local ML_Whitelist = {}
local ML_TargetName = nil

local ML_Window = ML_EZ:CreateWindow({
    Name = "Muscle Legends Hub",
    SubTitle = "by AkiraDev",
    Size = UDim2.fromOffset(620, 540),
    MinimizeKey = Enum.KeyCode.RightShift,
    ConfigId = "MuscleLegends",
    AutoLoad = true,
    NotifyPosition = "BottomRight",
    LoadingTitle = "Muscle Legends Hub",
    LoadingSubtitle = "Loading modules...",
    LoadingDuration = 1.5,
})

local ML_Tabs = {
    Main = ML_Window:AddTab({ Title = "Main", Icon = "biceps-flexed" }),
    Combat = ML_Window:AddTab({ Title = "Combat", Icon = "skull" }),
    Teleport = ML_Window:AddTab({ Title = "Teleport", Icon = "tree-palm" }),
    Status = ML_Window:AddTab({ Title = "Status", Icon = "trending-up" }),
    Visual = ML_Window:AddTab({ Title = "Visual", Icon = "eye" }),
    Server = ML_Window:AddTab({ Title = "Server", Icon = "users" }),
    Misc = ML_Window:AddTab({ Title = "Misc", Icon = "command" }),
    Settings = ML_Window:AddTab({ Title = "Settings", Icon = "settings" }),
    Credits = ML_Window:AddTab({ Title = "Credits", Icon = "info" }),
}

local ML_EX_TOOLS = { "Weight", "Pushups", "Handstands", "Situps" }
local ML_TIME_ATTR = {
    Weight = "workoutTime",
    Pushups = "pushupTime",
    Situps = "situpTime",
    Handstands = "handstandTime",
}

local function ML_GetChar() return ML_LocalPlayer.Character end
local function ML_GetRoot()
    local c = ML_GetChar()
    return c and c:FindFirstChild("HumanoidRootPart")
end
local function ML_GetHumanoid()
    local c = ML_GetChar()
    return c and c:FindFirstChildOfClass("Humanoid")
end

local function ML_Fire(name, ...)
    local r = ML_rEvents:FindFirstChild(name)
    if not r then return false end
    local args = table.pack(...)
    return pcall(function()
        if r:IsA("RemoteFunction") then
            r:InvokeServer(table.unpack(args, 1, args.n))
        else
            r:FireServer(table.unpack(args, 1, args.n))
        end
    end)
end

local function ML_FindTool(name)
    local char = ML_GetChar()
    local bp = ML_LocalPlayer:FindFirstChild("Backpack")
    local candidates = { name }
    local singular = name:gsub("s$", "")
    if singular ~= name then table.insert(candidates, singular) end
    for _, n in ipairs(candidates) do
        if char and char:FindFirstChild(n) then return char:FindFirstChild(n) end
        if bp and bp:FindFirstChild(n) then return bp:FindFirstChild(n) end
    end
    return nil
end

local function ML_EquipToolByName(name)
    local char = ML_GetChar()
    local tool = ML_FindTool(name)
    if tool and tool.Parent ~= char then
        pcall(function() tool.Parent = char end)
        return true
    end
    return tool ~= nil
end

local function ML_UnequipToolByName(name)
    local char = ML_GetChar()
    local bp = ML_LocalPlayer:FindFirstChild("Backpack")
    if not char or not bp then return end
    local tool = char:FindFirstChild(name) or char:FindFirstChild(name:gsub("s$", ""))
    if tool then pcall(function() tool.Parent = bp end) end
end

local function ML_SendRep()
    local ev = ML_LocalPlayer:FindFirstChild("muscleEvent")
    if ev then pcall(function() ev:FireServer("rep") end) end
end

local function ML_SetPunchSpeed(value)
    local tool = ML_FindTool("Punch")
    if tool then
        local at = tool:FindFirstChild("attackTime")
        if at then pcall(function() at.Value = value end) end
    end
end

ML_LocalPlayer.Idled:Connect(function()
    if ML_Options.ML_AntiAFK and ML_Options.ML_AntiAFK.Value then
        pcall(function()
            ML_VirtualUser:CaptureController()
            ML_VirtualUser:ClickButton2(Vector2.new())
        end)
    end
end)

ML_LocalPlayer.CharacterAdded:Connect(function(char)
    char:WaitForChild("Humanoid")
    task.wait(0.3)
    if ML_Options.ML_Speed then char.Humanoid.WalkSpeed = ML_Options.ML_Speed.Value end
    if ML_Options.ML_Jump then
        char.Humanoid.UseJumpPower = true
        char.Humanoid.JumpPower = ML_Options.ML_Jump.Value
    end
    if ML_Options.ML_LockPos and ML_Options.ML_LockPos.Value then
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then hrp.Anchored = true end
    end
    if ML_Options.ML_GodMode and ML_Options.ML_GodMode.Value then
        task.spawn(function()
            task.wait(0.5)
            local root = ML_GetRoot()
            if root then root.CFrame = CFrame.new(4011, 26043, -2394) end
        end)
    end
    if ML_Options.ML_AutoTrain and ML_Options.ML_AutoTrain.Value then
        task.spawn(function()
            task.wait(1)
            for _, name in ipairs(ML_EX_TOOLS) do ML_EquipToolByName(name) end
        end)
    end
end)

-- ===== MAIN =====
ML_Tabs.Main:AddSection({ Title = "player" })

ML_Tabs.Main:AddSlider({
    Title = "Walk Speed",
    Description = "Changes your character walk speed",
    Min = 16, Max = 300, Default = 16, Step = 1,
    Flag = "ML_Speed",
    Callback = function(v)
        ML_Options.ML_Speed = { Value = v }
        local hum = ML_GetHumanoid()
        if hum then hum.WalkSpeed = v end
    end
})

ML_Tabs.Main:AddSlider({
    Title = "Jump Power",
    Description = "Changes how high you can jump",
    Min = 50, Max = 500, Default = 50, Step = 5,
    Flag = "ML_Jump",
    Callback = function(v)
        ML_Options.ML_Jump = { Value = v }
        local hum = ML_GetHumanoid()
        if hum then
            hum.UseJumpPower = true
            hum.JumpPower = v
        end
    end
})

ML_Tabs.Main:AddToggle({
    Title = "Infinite Jump",
    Description = "Lets you jump multiple times in the air",
    Flag = "ML_InfJump",
    Default = false,
    Callback = function(state) ML_Options.ML_InfJump = { Value = state } end
})

ML_UserInputService.JumpRequest:Connect(function()
    if ML_Options.ML_InfJump and ML_Options.ML_InfJump.Value then
        local hum = ML_GetHumanoid()
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

ML_Tabs.Main:AddToggle({
    Title = "No Clip",
    Description = "Walk through walls and objects",
    Flag = "ML_NoClip",
    Default = false,
    Callback = function(state)
        ML_Options.ML_NoClip = { Value = state }
        if state then
            task.spawn(function()
                while ML_Options.ML_NoClip and ML_Options.ML_NoClip.Value do
                    local char = ML_GetChar()
                    if char then
                        for _, part in pairs(char:GetDescendants()) do
                            if part:IsA("BasePart") and part.CanCollide then
                                part.CanCollide = false
                            end
                        end
                    end
                    task.wait(0.1)
                end
            end)
        end
    end
})

ML_Tabs.Main:AddSection({ Title = "auto train" })

ML_Tabs.Main:AddToggle({
    Title = "Auto Train",
    Description = "Automatically trains all exercises for you",
    Flag = "ML_AutoTrain",
    Default = false,
    Callback = function(state)
        ML_Options.ML_AutoTrain = { Value = state }
        if state then
            task.spawn(function()
                while ML_Options.ML_AutoTrain and ML_Options.ML_AutoTrain.Value do
                    ML_SendRep()
                    for _, name in ipairs(ML_EX_TOOLS) do
                        ML_EquipToolByName(name)
                        local tool = ML_FindTool(name)
                        local char = ML_GetChar()
                        if tool and char and tool.Parent == char then
                            local timeAttr = tool:FindFirstChild(ML_TIME_ATTR[name])
                            if timeAttr then pcall(function() timeAttr.Value = 0 end) end
                            pcall(function() tool:Activate() end)
                        end
                    end
                    local speed = ML_Options.ML_TrainSpeed and ML_Options.ML_TrainSpeed.Value or 20
                    task.wait(1 / speed)
                end
            end)
        else
            for _, name in ipairs(ML_EX_TOOLS) do ML_UnequipToolByName(name) end
        end
    end
})

ML_Tabs.Main:AddSlider({
    Title = "Train Speed",
    Description = "How many reps per second",
    Min = 5, Max = 100, Default = 20, Step = 5,
    Flag = "ML_TrainSpeed",
    Callback = function(v) ML_Options.ML_TrainSpeed = { Value = v } end
})

ML_Tabs.Main:AddToggle({
    Title = "Speed Grind",
    Description = "Maximum strength grinding with no delays",
    Flag = "ML_SpeedGrind",
    Default = false,
    Callback = function(state)
        ML_Options.ML_SpeedGrind = { Value = state }
        if state then
            for i = 1, 12 do
                task.spawn(function()
                    while ML_Options.ML_SpeedGrind and ML_Options.ML_SpeedGrind.Value do
                        ML_SendRep()
                        task.wait(0.083)
                    end
                end)
            end
        end
    end
})

ML_Tabs.Main:AddSection({ Title = "exercises" })

for _, name in ipairs(ML_EX_TOOLS) do
    local flag = "ML_Ex_" .. name
    ML_Tabs.Main:AddToggle({
        Title = "Auto " .. name,
        Description = "Automatically uses the " .. name:lower() .. " tool",
        Flag = flag,
        Default = false,
        Callback = function(state)
            ML_Options[flag] = { Value = state }
            if state then
                task.spawn(function()
                    while ML_Options[flag] and ML_Options[flag].Value do
                        ML_EquipToolByName(name)
                        local tool = ML_FindTool(name)
                        local char = ML_GetChar()
                        if tool and char and tool.Parent == char then
                            local attr = tool:FindFirstChild(ML_TIME_ATTR[name])
                            if attr then pcall(function() attr.Value = 0 end) end
                            pcall(function() tool:Activate() end)
                        end
                        task.wait(0.1)
                    end
                end)
            else
                ML_UnequipToolByName(name)
            end
        end
    })
end

ML_Tabs.Main:AddSection({ Title = "rewards" })

ML_Tabs.Main:AddToggle({
    Title = "Auto Collect Chests",
    Description = "Automatically collects chests around the map",
    Flag = "ML_AutoChest",
    Default = false,
    Callback = function(state)
        ML_Options.ML_AutoChest = { Value = state }
        if state then
            task.spawn(function()
                while ML_Options.ML_AutoChest and ML_Options.ML_AutoChest.Value do
                    local root = ML_GetRoot()
                    if root then
                        for _, d in ipairs(workspace:GetDescendants()) do
                            if not (ML_Options.ML_AutoChest and ML_Options.ML_AutoChest.Value) then break end
                            local n = d.Name:lower()
                            if d:IsA("BasePart") and (n:find("chest") or n:find("gem")) then
                                root.CFrame = d.CFrame * CFrame.new(0, 1, (d.Size.Z / 2) + 2)
                                task.wait(0.1)
                                ML_Fire("checkChestRemote", d.Name)
                            end
                        end
                    end
                    task.wait(1)
                end
            end)
        end
    end
})

ML_Tabs.Main:AddSection({ Title = "rebirth" })

ML_Tabs.Main:AddToggle({
    Title = "Auto Rebirth",
    Description = "Automatically rebirths when you're eligible",
    Flag = "ML_AutoRebirth",
    Default = false,
    Callback = function(state)
        ML_Options.ML_AutoRebirth = { Value = state }
        if state then
            task.spawn(function()
                while ML_Options.ML_AutoRebirth and ML_Options.ML_AutoRebirth.Value do
                    ML_Fire("rebirthRemote", "rebirthRequest")
                    task.wait(0.1)
                end
            end)
        end
    end
})

ML_Tabs.Main:AddButton({
    Title = "Rebirth Now",
    Description = "Forces a rebirth right now",
    ButtonText = "Rebirth",
    Callback = function()
        local r = ML_rEvents:FindFirstChild("rebirthRemote")
        if not r then
            ML_EZ:Notify({ Title = "Rebirth", Content = "rebirthRemote not found.", Style = "Error", Duration = 3 })
            return
        end
        local result = nil
        local ok = pcall(function()
            if r:IsA("RemoteFunction") then
                result = r:InvokeServer("rebirthRequest")
            else
                r:FireServer("rebirthRequest")
            end
        end)
        ML_EZ:Notify({
            Title = "Rebirth",
            Content = "ok=" .. tostring(ok) .. " return=" .. tostring(result),
            Style = ok and "Success" or "Error",
            Duration = 5
        })
    end
})

ML_Tabs.Main:AddToggle({
    Title = "Auto Size 2",
    Description = "Keeps your character size at 2",
    Flag = "ML_AutoSize2",
    Default = false,
    Callback = function(state)
        ML_Options.ML_AutoSize2 = { Value = state }
        if state then
            task.spawn(function()
                while ML_Options.ML_AutoSize2 and ML_Options.ML_AutoSize2.Value do
                    ML_Fire("changeSpeedSizeRemote", "changeSize", 2)
                    task.wait(0.1)
                end
            end)
        end
    end
})

-- ===== COMBAT =====
ML_Tabs.Combat:AddSection({ Title = "punch" })

ML_Tabs.Combat:AddButton({
    Title = "Fast Punch",
    Description = "Makes your punches much faster",
    ButtonText = "Apply",
    Callback = function()
        ML_EquipToolByName("Punch")
        ML_SetPunchSpeed(0.065)
        ML_EZ:Notify({ Title = "Punch", Content = "Fast punch applied.", Style = "Success", Duration = 2 })
    end
})

ML_Tabs.Combat:AddButton({
    Title = "Normal Punch",
    Description = "Restores your punch speed to normal",
    ButtonText = "Apply",
    Callback = function()
        ML_SetPunchSpeed(0.35)
        ML_EZ:Notify({ Title = "Punch", Content = "Normal punch restored.", Style = "Info", Duration = 2 })
    end
})

ML_Tabs.Combat:AddSection({ Title = "auto kill" })

ML_Tabs.Combat:AddToggle({
    Title = "Auto Punch (No Anim)",
    Description = "Punches without showing animation",
    Flag = "ML_AutoKillNoAnim",
    Default = false,
    Callback = function(state)
        ML_Options.ML_AutoKillNoAnim = { Value = state }
        if state then
            task.spawn(function()
                while ML_Options.ML_AutoKillNoAnim and ML_Options.ML_AutoKillNoAnim.Value do
                    ML_EquipToolByName("Punch")
                    ML_SetPunchSpeed(0.065)
                    local ev = ML_LocalPlayer:FindFirstChild("muscleEvent")
                    if ev then
                        pcall(function() ev:FireServer("punch", "rightHand") end)
                        pcall(function() ev:FireServer("punch", "leftHand") end)
                    end
                    task.wait()
                end
            end)
        else
            ML_UnequipToolByName("Punch")
        end
    end
})

ML_Tabs.Combat:AddToggle({
    Title = "Auto Kill Players",
    Description = "Automatically kills all players except whitelisted ones",
    Flag = "ML_AutoKill",
    Default = false,
    Callback = function(state)
        ML_Options.ML_AutoKill = { Value = state }
        if state then
            if not firetouchinterest then
                ML_EZ:Notify({ Title = "Combat", Content = "Your executor lacks firetouchinterest.", Style = "Error", Duration = 3 })
                return
            end
            task.spawn(function()
                while ML_Options.ML_AutoKill and ML_Options.ML_AutoKill.Value do
                    ML_EquipToolByName("Punch")
                    ML_SetPunchSpeed(0.065)
                    local char = ML_GetChar()
                    local rHand = char and char:FindFirstChild("RightHand")
                    local lHand = char and char:FindFirstChild("LeftHand")
                    if rHand and lHand then
                        for _, target in ipairs(ML_Players:GetPlayers()) do
                            if target ~= ML_LocalPlayer and not ML_Whitelist[target.Name] then
                                local root = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
                                if root then
                                    pcall(function()
                                        firetouchinterest(rHand, root, 1)
                                        firetouchinterest(lHand, root, 1)
                                        firetouchinterest(rHand, root, 0)
                                        firetouchinterest(lHand, root, 0)
                                    end)
                                end
                            end
                        end
                    end
                    task.wait(0.1)
                end
            end)
        else
            ML_UnequipToolByName("Punch")
        end
    end
})

ML_Tabs.Combat:AddInput({
    Title = "Whitelist Player",
    Placeholder = "username",
    Flag = "ML_WhitelistInput",
    Callback = function() end
})

ML_Tabs.Combat:AddButton({
    Title = "Add to Whitelist",
    Description = "Adds the player to your kill whitelist",
    ButtonText = "Add",
    Callback = function()
        local name = ML_Options.ML_WhitelistInput and ML_Options.ML_WhitelistInput.Value
        if name and name ~= "" then
            ML_Whitelist[name] = true
            ML_EZ:Notify({ Title = "Whitelist", Content = name .. " added.", Style = "Success", Duration = 2 })
        end
    end
})

ML_Tabs.Combat:AddButton({
    Title = "Remove from Whitelist",
    Description = "Removes the player from your kill whitelist",
    ButtonText = "Remove",
    Callback = function()
        local name = ML_Options.ML_WhitelistInput and ML_Options.ML_WhitelistInput.Value
        if name and name ~= "" then
            ML_Whitelist[name] = nil
            ML_EZ:Notify({ Title = "Whitelist", Content = name .. " removed.", Style = "Warning", Duration = 2 })
        end
    end
})

ML_Tabs.Combat:AddInput({
    Title = "Target Player",
    Placeholder = "exact username",
    Flag = "ML_TargetInput",
    Callback = function(v) ML_TargetName = v end
})

ML_Tabs.Combat:AddToggle({
    Title = "Kill Target Player",
    Description = "Focuses killing only the specified player",
    Flag = "ML_KillTarget",
    Default = false,
    Callback = function(state)
        ML_Options.ML_KillTarget = { Value = state }
        if state then
            if not firetouchinterest then
                ML_EZ:Notify({ Title = "Combat", Content = "Your executor lacks firetouchinterest.", Style = "Error", Duration = 3 })
                return
            end
            task.spawn(function()
                while ML_Options.ML_KillTarget and ML_Options.ML_KillTarget.Value do
                    ML_EquipToolByName("Punch")
                    ML_SetPunchSpeed(0.065)
                    local target = ML_TargetName and ML_Players:FindFirstChild(ML_TargetName)
                    local char = ML_GetChar()
                    local rHand = char and char:FindFirstChild("RightHand")
                    local lHand = char and char:FindFirstChild("LeftHand")
                    if target and target ~= ML_LocalPlayer and rHand and lHand then
                        local root = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
                        if root then
                            pcall(function()
                                firetouchinterest(rHand, root, 1)
                                firetouchinterest(lHand, root, 1)
                                firetouchinterest(rHand, root, 0)
                                firetouchinterest(lHand, root, 0)
                            end)
                        end
                    end
                    task.wait(0.1)
                end
            end)
        else
            ML_UnequipToolByName("Punch")
        end
    end
})

ML_Tabs.Combat:AddSection({ Title = "brawl" })

ML_Tabs.Combat:AddToggle({
    Title = "Auto Join Brawl",
    Description = "Automatically joins brawl matches",
    Flag = "ML_AutoBrawl",
    Default = false,
    Callback = function(state)
        ML_Options.ML_AutoBrawl = { Value = state }
        if state then
            task.spawn(function()
                while ML_Options.ML_AutoBrawl and ML_Options.ML_AutoBrawl.Value do
                    ML_Fire("brawlEvent", "joinBrawl")
                    task.wait(2)
                end
            end)
        end
    end
})

ML_Tabs.Combat:AddSection({ Title = "survival" })

ML_Tabs.Combat:AddToggle({
    Title = "God Mode",
    Description = "Makes you invincible in a safe location",
    Flag = "ML_GodMode",
    Default = false,
    Callback = function(state)
        ML_Options.ML_GodMode = { Value = state }
        if state then
            task.spawn(function()
                while ML_Options.ML_GodMode and ML_Options.ML_GodMode.Value do
                    local root = ML_GetRoot()
                    if root then
                        root.CFrame = CFrame.new(4011, 26043, -2394)
                        root.Velocity = Vector3.zero
                    end
                    task.wait(0.05)
                end
            end)
        end
    end
})

ML_Tabs.Combat:AddToggle({
    Title = "Anti Fling",
    Description = "Prevents you from being knocked back",
    Flag = "ML_AntiFling",
    Default = false,
    Callback = function(state)
        ML_Options.ML_AntiFling = { Value = state }
        local function apply(char)
            if not char then return end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            if state then
                if not hrp:FindFirstChild("AntiFling_BV") then
                    local bv = Instance.new("BodyVelocity")
                    bv.Name = "AntiFling_BV"
                    bv.MaxForce = Vector3.new(1e5, 0, 1e5)
                    bv.Velocity = Vector3.zero
                    bv.P = 1250
                    bv.Parent = hrp
                end
            else
                local ex = hrp:FindFirstChild("AntiFling_BV")
                if ex then ex:Destroy() end
            end
        end
        apply(ML_GetChar())
        ML_LocalPlayer.CharacterAdded:Connect(function(c)
            task.wait(0.5)
            if ML_Options.ML_AntiFling and ML_Options.ML_AntiFling.Value then apply(c) end
        end)
    end
})

ML_Tabs.Combat:AddToggle({
    Title = "Walk on Water",
    Description = "Lets you walk on water surfaces",
    Flag = "ML_Water",
    Default = false,
    Callback = function(state)
        ML_Options.ML_Water = { Value = state }
        if state and #ML_WaterParts == 0 then
            local pSize = 2048
            local basePos = Vector3.new(-2, -9.5, -2)
            for x = -5, 5 do
                for z = -5, 5 do
                    local p = Instance.new("Part")
                    p.Size = Vector3.new(pSize, 1, pSize)
                    p.Position = basePos + Vector3.new(x * pSize, 0, z * pSize)
                    p.Anchored = true
                    p.Transparency = 1
                    p.CanCollide = true
                    p.Parent = workspace
                    table.insert(ML_WaterParts, p)
                end
            end
        end
        for _, p in ipairs(ML_WaterParts) do
            if p and p.Parent then p.CanCollide = state end
        end
    end
})

ML_Tabs.Combat:AddButton({
    Title = "Fe Invisible",
    Description = "Makes your character invisible to others",
    ButtonText = "Go Invis",
    Callback = function()
        local root = ML_GetRoot()
        if not root then return end
        local save = root.CFrame
        root.CFrame = CFrame.new(915.095215, 37.5268936, 349.808533)
        task.wait(0.5)
        local char = ML_GetChar()
        local lt = char and char:FindFirstChild("LowerTorso")
        if lt then
            local rootAt = lt:FindFirstChild("Root")
            if rootAt then
                local clone = rootAt:Clone()
                rootAt:Destroy()
                clone.Parent = lt
            end
        end
        task.wait(0.5)
        local r2 = ML_GetRoot()
        if r2 then r2.CFrame = save end
        ML_EZ:Notify({ Title = "Invis", Content = "Applied.", Style = "Success", Duration = 2 })
    end
})

-- ===== TELEPORT =====
ML_Tabs.Teleport:AddSection({ Title = "all locations" })

local ML_Locations = {
    { "Starter Island", CFrame.new(226.252472, 13.1526947, 219.366516) },
    { "Tiny Island", CFrame.new(-31.8626194, 11.0588026, 2087.88672) },
    { "Beach", CFrame.new(-365.798309, 49.5082932, -501.618591) },
    { "Jungle Gym", CFrame.new(-8137, 33, 2820) },
    { "Jungle Bench", CFrame.new(-8629.88086, 69.8842468, 1855.03467) },
    { "Jungle Bar Lift", CFrame.new(-8678.05566, 19.5030098, 2089.25977) },
    { "Jungle Squat", CFrame.new(-8374.25586, 39.5933418, 2932.44995) },
    { "Frost Gym", CFrame.new(-2933.47998, 34.6399612, -579.946045) },
    { "Mythical Gym", CFrame.new(2659.50635, 26.6095238, 934.690613) },
    { "Eternal Gym", CFrame.new(-7176.19141, 50.394104, -1106.31421) },
    { "Legend Gym", CFrame.new(4446.91699, 1009.46698, -3983.76074) },
    { "Muscle King", CFrame.new(-8626, 20, -5730) },
    { "Brawl Aura 1", CFrame.new(985.910645, 168.795364, -7037.80615) },
    { "Brawl Aura 2", CFrame.new(4466.75342, 339.973602, -8425.74512) },
    { "Brawl Aura 3", CFrame.new(-1901.87695, 256.895432, -5899.64795) },
}

local ML_SelectedLocation = ML_Locations[1][2]
local ML_LocationNames = {}
for _, l in ipairs(ML_Locations) do table.insert(ML_LocationNames, l[1]) end

ML_Tabs.Teleport:AddDropdown({
    Title = "Location",
    Description = "Pick where to teleport",
    Values = ML_LocationNames,
    Default = ML_LocationNames[1],
    Flag = "ML_Location",
    Callback = function(v)
        for _, l in ipairs(ML_Locations) do
            if l[1] == v then ML_SelectedLocation = l[2] break end
        end
    end
})

ML_Tabs.Teleport:AddButton({
    Title = "Teleport",
    Description = "Teleports you to the selected location",
    ButtonText = "Go",
    Callback = function()
        local root = ML_GetRoot()
        if root and ML_SelectedLocation then
            root.CFrame = ML_SelectedLocation
            ML_EZ:Notify({ Title = "Teleport", Content = "Arrived.", Style = "Success", Duration = 2 })
        end
    end
})

ML_Tabs.Teleport:AddButton({
    Title = "Random Player",
    Description = "Teleports you to a random player",
    ButtonText = "Random",
    Callback = function()
        local others = {}
        for _, p in ipairs(ML_Players:GetPlayers()) do
            if p ~= ML_LocalPlayer and p.Character and p.Character:FindFirstChild("Head") then
                table.insert(others, p)
            end
        end
        if #others > 0 then
            local t = others[math.random(1, #others)]
            local root = ML_GetRoot()
            if root then root.CFrame = CFrame.new(t.Character.Head.Position) end
        end
    end
})

-- ===== STATUS =====
ML_Tabs.Status:AddSection({ Title = "session stats" })

local function ML_Abbrev(value)
    if value >= 1e15 then return string.format("%.1fQa", value / 1e15)
    elseif value >= 1e12 then return string.format("%.1fT", value / 1e12)
    elseif value >= 1e9 then return string.format("%.1fB", value / 1e9)
    elseif value >= 1e6 then return string.format("%.1fM", value / 1e6)
    elseif value >= 1e3 then return string.format("%.1fK", value / 1e3)
    else return tostring(value) end
end

local ML_StatusParas = {
    Time = ML_Tabs.Status:AddParagraph({ Title = "Time Spent", Content = "Time spent in this server: 00:00" }),
    Strength = ML_Tabs.Status:AddParagraph({ Title = "Strength", Content = "Strength gained: 0" }),
    Durability = ML_Tabs.Status:AddParagraph({ Title = "Durability", Content = "Durability gained: 0" }),
    Agility = ML_Tabs.Status:AddParagraph({ Title = "Agility", Content = "Agility gained: 0" }),
    Kills = ML_Tabs.Status:AddParagraph({ Title = "Kills", Content = "Kills gained: 0" }),
    Evil = ML_Tabs.Status:AddParagraph({ Title = "Evil Karma", Content = "Evil Karma gained: 0" }),
    Good = ML_Tabs.Status:AddParagraph({ Title = "Good Karma", Content = "Good Karma gained: 0" }),
}

task.spawn(function()
    pcall(function()
        local leaderstats = ML_LocalPlayer:WaitForChild("leaderstats", 15)
        local strengthStat = leaderstats:WaitForChild("Strength", 15)
        local killsStat = leaderstats:WaitForChild("Kills", 15)
        local durabilityStat = ML_LocalPlayer:WaitForChild("Durability", 15)
        local agilityStat = ML_LocalPlayer:WaitForChild("Agility", 15)
        local evilStat = ML_LocalPlayer:WaitForChild("evilKarma", 5)
        local goodStat = ML_LocalPlayer:WaitForChild("goodKarma", 5)

        local init = {
            strength = strengthStat.Value,
            durability = durabilityStat.Value,
            agility = agilityStat.Value,
            kills = killsStat.Value,
            evil = evilStat and evilStat.Value or 0,
            good = goodStat and goodStat.Value or 0,
        }
        local startTime = tick()

        local function update()
            ML_StatusParas.Strength:Set("Strength gained: " .. ML_Abbrev(strengthStat.Value - init.strength))
            ML_StatusParas.Durability:Set("Durability gained: " .. ML_Abbrev(durabilityStat.Value - init.durability))
            ML_StatusParas.Agility:Set("Agility gained: " .. ML_Abbrev(agilityStat.Value - init.agility))
            ML_StatusParas.Kills:Set("Kills gained: " .. ML_Abbrev(killsStat.Value - init.kills))
            if evilStat then ML_StatusParas.Evil:Set("Evil Karma gained: " .. ML_Abbrev(evilStat.Value - init.evil)) end
            if goodStat then ML_StatusParas.Good:Set("Good Karma gained: " .. ML_Abbrev(goodStat.Value - init.good)) end
        end

        strengthStat.Changed:Connect(update)
        durabilityStat.Changed:Connect(update)
        agilityStat.Changed:Connect(update)
        killsStat.Changed:Connect(update)
        if evilStat then evilStat.Changed:Connect(update) end
        if goodStat then goodStat.Changed:Connect(update) end

        while true do
            local spent = tick() - startTime
            local minutes = math.floor(spent / 60)
            local seconds = math.floor(spent % 60)
            ML_StatusParas.Time:Set(string.format("Time spent in this server: %02d:%02d", minutes, seconds))
            task.wait(1)
        end
    end)
end)

-- ===== VISUAL =====
ML_Tabs.Visual:AddSection({ Title = "performance" })

ML_Tabs.Visual:AddButton({
    Title = "Anti Lag",
    Description = "Removes particles and lights for better performance",
    ButtonText = "Apply",
    Callback = function()
        local count = 0
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("ParticleEmitter") then
                pcall(function() obj.Enabled = false end)
                count = count + 1
            elseif obj:IsA("PointLight") or obj:IsA("SpotLight") or obj:IsA("SurfaceLight") then
                pcall(function() obj.Enabled = false end)
            end
        end
        ML_Lighting.FogEnd = 100000
        ML_EZ:Notify({ Title = "Visual", Content = count .. " emitters removed.", Style = "Success", Duration = 2 })
    end
})

ML_Tabs.Visual:AddDropdown({
    Title = "Time of Day",
    Description = "Changes the time of day in the game",
    Values = { "Day", "Night", "Midnight" },
    Default = "Day",
    Flag = "ML_Time",
    Callback = function(v)
        if v == "Day" then ML_Lighting.ClockTime = 12
        elseif v == "Night" then ML_Lighting.ClockTime = 0
        elseif v == "Midnight" then ML_Lighting.ClockTime = 6 end
    end
})

-- ===== SERVER =====
ML_Tabs.Server:AddSection({ Title = "server" })

ML_Tabs.Server:AddButton({
    Title = "Rejoin Server",
    Description = "Rejoins the same server",
    ButtonText = "Rejoin",
    Callback = function()
        pcall(function() ML_TeleportService:Teleport(game.PlaceId, ML_LocalPlayer) end)
    end
})

ML_Tabs.Server:AddButton({
    Title = "Server Hop",
    Description = "Joins a different public server",
    ButtonText = "Hop",
    Callback = function()
        task.spawn(function()
            local ok, res = pcall(function()
                return game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100")
            end)
            if not ok then
                ML_EZ:Notify({ Title = "Hop", Content = "Failed to list servers.", Style = "Error", Duration = 2 })
                return
            end
            local data = ML_HttpService:JSONDecode(res)
            if data and data.data then
                for _, server in ipairs(data.data) do
                    if server.id ~= game.JobId and not ML_ServerHopVisited[server.id]
                        and server.playing < server.maxPlayers and not server.privateServer then
                        ML_ServerHopVisited[server.id] = true
                        pcall(function() ML_TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, ML_LocalPlayer) end)
                        return
                    end
                end
            end
            ML_EZ:Notify({ Title = "Hop", Content = "No new server found.", Style = "Warning", Duration = 2 })
        end)
    end
})

ML_Tabs.Server:AddButton({
    Title = "Copy Server Link",
    Description = "Copies the link for the server you are in",
    ButtonText = "Copy",
    Callback = function()
        local link = "https://www.roblox.com/games/" .. game.PlaceId .. "/?serverId=" .. game.JobId
        if setclipboard then
            setclipboard(link)
            ML_EZ:Notify({ Title = "Server", Content = "Link copied.", Style = "Success", Duration = 2 })
        end
    end
})

-- ===== MISC =====
ML_Tabs.Misc:AddSection({ Title = "utility" })

ML_Tabs.Misc:AddToggle({
    Title = "Anti AFK",
    Description = "Prevents you from being kicked for being AFK",
    Flag = "ML_AntiAFK",
    Default = true,
    Callback = function(state) ML_Options.ML_AntiAFK = { Value = state } end
})

ML_Tabs.Misc:AddToggle({
    Title = "Lock Position",
    Description = "Freezes your character in place",
    Flag = "ML_LockPos",
    Default = false,
    Callback = function(state)
        ML_Options.ML_LockPos = { Value = state }
        local hrp = ML_GetRoot()
        if hrp then hrp.Anchored = state end
    end
})

ML_Tabs.Misc:AddToggle({
    Title = "Hide Pets",
    Description = "Hides your equipped pets",
    Flag = "ML_HidePets",
    Default = false,
    Callback = function(state)
        ML_Options.ML_HidePets = { Value = state }
        ML_Fire("showPetsEvent", state and "hidePets" or "showPets")
    end
})

ML_Tabs.Misc:AddToggle({
    Title = "Disable Trade",
    Description = "Blocks incoming trade requests",
    Flag = "ML_DisableTrade",
    Default = false,
    Callback = function(state)
        ML_Options.ML_DisableTrade = { Value = state }
        ML_Fire("tradingEvent", state and "disableTrading" or "enableTrading")
    end
})

ML_Tabs.Misc:AddButton({
    Title = "Turn Small",
    Description = "Makes your character smaller",
    ButtonText = "Small",
    Callback = function()
        ML_Fire("changeSpeedSizeRemote", "changeSize", 1)
    end
})

-- ===== SETTINGS & CREDITS =====
ML_Window:BuildConfigSection(ML_Tabs.Settings)

ML_Tabs.Credits:AddSection({ Title = "about" })
ML_Tabs.Credits:AddParagraph({
    Title = "Objective",
    Content = "Provide a powerful, efficient hub for Muscle Legends, focused on automation and grinding without breaking the game experience."
})
ML_Tabs.Credits:AddParagraph({
    Title = "Local & Security",
    Content = "This script is 100% Open Source and runs locally on your executor. The code is open to ensure total transparency, security, and community trust."
})

ML_Tabs.Credits:AddSection({ Title = "information" })
ML_Tabs.Credits:AddParagraph({
    Title = "Version Info",
    Content = "Script: v" .. ML_Version .. "\nUI Library: Eazy UI " .. ML_UIVersion .. "\nDeveloper: AkiraDev\nGitHub: github.com/akiradv"
})

ML_Tabs.Credits:AddSection({ Title = "community" })
ML_Tabs.Credits:AddButton({
    Title = "Join Discord",
    Description = "Copy the invite link to join the server",
    ButtonText = "Copy Link",
    Callback = function()
        local inviteUrl = "https://discord.gg/9VE4PXFDSg"
        if setclipboard then
            setclipboard(inviteUrl)
            ML_EZ:Notify({ Title = "Discord", Content = "Invite link copied to clipboard!", Duration = 3, Style = "Success" })
        else
            ML_EZ:Notify({ Title = "Discord", Content = "Copy this link: " .. inviteUrl, Duration = 10, Style = "Info" })
        end
    end
})

ML_Tabs.Credits:AddSection({ Title = "credits" })
ML_Tabs.Credits:AddParagraph({
    Title = "Development",
    Content = "Developer: AkiraDev\nGitHub: github.com/akiradv\nDiscord: discord.gg/9VE4PXFDSg\n\nUI Library: Eazy UI " .. ML_UIVersion .. " by AkiraDev"
})

task.spawn(function()
    task.wait(1)
    ML_EZ:Notify({
        Title = "Muscle Legends Hub",
        Content = "v" .. ML_Version .. " loaded successfully",
        Style = "Success",
        Duration = 3
    })
end)