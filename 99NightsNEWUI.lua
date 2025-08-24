
----\\ SERVICES //----
local Players = game:GetService("Players")
local LocalPlayer = game.Players.LocalPlayer or Players.LocalPlayer
local Interface = LocalPlayer.PlayerGui.Interface
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local workspace = game:GetService("Workspace")
local ProximityPromptService = game:GetService("ProximityPromptService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local VirtualUser = game:GetService("VirtualUser")
local VirtualInputManager = game:GetService("VirtualInputManager")
----\\ MODULES //----
local fishingRod = ReplicatedStorage:FindFirstChild("Tools"):FindFirstChild("Fishing Rod") or nil
local fishingModule
local originalPull
if fishingRod and require then
    fishingModule = require(fishingRod)
    originalPull = fishingModule.Pull 
end
----\\ TOGGLES //----
local MainToggle = {
    Hitbox = false,
    InstantInteract = false,
    WalkSpeed = false,
    NoFog = false,
    KillAura = false,
    TreeAura = false,
    AutoCook = false,
    ActiveAura = false,
    Scrapper = false,
    Campfire = false,
    BringItems = false,
    Food = false,
    AutoPlant = false,
    ActiveAllCode = false,
    ActiveEsp = false,
    AutoEat = false,
    MoveModel = false,
    AutoReel = false,
    AutoCast = false,
    AutoFishing = false,
    InstantFishing = false
}

local EspToggle = {
    Animals = false,
    Items = false
}

local TeleportToggle = {
    Campfire = false
}
----\\ Connection //----
local MainConnection = {
    Hitbox = nil,
    HitboxRemove = nil,
    InstantInteract = nil,
    WalkSpeed = nil,
    NoFog = nil,
    NoFogRemoved = nil,
    AutoEat = nil
}

local EspConnection = {
    Animals = nil,
    AnimalsRemoved = nil,
    Items = nil,
    ItemsRemoved = nil
}

local TeleportConnection = {
    Campfire = nil
}
----\\ Variables //----
local MainVariable = {
    BringScrap = false,
    BringFuel1 = false,
    BringFuel2 = false,
    BringFood = false,
    AutoCook = false,
    AutoPlant = false,
    ActiveMainCode = false,
    ActiveEsp = false,
    ActiveMoveModel = false
}

local EspVariable = {
    Items = false,
    Animals = false
}

local SelectedFood = {}
local SavedPrompt = {}
local SavedChest = {}
local SelectedItem = {}

local SavedModel = setmetatable({}, { __mode = "kv" })
local SavedHitbox = setmetatable({}, { __mode = "kv" })
local SavedEsp = setmetatable({}, { __mode = "k" })
local SavedFood = setmetatable({}, { __mode = "k" })
local SavedScrap = setmetatable({}, { __mode = "k" })
local SavedItems = setmetatable({}, { __mode = "k" })
local SavedEspAnimal = setmetatable({}, { __mode = "k" })
local MovingModels = setmetatable({}, { __mode = "kv" })

local isDragging = false
local ActiveBringItems = false
local PositionPlant = 'Random'
local BringFuelItems = false
local BringScrapItems = false
local AuraActive = false
local CountRemote = 1
local CountSpam = 0
local MultipleAttack = true
local AuraRange = 50
local Speed = 0.2
local HitboxSize = 42
local DoTask = false
local count = 0
local countesp = 0
local Processing = 0
local HitboxTransparency = 0.8
local ActiveHighlight = false
local Humanoid = LocalPlayer.Character:WaitForChild("Humanoid")
local SavedWalkSpeed = Humanoid.WalkSpeed or 20
local WalkSpeedValue = 30
local persen = 20
----\\ FUNCTIONS //----
local Functions = {}
local RunFunctions = {}

Functions.GetAllActiveToggle = function()
    for _, value in pairs(MainToggle) do
        if value == true then
            return true
        end
    end
    return false
end

Functions.CollectCoin = function()
    local request = RemoteEvents:WaitForChild("RequestCollectCoints")
    for _, v in pairs(workspace.Items:GetChildren()) do
        if v.Name:match("Coin") then
            request:InvokeServer(v)
        end
    end
end

Functions.IsInside = function()
    local gui = Interface.FishingCatchFrame
    local timbar = gui.TimingBar
    local bar = timbar.Bar
    local successArea = timbar.SuccessArea
    local successAreaY1 = successArea.AbsolutePosition.Y
    local successAreaY2 = successArea.AbsolutePosition.Y + successArea.AbsoluteSize.Y
    local barY1 = bar.AbsolutePosition.Y
    local barY2 = bar.AbsolutePosition.Y + bar.AbsoluteSize.Y
    return barY2 > successAreaY1 and barY1 < successAreaY2
end

Functions.MoveModel = function(model: Model, targetPos: Vector3, speed: number)
    if not model.PrimaryPart then
        warn(model.Name .. " PrimaryPart not found")
        return
    end

    local startPos = model.PrimaryPart.Position
    local distance = (targetPos - startPos).Magnitude
    local duration = distance / speed

    local tweenInfo = TweenInfo.new(
        0.5,
        Enum.EasingStyle.Sine,
        Enum.EasingDirection.Out
    )

    local tween = TweenService:Create(model.PrimaryPart, tweenInfo, {Position = targetPos})

    MovingModels[model] = {
        Model = model,
        Target = targetPos,
        Tween = tween,
        StartPos = startPos,
        Active = true
    }

    tween:Play()
    tween.Completed:Connect(function()
        if MovingModels[model] then
            MovingModels[model] = nil
            RemoteEvents:WaitForChild("StopDraggingItem"):FireServer(model)
            model.PrimaryPart.CanCollide = true
        end
    end)
end

Functions.EatFood = function()
    for _, v in pairs(workspace.Items:GetChildren()) do
        local bar = game:GetService("Players").LocalPlayer.PlayerGui.Interface.StatBars.HungerBar.Bar
        if bar.Size.X.Scale >= 1 then
            break
        end
        for _, isi in pairs(SelectedFood) do
            if isi == 'Cooked Food' and v.Name:lower():match('cook') and v:GetAttribute('RestoreHunger') then
                RemoteEvents.RequestConsumeItem:InvokeServer(v)
            end
            if isi == 'Raw Food' and (v.Name == 'Morsel' or v.Name == 'Steak') and v:GetAttribute('RestoreHunger') then
                RemoteEvents.RequestConsumeItem:InvokeServer(v)
            end
            if isi == 'Vegetable Food' and not v.Name:lower():match('morsel') and not v.Name:lower():match('steak') and v:GetAttribute('RestoreHunger') then
                RemoteEvents.RequestConsumeItem:InvokeServer(v)
            end
        end
    end
end

Functions.TeleportTo = function(target)
    if not target then return end
    local char = LocalPlayer.Character
    if not char then return end
    char:PivotTo(CFrame.new(target))
end

Functions.AutoPlant = function()
    pcall(function()
        for _, v in ipairs(workspace.Items:GetChildren()) do
            if not MainToggle.AutoPlant then
                break
            end
            if v:IsA('Model') and v.Name:lower():match('sapling') then
                local origin = v:GetPivot().Position
                local direction = Vector3.new(0, -100, 0)
                local raycastParams = RaycastParams.new()
                if PositionPlant == 'Random' then
                    raycastParams.FilterDescendantsInstances = {v}
                    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
                    local result = workspace:Raycast(origin, direction, raycastParams)
                    RemoteEvents:WaitForChild("RequestPlantItem"):InvokeServer(v, result.Position)
                else
                    origin = LocalPlayer.Character:GetPivot().Position
                    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
                    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
                    local result = workspace:Raycast(origin, direction, raycastParams)
                    RemoteEvents:WaitForChild("RequestPlantItem"):InvokeServer(v, result.Position)
                end
            end
        end
    end)
end

Functions.BringFood = function(target, click, toggle)
    pcall(function()
        for i, v in pairs(workspace.Items:GetChildren()) do
            if v:IsA('Model') and v:GetAttribute('RestoreHunger') and (click or not SavedFood[v]) then
                local distance = (v:GetPivot().Position - target).Magnitude
                if distance > 20 and v.PrimaryPart then
                    RemoteEvents:WaitForChild("CutsceneFinished"):FireServer()
                    if not isDragging and not SavedModel[v] then
                        RemoteEvents:WaitForChild("RequestStartDraggingItem"):FireServer(v)
                        isDragging = true
                        SavedModel[v] = true
                    end
                    v:PivotTo(CFrame.new(target))
                    if isDragging and SavedModel[v] then
                        RemoteEvents:WaitForChild("StopDraggingItem"):FireServer(v)
                        isDragging = false
                        SavedModel[v] = nil
                    end
                    task.wait(0.1)
                end
            end
        end
    end)
    return not toggle
end

Functions.BringScrap = function(target, click, toggle)
    pcall(function()
        for i, v in pairs(workspace.Items:GetChildren()) do
            if v:IsA('Model') and v.Parent == workspace.Items and v:GetAttribute('Scrappable') then
                local distance = (v:GetPivot().Position - target).Magnitude
                if distance > 7 and v.PrimaryPart then
                    RemoteEvents:WaitForChild("CutsceneFinished"):FireServer()
                    if not isDragging and not SavedModel[v] then
                        RemoteEvents:WaitForChild("RequestStartDraggingItem"):FireServer(v)
                        isDragging = true
                        SavedModel[v] = true
                    end
                    v:PivotTo(CFrame.new(target))
                    if isDragging and SavedModel[v] then
                        RemoteEvents:WaitForChild("StopDraggingItem"):FireServer(v)
                        isDragging = false
                        SavedModel[v] = nil
                    end
                    task.wait(0.1)
                end
            end
        end
    end)
    return not toggle
end

Functions.BringFuel = function(target, blacklist, toggle)
    pcall(function()
        for i, v in pairs(workspace.Items:GetChildren()) do
            if v:IsA('Model') and (v:GetAttribute('BurnFuel') or v:GetAttribute('FuelBurn')) and not v.Name:lower():match('sapling') then
                local nameLower = v.Name:lower()
                local isLogOrChair = nameLower:match('log') or nameLower:match('chair')
                if (blacklist == 'ExceptLog' and not isLogOrChair) or (blacklist == 'ExceptGas' and isLogOrChair) or (blacklist ~= 'ExceptLog' and blacklist ~= 'ExceptGas') then
                    local distance = (v:GetPivot().Position - target).Magnitude
                    if distance > 7 and v.PrimaryPart then
                        RemoteEvents:WaitForChild("CutsceneFinished"):FireServer()
                        if not isDragging and not SavedModel[v] then
                            RemoteEvents:WaitForChild("RequestStartDraggingItem"):FireServer(v)
                            isDragging = true
                            SavedModel[v] = true 
                        end
                        v:PivotTo(CFrame.new(target))
                        if isDragging and SavedModel[v] then
                            RemoteEvents:WaitForChild("StopDraggingItem"):FireServer(v)
                            isDragging = false
                            SavedModel[v] = nil
                        end
                        task.wait(0.1)
                    end
                end
            end
        end
    end)
    return not toggle
end

Functions.GetNearChar = function()
    local char = LocalPlayer.Character
    if not char or not char:GetPivot() then return end
    local rootPos = char:GetPivot().Position

    local minDist, closest = AuraRange or math.huge, nil
    local results = {}

    for _, v in ipairs(workspace.Characters:GetChildren()) do
        local hum = v:FindFirstChildOfClass('Humanoid')
        if v:IsA('Model') and hum and hum.Health > 0 and not v.Name:lower():match('child') and not v.Name:lower():match('trader') then

            local dist = (v:GetPivot().Position - rootPos).Magnitude
            if not MultipleAttack and dist < minDist then
                minDist, closest = dist, v
            end
            if MultipleAttack and dist <= AuraRange then
                table.insert(results, v)
            end
        end
    end
    if not MultipleAttack and closest then
        table.insert(results, closest)
    end

    return results
end

Functions.GetNearTree = function()
    local char = LocalPlayer.Character
    if not char or not char:GetPivot() then return end
    local rootPos = char:GetPivot().Position

    local minDist, closest = AuraRange or math.huge, nil
    local results = {}

    for _, v in ipairs(workspace.Map.Foliage:GetChildren()) do
        if v:IsA('Model') and v.Name:lower():match('tree') then
            local dist = (v:GetPivot().Position - rootPos).Magnitude
            if not MultipleAttack and dist < minDist then
                minDist, closest = dist, v
            end
            if MultipleAttack and dist <= AuraRange then
                table.insert(results, v)
            end
        end
    end
    if not MultipleAttack and closest then
        table.insert(results, closest)
    end

    return results
end

Functions.GetDamageTool = function()
    for _, tool in pairs(LocalPlayer.Inventory:GetChildren()) do
        if tool:IsA("Model") and tool:GetAttribute("WeaponDamage") then
            for _, char in pairs(LocalPlayer.Character:GetChildren()) do
                if char:IsA("Model") and char:FindFirstChild("OriginalItem") and tostring(char.OriginalItem.Value) == tool.Name then
                    return tool
                end
            end
        end
    end
    return
end

Functions.GetTreeTool = function()
    for _, v in pairs(LocalPlayer.Inventory:GetChildren()) do
        if v:IsA("Model") and (v.Name:lower():match("axe") or v.Name:lower():match("chainsaw") or tostring(v:GetAttribute("ToolName")) == "GenericAxe") then
            for _, inv in pairs(LocalPlayer.Character:GetChildren()) do
                if inv:IsA("Model") and inv:GetAttribute("ToolName") == "GenericAxe" and inv:FindFirstChild("OriginalItem") and tostring(inv.OriginalItem.Value) == v.Name then
                    return v
                end
            end
        end
    end
    return
end

Functions.GetRawMeat = function()
    local char = LocalPlayer.Character
    if not char or not char:GetPivot() then return end
    local rootPos = char:GetPivot().Position

    local results = {}

    for _, v in ipairs(workspace.Items:GetChildren()) do
        if v:IsA('Model') and (v.Name:lower():match('morsel') or v.Name:lower():match('steak')) then
            local dist = (v:GetPivot().Position - rootPos).Magnitude
            if dist <= 20 then
                table.insert(results, v)
            end
        end
    end

    return results
end

Functions.CookFood = function()
    local remote = ReplicatedStorage.RemoteEvents:FindFirstChild('RequestCookItem')
    task.spawn(function()
        local Target = GetRawMeat()
        if Target and remote then
            for _, v in pairs(Target) do
                task.spawn(function()
                    local success, err = pcall(function()
                        remote:FireServer(workspace.Map.Campground.MainFire, v)
                    end)
                end)
            end
        end
    end)
end

Functions.GetMob = function(type)
    local results = {}

    local characters = workspace.Characters:GetChildren()
    pcall(function()
        for i = 1, #characters do
            local v = characters[i]
            if v:IsA('Model') then
                local nameLower = v.Name:lower()
                if not nameLower:match('child') and not nameLower:match('trader') and not nameLower:match('deer') and not nameLower:match('horse') then
                    local shouldAdd = false
                    if type == 'Hitbox' and MainToggle.Hitbox then
                        local hrp = v:FindFirstChild('HumanoidRootPart')
                        if hrp and hrp.Size ~= Vector3.new(HitboxSize, HitboxSize, HitboxSize) then
                            shouldAdd = true
                        end
                    elseif type == 'EspAnimals' and EspToggle.Animals and not v:FindFirstChild('NevcitESP') then
                        shouldAdd = true
                    end
                    if shouldAdd then
                        table.insert(results, v)
                    end
                end
            end
        end
    end)
    return results
end

Functions.GetItem = function()
    local results = {}
    local items = workspace.Items:GetChildren()
    pcall(function()
        for i = 1, #items do
            local v = items[i]
            if v:IsA('Model') and v.PrimaryPart and not v:FindFirstChild('NevcitESP') then
                table.insert(results, v)
            end
        end
    end)
    return results
end

Functions.ApplyESP = function(obj, type, attribute)
    local folder = obj:FindFirstChild('NevcitESP') or Instance.new('Folder', obj)
    folder.Name = 'NevcitESP'
    local billboard = Instance.new("BillboardGui")
    billboard.Name = type
    billboard.Adornee = obj.PrimaryPart or obj:FindFirstChild('HumanoidRootPart') or obj
    billboard.Size = UDim2.new(0, 100, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 1.5, 0)
    billboard.MaxDistance = 900
    billboard.AlwaysOnTop = true
    billboard.Parent = folder
    local textLabel = Instance.new("TextLabel", billboard)
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.Text = obj.Name
    textLabel.BackgroundTransparency = 1
    textLabel.TextSize = 15
    textLabel.TextStrokeTransparency = 0.3
    textLabel.Font = Enum.Font.SourceSansBold
    if type == 'NevcitESPAnimal' then
        textLabel.TextColor3 = Color3.fromRGB(255,  80,  80)
    elseif attribute == 'Food' then
        textLabel.TextColor3 = Color3.fromRGB(255, 153,  51)
    elseif attribute == 'Fuel' then
        textLabel.TextColor3 = Color3.fromRGB(64, 64, 64)
    elseif attribute == 'Scrap' then
        local getScrap = tostring(obj:GetAttribute('Scrappable'))
        textLabel.Text = obj.Name .. ' (' .. getScrap .. ')'
        textLabel.TextColor3 = Color3.fromRGB(108, 117, 125)
    elseif attribute == 'Tool' then
        textLabel.TextColor3 = Color3.fromRGB(255, 193, 7)
    elseif attribute == 'Chest' then
        local attribute = tostring(LocalPlayer.UserId) .. "Opened"
        local con
        con = obj:GetAttributeChangedSignal(attribute):Connect(function()
            if obj:FindFirstChild('NevcitESP') then
                obj.NevcitESP:Destroy()
                con:Disconnect()
            end
        end)
        local gettier = obj.Name:match("%d+")  or '0'
        textLabel.Text = 'Chest | Tier : ' ..  gettier
        textLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
    elseif attribute == 'Ammo' then
        textLabel.TextColor3 = Color3.fromRGB(181, 142,  80)
    end
    if ActiveHighlight then
        local hl = folder:FindFirstChild('NevcitHighlight') or Instance.new("Highlight", folder)
        hl.Name = "NevcitHighlight"
        hl.Adornee = obj  
        hl.FillColor = type == 'NevcitESPAnimal' and Color3.fromRGB(255, 80, 80) or Color3.fromRGB(80, 180, 255)
        hl.FillTransparency = 0.5  
        hl.OutlineColor = Color3.fromRGB(255, 255, 255)  
        hl.OutlineTransparency = 0.7
    end
end

RunFunctions.NoFog = function(state)
   MainToggle.NoFog = state
    if MainToggle.NoFog then
        game.Lighting.FogEnd = math.huge
        game.Lighting.FogStart = math.huge
        for _, child in pairs(workspace.Map.Boundaries:GetChildren()) do
            task.spawn(function()
                if child:FindFirstChild('TouchInterest') then
                    firetouchinterest(LocalPlayer.Character:FindFirstChild('HumanoidRootPart'), child, 0)
                end
            end)
        end
        MainConnection.NogFogRemoved = workspace.Map.Boundaries.ChildAdded:Connect(function(child)
            task.spawn(function()
                if child:FindFirstChild('TouchInterest') then
                    firetouchinterest(LocalPlayer.Character:FindFirstChild('HumanoidRootPart'), child, 0)
                end
            end)
        end)
        MainConnection.NoFog = game:GetService('Lighting').Changed:Connect(function(property)
            if (tostring(property) == 'FogEnd' or tostring(property) == 'FogStart') then
                game.Lighting.FogEnd = math.huge
                game.Lighting.FogStart = math.huge
            end
        end)
    else
        if MainConnection.NoFog then
            MainConnection.NoFog:Disconnect()
            MainConnection.NoFog = nil
        end
        if MainConnection.NogFogRemoved then
            MainConnection.NogFogRemoved:Disconnect()
            MainConnection.NogFogRemoved = nil
        end
        if game.Lighting.ClockTime <= 0 then
            game.Lighting.FogEnd = 110
            game.Lighting.FogStart = 30
        elseif game.Lighting.ClockTime >= 14 then
            game.Lighting.FogEnd = 300
            game.Lighting.FogStart = 50
        end
    end
end

RunFunctions.CostumWalkSpeed = function(state)
    MainToggle.WalkSpeed = state
    if MainToggle.WalkSpeed then
        LocalPlayer.Character.Humanoid.WalkSpeed = WalkSpeedValue
        MainConnection.WalkSpeed = LocalPlayer.Character.Humanoid.Changed:Connect(function()
            if LocalPlayer.Character.Humanoid.WalkSpeed ~= WalkSpeedValue then
                LocalPlayer.Character.Humanoid.WalkSpeed = WalkSpeedValue
            end
        end)
    else
        if MainConnection.WalkSpeed then
            MainConnection.WalkSpeed:Disconnect()
            MainConnection.WalkSpeed = nil
        end
        if LocalPlayer.Character.Humanoid.WalkSpeed ~= SavedWalkSpeed then
            LocalPlayer.Character.Humanoid.WalkSpeed = SavedWalkSpeed
        end
    end
end

RunFunctions.InstantInteract = function(state)
    MainToggle.InstantInteract = state
    if MainToggle.InstantInteract then
        MainConnection.InstantInteract = ProximityPromptService.PromptButtonHoldBegan:Connect(function(v)
            if not SavedPrompt[v] then
                SavedPrompt[v] = true
                fireproximityprompt(v)
                task.wait(0.4)
                SavedPrompt[v] = nil
            end
        end)
    else
        if MainConnection.InstantInteract then
            MainConnection.InstantInteract:Disconnect()
            MainConnection.InstantInteract = nil
        end
    end
end

RunFunctions.ActiveEsp = function()
    if EspToggle.Animals and not EspVariable.Animals then
        for _, v in pairs(workspace.Characters:GetChildren()) do
            task.spawn(function()
                task.wait(0.1)
                local lower = v.Name:lower()
                if not lower:match('deer') and not lower:match('child') and not lower:match('trader') and not lower:match('horse') and not v:FindFirstChild('NevcitESP') then
                    local success, err = pcall(function()
                        Functions.ApplyESP(v, 'NevcitESPAnimal')
                    end)
                    if not success then
                        print(tostring(err))
                    end
                end
            end)
        end
        EspVariable.Animals = workspace.Characters.ChildAdded:Connect(function(v)
            task.spawn(function()
                task.wait(0.1)
                local lower = v.Name:lower()
                if not lower:match('deer') and not lower:match('child') and not lower:match('trader') and not lower:match('horse') and not v:FindFirstChild('NevcitESP') then
                    local success, err = pcall(function()
                        Functions.ApplyESP(v, 'NevcitESPAnimal')
                    end)
                    if not success then
                        print(tostring(err))
                    end
                end
            end)
        end)
    end
    if EspToggle.Items and not EspVariable.Items then
        for _, child in pairs(workspace.Items:GetChildren()) do
            task.spawn(function()
                task.wait(0.15)
                if not child:FindFirstChild('NevcitESP') then
                    local success, err = pcall(function()
                        for key, isi in pairs(SelectedItem) do
                            if (key == 'Chest' or isi == 'Chest') and child.Name:lower():match('chest') and not child:GetAttribute(tostring(LocalPlayer.UserId) .. 'Opened') then
                                Functions.ApplyESP(child, 'NevcitESPItem', 'Chest')
                            end
                            if (key == 'Fuel' or isi == 'Fuel') and (child:GetAttribute('BurnFuel') or child:GetAttribute('FuelBurn')) then
                                Functions.ApplyESP(child, 'NevcitESPItem', 'Fuel')
                            end
                            if (key == 'Scrap' or isi == 'Scrap') and child:GetAttribute('Scrappable') then
                                Functions.ApplyESP(child, 'NevcitESPItem', 'Scrap')
                            end
                            if (key == 'Tool' or isi == 'Tool') and child:GetAttribute('Interaction') and tostring(child:GetAttribute('Interaction')) == 'Tool' then
                                Functions.ApplyESP(child, 'NevcitESPItem', 'Tool')
                            end
                            if (key == 'Ammo' or isi == 'Ammo') and child.Name:lower():match('ammo') then
                                Functions.ApplyESP(child, 'NevcitESPItem', 'Ammo')
                            end
                            if (key == 'Food' or isi == 'Food') and child:GetAttribute('RestoreHunger') then
                                Functions.ApplyESP(child, 'NevcitESPItem', 'Food')
                            end
                        end
                    end)
                    if not success then
                        print(tostring(err))
                    end
                end
            end)
        end
        EspVariable.Items = workspace.Items.ChildAdded:Connect(function(child)
            task.spawn(function()
                task.wait(0.15)
                if not child:FindFirstChild('NevcitESP') then
                    local success, err = pcall(function()
                        for key, isi in pairs(SelectedItem) do
                            if (key == 'Chest' or isi == 'Chest') and child.Name:lower():match('chest') and not child:GetAttribute(tostring(LocalPlayer.UserId) .. 'Opened') then
                                Functions.ApplyESP(child, 'NevcitESPItem', 'Chest')
                            end
                            if (key == 'Fuel' or isi == 'Fuel') and (child:GetAttribute('BurnFuel') or child:GetAttribute('FuelBurn')) then
                                Functions.ApplyESP(child, 'NevcitESPItem', 'Fuel')
                            end
                            if (key == 'Scrap' or isi == 'Scrap') and child:GetAttribute('Scrappable') then
                                Functions.ApplyESP(child, 'NevcitESPItem', 'Scrap')
                            end
                            if (key == 'Tool' or isi == 'Tool') and child:GetAttribute('Interaction') and tostring(child:GetAttribute('Interaction')) == 'Tool' then
                                Functions.ApplyESP(child, 'NevcitESPItem', 'Tool')
                            end
                            if (key == 'Ammo' or isi == 'Ammo') and child.Name:lower():match('ammo') then
                                Functions.ApplyESP(child, 'NevcitESPItem', 'Ammo')
                            end
                            if (key == 'Food' or isi == 'Food') and child:GetAttribute('RestoreHunger') then
                                Functions.ApplyESP(child, 'NevcitESPItem', 'Food')
                            end
                        end
                    end)
                    if not success then
                        print(tostring(err))
                    end
                end
            end)
        end)
    end
    if not EspToggle.Animals and EspVariable.Animals then
        EspVariable.Animals:Disconnect()
        EspVariable.Animals = nil
        for _, v in pairs(workspace.Characters:GetDescendants()) do
            if v.Name == 'NevcitESP' then
                v:Destroy()
            end
            task.wait()
        end
    end
    if not EspToggle.Items and EspVariable.Items then
        EspVariable.Items:Disconnect()
        EspVariable.Items = nil
        for _, v in pairs(workspace.Items:GetDescendants()) do
            if v.Name == 'NevcitESP' then
                v:Destroy()
            end
            task.wait()
        end
    end
end

RunFunctions.HitboxExpander = function(state)
     MainToggle.Hitbox = state
    if MainToggle.Hitbox then
        task.spawn(function()
            while MainToggle.Hitbox do
                local target = Functions.GetMob('Hitbox')
                for _, v in pairs(target) do
                    if v:FindFirstChild('HumanoidRootPart') and (v.HumanoidRootPart.Size ~= Vector3.new(HitboxSize, HitboxSize, HitboxSize) or v.HumanoidRootPart.CanCollide == true or v.HumanoidRootPart.Transparancy ~= HitboxTransparency) then
                        if not SavedHitbox[v] then
                            SavedHitbox[v] = {
                                Size = v.HumanoidRootPart.Size,
                                Transparency = v.HumanoidRootPart.Transparency
                            }
                        end
                        v.HumanoidRootPart.CanCollide = false
                        v.HumanoidRootPart.Transparency = HitboxTransparency
                        v.HumanoidRootPart.Size = Vector3.new(HitboxSize, HitboxSize, HitboxSize)
                    end
                end
                task.wait(0.2)
            end
        end)
    else
        for i, v in pairs(workspace.Characters:GetChildren()) do
            task.spawn(function()
                if SavedHitbox[v] and v:FindFirstChild('HumanoidRootPart') and v.HumanoidRootPart.Size == Vector3.new(HitboxSize, HitboxSize, HitboxSize) then
                    v.HumanoidRootPart.Size = SavedHitbox[v].Size
                    v.HumanoidRootPart.Transparency = SavedHitbox[v].Transparency
                    v.HumanoidRootPart.CanCollide = true
                    task.wait()
                    SavedHitbox[v] = nil
                end
            end)
        end
    end
end

local ScrapperToggle
RunFunctions.ActiveAllCode = function(state)
    MainToggle.ActiveAllCode = state
    if MainToggle.ActiveAllCode then
        if MainVariable.ActiveMainCode then return end
        workspace.StreamingEnabled = false
        MainVariable.ActiveMainCode = true
        task.spawn(function()
            while Functions.GetAllActiveToggle() do
                task.wait(0.2)
                if MainToggle.AutoCollectCoin then
                    Functions.CollectCoin()
                end
                if MainToggle.AutoPlant and not MainVariable.AutoPlant then
                    MainVariable.AutoPlant = true
                    task.spawn(function()
                        pcall(function()
                            Functions.AutoPlant()
                        end)
                        MainVariable.AutoPlant = false
                    end)
                end
                if MainToggle.Scrapper then
                    if not BringFuelItems and not BringScrapItems then
                        Toggles.AutoBringtoScrapper:SetValue(false)
                    end
                    if BringFuelItems and not MainVariable.BringFuel1 then
                        MainVariable.BringFuel1 = true
                        task.spawn(function()
                            pcall(function()
                                Functions.BringFuel(workspace.Map.Campground.Scrapper.DashedLine.Position + Vector3.new(0, 7, 0), 'ExceptGas', MainVariable.BringFuel1)
                            end)
                        end)
                    end
                    if BringScrapItems and not MainVariable.BringScrap then
                        MainVariable.BringScrap = true
                        task.spawn(function()
                            pcall(function()
                                Functions.BringScrap(workspace.Map.Campground.Scrapper.DashedLine.Position + Vector3.new(0, 7, 0), false, MainVariable.BringScrap)
                            end)
                        end)
                    end
                end
                if MainToggle.Campfire and not MainVariable.BringFuel2 and BringFuelItems then
                    MainVariable.BringFuel2 = true
                    task.spawn(function()
                        pcall(function()
                            Functions.BringFuel(workspace.Map.Campground.MainFire.InnerTouchZone.Position + Vector3.new(0, 7, 0), 'ExceptLog', MainVariable.BringFuel2)
                        end)
                    end)
                end
                if MainToggle.Food and not MainVariable.BringFood then
                    MainVariable.BringFood = true
                    task.spawn(function()
                        pcall(function()
                            Functions.BringFood(workspace.Map.Campground.MainFire.InnerTouchZone.Position + Vector3.new(0, 7, 0), false, MainVariable.BringFood)
                        end)
                    end)
                end
                if MainToggle.AutoCook and not MainVariable.AutoCook then
                    MainVariable.AutoCook = true
                    task.spawn(function()
                        pcall(function()
                            Functions.CookFood()
                        end)
                        MainVariable.AutoCook = false
                    end)
                end
            end
        end)
    end
    if not MainToggle.Campfire and MainVariable.BringFuel2 then
        MainVariable.BringFuel2 = false
    end
    if not MainToggle.Scrapper and (MainVariable.BringFuel1 or MainVariable.BringScrap) then
        MainVariable.BringFuel1 = false
        MainVariable.BringScrap = false
        SavedScrap = {}
        SavedScrap = setmetatable({}, { __mode = "k" })
    end
    if not MainToggle.AutoPlant and MainVariable.AutoPlant then
        MainVariable.AutoPlant = false
    end
    if not MainToggle.AutoCook and MainVariable.AutoCook then
        MainVariable.AutoCook = false
    end
    if not MainToggle.Food and MainVariable.BringFood then
        MainVariable.BringFood = false
        SavedFood = {}
        SavedFood = setmetatable({}, { __mode = "k" })
    end
    if not Functions.GetAllActiveToggle() then
        MainVariable.ActiveMainCode = false
    end
end

RunFunctions.ActiveAura = function(state)
    MainToggle.ActiveAura = state
    if MainToggle.ActiveAura then
        if AuraActive then return end
        AuraActive = true
        for i, v in pairs(workspace.Map.Landmarks:GetChildren()) do
            if v.Name:lower():match('tree') then
                v.Parent = workspace.Map.Foliage
            end
        end
        local remote = ReplicatedStorage.RemoteEvents:FindFirstChild('ToolDamageObject')
        task.spawn(function()
            while MainToggle.KillAura or MainToggle.TreeAura do
                task.wait(Speed)
                local Tree = Functions.GetNearTree()
                local Char = Functions.GetNearChar()
                local TreeTool = Functions.GetTreeTool()
                local CharTool = Functions.GetDamageTool()
                if MainToggle.TreeAura and Tree and TreeTool then
                    for _, v in pairs(Tree) do
                        task.spawn(function()
                            local args = {
                                v,
                                TreeTool,
                                tostring(CountRemote) .. '_' .. tostring(LocalPlayer.UserId),
                                TreeTool.Main.CFrame
                            }
                            local success, err = pcall(function()
                                remote:InvokeServer(unpack(args))
                            end)
                            if success then
                                CountRemote = CountRemote + 1
                            end
                        end)
                    end
                end
                if MainToggle.KillAura and Char and CharTool then
                    for _, v in pairs(Char) do
                        task.spawn(function()
                            local args = {
                                v,
                                CharTool,
                                tostring(CountRemote) .. '_' .. tostring(LocalPlayer.UserId),
                                CharTool.Main.CFrame
                            }
                            local success, err = pcall(function()
                                remote:InvokeServer(unpack(args))
                            end)
                            if success then
                                CountRemote = CountRemote + 1
                            end
                        end)
                    end
                end
            end
        end)
    elseif not MainToggle.KillAura and not MainToggle.TreeAura then
        AuraActive = false
    end
end

RunFunctions.AutoTeleportToCampfire = function(state)
    TeleportToggle.Campfire = state
    if TeleportToggle.Campfire then
        if game.Lighting.ClockTime <= 0 then
            Functions.TeleportTo(workspace.Map.Campground.MainFire:GetPivot().Position + Vector3.new(0, 15, 0))
        end
        TeleportConnection.Campfire = game.Lighting.Changed:Connect(function(prop)
            if tostring(prop) == 'ClockTime' and game.Lighting.ClockTime <= 0 then
                Functions.TeleportTo(workspace.Map.Campground.MainFire:GetPivot().Position + Vector3.new(0, 15, 0))
            end
        end)
    else
        if TeleportConnection.Campfire then
            TeleportConnection.Campfire:Disconnect()
            TeleportConnection.Campfire = nil
        end
    end
end

RunFunctions.AutoEatFood = function(state)
    MainToggle.AutoEat = state
    if MainToggle.AutoEat then
        local bar = game:GetService("Players").LocalPlayer.PlayerGui.Interface.StatBars.HungerBar.Bar
        MainConnection.AutoEat = bar:GetPropertyChangedSignal("Size"):Connect(function()
            local getresult = persen / 100 * 1
            if bar.Size.X.Scale <= getresult then
                Functions.EatFood()
            end
        end)
    else
        if MainConnection.AutoEat then
            MainConnection.AutoEat:Disconnect()
            MainConnection.AutoEat = nil
        end
    end
end

RunFunctions.MoveModel = function(state)
    MainToggle.MoveModel = state
    if MainToggle.MoveModel then
        if MainVariable.ActiveMoveModel then return end
        MainVariable.ActiveMoveModel = true
        local rayParams = RaycastParams.new()
        rayParams.FilterType = Enum.RaycastFilterType.Blacklist
        task.spawn(function()
            while MainToggle.MoveModel do
                for model, data in pairs(MovingModels) do
                    if data.Active and model.PrimaryPart and model.PrimaryPart.Parent then
                        local primary = model.PrimaryPart
                        local dir = (data.Target - primary.Position)
                        local dist = dir.Magnitude
                        if dist > 1 then
                            local result = workspace:Raycast(primary.Position, dir.Unit * dist, rayParams)
                            if result then
                                local hitName = result.Instance.Name
                                local parentName = result.Instance.Parent and result.Instance.Parent.Name or ""

                                if parentName == "Fog" then
                                    data.Active = false
                                    local stopTween = TweenService:Create(primary, TweenInfo(0.01), {Position = data.StartPos})
                                    stopTween:Play()
                                    MovingModels[model] = nil
                                    primary.CanCollide = true
                                elseif not parentName == "Fog" and not parentName == "" then
                                    primary.CanCollide = false
                                end
                            end
                        end
                    else
                        MovingModels[model] = nil
                    end
                end
                task.wait(0.3)
            end
        end)
    else
        MainVariable.ActiveMoveModel = false
    end
end

RunFunctions.AutoReel = function(state)
    MainToggle.AutoCast = state
    if MainToggle.AutoCast and not MainToggle.AutoFishing then
        local lastY = nil
        local debounce = false
        local direction = nil
        local clickedUp = false
        local clickedDown = false 
        local gui = Interface.FishingCatchFrame.TimingBar
        local successArea = gui:WaitForChild("SuccessArea")
        local bar = gui:WaitForChild("Bar")
        task.spawn(function()
            while MainToggle.AutoCast do
                if gui.Parent.Visible and Functions.IsInside() then
                    VirtualUser:CaptureController()
                    VirtualUser:ClickButton1(Vector2.new())              
                end
                task.wait(0.05)
            end
        end)
    end
end

RunFunctions.InstantFishing = function(state)
    MainToggle.InstantFishing = state
    if MainToggle.InstantFishing then
        fishingModule.Pull = function(self, ...)
            if self.CatchGoal and Functions.IsInside() then
                self.CatchProgress = self.CatchGoal
            end
            return originalPull(self, ...)
        end
    else
        fishingModulePull = originalPull
    end
end
            

local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Options = Library.Options
local Toggles = Library.Toggles

Library.ShowToggleFrameInKeybinds = true

local Window = Library:CreateWindow({
	-- Set Center to true if you want the menu to appear in the center
	-- Set AutoShow to true if you want the menu to appear when it is created
	-- Set Resizable to true if you want to have in-game resizable Window
	-- Set MobileButtonsSide to "Left" or "Right" if you want the ui toggle & lock buttons to be on the left or right side of the window
	-- Set ShowCustomCursor to false if you don't want to use the Linoria cursor
	-- NotifySide = Changes the side of the notifications (Left, Right) (Default value = Left)
	-- Position and Size are also valid options here
	-- but you do not need to define them unless you are changing them :)

	Title = "mspaint",
	Footer = "version: example",
	Icon = 95816097006870,
	NotifySide = "Right",
	ShowCustomCursor = true,
})

