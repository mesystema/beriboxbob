--[[ 
    ANDROID REMOTE SPY UI v7 (STABILITY FIX)
    Metode: Buffer Queue System (Sistem Antrian)
    Fix: Mengatasi Crash saat Start/Clear/Test
]]

local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- KONFIGURASI
local isLogging = false 
local isMinimized = false
local LogQueue = {} -- Tempat penampungan data sementara (Buffer)
local isProcessing = false

-- UKURAN UI
local expandedSize = UDim2.new(0, 400, 0, 250)
local minimizedSize = UDim2.new(0, 150, 0, 30)

-- 1. BERSIHKAN UI LAMA
if CoreGui:FindFirstChild("AndroidSpyUI_v7") then
    CoreGui.AndroidSpyUI_v7:Destroy()
end

-- 2. SETUP GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AndroidSpyUI_v7"
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 9999
pcall(function() ScreenGui.Parent = CoreGui end)
if not ScreenGui.Parent then ScreenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui") end

-- MAIN FRAME
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = expandedSize
MainFrame.Position = UDim2.new(0.5, -200, 0.15, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true 
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)

-- TITLE
local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -40, 0, 30)
TitleLabel.Position = UDim2.new(0, 10, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "🛡️ Stable Spy v7"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.Font = Enum.Font.GothamBlack
TitleLabel.TextSize = 14
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = MainFrame

-- MINIMIZE
local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 30, 0, 30)
MinBtn.Position = UDim2.new(1, -30, 0, 0)
MinBtn.BackgroundTransparency = 1
MinBtn.Text = "_"
MinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinBtn.Font = Enum.Font.GothamBold
MinBtn.TextSize = 18
MinBtn.Parent = MainFrame

-- CONTENT
local ContentFrame = Instance.new("Frame")
ContentFrame.Size = UDim2.new(1, 0, 1, -35)
ContentFrame.Position = UDim2.new(0, 0, 0, 35)
ContentFrame.BackgroundTransparency = 1
ContentFrame.Parent = MainFrame

local ButtonFrame = Instance.new("Frame")
ButtonFrame.Size = UDim2.new(1, -20, 0, 30)
ButtonFrame.Position = UDim2.new(0, 10, 0, 0)
ButtonFrame.BackgroundTransparency = 1
ButtonFrame.Parent = ContentFrame

-- TOMBOL-TOMBOL
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0.4, 0, 1, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
ToggleBtn.Text = "▶ START"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 12
ToggleBtn.Parent = ButtonFrame
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0, 4)

local TestBtn = Instance.new("TextButton")
TestBtn.Size = UDim2.new(0.25, 0, 1, 0)
TestBtn.Position = UDim2.new(0.42, 0, 0, 0)
TestBtn.BackgroundColor3 = Color3.fromRGB(52, 152, 219)
TestBtn.Text = "TEST"
TestBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
TestBtn.Font = Enum.Font.GothamBold
TestBtn.TextSize = 12
TestBtn.Parent = ButtonFrame
Instance.new("UICorner", TestBtn).CornerRadius = UDim.new(0, 4)

local ClearBtn = Instance.new("TextButton")
ClearBtn.Size = UDim2.new(0.3, 0, 1, 0)
ClearBtn.Position = UDim2.new(0.7, 0, 0, 0)
ClearBtn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
ClearBtn.Text = "CLR"
ClearBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ClearBtn.Font = Enum.Font.GothamBold
ClearBtn.TextSize = 12
ClearBtn.Parent = ButtonFrame
Instance.new("UICorner", ClearBtn).CornerRadius = UDim.new(0, 4)

local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Size = UDim2.new(1, -10, 1, -40)
ScrollFrame.Position = UDim2.new(0, 5, 0, 35)
ScrollFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
ScrollFrame.ScrollBarThickness = 4
ScrollFrame.Parent = ContentFrame
local UIListLayout = Instance.new("UIListLayout")
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 2)
UIListLayout.Parent = ScrollFrame

