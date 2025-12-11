--[[ 
    FISH-IT BOT v11 (SMART EQUIP & UI FIX)
    Fitur: 
    - UI Log Rapi (Tidak menumpuk)
    - Smart Equip (Tidak akan menyimpan pancingan jika sedang dipegang)
    - Scanner Tetap Ada
]]

local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- KONFIGURASI BOT
local BotConfig = {
    IsRunning = false,
    ActionDelay = 0.2, -- Sedikit lebih santai agar server tidak error
    Cooldown = 0.8,
    CastPower = 1.0
}

-- UI VARIABLES
local expandedSize = UDim2.new(0, 400, 0, 280)
local minimizedSize = UDim2.new(0, 150, 0, 30)
local isMinimized = false

if CoreGui:FindFirstChild("FishBotUI_V11") then
    CoreGui.FishBotUI_V11:Destroy()
end

local Remotes = { Equip = nil, Charge = nil, Minigame = nil, Finish = nil }

-- UI SETUP
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "FishBotUI_V11"
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
TitleLabel.Text = "🤖 Smart Bot v11"
TitleLabel.TextColor3 = Color3.fromRGB(0, 255, 127) -- Spring Green
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
ScanBtn.BackgroundColor3 = Color3.fromRGB(52, 152, 219)
ScanBtn.Text = "🔍 SCAN"
ScanBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ScanBtn.Font = Enum.Font.GothamBold
ScanBtn.TextSize = 12
ScanBtn.Parent = BtnContainer
Instance.new("UICorner", ScanBtn).CornerRadius = UDim.new(0, 6)

-- SCROLL FRAME FIX (Agar Log Tidak Menumpuk)
local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Size = UDim2.new(1, -10, 1, -50)
ScrollFrame.Position = UDim2.new(0, 5, 0, 45)
ScrollFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
ScrollFrame.ScrollBarThickness = 4
ScrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y -- FIX UTAMA
ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
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
    if colorType == "debug" then color = Color3.fromRGB(155, 89, 182) end 

    local Label = Instance.new("TextLabel")
    Label.BackgroundTransparency = 1
    Label.Font = Enum.Font.Code
    Label.TextSize = 12
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.TextWrapped = true
    Label.RichText = true
    Label.Text = text
    Label.TextColor3 = color
    -- Agar ukuran label menyesuaikan panjang teks
    Label.Size = UDim2.new(1, 0, 0, 0)
    Label.AutomaticSize = Enum.AutomaticSize.Y 
    Label.Parent = ScrollFrame

    -- Paksa update canvas agar bisa scroll
    ScrollFrame.CanvasPosition = Vector2.new(0, ScrollFrame.AbsoluteCanvasSize.Y)
    
    -- Hapus log lama biar gak lag (max 50 baris)
    if #ScrollFrame:GetChildren() > 50 then 
        local first = ScrollFrame:GetChildren()[1]
        if first and first ~= UIListLayout then first:Destroy() end
    end
end

-- [[ FUNGSI SCANNER ]] --
local function FindRemoteSmart(partialName)
    for _, v in pairs(ReplicatedStorage:GetDescendants()) do
        if v.Name:lower():find(partialName:lower()) and (v:IsA("RemoteEvent") or v:IsA("RemoteFunction")) then return v end
    end
    if LocalPlayer and LocalPlayer:FindFirstChild("Backpack") then
        for _, v in pairs(LocalPlayer.Backpack:GetDescendants()) do
            if v.Name:lower():find(partialName:lower()) and (v:IsA("RemoteEvent") or v:IsA("RemoteFunction")) then return v end
        end
    end
    if LocalPlayer and LocalPlayer.Character then
        for _, v in pairs(LocalPlayer.Character:GetDescendants()) do
            if v.Name:lower():find(partialName:lower()) and (v:IsA("RemoteEvent") or v:IsA("RemoteFunction")) then return v end
        end
    end
    return nil
end

local function SetupRemotes()
    Remotes.Equip = FindRemoteSmart("EquipTool")
    Remotes.Charge = FindRemoteSmart("ChargeFish")
    Remotes.Minigame = FindRemoteSmart("Minigame")
    Remotes.Finish = FindRemoteSmart("FishingComplet")
    
    if Remotes.Equip and Remotes.Charge and Remotes.Minigame and Remotes.Finish then
        AddLog("✅ Semua Remote Siap!", "success")
        return true
    else
        AddLog("❌ Masih ada remote hilang. Scan dulu!", "error")
        return false
    end
end

ScanBtn.MouseButton1Click:Connect(function()
    SetupRemotes()
end)

-- [[ ENGINE PINTAR ]] --

-- Fungsi Cek Apakah Sedang Pegang Alat
local function IsHoldingTool()
    if LocalPlayer.Character then
        -- Cari tool di dalam karakter
        local tool = LocalPlayer.Character:FindFirstChildWhichIsA("Tool")
        if tool then return true end
    end
    return false
end

local function StartBot()
    task.spawn(function()
        if not Remotes.Equip then if not SetupRemotes() then BotConfig.IsRunning = false; return end end
        
        AddLog("🚀 BOT DIMULAI...", "success")

        while BotConfig.IsRunning do
            local success, err = pcall(function()
                
                -- STEP 1: SMART EQUIP (Fix Masalah Unequip)
                if IsHoldingTool() then
                    -- Jika sudah pegang alat, JANGAN equip lagi (skip)
                    -- AddLog("Sudah pegang alat, lanjut...", "info") -- Optional log
                else
                    -- Jika tangan kosong, baru equip
                    AddLog("Mengambil alat...", "warn")
                    Remotes.Equip:FireServer(1)
                    task.wait(0.5) -- Tunggu animasi equip
                end

                -- Cek lagi apakah berhasil equip sebelum lanjut
                if not IsHoldingTool() then
                    AddLog("Gagal equip! Coba lagi...", "error")
                    task.wait(1)
                    return -- Ulangi loop
                end

                -- STEP 2: CHARGE
                Remotes.Charge:InvokeServer(workspace.DistributedGameTime)
                task.wait(BotConfig.ActionDelay)

                -- STEP 3: MINIGAME
                local randomID = math.random(100000000, 999999999) 
                Remotes.Minigame:InvokeServer(BotConfig.CastPower, randomID, os.time())
                task.wait(BotConfig.ActionDelay)

                -- STEP 4: FINISH
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
