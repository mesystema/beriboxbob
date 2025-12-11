-- [[ LIGHTWEIGHT REMOTE SCANNER v2 ]] --
-- Khusus Android/Ronix yang tidak kuat buka DarkDex
-- Fitur: Menampilkan RemoteEvent/Function dan Path-nya

local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- 1. SETUP UI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SimpleScanner"
ScreenGui.ResetOnSpawn = false
if CoreGui:FindFirstChild("SimpleScanner") then CoreGui.SimpleScanner:Destroy() end
ScreenGui.Parent = CoreGui

-- Frame Utama
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0.7, 0, 0.6, 0) -- Ukuran pas di HP
MainFrame.Position = UDim2.new(0.15, 0, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
MainFrame.BorderSizePixel = 2
MainFrame.BorderColor3 = Color3.fromRGB(46, 204, 113)
MainFrame.Parent = ScreenGui

-- Judul
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -30, 0, 30)
Title.Position = UDim2.new(0, 5, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "🔍 Scanning ReplicatedStorage..."
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 14
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = MainFrame

-- Tombol Close (X)
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -30, 0, 0)
CloseBtn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255,255,255)
CloseBtn.Parent = MainFrame
CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

-- Area Scroll List
local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Size = UDim2.new(1, -10, 1, -40)
ScrollFrame.Position = UDim2.new(0, 5, 0, 35)
ScrollFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
ScrollFrame.Parent = MainFrame

local UIList = Instance.new("UIListLayout")
UIList.Padding = UDim.new(0, 2)
UIList.Parent = ScrollFrame

-- 2. FUNGSI SCANNING
local function Scan()
    local Count = 0
    -- Cari di ReplicatedStorage
    local items = ReplicatedStorage:GetDescendants()
    
    for _, v in pairs(items) do
        -- Filter: Hanya RemoteEvent atau RemoteFunction
        if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
            Count = Count + 1
            
            local Btn = Instance.new("TextButton")
            Btn.Size = UDim2.new(1, 0, 0, 35)
            Btn.BackgroundColor3 = v:IsA("RemoteEvent") and Color3.fromRGB(52, 152, 219) or Color3.fromRGB(155, 89, 182)
            Btn.Text = "  " .. v.Name .. " (" .. v.ClassName .. ")"
            Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            Btn.TextXAlignment = Enum.TextXAlignment.Left
            Btn.Font = Enum.Font.Code
            Btn.TextSize = 12
            Btn.Parent = ScrollFrame
            
            -- KLIK UNTUK COPY PATH
            Btn.MouseButton1Click:Connect(function()
                setclipboard(v.Name) -- Copy Nama saja
                Title.Text = "✅ Copied: " .. v.Name
                wait(1)
                Title.Text = "🔍 Found: " .. Count .. " Remotes"
            end)
        end
    end
    Title.Text = "🔍 Found: " .. Count .. " Remotes"
    ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, UIList.AbsoluteContentSize.Y)
end

-- Jalankan Scan
task.spawn(Scan)
