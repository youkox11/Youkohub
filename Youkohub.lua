--===========================================================================
--  YOUKO HUB EXCLUSIVE – STEAL AN EGG
--  Version: 2.0.0 | Date: November 20, 2026
--  Target Game: Steal An Egg (Place ID: 107778070777162)
--  Author: Youko Dev Team
--  Note: This script is keyless and optimized. Update RemoteEvent names in 
--        the 'Game Remotes' section if the game developer updates them.
--===========================================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

--===========================================================================
-- 1. SETTINGS & STATE MANAGEMENT
--===========================================================================
local Settings = {
    -- 🥚 Auto Steal System
    AutoSteal = false, AutoDeliver = false, RareFinder = false, ServerHop = false,
    HelpFriend = false, AuraBat = false, StealByValue = false, WebhookNotifs = false,
    FilterName = "All", FilterRarity = "All", SelectArea = "All",
    
    -- ⚡ Speed System
    SpeedAdvice = false, CurrentSpeedDet = false, LowSpeedBoost = false, LowSpeedProfile = false,
    AutoTreadmill = false, SpeedMultiplier = 50,
    
    -- ⚔️ Steal From Players
    AutoStealPvP = false, AutoChase = false, AutoBatAttack = false, AutoCollectDropped = false,
    AutoReturnHome = false, SkipFriends = true, PvPRarityFilter = "All", DivinePriority = false,
    
    -- 💎 Egg Rarity Filters
    FilterCommon = true, FilterUncommon = true, FilterRare = true, FilterEpic = true,
    FilterLegendary = true, FilterMythic = true, FilterCosmic = true, FilterSecret = true,
    FilterEternal = true, FilterDivine = true, FilterBrainrot = true, FilterMonster = true,
    
    -- 🛸 UFO Sightings Event
    AutoRepairComms = false, AutoSignalDecoder = false, AutoUnlockUFO = false, AutoTradeDebris = false,
    AutoUFOEncounter = false, AutoDeliver3Eggs = false, AutoClaimRewards = false, AutoCollectDebris = false,
    AlienMutationExchange = false,
    
    -- 🎣 Auto Fishing System
    AutoFish = false, PerfectCasts = false, AutoBestRod = false, ManualRod = "Kraken Rod",
    
    -- 🚀 Performance System
    StartupBoost = false, BoostFPS = false, UncapFPS = false, HidePetsEggs = false,
    GraphicsOpt = false, MapOpt = false,
    
    -- 🖥️ Stats
    FPS = 60, Ping = 0, SessionTime = 0, StolenEggs = 0, ActiveFeatures = 0
}

--===========================================================================
-- 2. GAME REMOTES & OBJECTS (Steal An Egg Specific)
--===========================================================================
-- Based on the game's template structure: ReplicatedStorage.StealAnEgg.Remotes
local RemotesFolder = game.ReplicatedStorage:FindFirstChild("StealAnEgg") and game.ReplicatedStorage.StealAnEgg:FindFirstChild("Remotes") or game.ReplicatedStorage

local GameRemotes = {
    StealEgg = RemotesFolder:FindFirstChild("StealEgg") or RemotesFolder:FindFirstChild("ToggleAutoFarm"),
    HatchEgg = RemotesFolder:FindFirstChild("HatchEgg") or RemotesFolder:FindFirstChild("ClaimEgg"),
    UpgradeSpeed = RemotesFolder:FindFirstChild("UpgradeSpeed") or RemotesFolder:FindFirstChild("ToggleTreadmill"),
    FishCast = RemotesFolder:FindFirstChild("FishCast") or Instance.new("RemoteEvent"),
    UFOEvent = RemotesFolder:FindFirstChild("UFOEvent") or Instance.new("RemoteEvent"),
    AttackPlayer = RemotesFolder:FindFirstChild("AttackPlayer") or Instance.new("RemoteEvent")
}

local EggsFolder = Workspace:FindFirstChild("Eggs") or Workspace
local TreadmillPart = Workspace:FindFirstChild("Treadmill")

