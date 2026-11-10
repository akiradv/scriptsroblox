local LT2_Eazy = loadstring(game:HttpGet("https://raw.githubusercontent.com/akiradv/eazyuilib/refs/heads/main/eazyui.lua"))()
local LT2_Version = "1.1.1"
local LT2_UIVersion = LT2_Eazy.Version

local LT2_Players = game:GetService("Players")
local LT2_LocalPlayer = LT2_Players.LocalPlayer
local LT2_Workspace = game:GetService("Workspace")
local LT2_ReplicatedStorage = game:GetService("ReplicatedStorage")
local LT2_RunService = game:GetService("RunService")
local LT2_UserInputService = game:GetService("UserInputService")
local LT2_Lighting = game:GetService("Lighting")

if not getsenv or not checkcaller or not hookmetamethod or not debug then
    pcall(function() LT2_Eazy:Notify({ Title = "LT2 Hub", Content = "Unsupported executor.", Style = "Error", Duration = 5 }) end)
    return
end

warn("[LT2 Hub] Starting v" .. LT2_Version)

local LT2_Flags = {
    WalkSpeed = 16, JumpPower = 50, Fly = false, FlySpeed = 60,
    Noclip = false, InfJump = false, AutoSell = false, AutoFarm = false,
    StopAutoFarm = false, ManualCutSession = false, TreeSelected = "Generic",
    ChopAmount = 1, DupeCooldown = false, IsCutting = false,
    Day = false, Night = false, NoFog = false, Shadows = true
}

local LT2_OldHooks = {}
local LT2_Connections = {}
local LT2_AutoFarmToggle
local LT2_AutoSellToggle

local function LT2_WaitRemote(parent, name, timeout)
    if not parent then return nil end
    local existing = parent:FindFirstChild(name)
    if existing then return existing end
    local deadline = tick() + (timeout or 10)
    while tick() < deadline do
        task.wait(0.1)
        local found = parent:FindFirstChild(name)
        if found then return found end
    end
    return nil
end

local function LT2_SafeFire(remote, ...)
    if remote == nil then return end
    pcall(remote.FireServer, remote, ...)
end

local function LT2_SafeInvoke(remote, ...)
    if remote == nil then return nil end
    local ok, result = pcall(remote.InvokeServer, remote, ...)
    if ok then return result end
    return nil
end

local function LT2_GetHRP()
    local c = LT2_LocalPlayer.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function LT2_GetHum()
    local c = LT2_LocalPlayer.Character
    return c and c:FindFirstChildOfClass("Humanoid")
end

local function LT2_Teleport(targetCFrame)
    local hrp = LT2_GetHRP()
    if not hrp then return false end
    hrp.CFrame = targetCFrame
    hrp.Velocity = Vector3.zero
    hrp.RotVelocity = Vector3.zero
    return true
end

local function LT2_Notify(title, content, style, duration)
    pcall(function()
        LT2_Eazy:Notify({
            Title = title, Content = content,
            Style = style or "Info", Duration = duration or 4,
        })
    end)
end

warn("[LT2 Hub] Loading remotes...")
local LT2_Interaction = LT2_WaitRemote(LT2_ReplicatedStorage, "Interaction", 3)
if not LT2_Interaction then
    warn("[LT2 Hub] Interaction folder not found!")
    LT2_Notify("LT2 Hub", "Interaction folder not found. Is this LT2?", "Error", 5)
    return
end

local LT2_ClientIsDragging = LT2_WaitRemote(LT2_Interaction, "ClientIsDragging", 1)
local LT2_ClientRequestOwnership = LT2_WaitRemote(LT2_Interaction, "ClientRequestOwnership", 1)
local LT2_RemoteProxy = LT2_WaitRemote(LT2_Interaction, "RemoteProxy", 1)
local LT2_PropertyPurchasing = LT2_WaitRemote(LT2_ReplicatedStorage, "PropertyPurchasing", 1)
local LT2_SetPropertyPurchasingValue = LT2_PropertyPurchasing and LT2_WaitRemote(LT2_PropertyPurchasing, "SetPropertyPurchasingValue", 1)
local LT2_ClientPurchasedProperty = LT2_PropertyPurchasing and LT2_WaitRemote(LT2_PropertyPurchasing, "ClientPurchasedProperty", 1)
local LT2_ClientExpandedProperty = LT2_PropertyPurchasing and LT2_WaitRemote(LT2_PropertyPurchasing, "ClientExpandedProperty", 1)

if not LT2_ClientIsDragging or not LT2_ClientRequestOwnership or not LT2_RemoteProxy then
    warn("[LT2 Hub] Missing remotes: ClientIsDragging=" .. tostring(LT2_ClientIsDragging ~= nil) ..
         ", ClientRequestOwnership=" .. tostring(LT2_ClientRequestOwnership ~= nil) ..
         ", RemoteProxy=" .. tostring(LT2_RemoteProxy ~= nil))
end

warn("[LT2 Hub] Remotes loaded. Building UI...")

local function LT2_IsOwned(model)
    local owner = model:FindFirstChild("Owner")
    if not owner then return false end
    if owner:IsA("ObjectValue") then return owner.Value == LT2_LocalPlayer end
    if owner:IsA("StringValue") then return owner.Value == LT2_LocalPlayer.Name end
    if owner:FindFirstChild("OwnerString") then return owner.OwnerString.Value == LT2_LocalPlayer.Name end
    return false
end

