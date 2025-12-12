--[[ 
    FISH-IT BOT v26 (FINAL UI & STOPWATCH)
    Fitur Baru:
    1. Input 'Water Depth' di UI (Untuk teleport pelampung).
    2. Stopwatch: Menghitung durasi per ikan (Casting -> Catching).
    3. Log Detail: Mencatat setiap langkah proses.
]]

local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- [[ DEFAULT CONFIG ]] --
local BotConfig = {
    IsRunning = false,
    
    ChargeValue = 1,           -- Nilai charge (contoh: 1)
    MinigameValues = "1,1,1",  -- Nilai minigame (comma-separated)
    WaitAfterCancel = 0.1,     -- Tunggu setelah cancel
    WaitAfterCharge = 0.2,     -- Tunggu setelah charge
    WaitAfterMinigame = 0.2,   -- Tunggu setelah minigame request
    WaterDepthOffset = 15      -- Kedalaman teleport
}

-- CLEANUP
if CoreGui:FindFirstChild("Boim-Fishilitv2") then CoreGui.FishBotUI_V26:Destroy() end

local Remotes = { Charge = nil, Minigame = nil, Finish = nil, Cancel = nil }

-- [[ UI CREATION ]] --
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "Boim-Fishilitv2"
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 9999
pcall(function() ScreenGui.Parent = CoreGui end)
if not ScreenGui.Parent then ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

-- MAIN FRAME (Lebih Tinggi dikit buat input tambahan)
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 420, 0, 400) 
MainFrame.Position = UDim2.new(0.5, -210, 0.15, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)

-- TITLE
local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -40, 0, 30)
TitleLabel.Position = UDim2.new(0, 10, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "⏱️ Boim-Fishilitv2 (Stopwatch Mode)"
TitleLabel.TextColor3 = Color3.fromRGB(255, 165, 0) -- Orange
TitleLabel.Font = Enum.Font.GothamBlack
TitleLabel.TextSize = 14
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = MainFrame

-- MINIMIZE
local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 30, 0, 30)
MinBtn.Position = UDim2.new(1, -30, 0, 0)
MinBtn.BackgroundTransparency = 1
MinBtn.Text = "_"
MinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinBtn.Font = Enum.Font.GothamBold
MinBtn.TextSize = 18
MinBtn.Parent = MainFrame

-- AREA SETTING
local SettingFrame = Instance.new("Frame")
SettingFrame.Size = UDim2.new(1, -20, 0, 150) -- Diperbesar untuk muat 5 input
SettingFrame.Position = UDim2.new(0, 10, 0, 35)
SettingFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
SettingFrame.Parent = MainFrame
Instance.new("UICorner", SettingFrame).CornerRadius = UDim.new(0, 6)

local UIListSettings = Instance.new("UIListLayout")
UIListSettings.FillDirection = Enum.FillDirection.Horizontal
UIListSettings.SortOrder = Enum.SortOrder.LayoutOrder
UIListSettings.Padding = UDim.new(0, 5)
UIListSettings.Wraps = true
UIListSettings.Parent = SettingFrame

-- INPUT FUNCTION
local function CreateInput(name, configKey, defaultVal)
    local Container = Instance.new("Frame")
    Container.Size = UDim2.new(0.48, 0, 0, 45)
    Container.BackgroundTransparency = 1
    Container.Parent = SettingFrame
    
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, 0, 0, 20)
    Label.BackgroundTransparency = 1
    Label.Text = name
    Label.TextColor3 = Color3.fromRGB(180, 180, 180)
    Label.Font = Enum.Font.GothamBold
    Label.TextSize = 10
    Label.Parent = Container
    
    local TextBox = Instance.new("TextBox")
    TextBox.Size = UDim2.new(1, 0, 0, 20)
    TextBox.Position = UDim2.new(0, 0, 0, 20)
    TextBox.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
    TextBox.Text = tostring(defaultVal)
    TextBox.TextColor3 = Color3.fromRGB(255, 255, 0)
    TextBox.Font = Enum.Font.Code
    TextBox.TextSize = 12
    TextBox.Parent = Container
    Instance.new("UICorner", TextBox).CornerRadius = UDim.new(0, 4)
    
    TextBox.FocusLost:Connect(function()
        local num = tonumber(TextBox.Text)
        if num then
            BotConfig[configKey] = num
            TextBox.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
            task.wait(0.2)
            TextBox.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
        else
            TextBox.Text = tostring(BotConfig[configKey])
        end
    end)
end

-- BUAT 5 INPUT
CreateInput("Charge Value", "ChargeValue", BotConfig.ChargeValue)
CreateInput("Minigame Val", "MinigameValues", BotConfig.MinigameValues)
CreateInput("Wait Cancel", "WaitAfterCancel", BotConfig.WaitAfterCancel)
CreateInput("Wait Charge", "WaitAfterCharge", BotConfig.WaitAfterCharge)
CreateInput("Wait Minigame", "WaitAfterMinigame", BotConfig.WaitAfterMinigame)