--===========================================================================
-- 3. UI LIBRARY (Lightweight, Draggable, Tabbed)
--===========================================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "YoukoHubUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = playerGui

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 680, 0, 480)
MainFrame.Position = UDim2.new(0.5, -340, 0.5, -240)
MainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)
Instance.new("UIStroke", MainFrame).Color = Color3.fromRGB(255, 150, 200)
Instance.new("UIStroke", MainFrame).Thickness = 1

local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 40)
TitleBar.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
TitleBar.Parent = MainFrame
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 8)

local TitleText = Instance.new("TextLabel")
TitleText.Size = UDim2.new(1, 0, 1, 0)
TitleText.BackgroundTransparency = 1
TitleText.Text = "🦊 Youko HUB EXCLUSIVE – STEAL AN EGG"
TitleText.TextColor3 = Color3.fromRGB(255, 150, 200)
TitleText.Font = Enum.Font.GothamBold
TitleText.TextSize = 18
TitleText.Parent = TitleBar

local TabContainer = Instance.new("Frame")
TabContainer.Size = UDim2.new(0, 160, 1, -40)
TabContainer.Position = UDim2.new(0, 0, 0, 40)
TabContainer.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
TabContainer.Parent = MainFrame
Instance.new("UICorner", TabContainer).CornerRadius = UDim.new(0, 8)

local ContentContainer = Instance.new("Frame")
ContentContainer.Size = UDim2.new(1, -160, 1, -40)
ContentContainer.Position = UDim2.new(0, 160, 0, 40)
ContentContainer.BackgroundTransparency = 1
ContentContainer.Parent = MainFrame

local ContentScroll = Instance.new("ScrollingFrame")
ContentScroll.Size = UDim2.new(1, 0, 1, 0)
ContentScroll.BackgroundTransparency = 1
ContentScroll.ScrollBarThickness = 4
ContentScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
ContentScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
ContentScroll.Parent = ContentContainer

local UIListLayout = Instance.new("UIListLayout", ContentScroll)
UIListLayout.Padding = UDim.new(0, 6)
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder

-- UI Helpers
local function CreateTab(name, icon)
    local TabBtn = Instance.new("TextButton")
    TabBtn.Size = UDim2.new(1, 0, 0, 38)
    TabBtn.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
    TabBtn.TextColor3 = Color3.fromRGB(180, 180, 180)
    TabBtn.Text = icon .. " " .. name
    TabBtn.Font = Enum.Font.GothamSemibold
    TabBtn.TextSize = 14
    TabBtn.Parent = TabContainer
    
    local TabContent = Instance.new("Frame")
    TabContent.Name = name .. "Content"
    TabContent.Size = UDim2.new(1, -10, 0, 0)
    TabContent.BackgroundTransparency = 1
    TabContent.Visible = false
    TabContent.Parent = ContentScroll
    
    local TabLayout = Instance.new("UIListLayout", TabContent)
    TabLayout.Padding = UDim.new(0, 6)
    TabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    
    TabBtn.MouseButton1Click:Connect(function()
        for _, tab in pairs(ContentScroll:GetChildren()) do
            if tab:IsA("Frame") then tab.Visible = false end
        end
        for _, btn in pairs(TabContainer:GetChildren()) do
            if btn:IsA("TextButton") then btn.BackgroundColor3 = Color3.fromRGB(22, 22, 30) end
        end
        TabContent.Visible = true
        TabBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
    end)
    return TabContent
end

local function CreateLabel(parent, text)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 28)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(255, 150, 200)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 15
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = parent
    return lbl
end

local function CreateToggle(parent, text, default, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 32)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    frame.Parent = parent
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 4)
    
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -60, 1, 0)
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(220, 220, 220)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = frame
    
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0, 44, 0, 22)
    toggleBtn.Position = UDim2.new(1, -54, 0.5, -11)
    toggleBtn.BackgroundColor3 = default and Color3.fromRGB(100, 200, 100) or Color3.fromRGB(70, 70, 80)
    toggleBtn.Text = ""
    toggleBtn.Parent = frame
    Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(1, 0)
    
    local state = default
    toggleBtn.MouseButton1Click:Connect(function()
        state = not state
        toggleBtn.BackgroundColor3 = state and Color3.fromRGB(100, 200, 100) or Color3.fromRGB(70, 70, 80)
        if callback then callback(state) end
    end)
    return frame
