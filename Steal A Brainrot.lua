if alreadyRunGoaHub then
    warn("⚠️ Already run Goa Hub")
    return
end

----\\ Services //----
local repo = "https://raw.githubusercontent.com/Dika2964/Library/refs/heads/main/Obsidian/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua%20(4).txt"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "SaveManager.lua"))()
local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local Net = Packages:WaitForChild("Net")
----\\ Toggles //----
local mainToggle = {
    AutoBuyBrainrot = false,
    AutoBuyGear = false,
    AutoNotification = false,
}
local visualToggle = {
    EspBrainrot = false,
    BaseTransparency = false,
    Dupe = false,
}
----\\ Variables //----
local LocalPlayer = Players.LocalPlayer or game.Players.LocalPlayer
local Backpack = LocalPlayer.Backpack
local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")
local mbr = require(game:GetService("ReplicatedStorage").Datas.Animals)
local rarities = require(game:GetService("ReplicatedStorage").Datas.Rarities)
local gears = require(game:GetService("ReplicatedStorage").Datas.ShopItems)
local selectedName = {}
local selectedNameNotif = {}
local selectedNameEsp = {}
local selectedRarity = {}
local selectedRarityNotif = {}
local selectedRarityEsp = {}
local selectedMerchant = {}
local selectedGen = 100000
local selectedGenNotif = 100000
local selectedGenEsp = 100000
local selectedGear = {}
local promptBr = {}
--- Brainrot Name Data
local brainrot = {}
for key, data in pairs(mbr) do
    if type(data) == "table" and data.DisplayName then
        table.insert(brainrot, data.DisplayName)
    end
end
local seen = {}
local unique = {}
for _, name in ipairs(brainrot) do
    if not seen[name] then
        seen[name] = true
        table.insert(unique, name)
    end
end
brainrot = unique
table.sort(brainrot, function(a, b)
    return a:lower() < b:lower()
end)
local brainrotNames = {}
for i, name in pairs(brainrot) do
    if name then
        table.insert(brainrotNames, name)
    end
end

--- Rarity Brainrot Data
local rarityNames = {}
for name, _ in pairs(rarities) do
    table.insert(rarityNames, name)
end

--- Gear Data
local gearNames = {}
for name, _ in pairs(gears) do
	table.insert(gearNames, name)
end
table.sort(gearNames, function(a, b)
	return a:lower() < b:lower()
end)

--- Merchant Data
local merchantData = {}
local merchantFrame = LocalPlayer.PlayerGui:WaitForChild("Merchant", 5)
if merchantFrame then
    local list = merchantFrame.Merchant.Frame.List:GetChildren()
    for i, v in ipairs(list) do
        if v:IsA("Frame") then
            if v.Name == "Normal" or v.Name == "ToiletTemplate" or v.Name == "ShakeTemplate" then
                table.insert(merchantData, v.Spacer.Txt.Text)
            end
        end
    end
end

----\\ Functions //----
local functions = {}
local runFunctions = {}

functions.TrackPrompt = function(prompt)
    if promptBr[prompt] then return end
    local originalParent = prompt.Parent
    promptBr[prompt] = {}
    promptBr[prompt].Trigger = prompt.Triggered:Connect(function()
        promptBr[prompt].Trigger:Disconnect()
        promptBr[prompt].Ancestry:Disconnect()
        promptBr[prompt] = nil
    end)
    promptBr[prompt].Ancestry = prompt.AncestryChanged:Connect(function(_, parent)
        if parent ~= originalParent then
            promptBr[prompt].Ancestry:Disconnect()
            promptBr[prompt].Triggered:Disconnect()
            promptBr[prompt] = nil
        end
    end)
end

functions.FormatNumber = function(num: number)
    if num >= 1e9 then
        return string.format("%.1fB", num / 1e9)
    elseif num >= 1e6 then
        return string.format("%.1fM", num / 1e6)
    elseif num >= 1e3 then
        return string.format("%.1fK", num / 1e3)
    else
        return tostring(num)
    end
end