-- UI LOGIC (Minimize & Drag)
MinBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    if isMinimized then
        MainFrame:TweenSize(minimizedSize, "Out", "Quad", 0.3, true)
        MinBtn.Text = "+"
        ContentFrame.Visible = false
        MainFrame.Active = false 
    else
        MainFrame:TweenSize(expandedSize, "Out", "Quad", 0.3, true)
        MinBtn.Text = "_"
        task.wait(0.2)
        ContentFrame.Visible = true
        MainFrame.Active = true
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

-- TOMBOL LOGIC
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
    LogQueue = {} -- Bersihkan antrian juga
    for _, v in pairs(ScrollFrame:GetChildren()) do 
        if v:IsA("TextLabel") then v:Destroy() end 
    end
end)

-- 3. SISTEM PENCATATAN DATA (BUFFER)
-- Fungsi ini HANYA menyimpan data, tidak membuat UI (Biar gak crash)
local function AddToQueue(remoteName, method, args)
    if not isLogging then return end
    
    -- Batas Aman: Jika antrian > 50, jangan terima lagi (Anti Lag)
    if #LogQueue > 50 then return end

    table.insert(LogQueue, {
        name = remoteName,
        method = method,
        args = args,
        color = (method == "FireServer" and "#f1c40f") or (method == "TEST" and "#9b59b6") or "#3498db"
    })
end

TestBtn.MouseButton1Click:Connect(function()
    local old = isLogging; isLogging = true
    AddToQueue("Test_Remote", "TEST", {"System Check", os.time()})
    isLogging = old
end)

-- 4. SISTEM UI UPDATE (Render Loop)
-- Ini berjalan terpisah dari Hook, setiap 0.1 detik memproses data
task.spawn(function()
    while true do
        task.wait(0.1) -- Delay kecil agar HP bisa nafas
        
        if #LogQueue > 0 then
            -- Proses maksimal 5 log per update agar tidak freeze
            for i = 1, 5 do
                local data = table.remove(LogQueue, 1)
                if not data then break end
                
                -- Proses parsing argumen di sini (Aman)
                local success, argsString = pcall(function()
                    local s = ""
                    for _, v in pairs(data.args) do
                        local val = tostring(v)
                        if type(v) == "table" then val = "{...}" end
                        s = s .. val .. ", "
                    end
                    return s:sub(1, -3)
                end)
                if not success or argsString == "" then argsString = "nil" end

                local Label = Instance.new("TextLabel")
                Label.BackgroundTransparency = 1
                Label.Font = Enum.Font.Code
                Label.TextSize = 12
                Label.TextXAlignment = Enum.TextXAlignment.Left
                Label.TextWrapped = true
                Label.RichText = true
                Label.Text = string.format("<font color='%s'><b>[%s] %s</b></font>\n<font color='#bdc3c7'>%s</font>", data.color, data.method, data.name, argsString)
                Label.AutomaticSize = Enum.AutomaticSize.Y
                Label.Size = UDim2.new(1, 0, 0, 0)
                Label.Parent = ScrollFrame
            end
            
            -- Auto Scroll
            if ScrollFrame.CanvasPosition.Y >= (ScrollFrame.CanvasSize.Y.Offset - ScrollFrame.AbsoluteSize.Y - 50) then
                 ScrollFrame.CanvasPosition = Vector2.new(0, 99999)
            end
        end
    end
end)

-- 5. HOOKING (SAFE MODE)
-- Kita kembali ke Namecall saja, karena Index hook sering bikin crash di Android
local mt = getrawmetatable(game)
local oldNamecall = mt.__namecall
if setreadonly then setreadonly(mt, false) else make_writeable(mt) end

mt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    
    if isLogging and (self.ClassName == "RemoteEvent" or self.ClassName == "RemoteFunction") then
        local m = tostring(method):lower()
        -- Deteksi longgar: FireServer, InvokeServer, atau nama method apa saja (opsional)
        if m == "fireserver" or m == "invokeserver" then
            AddToQueue(self.Name, tostring(method), {...})
        end
    end

    return oldNamecall(self, ...)
end)

if setreadonly then setreadonly(mt, true) end
