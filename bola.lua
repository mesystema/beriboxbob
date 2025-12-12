--[[
    bolo_android.lua: Auto Fishing Loop Script - Android Compatible
    Versi khusus untuk Roblox Android dengan compatibility terbaik
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

-- Tunggu player GUI ready
local playerGui = player:FindFirstChild("PlayerGui")
if not playerGui then
    playerGui = player:WaitForChild("PlayerGui")
end

-- ===== UI SETUP =====
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "BoloFishingUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 350, 0, 450)
mainFrame.Position = UDim2.new(0.5, -175, 0.5, -225)
mainFrame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.15)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

-- Title
local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 0, 30)
titleLabel.Position = UDim2.new(0, 0, 0, 0)
titleLabel.BackgroundColor3 = Color3.new(0.05, 0.05, 0.1)
titleLabel.Text = "BOLO FISHING"
titleLabel.TextColor3 = Color3.new(1, 1, 1)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 16
titleLabel.Parent = mainFrame

-- Start Button
local startBtn = Instance.new("TextButton")
startBtn.Size = UDim2.new(0.45, 0, 0, 40)
startBtn.Position = UDim2.new(0.05, 0, 0, 40)
startBtn.BackgroundColor3 = Color3.new(0.2, 0.6, 0.2)
startBtn.Text = "START"
startBtn.TextColor3 = Color3.new(1, 1, 1)
startBtn.Font = Enum.Font.GothamBold
startBtn.TextSize = 14
startBtn.Parent = mainFrame

-- Stop Button
local stopBtn = Instance.new("TextButton")
stopBtn.Size = UDim2.new(0.45, 0, 0, 40)
stopBtn.Position = UDim2.new(0.5, 0, 0, 40)
stopBtn.BackgroundColor3 = Color3.new(0.7, 0.2, 0.2)
stopBtn.Text = "STOP"
stopBtn.TextColor3 = Color3.new(1, 1, 1)
stopBtn.Font = Enum.Font.GothamBold
stopBtn.TextSize = 14
stopBtn.Parent = mainFrame

-- Charge Input
local chargeLabel = Instance.new("TextLabel")
chargeLabel.Size = UDim2.new(1, -20, 0, 20)
chargeLabel.Position = UDim2.new(0, 10, 0, 90)
chargeLabel.BackgroundTransparency = 1
chargeLabel.Text = "Charge Value:"
chargeLabel.TextColor3 = Color3.new(1, 1, 1)
chargeLabel.Font = Enum.Font.Gotham
chargeLabel.TextSize = 12
chargeLabel.TextXAlignment = Enum.TextXAlignment.Left
chargeLabel.Parent = mainFrame

local chargeBox = Instance.new("TextBox")
chargeBox.Size = UDim2.new(1, -20, 0, 28)
chargeBox.Position = UDim2.new(0, 10, 0, 112)
chargeBox.BackgroundColor3 = Color3.new(0.15, 0.15, 0.25)
chargeBox.TextColor3 = Color3.new(1, 1, 1)
chargeBox.Font = Enum.Font.Code
chargeBox.TextSize = 12
chargeBox.Text = "1"
chargeBox.ClearTextOnFocus = false
chargeBox.Parent = mainFrame

-- Minigame Input
local minigameLabel = Instance.new("TextLabel")
minigameLabel.Size = UDim2.new(1, -20, 0, 20)
minigameLabel.Position = UDim2.new(0, 10, 0, 150)
minigameLabel.BackgroundTransparency = 1
minigameLabel.Text = "Minigame Values (comma sep):"
minigameLabel.TextColor3 = Color3.new(1, 1, 1)
minigameLabel.Font = Enum.Font.Gotham
minigameLabel.TextSize = 12
minigameLabel.TextXAlignment = Enum.TextXAlignment.Left
minigameLabel.Parent = mainFrame

local minigameBox = Instance.new("TextBox")
minigameBox.Size = UDim2.new(1, -20, 0, 28)
minigameBox.Position = UDim2.new(0, 10, 0, 172)
minigameBox.BackgroundColor3 = Color3.new(0.15, 0.15, 0.25)
minigameBox.TextColor3 = Color3.new(1, 1, 1)
minigameBox.Font = Enum.Font.Code
minigameBox.TextSize = 12
minigameBox.Text = "1,1,1"
minigameBox.ClearTextOnFocus = false
minigameBox.Parent = mainFrame

-- Wait Times Section
local waitLabel = Instance.new("TextLabel")
waitLabel.Size = UDim2.new(1, -20, 0, 20)
waitLabel.Position = UDim2.new(0, 10, 0, 210)
waitLabel.BackgroundTransparency = 1
waitLabel.Text = "Wait Times (seconds):"
waitLabel.TextColor3 = Color3.new(1, 1, 0.5)
waitLabel.Font = Enum.Font.Gotham
waitLabel.TextSize = 12
waitLabel.TextXAlignment = Enum.TextXAlignment.Left
waitLabel.Parent = mainFrame

