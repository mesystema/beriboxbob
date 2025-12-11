--[[ 
    FISH-IT BOT v31 (FINAL FIX - RONIX)
    - UI: Restored (Dikembalikan)
    - Logic: Blind Spam Method (Anti-Bug)
    - Remote Names: Updated based on Log (ChargeFishingRod, etc)
    - Safety: WaitGame 2.4s included
]]

local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- [[ CONFIGURATION ]] --
local BotConfig = {
    IsRunning = false,
    
    -- Settingan ini sudah disesuaikan agar INSTANT tapi AMAN
    WaitThrow = 0,      -- 0 = Langsung deteksi setelah lempar
    WaitBite = 0,       -- 0 = Digantikan oleh Loop Spam Request
    WaitGame = 2.4,     -- 2.4 = Wajib ada delay agar server menerima hasil
    WaitCool = 0.5,     -- 0.5 = Jeda aman antar ikan
    
    CastPower = 1.0,
    WaterDepthOffset = 15
}

-- CLEANUP OLD UI
if CoreGui:FindFirstChild("FishBotUI_V31") then CoreGui.FishBotUI_V31:Destroy() end
if LocalPlayer.PlayerGui:FindFirstChild("FishBotUI_V31") then LocalPlayer.PlayerGui.FishBotUI_V31:Destroy() end

local Remotes = { Charge = nil, Minigame = nil, Finish = nil }

-- [[ UI CREATION ]] --
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "FishBotUI_V31"
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 9999
-- Coba pasang di CoreGui dulu (untuk eksekutor), kalau gagal ke PlayerGui
pcall(function() ScreenGui.Parent = CoreGui end)
if not ScreenGui.Parent then ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

-- MAIN FRAME
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 420, 0, 450)
MainFrame.Position = UDim2.new(0.5, -210, 0.1, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)

-- TITLE
local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -40, 0, 30)
TitleLabel.Position = UDim2.new(0, 10, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "📝 Fish-It Fix (Log Based)"
TitleLabel.TextColor3 = Color3.fromRGB(0, 255, 127)
TitleLabel.Font = Enum.Font.GothamBlack
TitleLabel.TextSize = 14
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = MainFrame

-- MINIMIZE BUTTON
local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 30, 0, 30)
MinBtn.Position = UDim2.new(1, -30, 0, 0)
MinBtn.BackgroundTransparency = 1
MinBtn.Text = "_"
MinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinBtn.Font = Enum.Font.GothamBold
MinBtn.TextSize = 18
MinBtn.Parent = MainFrame

-- SETTING FRAME
local SettingFrame = Instance.new("Frame")
SettingFrame.Size = UDim2.new(1, -20, 0, 180)
SettingFrame.Position = UDim2.new(0, 10, 0, 35)
SettingFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
SettingFrame.Parent = MainFrame
Instance.new("UICorner", SettingFrame).CornerRadius = UDim.new(0, 6)

local UIListSettings = Instance.new("UIListLayout")
UIListSettings.FillDirection = Enum.FillDirection.Horizontal
UIListSettings.SortOrder = Enum.SortOrder.LayoutOrder
UIListSettings.Padding = UDim.new(0, 5)
UIListSettings.Wraps = true
UIListSettings.Parent = SettingFrame

-- INPUT CREATOR
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

-- SETUP INPUTS
CreateInput("1. Jeda Lempar (0 recommended)", "WaitThrow", BotConfig.WaitThrow)
CreateInput("2. Jeda Gigit (0 recommended)", "WaitBite", BotConfig.WaitBite)
CreateInput("3. Lama Minigame (Min 2.4s)", "WaitGame", BotConfig.WaitGame)
CreateInput("4. Cooldown (0.5s)", "WaitCool", BotConfig.WaitCool)
CreateInput("Power (1-100)", "CastPower", BotConfig.CastPower)
CreateInput("Water Depth", "WaterDepthOffset", BotConfig.WaterDepthOffset)

-- LOG FRAME
local LogFrame = Instance.new("ScrollingFrame")
LogFrame.Size = UDim2.new(1, -20, 1, -270)
LogFrame.Position = UDim2.new(0, 10, 0, 225)
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
ScanBtn.Text = "🔍 FIX REMOTE"
ScanBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ScanBtn.Font = Enum.Font.GothamBold
ScanBtn.TextSize = 12
ScanBtn.Parent = BtnContainer
Instance.new("UICorner", ScanBtn).CornerRadius = UDim.new(0, 6)

-- LOG HELPER
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
    Label.RichText = true
    Label.Text = text
    Label.TextColor3 = color
    Label.Size = UDim2.new(1, 0, 0, 0)
    Label.AutomaticSize = Enum.AutomaticSize.Y
    Label.Parent = LogFrame
    
    if #LogFrame:GetChildren() > 50 then 
        local first = LogFrame:GetChildren()[1]
        if first and first ~= UIListLog then first:Destroy() end
    end
    LogFrame.CanvasPosition = Vector2.new(0, LogFrame.AbsoluteCanvasSize.Y)
end

-- [[ LOGIC FUNCTIONS ]] --

local function ForceBobberDown()
    task.spawn(function()
        local startTime = tick()
        while tick() - startTime < 0.8 do
            for _, v in pairs(workspace:GetChildren()) do
                if v.Name:find("Bobber") or v.Name:find("FishingBobber") or v.Name:find("Float") then
                    local part = v:IsA("BasePart") and v or v:FindFirstChildWhichIsA("BasePart")
                    if part then
                        part.Velocity = Vector3.new(0, -60, 0)
                    end
                end
            end
            task.wait()
        end
    end)