local Tabs = {
	Main = Window:AddTab("Main", "user"),
    Visual = Window:AddTab("Visual", "eye"),
	["UI Settings"] = Window:AddTab("UI Settings", "settings"),
}

local AuraTab = Tabs.Main:AddLeftGroupbox("Aura", "sword")

AuraTab:AddInput("TextBoxRangeAura", {
	Default = 20,
	Numeric = true, -- true / false, only allows numbers
	Finished = false, -- true / false, only calls callback when you press enter
	ClearTextOnFocus = true, -- true / false, if false the text will not clear when textbox focused
	Text = "Range Aura",
	Tooltip = "For Mobile", -- Information shown when you hover over the textbox
	Placeholder = "Type here!",
	Callback = function(Value)
		Options.RangeAura:SetValue(Value)
	end,
})

AuraTab:AddSlider("RangeAura", {
	Text = "Range Aura",
	Default = 20,
	Min = 0,
	Max = 700,
	Rounding = 0,
	Compact = true,
    Callback = function(Value)
        AuraRange = Value
        Options.TextBoxRangeAura:SetValue(Value)
	end,
	Disabled = false,
	Visible = true, 
})

AuraTab:AddInput("TextBoxSpeed", {
	Default = 0.2,
	Numeric = true, -- true / false, only allows numbers
	Finished = false, -- true / false, only calls callback when you press enter
	ClearTextOnFocus = true, -- true / false, if false the text will not clear when textbox focused
	Text = "Speed",
	Tooltip = "For Mobile",
	Placeholder = "Type here!",
	Callback = function(Value)
		Options.Speed:SetValue(Value)
	end,
})

