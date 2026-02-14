local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- [[ CONFIGURATION ]] --
local Settings = {
    Enabled = false,
    CastPower = 100,
    WaitGame = 2.5, -- Durasi simulasi minigame
    WaitCool = 0.5
}

-- [[ UI SYSTEM ]] --
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "FishIt_Ultra"
ScreenGui.Parent = (gethui and gethui()) or CoreGui

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 200, 0, 180)
MainFrame.Position = UDim2.new(0.5, -100, 0.4, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local Corner = Instance.new("UICorner", MainFrame)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 40)
Title.Text = "FISH IT AUTO"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBold
Title.TextSize = 14
Title.Parent = MainFrame

-- Tombol Start/Stop
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0.8, 0, 0, 40)
ToggleBtn.Position = UDim2.new(0.1, 0, 0.3, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
ToggleBtn.Text = "START"
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextColor3 = Color3.white
ToggleBtn.Parent = MainFrame
Instance.new("UICorner", ToggleBtn)

-- Tombol Close
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0.8, 0, 0, 40)
CloseBtn.Position = UDim2.new(0.1, 0, 0.6, 0)
CloseBtn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
CloseBtn.Text = "CLOSE UI"
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextColor3 = Color3.white
CloseBtn.Parent = MainFrame
Instance.new("UICorner", CloseBtn)

-- [[ FUNCTIONS ]] --

local function DisableAnimations()
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hum = char:WaitForChild("Humanoid")
    for _, track in pairs(hum:GetPlayingAnimationTracks()) do
        track:Stop()
    end
end

local function GetRemotes()
    -- Mencari remotes secara otomatis berdasarkan pola nama umum
    local charge = ReplicatedStorage:FindFirstChild("ChargeFish", true) or ReplicatedStorage:FindFirstChild("Cast", true)
    local mini = ReplicatedStorage:FindFirstChild("Minigame", true) or ReplicatedStorage:FindFirstChild("Catch", true)
    local finish = ReplicatedStorage:FindFirstChild("FishingComplet", true) or ReplicatedStorage:FindFirstChild("Complete", true)
    return charge, mini, finish
end

local function MainLoop()
    task.spawn(function()
        while Settings.Enabled do
            local charge, mini, finish = GetRemotes()
            
            if charge and mini and finish then
                -- 1. Lempar Pancing
                pcall(function() charge:InvokeServer(workspace.DistributedGameTime) end)
                DisableAnimations()
                task.wait(0.5)

                -- 2. Tunggu & Deteksi Ikan
                local ticket = nil
                local attempt = 0
                repeat
                    local success, res = pcall(function() 
                        return mini:InvokeServer(Settings.CastPower, math.random(100, 999), os.time()) 
                    end)
                    if success and res then ticket = res end
                    task.wait(0.5)
                    attempt = attempt + 1
                until ticket or not Settings.Enabled or attempt > 20

                -- 3. Tarik Ikan
                if ticket then
                    task.wait(Settings.WaitGame)
                    pcall(function() finish:FireServer(ticket) end)
                    DisableAnimations()
                end
            end
            task.wait(Settings.WaitCool)
        end
    end)
end

-- [[ EVENTS ]] --

ToggleBtn.MouseButton1Click:Connect(function()
    Settings.Enabled = not Settings.Enabled
    if Settings.Enabled then
        ToggleBtn.Text = "STOP"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
        MainLoop()
    else
        ToggleBtn.Text = "START"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
    end
end)

CloseBtn.MouseButton1Click:Connect(function()
    Settings.Enabled = false
    ScreenGui:Destroy()
end)
