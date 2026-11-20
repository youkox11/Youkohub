-- Youko HUB | Steal an Egg
-- Executor: Delta | Device: iPhone | UI: Rayfield

local G = (typeof(getgenv) == "function" and getgenv()) or _G
if G.YoukoHubUnload then pcall(G.YoukoHubUnload) end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local Stats = game:GetService("Stats")

local LP = Players.LocalPlayer

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local RARITIES = {"Rare", "Epic", "Legendary", "Mythic", "Cosmic", "Secret", "Eternal", "Divine"}
local HAS_FIRE_PROMPT = typeof(fireproximityprompt) == "function"
local HAS_FPS_CAP = typeof(setfpscap) == "function"
local HTTP_REQ = (typeof(request) == "function" and request)
    or (typeof(http_request) == "function" and http_request)
    or nil

local S = {
    Running = true,
    AutoSteal = false,
    StealGen = 0,
    StealDelay = 0.4,
    EggFilter = "",
    RarityFilter = {},
    ValueMode = false,
    MinValue = 0,
    Webhook = "",
    WebhookOn = false,
    Speed = false,
    SpeedBase = 16,
    SpeedMult = 1,
    LowProfile = false,
    FPSBoost = false,
    FPSCap = 120,
    LowGraphics = false,
    MapDetails = false,
    HidePets = false,
    Stolen = 0,
    Frames = 0,
    FPS = 0,
    StartTime = os.clock(),
    Conns = {},
    OrigTex = {},
    OrigLowGfx = nil,
    HiddenModels = {},
}

----------------------------------------------------------------
-- helpers
----------------------------------------------------------------
local function notify(title, content)
    pcall(function()
        Rayfield:Notify({Title = title, Content = content, Duration = 3})
    end)
end

local function firstOf(v)
    if type(v) == "table" then return v[1] end
    return v
end

local function num(v)
    return tonumber(firstOf(v)) or 0
end

local function getHum()
    local c = LP.Character
    return c and c:FindFirstChildOfClass("Humanoid")
end

local function getHRP()
    local c = LP.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function rankOf(r)
    for i, v in ipairs(RARITIES) do
        if v == r then return i end
    end
    return 0
end

local function getRarity(inst, label)
    local attr = inst:GetAttribute("Rarity")
    if type(attr) == "string" then return attr end
    local low = label:lower()
    for _, r in ipairs(RARITIES) do
        if low:find(r:lower(), 1, true) then return r end
    end
    return "Unknown"
end

local function getValue(inst)
    for _, key in ipairs({"Value", "Price", "Cost"}) do
        local a = inst:GetAttribute(key)
        if type(a) == "number" then return a end
        local v = inst:FindFirstChild(key)
        if v and (v:IsA("NumberValue") or v:IsA("IntValue")) then
            return v.Value
        end
    end
    return 0
end

local function nearestPart(inst)
    local cur = inst
    while cur and cur ~= Workspace do
        if cur:IsA("BasePart") then return cur end
        if cur:IsA("Attachment") and cur.Parent and cur.Parent:IsA("BasePart") then
            return cur.Parent
        end
        cur = cur.Parent
    end
    return nil
end

local function eggContainer(prompt)
    local cur = prompt.Parent
    while cur and cur ~= Workspace do
        if cur:IsA("Model") and cur.Name:lower():find("egg", 1, true) then
            return cur
        end
        cur = cur.Parent
    end
    return nil
end

----------------------------------------------------------------
-- egg scanning / filtering
----------------------------------------------------------------
local function scanEggs()
    local out = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") and obj.Enabled then
            local part = nearestPart(obj)
            local model = eggContainer(obj)
            local label = (obj.ObjectText or "") .. " " .. (obj.ActionText or "") .. " " .. (model and model.Name or "")
            if part and label:lower():find("egg", 1, true) then
                local ref = model or part
                table.insert(out, {
                    prompt = obj,
                    part = part,
                    name = (model and model.Name) or obj.ObjectText or part.Name,
                    rarity = getRarity(ref, label),
                    value = getValue(ref),
                })
            end
        end
    end
    return out
end