AuraTab:AddSlider("Speed", {
	Text = "Speed",
	Default = 0.2,
	Min = 0,
	Max = 1,
	Rounding = 1,
	Compact = true,
    Callback = function(Value)
        Speed = Value
        Options.TextBoxSpeed:SetValue(Value)
	end,
	Disabled = false,
	Visible = true, 
})

AuraTab:AddToggle("Enemy", {
	Text = "Attack Animal",
	Default = false,
	Disabled = false,
	Visible = true,
	Callback = function(Value)
		task.spawn(function()
            MainToggle.KillAura = Value
            RunFunctions.ActiveAura(Value)
        end)
	end,
})

AuraTab:AddToggle("ChopTree", {
	Text = "Chop Tree",
	Default = false,
	Disabled = false,
	Visible = true,
	Callback = function(Value)
		task.spawn(function()
            MainToggle.TreeAura = Value
            RunFunctions.ActiveAura(Value)
        end)
	end,
})

local OtherTab = Tabs.Main:AddLeftGroupbox("Other", "home")

OtherTab:AddToggle("AutoCollectCoin", {
	Text = "Auto Collect Coin",
	Default = false,
	Disabled = false,
	Visible = true,
	Callback = function(Value)
		task.spawn(function()
            MainToggle.AutoCollectCoin = Value
            RunFunctions.ActiveAllCode(Value)
        end)
	end,
})