local function LT2_GetProperty()
    local properties = {}
    for _, v in pairs(LT2_Workspace.Properties:GetChildren()) do
        if v:FindFirstChild("Owner") and v.Owner.Value == nil then
            table.insert(properties, v)
        end
    end
    return properties[math.random(1, #properties)]
end

local function LT2_GetPlayerProperty()
    for _, v in pairs(LT2_Workspace.Properties:GetChildren()) do
        if v:FindFirstChild("Owner") and v.Owner.Value == LT2_LocalPlayer then
            return v
        end
    end
    return nil
end

local function LT2_FreeLand()
    if LT2_GetPlayerProperty() then
        LT2_Notify("Land", "You already have a piece of land!", "Warning", 3)
        return false
    end
    local property = LT2_GetProperty()
    if not property then return LT2_Notify("Land", "No free land found.", "Warning", 3) end
    
    LT2_SafeInvoke(LT2_SetPropertyPurchasingValue, true)
    LT2_SafeFire(LT2_ClientPurchasedProperty, property, property.OriginSquare.Position)
    LT2_SafeInvoke(LT2_SetPropertyPurchasingValue, false)
    LT2_Teleport(property.OriginSquare.CFrame)
    LT2_Notify("Land", "Free land acquired.", "Success", 3)
    return true
end

local function LT2_ExpandLand()
    local property = LT2_GetPlayerProperty()
    if not property then
        LT2_Notify("Land", "You need to own a land first!", "Warning", 3)
        return
    end
    
    local originSquare = property:FindFirstChild("OriginSquare")
    if not originSquare then
        LT2_Notify("Land", "OriginSquare not found.", "Error", 3)
        return
    end

    if not LT2_ClientExpandedProperty then
        LT2_Notify("Land", "Expansion remote not found.", "Error", 3)
        return
    end

    local spos = originSquare.Position
    local offsets = {
        {40, 0}, {-40, 0}, {0, 40}, {0, -40},
        {40, 40}, {40, -40}, {-40, 40}, {-40, -40},
        {80, 0}, {-80, 0}, {0, 80}, {0, -80},
        {80, 80}, {80, -80}, {-80, 80}, {-80, -80},
        {40, 80}, {-40, 80}, {80, 40}, {80, -40},
        {-80, 40}, {-80, -40}, {40, -80}, {-40, -80}
    }

    for _, offset in ipairs(offsets) do
        local targetCFrame = CFrame.new(spos.X + offset[1], spos.Y, spos.Z + offset[2])
        pcall(function()
            LT2_ClientExpandedProperty:FireServer(property, targetCFrame)
        end)
        task.wait(0.05)
    end
    
    LT2_Notify("Land", "Max Land executed.", "Success", 3)
end

local function LT2_GetTools()
    if not LT2_LocalPlayer.Character then return {} end
    LT2_LocalPlayer.Character.Humanoid:UnequipTools()
    local t = {}
    for _, v in pairs(LT2_LocalPlayer.Backpack:GetChildren()) do
        if v.Name ~= "BlueprintTool" then table.insert(t, v) end
    end
    return t
end

local function LT2_InstantSell(isAuto)
    local totalCount = 0
    local sellPos = Vector3.new(314.54, -0.5, 86.823)
    local oldCFrame = LT2_GetHRP().CFrame
    local emptyAttempts = 0
    local totalAttempts = 0

    while emptyAttempts < 3 and totalAttempts < 30 do
        totalAttempts = totalAttempts + 1
        if isAuto and LT2_Flags.StopAutoFarm then break end
        
        local targets = {}
        local logModels = LT2_Workspace:FindFirstChild("LogModels")
        local playerModels = LT2_Workspace:FindFirstChild("PlayerModels")

        if logModels then
            for _, model in ipairs(logModels:GetChildren()) do
                if model:IsA("Model") and LT2_IsOwned(model) then
                    table.insert(targets, model)
                end
            end
        end
        if playerModels then
            for _, model in ipairs(playerModels:GetChildren()) do
                if model:IsA("Model") and LT2_IsOwned(model) then
                    if model:FindFirstChild("WoodSection") or model:FindFirstChild("TreeClass") then
                        table.insert(targets, model)
                    end
                end
            end
        end

        if #targets == 0 then
            emptyAttempts = emptyAttempts + 1
            task.wait(1)
        else
            emptyAttempts = 0
            for _, model in ipairs(targets) do
                if isAuto and LT2_Flags.StopAutoFarm then break end
                totalCount = totalCount + 1
                
                local sections = {}
                for _, part in ipairs(model:GetDescendants()) do
                    if part:IsA("BasePart") and part.Name == "WoodSection" then
                        table.insert(sections, part)
                    end
                end

                for _, section in ipairs(sections) do
                    if isAuto and LT2_Flags.StopAutoFarm then break end
                    if not section.Parent then 
                        continue 
                    end

                    local root = LT2_GetHRP()
                    if root and (root.Position - section.Position).Magnitude > 10 then
                        root.CFrame = CFrame.new(section.Position + Vector3.new(0, 3, 0))
                        task.wait(0.05)
                    end

                    for _, desc in ipairs(model:GetDescendants()) do
                        if desc:IsA("Weld") or desc:IsA("WeldConstraint") or desc:IsA("ManualWeld") then
                            if desc.Part0 == section or desc.Part1 == section then
                                pcall(function() desc:Destroy() end)
                            end
                        end
                    end

                    for i = 1, 3 do
                        LT2_SafeFire(LT2_ClientIsDragging, model)
                        LT2_SafeFire(LT2_ClientRequestOwnership, section)
                        task.wait(0.01)
                    end

                    if not (isAuto and LT2_Flags.StopAutoFarm) then
                        local spin = CFrame.Angles(math.rad(math.random(0, 360)), math.rad(math.random(0, 360)), math.rad(math.random(0, 360)))
                        section.CFrame = CFrame.new(sellPos.X, sellPos.Y, sellPos.Z) * spin
                        section.Velocity = Vector3.zero
                    end
                end
            end
            task.wait(0.5)
        end
    end
    
    if LT2_GetHRP() and oldCFrame then
        LT2_Teleport(oldCFrame)
    end
    return totalCount
end

local function LT2_SplitWood()
    local hrp = LT2_GetHRP()
    if not hrp then return end
    local oldCFrame = hrp.CFrame
    local totalCount = 0

    local function processModel(model)
        local highestPart = nil
        for _, part in ipairs(model:GetDescendants()) do
            if part:IsA("BasePart") and part.Name == "WoodSection" then
                if not highestPart or part.Position.Y > highestPart.Position.Y then
                    highestPart = part
                end
            end
        end
        
        if highestPart then
            totalCount = totalCount + 1
            local root = LT2_GetHRP()
            if root then
                root.CFrame = CFrame.new(highestPart.Position.X, root.Position.Y, highestPart.Position.Z)
            end
            task.wait(0.05)

            for _, desc in ipairs(model:GetDescendants()) do
                if desc:IsA("Weld") or desc:IsA("WeldConstraint") or desc:IsA("ManualWeld") or desc:IsA("JointInstance") then
                    pcall(function() desc:Destroy() end)
                end
            end

            for j = 1, 3 do
                LT2_SafeFire(LT2_ClientIsDragging, model)
                task.wait(0.01)
            end

            for _, part in ipairs(model:GetDescendants()) do
                if part:IsA("BasePart") and part.Name == "WoodSection" then
                    part.Anchored = false
                    local offset = Vector3.new(math.random(-8, 8), 2, math.random(-8, 8))
                    part.CFrame = oldCFrame * CFrame.new(offset)
                    part.Velocity = Vector3.zero
                end
            end
        end
    end

    local logModels = LT2_Workspace:FindFirstChild("LogModels")
    if logModels then
        for _, model in ipairs(logModels:GetChildren()) do
            if model:IsA("Model") and LT2_IsOwned(model) then
                processModel(model)
            end
        end
    end
    
    local playerModels = LT2_Workspace:FindFirstChild("PlayerModels")
    if playerModels then
        for _, model in ipairs(playerModels:GetChildren()) do
            if model:IsA("Model") and LT2_IsOwned(model) then
                if model:FindFirstChild("WoodSection") then
                    processModel(model)
                end
            end
        end
    end
    
    LT2_Teleport(oldCFrame)
    LT2_Notify("Wood", "Split " .. totalCount .. " models.", "Success", 3)
end

local function LT2_BringAllLogs()
    local hrp = LT2_GetHRP()
    if not hrp then return end
    local oldCFrame = hrp.CFrame
    local count = 0
    local logModels = LT2_Workspace:FindFirstChild("LogModels")
    if logModels then
        for _, model in ipairs(logModels:GetChildren()) do
            if model:IsA("Model") and LT2_IsOwned(model) then
                local highestPart = nil
                for _, desc in ipairs(model:GetDescendants()) do
                    if desc.Name == "WoodSection" then
                        if not highestPart or desc.Position.Y > highestPart.Position.Y then
                            highestPart = desc
                        end
                    end
                end
                
                if highestPart then
                    if not model.PrimaryPart then model.PrimaryPart = highestPart end
                    local targetPos = Vector3.new(highestPart.Position.X, hrp.Position.Y, highestPart.Position.Z)
                    hrp.CFrame = CFrame.new(targetPos)
                    task.wait(0.05)
                    for i = 1, 5 do
                        LT2_SafeFire(LT2_ClientRequestOwnership, model)
                        LT2_SafeFire(LT2_ClientIsDragging, model)
                        if model.PrimaryPart then model:SetPrimaryPartCFrame(oldCFrame * CFrame.new(0, 0, -5)) end
                        task.wait(0.02)
                    end
                    count = count + 1
                end
            end
        end
    end
    LT2_Teleport(oldCFrame)
    LT2_Notify("Wood", "Brought " .. count .. " logs.", "Success", 3)
end

local LT2_AutoSellRunning = false
local function LT2_StartAutoSell()
    if LT2_AutoSellRunning then return end
    LT2_AutoSellRunning = true
    task.spawn(function()
        while LT2_Flags.AutoSell do
            if not LT2_Flags.IsCutting and not LT2_Flags.ManualCutSession then
                pcall(LT2_InstantSell, true)
            end
            task.wait(2)
        end
        LT2_AutoSellRunning = false
    end)
end

local LT2_GetToolStats = function(toolName)
    if typeof(toolName) ~= "string" then toolName = toolName.ToolName.Value end
    return require(LT2_ReplicatedStorage.AxeClasses['AxeClass_' .. toolName]).new()
end

local LT2_GetBestAxe = function(treeClass)
    local tools = LT2_GetTools()
    if #tools == 0 then return false, "No tools found in backpack." end
    local toolStats = {}
    local bestTool
    for _, v in pairs(tools) do
        if treeClass == "LoneCave" and v.ToolName.Value == "EndTimesAxe" then
            bestTool = v
            break
        end
        local axeStats = LT2_GetToolStats(v)
        if axeStats.SpecialTrees and axeStats.SpecialTrees[treeClass] then
            for i, val in pairs(axeStats.SpecialTrees[treeClass]) do axeStats[i] = val end
        end
        table.insert(toolStats, { tool = v, damage = axeStats.Damage })
    end
    if not bestTool and treeClass == "LoneCave" then return false, "You need an End Times Axe." end
    table.sort(toolStats, function(a, b) return a.damage > b.damage end)
    return true, bestTool or toolStats[1].tool
end

local LT2_KnownTrees = {"Generic","GoldSwampy","CaveCrawler","Cherry","Frost","Volcano","Oak","Walnut","Birch","SnowGlow","Pine","GreenSwampy","Koa","Palm","Spooky","SpookyNeon","LoneCave"}

local LT2_TreeClasses = {}
local LT2_TreeRegions = {}

for _, v in pairs(LT2_Workspace:GetChildren()) do
    if v.Name == "TreeRegion" then
        LT2_TreeRegions[v] = {}
        for _, v2 in pairs(v:GetChildren()) do
            if v2:FindFirstChild("TreeClass") then
                local tc = v2.TreeClass.Value
                if not table.find(LT2_TreeClasses, tc) then
                    table.insert(LT2_TreeClasses, tc)
                end
                if not table.find(LT2_TreeRegions[v], tc) then
                    table.insert(LT2_TreeRegions[v], tc)
                end
            end
        end
    end
end
for _, tree in ipairs(LT2_KnownTrees) do
    if not table.find(LT2_TreeClasses, tree) then
        table.insert(LT2_TreeClasses, tree)
    end
end
table.sort(LT2_TreeClasses, function(a, b)
    if a == "Generic" then return true end
    if b == "Generic" then return false end
    return a < b
end)

local LT2_GetBiggestTree = function(treeClass)
    local trees = {}
    for i, v in pairs(LT2_TreeRegions) do
        if table.find(v, treeClass) then
            for _, v2 in pairs(i:GetChildren()) do
                if v2:IsA("Model") and v2:FindFirstChild("Owner") then
                    if v2:FindFirstChild("TreeClass") and v2.TreeClass.Value == treeClass and (v2.Owner.Value == nil or v2.Owner.Value == LT2_LocalPlayer) then
                        local totalMass = 0
                        local treeTrunk
                        for _, v3 in pairs(v2:GetChildren()) do
                            if v3:IsA("BasePart") then
                                if v3:FindFirstChild("ID") and v3.ID.Value == 1 then treeTrunk = v3 end
                                totalMass = totalMass + v3:GetMass()
                            end
                        end
                        if treeTrunk and treeTrunk.Size.X >= 1 and treeTrunk.Size.Y >= 2 and treeTrunk.Size.Z >= 1 then
                            table.insert(trees, { tree = v2, trunk = treeTrunk, mass = totalMass })
                        end
                    end
                end
            end
        end
    end
    table.sort(trees, function(a, b) return a.mass > b.mass end)
    return trees[1]
end

local function LT2_CutTree(treeClass, isAuto)
    LT2_Flags.IsCutting = true
    
    local success, axeTool = LT2_GetBestAxe(treeClass)
    if not success then 
        LT2_Flags.IsCutting = false
        return false, axeTool
    end
    
    local treeInfo = LT2_GetBiggestTree(treeClass)
    if not treeInfo then 
        LT2_Flags.IsCutting = false
        return false, "No valid " .. treeClass .. " tree found."
    end
    
    local targetTree = treeInfo.tree
    local hrp = LT2_GetHRP()
    local oldCFrame = hrp.CFrame
    local axeStats = LT2_GetToolStats(axeTool)
    local damage = axeStats.Damage
    if axeStats.SpecialTrees and axeStats.SpecialTrees[treeClass] then
        damage = axeStats.SpecialTrees[treeClass].Damage
    end

    local hold = Instance.new("BodyPosition")
    hold.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    hold.Position = treeInfo.trunk.Position
    hold.Parent = hrp

    LT2_Teleport(treeInfo.trunk.CFrame)
    task.wait(0.1)

    local isDown = false
    local listener
    listener = LT2_Workspace.LogModels.ChildAdded:Connect(function(child)
        local owner = child:WaitForChild("Owner", 3)
        if owner and owner.Value == LT2_LocalPlayer and child.TreeClass.Value == treeClass then
            isDown = true
            local woodSection = child:FindFirstChild("WoodSection")
            if not child.PrimaryPart and woodSection then
                child.PrimaryPart = woodSection
            end
            for i = 1, 30 do
                if (isAuto and LT2_Flags.StopAutoFarm) or (not isAuto and not LT2_Flags.ManualCutSession) then break end
                LT2_SafeFire(LT2_ClientRequestOwnership, child)
                LT2_SafeFire(LT2_ClientIsDragging, child)
                if child.PrimaryPart then
                    child:SetPrimaryPartCFrame(oldCFrame)
                end
                task.wait(0.02)
            end
        end
    end)

    local startTime = tick()
    while not isDown and tick() - startTime < 60 do
        if (isAuto and LT2_Flags.StopAutoFarm) or (not isAuto and not LT2_Flags.ManualCutSession) then break end
        if targetTree.Parent then
            LT2_SafeFire(LT2_RemoteProxy, targetTree.CutEvent, {
                tool = axeTool, faceVector = Vector3.new(1, 0, 0), height = 0.32,
                sectionId = 1, hitPoints = damage, cooldown = -14, cuttingClass = "Axe"
            })
        end
        task.wait(0.1)
    end
    
    task.wait(0.5)
    if listener then listener:Disconnect() end
    
    if hold then 
        hold:Destroy() 
    end
    
    LT2_Teleport(oldCFrame)
    LT2_Flags.IsCutting = false
    
    if not isDown then
        if (isAuto and LT2_Flags.StopAutoFarm) or (not isAuto and not LT2_Flags.ManualCutSession) then
            return false, "Stopped"
        end
        return false, "Timed out. Tree might be unchoppable."
    end
    
    return true, "Success"
end

local function LT2_AutoFarmLoop()
    local failCount = 0
    while LT2_Flags.AutoFarm and not LT2_Flags.StopAutoFarm do
        if not LT2_LocalPlayer.Character or not LT2_LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            LT2_Notify("Farm", "Player died. Waiting for respawn...", "Warning", 3)
            pcall(function() LT2_LocalPlayer.CharacterAdded:Wait() end)
            task.wait(2)
        end
        
        if LT2_Flags.StopAutoFarm then break end
        
        local cutSuccess = 0
        
        for i = 1, LT2_Flags.ChopAmount do
            if not LT2_Flags.AutoFarm or LT2_Flags.StopAutoFarm then break end
            
            local ok, err = LT2_CutTree(LT2_Flags.TreeSelected, true)
            if ok then
                cutSuccess = cutSuccess + 1
                LT2_Notify("Farm", "Cut " .. i .. "/" .. LT2_Flags.ChopAmount, "Info", 1)
            else
                if err == "Stopped" then
                    break
                end
                failCount = failCount + 1
                LT2_Notify("Farm", "Cut failed: " .. err, "Warning", 2)
                if failCount >= 5 then
                    LT2_Notify("Farm", "Stopped after 5 failures.", "Error", 5)
                    LT2_Flags.AutoFarm = false
                    task.defer(function()
                        if LT2_AutoFarmToggle and LT2_AutoFarmToggle.Set then pcall(function() LT2_AutoFarmToggle:Set(false) end) end
                    end)
                    return
                end
                break
            end
            task.wait(0.5)
        end
        
        if cutSuccess > 0 and not LT2_Flags.StopAutoFarm then
            failCount = 0
            task.wait(0.5)
            local sold = LT2_InstantSell(true)
            LT2_Notify("Farm", "Sold " .. sold .. " logs. Continuing...", "Success", 2)
        end
        
        task.wait(0.5)
    end
    
    LT2_Flags.IsCutting = false
    if not LT2_Flags.AutoFarm and not LT2_Flags.StopAutoFarm then
        task.defer(function()
            if LT2_AutoFarmToggle and LT2_AutoFarmToggle.Set then pcall(function() LT2_AutoFarmToggle:Set(false) end) end
        end)
    end
end

LT2_OldHooks.namecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
    if getnamecallmethod() == "Kick" then return task.wait(9e9) end
    if tostring(self) == "Ban" or tostring(self) == "AddLog" then return true end
    return LT2_OldHooks.namecall(self, ...)
end))