-- LOG DISPLAY
local LogFrame = Instance.new("ScrollingFrame")
LogFrame.Size = UDim2.new(1, -20, 1, -240)
LogFrame.Position = UDim2.new(0, 10, 0, 195)
LogFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
LogFrame.ScrollBarThickness = 4
LogFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
LogFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
LogFrame.Parent = MainFrame

local UIListLog = Instance.new("UIListLayout")
UIListLog.SortOrder = Enum.SortOrder.LayoutOrder
UIListLog.Padding = UDim.new(0, 2)
UIListLog.Parent = LogFrame

-- BUTTONS
local BtnContainer = Instance.new("Frame")
BtnContainer.Size = UDim2.new(1, -20, 0, 35)
BtnContainer.Position = UDim2.new(0, 10, 1, -40)
BtnContainer.BackgroundTransparency = 1
BtnContainer.Parent = MainFrame

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0.65, 0, 1, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
ToggleBtn.Text = "▶ START"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 12
ToggleBtn.Parent = BtnContainer
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0, 6)

local ScanBtn = Instance.new("TextButton")
ScanBtn.Size = UDim2.new(0.32, 0, 1, 0)
ScanBtn.Position = UDim2.new(0.68, 0, 0, 0)
ScanBtn.BackgroundColor3 = Color3.fromRGB(52, 152, 219)
ScanBtn.Text = "🔍 SCAN"
ScanBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ScanBtn.Font = Enum.Font.GothamBold
ScanBtn.TextSize = 12
ScanBtn.Parent = BtnContainer
Instance.new("UICorner", ScanBtn).CornerRadius = UDim.new(0, 6)

-- HELPER LOG
local function AddLog(text, colorType)
    local color = Color3.fromRGB(255, 255, 255)
    if colorType == "success" then color = Color3.fromRGB(46, 204, 113) end
    if colorType == "warn" then color = Color3.fromRGB(241, 196, 15) end
    if colorType == "error" then color = Color3.fromRGB(231, 76, 60) end
    if colorType == "info" then color = Color3.fromRGB(52, 152, 219) end
    if colorType == "time" then color = Color3.fromRGB(255, 100, 255) end -- Warna Ungu Stopwatch

    local Label = Instance.new("TextLabel")
    Label.BackgroundTransparency = 1
    Label.Font = Enum.Font.Code
    Label.TextSize = 11
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.TextWrapped = true
    Label.RichText = true
    Label.Text = text
    Label.TextColor3 = color
    Label.Size = UDim2.new(1, 0, 0, 0)
    Label.AutomaticSize = Enum.AutomaticSize.Y 
    Label.Parent = LogFrame
    LogFrame.CanvasPosition = Vector2.new(0, LogFrame.AbsoluteCanvasSize.Y)
    
    if #LogFrame:GetChildren() > 60 then 
        local first = LogFrame:GetChildren()[1]
        if first and first ~= UIListLog then first:Destroy() end
    end
end

-- [[ HELPER: Parse Minigame Values ]] --
local function ParseMinigameValues(str)
    local args = {}
    local pos = 1
    while true do
        local comma = string.find(str, ",", pos)
        if not comma then
            local val = string.sub(str, pos)
            val = string.gsub(val, "^%s+", ""):gsub("%s+$", "")
            if val ~= "" then
                table.insert(args, tonumber(val) or val)
            end
            break
        else
            local val = string.sub(str, pos, comma - 1)
            val = string.gsub(val, "^%s+", ""):gsub("%s+$", "")
            if val ~= "" then
                table.insert(args, tonumber(val) or val)
            end
            pos = comma + 1
        end
    end
    return args
end

-- [[ PHYSICS & ANIM ]] --
local function ForceBobberDown()
    task.spawn(function()
        local startTime = tick()
        while tick() - startTime < 1.0 do
            for _, v in pairs(workspace:GetChildren()) do
                if (v.Name == "Bobber" or v.Name == "FishingBobber" or v.Name == "Float") then
                    local part = v:IsA("BasePart") and v or v:FindFirstChildWhichIsA("BasePart")
                    if part and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                        -- Teleport sesuai settingan UI
                        local playerPos = LocalPlayer.Character.HumanoidRootPart.Position
                        part.CFrame = CFrame.new(playerPos + (LocalPlayer.Character.HumanoidRootPart.CFrame.LookVector * 10) - Vector3.new(0, BotConfig.WaterDepthOffset, 0))
                        part.Velocity = Vector3.new(0, -50, 0)
                    end
                end
            end
            task.wait()
        end
    end)
end

local function KillAnimations()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        local Humanoid = LocalPlayer.Character.Humanoid
        for _, track in pairs(Humanoid:GetPlayingAnimationTracks()) do track:Stop() end
    end
end

-- [[ REMOTE FINDER ]] --
local function FindRemoteSmart(partialName)
    for _, v in pairs(ReplicatedStorage:GetDescendants()) do
        if v.Name:lower():find(partialName:lower()) and (v:IsA("RemoteEvent") or v:IsA("RemoteFunction")) then return v end
    end
    if LocalPlayer.Character then
        for _, v in pairs(LocalPlayer.Character:GetDescendants()) do
            if v.Name:lower():find(partialName:lower()) and (v:IsA("RemoteEvent") or v:IsA("RemoteFunction")) then return v end
        end
    end
    return nil