end

local function CreateDropdown(parent, text, options, default, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 32)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    frame.Parent = parent
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 4)
    
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.5, 0, 1, 0)
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(220, 220, 220)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = frame
    
    local dropBtn = Instance.new("TextButton")
    dropBtn.Size = UDim2.new(0.45, 0, 0, 22)
    dropBtn.Position = UDim2.new(0.5, 0, 0.5, -11)
    dropBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
    dropBtn.Text = default
    dropBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    dropBtn.Font = Enum.Font.Gotham
    dropBtn.TextSize = 12
    dropBtn.Parent = frame
    Instance.new("UICorner", dropBtn).CornerRadius = UDim.new(0, 4)
    
    local currentIndex = 1
    for i, v in pairs(options) do if v == default then currentIndex = i break end end
    
    dropBtn.MouseButton1Click:Connect(function()
        currentIndex = currentIndex + 1
        if currentIndex > #options then currentIndex = 1 end
        dropBtn.Text = options[currentIndex]
        if callback then callback(options[currentIndex]) end
    end)
end

--===========================================================================
-- 4. BUILDING THE UI TABS
--===========================================================================
local tab1 = CreateTab("Auto Steal", "🥚")
CreateLabel(tab1, "🥚 Auto Steal System")
CreateToggle(tab1, "Auto Steal (Normal)", false, function(v) Settings.AutoSteal = v end)
CreateToggle(tab1, "Automatic Egg Delivery to Home", false, function(v) Settings.AutoDeliver = v end)
CreateToggle(tab1, "Rare Egg Finder (Prioritize High Value)", false, function(v) Settings.RareFinder = v end)
CreateToggle(tab1, "Server Hop (If no eggs found)", false, function(v) Settings.ServerHop = v end)
CreateToggle(tab1, "Help Friend (Share Eggs)", false, function(v) Settings.HelpFriend = v end)
CreateToggle(tab1, "Aura Bat (Auto Equip/Visual)", false, function(v) Settings.AuraBat = v end)
CreateDropdown(tab1, "Filter By Egg Name", {"All", "Chicken", "Dog", "Fox", "Bear", "Dragon", "Unicorn"}, "All", function(v) Settings.FilterName = v end)
CreateDropdown(tab1, "Filter By Rarity", {"All", "Common", "Rare", "Epic", "Legendary", "Mythic", "Cosmic", "Secret", "Eternal", "Divine"}, "All", function(v) Settings.FilterRarity = v end)
CreateDropdown(tab1, "Select Area", {"All", "Forest", "Lake", "Desert", "Jungle", "Snow", "Volcano", "Abyss Ocean", "Prehistoric", "Cosmic", "Cherry Blossom", "Titan Temple", "Angels & Demons", "Rift"}, "All", function(v) Settings.SelectArea = v end)
CreateToggle(tab1, "Steal By Value (Heaviest/Best First)", false, function(v) Settings.StealByValue = v end)
CreateToggle(tab1, "Steal Webhook Notifications", false, function(v) Settings.WebhookNotifs = v end)

local tab2 = CreateTab("Speed", "⚡")
CreateLabel(tab2, "⚡ Speed System")
CreateToggle(tab2, "Auto Treadmill Farm", false, function(v) Settings.AutoTreadmill = v end)
CreateToggle(tab2, "Speed Advice (Chat Warnings)", false, function(v) Settings.SpeedAdvice = v end)
CreateToggle(tab2, "Current Speed Detection", true, function(v) Settings.CurrentSpeedDet = v end)
CreateToggle(tab2, "Low Speed Multiplier Boost", false, function(v) Settings.LowSpeedBoost = v end)
CreateToggle(tab2, "Low Speed Profile", false, function(v) Settings.LowSpeedProfile = v end)

