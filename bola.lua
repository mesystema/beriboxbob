--[[
    ReplicatedRemoteLogger
    Profesional, efisien, dan aman untuk Roblox Android.
    - Melakukan scanning semua instance RemoteEvent/RemoteFunction di ReplicatedStorage
    - Menyimpan referensi instance ke dalam tabel
    - Melakukan logging hanya pada instance yang ditemukan dari hasil scanning
    - Menyediakan tombol untuk copy semua log ke clipboard (mobile friendly)
    - Praktik terbaik: camelCase, modular, komentar jelas
    - Tidak blocking main game, mobile friendly
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")

-- Tabel untuk menyimpan remote yang ditemukan
local scannedRemotes = {}

-- Fungsi scanning instance di ReplicatedStorage
local function scanRemotes()
    table.clear(scannedRemotes)
    for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            scannedRemotes[obj] = true
        end
    end
end

-- Fungsi logging (buffer queue, anti-lag)
local isLogging = false
local logQueue = {}

local function addToQueue(remote, method, args)
    if not isLogging then return end
    if #logQueue > 50 then return end -- Anti lag
    table.insert(logQueue, {
        name = remote.Name,
        class = remote.ClassName,
        method = method,
        args = args,
        color = (method == "FireServer" and "#f1c40f") or (method == "InvokeServer" and "#3498db") or "#95a5a6"
    })
end

-- UI setup
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ReplicatedRemoteLoggerUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 340, 0, 300)
mainFrame.Position = UDim2.new(0, 40, 0, 80)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.BackgroundTransparency = 0.15
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

local startBtn = Instance.new("TextButton")
startBtn.Size = UDim2.new(0, 80, 0, 36)
startBtn.Position = UDim2.new(0, 10, 0, 10)
startBtn.BackgroundColor3 = Color3.fromRGB(60, 180, 75)
startBtn.Text = "Start"
startBtn.TextColor3 = Color3.new(1,1,1)
startBtn.Font = Enum.Font.SourceSansBold
startBtn.TextSize = 20
startBtn.Parent = mainFrame

local stopBtn = Instance.new("TextButton")
stopBtn.Size = UDim2.new(0, 80, 0, 36)
stopBtn.Position = UDim2.new(0, 100, 0, 10)
stopBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 47)
stopBtn.Text = "Stop"
stopBtn.TextColor3 = Color3.new(1,1,1)
stopBtn.Font = Enum.Font.SourceSansBold
stopBtn.TextSize = 20
stopBtn.Parent = mainFrame

local scanBtn = Instance.new("TextButton")
scanBtn.Size = UDim2.new(0, 80, 0, 36)
scanBtn.Position = UDim2.new(0, 190, 0, 10)
scanBtn.BackgroundColor3 = Color3.fromRGB(52, 152, 219)
scanBtn.Text = "Scan"
scanBtn.TextColor3 = Color3.new(1,1,1)
scanBtn.Font = Enum.Font.SourceSansBold
scanBtn.TextSize = 20
scanBtn.Parent = mainFrame

local copyBtn = Instance.new("TextButton")
copyBtn.Size = UDim2.new(0, 80, 0, 36)
copyBtn.Position = UDim2.new(0, 10, 0, 56)
copyBtn.BackgroundColor3 = Color3.fromRGB(241, 196, 15)
copyBtn.Text = "Copy Log"
copyBtn.TextColor3 = Color3.fromRGB(40, 40, 40)
copyBtn.Font = Enum.Font.SourceSansBold
copyBtn.TextSize = 18
copyBtn.Parent = mainFrame

local logFrame = Instance.new("ScrollingFrame")
logFrame.Size = UDim2.new(1, -20, 1, -102)
logFrame.Position = UDim2.new(0, 10, 0, 102)
logFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
logFrame.BackgroundTransparency = 0.2
logFrame.BorderSizePixel = 0
logFrame.CanvasSize = UDim2.new(0, 0, 0, 1000)
logFrame.ScrollBarThickness = 6
logFrame.Parent = mainFrame

