--[[ 
    ANDROID REMOTE SPY UI v4 (SAFE THREAD MODE)
    Perbaikan:
    - Menggunakan task.spawn agar TIDAK memblokir gameplay (Pancingan fix)
    - Error handling pada argumen (Mengatasi log kosong/crash)
    - UI Minimize tetap ada
]]

local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

-- CONFIG & STATUS
local isLogging = false 
local isMinimized = false
local expandedSize = UDim2.new(0, 380, 0, 250)
local minimizedSize = UDim2.new(0, 150, 0, 30)

-- 1. BERSIHKAN UI LAMA
if CoreGui:FindFirstChild("AndroidSpyUI_Safe") then
    CoreGui.AndroidSpyUI_Safe:Destroy()
end

-- 2. SETUP SCREEN GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AndroidSpyUI_Safe"
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 999 
pcall(function() ScreenGui.Parent = CoreGui end)
if not ScreenGui.Parent then ScreenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui") end

-- 3. MAIN FRAME
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = expandedSize
MainFrame.Position = UDim2.new(0.5, -190, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true -- Hanya aktif saat mode besar
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = MainFrame

-- TITLE BAR
local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -40, 0, 30)
TitleLabel.Position = UDim2.new(0, 10, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "🛡️ Safe Spy v4"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.Font = Enum.Font.GothamBlack
TitleLabel.TextSize = 14
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = MainFrame

-- MINIMIZE BUTTON
local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 30, 0, 30)
MinBtn.Position = UDim2.new(1, -30, 0, 0)
MinBtn.BackgroundTransparency = 1
MinBtn.Text = "_"
MinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinBtn.Font = Enum.Font.GothamBold
MinBtn.TextSize = 18
MinBtn.TextYAlignment = Enum.TextYAlignment.Bottom
MinBtn.Parent = MainFrame

-- CONTENT FRAME
local ContentFrame = Instance.new("Frame")
ContentFrame.Size = UDim2.new(1, 0, 1, -35)
ContentFrame.Position = UDim2.new(0, 0, 0, 35)
ContentFrame.BackgroundTransparency = 1
ContentFrame.Parent = MainFrame

-- TOMBOL START/CLEAR
local ButtonFrame = Instance.new("Frame")
ButtonFrame.Size = UDim2.new(1, -20, 0, 30)
ButtonFrame.Position = UDim2.new(0, 10, 0, 0)
ButtonFrame.BackgroundTransparency = 1
ButtonFrame.Parent = ContentFrame

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0.65, 0, 1, 0)
ToggleBtn.Position = UDim2.new(0, 0, 0, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
ToggleBtn.Text = "▶ START"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 12
ToggleBtn.Parent = ButtonFrame
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0, 4)

local ClearBtn = Instance.new("TextButton")
ClearBtn.Size = UDim2.new(0.33, 0, 1, 0)
ClearBtn.Position = UDim2.new(0.67, 0, 0, 0)
ClearBtn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
ClearBtn.Text = "CLR"
ClearBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ClearBtn.Font = Enum.Font.GothamBold
ClearBtn.TextSize = 12
ClearBtn.Parent = ButtonFrame
Instance.new("UICorner", ClearBtn).CornerRadius = UDim.new(0, 4)

-- SCROLL LOGS
local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Size = UDim2.new(1, -10, 1, -40)
ScrollFrame.Position = UDim2.new(0, 5, 0, 35)
ScrollFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
ScrollFrame.ScrollBarThickness = 3
ScrollFrame.BorderSizePixel = 0
ScrollFrame.Parent = ContentFrame

local UIListLayout_Log = Instance.new("UIListLayout")
UIListLayout_Log.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout_Log.Padding = UDim.new(0, 2)
UIListLayout_Log.Parent = ScrollFrame