functions.GetListMerchant = function()
    local result = {}
    local index = 0
    local merchantFrame = LocalPlayer.PlayerGui:WaitForChild("Merchant", 5)
    if not merchantFrame then return result end

    local list = merchantFrame.Merchant.Frame.List:GetChildren()
    for i, v in ipairs(list) do
        if v:IsA("Frame") then
            if v.Name == "Normal" or v.Name == "ToiletTemplate" or v.Name == "ShakeTemplate" then
                index += 1
                table.insert(result, {
                    Index = index,
                    Brainrot = v.Spacer.Txt.Text,
                    Left = v.Spacer.Left.Txt.Text,
                })
            end
        end
    end

    return result
end

functions.IsAlreadyHaveTrap = function()
    local total = {}
    for _, v in pairs(Backpack:GetChildren()) do
        if v.Name == "Trap" then
            table.insert(total, v)
        end
    end
    if #total >= 5 then
        return true
    end
    return false
end

functions.GetBrainrotMoving = function()
    local list = {}
    for _, v in pairs(workspace:GetChildren()) do
        if not v or typeof(v.GetAttribute) ~= "function" then
            continue
        end
        local index = v:GetAttribute("Index")
        if not index then
            continue
        end
        if v:IsA("Model") then
            local Part = v:FindFirstChild("Part")
            local head = Part and Part:FindFirstChild("Info") and Part.Info:FindFirstChild("AnimalOverhead")
            local mutation = v:GetAttribute("Mutation") and tostring(v:GetAttribute("Mutation")) or nil
            local prompt = Part and Part:FindFirstChild("PromptAttachment") and Part.PromptAttachment:FindFirstChild("ProximityPrompt")
            if head and head:FindFirstChild("DisplayName") and head:FindFirstChild("Rarity") then
                table.insert(list, {
                    Object = v,
                    Name = index or head.DisplayName.Text or "",
                    Rarity = head.Rarity.Text or "",
                    Price = head.Price.Text or "",
                    Generation = head:FindFirstChild("Generation") and head.Generation.Text or "-",
                    Mutation = mutation,
                    Prompt = prompt or nil,
                })
            elseif not Part or not head then
                table.insert(list, {
                    Object = v,
                    Name = index or "-",
                    Rarity = nil,
                    Price = nil,
                    Generation = nil,
                    Mutation = mutation,
                    Prompt = prompt or nil,
                })
            end
        end
    end
    if #list == 0 then
        warn("⚠️ Brainrot Not Found")
        return {}
    end
    return list
end

functions.GetCharacterParts = function()
    character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local humanoid = character:WaitForChild("Humanoid")
    local rootPart = character:WaitForChild("HumanoidRootPart")
    return humanoid, rootPart
end

functions.IsValidBr = function(br)
    return br and br.Object and br.Object.Parent and br.Prompt
end

functions.MatchesFilter = function(br)
    return table.find(selectedRarity, br.Rarity) or table.find(selectedName, br.Name)
end

functions.IsValidBrNotify = function(br)
    return br and br.Object and br.Object.Parent and br.Prompt
end

functions.GetDataBrainrot = function(br, selectRarity, selectName)
    local name = br.Object:GetAttribute("Index") and tostring(br.Object:GetAttribute("Index"))
    for _, v in pairs(mbr) do
        if name and v.DisplayName == name and (table.find(selectRarity, v.Rarity) or table.find(selectName, v.DisplayName)) then
            local data = {
                Name = name,
                Rarity = v.Rarity,
                Generation = "$" .. functions.FormatNumber(v.Generation) .. "/s",
            }
            return data
        end
    end
    return nil
end

