--[[ 
    FISH-IT BOT v10 (BLOODHOUND SCANNER)
    Fitur: 
    - Mencari remote di ReplicatedStorage, Backpack, dan Character
    - Fuzzy Search (Mencari nama yang mirip, mengatasi typo/spasi)
    - Tombol SCAN DEBUG untuk melihat semua remote yang ada
]]

local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- KONFIGURASI TURBO
local BotConfig = {
    IsRunning = false,
    ActionDelay = 0.15, 
    Cooldown = 0.5,
    CastPower = 1.0
}

-- UI VARIABLES
local expandedSize = UDim2.new(0, 400, 0, 280)
local minimizedSize = UDim2.new(0, 150, 0, 30)
local isMinimized = false

if CoreGui:FindFirstChild("FishBotUI_V10") then
    CoreGui.FishBotUI_V10:Destroy()
end

local Remotes = { Equip = nil, Charge = nil, Minigame = nil, Finish = nil }

-- UI SETUP
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "FishBotUI_V10"
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 9999
pcall(function() ScreenGui.Parent = CoreGui end)
if not ScreenGui.Parent then ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = expandedSize
MainFrame.Position = UDim2.new(0.5, -200, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -40, 0, 30)
TitleLabel.Position = UDim2.new(0, 10, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "🐕 Bloodhound Bot v10"
TitleLabel.TextColor3 = Color3.fromRGB(255, 100, 100) -- Merah Muda
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

-- BUTTON CONTAINER
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
ScanBtn.BackgroundColor3 = Color3.fromRGB(52, 152, 219) -- Biru
ScanBtn.Text = "🔍 SCAN"
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
ScrollFrame.Parent = ContentFrame
local UIListLayout = Instance.new("UIListLayout")
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 2)
UIListLayout.Parent = ScrollFrame

-- FUNGSI LOGGING
local function AddLog(text, colorType)
    local color = Color3.fromRGB(255, 255, 255)
    if colorType == "success" then color = Color3.fromRGB(46, 204, 113) end
    if colorType == "warn" then color = Color3.fromRGB(241, 196, 15) end
    if colorType == "error" then color = Color3.fromRGB(231, 76, 60) end
    if colorType == "info" then color = Color3.fromRGB(52, 152, 219) end
    if colorType == "debug" then color = Color3.fromRGB(155, 89, 182) end -- Ungu

    local Label = Instance.new("TextLabel")
    Label.BackgroundTransparency = 1
    Label.Font = Enum.Font.Code
    Label.TextSize = 11
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.TextWrapped = true
    Label.RichText = true
    Label.Text = text
    Label.TextColor3 = color
    Label.AutomaticSize = Enum.AutomaticSize.Y
    Label.Size = UDim2.new(1, 0, 0, 0)
    Label.Parent = ScrollFrame
    ScrollFrame.CanvasPosition = Vector2.new(0, 99999)
    if #ScrollFrame:GetChildren() > 60 then ScrollFrame:GetChildren()[1]:Destroy() end
end

-- [[ FUNGSI PENCARI CANGGIH ]] --
local function FindRemoteSmart(partialName, typeStr)
    -- 1. Cari di ReplicatedStorage (Deep Scan)
    for _, v in pairs(ReplicatedStorage:GetDescendants()) do
        if v.Name:lower():find(partialName:lower()) and (v:IsA("RemoteEvent") or v:IsA("RemoteFunction")) then
            return v
        end
    end
    
    -- 2. Cari di Backpack (Tas Pemain)
    if LocalPlayer and LocalPlayer:FindFirstChild("Backpack") then
        for _, v in pairs(LocalPlayer.Backpack:GetDescendants()) do
            if v.Name:lower():find(partialName:lower()) and (v:IsA("RemoteEvent") or v:IsA("RemoteFunction")) then
                return v
            end
        end
    end

    -- 3. Cari di Karakter (Siapa tau ada di pancingan yang dipegang)
    if LocalPlayer and LocalPlayer.Character then
        for _, v in pairs(LocalPlayer.Character:GetDescendants()) do
            if v.Name:lower():find(partialName:lower()) and (v:IsA("RemoteEvent") or v:IsA("RemoteFunction")) then
                return v
            end
        end
    end

    return nil