end

local function SetupRemotes()
    Remotes.Cancel = FindRemoteSmart("Cancel")
    Remotes.Charge = FindRemoteSmart("ChargeFish")
    Remotes.Minigame = FindRemoteSmart("Minigame")
    Remotes.Finish = FindRemoteSmart("FishingComplet")
    if Remotes.Charge and Remotes.Minigame and Remotes.Finish then
        AddLog("✅ Sistem Siap. Pegang Pancingan!", "success")
        return true
    else
        AddLog("❌ Remote Gagal. Coba Scan lagi.", "error")
        AddLog("Cancel: " .. (Remotes.Cancel and "OK" or "MISS"), "warn")
        AddLog("Charge: " .. (Remotes.Charge and "OK" or "MISS"), "warn")
        AddLog("Minigame: " .. (Remotes.Minigame and "OK" or "MISS"), "warn")
        AddLog("Finish: " .. (Remotes.Finish and "OK" or "MISS"), "warn")
        return false
    end
end

ScanBtn.MouseButton1Click:Connect(function() SetupRemotes() end)

-- [[ MAIN ENGINE ]] --
local function StartBot()
    task.spawn(function()
        if not Remotes.Charge then if not SetupRemotes() then BotConfig.IsRunning = false; return end end
        
        AddLog("⚙️ Bot Jalan. Logic: Cancel -> Charge -> Minigame -> Finish", "info")

        while BotConfig.IsRunning do
            -- MULAI STOPWATCH
            local startTime = tick()
            
            -- 1. CANCEL FISHING INPUT
            AddLog("1. Membatalkan Input Sebelumnya...", "info")
            if Remotes.Cancel then
                pcall(function() 
                    Remotes.Cancel:FireServer()
                    AddLog("   ✓ Cancel sent", "success")
                end)
            else
                AddLog("   - Cancel tidak ada (optional)", "warn")
            end
            task.wait(BotConfig.WaitAfterCancel)
            
            -- 2. CHARGE FISHING ROD
            AddLog("2. Mengisi Ulur Pancingan (Value: " .. BotConfig.ChargeValue .. ")...", "info")
            local chargeOk = false
            if Remotes.Charge then
                chargeOk = pcall(function() 
                    Remotes.Charge:InvokeServer(tick())
                    AddLog("   ✓ Charge sent", "success")
                end)
            end
            if not chargeOk then AddLog("   ✗ Charge failed", "error") end
            task.wait(BotConfig.WaitAfterCharge)
            
            -- 3. REQUEST MINIGAME
            AddLog("3. Request Minigame (Values: " .. BotConfig.MinigameValues .. ")...", "info")
            local minigameArgs = ParseMinigameValues(BotConfig.MinigameValues)
            table.insert(minigameArgs, tick()) -- Add timestamp
            
            local minigameOk = false
            local minigameResponse = nil
            if Remotes.Minigame then
                minigameOk, minigameResponse = pcall(function() 
                    return Remotes.Minigame:InvokeServer(unpack(minigameArgs))
                end)
                if minigameOk then
                    AddLog("   ✓ Minigame request sent", "success")
                else
                    AddLog("   ✗ Minigame request failed", "error")
                end
            end
            task.wait(BotConfig.WaitAfterMinigame)
            
            -- 4. FINISH / FISHING COMPLETED
            if minigameOk and minigameResponse then
                AddLog("4. Menyelesaikan Minigame (Tarik Ikan)...", "info")
                local finishOk = pcall(function() 
                    Remotes.Finish:FireServer(minigameResponse)
                    AddLog("   ✓ Finish sent", "success")
                end)
                
                if not finishOk then 
                    AddLog("   ✗ Finish failed", "error")
                end
            else
                AddLog("4. Skip Finish (Minigame tidak success)", "warn")
            end
            
            -- STOPWATCH SELESAI
            local totalTime = tick() - startTime
            local timeFormatted = string.format("%.2f", totalTime)
            
            AddLog("✨ SIKLUS SELESAI! (⏱️ " .. timeFormatted .. " Detik)", "time")
            task.wait(0.5)
            
            if not BotConfig.IsRunning then break end
        end
        
        ToggleBtn.Text = "▶ START"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
        AddLog("Bot Stopped", "warn")
    end)
end

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
        MainFrame:TweenSize(UDim2.new(0, 150, 0, 30), "Out", "Quad", 0.3, true)
        MinBtn.Text = "+"; SettingFrame.Visible = false; LogFrame.Visible = false; BtnContainer.Visible = false
    else
        MainFrame:TweenSize(UDim2.new(0, 420, 0, 400), "Out", "Quad", 0.3, true)
        MinBtn.Text = "_"; task.wait(0.2); SettingFrame.Visible = true; LogFrame.Visible = true; BtnContainer.Visible = true
    end
end)

-- Dragging
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
