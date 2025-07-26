for i, v in ipairs(game.CoreGui:GetChildren()) do
    if v.Name == "FLUENT" then
        v:Destroy()
    end
end
local Fluent = loadstring(game:HttpGet("https://raw.githubusercontent.com/Nevcit/Doors/refs/heads/main/Fluent.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/Nevcit/UI-Library/refs/heads/main/Loadstring/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Window = Fluent:CreateWindow({
    Title = "Goa Hub | 99 Nights in The Forest by Nevcit",
    SubTitle = "",
    TabWidth = 100,
    Size = UDim2.fromOffset(560, 300),
    Acrylic = false, -- The blur may be detectable, setting this to false disables blur entirely
    Theme = "Blue",
    MinimizeKey = Enum.KeyCode.LeftControl -- Used when theres no MinimizeKeybind
})

local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "home" }),
    Item = Window:AddTab({ Title = "Bring Items", Icon = "box" }),
    AttackAura = Window:AddTab({ Title = "Attack Aura", Icon = "sword" }),
    Esp = Window:AddTab({ Title = "Visual", Icon = "eye" }),    
    Credit = Window:AddTab({ Title = "Credit", Icon = "bookmark" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

---\ Services /---
local Players = game:GetService("Players")
local workspace = game:GetService("Workspace")
local LocalPlayer = game.Players.LocalPlayer
local ProximityPromptService = game:GetService('ProximityPromptService')
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
---\ Toggle /---
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
    ActiveEsp = false
}
local EspToggle = {
    Animals = false,
    Items = false
}
---\ Connection /---
local MainConnection = {
    Hitbox = nil,
    HitboxRemove = nil,
    InstantInteract = nil,
    WalkSpeed = nil,
    NoFog = nil,
    NoFogRemoved = nil
}

local EspConnection = {
    Animals = nil,
    AnimalsRemoved = nil,
    Items = nil,
    ItemsRemoved = nil
}
---\ Variables /---
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
local SavedHitbox = setmetatable({}, { __mode = "kv" })
local SavedPrompt = {}
local SavedModel = {}
local SavedEsp = setmetatable({}, { __mode = "k" })
local SavedFood = setmetatable({}, { __mode = "k" })
local SavedScrap = setmetatable({}, { __mode = "k" })
local SavedItems = setmetatable({}, { __mode = "k" })
local SavedEspAnimal = setmetatable({}, { __mode = "k" })
local SavedChest = {}
local SelectedItem = {}
local ActiveHighlight = false
local Humanoid = LocalPlayer.Character:WaitForChild("Humanoid")
local SavedWalkSpeed = Humanoid.WalkSpeed or 20
local WalkSpeedValue = 30
---\ Functions /---
task.wait(0.1)
local function AutoPlant()
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

local function GetAllActiveToggle()
    for _, value in pairs(MainToggle) do
        if value == true then
            return true
        end
    end
    return false
end

local function BringFood(target, click)
    pcall(function()
        for i, v in pairs(workspace.Items:GetChildren()) do
            if v:IsA('Model') and v:GetAttribute('RestoreHunger') and (click or not SavedFood[v]) then
                local distance = (v:GetPivot().Position - target).Magnitude
                if distance > 20 and v.PrimaryPart then
                    game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents"):WaitForChild("RequestStartDraggingItem"):FireServer(v)
                    v:PivotTo(CFrame.new(target))
                    if not click then
                        SavedFood[v] = true
                    end
                    task.wait(0.1)
                end
            end
        end
    end)
end

local function BringScrap(target, click)
    workspace.StreamingEnabled = false
    pcall(function()
        for i, v in pairs(workspace.Items:GetChildren()) do
            if v:IsA('Model') and v.Parent == workspace.Items and v:GetAttribute('Scrappable') then
                local distance = (v:GetPivot().Position - target).Magnitude
                if distance > 7 and v.PrimaryPart then
                    game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents"):WaitForChild("RequestStartDraggingItem"):FireServer(v)
                    repeat task.wait() until tostring(v:GetAttribute("Owner")) == tostring(LocalPlayer.UserId)
                    v:PivotTo(CFrame.new(target))
                    game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents"):WaitForChild("StopDraggingItem"):FireServer(v)
                    task.wait(0.1)
                end
            end
        end
    end)
end

local function BringFuel(target, blacklist)
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
                        task.wait(0.1)
                    end
                end
            end
        end
    end)
end

local function GetNearChar()
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


local function GetTool()
    for _, charTool in pairs(LocalPlayer.Character:GetChildren()) do
        if charTool:IsA("Model") and charTool:GetAttribute("ToolName") then
            local neededName = charTool:GetAttribute("ToolName")
            for _, inv in pairs(LocalPlayer.Inventory:GetChildren()) do
                if inv:IsA("Model") and inv:GetAttribute("ToolName") == neededName and inv:GetAttribute("WeaponDamage") and inv:FindFirstChild("OriginalItem") and tostring(inv.OriginalItem.Value) == charTool.Name then
                    return inv
                end
            end
        end
    end
    return
end

local function GetCharTool()
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