functions.AddEsp = function(model, rarity, gen)
    if not model or not model:IsA("Model") then return end
    local primaryPart = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
    if not primaryPart then return end
    local oldGui = model:FindFirstChild("ESP_GUI")
    if oldGui then return end
    local rarityData = rarities[rarity]
    local color = rarityData and rarityData.Color or Color3.fromRGB(255, 255, 255)
    local gradientPreset = rarityData and rarityData.GradientPreset
    
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ESP_GUI"
    billboard.Adornee = primaryPart
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.new(0, 200, 0, 50)
    billboard.StudsOffset = Vector3.new(1, 3, 0)
    billboard.MaxDistance = 200
    
    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(0.7, 0, 0.7, 0)
    bg.BackgroundTransparency = 0.3
    bg.BackgroundColor3 = color
    bg.BorderSizePixel = 0
    bg.Parent = billboard
    bg.ZIndex = 1
	
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = bg
    
    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 2 -- ketebalan outline
    stroke.Transparency = 0.4 -- semakin besar, semakin transparan
    stroke.Color = Color3.fromRGB(0, 0, 0)
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = bg
    
    if gradientPreset then
        local gradient = Instance.new("UIGradient")
        gradient.Name = "ESP_Gradient"
        gradient.Rotation = 0
        
        if gradientPreset == "Rainbow" then
            gradient.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
                ColorSequenceKeypoint.new(0.2, Color3.fromRGB(255, 128, 0)),
                ColorSequenceKeypoint.new(0.4, Color3.fromRGB(255, 255, 0)),
                ColorSequenceKeypoint.new(0.6, Color3.fromRGB(0, 255, 0)),
                ColorSequenceKeypoint.new(0.8, Color3.fromRGB(0, 0, 255)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(128, 0, 255))
            })
            task.spawn(function()
                while gradient.Parent do
                    for i = 0, 1, 0.01 do
                        gradient.Rotation = i * 360
                        task.wait(0.05)
                    end
                end
            end)
        elseif gradientPreset == "Zebra" then
            gradient.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255,255,255)),
                ColorSequenceKeypoint.new(0.5, Color3.fromRGB(44,44,44)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(255,255,255))
            })
        elseif gradientPreset == "YellowRed" then
            gradient.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255,255,0)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(255,0,0))
            })
        elseif gradientPreset == "OG" then
            gradient.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255,255,255)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(0,255,0))
            })
        end
		
        gradient.Parent = bg
    end
    
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = tostring(model:GetAttribute("Index")) .. " [" .. (rarity or "-") .. "]\nGen : " .. gen
    textLabel.Font = Enum.Font.GothamBold
    textLabel.TextScaled = false
    textLabel.TextSize = 10
    textLabel.TextWrapped = true
    textLabel.TextColor3 = Color3.new(1, 1, 1)
    textLabel.TextStrokeTransparency = 0.5
    textLabel.Parent = bg
    textLabel.ZIndex = 2
    billboard.Parent = model
end
    