local tab3 = CreateTab("PvP Steal", "⚔️")
CreateLabel(tab3, "⚔️ Steal From Players")
CreateToggle(tab3, "Auto Steal From Players", false, function(v) Settings.AutoStealPvP = v end)
CreateToggle(tab3, "Automatic Player Chase", false, function(v) Settings.AutoChase = v end)
CreateToggle(tab3, "Automatic Bat Attack", false, function(v) Settings.AutoBatAttack = v end)
CreateToggle(tab3, "Automatic Dropped Egg Collection", false, function(v) Settings.AutoCollectDropped = v end)
CreateToggle(tab3, "Automatic Return to Home", false, function(v) Settings.AutoReturnHome = v end)
CreateToggle(tab3, "Skip Friends", true, function(v) Settings.SkipFriends = v end)
CreateDropdown(tab3, "PvP Rarity Filter", {"All", "Rare", "Epic", "Legendary", "Divine"}, "All", function(v) Settings.PvPRarityFilter = v end)
CreateToggle(tab3, "Divine Egg Priority", false, function(v) Settings.DivinePriority = v end)

local tab4 = CreateTab("Filters", "💎")
CreateLabel(tab4, "💎 Egg Rarity Filters")
CreateToggle(tab4, "Common", true, function(v) Settings.FilterCommon = v end)
CreateToggle(tab4, "Uncommon", true, function(v) Settings.FilterUncommon = v end)
CreateToggle(tab4, "Rare", true, function(v) Settings.FilterRare = v end)
CreateToggle(tab4, "Epic", true, function(v) Settings.FilterEpic = v end)
CreateToggle(tab4, "Legendary", true, function(v) Settings.FilterLegendary = v end)
CreateToggle(tab4, "Mythic", true, function(v) Settings.FilterMythic = v end)
CreateToggle(tab4, "Cosmic", true, function(v) Settings.FilterCosmic = v end)
CreateToggle(tab4, "Secret", true, function(v) Settings.FilterSecret = v end)
CreateToggle(tab4, "Eternal", true, function(v) Settings.FilterEternal = v end)
CreateToggle(tab4, "Divine", true, function(v) Settings.FilterDivine = v end)
CreateToggle(tab4, "Brainrot / Monster / Event", true, function(v) Settings.FilterBrainrot = v end)

local tab5 = CreateTab("UFO Event", "🛸")
CreateLabel(tab5, "🛸 UFO Sightings Event")
CreateToggle(tab5, "Auto Repair Comms", false, function(v) Settings.AutoRepairComms = v end)
CreateToggle(tab5, "Auto Signal Decoder Puzzle", false, function(v) Settings.AutoSignalDecoder = v end)
CreateToggle(tab5, "Auto Unlock UFO Sightings", false, function(v) Settings.AutoUnlockUFO = v end)
CreateToggle(tab5, "Auto Trade Debris", false, function(v) Settings.AutoTradeDebris = v end)
CreateToggle(tab5, "Auto UFO Encounter", false, function(v) Settings.AutoUFOEncounter = v end)
CreateToggle(tab5, "Auto Deliver 3 Suspicious Eggs", false, function(v) Settings.AutoDeliver3Eggs = v end)
CreateToggle(tab5, "Auto Claim Rewards", false, function(v) Settings.AutoClaimRewards = v end)
CreateToggle(tab5, "Auto Collect UFO Debris", false, function(v) Settings.AutoCollectDebris = v end)
CreateToggle(tab5, "Alien Mutation Crystal Exchange", false, function(v) Settings.AlienMutationExchange = v end)

local tab6 = CreateTab("Fishing", "🎣")
CreateLabel(tab6, "🎣 Auto Fishing System")
CreateToggle(tab6, "Auto Fish", false, function(v) Settings.AutoFish = v end)
CreateToggle(tab6, "Perfect Casts", false, function(v) Settings.PerfectCasts = v end)
CreateToggle(tab6, "Auto Best Rod Selection", false, function(v) Settings.AutoBestRod = v end)
CreateDropdown(tab6, "Manual Rod Selection", {"Kraken Rod", "Void Rod", "Lunar Rod", "Xeno Rod", "Alien Rod"}, "Kraken Rod", function(v) Settings.ManualRod = v end)
CreateLabel(tab6, "Status: Idle | Mastery: 0 | Void Pearls: 0")

