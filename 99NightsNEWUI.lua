
----\\ SERVICES //----
local Players = game:GetService("Players")
local LocalPlayer = game.Players.LocalPlayer or Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local workspace = game:GetService("Workspace")
local ProximityPromptService = game:GetService("ProximityPromptService")
local RunService = game:GetService("RunService")
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
    AutoEat = false
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
    ActiveEsp = false
}

local EspVariable = {
    Items = false,
    Animals = false
}

local SelectedFood = {}
local SavedPrompt = {}
local SavedModel = {}
local SavedChest = {}
local SelectedItem = {}

local SavedHitbox = setmetatable({}, { __mode = "kv" })
local SavedEsp = setmetatable({}, { __mode = "k" })
local SavedFood = setmetatable({}, { __mode = "k" })
local SavedScrap = setmetatable({}, { __mode = "k" })
local SavedItems = setmetatable({}, { __mode = "k" })
local SavedEspAnimal = setmetatable({}, { __mode = "k" })

local ActiveBringItems = false
local PositionPlant = 'Random'
local BringFuelItems = false
local BringScrapItems = false
local AuraActive = false
local CountRemote = 1
local CountSpam = 0
local MultipleAttack = false
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

Functions.EatFood = function()
    for _, v in pairs(workspace.Items:GetChildren()) do
        local bar = game:GetService("Players").LocalPlayer.PlayerGui.Interface.StatBars.HungerBar.Bar
        if bar.Size.X.Scale >= 1 then
            break
        end
        for _, isi in pairs(SelectedFood) do
            if isi == 'Cooked Food' and v.Name:lower():match('cook') and v:GetAttribute('RestoreHunger') then
                game:GetService("ReplicatedStorage").RemoteEvents.RequestConsumeItem:InvokeServer(v)
            end
            if isi == 'Raw Food' and (v.Name == 'Morsel' or v.Name == 'Steak') and v:GetAttribute('RestoreHunger') then
                game:GetService("ReplicatedStorage").RemoteEvents.RequestConsumeItem:InvokeServer(v)
            end
            if isi == 'Vegetable Food' and not v.Name:lower():match('morsel') and not v.Name:lower():match('steak') and v:GetAttribute('RestoreHunger') then
                game:GetService("ReplicatedStorage").RemoteEvents.RequestConsumeItem:InvokeServer(v)
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
                    game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents"):WaitForChild("RequestPlantItem"):InvokeServer(v, result.Position)
                else
                    origin = LocalPlayer.Character:GetPivot().Position
                    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
                    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
                    local result = workspace:Raycast(origin, direction, raycastParams)
                    game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents"):WaitForChild("RequestPlantItem"):InvokeServer(v, result.Position)
                end
            end
        end
    end)
end

Functions.BringFood = function(target, click)
    pcall(function()
        for i, v in pairs(workspace.Items:GetChildren()) do
            if v:IsA('Model') and v:GetAttribute('RestoreHunger') and (click or not SavedFood[v]) then
                local distance = (v:GetPivot().Position - target).Magnitude
                if distance > 20 and v.PrimaryPart then
                    game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents"):WaitForChild("RequestStartDraggingItem"):FireServer(v)
                    v:PivotTo(CFrame.new(target))
                    game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents"):WaitForChild("StopDraggingItem"):FireServer(v)
                    if not click then
                        SavedFood[v] = true
                    end
                    task.wait(0.1)
                end
            end
        end
    end)
end

Functions.BringScrap = function(target, click)
    workspace.StreamingEnabled = false
    pcall(function()
        for i, v in pairs(workspace.Items:GetChildren()) do
            if v:IsA('Model') and v.Parent == workspace.Items and v:GetAttribute('Scrappable') then
                local distance = (v:GetPivot().Position - target).Magnitude
                if distance > 7 and v.PrimaryPart then
                    game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents"):WaitForChild("RequestStartDraggingItem"):FireServer(v)
                    v:PivotTo(CFrame.new(target))
                    game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents"):WaitForChild("StopDraggingItem"):FireServer(v)
                    task.wait(0.1)
                end
            end
        end
    end)
end

Functions.BringFuel = function(target, blacklist)
    workspace.StreamingEnabled = false
    pcall(function()
        for i, v in pairs(workspace.Items:GetChildren()) do
            if v:IsA('Model') and (v:GetAttribute('BurnFuel') or v:GetAttribute('FuelBurn')) and not v.Name:lower():match('sapling') then
                local nameLower = v.Name:lower()
                local isLogOrChair = nameLower:match('log') or nameLower:match('chair')
                if (blacklist == 'ExceptLog' and not isLogOrChair) or (blacklist == 'ExceptGas' and isLogOrChair) or (blacklist ~= 'ExceptLog' and blacklist ~= 'ExceptGas') then
                    local distance = (v:GetPivot().Position - target).Magnitude
                    if distance > 7 and v.PrimaryPart then
                        game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents"):WaitForChild("RequestStartDraggingItem"):FireServer(v)
                        v:PivotTo(CFrame.new(target))
                        game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents"):WaitForChild("StopDraggingItem"):FireServer(v)
                        task.wait(0.1)
                    end
                end
            end
        end
    end)
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
                local target = GetMob('Hitbox')
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
                task.wait(0.3)
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
                                Functions.BringFuel(workspace.Map.Campground.Scrapper.DashedLine.Position + Vector3.new(0, 7, 0), 'ExceptGas')
                            end)
                            MainVariable.BringFuel1 = false
                        end)
                    end
                    if BringScrapItems and not MainVariable.BringScrap then
                        MainVariable.BringScrap = true
                        task.spawn(function()
                            pcall(function()
                                Functions.BringScrap(workspace.Map.Campground.Scrapper.DashedLine.Position + Vector3.new(0, 7, 0))
                            end)
                            MainVariable.BringScrap = false
                        end)
                    end
                end
                if MainToggle.Campfire and not MainVariable.BringFuel2 then
                    MainVariable.BringFuel2 = true
                    task.spawn(function()
                        pcall(function()
                            Functions.BringFuel(workspace.Map.Campground.MainFire.InnerTouchZone.Position + Vector3.new(0, 7, 0), 'ExceptLog')
                        end)
                        MainVariable.BringFuel2 = false
                    end)
                end
                if MainToggle.Food and not MainVariable.BringFood then
                    MainVariable.BringFood = true
                    task.spawn(function()
                        pcall(function()
                            Functions.BringFood(workspace.Map.Campground.MainFire.InnerTouchZone.Position + Vector3.new(0, 7, 0))
                        end)
                        MainVariable.BringFood = false
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
            MainToggle.KillAura = true
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
            MainToggle.TreeAura = true
            RunFunctions.ActiveAura(Value)
        end)
	end,
})

local OtherTab = Tabs.Main:AddLeftGroupbox("Other", "home")

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

BringTab:AddButton({
	Text = "Eat Food",
	Func = function()
		Functions.EatFood()
	end,
	DoubleClick = false,
	Disabled = false,
	Visible = true,
	Risky = false,
})

local BringTab = Tabs.Main:AddRightGroupbox("Bring Items", "box")

BringTab:AddDropdown("TypeItem", {
	Values = { "Food", "Fuel", "Scrap" },
	Default = 1,
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
            MainToggle.Scrapper = state
            RunFunctions.ActiveAllCode(state)
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
            MainToggle.Campfire = state
            RunFunctions.ActiveAllCode(state)
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