local function GetNearTree()
    local char = LocalPlayer.Character
    if not char or not char:GetPivot() then return end
    local rootPos = char:GetPivot().Position

    local minDist, closest = AuraRange or math.huge, nil
    local results = {}

    for _, v in ipairs(workspace.Map.Foliage:GetChildren()) do
        if v:IsA('Model') and v.Name:lower():match('tree') then

            local dist = (v:GetPivot().Position - rootPos).Magnitude

            -- selalu cek single‐attack
            if not MultipleAttack and dist < minDist then
                minDist, closest = dist, v
            end

            -- selalu cek multi‐attack
            if MultipleAttack and dist <= AuraRange then
                table.insert(results, v)
            end
        end
    end

    -- jika single, masukkan hasil closest sekali saja
    if not MultipleAttack and closest then
        table.insert(results, closest)
    end

    return results
end

local function GetTreeTool()
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

local function ActiveAura(state)
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
                local Tree = GetNearTree()
                local Char = GetNearChar()
                local TreeTool = GetTreeTool()
                local CharTool = GetCharTool()
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

local function GetRawMeat()
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

local function AutoCook()
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

local ScrapperToggle
local function ActiveAllCode(state)
    MainToggle.ActiveAllCode = state
    if MainToggle.ActiveAllCode then
        if MainVariable.ActiveMainCode then return end
        workspace.StreamingEnabled = false
        MainVariable.ActiveMainCode = true
        task.spawn(function()
            while GetAllActiveToggle() do
                task.wait(0.3)
                if MainToggle.AutoPlant and not MainVariable.AutoPlant then
                    MainVariable.AutoPlant = true
                    task.spawn(function()
                        pcall(function()
                            AutoPlant()
                        end)
                        MainVariable.AutoPlant = false
                    end)
                end
                if MainToggle.Scrapper then
                    if not BringFuelItems and not BringScrapItems then
                        ScrapperToggle:SetValue(false)
                    end
                    if BringFuelItems and not MainVariable.BringFuel1 then
                        MainVariable.BringFuel1 = true
                        task.spawn(function()
                            pcall(function()
                                BringFuel(workspace.Map.Campground.Scrapper.DashedLine.Position + Vector3.new(0, 7, 0), 'ExceptGas')
                            end)
                            MainVariable.BringFuel1 = false
                        end)
                    end
                    if BringScrapItems and not MainVariable.BringScrap then
                        MainVariable.BringScrap = true
                        task.spawn(function()
                            pcall(function()
                                BringScrap(workspace.Map.Campground.Scrapper.DashedLine.Position + Vector3.new(0, 7, 0))
                            end)
                            MainVariable.BringScrap = false
                        end)
                    end
                end
                if MainToggle.Campfire and not MainVariable.BringFuel2 then
                    MainVariable.BringFuel2 = true
                    task.spawn(function()
                        pcall(function()
                            BringFuel(workspace.Map.Campground.MainFire.InnerTouchZone.Position + Vector3.new(0, 7, 0), 'ExceptLog')
                        end)
                        MainVariable.BringFuel2 = false
                    end)
                end
                if MainToggle.Food and not MainVariable.BringFood then
                    MainVariable.BringFood = true
                    task.spawn(function()
                        pcall(function()
                            BringFood(workspace.Map.Campground.MainFire.InnerTouchZone.Position + Vector3.new(0, 7, 0))
                        end)
                        MainVariable.BringFood = false
                    end)
                end
                if MainToggle.AutoCook and not MainVariable.AutoCook then
                    MainVariable.AutoCook = true
                    task.spawn(function()
                        pcall(function()
                            AutoCook()
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
    if not GetAllActiveToggle() then
        MainVariable.ActiveMainCode = false
    end
end
                
local function RestoreModel(model)
    local data = SavedHitbox[model]
    if not data then return end
    local hrp = model:FindFirstChild('HumanoidRootPart')
    if hrp then
        hrp.Size = data.Size
        hrp.Transparency = data.Transparency
        hrp.CanCollide = true
    end
    SavedHitbox[model] = nil
end

local function HitboxExpander123(state)
    MainToggle.Hitbox = state
    if MainToggle.Hitbox then
        MainConnection.HitboxRemove = workspace.Characters.ChildRemoved:Connect(RestoreModel)
        MainConnection.Hitbox = workspace.Items.ChildAdded:Connect(RestoreModel)
        task.spawn(function()
            while MainToggle.Hitbox do
                if MainToggle.Hitbox == false then
                    break
                end
                if count > 10 then
                    task.wait(0.7)
                    count = 0
                end
                local success, err = pcall(function()
                    for _, v in pairs(workspace.Characters:GetChildren()) do
                        if not SavedHitbox[v] and v:IsA('Model') then
                            if not v.Name:lower():match('child') and not v.Name:lower():match('trader') then
                                local hrp = v:FindFirstChild('HumanoidRootPart')
                                if hrp and hrp.Size ~= Vector3.new(HitboxSize, HitboxSize, HitboxSize) or hrp.Transparency ~= HitboxTransparency or hrp.CanCollide == true then
                                    SavedHitbox[v] = {
                                        Size = hrp.Size,
                                        Transparency = hrp.Transparency
                                    }
                                    hrp.Size = Vector3.new(HitboxSize, HitboxSize, HitboxSize)
                                    hrp.Transparency = HitboxTransparency
                                    hrp.CanCollide = false
                                end
                            end
                        end
                    end
                end)
                count = count + 1
                task.wait()
            end
        end)
    else
        if MainConnection.HitboxRemove then
            MainConnection.HitboxRemove:Disconnect()
            MainConnection.HitboxRemove = nil
        end
        if MainConnection.Hitbox then
            MainConnection.Hitbox:Disconnect()
            MainConnection.Hitbox = nil
        end
        for _, v in pairs(workspace.Characters:GetChildren()) do
            task.spawn(function()
                local hrp = v:FindFirstChild('HumanoidRootPart')
                if hrp and SavedHitbox[v] then
                    local saved = SavedHitbox[v]
                    hrp.Size = Vector3.new(saved.X, saved.Y, saved.Z)
                    hrp.Transparency = saved.Transparency
                    hrp.CanCollide = true
                    SavedHitbox[v] = nil
                end
            end)
        end
        SavedHitbox = {}
    end
end

local function ApplyHitbox(obj)
    if obj:IsA('Model') then
        local hrp = obj:FindFirstChild('HumanoidRootPart')
        if hrp and (hrp.Size ~= Vector3.new(HitboxSize, HitboxSize, HitboxSize) or hrp.Transparency ~= HitboxTransparency or hrp.CanCollide == true) then
            if not SavedHitbox[obj] then
                SavedHitbox[obj] = {
                    Size = hrp.Size,
                    Transparency = hrp.Transparency
                }
            end
            task.wait()
            hrp.CanCollide = false
            hrp.Transparency = HitboxTransparency
            hrp.Size = Vector3.new(HitboxSize, HitboxSize, HitboxSize)
        end
    end
end

local function ProcessHitbox(model)
    local function checkPart()
        local part = model:FindFirstChild('HumanoidRootPart')
        if part then
            ApplyHitbox(model)
            return true
        end
        return false
    end
    
    if checkPart() then return end
    
    local conn
    conn = model.DescendantAdded:Connect(function(desc)
        if desc.Name == 'HumanoidRootPart' then
            ApplyHitbox(model)
            conn:Disconnect()
            return
        end
        task.delay(5, function()
            for _, obj in pairs(workspace.Characters:GetChildren()) do
                if MainToggle.Hitbox and obj.Name == model.Name and not SavedHitbox[obj] and obj:FindFirstChild('HumanoidRootPart') then
                    ApplyHitbox(obj)
                    conn:Disconnect()
                    return
                end
            end
        end)
        task.delay(10, function()
            if conn.Connected then
                conn:Disconnect()
                conn = nil
            end
        end)
    end)
end

local function GetMob(type)
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

local function GetItem()
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

local function HitboxExpander(state)
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

local function HitboxExpandersaa(state)
    MainToggle.Hitbox = state
    if MainToggle.Hitbox then
        for i, v in pairs(workspace.Characters:GetChildren()) do
            if v:IsA('Model') and not v.Name:lower():match('child') and not v.Name:lower():match('trader') then
                ProcessHitbox(v)
            end
        end
        MainConnection.Hitbox = workspace.Characters.ChildAdded:Connect(function(model)
            if model:IsA('Model') and not model.Name:lower():match('child') and not model.Name:lower():match('trader') then
                ProcessHitbox(model)
            end
        end)
        MainConnection.HitboxRemove = workspace.Items.ChildAdded:Connect(RestoreModel)
    else
        if MainConnection.Hitbox then
            MainConnection.Hitbox:Disconnect()
            MainConnection.Hitbox = nil
        end
        if MainConnection.HitboxRemove then
            MainConnection.HitboxRemove:Disconnect()
            MainConnection.HitboxRemove = nil
        end
        for _, v in pairs(workspace.Characters:GetChildren()) do
            task.spawn(function()
                local hrp = v:FindFirstChild('HumanoidRootPart')
                if hrp and SavedHitbox[v] then
                    local saved = SavedHitbox[v]
                    hrp.Size = saved.Size
                    hrp.Transparency = saved.Transparency
                    hrp.CanCollide = true
                    SavedHitbox[v] = nil
                end
            end)
        end
    end
end

local function ApplyESP(obj, type, attribute)
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

local function restoreEsp(obj)
    if obj:IsA('Model') then
        local folder = obj:FindFirstChild('NevcitESP')
        if not folder then return end
        folder:Destroy()
    end
    if SavedEsp[obj] then
        SavedEsp[obj] = nil
    end
    if SavedEspAnimal[obj] then
        SavedEspAnimal[obj] = nil
    end
    if SavedChest[obj] then
        SavedChest[obj] = nil
    end
end

local function ActiveEsp()
    if EspToggle.Animals and not EspVariable.Animals then
        for _, v in pairs(workspace.Characters:GetChildren()) do
            task.spawn(function()
                task.wait(0.1)
                local lower = v.Name:lower()
                if not lower:match('deer') and not lower:match('child') and not lower:match('trader') and not lower:match('horse') and not v:FindFirstChild('NevcitESP') then
                    local success, err = pcall(function()
                        ApplyESP(v, 'NevcitESPAnimal')
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
                        ApplyESP(v, 'NevcitESPAnimal')
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
                                ApplyESP(child, 'NevcitESPItem', 'Chest')
                            end
                            if (key == 'Fuel' or isi == 'Fuel') and (child:GetAttribute('BurnFuel') or child:GetAttribute('FuelBurn')) then
                                ApplyESP(child, 'NevcitESPItem', 'Fuel')
                            end
                            if (key == 'Scrap' or isi == 'Scrap') and child:GetAttribute('Scrappable') then
                                ApplyESP(child, 'NevcitESPItem', 'Scrap')
                            end
                            if (key == 'Tool' or isi == 'Tool') and child:GetAttribute('Interaction') and tostring(child:GetAttribute('Interaction')) == 'Tool' then
                                ApplyESP(child, 'NevcitESPItem', 'Tool')
                            end
                            if (key == 'Ammo' or isi == 'Ammo') and child.Name:lower():match('ammo') then
                                ApplyESP(child, 'NevcitESPItem', 'Ammo')
                            end
                            if (key == 'Food' or isi == 'Food') and child:GetAttribute('RestoreHunger') then
                                ApplyESP(child, 'NevcitESPItem', 'Food')
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
                                ApplyESP(child, 'NevcitESPItem', 'Chest')
                            end
                            if (key == 'Fuel' or isi == 'Fuel') and (child:GetAttribute('BurnFuel') or child:GetAttribute('FuelBurn')) then
                                ApplyESP(child, 'NevcitESPItem', 'Fuel')
                            end
                            if (key == 'Scrap' or isi == 'Scrap') and child:GetAttribute('Scrappable') then
                                ApplyESP(child, 'NevcitESPItem', 'Scrap')
                            end
                            if (key == 'Tool' or isi == 'Tool') and child:GetAttribute('Interaction') and tostring(child:GetAttribute('Interaction')) == 'Tool' then
                                ApplyESP(child, 'NevcitESPItem', 'Tool')
                            end
                            if (key == 'Ammo' or isi == 'Ammo') and child.Name:lower():match('ammo') then
                                ApplyESP(child, 'NevcitESPItem', 'Ammo')
                            end
                            if (key == 'Food' or isi == 'Food') and child:GetAttribute('RestoreHunger') then
                                ApplyESP(child, 'NevcitESPItem', 'Food')
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

local function ActiveEsp123(state)
    MainToggle.ActiveEsp = state
    if MainToggle.ActiveEsp then
        if MainVariable.ActiveEsp then return end
        MainVariable.ActiveEsp = true
        task.spawn(function()
            while EspToggle.Animals or EspToggle.Items do
                task.wait(0.2)
                if EspToggle.Animals and not EspVariable.Animals then
                    EspVariable.Animals = true
                    task.spawn(function()
                        pcall(function()
                            local mobList = GetMob('EspAnimals')
                            local batchSize = 20
                            for i = 1, #mobList, batchSize do
                                for j = i, math.min(i + batchSize - 1, #mobList) do
                                    local v = mobList[j]
                                    if v and not v:FindFirstChild('NevcitESP') then
                                        ApplyESP(v, 'NevcitESPAnimal')
                                    end
                                end
                                task.wait()
                            end
                        end)
                        EspVariable.Animals = false
                    end)
                end
                if EspToggle.Items and not EspVariable.Items then
                    EspVariable.Items = true
                    task.spawn(function()
                        pcall(function()
                            local itemList = GetItem()
                            local batchSize = 10
                            for i = 1, #itemList, batchSize do
                                for j = i, math.min(i + batchSize - 1, #itemList) do
                                    local child = itemList[j]
                                    if not child then continue end
                                    for key, isi in pairs(SelectedItem) do
                                        if (key == 'Chest' or isi == 'Chest') and child.Name:lower():match('chest') and not child:GetAttribute(tostring(LocalPlayer.UserId) .. 'Opened') then
                                            ApplyESP(child, 'NevcitESPItem', 'Chest')
                                        end
                                        if (key == 'Fuel' or isi == 'Fuel') and (child:GetAttribute('BurnFuel') or child:GetAttribute('FuelBurn')) then
                                            ApplyESP(child, 'NevcitESPItem', 'Fuel')
                                        end
                                        if (key == 'Scrap' or isi == 'Scrap') and child:GetAttribute('Scrappable') then
                                            ApplyESP(child, 'NevcitESPItem', 'Scrap')
                                        end
                                        if (key == 'Tool' or isi == 'Tool') and child:GetAttribute('Interaction') and tostring(child:GetAttribute('Interaction')) == 'Tool' then
                                            ApplyESP(child, 'NevcitESPItem', 'Tool')
                                        end
                                        if (key == 'Ammo' or isi == 'Ammo') and child.Name:lower():match('ammo') then
                                            ApplyESP(child, 'NevcitESPItem', 'Ammo')
                                        end
                                        if (key == 'Food' or isi == 'Food') and child:GetAttribute('RestoreHunger') then
                                            ApplyESP(child, 'NevcitESPItem', 'Food')
                                        end
                                    end
                                end
                                task.wait()
                            end
                        end)
                        EspVariable.Items = false
                    end)
                end
            end
        end)
    elseif not EspToggle.Animals and not EspToggle.Items then
        MainVariable.ActiveEsp = false
    end
    if not EspToggle.Animals then
        EspVariable.Animals = false
        for i, v in pairs(workspace.Characters:GetChildren()) do
            task.spawn(function()
                if v:FindFirstChild('NevcitESP') then
                    v.NevcitESP:Destroy()
                end
            end)
        end
    end
    if not EspToggle.Items then
        EspVariable.Items = false
        for i, v in pairs(workspace.Items:GetChildren()) do
            task.spawn(function()
                if v:FindFirstChild('NevcitESP') then
                    v.NevcitESP:Destroy()
                end
            end)
        end
    end
end

local function AddESPAnimals(state)
    EspToggle.Animals = state
    if EspToggle.Animals then
        workspace.StreamingEnabled = false
        for _, child in pairs(workspace.Characters:GetChildren()) do
            task.spawn(function()
                if child:IsA('Model') and not child:FindFirstChild('NevcitESP') and not child.Name:lower():match('child') and not child.Name:lower():match('trader') and not child.Name:lower():match('horse') and not Players:GetPlayerFromCharacter(child) then
                    ApplyESP(child, 'NevcitESPAnimal')
                end
            end)
        end
        EspConnection.Animals = workspace.Characters.ChildAdded:Connect(function(child)
            task.spawn(function()
                if child:IsA('Model') and not child:FindFirstChild('NevcitESP') and not child.Name:lower():match('child') and not child.Name:lower():match('trader') and not child.Name:lower():match('horse') and not Players:GetPlayerFromCharacter(child) then
                    ApplyESP(child, 'NevcitESPAnimal')
                end
            end)
        end)
        EspConnection.AnimalsRemoved = workspace.Characters.ChildRemoved:Connect(function(child)
            task.spawn(function()
                if child:FindFirstChild('NevcitESP') then
                    child.NevcitESP:Destroy()
                end
            end)
        end)
    else
        workspace.StreamingEnabled = true
        if EspConnection.Animals then
            EspConnection.Animals:Disconnect()
            EspConnection.Animals = nil
        end
        if EspConnection.AnimalsRemoved then
            EspConnection.AnimalsRemoved:Disconnect()
            EspConnection.AnimalsRemoved = nil
        end
        for i, v in pairs(workspace.Characters:GetChildren()) do
            if v:FindFirstChild('NevcitESP') then
                v.NevcitESP:Destroy()
            end
        end
    end
end

local function AddESPAnimalsaa(state)
    EspToggle.Animals = state
    if EspToggle.Animals then
        EspConnection.Animals = workspace.Characters.ChildRemoved:Connect(restoreEsp)
        task.spawn(function()
            while EspToggle.Animals do
                if not EspToggle.Animals then
                    break
                end
                if countesp > 10 then
                    task.wait(0.6)
                    countesp = 0
                end
                local success, err = pcall(function()
                    for _, child in pairs(workspace.Characters:GetChildren()) do
                        if child:IsA('Model') and not SavedEspAnimal[child] and not child.Name:lower():match('child') and not child.Name:match('Pelt Trader') and not Players:GetPlayerFromCharacter(child) then
                            local nev = child:FindFirstChild('NevcitESP')
                            local hrp = child:FindFirstChild('HumanoidRootPart')
                            local hum = child:FindFirstChildOfClass('Humanoid')
                            if nev and hrp then
                                local mal = nev:FindFirstChild('NevcitESPAnimal')
                                local tem = nev:FindFirstChild('NevcitESPItem')
                                if not mal and not tem then
                                    ApplyESP(child, 'NevcitESPAnimal')
                                elseif not mal and tem then
                                    tem:Destroy()
                                    ApplyESP(child, 'NevcitESPAnimal')
                                elseif mal and tem then
                                    tem:Destroy()
                                end
                            elseif not nev and hrp then
                                ApplyESP(child, 'NevcitESPAnimal')
                            end
                        end
                    end
                end)
                countesp = countesp + 1
                task.wait()
            end
        end)
    else
        if EspConnection.Animals then
            EspConnection.Animals:Disconnect()
            EspConnection.Animals = nil
        end
        for _, v in pairs(workspace.Characters:GetChildren()) do
            task.spawn(function()
                if v:IsA('Model') and SavedEspAnimal[v] then
                    local nev = v:FindFirstChild('NevcitESP')
                    if nev then
                        nev:Destroy()
                        SavedEspAnimal[v] = nil
                    end
                end
            end)
        end
    end
end

local function AddESPItems(state)
    EspToggle.Items = state
    if EspToggle.Items then
        workspace.StreamingEnabled = false
        for _, child in pairs(workspace.Items:GetChildren()) do
            task.spawn(function()
                if child:IsA('Model') and not child:FindFirstChild('NevcitESP') and not child.Name:lower():match('child') then
                    local distance = (child:GetPivot().Position - workspace.Map.Campground.MainFire.InnerTouchZone.Position).Magnitude
                    if distance < 30 then return end
                    for key, isi in pairs(SelectedItem) do
                        if (key == 'Chest' or isi == 'Chest') and child.Name:lower():match('chest') then
                            ApplyESP(child, 'NevcitESPItem', 'Chest')
                        elseif (key == 'Fuel' or isi == 'Fuel') and (child:GetAttribute('BurnFuel')) then
                            ApplyESP(child, 'NevcitESPItem', 'Fuel')
                        elseif (key == 'Scrap' or isi == 'Scrap') and child:GetAttribute('Scrappable') then
                            ApplyESP(child, 'NevcitESPItem', 'Scrap')
                        elseif (key == 'Tool' or isi == 'Tool') and child:GetAttribute('Interaction') and tostring(child:GetAttribute('Interaction')) == 'Tool' then
                            ApplyESP(child, 'NevcitESPItem', 'Tool')
                        elseif (key == 'Ammo' or isi == 'Ammo') and child.Name:lower():match('ammo') then
                            ApplyESP(child, 'NevcitESPItem', 'Ammo')
                        elseif (key == 'Food' or isi == 'Food') and child:GetAttribute('RestoreHunger') then
                            ApplyESP(child, 'NevcitESPItem', 'Food')
                        end
                    end
                end
            end)
        end
        EspConnection.Items = workspace.Items.ChildAdded:Connect(function(child)
            task.spawn(function()
                if child:IsA('Model') and not child:FindFirstChild('NevcitESP') and not child.Name:lower():match('child') then
                    local distance = (child:GetPivot().Position - workspace.Map.Campground.MainFire.InnerTouchZone.Position).Magnitude
                    if distance < 30 then return end
                    for key, isi in pairs(SelectedItem) do
                        if (key == 'Chest' or isi == 'Chest') and child.Name:lower():match('chest') then
                            ApplyESP(child, 'NevcitESPItem', 'Chest')
                        elseif (key == 'Fuel' or isi == 'Fuel') and (child:GetAttribute('BurnFuel') or child:GetAttribute('FuelBurn')) then
                            ApplyESP(child, 'NevcitESPItem', 'Fuel')
                        elseif (key == 'Scrap' or isi == 'Scrap') and child:GetAttribute('Scrappable') then
                            ApplyESP(child, 'NevcitESPItem', 'Scrap')
                        elseif (key == 'Tool' or isi == 'Tool') and child:GetAttribute('Interaction') and tostring(child:GetAttribute('Interaction')) == 'Tool' then
                            ApplyESP(child, 'NevcitESPItem', 'Tool')
                        elseif (key == 'Ammo' or isi == 'Ammo') and child.Name:lower():match('ammo') then
                            ApplyESP(child, 'NevcitESPItem', 'Ammo')
                        elseif (key == 'Food' or isi == 'Food') and child:GetAttribute('RestoreHunger') then
                            ApplyESP(child, 'NevcitESPItem', 'Food')
                        end
                    end
                end
            end)
        end)
        EspConnection.ItemsRemoved = workspace.Items.ChildRemoved:Connect(function(child)
            task.spawn(function()
                if child:FindFirstChild('NevcitESP') then
                    child.NevcitESP:Destroy()
                end
            end)
        end)
    else
        workspace.StreamingEnabled = true
        if EspConnection.Items then
            EspConnection.Items:Disconnect()
            EspConnection.Items = nil
        end
        if EspConnection.ItemsRemoved then
            EspConnection.ItemsRemoved:Disconnect()
            EspConnection.ItemsRemoved = nil
        end
        for i, v in pairs(workspace.Items:GetChildren()) do
            if v:FindFirstChild('NevcitESP') then
                v.NevcitESP:Destroy()
            end
        end
    end
end

        
local function AddESPItemsaa(state)
    EspToggle.Items = state
    if EspToggle.Items then
        EspConnection.Items = workspace.Items.ChildRemoved:Connect(restoreEsp)
        task.spawn(function()
            while EspToggle.Items do
                if not EspToggle.Items then
                    break
                end
                if countesp > 10 then
                    task.wait(0.7)
                    countesp = 0
                end
                local success, err = pcall(function()
                    for _, child in pairs(workspace.Items:GetChildren()) do
                        if SavedChest[child] then
                            for name, value in pairs(child:GetAttributes()) do
                                if name:lower():match(tostring(LocalPlayer.UserId)) and child:FindFirstChild('NevcitESP') then
                                    child:FindFirstChild('NevcitESP'):Destroy()
                                end
                            end
                        elseif not SavedEsp[child] and child:IsA('Model') and not child.Name:lower():match('child') then
                            local nev = child:FindFirstChild('NevcitESP')
                            if nev then
                                local mal = nev:FindFirstChild('NevcitESPAnimal')
                                local tem = nev:FindFirstChild('NevcitESPItem')
                                for key, isi in pairs(SelectedItem) do
                                    if (key == 'Chest' or isi == 'Chest') and not tem then
                                        if child.Name:lower():match('chest') then
                                            for name, value in pairs(child:GetAttributes()) do
                                                if name:lower():match('open') and nev then
                                                    nev:Destroy()
                                                end
                                            end
                                            if not tem and not mal then
                                                ApplyESP(child, 'NevcitESPItem', 'Chest')
                                            elseif not tem and mal then
                                                mal:Destroy()
                                                ApplyESP(child, 'NevcitESPItem', 'Chest')
                                            elseif tem and mal then
                                                mal:Destroy()
                                            end
                                        end
                                    end
                                end
                            else
                                for key, isi in pairs(SelectedItem) do
                                    if key == 'Fuel' or isi == 'Fuel' then
                                        if child:GetAttribute('BurnFuel') or child:GetAttribute('FuelBurn') then
                                            ApplyESP(child, 'NevcitESPItem', 'Fuel')
                                        end
                                    end
                                    if key == 'Scrap' or isi == 'Scrap' then
                                        if child:GetAttribute('Scrappable') then
                                            if not tem and not mal then
                                                ApplyESP(child, 'NevcitESPItem', 'Scrap')
                                            elseif not tem and mal then
                                                mal:Destroy()
                                                ApplyESP(child, 'NevcitESPItem', 'Scrap')
                                            elseif tem and mal then
                                                mal:Destroy()
                                            end
                                        end
                                    end
                                    if key == 'Tool' or isi == 'Tool' then
                                        if child:GetAttribute('Interaction') and tostring(child:GetAttribute('Interaction')) == 'Tool' then
                                            if not tem and not mal then
                                                ApplyESP(child, 'NevcitESPItem', 'Tool')
                                            elseif not tem and mal then
                                                mal:Destroy()
                                                ApplyESP(child, 'NevcitESPItem', 'Tool')
                                            elseif tem and mal then
                                                mal:Destroy()
                                            end
                                        end
                                    end
                                    if key == 'Chest' or isi == 'Chest' then
                                        if child.Name:lower():match('chest') then
                                            if not tem and not mal then
                                                ApplyESP(child, 'NevcitESPItem', 'Chest')
                                            elseif not tem and mal then
                                                mal:Destroy()
                                                ApplyESP(child, 'NevcitESPItem', 'Chest')
                                            elseif tem and mal then
                                                mal:Destroy()
                                            end
                                        end
                                    end
                                    if key == 'Ammo' or isi == 'Ammo' then
                                        if child.Name:lower():match('ammo') then
                                            if not tem and not mal then
                                                ApplyESP(child, 'NevcitESPItem', 'Ammo')
                                            elseif not tem and mal then
                                                mal:Destroy()
                                                ApplyESP(child, 'NevcitESPItem', 'Ammo')
                                            elseif tem and mal then
                                                mal:Destroy()
                                            end
                                        end
                                    end
                                    if key == 'Food' or isi == 'Food' then
                                        if child:GetAttribute('RestoreHunger') then
                                            ApplyESP(child, 'NevcitESPItem', 'Food')
                                        end
                                    end
                                end
                            end
                        end
                    end
                end)
                countesp = countesp + 1
                task.wait()
            end
        end)
    else
        if EspConnection.Items then
            EspConnection.Items:Disconnect()
            EspConnection.Items = nil
        end
        for _, v in pairs(workspace.Items:GetChildren()) do
            task.spawn(function()
                if v:IsA('Model') and SavedEsp[v] then
                    local nev = v:FindFirstChild('NevcitESP')
                    if nev then
                        nev:Destroy()
                        SavedEsp[v] = nil
                        if SavedChest[v] then
                            SavedChest[v] = nil
                        end
                    end
                end
            end)
        end
        SavedEsp = {}
        SavedChest = {}
    end
end

local function InstantInteract(state)
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

local function CostumWalkSpeed(state)
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

local function NoFog(state)
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

---\ MAIN TABS /---

Tabs.Main:AddDropdown("Select Plant Position", {
    Title = "Select Plant Position",
    Description = "",
    Values = {'Random', 'Player'},
    Multi = false,
    Default = 1,
    Callback = function(Value)
        task.spawn(function()
            PositionPlant = Value
        end)
    end
})

Tabs.Main:AddToggle("Auto Plant Sapling", 
{
    Title = "Auto Plant Sapling",
    Description = "",
    Default = false,
    Callback = function(state)
        task.spawn(function()
            MainToggle.AutoPlant = state
            ActiveAllCode(state)
        end)
    end 
})

Tabs.Main:AddToggle("Auto Cook", 
{
    Title = "Auto Cook",
    Description = "Auto cook raw meat near you",
    Default = false,
    Callback = function(state)
        task.spawn(function()
            MainToggle.AutoCook = state
            ActiveAllCode(state)
        end)
    end 
})

Tabs.Main:AddToggle("Instant Interact", 
{
    Title = "Instant Interact",
    Description = "",
    Default = false,
    Callback = function(state)
        task.spawn(function()
            InstantInteract(state)
        end)
    end 
})

Tabs.Main:AddSlider("Hitbox Size", 
{
    Title = "Hitbox Size",
    Description = "",
    Default = 42,
    Min = 0,
    Max = 100,
    Rounding = 0,
    Callback = function(Value)
        HitboxSize = Value
    end
})

Tabs.Main:AddSlider("Hitbox Transparency", 
{
    Title = "Hitbox Transparency",
    Description = "",
    Default = 0.8,
    Min = 0,
    Max = 1,
    Rounding = 1,
    Callback = function(Value)
        HitboxTransparency = Value
    end
})

Tabs.Main:AddToggle("Active Hitbox Expander", 
{
    Title = "Active Hitbox Expander",
    Description = "",
    Default = false,
    Callback = function(state)
        task.spawn(function()
            HitboxExpander(state)
        end)
    end 
})

Tabs.Main:AddInput("Costum Walk Speed Value", {
    Title = "Costum Walk Speed Value",
    Description = "",
    Default = 30,
    Placeholder = "Type Here",
    Numeric = true, -- Only allows numbers
    Finished = false, -- Only calls callback when you press enter
    Callback = function(Value)
        WalkSpeedValue = Value
    end
})

Tabs.Main:AddToggle("Active Costum Walk Speed", 
{
    Title = "Active Costum Walk Speed",
    Description = "",
    Default = false,
    Callback = function(state)
        task.spawn(function()
            CostumWalkSpeed(state)
        end)
    end 
})

---\ ITEMS TAB /---
Tabs.Item:AddToggle("Fuel Items", 
{
    Title = "Fuel Items",
    Description = "Only Bring Log and Chair",
    Default = false,
    Callback = function(state)
        task.spawn(function()
            BringFuelItems = state
        end)
    end 
})

Tabs.Item:AddToggle("Scrap Items", 
{
    Title = "Scrap Items",
    Description = "",
    Default = false,
    Callback = function(state)
        task.spawn(function()
            BringScrapItems = state
        end)
    end 
})

ScrapperToggle = Tabs.Item:AddToggle("Bring Selected Items To Scrapper", 
{
    Title = "Bring Type Items To Scrapper",
    Description = "",
    Default = false,
    Callback = function(state)
        task.spawn(function()
            MainToggle.Scrapper = state
            ActiveAllCode(state)
        end)
    end 
})

Tabs.Item:AddToggle("Bring Fuel Items To Campfire", 
{
    Title = "Bring Fuel Items To Campfire",
    Description = "Except Log and Chair",
    Default = false,
    Callback = function(state)
        task.spawn(function()
            MainToggle.Campfire = state
            ActiveAllCode(state)
        end)
    end 
})

Tabs.Item:AddToggle("Bring Foods To Campfire", 
{
    Title = "Bring Foods To Campfire",
    Description = "",
    Default = false,
    Callback = function(state)
        task.spawn(function()
            MainToggle.Food = state
            ActiveAllCode(state)
        end)
    end 
})

Tabs.Item:AddButton({
    Title = "Bring Fuel Item",
    Description = "",
    Callback = function()
        BringFuel(LocalPlayer.Character.HumanoidRootPart.Position + Vector3.new(0, 7, 0))
    end
})

Tabs.Item:AddButton({
    Title = "Bring Scrap Item",
    Description = "",
    Callback = function()
        BringScrap(LocalPlayer.Character.HumanoidRootPart.Position + Vector3.new(0, 7, 0), true)
    end
})

Tabs.Item:AddButton({
    Title = "Bring Food",
    Description = "",
    Callback = function()
        BringFood(LocalPlayer.Character.HumanoidRootPart.Position + Vector3.new(0, 7, 0), true)
    end
})

---\ ATTACKAURA TABS /---
Tabs.AttackAura:AddSlider("Range Aura", 
{
    Title = "Range Aura",
    Description = "",
    Default = 50,
    Min = 0,
    Max = 500,
    Rounding = 0,
    Callback = function(Value)
        AuraRange = Value
    end
})

Tabs.AttackAura:AddSlider("Speed", 
{
    Title = "Speed",
    Description = "",
    Default = 0.2,
    Min = 0.1,
    Max = 2,
    Rounding = 1,
    Callback = function(Value)
        Speed = Value
    end
})

Tabs.AttackAura:AddToggle("Multiple Attack", 
{
    Title = "Multiple Attack",
    Description = "May Cause Laggy",
    Default = false,
    Callback = function(state)
        task.spawn(function()
            MultipleAttack = state
        end)
    end 
})

Tabs.AttackAura:AddToggle("Active Kill Aura", 
{
    Title = "Active Kill Aura",
    Description = "",
    Default = false,
    Callback = function(state)
        task.spawn(function()
            MainToggle.KillAura = state
            ActiveAura(state)
        end)
    end 
})

Tabs.AttackAura:AddToggle("Active Tree Aura", 
{
    Title = "Active Tree Aura",
    Description = "",
    Default = false,
    Callback = function(state)
        task.spawn(function()
            MainToggle.TreeAura = state
            ActiveAura(state)
        end)
    end 
})
---\ ESP TABS /---
Tabs.Esp:AddToggle("No Fog", 
{
    Title = "No Fog",
    Description = "",
    Default = false,
    Callback = function(state)
        task.spawn(function()
            NoFog(state)
        end)
    end 
})

Tabs.Esp:AddToggle("ESP Animals", 
{
    Title = "ESP Animals",
    Description = "",
    Default = false,
    Callback = function(state)
        task.spawn(function()
            EspToggle.Animals = state
            ActiveEsp()
        end)
    end 
})

local ItemESP
Tabs.Esp:AddDropdown("Select Type Item", {
    Title = "Select Type Items",
    Description = "",
    Values = {"Ammo", "Chest", "Fuel", "Food", "Tool", "Scrap"},
    Multi = true,
    Default = {},
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
    end
})

ItemESP = Tabs.Esp:AddToggle("ESP Items", 
{
    Title = "ESP Items",
    Description = "",
    Default = false,
    Callback = function(state)
        task.spawn(function()
            EspToggle.Items = state
            ActiveEsp()
        end)
    end 
})

---\\ SETTINGS //----
local toggleproblem = Tabs.Settings:AddSection("Toggle UI Problem")

toggleproblem:AddButton({
    Title = "Toggle UI Dissapear? Click This",
    Description = "",
    Callback = function()
        for _, gui in ipairs(game:GetService("CoreGui"):GetChildren()) do            
            if gui.Name == "Nevcit" then
                gui:Destroy()
            end
        end
        if UI then
            UI:Disconnect()
            UI = nil
        end
        local minimize = game:GetService("CoreGui").FLUENT:GetChildren()[2]
        local size = {35, 35}
        local ScreenGui = Instance.new("ScreenGui", game.CoreGui)       
        ScreenGui.Name = "Nevcit"
        ScreenGui.Enabled = true
        local Button = Instance.new("ImageButton", ScreenGui)
        Button.Image = "rbxassetid://114587443832683"
        Button.Size = UDim2.new(0, size[1], 0, size[2])
        Button.Position = UDim2.new(0.15, 0, 0.15, 0)
        Button.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Button.Active = true
        Button.Draggable = true
        local uistroke = Instance.new("UIStroke", Button)
        uistroke.Thickness = 4
        uistroke.Color = Color3.fromRGB(0, 0, 0)
        UI = Button.MouseButton1Click:Connect(function()
            if minimize.Visible == true then
                minimize.Visible = false
            elseif minimize.Visible == false then
                minimize.Visible = true
            end
        end)
    end
})

SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)

InterfaceManager:SetFolder("GOAHUB")
SaveManager:SetFolder("GOAHUB/Dead-Rails")

InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

-----------------\\ CREDIT //-----------------

Tabs.Credit:AddButton({
    Title = "Youtube Channel",
    Description = "",
    Callback = function()
        setclipboard("https://www.youtube.com/@Nevcit")
        Fluent:Notify({
            Title = "Subcribe For Support Me",
            Content = "",
            SubContent = "", -- Optional
            Duration = 5 -- Set to nil to make the notification not disappear
        })
    end
})

----------------- TOOGLE UI -----------------
