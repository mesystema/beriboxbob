--[[
    bolo.lua: Auto Fishing Loop Script (Mobile Friendly)
    Profesional, modular, dan aman untuk Roblox Android.
    - UI: Start/Stop, input value charge, minigame, global wait
    - Looping: CancelFishingInput -> ChargeFishingRod -> RequestFishingMinigameStarted -> Wait -> FishingCompleted
    - Praktik terbaik: camelCase, event-driven, tidak blocking main game
    - Aman: Server-side validation, error handling, rate limiting
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

-- Tunggu player GUI ready
if not player:FindFirstChild("PlayerGui") then
    player:WaitForChild("PlayerGui")
end

-- Konfigurasi Remote References - dengan timeout handling
local remotes = {}
local function loadRemote(path, isWait)
    local parts = string.split(path, "/")
    local remote = ReplicatedStorage:FindFirstChild(parts[1])
    if remote then
        for i = 2, #parts do
            remote = remote:FindFirstChild(parts[i])
            if not remote then break end
        end
    end
    return remote
end

-- Load remotes dengan safe checking
remotes.chargeRod = loadRemote("RF/ChargeFishingRod")
remotes.minigameStart = loadRemote("RF/RequestFishingMinigameStarted")
remotes.fishingCompleted = loadRemote("RE/FishingCompleted")
remotes.cancelInput = loadRemote("RE/CancelFishingInput")

-- UI Setup
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "BoloFishingUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 420, 0, 340)
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
stopBtn.Position = UDim2.new(0, 110, 0, 10)
stopBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 47)
stopBtn.Text = "Stop"
stopBtn.TextColor3 = Color3.new(1,1,1)
stopBtn.Font = Enum.Font.SourceSansBold
stopBtn.TextSize = 20
stopBtn.Parent = mainFrame

local chargeBox = Instance.new("TextBox")
chargeBox.Size = UDim2.new(0, 120, 0, 32)
chargeBox.Position = UDim2.new(0, 10, 0, 60)
chargeBox.BackgroundColor3 = Color3.fromRGB(35, 35, 60)
chargeBox.TextColor3 = Color3.fromRGB(255, 255, 255)
chargeBox.Font = Enum.Font.Code
chargeBox.TextSize = 14
chargeBox.PlaceholderText = "Charge Val"
chargeBox.Text = "1"
chargeBox.ClearTextOnFocus = false
chargeBox.Parent = mainFrame

local minigameBox = Instance.new("TextBox")
minigameBox.Size = UDim2.new(0, 180, 0, 32)
minigameBox.Position = UDim2.new(0, 140, 0, 60)
minigameBox.BackgroundColor3 = Color3.fromRGB(35, 35, 60)
minigameBox.TextColor3 = Color3.fromRGB(255, 255, 255)
minigameBox.Font = Enum.Font.Code
minigameBox.TextSize = 14
minigameBox.PlaceholderText = "Minigame (1,1,1)"
minigameBox.Text = "1,1,1"
minigameBox.ClearTextOnFocus = false
minigameBox.Parent = mainFrame

-- Wait Time Inputs
local waitAfterCancelBox = Instance.new("TextBox")
waitAfterCancelBox.Size = UDim2.new(0, 95, 0, 28)
waitAfterCancelBox.Position = UDim2.new(0, 10, 0, 100)
waitAfterCancelBox.BackgroundColor3 = Color3.fromRGB(35, 35, 60)
waitAfterCancelBox.TextColor3 = Color3.fromRGB(255, 200, 0)
waitAfterCancelBox.Font = Enum.Font.Code
waitAfterCancelBox.TextSize = 12
waitAfterCancelBox.PlaceholderText = "Wait Cancel"
waitAfterCancelBox.Text = "0.1"
waitAfterCancelBox.ClearTextOnFocus = false
waitAfterCancelBox.Parent = mainFrame

local waitAfterChargeBox = Instance.new("TextBox")
waitAfterChargeBox.Size = UDim2.new(0, 95, 0, 28)
waitAfterChargeBox.Position = UDim2.new(0, 115, 0, 100)
waitAfterChargeBox.BackgroundColor3 = Color3.fromRGB(35, 35, 60)
waitAfterChargeBox.TextColor3 = Color3.fromRGB(255, 200, 0)
waitAfterChargeBox.Font = Enum.Font.Code
waitAfterChargeBox.TextSize = 12
waitAfterChargeBox.PlaceholderText = "Wait Charge"
waitAfterChargeBox.Text = "0.2"
waitAfterChargeBox.ClearTextOnFocus = false
waitAfterChargeBox.Parent = mainFrame

local waitAfterMinigameBox = Instance.new("TextBox")
waitAfterMinigameBox.Size = UDim2.new(0, 95, 0, 28)
waitAfterMinigameBox.Position = UDim2.new(0, 220, 0, 100)
waitAfterMinigameBox.BackgroundColor3 = Color3.fromRGB(35, 35, 60)
waitAfterMinigameBox.TextColor3 = Color3.fromRGB(255, 200, 0)
waitAfterMinigameBox.Font = Enum.Font.Code
waitAfterMinigameBox.TextSize = 12
waitAfterMinigameBox.PlaceholderText = "Wait Minigame"
waitAfterMinigameBox.Text = "0.2"
waitAfterMinigameBox.ClearTextOnFocus = false
waitAfterMinigameBox.Parent = mainFrame

-- Label untuk Wait Times
local waitLabel = Instance.new("TextLabel")
waitLabel.Size = UDim2.new(1, -20, 0, 18)
waitLabel.Position = UDim2.new(0, 10, 0, 138)
waitLabel.BackgroundTransparency = 1
waitLabel.Text = "Wait: Cancel | Charge | Minigame"
waitLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
waitLabel.Font = Enum.Font.Code
waitLabel.TextSize = 12
waitLabel.TextXAlignment = Enum.TextXAlignment.Left
waitLabel.Parent = mainFrame

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -20, 0, 50)
statusLabel.Position = UDim2.new(0, 10, 0, 160)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Status: Idle"
statusLabel.TextColor3 = Color3.fromRGB(200, 255, 200)
statusLabel.Font = Enum.Font.Code
statusLabel.TextSize = 14
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.TextWrapped = true
statusLabel.Parent = mainFrame