local function passesFilter(e)
    if S.EggFilter ~= "" and not e.name:lower():find(S.EggFilter:lower(), 1, true) then
        return false
    end
    if next(S.RarityFilter) ~= nil and not S.RarityFilter[e.rarity] then
        return false
    end
    if S.ValueMode and e.value < S.MinValue then
        return false
    end
    return true
end

----------------------------------------------------------------
-- webhook
----------------------------------------------------------------
local function sendWebhook(e)
    if not (S.WebhookOn and HTTP_REQ and S.Webhook ~= "") then return end
    local body = HttpService:JSONEncode({
        username = "Youko HUB",
        embeds = {{
            title = "Egg Stolen",
            color = 16753920,
            fields = {
                {name = "Egg", value = e.name, inline = true},
                {name = "Rarity", value = e.rarity, inline = true},
                {name = "Value", value = tostring(e.value), inline = true},
                {name = "Player", value = LP.Name, inline = true},
            },
        }},
    })
    pcall(HTTP_REQ, {
        Url = S.Webhook,
        Method = "POST",
        Headers = {["Content-Type"] = "application/json"},
        Body = body,
    })
end

----------------------------------------------------------------
-- auto steal
----------------------------------------------------------------
local function stealEgg(e)
    if not HAS_FIRE_PROMPT then return false end
    local hrp = getHRP()
    if not hrp then return false end
    if not e.prompt.Parent or not e.prompt.Enabled then return false end
    local ok = pcall(function()
        hrp.CFrame = e.part.CFrame * CFrame.new(0, 3, 0)
    end)
    if not ok then return false end
    task.wait(0.15)
    local fired = pcall(fireproximityprompt, e.prompt)
    return fired
end

local function startAutoSteal()
    S.StealGen += 1
    local gen = S.StealGen
    task.spawn(function()
        while S.Running and S.AutoSteal and S.StealGen == gen do
            local ok, list = pcall(scanEggs)
            if ok and list then
                local targets = {}
                for _, e in ipairs(list) do
                    if passesFilter(e) then table.insert(targets, e) end
                end
                table.sort(targets, function(a, b)
                    local ra, rb = rankOf(a.rarity), rankOf(b.rarity)
                    if ra ~= rb then return ra > rb end
                    return a.value > b.value
                end)
                for _, e in ipairs(targets) do
                    if not (S.Running and S.AutoSteal and S.StealGen == gen) then break end
                    if stealEgg(e) then
                        S.Stolen += 1
                        sendWebhook(e)
                    end
                    task.wait(S.StealDelay)
                end
            end
            task.wait(0.5)
        end
    end)
end

----------------------------------------------------------------
-- speed
----------------------------------------------------------------
local function applySpeed()
    local hum = getHum()
    if not hum then return end
    local target = S.SpeedBase * S.SpeedMult
    if S.LowProfile then target = math.min(target, 24) end
    hum.WalkSpeed = target
end

local function setSpeedEnabled(on)
    S.Speed = on
    if not on then
        local hum = getHum()
        if hum then hum.WalkSpeed = 16 end
    end
end

----------------------------------------------------------------
-- performance
----------------------------------------------------------------
local function setFPSBoost(on)
    S.FPSBoost = on
    if not HAS_FPS_CAP then
        notify("FPS", "Executor không hỗ trợ setfpscap")
        return
    end
    pcall(setfpscap, on and S.FPSCap or 60)
end

local function setLowGraphics(on)
    S.LowGraphics = on
    pcall(function()
        if on then
            if not S.OrigLowGfx then
                S.OrigLowGfx = {
                    Quality = settings().Rendering.QualityLevel,
                    Shadows = Lighting.GlobalShadows,
                }
            end
            settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
            Lighting.GlobalShadows = false
        elseif S.OrigLowGfx then
            settings().Rendering.QualityLevel = S.OrigLowGfx.Quality
            Lighting.GlobalShadows = S.OrigLowGfx.Shadows
            S.OrigLowGfx = nil
        end
    end)
end

local function setMapDetails(on)
    S.MapDetails = on
    pcall(function()
        Workspace.Terrain.Decoration = not on
    end)
    if on then
        for _, d in ipairs(Workspace:GetDescendants()) do
            if (d:IsA("Decal") or d:IsA("Texture")) and S.OrigTex[d] == nil then
                S.OrigTex[d] = d.Transparency
                d.Transparency = 1
            end
        end
    else
        for d, t in pairs(S.OrigTex) do
            if d.Parent then d.Transparency = t end
        end
        S.OrigTex = {}
    end