OtherTab:AddDropdown("PositionPlant", {
	Values = { "Random", "Player (Yourself)"},
	Default = 1,
	Multi = false, -- true / false, allows multiple choices to be selected
	Text = "Position Plant",
	Callback = function(Value)
        if Value == "Random" then
            PositionPlant = "Random"
        elseif Value == "Player (Yourself)" then
            PositionPlant = "Player"
        end
	end,
})

OtherTab:AddToggle("AutoPlant", {
	Text = "Auto Plant Sapling",
	Default = false,
	Disabled = false,
	Visible = true,
	Callback = function(Value)
		task.spawn(function()
            MainToggle.AutoPlant = Value
            RunFunctions.ActiveAllCode(Value)
        end)
	end,
})

OtherTab:AddDropdown("TypeFood", {
	Values = { "Cooked Food", "Raw Food", "Vegetable Food" },
	Default = 1,
	Multi = true, -- true / false, allows multiple choices to be selected
	Text = "Type Food",
	Callback = function(Value)
        for key, value in next, Options.TypeFood.Value do
			if value then
                table.insert(SelectedFood, key)
            end
		end
	end,
})

OtherTab:AddInput("TextBoxHunger", {
	Default = 20,
	Numeric = true, -- true / false, only allows numbers
	Finished = false, -- true / false, only calls callback when you press enter
	ClearTextOnFocus = true, -- true / false, if false the text will not clear when textbox focused
	Text = "Eat if Hunger Reach (%)",
	Tooltip = "For Mobile",
	Placeholder = "Type here!",
	Callback = function(Value)
		Options.PercentageHunger:SetValue(Value)
        if tonumber(Value) > 99 then
            Options.TextBoxTransparencyHitbox:SetValue(99)
        end
	end,
})