runFunctions.AutoBuy = function(state)
    if state and not mainToggle.AutoBuyBrainrot then
        mainToggle.AutoBuyBrainrot = true
        print("▶️ Auto Buy Brainrot started...")

        task.spawn(function()
            local Players = game:GetService("Players")
            local PathfindingService = game:GetService("PathfindingService")
            local LocalPlayer = Players.LocalPlayer
            local humanoid, rootPart = functions.GetCharacterParts()
            local currentTarget, targetInfo
            local lastTargetPos
            local predictedSpeed = 12
            local recomputeDelay = 0.6
            local currentPromptConn -- koneksi ke prompt.Triggered

            while mainToggle.AutoBuyBrainrot do
                local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
                if not character or not character.Parent then
                    humanoid, rootPart = functions.GetCharacterParts()
                end

                -- 🧭 Cari target baru
                if not currentTarget or not currentTarget.Parent then
                    local list = functions.GetBrainrotMoving()
                    local nearestTarget, nearestDistance = nil, math.huge

                    for _, br in ipairs(list) do
                        if promptBr[br.Prompt] then continue end
                        if not promptBr[br.Prompt] and functions.IsValidBr(br) and functions.MatchesFilter(br) and br.Prompt then
                            local part = br.Object.PrimaryPart or br.Object:FindFirstChildWhichIsA("BasePart") or br.Object:GetPivot()
                            if part then
                                local dist = (rootPart.Position - part.Position).Magnitude
                                if dist < nearestDistance then
                                    nearestTarget = br
                                    nearestDistance = dist
                                end
                            end
                        end
                    end

                    if nearestTarget then
                        currentTarget = nearestTarget.Object
                        targetInfo = nearestTarget
                        lastTargetPos = currentTarget.PrimaryPart and currentTarget.PrimaryPart.Position
                    else
                        task.wait(1)
                        continue
                    end
                end

                local targetPart = currentTarget.PrimaryPart or currentTarget:FindFirstChildWhichIsA("BasePart") or currentTarget:GetPivot()
                if not targetPart then
                    currentTarget = nil
                    task.wait(0.5)
                    continue
                end

                local dist = (rootPart.Position - targetPart.Position).Magnitude
                local basePrediction = 1
                local predictionTime = math.clamp(basePrediction + (dist / 30), 1, 4)
                local currentPos = targetPart.Position
                local predictedPos = currentPos

                if lastTargetPos then
                    local delta = currentPos - lastTargetPos
                    if delta.Magnitude > 0.05 then
                        predictedPos = currentPos + delta.Unit * predictedSpeed * predictionTime
                    end
                end
                lastTargetPos = currentPos

                if dist > 300 then
                    print("📡 Target too far, finding new one...")
                    currentTarget = nil
                    task.wait(0.5)
                    continue
                end

                if not rootPart or not rootPart.Parent then
                    humanoid, rootPart = functions.GetCharacterParts()
                    continue
                end

                local path = PathfindingService:CreatePath({
                    AgentRadius = 2,
                    AgentHeight = 5,
                    AgentCanJump = true
                })
                path:ComputeAsync(rootPart.Position, predictedPos)

                if path.Status ~= Enum.PathStatus.Success then
                    task.wait(0.5)
                    continue
                end
                for _, wp in ipairs(path:GetWaypoints()) do
                    if promptBr[targetInfo.Prompt] then break end
                    if not mainToggle.AutoBuyBrainrot then return end
                    if wp.Action == Enum.PathWaypointAction.Jump then
                        humanoid.Jump = true
                    end
                    humanoid:MoveTo(wp.Position)
                    humanoid.MoveToFinished:Wait()

                    local nearDist = (rootPart.Position - targetPart.Position).Magnitude
                    if nearDist < 6 and targetInfo and targetInfo.Prompt then
                        local success, err = pcall(function()
                            fireproximityprompt(targetInfo.Prompt)
                        end)
                        if success then
                            local prompt = targetInfo.Prompt
                            promptBr[prompt] = {}
                            local originalParent = prompt.Parent
                            promptBr[prompt].Ancestry = prompt.AncestryChanged:Connect(function(_, parent)
                                if not parent or parent ~= originalParent then
                                    promptBr[prompt].Ancestry:Disconnect()
                                    promptBr[prompt] = nil
                                end
                            end)
                            print("Prompt triggered, changed object....")
                            break
                        end
                        task.wait(0.3)
                    end
                end

                task.wait(recomputeDelay)
            end

            -- 🧹 Bersihkan koneksi prompt jika toggle dimatikan
        end)

    else
        mainToggle.AutoBuyBrainrot = false
        print("🛑 Auto Buy Brainrot stopped.")
    end
end

