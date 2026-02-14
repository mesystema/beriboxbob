local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- [[ CONFIGURATION ]] --
local Settings = {
    Enabled = false,
    CastPower = 100,
    WaitGame = 2.5, 
    WaitCool = 0.8,
    AutoSell = true -- Fitur jual otomatis aktif
}

-- [[ UI SYSTEM ]] --
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "FishIt_Ultra_V2"
ScreenGui.Parent = (gethui and gethui()) or CoreGui

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 220, 0, 220)
MainFrame.Position = UDim2.new(0.5, -110, 0.4, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 40)
Title.Text = "⚡ FISH IT PRO + SELL"
Title.TextColor3 = Color3.fromRGB(0, 255, 150)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBold
Title.TextSize = 14
Title.Parent = MainFrame

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, 0, 0, 30)
StatusLabel.Position = UDim2.new(0, 0, 0, 40)
StatusLabel.Text = "Status: Idle"
StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextSize = 12
StatusLabel.Parent = MainFrame

-- Tombol Start/Stop
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0.85, 0, 0, 45)
ToggleBtn.Position = UDim2.new(0.075, 0, 0.45, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
ToggleBtn.Text = "START BOT"
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextColor3 = Color3.white
ToggleBtn.Parent = MainFrame
Instance.new("UICorner", ToggleBtn)

-- Tombol Close
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0.85, 0, 0, 40)
CloseBtn.Position = UDim2.new(0.075, 0, 0.75, 0)
CloseBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
CloseBtn.Text = "CLOSE"
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextColor3 = Color3.fromRGB(200, 50, 50)
CloseBtn.Parent = MainFrame
Instance.new("UICorner", CloseBtn)

-- [[ FUNCTIONS ]] --

local function KillAnims()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then
        for _, v in pairs(char.Humanoid:GetPlayingAnimationTracks()) do
            v:Stop()
        end
    end
end

local function GetRemotes()
    local charge = ReplicatedStorage:FindFirstChild("ChargeFish", true) or ReplicatedStorage:FindFirstChild("Cast", true)
    local mini = ReplicatedStorage:FindFirstChild("Minigame", true) or ReplicatedStorage:FindFirstChild("Catch", true)
    local finish = ReplicatedStorage:FindFirstChild("FishingComplet", true) or ReplicatedStorage:FindFirstChild("Complete", true)
    local sell = ReplicatedStorage:FindFirstChild("SellFish", true) or ReplicatedStorage:FindFirstChild("Sell", true)
    return charge, mini, finish, sell
end

-- Fungsi cek tas (Inventory)
local function CheckInventoryAndSell(sellRemote)
    local stats = LocalPlayer:FindFirstChild("leaderstats")
    local inventory = LocalPlayer:FindFirstChild("Inventory") -- Tergantung struktur game
    
    -- Jika ada remote jual, kita panggil saja setiap beberapa kali tangkapan 
    -- atau panggil langsung untuk memastikan tas kosong.
    if sellRemote then
        StatusLabel.Text = "Status: Selling Fish..."
        pcall(function() sellRemote:FireServer() end)
        task.wait(0.5)
    end
end

local function MainLoop()
    task.spawn(function()
        while Settings.Enabled do
            local charge, mini, finish, sell = GetRemotes()
            
            -- Cek Jual Otomatis sebelum mancing
            if Settings.AutoSell then
                CheckInventoryAndSell(sell)
            end

            if charge and mini and finish then
                StatusLabel.Text = "Status: Casting..."
                pcall(function() charge:InvokeServer(Settings.CastPower) end)
                KillAnims()
                task.wait(0.5)

                StatusLabel.Text = "Status: Waiting Fish..."
                local ticket = nil
                local startWait = tick()
                repeat
                    local success, res = pcall(function() 
                        return mini:InvokeServer(Settings.CastPower, math.random(1, 1000), os.time()) 
                    end)
                    if success and res then ticket = res end
                    task.wait(0.5)
                until ticket or not Settings.Enabled or (tick() - startWait > 25)

                if ticket then
                    StatusLabel.Text = "Status: Catching..."
                    task.wait(Settings.WaitGame)
                    pcall(function() finish:FireServer(ticket) end)
                    KillAnims()
                    StatusLabel.Text = "Status: Success!"
                end
            else
                StatusLabel.Text = "Status: Remote Error!"
            end
            
            task.wait(Settings.WaitCool)
        end
    end)
end

-- [[ EVENTS ]] --

ToggleBtn.MouseButton1Click:Connect(function()
    Settings.Enabled = not Settings.Enabled
    if Settings.Enabled then
        ToggleBtn.Text = "STOP BOT"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
        MainLoop()
    else
        ToggleBtn.Text = "START BOT"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
        StatusLabel.Text = "Status: Idle"
    end
end)

CloseBtn.MouseButton1Click:Connect(function()
    Settings.Enabled = false
    ScreenGui:Destroy()
end)