local function LT2_SetupCharacter(char)
    local hum = char:WaitForChild("Humanoid")
    hum:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
        if hum.WalkSpeed ~= LT2_Flags.WalkSpeed and LT2_Flags.WalkSpeed > 16 then
            hum.WalkSpeed = LT2_Flags.WalkSpeed
        end
    end)
    hum:GetPropertyChangedSignal("JumpPower"):Connect(function()
        if hum.JumpPower ~= LT2_Flags.JumpPower and LT2_Flags.JumpPower > 50 then
            hum.JumpPower = LT2_Flags.JumpPower
        end
    end)
    if LT2_Flags.WalkSpeed > 16 then hum.WalkSpeed = LT2_Flags.WalkSpeed end
    if LT2_Flags.JumpPower > 50 then hum.JumpPower = LT2_Flags.JumpPower end
end

LT2_LocalPlayer.CharacterAdded:Connect(LT2_SetupCharacter)
if LT2_LocalPlayer.Character then LT2_SetupCharacter(LT2_LocalPlayer.Character) end

LT2_UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe or input.UserInputType ~= Enum.UserInputType.MouseButton1 or not LT2_UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then return end
    local hrp = LT2_GetHRP()
    if hrp then
        local mouse = LT2_LocalPlayer:GetMouse()
        LT2_Teleport(CFrame.new(mouse.Hit.Position + Vector3.new(0, hrp.Size.Y, 0)))
    end
