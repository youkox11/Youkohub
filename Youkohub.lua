
-- YOUKO HUB EXCLUSIVE
-- Game Scanner V1.0
-- For authorized Roblox Studio experiences

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local old = PlayerGui:FindFirstChild("YoukoHubScanner")
if old then
    old:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "YoukoHubScanner"
gui.ResetOnSpawn = false
gui.Parent = PlayerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.fromScale(0.85, 0.65)
frame.Position = UDim2.fromScale(0.5, 0.5)
frame.AnchorPoint = Vector2.new(0.5, 0.5)
frame.BackgroundColor3 = Color3.fromRGB(15, 18, 28)
frame.Parent = gui

Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -50, 0, 45)
title.BackgroundTransparency = 1
title.Text = "YOUKO HUB | SCANNER V1"
title.TextColor3 = Color3.fromRGB(90, 170, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.Parent = frame

local close = Instance.new("TextButton")
close.Size = UDim2.fromOffset(40, 35)
close.Position = UDim2.new(1, -45, 0, 5)
close.Text = "X"
close.TextColor3 = Color3.new(1, 1, 1)
close.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
close.Parent = frame

local scan = Instance.new("TextButton")
scan.Size = UDim2.new(1, -20, 0, 40)
scan.Position = UDim2.fromOffset(10, 50)
scan.Text = "START GAME SCAN"
scan.Font = Enum.Font.GothamBold
scan.TextColor3 = Color3.new(1, 1, 1)
scan.BackgroundColor3 = Color3.fromRGB(35, 100, 220)
scan.Parent = frame

Instance.new("UICorner", scan)

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -20, 0, 30)
status.Position = UDim2.fromOffset(10, 95)
status.BackgroundTransparency = 1
status.TextColor3 = Color3.fromRGB(100, 255, 160)
status.TextSize = 13
status.Text = "Status: Ready"
status.Parent = frame

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -20, 1, -140)
scroll.Position = UDim2.fromOffset(10, 130)
scroll.BackgroundColor3 = Color3.fromRGB(23, 27, 38)
scroll.ScrollBarThickness = 5
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.CanvasSize = UDim2.new()
scroll.Parent = frame

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 4)
layout.Parent = scroll

local keywords = {
    "egg", "divine", "eternal", "secret",
    "cosmic", "mythic", "legendary",
    "rare", "epic", "pet", "treadmill",
    "fish", "rod", "ufo", "alien",
    "debris", "home", "safezone",
    "spawn", "mutation", "relic",
    "pearl", "bat"
}

local function addResult(message)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -10, 0, 0)
    label.AutomaticSize = Enum.AutomaticSize.Y
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(225, 230, 240)
    label.TextWrapped = true
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Font = Enum.Font.Code
    label.TextSize = 12
    label.Text = message
    label.Parent = scroll
end

local scanning = false
local cancelled = false

local function startScan()
    if scanning then return end

    scanning = true
    cancelled = false
    scan.Text = "SCANNING..."

    for _, child in ipairs(scroll:GetChildren()) do
        if child:IsA("TextLabel") then
            child:Destroy()
        end
    end

    if not RunService:IsStudio() then
        status.Text = "Roblox Studio required"
        scanning = false
        scan.Text = "START GAME SCAN"
        return
    end

    addResult("Place ID: " .. tostring(game.PlaceId))
    addResult("Player: " .. Player.Name)
    addResult("----- SCAN RESULTS -----")

    local count = 0

    for index, object in ipairs(Workspace:GetDescendants()) do
        if cancelled then break end

        local name = string.lower(object.Name)

        for _, keyword in ipairs(keywords) do
            if string.find(name, keyword, 1, true) then
                count += 1

                local result = object:GetFullName()
                addResult(result)
                print("[YOUKO SCAN]", result)

                for key, value in pairs(object:GetAttributes()) do
                    addResult(key .. ": " .. tostring(value))
                end

                break
            end
        end

        if index % 200 == 0 then
            status.Text = "Scanning: " .. index
            task.wait()
        end
    end

    if not cancelled then
        status.Text = "Completed | Found: " .. count
        scan.Text = "SCAN AGAIN"
        addResult("Total matches: " .. count)
    end

    scanning = false
end

scan.Activated:Connect(startScan)

close.Activated:Connect(function()
    cancelled = true
    gui:Destroy()
end)

print("[YOUKO HUB] Scanner loaded")
