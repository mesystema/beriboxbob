--[[ 
    ANDROID REMOTE SPY UI v6 (AGGRESSIVE MODE)
    Perbaikan:
    - Menghapus filter nama method (Log SEMUA aktivitas Remote)
    - Menambahkan hook __index untuk menangkap "Direct Calls"
    - UI Test Button tetap ada
]]

local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

-- CONFIG
local isLogging = false 
local isMinimized = false
local expandedSize = UDim2.new(0, 420, 0, 260)
local minimizedSize = UDim2.new(0, 160, 0, 30)

-- 1. CLEANUP UI
if CoreGui:FindFirstChild("AndroidSpyUI_v6") then
    CoreGui.AndroidSpyUI_v6:Destroy()
end

-- 2. SETUP GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AndroidSpyUI_v6"
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 9999
pcall(function() ScreenGui.Parent = CoreGui end)
if not ScreenGui.Parent then ScreenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui") end

-- MAIN FRAME
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = expandedSize
MainFrame.Position = UDim2.new(0.5, -210, 0.15, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true 
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)

-- TITLE BAR
local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -40, 0, 30)
TitleLabel.Position = UDim2.new(0, 10, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "🔥 Aggressive Spy v6"
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
MinBtn.Parent = MainFrame

-- CONTENT & BUTTONS
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
ScrollFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
ScrollFrame.ScrollBarThickness = 4
ScrollFrame.Parent = ContentFrame
local UIListLayout_Log = Instance.new("UIListLayout")
UIListLayout_Log.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout_Log.Padding = UDim.new(0, 2)
UIListLayout_Log.Parent = ScrollFrame

-- UI LOGIC
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

ToggleBtn.MouseButton1Click:Connect(function()
    isLogging = not isLogging
    ToggleBtn.Text = isLogging and "⏹ STOP" or "▶ START"
    ToggleBtn.BackgroundColor3 = isLogging and Color3.fromRGB(230, 126, 34) or Color3.fromRGB(46, 204, 113)
end)
ClearBtn.MouseButton1Click:Connect(function()
    for _, v in pairs(ScrollFrame:GetChildren()) do if v:IsA("TextLabel") then v:Destroy() end end
end)

-- LOGGER FUNCTION
local function LogEvent(remoteName, method, args)
    if not isLogging then return end
    
    task.spawn(function()
        local argsString = ""
        for i, v in pairs(args) do
            local s = tostring(v)
            if type(v) == "table" then s = "{...}" end
            if type(v) == "userdata" then s = typeof(v) end
            argsString = argsString .. s .. ", "
        end
        argsString = argsString:sub(1, -3)
        if argsString == "" then argsString = "nil" end

        local Label = Instance.new("TextLabel")
        Label.BackgroundTransparency = 1
        Label.Font = Enum.Font.Code
        Label.TextSize = 12
        Label.TextXAlignment = Enum.TextXAlignment.Left
        Label.TextWrapped = true
        Label.RichText = true
        
        local colorHex = "#3498db"
        local mLower = method:lower()
        if mLower:find("fire") then colorHex = "#f1c40f" end
        if mLower:find("test") then colorHex = "#9b59b6" end

        Label.Text = string.format("<font color='%s'><b>[%s] %s</b></font>\n<font color='#bdc3c7'>%s</font>", colorHex, method, remoteName, argsString)
        Label.AutomaticSize = Enum.AutomaticSize.Y
        Label.Size = UDim2.new(1, 0, 0, 0)
        Label.Parent = ScrollFrame
        
        if ScrollFrame.CanvasPosition.Y >= (ScrollFrame.CanvasSize.Y.Offset - ScrollFrame.AbsoluteSize.Y) then
             ScrollFrame.CanvasPosition = Vector2.new(0, 99999)
        end
    end)
end

TestBtn.MouseButton1Click:Connect(function()
    local old = isLogging; isLogging = true
    LogEvent("Test_Remote", "TEST", {"Test Success!", 123}); isLogging = old
end)

-- [[ AGGRESSIVE HOOKING LOGIC ]] --

local mt = getrawmetatable(game)
local oldNamecall = mt.__namecall
local oldIndex = mt.__index

if setreadonly then setreadonly(mt, false) else make_writeable(mt) end

-- 1. NAMECALL HOOK (Untuk call biasa: remote:FireServer())
mt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    
    -- Cek jika ini Remote Event/Function
    if isLogging and typeof(self) == "Instance" and (self:IsA("RemoteEvent") or self:IsA("RemoteFunction")) then
        -- KITA HAPUS PENGECEKAN METHOD NAME. LOG SEMUANYA.
        -- Ini akan spam console jika game banyak interaksi, tapi ini satu-satunya cara deteksi.
        LogEvent(self.Name, tostring(method), {...})
    end

    return oldNamecall(self, ...)
end)

-- 2. INDEX HOOK (Untuk direct call: remote.FireServer(remote, ...))
mt.__index = newcclosure(function(self, k)
    -- Jika game mencoba mengakses fungsi "FireServer" atau "InvokeServer"
    if isLogging and typeof(self) == "Instance" and (self:IsA("RemoteEvent") or self:IsA("RemoteFunction")) then
        if tostring(k):lower() == "fireserver" or tostring(k):lower() == "invokeserver" then
            -- Kita tidak bisa log argumen di sini karena ini baru "mengambil" fungsi, belum "memanggil".
            -- Tapi setidaknya kita tahu remote mana yang disentuh.
            LogEvent(self.Name, "DirectIndex: " .. tostring(k), {"Detected attempt to get function"})
        end
    end
    
    return oldIndex(self, k)
end)

if setreadonly then setreadonly(mt, true) end