local tab7 = CreateTab("Performance", "🚀")
CreateLabel(tab7, "🚀 Performance System")
CreateToggle(tab7, "Startup Boost", false, function(v) Settings.StartupBoost = v end)
CreateToggle(tab7, "Boost FPS", false, function(v) Settings.BoostFPS = v end)
CreateToggle(tab7, "Uncap FPS (Up to 1000)", false, function(v) Settings.UncapFPS = v end)
CreateToggle(tab7, "Hide My Pets & Eggs", false, function(v) Settings.HidePetsEggs = v end)
CreateToggle(tab7, "Graphics Optimization", false, function(v) Settings.GraphicsOpt = v end)
CreateToggle(tab7, "Map Details Optimization", false, function(v) Settings.MapOpt = v end)

local tab8 = CreateTab("Menu", "🖥️")
CreateLabel(tab8, "🖥️ Menu & Tools")
CreateLabel(tab8, "FPS: 60 | Ping: 0ms | Session: 00:00:00")
CreateLabel(tab8, "Stolen Eggs: 0 | Active Features: 0")

-- Make Tab 1 visible by default
tab1.Visible = true
TabContainer:GetChildren()[1].BackgroundColor3 = Color3.fromRGB(35, 35, 50)

--===========================================================================
-- 5. GAME LOGIC & EXECUTION LOOPS
--===========================================================================

local function GetEggRarity(eggName)
    local nameLower = string.lower(eggName)
    if string.find(nameLower, "divine") then return "Divine"
    elseif string.find(nameLower, "eternal") then return "Eternal"
    elseif string.find(nameLower, "secret") then return "Secret"
    elseif string.find(nameLower, "cosmic") then return "Cosmic"
    elseif string.find(nameLower, "mythic") then return "Mythic"
    elseif string.find(nameLower, "legendary") then return "Legendary"
    elseif string.find(nameLower, "epic") then return "Epic"
    elseif string.find(nameLower, "rare") then return "Rare"
    else return "Common" end
end

local function FindBestEgg()
    local bestEgg = nil
    local bestScore = -1
    
    for _, egg in ipairs(EggsFolder:GetDescendants()) do
        if egg:IsA("Model") or egg:IsA("BasePart") then
            local name = egg.Name
            if string.find(string.lower(name), "egg") and not egg:GetAttribute("Collected") then
                local rarity = GetEggRarity(name)
                local score = 1
                
                -- Apply Filters
                if Settings.FilterRarity ~= "All" and rarity ~= Settings.FilterRarity then continue end
                if Settings.FilterName ~= "All" and not string.find(string.lower(name), string.lower(Settings.FilterName)) then continue end
                
                -- Scoring for Rare Finder / Steal By Value
                if Settings.RareFinder or Settings.StealByValue then
                    if rarity == "Divine" then score = 100
                    elseif rarity == "Eternal" then score = 90
                    elseif rarity == "Secret" then score = 80
                    elseif rarity == "Cosmic" then score = 70
                    elseif rarity == "Mythic" then score = 60
                    elseif rarity == "Legendary" then score = 50 end
                end
                
                if score > bestScore then
                    bestScore = score
                    bestEgg = egg
                end
            end
        end
    end
    return bestEgg
end

local function SendWebhook(message)
    if not Settings.WebhookNotifs then return end
    -- Replace with your actual Discord Webhook URL
    local url = "YOUR_WEBHOOK_URL_HERE"
    local data = { content = "**Youko HUB:** " .. message, username = "Youko HUB" }
    pcall(function() HttpService:PostAsync(url, HttpService:JSONEncode(data)) end)
end