runFunctions.AutoBuyGear = function(state)
    mainToggle.AutoBuyGear = state
    if not state then return end
    task.spawn(function()
        local alreadyBuyGear = {}
        local RFCoinsShopServiceRequestBuy = ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Net"):WaitForChild("RF/CoinsShopService/RequestBuy")
        while mainToggle.AutoBuyGear do
            -- buat salinan selectedGear biar aman kalau dropdown berubah
            local currentSelection = {}
            for i, g in pairs(selectedGear) do
                currentSelection[i] = g
            end
            
            for _, gear in pairs(currentSelection) do
                if typeof(gear) == "string" and gear == "Trap" and not functions.IsAlreadyHaveTrap() then
                    local success, err = pcall(function()
                        RFCoinsShopServiceRequestBuy:InvokeServer(gear)
                    end)
                    if success and Backpack:FindFirstChild(gear) then
                        Library:Notify("Success Buy Gear " .. gear, 2)
                    elseif success and not Backpack:FindFirstChild(gear) then
                        Library:Notify("Failed Buy Gear " .. gear .. " Because Required Rebirth Not Achieved", 3)
                    elseif not success then
                        warn("❌ Failed Buy Gear:", gear, err)
                    end
                    task.wait(0.35)
                elseif typeof(gear) == "string" and gear ~= "" and not alreadyBuyGear[gear] then
                    local success, err = pcall(function()
                        RFCoinsShopServiceRequestBuy:InvokeServer(gear)
                    end)
                    if success and Backpack:FindFirstChild(gear) then
                        Library:Notify("Success Buy Gear " .. gear, 2)
                        alreadyBuyGear[gear] = true
                    elseif success and not Backpack:FindFirstChild(gear) then
                        Library:Notify("Failed Buy Gear " .. gear .. " Because Required Rebirth Not Achieved", 3)
                        alreadyBuyGear[gear] = true
                    elseif not success then
                        warn("❌ Failed Buy Gear:", gear, err)
                    end
                    task.wait(0.5) -- kasih jeda aman
                end
            end
            
            task.wait(1)
        end
    end)
end

runFunctions.AutoNotification = function(state)
    mainToggle.AutoNotification = state
    if mainToggle.AutoNotification then
        local alreadyNotifyBrainrot = {}
        task.spawn(function()
            local success, err = pcall(function()
                while mainToggle.AutoNotification do
                    local list = functions.GetBrainrotMoving()
                    local success, err = pcall(function()
                        for _, br in ipairs(list) do
                            if alreadyNotifyBrainrot[br.Object] then continue end
                            if functions.IsValidBrNotify(br) and functions.GetDataBrainrot(br, selectedRarityNotif, selectedNameNotif) then
                                local data = functions.GetDataBrainrot(br, selectedRarityNotif, selectedNameNotif)
                                local gen = br.Generation or data.Generation
                                local price = br.Price or data.Price
                                local mutation = br.Mutation
                                local desc = "Name : " .. data.Name .. "\n"
                                if gen then
                                    desc = desc .. "Gen : " .. gen .. "\n"
                                end
                                if price then
                                    desc = desc .. "Price : " .. price .. "\n"
                                end
                                if mutation then
                                    desc = desc .. "Mutation : " .. mutation .. "\n"
                                end
                                Library:Notify({
                                    Title = data.Rarity .. " Brainrot Spawned!!",
                                    Description = desc,
                                    Time = 5, -- Duration in seconds
                                })
                                alreadyNotifyBrainrot[br.Object] = {
                                    Event = br.Object:GetPropertyChangedSignal("Parent"):Connect(function()
                                        alreadyNotifyBrainrot[br.Object].Event:Disconnect()
                                        alreadyNotifyBrainrot[br.Object] = nil
                                    end)
                                }
                                task.wait(0.5)
                            end
                        end
                    end)
                    if not success then
                        warn("Auto Notification Error : ", err)
                    end
                    task.wait(0.2)
                end
            end)
            if not success then
                warn(err)
            end
        end)
    end
end

runFunctions.EspBrainrot = function(state)
    visualToggle.EspBrainrot = state
    if visualToggle.EspBrainrot then
        local alreadyEspBrainrot = {}
        task.spawn(function()
            local success, err = pcall(function()
                while visualToggle.EspBrainrot do
                    local list = functions.GetBrainrotMoving()
                    local success, err = pcall(function()
                        for _, br in ipairs(list) do
                            if alreadyEspBrainrot[br.Object] then continue end
                            if functions.IsValidBrNotify(br) and functions.GetDataBrainrot(br, selectedRarityEsp, selectedNameEsp) then
                                local data = functions.GetDataBrainrot(br, selectedRarityEsp, selectedNameEsp)
                                local gen = br.Generation or data.Generation or "0"
                                local brainrot = br.Object
                                functions.AddEsp(brainrot, data.Rarity, gen)
                                alreadyEspBrainrot[brainrot] = {
                                    Event = brainrot.AncestryChanged:Connect(function()
                                        alreadyNotifyBrainrot[brainrot].Event:Disconnect()
                                        alreadyNotifyBrainrot[brainrot] = nil
                                    end)
                                }
                                task.wait(0.5)
                            end
                        end
                    end)
                    if not success then
                        warn("Esp Brainrot Error : ", err)
                    end
                    task.wait(0.2)
                end
            end)
            if not success then
                warn(err)
            end
        end)
    else
        for _, v in pairs(workspace:GetChildren()) do
            if v:IsA("Model") and v:FindFirstChild("ESP_GUI") then
                v.ESP_GUI:Destroy()
            end
        end
    end