-- 4. LOGIKA UI (Minimize & Drag)
MinBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    if isMinimized then
        MainFrame:TweenSize(minimizedSize, "Out", "Quad", 0.3, true)
        MinBtn.Text = "+"
        MinBtn.TextYAlignment = Enum.TextYAlignment.Center
        ContentFrame.Visible = false
        MainFrame.Active = false -- Matikan touch block saat minimize
    else
        MainFrame:TweenSize(expandedSize, "Out", "Quad", 0.3, true)
        MinBtn.Text = "_"
        MinBtn.TextYAlignment = Enum.TextYAlignment.Bottom
        task.wait(0.2)
        ContentFrame.Visible = true
        MainFrame.Active = true
    end
end)

-- Drag Logic
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
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
MainFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
end)
UserInputService.InputChanged:Connect(function(input) if input == dragInput and dragging then update(input) end end)

-- 5. LOGIKA START/STOP
ToggleBtn.MouseButton1Click:Connect(function()
    isLogging = not isLogging
    if isLogging then
        ToggleBtn.Text = "⏹ STOP"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(230, 126, 34)
    else
        ToggleBtn.Text = "▶ START"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
    end
end)

ClearBtn.MouseButton1Click:Connect(function()
    for _, v in pairs(ScrollFrame:GetChildren()) do
        if v:IsA("TextLabel") then v:Destroy() end
    end
end)

-- 6. FUNGSI LOG (Safe Parser)
local function SafeLog(remoteName, method, args)
    if not isLogging then return end
    
    -- Gunakan pcall untuk mencegah error UI merusak game
    pcall(function()
        local argsString = ""
        for i, v in pairs(args) do
            -- Cek tipe data agar tidak error saat convert ke string
            local valStr = tostring(v)
            if type(v) == "userdata" then valStr = typeof(v) end
            if type(v) == "table" then valStr = "{...}" end -- Sederhanakan table
            
            argsString = argsString .. valStr .. ", "
        end
        argsString = argsString:sub(1, -3)
        if argsString == "" then argsString = "nil" end

        local Label = Instance.new("TextLabel")
        Label.BackgroundTransparency = 1
        Label.Font = Enum.Font.Code
        Label.TextSize = 11
        Label.TextXAlignment = Enum.TextXAlignment.Left
        Label.TextWrapped = true
        Label.RichText = true
        
        local colorHex = (method == "FireServer") and "#f39c12" or "#3498db"
        Label.Text = string.format("<font color='%s'>[%s] %s</font>\n<font color='#bdc3c7'>%s</font>", colorHex, method, remoteName, argsString)
        
        Label.AutomaticSize = Enum.AutomaticSize.Y
        Label.Size = UDim2.new(1, 0, 0, 0)
        Label.Parent = ScrollFrame
        
        if ScrollFrame.CanvasPosition.Y >= (ScrollFrame.CanvasSize.Y.Offset - ScrollFrame.AbsoluteSize.Y) then
             ScrollFrame.CanvasPosition = Vector2.new(0, 99999)
        end
    end)
end

-- 7. HOOKING (INTI PERBAIKAN)
local mt = getrawmetatable(game)
local oldNamecall = mt.__namecall
if setreadonly then setreadonly(mt, false) else make_writeable(mt) end

mt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    local args = {...}

    -- CEK 1: Apakah ini Remote?
    if (self.ClassName == "RemoteEvent" or self.ClassName == "RemoteFunction") then
        -- CEK 2: Apakah method-nya benar? (Case insensitive check untuk beberapa executor android)
        if method == "FireServer" or method == "fireServer" or method == "InvokeServer" or method == "invokeServer" then
            
            -- PERBAIKAN UTAMA: Gunakan task.spawn
            -- Ini memisahkan proses logging dari proses game.
            -- Game akan lanjut jalan duluan (return oldNamecall), logging nyusul belakangan.
            task.spawn(function()
                SafeLog(self.Name, method, args)
            end)
            
        end
    end

    -- PENTING: Selalu kembalikan fungsi asli APAPUN yang terjadi
    return oldNamecall(self, ...)
end)

if setreadonly then setreadonly(mt, true) end
