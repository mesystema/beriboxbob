--[[ 
    ULTIMATE FISH-IT BOT (UI Version)
    Fitur: 
    - UI Draggable & Minimize (Mirip Spy V7)
    - Status Log Real-time (Bukan remote spy, tapi status bot)
    - Auto Start/Stop
    - Error Handling (Anti Macet)
]]

local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- KONFIGURASI BOT
local BotConfig = {
    IsRunning = false,
    Cooldown = 1.5, -- Jeda antar tangkapan
    CastPower = 1.0
}

-- CONFIG UI
local isMinimized = false
local expandedSize = UDim2.new(0, 380, 0, 240)
local minimizedSize = UDim2.new(0, 150, 0, 30)

-- 1. BERSIHKAN UI LAMA
if CoreGui:FindFirstChild("FishBotUI") then
    CoreGui.FishBotUI:Destroy()
end

-- 2. SETUP REMOTES (Mencari Remote Game)
-- Kita siapkan variabelnya dulu, nanti diisi saat script jalan
local Remotes = {
    Equip = nil,
    Charge = nil,
    Minigame = nil,
    Finish = nil
}

-- 3. MEMBUAT UI (BASE V7 SPY)
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "FishBotUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 9999
pcall(function() ScreenGui.Parent = CoreGui end)
if not ScreenGui.Parent then ScreenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui") end

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = expandedSize
MainFrame.Position = UDim2.new(0.5, -190, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)

-- HEADER
local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -40, 0, 30)
TitleLabel.Position = UDim2.new(0, 10, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "🎣 Fish-It Auto v1"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
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

-- AREA KONTEN
local ContentFrame = Instance.new("Frame")
ContentFrame.Size = UDim2.new(1, 0, 1, -35)
ContentFrame.Position = UDim2.new(0, 0, 0, 35)
ContentFrame.BackgroundTransparency = 1
ContentFrame.Parent = MainFrame

-- TOMBOL START/STOP
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0.95, 0, 0, 35)
ToggleBtn.Position = UDim2.new(0.025, 0, 0, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113) -- Hijau
ToggleBtn.Text = "▶ START FARMING"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 14
ToggleBtn.Parent = ContentFrame
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0, 6)

-- LOG DISPLAY (Tempat status muncul)
local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Size = UDim2.new(0.95, 0, 1, -45)
ScrollFrame.Position = UDim2.new(0.025, 0, 0, 45)
ScrollFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
ScrollFrame.ScrollBarThickness = 4
ScrollFrame.Parent = ContentFrame
local UIListLayout = Instance.new("UIListLayout")
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 2)
UIListLayout.Parent = ScrollFrame

-- 4. FUNGSI LOGGING (KE LAYAR)
local function AddLog(text, colorType)
    local color = Color3.fromRGB(255, 255, 255) -- Default Putih
    if colorType == "success" then color = Color3.fromRGB(46, 204, 113) end -- Hijau
    if colorType == "warn" then color = Color3.fromRGB(241, 196, 15) end -- Kuning
    if colorType == "error" then color = Color3.fromRGB(231, 76, 60) end -- Merah
    if colorType == "info" then color = Color3.fromRGB(52, 152, 219) end -- Biru

    -- Buat Waktu (Jam:Menit:Detik)
    local date = os.date("*t")
    local timeStr = string.format("[%02d:%02d:%02d] ", date.hour, date.min, date.sec)

    local Label = Instance.new("TextLabel")
    Label.BackgroundTransparency = 1
    Label.Font = Enum.Font.Code
    Label.TextSize = 12
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.TextWrapped = true
    Label.Text = timeStr .. text
    Label.TextColor3 = color
    Label.AutomaticSize = Enum.AutomaticSize.Y
    Label.Size = UDim2.new(1, 0, 0, 0)
    Label.Parent = ScrollFrame

    -- Auto Scroll
    ScrollFrame.CanvasPosition = Vector2.new(0, 99999)
    
    -- Bersihkan log lama jika terlalu banyak (Anti Lag)
    if #ScrollFrame:GetChildren() > 50 then
        ScrollFrame:GetChildren()[1]:Destroy()
    end
end

-- 5. FUNGSI UTAMA BOT (FARMING ENGINE)
local function StartBot()
    task.spawn(function()
        -- STEP 0: Cek Remote Dulu
        AddLog("Memeriksa Remote Game...", "info")
        local RE = ReplicatedStorage:FindFirstChild("RE")
        local RF = ReplicatedStorage:FindFirstChild("RF")
        
        if not RE or not RF then
            AddLog("GAGAL: Folder Remote tidak ditemukan!", "error")
            BotConfig.IsRunning = false
            ToggleBtn.Text = "▶ START FARMING"
            ToggleBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
            return
        end

        Remotes.Equip = RE:FindFirstChild("EquipToolFromHotbar")
        Remotes.Charge = RF:FindFirstChild("ChargeFishingRod")
        Remotes.Minigame = RF:FindFirstChild("RequestFishingMinigameStarted")
        Remotes.Finish = RE:FindFirstChild("FishingCompleted")

        if not Remotes.Equip or not Remotes.Charge then
            AddLog("GAGAL: Beberapa remote hilang/ganti nama.", "error")
            return
        end
        AddLog("Remote ditemukan! Memulai Loop...", "success")

        -- LOOP FARMING
        while BotConfig.IsRunning do
            local success, err = pcall(function()
                -- A. EQUIP
                AddLog("1. Mengambil Pancingan...", "warn")
                Remotes.Equip:FireServer(1)
                task.wait(0.8)

                -- B. CHARGE (LEMPAR)
                AddLog("2. Melempar Kail...", "info")
                Remotes.Charge:InvokeServer(workspace.DistributedGameTime)
                task.wait(1.5)

                -- C. MINIGAME (SIMULASI)
                AddLog("3. Memainkan Minigame...", "info")
                local randomID = math.random(100000000, 999999999) 
                Remotes.Minigame:InvokeServer(BotConfig.CastPower, randomID, os.time())
                
                -- Tunggu sebentar (Pura-pura main biar aman)
                task.wait(2.0) 

                -- D. FINISH (TANGKAP)
                Remotes.Finish:FireServer()
                AddLog("✅ IKAN TERTANGKAP!", "success")
                
                -- E. COOLDOWN
                task.wait(BotConfig.Cooldown)
            end)

            if not success then
                AddLog("❌ Error: " .. tostring(err), "error")
                task.wait(2) -- Tunggu sebentar sebelum coba lagi
            end
            
            if not BotConfig.IsRunning then break end
        end
    end)
end

-- 6. INTERAKSI UI (TOMBOL & GESER)
ToggleBtn.MouseButton1Click:Connect(function()
    BotConfig.IsRunning = not BotConfig.IsRunning
    
    if BotConfig.IsRunning then
        ToggleBtn.Text = "⏹ STOP FARMING"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(231, 76, 60) -- Merah
        StartBot()
    else
        ToggleBtn.Text = "▶ START FARMING"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113) -- Hijau
        AddLog("Bot Dihentikan.", "warn")
    end
end)

-- Minimize Logic
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

-- Draggable Logic
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