OtherTab:AddSlider("PercentageHunger", {
	Text = "Eat if Hunger Reach (%)",
	Default = 20,
	Min = 1,
	Max = 99,
	Rounding = 0,
	Compact = true,
    Callback = function(Value)
        persen = Value
        Options.TextBoxHunger:SetValue(Value)
	end,
	Disabled = false,
	Visible = true, 
})

OtherTab:AddToggle("AutoEatFood", {
	Text = "Auto Eat Food",
	Default = false,
	Disabled = false,
	Visible = true,
	Callback = function(Value)
		task.spawn(function()
            RunFunctions.AutoEatFood(Value)
        end)
	end,
})

OtherTab:AddButton({
	Text = "Eat Food",
	Func = function()
		Functions.EatFood()
	end,
	DoubleClick = false,
	Disabled = false,
	Visible = true,
	Risky = false,
})

local TeleportTab = Tabs.Main:AddLeftGroupbox("Teleport", "")

TeleportTab:AddToggle("AutoTeleportToCampfire", {
	Text = "Auto Teleport To Campfire When Night",
	Default = false,
	Disabled = false,
	Visible = true,
	Callback = function(Value)
		task.spawn(function()
            RunFunctions.AutoTeleportToCampfire(Value)
        end)
	end,
})

TeleportTab:AddButton({
	Text = "Teleport To Campfire",
	Func = function()
		Functions.TeleportTo(workspace.Map.Campground.MainFire:GetPivot().Position + Vector3.new(0, 15, 0))
	end,
	DoubleClick = false,
	Disabled = false,
	Visible = true,
	Risky = false,
})