-- Wait Cancel
local waitCancelLabel = Instance.new("TextLabel")
waitCancelLabel.Size = UDim2.new(0.3, 0, 0, 18)
waitCancelLabel.Position = UDim2.new(0, 10, 0, 235)
waitCancelLabel.BackgroundTransparency = 1
waitCancelLabel.Text = "Cancel:"
waitCancelLabel.TextColor3 = Color3.new(0.8, 0.8, 0.8)
waitCancelLabel.Font = Enum.Font.Gotham
waitCancelLabel.TextSize = 11
waitCancelLabel.TextXAlignment = Enum.TextXAlignment.Left
waitCancelLabel.Parent = mainFrame

local waitCancelBox = Instance.new("TextBox")
waitCancelBox.Size = UDim2.new(0.3, 0, 0, 22)
waitCancelBox.Position = UDim2.new(0, 10, 0, 253)
waitCancelBox.BackgroundColor3 = Color3.new(0.15, 0.15, 0.25)
waitCancelBox.TextColor3 = Color3.new(1, 1, 1)
waitCancelBox.Font = Enum.Font.Code
waitCancelBox.TextSize = 11
waitCancelBox.Text = "0.1"
waitCancelBox.ClearTextOnFocus = false
waitCancelBox.Parent = mainFrame

-- Wait Charge
local waitChargeLabel = Instance.new("TextLabel")
waitChargeLabel.Size = UDim2.new(0.3, 0, 0, 18)
waitChargeLabel.Position = UDim2.new(0.35, 0, 0, 235)
waitChargeLabel.BackgroundTransparency = 1
waitChargeLabel.Text = "Charge:"
waitChargeLabel.TextColor3 = Color3.new(0.8, 0.8, 0.8)
waitChargeLabel.Font = Enum.Font.Gotham
waitChargeLabel.TextSize = 11
waitChargeLabel.TextXAlignment = Enum.TextXAlignment.Left
waitChargeLabel.Parent = mainFrame

local waitChargeBox = Instance.new("TextBox")
waitChargeBox.Size = UDim2.new(0.3, 0, 0, 22)
waitChargeBox.Position = UDim2.new(0.35, 0, 0, 253)
waitChargeBox.BackgroundColor3 = Color3.new(0.15, 0.15, 0.25)
waitChargeBox.TextColor3 = Color3.new(1, 1, 1)
waitChargeBox.Font = Enum.Font.Code
waitChargeBox.TextSize = 11
waitChargeBox.Text = "0.2"
waitChargeBox.ClearTextOnFocus = false
waitChargeBox.Parent = mainFrame

-- Wait Minigame
local waitMinigameLabel = Instance.new("TextLabel")
waitMinigameLabel.Size = UDim2.new(0.3, 0, 0, 18)
waitMinigameLabel.Position = UDim2.new(0.68, 0, 0, 235)
waitMinigameLabel.BackgroundTransparency = 1
waitMinigameLabel.Text = "Minigame:"
waitMinigameLabel.TextColor3 = Color3.new(0.8, 0.8, 0.8)
waitMinigameLabel.Font = Enum.Font.Gotham
waitMinigameLabel.TextSize = 11
waitMinigameLabel.TextXAlignment = Enum.TextXAlignment.Left
waitMinigameLabel.Parent = mainFrame

local waitMinigameBox = Instance.new("TextBox")
waitMinigameBox.Size = UDim2.new(0.3, 0, 0, 22)
waitMinigameBox.Position = UDim2.new(0.68, 0, 0, 253)
waitMinigameBox.BackgroundColor3 = Color3.new(0.15, 0.15, 0.25)
waitMinigameBox.TextColor3 = Color3.new(1, 1, 1)
waitMinigameBox.Font = Enum.Font.Code
waitMinigameBox.TextSize = 11
waitMinigameBox.Text = "0.2"
waitMinigameBox.ClearTextOnFocus = false
waitMinigameBox.Parent = mainFrame

-- Log Box
local logBox = Instance.new("TextBox")
logBox.Size = UDim2.new(1, -20, 0, 100)
logBox.Position = UDim2.new(0, 10, 0, 285)
logBox.BackgroundColor3 = Color3.new(0.05, 0.05, 0.1)
logBox.TextColor3 = Color3.new(0.5, 1, 0.5)
logBox.Font = Enum.Font.Code
logBox.TextSize = 10
logBox.TextWrapped = true
logBox.TextXAlignment = Enum.TextXAlignment.Left
logBox.TextYAlignment = Enum.TextYAlignment.Top
logBox.ReadOnly = true
logBox.MultiLine = true
logBox.ClearTextOnFocus = false
logBox.Parent = mainFrame

-- Status Label
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -20, 0, 20)
statusLabel.Position = UDim2.new(0, 10, 0, 390)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Status: Ready"
statusLabel.TextColor3 = Color3.new(0.5, 1, 0.5)
statusLabel.Font = Enum.Font.Code
statusLabel.TextSize = 11
statusLabel.Parent = mainFrame

-- ===== HELPER FUNCTIONS =====
local logMessages = {}
local function addLog(msg)
    table.insert(logMessages, msg)
    if #logMessages > 12 then
        table.remove(logMessages, 1)
    end
    logBox.Text = table.concat(logMessages, "\n")
