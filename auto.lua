--[[ 
    FISH-IT BOT v15 (TIME TRAVELER / FAKE TIMESTAMP)
    Teori:
    - Memanipulasi argumen waktu (os.time() - 5).
    - Menipu server agar mengira kita sudah main minigame selama 5 detik.
    - Menghapus semua delay tunggu (INSTANT CATCH).
]]

local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- KONFIGURASI EKSTRIM
local BotConfig = {
    IsRunning = false,
    ActionDelay = 0.15, -- Sangat Cepat
    SpoofTime = 5,      -- Kita kurangi waktu sebanyak 5 detik (Fake History)
    Cooldown = 0.5,     -- Jeda antar ikan
    CastPower = 1.0
}

-- UI SETUP (Sama seperti v14 tapi warna tema Ungu Misterius)
local expandedSize = UDim2.new(0, 400, 0, 260)
local minimizedSize = UDim2.new(0, 150, 0, 30)
local isMinimized = false

if CoreGui:FindFirstChild("FishBotUI_V15") then CoreGui.FishBotUI_V15:Destroy() end

local Remotes = { Charge = nil, Minigame = nil, Finish = nil }
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "FishBotUI_V15"
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 9999
pcall(function() ScreenGui.Parent = CoreGui end)
if not ScreenGui.Parent then ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = expandedSize
MainFrame.Position = UDim2.new(0.5, -200, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 10, 30) -- Ungu Gelap
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -40, 0, 30)
TitleLabel.Position = UDim2.new(0, 10, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "⏳ Time Traveler v15"
TitleLabel.TextColor3 = Color3.fromRGB(200, 100, 255) -- Ungu Neon
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
ToggleBtn.Text = "▶ START INSTANT"
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

-- [[ ENGINE TIME TRAVELER ]] --
local function StartBot()
    task.spawn(function()
        if not Remotes.Charge then if not SetupRemotes() then BotConfig.IsRunning = false; return end end
        
        AddLog("🔮 Mencoba menipu waktu...", "info")

        while BotConfig.IsRunning do
            local success, err = pcall(function()
                -- 1. CHARGE
                Remotes.Charge:InvokeServer(workspace.DistributedGameTime)
                task.wait(BotConfig.ActionDelay)

                -- 2. MINIGAME (FAKE TIME)
                local randomID = math.random(100000000, 999999999)
                
                -- DI SINI KUNCINYA:
                -- Kita kirim waktu masa lalu (os.time - 5 detik)
                -- Server mungkin mengira kita sudah mulai 5 detik yg lalu
                local fakeTime = os.time() - BotConfig.SpoofTime
                
                Remotes.Minigame:InvokeServer(BotConfig.CastPower, randomID, fakeTime)
                
                -- KITA TIDAK TUNGGU LAMA-LAMA!
                -- Langsung gas finish (Cuma jeda dikit biar sinyal nyampe)
                task.wait(BotConfig.ActionDelay) 

                -- 3. FINISH
                Remotes.Finish:FireServer()
                
                AddLog("✨ INSTANT CATCH?", "success")
                task.wait(BotConfig.Cooldown)
            end)

            if not success then
                AddLog("Err: " .. tostring(err), "error")
                task.wait(1)
            end
            
            if not BotConfig.IsRunning then break end
        end
        ToggleBtn.Text = "▶ START INSTANT"
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
        ToggleBtn.Text = "▶ START INSTANT"
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