local FishingTab = Tabs.Main:AddLeftGroupbox("Fishing", "")

FishingTab:AddToggle("AutoReel", {
	Text = "Auto Reel",
	Default = false,
	Disabled = false,
	Visible = true,
	Callback = function(Value)
		task.spawn(function()
            RunFunctions.AutoReel(Value)
        end)
	end,
})

FishingTab:AddToggle("InstantCatch", {
	Text = "Instant Catch",
	Default = false,
	Disabled = false,
	Visible = true,
	Callback = function(Value)
		task.spawn(function()
            RunFunctions.InstantFishing(Value)
        end)
	end,
})


local BringTab = Tabs.Main:AddRightGroupbox("Bring Items", "box")

BringTab:AddDropdown("TypeItem", {
	Values = { "Food", "Fuel", "Scrap" },
	Default = 0,
	Multi = true, -- true / false, allows multiple choices to be selected
	Text = "Type Item",
	Callback = function(Value)
        for key, value in next, Options.TypeItem.Value do
			if tostring(key) == "Food" and not MainToggle.Food then
                MainToggle.Food = true
            end
            if tostring(key) == "Fuel" and not BringFuelItems then
                BringFuelItems = true
            end
            if tostring(key) == "Scrap" and not BringScrapItems then
                BringScrapItems = true
            end
		end
	end,
})