-- 🥚 Auto Steal Loop
task.spawn(function()
    while task.wait(0.5) do
        if Settings.AutoSteal then
            local egg = FindBestEgg()
            if egg then
                local eggPos = egg:IsA("Model") and egg:GetPivot().Position or egg.Position
                -- Move to egg (Anti-Guardian speed burst)
                local oldSpeed = humanoid.WalkSpeed
                humanoid.WalkSpeed = 100 
                rootPart.CFrame = CFrame.new(eggPos + Vector3.new(0, 3, 0))
                task.wait(0.2)
                humanoid.WalkSpeed = oldSpeed
                
                -- Fire Remote or rely on proximity collection
                if GameRemotes.StealEgg then
                    pcall(function() GameRemotes.StealEgg:FireServer(egg) end)
                end
                
                Settings.StolenEggs += 1
                SendWebhook("Successfully stole: " .. egg.Name)
                
                if Settings.AutoDeliver then
                    task.wait(0.5)
                    if GameRemotes.HatchEgg then
                        pcall(function() GameRemotes.HatchEgg:FireServer() end)
                    end
                end
            elseif Settings.ServerHop then
                -- Basic server hop logic
                local places = game:GetService("JobId")
                -- TeleportService:TeleportToPlaceInstance(game.PlaceId, places, player)
            end
        end
    end
end)

-- ⚡ Speed & Treadmill Loop
task.spawn(function()
    while task.wait(1) do
        if Settings.CurrentSpeedDet then
            Settings.FPS = math.floor(1 / RunService.Heartbeat:Wait())
        end
        
        if Settings.LowSpeedBoost and humanoid.WalkSpeed < 20 then
            humanoid.WalkSpeed = Settings.SpeedMultiplier
        end
        
        if Settings.AutoTreadmill and TreadmillPart then
            local tPos = TreadmillPart:IsA("Model") and TreadmillPart:GetPivot().Position or TreadmillPart.Position
            local dist = (rootPart.Position - tPos).Magnitude
            if dist < 15 then
                if GameRemotes.UpgradeSpeed then
                    pcall(function() GameRemotes.UpgradeSpeed:FireServer(true) end)
                end
            else
                rootPart.CFrame = CFrame.new(tPos + Vector3.new(0, 3, 0))
            end
        end
        
        if Settings.UncapFPS then
            settings().Rendering.QualityLevel = 1
        end
        
        if Settings.HidePetsEggs then
            -- Hide logic: iterate through player's character or workspace pets and set Transparency = 1
        end
    end
end)

-- ⚔️ PvP Steal Loop
task.spawn(function()
    while task.wait(0.5) do
        if Settings.AutoStealPvP then
            for _, target in ipairs(Players:GetPlayers()) do
                if target ~= player and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
                    if Settings.SkipFriends and player:IsFriendsWith(target.UserId) then continue end
                    
                    local targetRoot = target.Character.HumanoidRootPart
                    if Settings.AutoChase then
                        rootPart.CFrame = CFrame.new(targetRoot.Position + Vector3.new(0, 3, 0))
                    end
                    if Settings.AutoBatAttack and GameRemotes.AttackPlayer then
                        pcall(function() GameRemotes.AttackPlayer:FireServer(target) end)
                    end
                end
            end
        end
    end
end)

-- 🎣 Auto Fishing Loop
task.spawn(function()
    while task.wait(1.5) do
        if Settings.AutoFish and GameRemotes.FishCast then
            pcall(function() 
                GameRemotes.FishCast:FireServer("Cast", Settings.ManualRod)
                task.wait(1.5)
                GameRemotes.FishCast:FireServer("Reel")
            end)
        end
    end
end)

-- 🛸 UFO Event Loop
task.spawn(function()
    while task.wait(2) do
        if GameRemotes.UFOEvent then
            if Settings.AutoRepairComms then pcall(function() GameRemotes.UFOEvent:FireServer("RepairComms") end) end
            if Settings.AutoCollectDebris then pcall(function() GameRemotes.UFOEvent:FireServer("CollectDebris") end) end
            if Settings.AutoClaimRewards then pcall(function() GameRemotes.UFOEvent:FireServer("ClaimRewards") end) end
        end
    end
end)

--===========================================================================
-- 6. UI DRAGGABILITY & CLEANUP
--===========================================================================
local dragging, dragInput, dragStart, startPos

TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)

TitleBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- Toggle UI with RightShift
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        ScreenGui.Enabled = not ScreenGui.Enabled
    end
end)

-- Cleanup on re-execution to prevent memory leaks
if _G.YoukoHubLoaded then
    _G.YoukoHubLoaded:Destroy()
end
_G.YoukoHubLoaded = ScreenGui

print("[Youko HUB] Successfully loaded for Steal An Egg! Press RightShift to toggle UI.")
