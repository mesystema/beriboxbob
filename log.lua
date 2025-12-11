-- [[ SIMPLE UI SCANNER by Gemini ]] --
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Buat GUI Label di layar supaya mudah dilihat di HP
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DebugUI"
ScreenGui.Parent = CoreGui or LocalPlayer.PlayerGui

local Label = Instance.new("TextLabel")
Label.Size = UDim2.new(1, 0, 0, 50)
Label.Position = UDim2.new(0, 0, 0.1, 0)
Label.BackgroundColor3 = Color3.new(0, 0, 0)
Label.BackgroundTransparency = 0.5
Label.TextColor3 = Color3.new(1, 1, 0)
Label.TextSize = 20
Label.Font = Enum.Font.GothamBold
Label.Text = "🔍 Menunggu UI Muncul..."
Label.Parent = ScreenGui

-- Daftar UI yang biasa diabaikan (UI bawaan Roblox/Chat)
local IgnoreList = {"Chat", "BubbleChat", "FreeCamera", "TouchGui", "DebugUI", "FishBotUI_V27"}

local function CheckUI()
    local foundUI = ""
    for _, gui in pairs(PlayerGui:GetChildren()) do
        if gui:IsA("ScreenGui") and gui.Enabled then
            -- Cek apakah nama UI ini bukan UI bawaan
            local isIgnored = false
            for _, name in pairs(IgnoreList) do
                if gui.Name == name then isIgnored = true break end
            end
            
            if not isIgnored then
                -- Cek apakah ada elemen yang visible di dalamnya
                for _, child in pairs(gui:GetDescendants()) do
                    if (child:IsA("Frame") or child:IsA("ImageLabel") or child:IsA("ImageButton")) and child.Visible then
                         -- UI Ditemukan!
                         foundUI = gui.Name .. " -> " .. child.Name
                         break
                    end
                end
            end
        end
    end
    
    if foundUI ~= "" then
        Label.Text = "🛑 UI TERDETEKSI: " .. foundUI
        warn("UI FOUND: " .. foundUI) -- Cek juga di console/logcat
    else
        Label.Text = "🔍 Memantau... (Pancing Manual Sekarang)"
    end
end

RunService.RenderStepped:Connect(CheckUI)