BringTab:AddToggle("AutoBringtoScrapper", {
	Text = "Auto Bring to Scrapper",
    ToolTip = "Bring Selected Type Item",
	Default = false,
	Disabled = false,
	Visible = true,
	Callback = function(Value)
		task.spawn(function()
            MainToggle.Scrapper = Value
            RunFunctions.ActiveAllCode(Value)
            RunFunctions.MoveModel(Value)
        end)
	end,
})

BringTab:AddToggle("AutoBringtoCampfire", {
	Text = "Auto Bring to Campfire",
    ToolTip = "Only Bring Fuel and Food",
	Default = false,
	Disabled = false,
	Visible = true,
	Callback = function(Value)
		task.spawn(function()
            MainToggle.Campfire = Value
            RunFunctions.ActiveAllCode(Value)
            RunFunctions.MoveModel(Value)
        end)
	end,
})

BringTab:AddButton({
	Text = "Bring Scrap",
	Func = function()
		Functions.BringScrap(LocalPlayer.Character.HumanoidRootPart.Position + Vector3.new(0, 7, 0), true)
	end,
	DoubleClick = false,
	Disabled = false,
	Visible = true,
	Risky = false,
})

BringTab:AddButton({
	Text = "Bring Bring Fuel",
	Func = function()
		Functions.BringFuel(LocalPlayer.Character.HumanoidRootPart.Position + Vector3.new(0, 7, 0), true)
	end,
	DoubleClick = false,
	Disabled = false,
	Visible = true,
	Risky = false,
})

BringTab:AddButton({
	Text = "Bring Foods",
	Func = function()
		Functions.BringFood(LocalPlayer.Character.HumanoidRootPart.Position + Vector3.new(0, 7, 0), true)
	end,
	DoubleClick = false,
	Disabled = false,
	Visible = true,
	Risky = false,
})