end

local function isMine(m)
    local owner = m:GetAttribute("Owner") or m:GetAttribute("OwnerName") or m:GetAttribute("UserId")
    if owner ~= nil then
        local s = tostring(owner)
        return s == LP.Name or s == tostring(LP.UserId)
    end
    return m.Name:find(LP.Name, 1, true) ~= nil
end

local function setPartsHidden(m, hidden)
    for _, p in ipairs(m:GetDescendants()) do
        if p:IsA("BasePart") then
            p.LocalTransparencyModifier = hidden and 1 or 0
        end
    end
end

local function refreshHidden()
    if not S.HidePets then return end
    for _, m in ipairs(Workspace:GetDescendants()) do
        if m:IsA("Model") and m ~= LP.Character then
            local n = m.Name:lower()
            if (n:find("egg", 1, true) or n:find("pet", 1, true)) and isMine(m) then
                S.HiddenModels[m] = true
            end
        end
    end
    for m in pairs(S.HiddenModels) do
        if m.Parent then
            setPartsHidden(m, true)
        else
            S.HiddenModels[m] = nil
        end
    end
end

local function setHidePets(on)
    S.HidePets = on
    if on then
        refreshHidden()
    else
        for m in pairs(S.HiddenModels) do
            if m.Parent then setPartsHidden(m, false) end
        end
        S.HiddenModels = {}
    end
end