end

runFunctions.AutoBuyMerchant = function(state)
    mainToggle.AutoBuyMerchant = state
    if mainToggle.AutoBuyMerchant then
        task.spawn(function()
            local buy = Net:FindFirstChild("RF/MerchantService/Buy")
            local uuid = "2298b248-44dd-4a34-bbfe-e1174e8ae1b4"

            while mainToggle.AutoBuyMerchant do
                local getList = functions.GetListMerchant()
                if buy and #getList > 0 then
                    for _, v in ipairs(getList) do
                        task.spawn(function()
                            if v.Index and v.Left ~= "SOLD OUT" and table.find(selectedMerchant, v.Brainrot) then
                                print("TRYING BUY MERCHANT")
                                pcall(function()
                                    buy:InvokeServer(uuid, v.Index)
                                end)
                            end
                        end)
                    end
                end
                task.wait(0.5)
            end
        end)
    end
end

local Options = Library.Options
local Toggles = Library.Toggles

local Window = Library:CreateWindow({
    Title = "Goa Hub",
    Footer = "Steal a Brainrot",
    Icon = 95816097006870,
    NotifySide = "Right",
    ShowCustomCursor = false,
})

local Tabs = {
    Main = Window:AddTab("Main", "user"),
    Visual = Window:AddTab("Visual", "eye"),
    Settings = Window:AddTab("Settings", "settings"),
}

local brainrot = Tabs.Main:AddRightGroupbox("Brainrot Shop", "money")

brainrot:AddDropdown("BrainrotNameShop", {
    Values = brainrotNames,
    Default = {""},
    Multi = true, -- true / false, allows multiple choices to be selected
    Searchable = true,
    Text = "Select Brainrot Name",
    Callback = function(Value)
        selectedName = {}
        for key, value in next, Options.BrainrotNameShop.Value do
            if value then
                table.insert(selectedName, key)
            end
        end
    end,
})


brainrot:AddDropdown("RarityBrainrotShop", {
    Values = rarityNames,
    Default = {""},
    Multi = true, -- true / false, allows multiple choices to be selected
    Searchable = true,
    Text = "Select Rarity Brainrot",
    Callback = function(Value)
        selectedRarity = {}
        for key, value in next, Options.RarityBrainrotShop.Value do
            if value then
                table.insert(selectedRarity, key)
            end
        end
    end,
})

brainrot:AddToggle("AutoBuyBrainrot", {
    Text = "Auto Buy",
    Default = false,
    Disabled = false,
    Visible = true,
    Callback = function(Value)
        task.spawn(function()
            runFunctions.AutoBuy(Value)
        end)
    end,
})

local gear = Tabs.Main:AddRightGroupbox("Gear Shop", "hammer")

gear:AddDropdown("GearName", {
    Values = gearNames,
    Default = {""},
    Multi = true, -- true / false, allows multiple choices to be selected
    Searchable = true,
    Text = "Select Gear",
    Callback = function(Value)
        selectedGear = {}
        for key, value in next, Options.GearName.Value do
            if value then
                table.insert(selectedGear, key)
            end
        end
        print("SelectedGear:", selectedGear)
        for i,v in ipairs(selectedGear) do
            print(i, v)
        end
    end,
})

gear:AddToggle("AutoBuyGear", {
    Text = "Auto Buy",
    Default = false,
    Disabled = false,
    Visible = true,
    Callback = function(Value)
        task.spawn(function()
            runFunctions.AutoBuyGear(Value)
        end)
    end,
})

