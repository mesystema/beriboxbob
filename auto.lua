--[[ 
    TURBO FISH-IT BOT v8 (AUTO-FIND FIX)
    Fitur: 
    - Auto-Search Remote (Tidak peduli nama folder)
    - Anti-Crash jika remote belum load
    - Turbo Mode (Instant Catch)
]]

local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- KONFIGURASI BOT
local BotConfig = {
    IsRunning = false,
    ActionDelay = 0.15, -- Sedikit diperlambat biar server nangkep sinyal
    Cooldown = 0.5,
    CastPower = 1.0
}

-- CONFIG UI
local isMinimized = false
local expandedSize = UDim2.new(0, 380, 0, 240)
local minimizedSize = UDim2.new(0, 150, 0, 30)

-- BERSIHKAN UI LAMA
if CoreGui:FindFirstChild("FishBotUI_V8") then
    CoreGui.FishBotUI_V8:Destroy()
end

local Remotes = { Equip = nil, Charge = nil, Minigame = nil, Finish = nil }

-- UI SETUP
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "FishBotUI_V8"
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 9999
pcall(function() ScreenGui.Parent = CoreGui end)
if not ScreenGui.Parent then ScreenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui") end

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = expandedSize
MainFrame.Position = UDim2.new(0.5, -190, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -40, 0, 30)
TitleLabel.Position = UDim2.new(0, 10, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "🔎 Auto-Find Bot v8"
TitleLabel.TextColor3 = Color3.fromRGB(0, 255, 255) -- Cyan
TitleLabel.Font = Enum.Font.GothamBlack
TitleLabel.TextSize = 14
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = MainFrame

local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 30, 0, 30)
MinBtn.Position = UDim2.new(1, -30, 0, 0)
MinBtn.BackgroundTransparency = 1
MinBtn.Text = "_"
MinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinBtn.Font = Enum.Font.GothamBold
MinBtn.TextSize = 18
MinBtn.Parent = MainFrame

local ContentFrame = Instance.new("Frame")
ContentFrame.Size = UDim2.new(1, 0, 1, -35)
ContentFrame.Position = UDim2.new(0, 0, 0, 35)
ContentFrame.BackgroundTransparency = 1
ContentFrame.Parent = MainFrame

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0.95, 0, 0, 35)
ToggleBtn.Position = UDim2.new(0.025, 0, 0, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
ToggleBtn.Text = "▶ START"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 14
ToggleBtn.Parent = ContentFrame
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0, 6)

local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Size = UDim2.new(0.95, 0, 1, -45)
ScrollFrame.Position = UDim2.new(0.025, 0, 0, 45)
ScrollFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
ScrollFrame.ScrollBarThickness = 4
ScrollFrame.Parent = ContentFrame
local UIListLayout = Instance.new("UIListLayout")
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 2)
UIListLayout.Parent = ScrollFrame

-- FUNGSI LOG
local function AddLog(text, colorType)
    local color = Color3.fromRGB(255, 255, 255)
    if colorType == "success" then color = Color3.fromRGB(46, 204, 113) end
    if colorType == "warn" then color = Color3.fromRGB(241, 196, 15) end
    if colorType == "error" then color = Color3.fromRGB(231, 76, 60) end
    if colorType == "info" then color = Color3.fromRGB(52, 152, 219) end

    local Label = Instance.new("TextLabel")
    Label.BackgroundTransparency = 1
    Label.Font = Enum.Font.Code
    Label.TextSize = 11
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.TextWrapped = true
    Label.Text = text
    Label.TextColor3 = color
    Label.AutomaticSize = Enum.AutomaticSize.Y
    Label.Size = UDim2.new(1, 0, 0, 0)
    Label.Parent = ScrollFrame
    ScrollFrame.CanvasPosition = Vector2.new(0, 99999)
    if #ScrollFrame:GetChildren() > 40 then ScrollFrame:GetChildren()[1]:Destroy() end
end

-- [[ FUNGSI AUTO FIND (DEEP SEARCH) ]] --
local function DeepSearchRemote(name)
    AddLog("Mencari: " .. name .. "...", "info")
    -- Cari di seluruh keturunan ReplicatedStorage
    for _, v in pairs(ReplicatedStorage:GetDescendants()) do
        if v.Name == name and (v:IsA("RemoteEvent") or v:IsA("RemoteFunction")) then
            return v
        end
    end
    return nil
end

local function SetupRemotes()
    -- Reset Remotes
    Remotes.Equip = DeepSearchRemote("EquipToolFromHotbar")
    Remotes.Charge = DeepSearchRemote("ChargeFishingRod")
    Remotes.Minigame = DeepSearchRemote("RequestFishingMinigameStarted")
    Remotes.Finish = DeepSearchRemote("FishingCompleted")
    
    if Remotes.Equip and Remotes.Charge and Remotes.Minigame and Remotes.Finish then
        AddLog("✅ Semua Remote Ditemukan!", "success")
        return true
    else
        AddLog("❌ GAGAL: Beberapa remote tidak ketemu.", "error")
        AddLog("Pastikan kamu sudah masuk game sepenuhnya.", "warn")
        return false
    end
end

-- [[ LOGIKA BOT ]] --
local function StartBot()
    task.spawn(function()
        -- Langkah 1: Setup Remote Dulu
        if not Remotes.Equip then
            local ready = SetupRemotes()
            if not ready then
                BotConfig.IsRunning = false
                ToggleBtn.Text = "▶ START"
                ToggleBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
                return 
            end
        end

        AddLog("🚀 Memulai Farming...", "success")

        while BotConfig.IsRunning do
            local success, err = pcall(function()
                -- 1. EQUIP
                Remotes.Equip:FireServer(1)
                task.wait(BotConfig.ActionDelay)

                -- 2. CHARGE
                Remotes.Charge:InvokeServer(workspace.DistributedGameTime)
                task.wait(BotConfig.ActionDelay)

                -- 3. MINIGAME
                local randomID = math.random(100000000, 999999999) 
                Remotes.Minigame:InvokeServer(BotConfig.CastPower, randomID, os.time())
                task.wait(BotConfig.ActionDelay)

                -- 4. FINISH
                Remotes.Finish:FireServer()
                
                AddLog("✅ Ikan Dapat!", "success")
                task.wait(BotConfig.Cooldown)
            end)

            if not success then
                AddLog("Error Script: " .. tostring(err), "error")
                task.wait(1)
            end
            
            if not BotConfig.IsRunning then break end
        end
    end)
end

-- INTERAKSI TOMBOL
ToggleBtn.MouseButton1Click:Connect(function()
    BotConfig.IsRunning = not BotConfig.IsRunning
    if BotConfig.IsRunning then
        ToggleBtn.Text = "⏹ STOP"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
        StartBot()
    else
        ToggleBtn.Text = "▶ START"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
        AddLog("Bot Berhenti.", "warn")
    end
end)

MinBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    if isMinimized then
        MainFrame:TweenSize(minimizedSize, "Out", "Quad", 0.3, true)
        MinBtn.Text = "+"
        ContentFrame.Visible = false
    else
        MainFrame:TweenSize(expandedSize, "Out", "Quad", 0.3, true)
        MinBtn.Text = "_"
        task.wait(0.2)
        ContentFrame.Visible = true
    end
end)

-- Draggable
local dragging, dragInput, dragStart, startPos
local function update(input)
    local delta = input.Position - dragStart
    MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end
MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true; dragStart = input.Position; startPos = MainFrame.Position
        input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
    end
end)
MainFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
end)
UserInputService.InputChanged:Connect(function(input) if input == dragInput and dragging then update(input) end end)
