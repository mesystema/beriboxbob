--[[ 
    FISH-IT BOT v16 (FULLY CONFIGURABLE)
    Fitur Baru:
    - Pengaturan 'BiteDelay': Kamu bisa atur berapa lama nunggu ikan menyambar.
    - Struktur Config yang lebih lengkap.
]]

local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- [[ ⚙️ PENGATURAN WAKTU (UBAH DISINI) ⚙️ ]] --
local BotConfig = {
    IsRunning = false,
    CastPower = 1.0,

    -- 1. Jeda Klik (Detik)
    -- Seberapa cepat bot menekan tombol (Jeda teknis).
    ActionDelay = 0.2, 

    -- 2. Waktu Nunggu Ikan (Detik) [FITUR BARU]
    -- Setelah lempar, nunggu berapa detik baru ikan gigit?
    -- Set 0.1 untuk Instan. Set 2.0 - 5.0 untuk Legit/Wajar.
    BiteDelay = 3.0, 

    -- 3. Waktu Main Minigame (Detik)
    -- Berapa lama pura-pura main minigame agar server tidak curiga.
    -- Minimal 2.5 - 3.0 detik.
    MinigameTime = 2.8, 

    -- 4. Istirahat (Detik)
    -- Jeda setelah dapat ikan sebelum melempar lagi.
    Cooldown = 0.0 
}

-- UI VARIABLES
local expandedSize = UDim2.new(0, 400, 0, 280)
local minimizedSize = UDim2.new(0, 150, 0, 30)
local isMinimized = false

if CoreGui:FindFirstChild("FishBotUI_V16") then
    CoreGui.FishBotUI_V16:Destroy()
end

local Remotes = { Charge = nil, Minigame = nil, Finish = nil }

-- UI SETUP
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "FishBotUI_V16"
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 9999
pcall(function() ScreenGui.Parent = CoreGui end)
if not ScreenGui.Parent then ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = expandedSize
MainFrame.Position = UDim2.new(0.5, -200, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25) -- Dark Grey Blue
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)

-- TITLE
local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -40, 0, 30)
TitleLabel.Position = UDim2.new(0, 10, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "🎛️ Configurable Bot v16"
TitleLabel.TextColor3 = Color3.fromRGB(100, 200, 255) -- Sky Blue
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

-- BUTTONS
local BtnContainer = Instance.new("Frame")
BtnContainer.Size = UDim2.new(1, -20, 0, 35)
BtnContainer.Position = UDim2.new(0, 10, 0, 0)
BtnContainer.BackgroundTransparency = 1
BtnContainer.Parent = ContentFrame

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
ScanBtn.Text = "🔍 FIX"
ScanBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ScanBtn.Font = Enum.Font.GothamBold
ScanBtn.TextSize = 12
ScanBtn.Parent = BtnContainer
Instance.new("UICorner", ScanBtn).CornerRadius = UDim.new(0, 6)

-- LOG DISPLAY
local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Size = UDim2.new(1, -10, 1, -50)
ScrollFrame.Position = UDim2.new(0, 5, 0, 45)
ScrollFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
ScrollFrame.ScrollBarThickness = 4
ScrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
ScrollFrame.Parent = ContentFrame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 2)
UIListLayout.Parent = ScrollFrame

local function AddLog(text, colorType)
    local color = Color3.fromRGB(255, 255, 255)
    if colorType == "success" then color = Color3.fromRGB(46, 204, 113) end
    if colorType == "warn" then color = Color3.fromRGB(241, 196, 15) end
    if colorType == "error" then color = Color3.fromRGB(231, 76, 60) end
    if colorType == "info" then color = Color3.fromRGB(52, 152, 219) end

    local Label = Instance.new("TextLabel")
    Label.BackgroundTransparency = 1
    Label.Font = Enum.Font.Code
    Label.TextSize = 12
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.TextWrapped = true
    Label.RichText = true
    Label.Text = text
    Label.TextColor3 = color
    Label.Size = UDim2.new(1, 0, 0, 0)
    Label.AutomaticSize = Enum.AutomaticSize.Y 
    Label.Parent = ScrollFrame

    ScrollFrame.CanvasPosition = Vector2.new(0, ScrollFrame.AbsoluteCanvasSize.Y)
    
    if #ScrollFrame:GetChildren() > 50 then 
        local first = ScrollFrame:GetChildren()[1]
        if first and first ~= UIListLayout then first:Destroy() end
    end
end

-- [[ SCANNER ]] --
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
    Remotes.Charge = FindRemoteSmart("ChargeFish")
    Remotes.Minigame = FindRemoteSmart("Minigame")
    Remotes.Finish = FindRemoteSmart("FishingComplet")
    if Remotes.Charge and Remotes.Minigame and Remotes.Finish then
        AddLog("✅ Sistem Siap. Pegang Pancingan!", "success")
        return true
    else
        AddLog("❌ Remote Missing. Scan lagi.", "error")
        return false
    end
end

ScanBtn.MouseButton1Click:Connect(function() SetupRemotes() end)

-- [[ ENGINE ]] --
local function StartBot()
    task.spawn(function()
        if not Remotes.Charge then if not SetupRemotes() then BotConfig.IsRunning = false; return end end
        
        AddLog("⚙️ Bot Jalan (Delay Ikan: "..BotConfig.BiteDelay.."s)", "info")

        while BotConfig.IsRunning do
            local success, err = pcall(function()
                
                -- STEP 1: LEMPAR KAIL
                Remotes.Charge:InvokeServer(workspace.DistributedGameTime)
                
                -- [[ JEDA TUNGGU IKAN MENYAMBAR ]] --
                if BotConfig.BiteDelay > 0 then
                    AddLog("⏳ Nunggu ikan ("..BotConfig.BiteDelay.."s)...", "info")
                    task.wait(BotConfig.BiteDelay)
                else
                    task.wait(BotConfig.ActionDelay) -- Jeda minimal kalau diset 0
                end

                -- STEP 2: MULAI MINIGAME
                local randomID = math.random(100000000, 999999999) 
                Remotes.Minigame:InvokeServer(BotConfig.CastPower, randomID, os.time())
                
                -- [[ JEDA MAIN MINIGAME ]] --
                AddLog("🎮 Main minigame ("..BotConfig.MinigameTime.."s)...", "warn")
                task.wait(BotConfig.MinigameTime)

                -- STEP 3: AMBIL HASIL
                Remotes.Finish:FireServer()
                
                AddLog("✅ Ikan Dapat!", "success")
                task.wait(BotConfig.Cooldown)
            end)

            if not success then
                AddLog("Err: " .. tostring(err), "error")
                task.wait(1)
            end
            
            if not BotConfig.IsRunning then break end
        end
        ToggleBtn.Text = "▶ START"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
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
        MainFrame:TweenSize(minimizedSize, "Out", "Quad", 0.3, true)
        MinBtn.Text = "+"; ContentFrame.Visible = false
    else
        MainFrame:TweenSize(expandedSize, "Out", "Quad", 0.3, true)
        MinBtn.Text = "_"; task.wait(0.2); ContentFrame.Visible = true
    end
end)

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