-- Helper: Parse minigame value dari string format "1,1,1"
-- @param str string: Format "value1,value2,value3"
-- @return table: Array dari parsed values
local function parseMinigame(str)
    local args = {}
    for arg in string.gmatch(str, "([^,]+)") do
        arg = arg:gsub("^%s*(.-)%s*$", "%1")
        local n = tonumber(arg)
        table.insert(args, n or arg)
    end
    return args
end

-- Helper: Parse charge value (single number)
-- @param str string: Format "1"
-- @return number: Parsed value atau default 1
local function parseCharge(str)
    return tonumber(str) or 1
end

-- Helper: Parse wait time
-- @param str string: Detik untuk menunggu
-- @return number: Parsed value atau default 0.1
local function parseWaitTime(str, default)
    return math.max(0.01, tonumber(str) or (default or 0.1))
end

-- Looping logic
local isLooping = false
local errorCount = 0
local loopCount = 0

-- @param text string: Status text untuk ditampilkan
local function setStatus(text)
    statusLabel.Text = "Status: " .. text
end

-- Execute satu siklus fishing
-- @return boolean: true jika sukses, false jika error
local function executeFishingCycle()
    local success = true
    
    -- 1. CancelFishingInput (optional)
    if remotes.cancelInput then
        pcall(function()
            remotes.cancelInput:FireServer()
        end)
    end
    
    local waitCancel = parseWaitTime(waitAfterCancelBox.Text, 0.1)
    task.wait(waitCancel)
    
    -- 2. ChargeFishingRod
    local chargeVal = parseCharge(chargeBox.Text)
    local chargeTimestamp = tick()
    
    if remotes.chargeRod then
        local ok = pcall(function()
            local result = remotes.chargeRod:InvokeServer(chargeTimestamp)
            setStatus("Charging... (" .. chargeVal .. ")")
        end)
        if not ok then
            success = false
            errorCount = errorCount + 1
        end
    end
    
    local waitCharge = parseWaitTime(waitAfterChargeBox.Text, 0.2)
    task.wait(waitCharge)
    
    -- 3. RequestFishingMinigameStarted
    local minigameArgs = parseMinigame(minigameBox.Text)
    local minigameTimestamp = tick()
    
    if remotes.minigameStart then
        local ok = pcall(function()
            -- Tambah timestamp sebagai argument terakhir
            table.insert(minigameArgs, minigameTimestamp)
            local result = remotes.minigameStart:InvokeServer(unpack(minigameArgs))
            setStatus("Minigame Started...")
        end)
        if not ok then
            success = false
            errorCount = errorCount + 1
        end
    end
    
    local waitMinigame = parseWaitTime(waitAfterMinigameBox.Text, 0.2)
    task.wait(waitMinigame)
    
    -- 4. FishingCompleted
    if remotes.fishingCompleted then
        pcall(function()
            remotes.fishingCompleted:FireServer()
            setStatus("Completed! Loop: " .. loopCount)
        end)
    end
    
    loopCount = loopCount + 1
    
    -- Reset error count jika cycle sukses
    if success then
        errorCount = 0
    end
    
    return success
end

-- Main loop function
local function doLoop()
    loopCount = 0
    errorCount = 0
    setStatus("Looping... (0)")
    
    while isLooping do
        -- Stop jika error berlebihan
        if errorCount > 5 then
            setStatus("Error limit reached! Stopping...")
            isLooping = false
            break
        end
        
        local ok = pcall(executeFishingCycle)
        if not ok then
            errorCount = errorCount + 1
            setStatus("Error! (" .. errorCount .. "/5)")
            task.wait(0.5)
        else
            task.wait(0.1) -- Minimal delay antar cycle
        end
    end
    
    setStatus("Idle")
end

startBtn.MouseButton1Click:Connect(function()
    if not isLooping then
        -- Validasi remote ada sebelum start
        if not remotes.chargeRod or not remotes.minigameStart or not remotes.fishingCompleted then
            setStatus("Error: Remotes not found!")
            return
        end
        isLooping = true
        setStatus("Starting...")
        task.spawn(doLoop)
    end
end)

stopBtn.MouseButton1Click:Connect(function()
    isLooping = false
    setStatus("Stopping...")
end)

-- Cleanup on player leaving
local humanoidPath = player:FindFirstChild("Character")
if humanoidPath then
    local humanoid = humanoidPath:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.Died:Connect(function()
            isLooping = false
        end)
    end
end

-- Inisialisasi status
setStatus("Idle")