end)

local LT2_FlyBV, LT2_FlyBG, LT2_FlyConn
local function LT2_StartFly()
    local hrp = LT2_GetHRP()
    local hum = LT2_GetHum()
    if not hrp or not hum then return end
    hum.PlatformStand = true
    LT2_FlyBV = Instance.new("BodyVelocity")
    LT2_FlyBV.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    LT2_FlyBV.Parent = hrp
    LT2_FlyBG = Instance.new("BodyGyro")
    LT2_FlyBG.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
    LT2_FlyBG.P = 1e4
    LT2_FlyBG.Parent = hrp
    LT2_FlyConn = LT2_RunService.Heartbeat:Connect(function()
        if not LT2_Flags.Fly or not LT2_FlyBV or not LT2_FlyBV.Parent then return end
        local mv = Vector3.zero
        local cam = LT2_Workspace.CurrentCamera
        if LT2_UserInputService:IsKeyDown(Enum.KeyCode.W) then mv = mv + cam.CFrame.LookVector end
        if LT2_UserInputService:IsKeyDown(Enum.KeyCode.S) then mv = mv - cam.CFrame.LookVector end
        if LT2_UserInputService:IsKeyDown(Enum.KeyCode.A) then mv = mv - cam.CFrame.RightVector end
        if LT2_UserInputService:IsKeyDown(Enum.KeyCode.D) then mv = mv + cam.CFrame.RightVector end
        if LT2_UserInputService:IsKeyDown(Enum.KeyCode.Space) then mv = mv + Vector3.yAxis end
        if LT2_UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then mv = mv - Vector3.yAxis end
        LT2_FlyBV.Velocity = mv.Magnitude > 0 and mv.Unit * LT2_Flags.FlySpeed or Vector3.zero
        LT2_FlyBG.CFrame = cam.CFrame
    end)