end

local function KillAnimations()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        for _, track in pairs(LocalPlayer.Character.Humanoid:GetPlayingAnimationTracks()) do 
            track:Stop() 
        end
    end
end

-- REMOTE FINDER (UPDATED BASED ON LOGS)
local function SetupRemotes()
    AddLog("🔍 Mencari Remote...", "info")
    
    local function Find(name, typeName)
        for _, v in pairs(ReplicatedStorage:GetDescendants()) do
            if v.Name == name and v:IsA(typeName) then return v end
        end
        return nil
    end

    -- 1. ChargeFishingRod (Invoke)
    Remotes.Charge = Find("ChargeFishingRod", "RemoteFunction")
    if not Remotes.Charge then Remotes.Charge = Find("ChargeFish", "RemoteFunction") end -- Fallback
    
    -- 2. RequestFishingMinigameStarted (Invoke)
    Remotes.Minigame = Find("RequestFishingMinigameStarted", "RemoteFunction")
    if not Remotes.Minigame then Remotes.Minigame = Find("Minigame", "RemoteFunction") end -- Fallback

    -- 3. FishingCompleted (Fire)
    Remotes.Finish = Find("FishingCompleted", "RemoteEvent")
    if not Remotes.Finish then Remotes.Finish = Find("FishingComplet", "RemoteEvent") end -- Fallback

    if Remotes.Charge and Remotes.Minigame and Remotes.Finish then
        AddLog("✅ Remote Ditemukan!", "success")
        AddLog("• Charge: "..Remotes.Charge.Name, "debug")
        AddLog("• Game: "..Remotes.Minigame.Name, "debug")
        AddLog("• Finish: "..Remotes.Finish.Name, "debug")
        return true
    else
        AddLog("❌ Gagal menemukan Remote.", "error")
        return false
    end
end

ScanBtn.MouseButton1Click:Connect(function() SetupRemotes() end)

-- [[ MAIN BOT LOOP (FIXED LOGIC) ]] --
local function StartBot()
    task.spawn(function()
        if not Remotes.Charge then if not SetupRemotes() then BotConfig.IsRunning = false; return end end
        
        AddLog("⚙️ Bot Started (Spam Logic)", "info")
        
        while BotConfig.IsRunning do
            -- A. LEMPAR
            AddLog("1. Melempar...", "info")
            KillAnimations()
            
            -- InvokeServer akan 'Yield' (Pause) sampai server bilang lemparan selesai
            pcall(function() 
                Remotes.Charge:InvokeServer(workspace.DistributedGameTime) 
            end)
            
            ForceBobberDown()
            
            -- B. TUNGGU GIGITAN (SPAM REQUEST)
            AddLog("🐟 Mencari Ikan...", "warn")
            
            local Ticket = nil
            local StartWait = tick()
            local MaxWait = 20 -- Timeout biar gak macet selamanya
            
            repeat
                -- Spam setiap 0.25 detik
                task.wait(0.25)
                
                local randomID = math.random(100000000, 999999999)
                local Success, Response = nil, nil
                
                -- Coba Request ke Server
                Success, Response = pcall(function()
                    return Remotes.Minigame:InvokeServer(BotConfig.CastPower, randomID, os.time())
                end)
                
                -- Cek apakah server ngasih tiket
                if Success and Response ~= nil then
                    Ticket = Response
                    AddLog("✅ Ikan Nyangkut!", "success")
                end
                
                if (tick() - StartWait) > MaxWait then
                    AddLog("⚠️ Timeout. Reset.", "error")
                    break 
                end
            until Ticket ~= nil or not BotConfig.IsRunning
            
            -- C. EKSEKUSI TIKET (JIKA ADA)
            if Ticket then
                -- Tunggu durasi minigame agar server tidak reject
                if BotConfig.WaitGame > 0 then
                    AddLog("⏳ Main Game ("..BotConfig.WaitGame.."s)...", "warn")
                    task.wait(BotConfig.WaitGame)
                end
                
                -- Kirim Selesai
                pcall(function()
                    Remotes.Finish:FireServer(Ticket)
                end)
                
                KillAnimations()
                AddLog("✨ SELESAI.", "success")
            end
            
            -- D. COOLDOWN
            task.wait(BotConfig.WaitCool)
            if not BotConfig.IsRunning then break end
        end
        
        ToggleBtn.Text = "▶ START"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
        AddLog("Bot Stopped.", "warn")
    end)
end

-- UI INTERACTION
ToggleBtn.MouseButton1Click:Connect(function()
    BotConfig.IsRunning = not BotConfig.IsRunning
    if BotConfig.IsRunning then
        ToggleBtn.Text = "⏹ STOP"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
        StartBot()
    else
        ToggleBtn.Text = "▶ START"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
    end
end)

local isMinimized = false
MinBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    if isMinimized then
        MainFrame:TweenSize(UDim2.new(0, 150, 0, 30), "Out", "Quad", 0.3, true)
        MinBtn.Text = "+"
        SettingFrame.Visible = false
        LogFrame.Visible = false
        BtnContainer.Visible = false
    else
        MainFrame:TweenSize(UDim2.new(0, 420, 0, 450), "Out", "Quad", 0.3, true)
        MinBtn.Text = "_"
        task.wait(0.2)
        SettingFrame.Visible = true
        LogFrame.Visible = true
        BtnContainer.Visible = true
    end
end)

-- DRAGGABLE
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