local logTemplate = Instance.new("TextLabel")
logTemplate.Size = UDim2.new(1, 0, 0, 22)
logTemplate.BackgroundTransparency = 1
logTemplate.TextColor3 = Color3.fromRGB(220, 220, 220)
logTemplate.Font = Enum.Font.Code
logTemplate.TextSize = 15
logTemplate.TextXAlignment = Enum.TextXAlignment.Left
logTemplate.ClipsDescendants = true
logTemplate.Visible = false
logTemplate.Parent = logFrame

-- Update tampilan log di UI
local function updateLogUI()
    for _, child in ipairs(logFrame:GetChildren()) do
        if child:IsA("TextLabel") and child ~= logTemplate then
            child:Destroy()
        end
    end
    for i, data in ipairs(logQueue) do
        local label = logTemplate:Clone()
        local argsString = ""
        for _, v in pairs(data.args) do
            local val = tostring(v)
            if typeof(v) == "table" then val = "{...}" end
            argsString = argsString .. val .. ", "
        end
        argsString = argsString:sub(1, -3)
        label.Text = string.format("<font color='%s'><b>[%s] %s (%s)</b></font>\n<font color='#bdc3c7'>%s</font>", data.color, data.method, data.name, data.class, argsString)
        label.RichText = true
        label.Position = UDim2.new(0, 0, 0, (i-1)*24)
        label.Visible = true
        label.Parent = logFrame
    end
    logFrame.CanvasSize = UDim2.new(0, 0, 0, math.max(#logQueue*24, logFrame.AbsoluteSize.Y))
end

-- Render loop untuk update UI
task.spawn(function()
    while true do
        task.wait(0.1)
        if #logQueue > 0 then
            updateLogUI()
        end
    end
end)

-- Tombol scan
scanBtn.MouseButton1Click:Connect(function()
    scanRemotes()
    table.insert(logQueue, 1, {
        name = "SYSTEM",
        class = "",
        method = "Scan",
        args = {"Total: " .. tostring(table.getn(scannedRemotes))},
        color = "#9b59b6"
    })
    updateLogUI()
end)

-- Tombol start/stop logging
startBtn.MouseButton1Click:Connect(function()
    isLogging = true
    table.insert(logQueue, 1, {
        name = "SYSTEM",
        class = "",
        method = "Start",
        args = {"Logging started"},
        color = "#2ecc40"
    })
    updateLogUI()
end)
stopBtn.MouseButton1Click:Connect(function()
    isLogging = false
    table.insert(logQueue, 1, {
        name = "SYSTEM",
        class = "",
        method = "Stop",
        args = {"Logging stopped"},
        color = "#e74c3c"
    })
    updateLogUI()
end)

-- Tombol copy log ke clipboard
copyBtn.MouseButton1Click:Connect(function()
    -- Gabungkan semua log menjadi satu string
    local logText = ""
    for i, data in ipairs(logQueue) do
        local argsString = ""
        for _, v in pairs(data.args) do
            local val = tostring(v)
            if typeof(v) == "table" then val = "{...}" end
            argsString = argsString .. val .. ", "
        end
        argsString = argsString:sub(1, -3)
        logText = logText .. string.format("[%s] %s (%s): %s\n", data.method, data.name, data.class, argsString)
    end
    -- Copy ke clipboard (gunakan SetClipboard jika tersedia, fallback ke SetCore)
    local success = false
    if setclipboard then
        setclipboard(logText)
        success = true
    else
        -- Fallback: Roblox mobile/console tidak mendukung clipboard, tampilkan popup
        pcall(function()
            StarterGui:SetCore("SendNotification", {
                Title = "Copy Log",
                Text = "Clipboard not supported on this device.",
                Duration = 2
            })
        end)
    end
    if success then
        pcall(function()
            StarterGui:SetCore("SendNotification", {
                Title = "Copy Log",
                Text = "Log copied to clipboard!",
                Duration = 2
            })
        end)
    end
end)

-- HOOKING: Logging hanya pada instance hasil scanning
local mt = getrawmetatable(game)
local oldNamecall = mt.__namecall
if setreadonly then setreadonly(mt, false) end

mt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    if isLogging and scannedRemotes[self] then
        local m = tostring(method):lower()
        if m == "fireserver" or m == "invokeserver" then
            local args = {...}
            addToQueue(self, method, args)
        end
    end
    return oldNamecall(self, ...)
end)

if setreadonly then setreadonly(mt, true) end

-- Inisialisasi awal: scan sekali
scanRemotes()