BringTab:AddButton({
	Text = "Bring Foods to Campfire",
	Func = function()
		Functions.BringFood(workspace.Map.Campground.MainFire.InnerTouchZone.Position + Vector3.new(0, 7, 0), true)
	end,
	DoubleClick = false,
	Disabled = false,
	Visible = true,
	Risky = false,
})

local HitboxTab = Tabs.Main:AddRightGroupbox("Hitbox", "")

HitboxTab:AddInput("TextBoxSizeHitbox", {
	Default = 20,
	Numeric = true, -- true / false, only allows numbers
	Finished = false, -- true / false, only calls callback when you press enter
	ClearTextOnFocus = true, -- true / false, if false the text will not clear when textbox focused
	Text = "Size",
	Tooltip = "For Mobile",
	Placeholder = "Type here!",
	Callback = function(Value)
		Options.SizeHitbox:SetValue(Value)
        if tonumber(Value) > 200 then
            Options.TextBoxSizeHitbox:SetValue(200)
        end
	end,
})

HitboxTab:AddSlider("SizeHitbox", {
	Text = "Size",
	Default = 20,
	Min = 0,
	Max = 200,
	Rounding = 0,
	Compact = true,
    Callback = function(Value)
        HitboxSize = Value
        Options.TextBoxSizeHitbox:SetValue(Value)
	end,
	Disabled = false,
	Visible = true, 
})

HitboxTab:AddInput("TextBoxTransparencyHitbox", {
	Default = 0.5,
	Numeric = true, -- true / false, only allows numbers
	Finished = false, -- true / false, only calls callback when you press enter
	ClearTextOnFocus = true, -- true / false, if false the text will not clear when textbox focused
	Text = "Transparancy",
	Tooltip = "For Mobile",
	Placeholder = "Type here!",
	Callback = function(Value)
		Options.TransparancyHitbox:SetValue(Value)
        if tonumber(Value) > 1 then
            Options.TextBoxTransparencyHitbox:SetValue(1)
        end
	end,
})

HitboxTab:AddSlider("TransparancyHitbox", {
	Text = "Transparancy",
	Default = 0.5,
	Min = 0,
	Max = 1,
	Rounding = 0,
	Compact = true,
    Callback = function(Value)
        HitboxTransparency = Value
        Options.TextBoxTransparencyHitbox:SetValue(Value)
	end,
	Disabled = false,
	Visible = true, 
})

HitboxTab:AddToggle("HitboxExpander", {
	Text = "Expand Hitbox Animals",
	Default = false,
	Disabled = false,
	Visible = true,
	Callback = function(Value)
		task.spawn(function()
            RunFunctions.HitboxExpander(Value)
        end)
	end,
})

local EspTab = Tabs.Visual:AddLeftGroupbox("ESP", "")

EspTab:AddDropdown("TypeEspItems", {
	Values = { "Ammo", "Chest", "Fuel", "Food", "Tool", "Scrap" },
	Default = 0,
	Multi = true, -- true / false, allows multiple choices to be selected
	Text = "Type Item",
	Callback = function(Value)
        SelectedItem = {}
        if typeof(Value) == "table" then
            for itemName, isSelected in pairs(Value) do
                if isSelected then
                    table.insert(SelectedItem, itemName)
                end
            end
        else
            SelectedItem = { tostring(Value) }
        end
	end,
})

EspTab:AddToggle("EspItems", {
	Text = "Esp Items",
	Default = false,
	Disabled = false,
	Visible = true,
	Callback = function(Value)
		task.spawn(function()
            EspToggle.Items = Value
            RunFunctions.ActiveEsp()
        end)
	end,
})

EspTab:AddToggle("EspAnimals", {
	Text = "Esp Animals",
	Default = false,
	Disabled = false,
	Visible = true,
	Callback = function(Value)
		task.spawn(function()
            EspToggle.Animals = Value
            RunFunctions.ActiveEsp()
        end)
	end,
})

local VisualTab = Tabs.Visual:AddRightGroupbox("Other", "")

VisualTab:AddToggle("NoFog", {
	Text = "No Fog",
	Default = false,
	Disabled = false,
	Visible = true,
	Callback = function(Value)
		task.spawn(function()
            RunFunctions.NoFog(Value)
        end)
	end,
})

---\\ UI Tab //---

local MenuGroup = Tabs["UI Settings"]:AddLeftGroupbox("Menu", "wrench")

MenuGroup:AddToggle("KeybindMenuOpen", {
	Default = Library.KeybindFrame.Visible,
	Text = "Open Keybind Menu",
	Callback = function(value)
		Library.KeybindFrame.Visible = value
	end,
})
MenuGroup:AddToggle("ShowCustomCursor", {
	Text = "Custom Cursor",
	Default = true,
	Callback = function(Value)
		Library.ShowCustomCursor = Value
	end,
})
MenuGroup:AddDropdown("NotificationSide", {
	Values = { "Left", "Right" },
	Default = "Right",

	Text = "Notification Side",

	Callback = function(Value)
		Library:SetNotifySide(Value)
	end,
})
MenuGroup:AddDropdown("DPIDropdown", {
	Values = { "50%", "75%", "100%", "125%", "150%", "175%", "200%" },
	Default = "100%",

	Text = "DPI Scale",

	Callback = function(Value)
		Value = Value:gsub("%%", "")
		local DPI = tonumber(Value)

		Library:SetDPIScale(DPI)
	end,
})
MenuGroup:AddDivider()
MenuGroup:AddLabel("Menu bind")
	:AddKeyPicker("MenuKeybind", { Default = "RightShift", NoUI = true, Text = "Menu keybind" })

MenuGroup:AddButton("Unload", function()
	Library:Unload()
end)

Library.ToggleKeybind = Options.MenuKeybind

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)

-- Ignore keys that are used by ThemeManager.
-- (we dont want configs to save themes, do we?)
SaveManager:IgnoreThemeSettings()

-- Adds our MenuKeybind to the ignore list
-- (do you want each config to have a different menu key? probably not.)
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })

ThemeManager:SetFolder("GoaHub")
SaveManager:SetFolder("GoaHub/99nights")
SaveManager:SetSubFolder("In-Game") -- if the game has multiple places inside of it (for example: DOORS)
-- you can use this to save configs for those places separately
-- The path in this script would be: MyScriptHub/specific-game/settings/specific-place
-- [ This is optional ]

-- Builds our config menu on the right side of our tab
SaveManager:BuildConfigSection(Tabs["UI Settings"])

-- Builds our theme menu (with plenty of built in themes) on the left side
-- NOTE: you can also call ThemeManager:ApplyToGroupbox to add it to a specific groupbox
ThemeManager:ApplyToTab(Tabs["UI Settings"])

-- You can use the SaveManager:LoadAutoloadConfig() to load a config
-- which has been marked to be one that auto loads!
SaveManager:LoadAutoloadConfig()