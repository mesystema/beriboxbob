--[[ 
    AUTO FISHING BOT (Based on Captured Logs)
    Optimized for Android
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- CONFIG
_G.AutoFish = false -- Status Awal Mati

-- MENCARI LOKASI REMOTE (Berdasarkan nama log kamu "RE/..." dan "RF/...")
-- Biasanya ada folder bernama "RE" dan "RF" di ReplicatedStorage
local RE_Folder = ReplicatedStorage:WaitForChild("RE")
local RF_Folder = ReplicatedStorage:WaitForChild("RF")

-- REMOTE DEFINITIONS
local EquipRemote = RE_Folder:WaitForChild("EquipToolFromHotbar")
local ChargeRemote = RF_Folder:WaitForChild("ChargeFishingRod")
local MinigameRemote = RF_Folder:WaitForChild("RequestFishingMinigameStarted")
local FinishRemote = RE_Folder:WaitForChild("FishingCompleted")

-- UI SEDERHANA (Hanya Tombol Toggle)
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "FishBotUI"
if game.CoreGui:FindFirstChild("FishBotUI") then game.CoreGui.FishBotUI:Destroy() end
ScreenGui.Parent = game.CoreGui

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Name = "Toggle"
ToggleBtn.Size = UDim2.new(0, 150, 0, 50)
ToggleBtn.Position = UDim2.new(0.5, -75, 0.1, 0) -- Di atas tengah
ToggleBtn.BackgroundColor3 = Color3.fromRGB(231, 76, 60) -- Merah (Mati)
ToggleBtn.Text = "OFF - CLICK TO START"
ToggleBtn.TextColor3 = Color3.new(1,1,1)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 14
ToggleBtn.Parent = ScreenGui
local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 10)
UICorner.Parent = ToggleBtn

-- STATUS LABEL
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, 0, 0, 20)
StatusLabel.Position = UDim2.new(0, 0, 1, 0)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Idle"
StatusLabel.TextColor3 = Color3.new(1,1,1)
StatusLabel.Parent = ToggleBtn

-- FUNGSI UTAMA (AUTO FARM LOOP)
local function StartFarming()
    task.spawn(function()
        while _G.AutoFish do
            pcall(function()
                -- 1. EQUIP ROD
                StatusLabel.Text = "1. Equipping Rod..."
                EquipRemote:FireServer(1) 
                task.wait(0.5)

                -- 2. CHARGE / THROW (Menggunakan waktu dinamis agar aman)
                StatusLabel.Text = "2. Casting Line..."
                -- Kita gunakan argumen waktu saat ini
                ChargeRemote:InvokeServer(workspace.DistributedGameTime)
                task.wait(1) 

                -- 3. MINIGAME START
                StatusLabel.Text = "3. Playing Minigame..."
                -- Argumen dari log: 1.233 (Power?), Random ID, os.time()
                -- Kita buat ID random dan Time baru agar server tidak curiga
                local castPower = 1.0 
                local randomID = math.random(100000000, 999999999) 
                local timeNow = os.time()
                
                MinigameRemote:InvokeServer(castPower, randomID, timeNow)
                
                -- Tunggu sebentar seolah-olah kita sedang main minigame
                task.wait(2.5) 

                -- 4. FINISH / CATCH
                StatusLabel.Text = "4. Catching Fish!"
                FinishRemote:FireServer()
                
                StatusLabel.Text = "Success! Cooldown..."
                task.wait(1.5) -- Jeda antar tangkapan
            end)
            
            if not _G.AutoFish then break end
        end
        StatusLabel.Text = "Stopped."
        ToggleBtn.Text = "OFF - CLICK TO START"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
    end)
end

-- LOGIKA TOMBOL
ToggleBtn.MouseButton1Click:Connect(function()
    _G.AutoFish = not _G.AutoFish
    
    if _G.AutoFish then
        ToggleBtn.Text = "ON - FARMING..."
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113) -- Hijau
        StartFarming()
    else
        ToggleBtn.Text = "STOPPING..."
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(230, 126, 34)
    end
end)
