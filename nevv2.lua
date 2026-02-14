local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- [[ CONFIG ]] --
local Settings = { Enabled = false, CastPower = 100, WaitGame = 2.5 }

-- [[ UI CLEANUP ]] --
if CoreGui:FindFirstChild("FishItFixed") then CoreGui.FishItFixed:Destroy() end

-- [[ UI CREATION ]] --
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "FishItFixed"
ScreenGui.Parent = (gethui and gethui()) or CoreGui
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 220, 0, 200)
MainFrame.Position = UDim2.new(0.5, -110, 0.4, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
MainFrame.BorderSizePixel = 2
MainFrame.BorderColor3 = Color3.fromRGB(0, 255, 150)
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 35)
Title.Text = "FISH IT - STABLE"
Title.TextColor3 = Color3.white
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBold
Title.Parent = MainFrame

-- FUNGSI UNTUK BUAT TOMBOL (Lebih Aman)
local function CreateButton(name, pos, color, text)
    local btn = Instance.new("TextButton")
    btn.Name = name
    btn.Size = UDim2.new(0.85, 0, 0, 40)
    btn.Position = pos
    btn.BackgroundColor3 = color
    btn.Text = text
    btn.TextColor3 = Color3.white
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.BorderSizePixel = 0
    btn.ZIndex = 5 -- Memastikan di atas frame
    btn.Parent = MainFrame
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = btn
    
    return btn
end

local StartBtn = CreateButton("StartBtn", UDim2.new(0.075, 0, 0.25, 0), Color3.fromRGB(46, 204, 113), "START BOT")
local CloseBtn = CreateButton("CloseBtn", UDim2.new(0.075, 0, 0.55, 0), Color3.fromRGB(180, 50, 50), "CLOSE UI")

-- [[ LOGIC ]] --
local function GetRemotes()
    local charge = ReplicatedStorage:FindFirstChild("ChargeFish", true) or ReplicatedStorage:FindFirstChild("Cast", true)
    local mini = ReplicatedStorage:FindFirstChild("Minigame", true) or ReplicatedStorage:FindFirstChild("Catch", true)
    local finish = ReplicatedStorage:FindFirstChild("FishingComplet", true) or ReplicatedStorage:FindFirstChild("Complete", true)
    local sell = ReplicatedStorage:FindFirstChild("SellFish", true) or ReplicatedStorage:FindFirstChild("Sell", true)
    return charge, mini, finish, sell
end

local function MainLoop()
    task.spawn(function()
        while Settings.Enabled do
            local charge, mini, finish, sell = GetRemotes()
            
            -- Auto Sell
            if sell then pcall(function() sell:FireServer() end) end

            if charge and mini and finish then
                pcall(function() charge:InvokeServer(Settings.CastPower) end)
                task.wait(0.5)

                local ticket = nil
                local start = tick()
                repeat
                    local success, res = pcall(function() 
                        return mini:InvokeServer(Settings.CastPower, math.random(1, 1000), os.time()) 
                    end)
                    if success and res then ticket = res end
                    task.wait(0.5)
                until ticket or not Settings.Enabled or (tick() - start > 20)

                if ticket then
                    task.wait(Settings.WaitGame)
                    pcall(function() finish:FireServer(ticket) end)
                end
            end
            task.wait(0.5)
        end
    end)
end

-- [[ BUTTON EVENTS ]] --
StartBtn.MouseButton1Click:Connect(function()
    Settings.Enabled = not Settings.Enabled
    if Settings.Enabled then
        StartBtn.Text = "STOP BOT"
        StartBtn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
        MainLoop()
    else
        StartBtn.Text = "START BOT"
        StartBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
    end
end)

CloseBtn.MouseButton1Click:Connect(function()
    Settings.Enabled = false
    ScreenGui:Destroy()
end)