end

local function SetupRemotes()
    AddLog("Melacak Remote...", "info")
    
    -- Gunakan kata kunci sebagian saja biar pasti ketemu
    Remotes.Equip = FindRemoteSmart("EquipTool", "RemoteEvent")
    Remotes.Charge = FindRemoteSmart("ChargeFish", "RemoteFunction")
    Remotes.Minigame = FindRemoteSmart("Minigame", "RemoteFunction")
    Remotes.Finish = FindRemoteSmart("FishingComplet", "RemoteEvent")
    
    local missing = false
    if Remotes.Equip then AddLog("✅ Equip: " .. Remotes.Equip:GetFullName(), "debug") else AddLog("❌ Equip Missing", "error"); missing = true end
    if Remotes.Charge then AddLog("✅ Charge: " .. Remotes.Charge:GetFullName(), "debug") else AddLog("❌ Charge Missing", "error"); missing = true end
    if Remotes.Minigame then AddLog("✅ Minigame: " .. Remotes.Minigame:GetFullName(), "debug") else AddLog("❌ Minigame Missing", "error"); missing = true end
    if Remotes.Finish then AddLog("✅ Finish: " .. Remotes.Finish:GetFullName(), "debug") else AddLog("❌ Finish Missing", "error"); missing = true end
    
    if missing then
        AddLog("TIPS: Coba pegang pancingan dulu baru Start/Scan!", "warn")
        return false
    end
    return true
end

-- [[ FITUR SCANNER DEBUG ]] --
ScanBtn.MouseButton1Click:Connect(function()
    AddLog("--- MULAI SCAN SEMUA REMOTE ---", "info")
    local count = 0
    
    local function ScanTarget(parent, label)
        for _, v in pairs(parent:GetDescendants()) do
            if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
                -- Filter remote bawaan roblox biar gak spam
                if not v:GetFullName():find("DefaultChat") and not v:GetFullName():find("RobloxReplicated") then
                    AddLog("Found ["..label.."]: " .. v.Name, "debug")
                    count = count + 1
                end
            end
        end
    end
    
    ScanTarget(ReplicatedStorage, "RepStore")
    if LocalPlayer.Character then ScanTarget(LocalPlayer.Character, "Char") end
    if LocalPlayer.Backpack then ScanTarget(LocalPlayer.Backpack, "Backpack") end
    
    AddLog("--- SELESAI: Ditemukan " .. count .. " remote ---", "info")
end)

-- [[ ENGINE ]] --
local function StartBot()
    task.spawn(function()
        if not Remotes.Equip then
            if not SetupRemotes() then
                BotConfig.IsRunning = false
                ToggleBtn.Text = "▶ START"
                ToggleBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
                return 
            end
        end

        AddLog("⚡ BOT BERJALAN...", "success")

        while BotConfig.IsRunning do
            local success, err = pcall(function()
                Remotes.Equip:FireServer(1)
                task.wait(BotConfig.ActionDelay)
                Remotes.Charge:InvokeServer(workspace.DistributedGameTime)
                task.wait(BotConfig.ActionDelay)
                local randomID = math.random(100000000, 999999999) 
                Remotes.Minigame:InvokeServer(BotConfig.CastPower, randomID, os.time())
                task.wait(BotConfig.ActionDelay)
                Remotes.Finish:FireServer()
                AddLog("✅ Ikan +1", "success")
                task.wait(BotConfig.Cooldown)
            end)

            if not success then
                AddLog("Err: " .. tostring(err), "error")
                task.wait(1)
            end
            if not BotConfig.IsRunning then break end
        end
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