local notify = Tabs.Main:AddLeftGroupbox("Notify Brainrot", "bell")

notify:AddDropdown("BrainrotNotify", {
    Values = brainrotNames,
    Default = {""},
    Multi = true, -- true / false, allows multiple choices to be selected
    Searchable = true,
    Text = "Select Brainrot Name",
    Callback = function(Value)
        selectedNameNotif = {}
        for key, value in next, Options.BrainrotNotify.Value do
            if value then
                table.insert(selectedNameNotif, key)
            end
        end
    end,
})


notify:AddDropdown("RarityNotify", {
    Values = rarityNames,
    Default = {""},
    Multi = true, -- true / false, allows multiple choices to be selected
    Searchable = true,
    Text = "Select Rarity Brainrot",
    Callback = function(Value)
        selectedRarityNotif = {}
        for key, value in next, Options.RarityNotify.Value do
            if value then
                table.insert(selectedRarityNotif, key)
            end
        end
    end,
})

notify:AddToggle("AutoNotification", {
    Text = "Auto Notification",
    Default = false,
    Disabled = false,
    Visible = true,
    Callback = function(Value)
        task.spawn(function()
            runFunctions.AutoNotification(Value)
        end)
    end,
})

local merchant = Tabs.Main:AddLeftGroupbox("Brainrot Dealer", "")

merchant:AddDropdown("MerchantName", {
    Values = merchantData,
    Default = {""},
    Multi = true, -- true / false, allows multiple choices to be selected
    Searchable = true,
    Text = "Select Brainrot",
    Callback = function(Value)
        selectedMerchant = {}
        for key, value in next, Options.MerchantName.Value do
            if value then
                table.insert(selectedMerchant, key)
            end
        end
    end,
})

merchant:AddToggle("AutoBuyMerchant", {
    Text = "Auto Buy",
    Default = false,
    Disabled = false,
    Visible = true,
    Callback = function(Value)
        task.spawn(function()
            runFunctions.AutoBuyMerchant(Value)
        end)
    end,
})

local esp = Tabs.Visual:AddLeftGroupbox("ESP", "eyes")

esp:AddDropdown("BrainrotEsp", {
    Values = brainrotNames,
    Default = {""},
    Multi = true, -- true / false, allows multiple choices to be selected
    Searchable = true,
    Text = "Select Brainrot Name",
    Callback = function(Value)
        selectedNameEsp = {}
        for key, value in next, Options.BrainrotEsp.Value do
            if value then
                table.insert(selectedNameEsp, key)
            end
        end
    end,
})


esp:AddDropdown("RarityEsp", {
    Values = rarityNames,
    Default = {""},
    Multi = true, -- true / false, allows multiple choices to be selected
    Searchable = true,
    Text = "Select Rarity Brainrot",
    Callback = function(Value)
        selectedRarityEsp = {}
        for key, value in next, Options.RarityEsp.Value do
            if value then
                table.insert(selectedRarityEsp, key)
            end
        end
    end,
})

esp:AddToggle("EspBrainrot", {
    Text = "Active Esp Brainrot",
    Default = false,
    Disabled = false,
    Visible = true,
    Callback = function(Value)
        task.spawn(function()
            runFunctions.EspBrainrot(Value)
        end)
    end,
})

local MenuGroup = Tabs.Settings:AddLeftGroupbox("Menu", "wrench")

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
MenuGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", { Default = "RightShift", NoUI = true, Text = "Menu keybind" })
MenuGroup:AddButton("Unload", function()
    Library:Unload()
end)

Library.ToggleKeybind = Options.MenuKeybind

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })

ThemeManager:SetFolder("GoaHub")
SaveManager:SetFolder("GoaHub/sab")
SaveManager:BuildConfigSection(Tabs.Settings)
ThemeManager:ApplyToTab(Tabs.Settings)
SaveManager:LoadAutoloadConfig()

Library:SetFont(Enum.Font.GothamBold)
getgenv().alreadyRunGoaHub = true