end

local function setStatus(msg)
    statusLabel.Text = "Status: " .. msg
    addLog("[" .. msg .. "]")
end

-- ===== REMOTE FINDER (SMART SEARCH) =====
local function FindRemoteSmart(partialName)
    -- Cari di ReplicatedStorage terlebih dahulu
    for _, v in pairs(ReplicatedStorage:GetDescendants()) do
        if v.Name:lower():find(partialName:lower()) and (v:IsA("RemoteEvent") or v:IsA("RemoteFunction")) then
            return v
        end
    end
    -- Fallback: cari di Character
    if player.Character then
        for _, v in pairs(player.Character:GetDescendants()) do
            if v.Name:lower():find(partialName:lower()) and (v:IsA("RemoteEvent") or v:IsA("RemoteFunction")) then
                return v
            end
        end
    end
    return nil
end

-- ===== REMOTE LOADING =====
local remotes = {}

local function SetupRemotes()
    addLog("=== Scanning Remotes ===")
    remotes.cancelInput = FindRemoteSmart("Cancel")
    remotes.chargeRod = FindRemoteSmart("Charge")
    remotes.minigameStart = FindRemoteSmart("Minigame")
    remotes.fishingCompleted = FindRemoteSmart("FishingComplet")
    
    -- Log hasil pencarian
    if remotes.cancelInput then addLog("✓ Cancel: " .. remotes.cancelInput.Name) else addLog("✗ Cancel: NOT FOUND") end
    if remotes.chargeRod then addLog("✓ Charge: " .. remotes.chargeRod.Name) else addLog("✗ Charge: NOT FOUND") end
    if remotes.minigameStart then addLog("✓ Minigame: " .. remotes.minigameStart.Name) else addLog("✗ Minigame: NOT FOUND") end
    if remotes.fishingCompleted then addLog("✓ Completed: " .. remotes.fishingCompleted.Name) else addLog("✗ Completed: NOT FOUND") end
    addLog("=======================")
    
    if remotes.chargeRod and remotes.minigameStart and remotes.fishingCompleted then
        return true
    else
        return false
    end
end

-- Setup remotes saat load
SetupRemotes()

-- ===== PARSING FUNCTIONS =====
local function parseMinigame(str)
    local args = {}
    local pos = 1
    while true do
        local comma = string.find(str, ",", pos)
        if not comma then
            local val = string.sub(str, pos)
            val = string.gsub(val, "^%s+", "")
            val = string.gsub(val, "%s+$", "")
            if val ~= "" then
                table.insert(args, tonumber(val) or val)
            end
            break
        else
            local val = string.sub(str, pos, comma - 1)
            val = string.gsub(val, "^%s+", "")
            val = string.gsub(val, "%s+$", "")
            if val ~= "" then
                table.insert(args, tonumber(val) or val)
            end
            pos = comma + 1
        end
    end
    return args
end

local function parseNum(str, default)
    local n = tonumber(str)
    return n and math.max(0.01, n) or (default or 0.1)
end

-- ===== LOOP LOGIC =====
local isLooping = false
local loopCount = 0

local function executeLoop()
    loopCount = 0
    while isLooping do
        -- 1. Cancel
        if remotes.cancelInput then
            pcall(function()
                remotes.cancelInput:FireServer()
            end)
        end
        wait(parseNum(waitCancelBox.Text, 0.1))
        
        -- 2. Charge
        if remotes.chargeRod then
            pcall(function()
                remotes.chargeRod:InvokeServer(tick())
            end)
        end
        wait(parseNum(waitChargeBox.Text, 0.2))
        
        -- 3. Minigame
        if remotes.minigameStart then
            pcall(function()
                local args = parseMinigame(minigameBox.Text)
                table.insert(args, tick())
                remotes.minigameStart:InvokeServer(unpack(args))
            end)
        end
        wait(parseNum(waitMinigameBox.Text, 0.2))
        
        -- 4. Completed
        if remotes.fishingCompleted then
            pcall(function()
                remotes.fishingCompleted:FireServer()
            end)
        end
        
        loopCount = loopCount + 1
        setStatus("Running [" .. loopCount .. "]")
        wait(0.1)
    end
end


-- Gunakan MouseButton1Click agar kompatibel di Android
startBtn.MouseButton1Click:Connect(function()
    if not isLooping then
        addLog(">>> START BUTTON <<<")
        -- Cek remotes
        if not remotes.chargeRod or not remotes.minigameStart or not remotes.fishingCompleted then
            addLog("Scanning remotes...")
            if not SetupRemotes() then
                setStatus("ERROR: Remotes not found!")
                return
            end
        end
        isLooping = true
        setStatus("RUNNING")
        spawn(executeLoop)
    else
        addLog("Already running!")
    end
end)

stopBtn.MouseButton1Click:Connect(function()
    addLog(">>> STOP BUTTON <<<")
    isLooping = false
    loopCount = 0
    setStatus("STOPPED")
end)

addLog("Script Ready! Press SCAN or START")
