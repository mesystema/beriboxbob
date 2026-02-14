-- [[ FISH-IT BOT v29.2 FIXED ]] --
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- Pastikan PlayerGui tersedia
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- [[ DEFAULT CONFIG ]] --
local BotConfig = {
    IsRunning = false,
    UseTimeSpoof = false,
    WaitThrow = 0.5,
    WaitGame = 2.5,
    WaitCool = 0.5,
    CastPower = 100
}

-- Hapus UI Lama jika ada
if CoreGui:FindFirstChild("FishBotUI_V29") then CoreGui.FishBotUI_V29:Destroy() end
if PlayerGui:FindFirstChild("FishBotUI_V29") then PlayerGui.FishBotUI_V29:Destroy() end

-- [[ UI CREATION ]] --
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "FishBotUI_V29"
ScreenGui.ResetOnSpawn = false
-- Coba ke CoreGui, jika gagal ke PlayerGui
local success, err = pcall(function() ScreenGui.Parent = CoreGui end)
if not success then ScreenGui.Parent = PlayerGui end

-- Main Frame
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 300, 0, 350)
MainFrame.Position = UDim2.new(0.5, -150, 0.4, -175)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true -- Support drag sederhana
MainFrame.Parent = ScreenGui

local Corner = Instance.new("UICorner", MainFrame)
Corner.CornerRadius = UDim.new(0, 10)

-- Title
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 40)
Title.Text = "⚡ FISH-IT V29 FIXED"
Title.TextColor3 = Color3.fromRGB(0, 255, 150)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBold
Title.TextSize = 16
Title.Parent = MainFrame

-- Status Label
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, 0, 0, 30)
StatusLabel.Position = UDim2.new(0, 0, 0, 40)
StatusLabel.Text = "Status: Ready"
StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.Parent = MainFrame

-- Start/Stop Button
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0.8, 0, 0, 50)
ToggleBtn.Position = UDim2.new(0.1, 0, 0.4, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
ToggleBtn.Text = "START BOT"
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextColor3 = Color3.white
ToggleBtn.TextSize = 18
ToggleBtn.Parent = MainFrame
Instance.new("UICorner", ToggleBtn)

-- [[ BOT LOGIC ]] --
local function GetRemotes()
    local Names = {"ChargeFish", "Cast", "Minigame", "Catch", "FishingComplet", "Complete"}
    local Found = {}
    for _, name in pairs(Names) do
        local r = ReplicatedStorage:FindFirstChild(name, true)
        if r then Found[name] = r end
    end
    return Found
end

local function StartBot()
    task.spawn(function()
        while BotConfig.IsRunning do
            local remotes = GetRemotes()
            local charge = remotes.ChargeFish or remotes.Cast
            local mini = remotes.Minigame or remotes.Catch
            local finish = remotes.FishingComplet or remotes.Complete

            if not charge or not mini then
                StatusLabel.Text = "Error: Remotes Not Found!"
                StatusLabel.TextColor3 = Color3.new(1,0,0)
                task.wait(1)
                continue
            end

            StatusLabel.Text = "Status: Casting..."
            pcall(function() charge:InvokeServer(workspace.DistributedGameTime) end)
            task.wait(BotConfig.WaitThrow)

            StatusLabel.Text = "Status: Waiting for Fish..."
            local ticket = nil
            local start = tick()
            
            repeat
                local fakeTime = BotConfig.UseTimeSpoof and (os.time() - 3) or os.time()
                local success, res = pcall(function() 
                    return mini:InvokeServer(BotConfig.CastPower, math.random(1, 999), fakeTime) 
                end)
                if success and res then ticket = res end
                task.wait(0.5)
            until ticket or not BotConfig.IsRunning or (tick() - start > 20)

            if ticket then
                StatusLabel.Text = "Status: Catching!"
                task.wait(BotConfig.WaitGame)
                pcall(function() finish:FireServer(ticket) end)
            end

            task.wait(BotConfig.WaitCool)
        end
    end)
end

-- Button Event
ToggleBtn.MouseButton1Click:Connect(function()
    BotConfig.IsRunning = not BotConfig.IsRunning
    if BotConfig.IsRunning then
        ToggleBtn.Text = "STOP BOT"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
        StartBot()
    else
        ToggleBtn.Text = "START BOT"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
        StatusLabel.Text = "Status: Stopped"
    end
end)