----------------------------------------------------------------
-- server hop
----------------------------------------------------------------
local function serverHop()
    notify("Server Hop", "Đang tìm server...")
    task.spawn(function()
        local ok, body = pcall(function()
            return game:HttpGet(("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100"):format(game.PlaceId))
        end)
        if not ok then
            notify("Server Hop", "Không lấy được danh sách server")
            return
        end
        local ok2, data = pcall(function() return HttpService:JSONDecode(body) end)
        if not ok2 or type(data) ~= "table" or type(data.data) ~= "table" then
            notify("Server Hop", "Dữ liệu server không hợp lệ")
            return
        end
        local candidates = {}
        for _, sv in ipairs(data.data) do
            if sv.id ~= game.JobId and sv.playing < sv.maxPlayers then
                table.insert(candidates, sv.id)
            end
        end
        if #candidates == 0 then
            notify("Server Hop", "Không có server trống phù hợp")
            return
        end
        local pick = candidates[math.random(1, #candidates)]
        pcall(function()
            TeleportService:TeleportToPlaceInstance(game.PlaceId, pick, LP)
        end)
    end)
end

----------------------------------------------------------------
-- monitors
----------------------------------------------------------------
local function countActive()
    local n = 0
    for _, k in ipairs({"AutoSteal", "Speed", "FPSBoost", "LowGraphics", "MapDetails", "HidePets", "WebhookOn"}) do
        if S[k] then n += 1 end
    end
    return n
end

local function speedAdvice(cur)
    if not S.Speed then return "Speed đang tắt. Bật Speed rồi chỉnh Base Speed." end
    if cur >= 100 then return "Tốc độ rất cao. Nên bật Low Speed Profile." end
    if cur >= 40 then return "Tốc độ vừa phải, phù hợp để farm." end
    return "Tốc độ thấp. Tăng Low Speed Multiplier nếu cần nhanh hơn."
end

table.insert(S.Conns, RunService.RenderStepped:Connect(function()
    S.Frames += 1
end))

table.insert(S.Conns, RunService.Heartbeat:Connect(function()
    if S.Speed then applySpeed() end
end))

----------------------------------------------------------------
-- window
----------------------------------------------------------------
local Window = Rayfield:CreateWindow({
    Name = "Youko HUB | Steal an Egg",
    LoadingTitle = "Youko HUB",
    LoadingSubtitle = "Steal an Egg",
    ConfigurationSaving = {Enabled = false},
    Discord = {Enabled = false},
    KeySystem = false,
})

local DashTab = Window:CreateTab("Dashboard")
local StealTab = Window:CreateTab("Auto Steal")
local SpeedTab = Window:CreateTab("Speed")
local PerfTab = Window:CreateTab("Performance")
local ServerTab = Window:CreateTab("Server")
local MiscTab = Window:CreateTab("Misc")

-- Dashboard
DashTab:CreateSection("Live Status")
local dashPara = DashTab:CreateParagraph({Title = "Youko HUB", Content = "Đang khởi tạo..."})
local speedAdvicePara = DashTab:CreateParagraph({Title = "Speed Advice", Content = "..."})

-- Auto Steal
StealTab:CreateSection("Auto Steal System")
StealTab:CreateToggle({
    Name = "Auto Steal (Normal)",
    CurrentValue = false,
    Flag = "AutoSteal",
    Callback = function(v)
        S.AutoSteal = v
        if v then startAutoSteal() end
        if not HAS_FIRE_PROMPT and v then
            notify("Auto Steal", "Executor không hỗ trợ fireproximityprompt")
        end
    end,
})
StealTab:CreateSlider({
    Name = "Steal Delay",
    Range = {0.1, 3},
    Increment = 0.1,
    Suffix = "s",
    CurrentValue = 0.4,
    Flag = "StealDelay",
    Callback = function(v) S.StealDelay = num(v) end,
})
StealTab:CreateInput({
    Name = "Filter By Egg Name",
    PlaceholderText = "ví dụ: Dragon",
    RemoveTextAfterFocusLost = false,
    Callback = function(t) S.EggFilter = tostring(firstOf(t) or "") end,
})
StealTab:CreateDropdown({
    Name = "Filter By Rarity",
    Options = RARITIES,
    CurrentOption = {},
    MultipleOptions = true,
    Flag = "RarityFilter",
    Callback = function(opts)
        local set = {}
        if type(opts) == "table" then
            for _, v in ipairs(opts) do set[v] = true end
        elseif type(opts) == "string" then
            set[opts] = true
        end
        S.RarityFilter = set
    end,
})
StealTab:CreateToggle({
    Name = "Steal By Value",
    CurrentValue = false,
    Flag = "ValueMode",
    Callback = function(v) S.ValueMode = v end,
})
StealTab:CreateSlider({
    Name = "Min Value",
    Range = {0, 1000000},
    Increment = 1000,
    CurrentValue = 0,
    Flag = "MinValue",
    Callback = function(v) S.MinValue = num(v) end,
})

StealTab:CreateSection("Rare Egg Finder")
local finderPara = StealTab:CreateParagraph({Title = "Rare Egg Finder", Content = "Chưa quét."})
StealTab:CreateButton({
    Name = "Scan Rare Eggs",
    Callback = function()
        local list = scanEggs()
        local lines, count = {}, 0
        for _, e in ipairs(list) do
            if rankOf(e.rarity) >= rankOf("Rare") then
                count += 1
                if count <= 15 then
                    table.insert(lines, ("[%s] %s | Value: %s"):format(e.rarity, e.name, tostring(e.value)))
                end
            end
        end
        finderPara:Set({
            Title = "Rare Egg Finder",
            Content = count == 0 and "Không tìm thấy egg hiếm." or table.concat(lines, "\n"),
        })
        notify("Rare Egg Finder", ("Tìm thấy %d egg hiếm"):format(count))
    end,
})

StealTab:CreateSection("Steal Webhook")
StealTab:CreateInput({
    Name = "Webhook URL",
    PlaceholderText = "https://discord.com/api/webhooks/...",
    RemoveTextAfterFocusLost = false,
    Callback = function(t) S.Webhook = tostring(firstOf(t) or "") end,
})
StealTab:CreateToggle({
    Name = "Steal Webhook Notifications",
    CurrentValue = false,
    Flag = "WebhookOn",
    Callback = function(v)
        S.WebhookOn = v
        if v and not HTTP_REQ then
            notify("Webhook", "Executor không hỗ trợ request")
        end
    end,
})

-- Speed
SpeedTab:CreateSection("Speed System")
SpeedTab:CreateToggle({
    Name = "Speed",
    CurrentValue = false,
    Flag = "Speed",
    Callback = function(v) setSpeedEnabled(v) end,
})
SpeedTab:CreateSlider({
    Name = "Base Speed",
    Range = {16, 200},
    Increment = 1,
    CurrentValue = 16,
    Flag = "SpeedBase",
    Callback = function(v) S.SpeedBase = num(v) end,
})
SpeedTab:CreateSlider({
    Name = "Low Speed Multiplier",
    Range = {1, 3},
    Increment = 0.1,
    CurrentValue = 1,
    Flag = "SpeedMult",
    Callback = function(v) S.SpeedMult = num(v) end,
})
SpeedTab:CreateToggle({
    Name = "Low Speed Profile (max 24)",
    CurrentValue = false,
    Flag = "LowProfile",
    Callback = function(v) S.LowProfile = v end,
})

-- Performance
PerfTab:CreateSection("Performance System")
PerfTab:CreateToggle({
    Name = "Boost FPS",
    CurrentValue = false,
    Flag = "FPSBoost",
    Callback = function(v) setFPSBoost(v) end,
})
PerfTab:CreateSlider({
    Name = "FPS Cap",
    Range = {30, 1000},
    Increment = 10,
    CurrentValue = 120,
    Flag = "FPSCap",
    Callback = function(v)
        S.FPSCap = num(v)
        if S.FPSBoost then setFPSBoost(true) end
    end,
})
PerfTab:CreateToggle({
    Name = "Graphics Optimization",
    CurrentValue = false,
    Flag = "LowGraphics",
    Callback = function(v) setLowGraphics(v) end,
})
PerfTab:CreateToggle({
    Name = "Map Details Optimization",
    CurrentValue = false,
    Flag = "MapDetails",
    Callback = function(v) setMapDetails(v) end,
})
PerfTab:CreateToggle({
    Name = "Hide My Pets & Eggs",
    CurrentValue = false,
    Flag = "HidePets",
    Callback = function(v) setHidePets(v) end,
})
PerfTab:CreateButton({
    Name = "Startup Boost (Apply All)",
    Callback = function()
        setFPSBoost(true)
        setLowGraphics(true)
        setMapDetails(true)
        notify("Startup Boost", "Đã áp dụng toàn bộ tối ưu")
    end,
})

-- Server
ServerTab:CreateSection("Server Tools")
ServerTab:CreateButton({
    Name = "Server Hop",
    Callback = function() serverHop() end,
})

-- Misc
MiscTab:CreateSection("Control")
MiscTab:CreateButton({
    Name = "Unload Youko HUB",
    Callback = function()
        if G.YoukoHubUnload then G.YoukoHubUnload() end
    end,
})

----------------------------------------------------------------
-- dashboard loop
----------------------------------------------------------------
task.spawn(function()
    while S.Running do
        task.wait(1)
        S.FPS = S.Frames
        S.Frames = 0
        if S.HidePets then refreshHidden() end

        local hum = getHum()
        local cur = hum and math.floor(hum.WalkSpeed) or 0
        local elapsed = math.floor(os.clock() - S.StartTime)
        local ping = 0
        pcall(function()
            ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
        end)

        pcall(function()
            dashPara:Set({
                Title = "Youko HUB",
                Content = string.format(
                    "Session: %02d:%02d:%02d\nFPS: %d | Ping: %d ms\nSpeed: %d\nStolen (fired): %d\nActive features: %d",
                    math.floor(elapsed / 3600),
                    math.floor((elapsed % 3600) / 60),
                    elapsed % 60,
                    S.FPS, ping, cur, S.Stolen, countActive()
                ),
            })
            speedAdvicePara:Set({Title = "Speed Advice", Content = speedAdvice(cur)})
        end)
    end
end)

----------------------------------------------------------------
-- unload / cleanup
----------------------------------------------------------------
G.YoukoHubUnload = function()
    S.Running = false
    S.AutoSteal = false
    S.StealGen += 1
    for _, c in ipairs(S.Conns) do
        pcall(function() c:Disconnect() end)
    end
    S.Conns = {}
    setSpeedEnabled(false)
    setFPSBoost(false)
    setLowGraphics(false)
    setMapDetails(false)
    setHidePets(false)
    pcall(function() Rayfield:Destroy() end)
    G.YoukoHubUnload = nil
end

notify("Youko HUB", "Đã load Steal an Egg")
