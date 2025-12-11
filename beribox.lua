--[[ 
    ANDROID REMOTE SPY UI v2
    Fitur: Start/Stop Toggle & Clear Log
]]

local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- STATUS VARIABEL
local isLogging = false -- Default mati agar tidak spam di awal

-- 1. MEMBERSIHKAN UI LAMA
if CoreGui:FindFirstChild("AndroidSpyUI_v2") then
    CoreGui.AndroidSpyUI_v2:Destroy()
end

-- 2. MEMBUAT UI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AndroidSpyUI_v2"
pcall(function() ScreenGui.Parent = CoreGui end)
if not ScreenGui.Parent then ScreenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui") end

-- Main Frame
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 400, 0, 280) -- Sedikit lebih lebar
MainFrame.Position = UDim2.new(0.5, -200, 0.5, -140)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 10)
UICorner.Parent = MainFrame

-- Title
local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, 0, 0, 25)
TitleLabel.Position = UDim2.new(0, 0, 0, 5)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "📡 Ultimate Spy (Android)"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.Font = Enum.Font.GothamBlack
TitleLabel.TextSize = 18
TitleLabel.Parent = MainFrame

-- Container Tombol (Agar rapi)
local ButtonFrame = Instance.new("Frame")
ButtonFrame.Size = UDim2.new(1, -20, 0, 35)
ButtonFrame.Position = UDim2.new(0, 10, 0, 35)
ButtonFrame.BackgroundTransparency = 1
ButtonFrame.Parent = MainFrame

local UIListLayout_Btn = Instance.new("UIListLayout")
UIListLayout_Btn.FillDirection = Enum.FillDirection.Horizontal
UIListLayout_Btn.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout_Btn.Padding = UDim.new(0, 10)
UIListLayout_Btn.Parent = ButtonFrame

-- Tombol START/STOP
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Name = "ToggleBtn"
ToggleBtn.Size = UDim2.new(0.6, 0, 1, 0) -- Mengambil 60% lebar
ToggleBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113) -- Hijau (Start)
ToggleBtn.Text = "▶ START LOG"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 14
ToggleBtn.Parent = ButtonFrame
local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(0, 6)
ToggleCorner.Parent = ToggleBtn

-- Tombol CLEAR
local ClearBtn = Instance.new("TextButton")
ClearBtn.Name = "ClearBtn"
ClearBtn.Size = UDim2.new(0.35, 0, 1, 0) -- Mengambil sisa lebar
ClearBtn.BackgroundColor3 = Color3.fromRGB(231, 76, 60) -- Merah (Clear)
ClearBtn.Text = "🗑 CLEAR"
ClearBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ClearBtn.Font = Enum.Font.GothamBold
ClearBtn.TextSize = 14
ClearBtn.Parent = ButtonFrame
local ClearCorner = Instance.new("UICorner")
ClearCorner.CornerRadius = UDim.new(0, 6)
ClearCorner.Parent = ClearBtn

-- Scrolling Frame (Area Log)
local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Size = UDim2.new(1, -20, 1, -90)
ScrollFrame.Position = UDim2.new(0, 10, 0, 80)
ScrollFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
ScrollFrame.ScrollBarThickness = 4
ScrollFrame.Parent = MainFrame

local UIListLayout_Log = Instance.new("UIListLayout")
UIListLayout_Log.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout_Log.Padding = UDim.new(0, 4)
UIListLayout_Log.Parent = ScrollFrame

-- 3. LOGIKA TOMBOL
ToggleBtn.MouseButton1Click:Connect(function()
    isLogging = not isLogging -- Balikkan status (True jadi False, False jadi True)
    
    if isLogging then
        -- Mode Merekam
        ToggleBtn.Text = "⏹ STOP LOG"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(230, 126, 34) -- Oranye/Merah
    else
        -- Mode Standby
        ToggleBtn.Text = "▶ START LOG"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113) -- Hijau
    end
end)

ClearBtn.MouseButton1Click:Connect(function()
    -- Hapus semua anak ScrollFrame kecuali UIListLayout
    for _, v in pairs(ScrollFrame:GetChildren()) do
        if v:IsA("TextLabel") then
            v:Destroy()
        end
    end
end)

-- 4. LOGIKA DRAGGABLE (Geser UI)
local dragging, dragInput, dragStart, startPos

local function update(input)
    local delta = input.Position - dragStart
    MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

MainFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        update(input)
    end
end)

-- 5. FUNGSI PENCETAK LOG
local function LogToUI(remoteName, method, args)
    local Label = Instance.new("TextLabel")
    Label.BackgroundTransparency = 1
    Label.Font = Enum.Font.Code
    Label.TextSize = 13
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.TextWrapped = true
    Label.RichText = true
    
    local argsString = ""
    for i,v in pairs(args) do
        argsString = argsString .. tostring(v) .. ", "
    end
    argsString = argsString:sub(1, -3) 
    if argsString == "" then argsString = "nil" end

    local colorHex = (method == "FireServer") and "#f39c12" or "#3498db"
    
    Label.Text = string.format("<font color='%s'><b>[%s] %s</b></font>\n<font color='#bdc3c7'>%s</font>", colorHex, method, remoteName, argsString)
    
    Label.AutomaticSize = Enum.AutomaticSize.Y
    Label.Size = UDim2.new(1, 0, 0, 0)
    Label.Parent = ScrollFrame
    
    if ScrollFrame.CanvasPosition.Y >= (ScrollFrame.CanvasSize.Y.Offset - ScrollFrame.AbsoluteSize.Y) then
         ScrollFrame.CanvasPosition = Vector2.new(0, 99999)
    end
end

-- 6. HOOK UTAMA (Metatable)
local mt = getrawmetatable(game)
local oldNamecall = mt.__namecall
setreadonly(mt, false)

mt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    local args = {...}

    -- Cek Logika Logging (Hanya log jika tombol START sudah ditekan)
    if isLogging and (self.ClassName == "RemoteEvent" or self.ClassName == "RemoteFunction") then
        if method == "FireServer" or method == "InvokeServer" then
            LogToUI(self.Name, method, args)
        end
    end

    return oldNamecall(self, ...)
end)

setreadonly(mt, true)