end

local function LT2_StopFly()
    if LT2_FlyConn then LT2_FlyConn:Disconnect() LT2_FlyConn = nil end
    if LT2_FlyBV then LT2_FlyBV:Destroy() LT2_FlyBV = nil end
    if LT2_FlyBG then LT2_FlyBG:Destroy() LT2_FlyBG = nil end
    local hum = LT2_GetHum()
    if hum then hum.PlatformStand = false end
end

LT2_UserInputService.JumpRequest:Connect(function()
    if LT2_Flags.InfJump and LT2_LocalPlayer.Character then
        LT2_LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

LT2_RunService.Stepped:Connect(function()
    if not LT2_Flags.Noclip then return end
    local c = LT2_LocalPlayer.Character
    if not c then return end
    for _, p in pairs(c:GetDescendants()) do
        if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end
    end
end)

local vu
pcall(function() vu = game:GetService("VirtualUser") end)
if vu then
    LT2_Connections[#LT2_Connections + 1] = LT2_LocalPlayer.Idled:Connect(function()
        vu:Button2Down(Vector2.new(0, 0), LT2_Workspace.CurrentCamera.CFrame)
        task.wait(1)
        vu:Button2Up(Vector2.new(0, 0), LT2_Workspace.CurrentCamera.CFrame)
    end)
end

local function LT2_GetAllBlueprints()
    local playerBlueprints = LT2_LocalPlayer.PlayerBlueprints.Blueprints
    for _, v in pairs(LT2_ReplicatedStorage.ClientItemInfo:GetChildren()) do
        if v:FindFirstChild('WoodCost') and not playerBlueprints:FindFirstChild(v.Name) then
            v:Clone().Parent = playerBlueprints
        end
    end
    LT2_Notify("Local", "Blueprints acquired.", "Success", 3)
end

local function LT2_AxeDupe()
    if LT2_Flags.DupeCooldown then 
        LT2_Notify("Dupe", "Cooldown active.", "Warning", 3)
        return 
    end
    
    local slotText = LT2_LocalPlayer.PlayerGui.LoadSaveGUI.SlotInfo.Main.SlotName.Text
    local slot = tonumber(slotText:match("%d+"))
    if not slot then 
        LT2_Notify("Dupe", "Could not find slot.", "Error", 3)
        return 
    end
    
    LT2_Notify("Axe Dupe", "Current Slot: " .. slot, "Info", 3)
    LT2_Flags.DupeCooldown = true
    
    local hum = LT2_GetHum()
    if hum then hum:UnequipTools() end
    
    local hrp = LT2_GetHRP()
    if hrp then hrp.CFrame = CFrame.new(0, -390, 0) end
    task.wait(0.33)
    
    if not LT2_LocalPlayer.Character or not LT2_LocalPlayer.Character.Parent then
        LT2_LocalPlayer.CharacterAdded:Wait()
    end
    
    if not LT2_LocalPlayer.Backpack:FindFirstChildWhichIsA("Tool") then
        LT2_LocalPlayer.Backpack.ChildAdded:Wait(function(child)
            return child:IsA("Tool")
        end)
    end
    
    pcall(function()
        game:GetService("ReplicatedStorage"):WaitForChild("LoadSaveRequests"):WaitForChild("RequestLoad"):InvokeServer(slot, LT2_LocalPlayer)
    end)
    
    task.spawn(function()
        for i = 60, 1, -1 do
            LT2_Notify("Axe Dupe", "Cooldown: " .. i .. "s", "Info", 1)
            task.wait(1)
        end
        LT2_Flags.DupeCooldown = false
        LT2_Notify("Axe Dupe", "Ready!", "Success", 3)
    end)
end

local LT2_Locations = {
    { "Wood R Us", CFrame.new(264, 3, 57) },
    { "Land Store", CFrame.new(111, 11, -987) },
    { "Links Logic", CFrame.new(114, 3, -611) },
    { "Volcano", CFrame.new(-1585, 625, 1140) },
    { "Swamp", CFrame.new(-1209, 138, -801) },
    { "Cave", CFrame.new(3581, -177, 430) },
    { "Palm Island", CFrame.new(2549, 5, -42) },
    { "Spawn", CFrame.new(0, 5, 0) },
}

warn("[LT2 Hub] Creating window...")

local LT2_Window = LT2_Eazy:CreateWindow({
    Name = "LT2 Hub",
    SubTitle = "by AkiraDev | v" .. LT2_Version,
    Size = UDim2.fromOffset(660, 560),
    MinimizeKey = Enum.KeyCode.RightShift,
    ConfigId = "LT2_Hub_v1",
    AutoLoad = true,
    NotifyPosition = "BottomRight",
    LoadingTitle = "LT2 Hub",
    LoadingSubtitle = "Loading...",
    LoadingDuration = 1.2,
    Discord = {
        Enabled = true,
        Invite = "9VE4PXFDSg",
    },
})

local LT2_Tabs = {
    Local = LT2_Window:AddTab({ Title = "Local", Icon = "user" }),
    Land = LT2_Window:AddTab({ Title = "Land", Icon = "layers" }),
    Tree = LT2_Window:AddTab({ Title = "Tree", Icon = "zap" }),
    Wood = LT2_Window:AddTab({ Title = "Wood", Icon = "package" }),
    Environment = LT2_Window:AddTab({ Title = "Environment", Icon = "cloud" }),
    Teleport = LT2_Window:AddTab({ Title = "Teleport", Icon = "navigation" }),
    Settings = LT2_Window:AddTab({ Title = "Settings", Icon = "settings" }),
    Credits = LT2_Window:AddTab({ Title = "Credits", Icon = "info" }),
}

LT2_Tabs.Local:AddSection({ Title = "movement" })
LT2_Tabs.Local:AddSlider({ Title = "Walk Speed", Description = "Character speed", Min = 16, Max = 500, Default = 16, Step = 1, Flag = "LT2_WalkSpeed", Callback = function(v)
    LT2_Flags.WalkSpeed = v
    local hum = LT2_GetHum()
    if hum then hum.WalkSpeed = v end
end })

LT2_Tabs.Local:AddSlider({ Title = "Jump Power", Description = "Character jump power", Min = 50, Max = 500, Default = 50, Step = 1, Flag = "LT2_JumpPower", Callback = function(v)
    LT2_Flags.JumpPower = v
    local hum = LT2_GetHum()
    if hum then hum.JumpPower = v end
end })

LT2_Tabs.Local:AddSlider({ Title = "Fly Speed", Description = "Fly velocity", Min = 20, Max = 300, Default = 60, Step = 5, Flag = "LT2_FlySpeed", Callback = function(v)
    LT2_Flags.FlySpeed = v
end })

LT2_Tabs.Local:AddSection({ Title = "toggles" })
local LT2_FlyToggle = LT2_Tabs.Local:AddToggle({ Title = "Fly", Description = "WASD to move", Flag = "LT2_Fly", Default = false, Callback = function(v)
    LT2_Flags.Fly = v
    if v then LT2_StartFly() else LT2_StopFly() end
end })

LT2_Tabs.Local:AddKeybind({
    Title = "Fly Key",
    Default = Enum.KeyCode.F,
    Flag = "LT2_FlyKey",
    Callback = function()
        if LT2_FlyToggle and LT2_FlyToggle.Set then
            LT2_FlyToggle:Set(not LT2_Flags.Fly)
        end
    end
})

LT2_Tabs.Local:AddToggle({ Title = "Noclip", Description = "Walk through walls", Flag = "LT2_Noclip", Default = false, Callback = function(v)
    LT2_Flags.Noclip = v
end })

LT2_Tabs.Local:AddToggle({ Title = "Infinite Jump", Description = "Jump in midair", Flag = "LT2_InfJump", Default = false, Callback = function(v)
    LT2_Flags.InfJump = v
end })

LT2_Tabs.Local:AddSection({ Title = "tools" })
LT2_Tabs.Local:AddButton({ Title = "Axe Dupe", Description = "Duplicates any axe you're holding with your backpack limit of 10 axes then you can dupe to any amount you desire.", ButtonText = "Start (Cooldown of 60 seconds)", Callback = function() task.spawn(LT2_AxeDupe) end })
LT2_Tabs.Local:AddButton({ Title = "Temp Blueprints", Description = "Get all wood blueprints", ButtonText = "Get", Callback = LT2_GetAllBlueprints })

LT2_Tabs.Land:AddSection({ Title = "plot" })
LT2_Tabs.Land:AddButton({ Title = "Free Land", Description = "Get an unowned plot", ButtonText = "Get", Callback = function() task.spawn(function() LT2_FreeLand() end) end })
LT2_Tabs.Land:AddButton({ Title = "Expand Land", Description = "Max out the size of your current plot", ButtonText = "Expand", Callback = function() task.spawn(LT2_ExpandLand) end })

LT2_Tabs.Tree:AddSection({ Title = "cutting" })
local LT2_TreeDropdown = LT2_Tabs.Tree:AddDropdown({ 
    Title = "Tree Type", Description = "Select tree class",
    Values = LT2_TreeClasses, Default = "Generic",
    Callback = function(v) 
        if type(v) == "table" then v = v[1] end
        LT2_Flags.TreeSelected = tostring(v) 
        LT2_Notify("Tree", "Selected: " .. tostring(v), "Info", 2)
    end 
})

LT2_Tabs.Tree:AddSlider({ Title = "Chop Quantity", Description = "How many trees to cut per cycle", Min = 1, Max = 50, Default = 1, Step = 1, Flag = "LT2_ChopAmount", Callback = function(v)
    LT2_Flags.ChopAmount = v
end })

LT2_Tabs.Tree:AddButton({ 
    Title = "Bring & Cut Trees", Description = "Click to start, click again to stop",
    ButtonText = "Cut / Stop",
    Callback = function()
        if LT2_Flags.ManualCutSession then
            LT2_Flags.ManualCutSession = false
            LT2_Notify("Tree", "Stopping cut...", "Warning", 2)
            return
        end
        if LT2_Flags.TreeSelected == "" then 
            LT2_Notify("Tree", "Select a tree type first.", "Warning", 3) 
            return 
        end
        if LT2_Flags.AutoFarm or LT2_Flags.IsCutting then 
            LT2_Notify("Tree", "Farm or cut already in progress.", "Warning", 3) 
            return 
        end

        LT2_Flags.ManualCutSession = true
        LT2_Notify("Tree", "Cut session started. Click again to stop.", "Success", 2)
        
        task.spawn(function()
            local successCount = 0
            for i = 1, LT2_Flags.ChopAmount do
                if not LT2_Flags.ManualCutSession then break end
                local ok, err = LT2_CutTree(LT2_Flags.TreeSelected, false)
                if ok then
                    successCount = successCount + 1
                    LT2_Notify("Tree", "Cut " .. i .. "/" .. LT2_Flags.ChopAmount, "Info", 2)
                else
                    if err ~= "Stopped" then
                        LT2_Notify("Tree", "Failed: " .. err, "Error", 3)
                    end
                    break
                end
                task.wait(0.5)
            end
            LT2_Flags.ManualCutSession = false
            if successCount > 0 then
                LT2_Notify("Tree", "Finished. " .. successCount .. "/" .. LT2_Flags.ChopAmount .. " trees cut.", "Success", 3)
            end
        end)
    end 
})

LT2_AutoFarmToggle = LT2_Tabs.Tree:AddToggle({ 
    Title = "Auto Farm", Description = "Cuts and sells continuously",
    Flag = "LT2_AutoFarm", Default = false,
    Callback = function(v)
        if v then
            if LT2_Flags.TreeSelected == "" then
                LT2_Notify("Farm", "Select a tree type first!", "Warning", 3)
                task.defer(function()
                    if LT2_AutoFarmToggle and LT2_AutoFarmToggle.Set then pcall(function() LT2_AutoFarmToggle:Set(false) end) end
                end)
                return
            end
            LT2_Flags.AutoFarm = true
            LT2_Flags.StopAutoFarm = false
            LT2_Flags.ManualCutSession = false
            if LT2_Flags.AutoSell then
                LT2_Flags.AutoSell = false
                task.defer(function()
                    if LT2_AutoSellToggle and LT2_AutoSellToggle.Set then pcall(function() LT2_AutoSellToggle:Set(false) end) end
                end)
            end
            LT2_Notify("Farm", "Auto Farm started: " .. LT2_Flags.TreeSelected, "Success", 3)
            task.spawn(LT2_AutoFarmLoop)
        else
            if LT2_Flags.AutoFarm then
                LT2_Flags.AutoFarm = false
                LT2_Flags.StopAutoFarm = true
                LT2_Notify("Farm", "Auto Farm stopped.", "Info", 3)
            end
        end
    end 
})

LT2_Tabs.Wood:AddSection({ Title = "selling" })
LT2_Tabs.Wood:AddButton({ Title = "Sell Everything", Description = "Sells all owned wood", ButtonText = "Sell", Callback = function()
    task.spawn(function()
        LT2_Flags.StopAutoFarm = false
        local count = LT2_InstantSell(false)
        if count > 0 then 
            LT2_Notify("Wood", "Sold " .. count .. " models.", "Success", 3) 
        else
            LT2_Notify("Wood", "You don't have any wood to sell!", "Warning", 3)
        end
    end)
end })

LT2_AutoSellToggle = LT2_Tabs.Wood:AddToggle({ 
    Title = "Auto Sell", Description = "Sells wood periodically",
    Flag = "LT2_AutoSell", Default = false,
    Callback = function(v)
        if v then
            LT2_Flags.AutoSell = true
            if LT2_Flags.AutoFarm then
                LT2_Flags.AutoFarm = false
                LT2_Flags.StopAutoFarm = true
                task.defer(function()
                    if LT2_AutoFarmToggle and LT2_AutoFarmToggle.Set then pcall(function() LT2_AutoFarmToggle:Set(false) end) end
                end)
            end
            LT2_Notify("Wood", "Auto Sell started.", "Success", 3)
            LT2_StartAutoSell() 
        else
            if LT2_Flags.AutoSell then
                LT2_Flags.AutoSell = false
                LT2_Notify("Wood", "Auto Sell stopped.", "Info", 3)
            end
        end
    end 
})

LT2_Tabs.Wood:AddButton({ Title = "Bring All Logs", Description = "Teleports all owned logs to you", ButtonText = "Bring", Callback = function() task.spawn(LT2_BringAllLogs) end })
LT2_Tabs.Wood:AddButton({ Title = "Split All Wood", Description = "Splits all owned wood into small pieces near you", ButtonText = "Split", Callback = function() task.spawn(LT2_SplitWood) end })

LT2_Tabs.Environment:AddSection({ Title = "lighting" })
LT2_Tabs.Environment:AddToggle({ Title = "Always Day", Description = "Locks time to noon", Flag = "LT2_Day", Default = false, Callback = function(v)
    LT2_Flags.Day = v
    if v then
        LT2_Flags.Night = false
        LT2_Lighting.TimeOfDay = "12:00:00"
        if LT2_Lighting:FindFirstChild("SunPos") then LT2_Lighting.SunPos.Value = 1 end
    end
end })

LT2_Tabs.Environment:AddToggle({ Title = "Always Night", Description = "Locks time to midnight", Flag = "LT2_Night", Default = false, Callback = function(v)
    LT2_Flags.Night = v
    if v then
        LT2_Flags.Day = false
        LT2_Lighting.TimeOfDay = "00:00:00"
        if LT2_Lighting:FindFirstChild("SunPos") then LT2_Lighting.SunPos.Value = -1 end
    end
end })

LT2_Tabs.Environment:AddToggle({ Title = "No Fog", Description = "Removes fog", Flag = "LT2_NoFog", Default = false, Callback = function(v)
    LT2_Flags.NoFog = v
    if v then LT2_Lighting.FogEnd = 100000 end
end })

LT2_Tabs.Environment:AddToggle({ Title = "Shadows", Description = "Toggle global shadows", Flag = "LT2_Shadows", Default = true, Callback = function(v)
    LT2_Flags.Shadows = v
    LT2_Lighting.GlobalShadows = v
end })

LT2_Lighting:GetPropertyChangedSignal("TimeOfDay"):Connect(function()
    if LT2_Flags.Day then
        LT2_Lighting.TimeOfDay = "12:00:00"
    elseif LT2_Flags.Night then
        LT2_Lighting.TimeOfDay = "00:00:00"
    end
end)

LT2_Lighting:GetPropertyChangedSignal("FogEnd"):Connect(function()
    if LT2_Flags.NoFog then
        LT2_Lighting.FogEnd = 100000
    end
end)

LT2_Tabs.Teleport:AddSection({ Title = "locations" })
for _, loc in pairs(LT2_Locations) do
    LT2_Tabs.Teleport:AddButton({
        Title = loc[1], Description = "Teleport to " .. loc[1], ButtonText = "Go",
        Callback = function()
            if LT2_GetHRP() then
                LT2_Teleport(loc[2])
                LT2_Notify("Teleport", "Teleported to " .. loc[1], "Success", 2)
            end
        end,
    })
end

LT2_Tabs.Settings:AddSection({ Title = "safety" })
LT2_Tabs.Settings:AddButton({ Title = "Unload Script", Description = "Restore hooks", ButtonText = "Unload", Callback = function()
    if LT2_OldHooks.namecall then hookmetamethod(game, "__namecall", function(...) return LT2_OldHooks.namecall(...) end) end
    for _, c in pairs(LT2_Connections) do pcall(function() c:Disconnect() end) end
    LT2_StopFly()
    LT2_Notify("Settings", "Unloaded.", "Success", 3)
end })

LT2_Window:BuildConfigSection(LT2_Tabs.Settings)

LT2_Tabs.Credits:AddSection({ Title = "about" })
LT2_Tabs.Credits:AddParagraph({ Title = "LT2 Hub v" .. LT2_Version, Content = "Utility suite for Lumber Tycoon 2." })
LT2_Tabs.Credits:AddParagraph({ Title = "Developer", Content = "AkiraDev — github.com/akiradv" })
LT2_Tabs.Credits:AddParagraph({ Title = "Interface", Content = "Eazy UI " .. LT2_UIVersion .. " by AkiraDev" })
LT2_Tabs.Credits:AddParagraph({ Title = "Credits", Content = "Open source community." })

warn("[LT2 Hub] Loaded v" .. LT2_Version)
LT2_Notify("LT2 Hub", "Loaded v" .. LT2_Version, "Success", 3)