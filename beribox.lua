--[[ 
    ANDROID REMOTE SPY UI v5 (ULTIMATE FIX)
    Metode: Direct Function Hooking + Namecall Fallback
    Fitur: Tombol Test & Debug Console
]]

local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

-- KONFIGURASI
local isLogging = false 
local isMinimized = false
local expandedSize = UDim2.new(0, 420, 0, 260) -- Lebih lebar dikit
local minimizedSize = UDim2.new(0, 160, 0, 30)

-- 1. BERSIHKAN UI LAMA
if CoreGui:FindFirstChild("AndroidSpyUI_v5") then
    CoreGui.AndroidSpyUI_v5:Destroy()
end

-- 2. SETUP GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AndroidSpyUI_v5"
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 9999
pcall(function() ScreenGui.Parent = CoreGui end)
if not ScreenGui.Parent then ScreenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui") end

-- MAIN FRAME
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = expandedSize
MainFrame.Position = UDim2.new(0.5, -210, 0.15, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
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
TitleLabel.Text = "🛠️ Ultimate Spy v5"
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

-- CONTENT AREA
local ContentFrame = Instance.new("Frame")
ContentFrame.Size = UDim2.new(1, 0, 1, -35)
ContentFrame.Position = UDim2.new(0, 0, 0, 35)
ContentFrame.BackgroundTransparency = 1
ContentFrame.Parent = MainFrame

-- BUTTON CONTAINER
local ButtonFrame = Instance.new("Frame")
ButtonFrame.Size = UDim2.new(1, -20, 0, 30)
ButtonFrame.Position = UDim2.new(0, 10, 0, 0)
ButtonFrame.BackgroundTransparency = 1
ButtonFrame.Parent = ContentFrame

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0.4, 0, 1, 0)
ToggleBtn.Position = UDim2.new(0, 0, 0, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
ToggleBtn.Text = "▶ START"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 12
ToggleBtn.Parent = ButtonFrame
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0, 4)

local TestBtn = Instance.new("TextButton") -- TOMBOL BARU
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

-- SCROLL LOGS
local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Size = UDim2.new(1, -10, 1, -40)
ScrollFrame.Position = UDim2.new(0, 5, 0, 35)
ScrollFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
ScrollFrame.ScrollBarThickness = 4
ScrollFrame.Parent = ContentFrame
local UIListLayout_Log = Instance.new("UIListLayout")
UIListLayout_Log.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout_Log.Padding = UDim.new(0, 2)
UIListLayout_Log.Parent = ScrollFrame

-- 3. INTERAKSI UI
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

-- Draggable
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
    if isLogging then
        ToggleBtn.Text = "⏹ STOP"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(230, 126, 34)
    else
        ToggleBtn.Text = "▶ START"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
    end
end)

ClearBtn.MouseButton1Click:Connect(function()
    for _, v in pairs(ScrollFrame:GetChildren()) do if v:IsA("TextLabel") then v:Destroy() end end
end)

-- FUNGSI LOGGING (UI & Console)
local function LogEvent(remoteName, method, args)
    if not isLogging then return end
    
    task.spawn(function()
        -- 1. Print ke Console Asli (Cek F9 jika UI kosong)
        print(">> SPY: " .. remoteName .. " | " .. method)

        -- 2. Print ke UI
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
        
        local colorHex = (method == "FireServer") and "#f1c40f" or "#3498db"
        if method == "TEST" then colorHex = "#9b59b6" end -- Ungu untuk test

        Label.Text = string.format("<font color='%s'><b>[%s] %s</b></font>\n<font color='#bdc3c7'>%s</font>", colorHex, method, remoteName, argsString)
        Label.AutomaticSize = Enum.AutomaticSize.Y
        Label.Size = UDim2.new(1, 0, 0, 0)
        Label.Parent = ScrollFrame
        
        if ScrollFrame.CanvasPosition.Y >= (ScrollFrame.CanvasSize.Y.Offset - ScrollFrame.AbsoluteSize.Y) then
             ScrollFrame.CanvasPosition = Vector2.new(0, 99999)
        end
    end)
end

-- TOMBOL TEST (Untuk Cek UI)
TestBtn.MouseButton1Click:Connect(function()
    -- Paksa Log muncul tanpa perlu remote asli
    local status = isLogging
    isLogging = true -- Paksa on sebentar
    LogEvent("Test_Remote", "TEST", {"Hello", 123, Vector3.new(0,1,0)})
    isLogging = status -- Balikin status
end)


-- 4. HOOKING ENGINE (DUAL ENGINE)

-- ENGINE A: DIRECT FUNCTION HOOK (Lebih Kuat)
local safe_hook = true
local success_hook, err = pcall(function()
    local RemoteEvent = Instance.new("RemoteEvent")
    local RemoteFunction = Instance.new("RemoteFunction")

    -- Hook FireServer
    local oldFireServer
    oldFireServer = hookfunction(RemoteEvent.FireServer, newcclosure(function(self, ...)
        if isLogging then
            LogEvent(self.Name, "FireServer", {...})
        end
        return oldFireServer(self, ...)
    end))

    -- Hook InvokeServer
    local oldInvokeServer
    oldInvokeServer = hookfunction(RemoteFunction.InvokeServer, newcclosure(function(self, ...)
        if isLogging then
            LogEvent(self.Name, "InvokeServer", {...})
        end
        return oldInvokeServer(self, ...)
    end))
end)

if not success_hook then
    warn("Direct Hook Gagal, Menggunakan Fallback Metatable: " .. tostring(err))
    safe_hook = false
end

-- ENGINE B: METATABLE HOOK (Cadangan)
if not safe_hook then
    local mt = getrawmetatable(game)
    local oldNamecall = mt.__namecall
    setreadonly(mt, false)

    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        local args = {...}

        -- Kita longgarkan pengecekan agar lebih sensitif
        if isLogging and (self:IsA("RemoteEvent") or self:IsA("RemoteFunction")) then
            -- Cek string secara manual jika method nil
            local m = tostring(method):lower()
            if m == "fireserver" or m == "invokeserver" then
                LogEvent(self.Name, method, args)
            end
        end

        return oldNamecall(self, ...)
    end)
    setreadonly(mt, true)
end
