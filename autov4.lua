--[[ 
    FISH-IT BOT v19 (THE GHOST / ANIMATION SPEED HACK)
    Fokus: MENGHILANGKAN VISUAL LAMBAT
    
    Fitur Baru:
    - Speed Anim: Memaksa kecepatan animasi menjadi 100x lipat (Instan gerak).
    - Bobber Delete: Menghapus pelampung secara visual agar tidak perlu dilihat jatuh.
    - Non-Blocking Cast: Mengirim sinyal lempar tanpa menunggu server merespon.
]]

local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- [[ ⚙️ CONFIGURATION ⚙️ ]] --
local BotConfig = {
    IsRunning = false,
    
    -- Jeda Waktu (Detik)
    -- Karena animasi sudah instan, kita bisa set ini rendah.
    WaitBite = 0.15,
    WaitGame = 2.6, -- Batas aman server (Jangan dibawah 2.5)
    WaitCool = 0.1, -- Cooldown super cepat
    
    CastPower = 1.0
}

-- UI SETUP
local expandedSize = UDim2.new(0, 400, 0, 260)
local minimizedSize = UDim2.new(0, 150, 0, 30)
local isMinimized = false

if CoreGui:FindFirstChild("FishBotUI_V19") then CoreGui.FishBotUI_V19:Destroy() end
local Remotes = { Charge = nil, Minigame = nil, Finish = nil }

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "FishBotUI_V19"
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 9999
pcall(function() ScreenGui.Parent = CoreGui end)
if not ScreenGui.Parent then ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = expandedSize
MainFrame.Position = UDim2.new(0.5, -200, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(5, 5, 10) -- Hitam Kebiruan
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -40, 0, 30)
TitleLabel.Position = UDim2.new(0, 10, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "👻 Ghost Bot v19 (No Anim)"
TitleLabel.TextColor3 = Color3.fromRGB(200, 200, 255) -- Ghost White
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

local BtnContainer = Instance.new("Frame")
BtnContainer.Size = UDim2.new(1, -20, 0, 35)
BtnContainer.Position = UDim2.new(0, 10, 0, 0)
BtnContainer.BackgroundTransparency = 1
BtnContainer.Parent = ContentFrame

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0.65, 0, 1, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
ToggleBtn.Text = "▶ START GHOST"
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

-- [[ FUNGSI PENGHILANG VISUAL ]] --

-- 1. Percepat Animasi hingga Instan
local function InstantAnim()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        local Animator = LocalPlayer.Character.Humanoid:FindFirstChild("Animator")
        if Animator then
            for _, track in pairs(Animator:GetPlayingAnimationTracks()) do
                -- Ubah kecepatan jadi 100x lipat (gerakan selesai dalam 0.01 detik)
                track:AdjustSpeed(100) 
            end
        end
    end
end

-- 2. Hapus Pelampung (Bobber) dari Layar
local function RemoveBobber()
    pcall(function()
        -- Cari semua part di workspace
        for _, v in pairs(workspace:GetChildren()) do
            -- Cek nama umum pelampung
            if (v.Name == "Bobber" or v.Name == "FishingBobber" or v.Name == "Float") then
                -- Cek apakah milik kita (opsional, tapi lebih aman)
                -- Kita hapus visual client-side saja
                v:Destroy()
            end
        end
    end)
end

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

-- [[ ENGINE GHOST ]] --
local function StartBot()
    task.spawn(function()
        if not Remotes.Charge then if not SetupRemotes() then BotConfig.IsRunning = false; return end end
        
        AddLog("👻 GHOST MODE ON...", "info")
        
        -- Loop pembersih visual background (Jalan terus tiap frame)
        local VisualConnection
        VisualConnection = RunService.RenderStepped:Connect(function()
            if not BotConfig.IsRunning then VisualConnection:Disconnect() return end
            InstantAnim() -- Paksa animasi ngebut tiap frame
        end)

        while BotConfig.IsRunning do
            local success, err = pcall(function()
                
                -- STEP 1: CHARGE (LEMPAR)
                -- Gunakan task.spawn agar tidak nunggu balasan server (InvokeServer biasanya nunggu)
                task.spawn(function()
                    Remotes.Charge:InvokeServer(workspace.DistributedGameTime)
                end)
                
                -- Hapus bobber segera setelah lempar
                task.wait(0.05)
                RemoveBobber()

                task.wait(BotConfig.WaitBite)

                -- STEP 2: MINIGAME
                local randomID = math.random(100000000, 999999999) 
                Remotes.Minigame:InvokeServer(BotConfig.CastPower, randomID, os.time())
                
                -- Tunggu waktu wajib server (Gak bisa di-skip)
                AddLog("⏳ Tunggu server ("..BotConfig.WaitGame.."s)...", "warn")
                task.wait(BotConfig.WaitGame)

                -- STEP 3: FINISH
                Remotes.Finish:FireServer()
                InstantAnim() -- Pastikan animasi tarik juga instan
                
                AddLog("✅ Ikan Dapat!", "success")
                task.wait(BotConfig.WaitCool)
            end)

            if not success then
                AddLog("Err: " .. tostring(err), "error")
                task.wait(1)
            end
            
            if not BotConfig.IsRunning then break end
        end
        ToggleBtn.Text = "▶ START GHOST"
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
        ToggleBtn.Text = "▶ START GHOST"
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
