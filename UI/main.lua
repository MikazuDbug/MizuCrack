-- ============================================
-- 🌊 MIZUKAGE UI FRAMEWORK
-- ============================================

return function()
    local Core = Modules.Core
    
    local UI = {
        Elements = {},
        Colors = Core.Config.Theme,
        Visible = true,
        Minimized = false
    }
    
    -- Create main UI
    function UI:Create()
        Core:Log("INFO", "Creating UI...")
        
        -- Generate unique name
        local guiName = "MizuUI_" .. Core.Services.HS:GenerateGUID(false):sub(1, 6)
        
        -- Clean up old
        pcall(function()
            Core.Services.CG[guiName]:Destroy()
        end)
        
        -- Parent (CoreGui or PlayerGui fallback)
        local parent = pcall(function() return Core.Services.CG end) and Core.Services.CG 
                     or Core.LocalPlayer:WaitForChild("PlayerGui")
        
        -- Main screen
        self.Elements.Screen = Instance.new("ScreenGui", parent)
        self.Elements.Screen.Name = guiName
        self.Elements.Screen.ResetOnSpawn = false
        self.Elements.Screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        
        -- Create UI components
        self:CreateMainFrame()
        self:CreateHeader()
        self:CreateTabs()
        self:CreateLogArea()
        self:CreateControlBar()
        self:CreateMinimizedButton()
        
        -- Make draggable
        self:MakeDraggable(self.Elements.Header, self.Elements.Main)
        
        -- Start color animation
        self:StartAnimation()
        
        Core:Log("INFO", "UI created")
    end
    
    -- Create main frame
    function UI:CreateMainFrame()
        local frame = Instance.new("Frame", self.Elements.Screen)
        frame.Size = UDim2.new(0, 600, 0, 450)
        frame.Position = UDim2.new(0.5, -300, 0.5, -225)
        frame.BackgroundColor3 = self.Colors.Main
        frame.BackgroundTransparency = 0.1
        frame.BorderSizePixel = 0
        frame.ClipsDescendants = true
        
        -- Corner
        local corner = Instance.new("UICorner", frame)
        corner.CornerRadius = UDim.new(0, 10)
        
        -- Stroke
        local stroke = Instance.new("UIStroke", frame)
        stroke.Color = self.Colors.Stroke
        stroke.Thickness = 2
        
        self.Elements.Main = frame
    end
    
    -- Create header
    function UI:CreateHeader()
        local header = Instance.new("Frame", self.Elements.Main)
        header.Size = UDim2.new(1, 0, 0, 45)
        header.BackgroundColor3 = Color3.fromRGB(15, 18, 25)
        header.BorderSizePixel = 0
        
        -- Corner
        local corner = Instance.new("UICorner", header)
        corner.CornerRadius = UDim.new(0, 10)
        
        -- Title
        local title = Instance.new("TextLabel", header)
        title.Size = UDim2.new(1, -90, 0.5, 0)
        title.Position = UDim2.new(0, 10, 0, 5)
        title.BackgroundTransparency = 1
        title.Text = "🌊 MIZUKAGE " .. Core.Config.Version
        title.TextColor3 = self.Colors.Stroke
        title.Font = Enum.Font.GothamBlack
        title.TextSize = 14
        title.TextXAlignment = Enum.TextXAlignment.Left
        
        -- Subtitle (game info)
        local subtitle = Instance.new("TextLabel", header)
        subtitle.Size = UDim2.new(1, -90, 0.5, 0)
        subtitle.Position = UDim2.new(0, 10, 0.5, -2)
        subtitle.BackgroundTransparency = 1
        subtitle.Text = Core.State.Game.Name .. " [" .. Core.State.Game.ID .. "]"
        subtitle.TextColor3 = Color3.fromRGB(150, 150, 150)
        subtitle.Font = Enum.Font.Gotham
        subtitle.TextSize = 10
        subtitle.TextXAlignment = Enum.TextXAlignment.Left
        
        -- Close button
        local close = Instance.new("TextButton", header)
        close.Size = UDim2.new(0, 35, 0, 35)
        close.Position = UDim2.new(1, -35, 0, 5)
        close.BackgroundTransparency = 1
        close.Text = "X"
        close.TextColor3 = Color3.fromRGB(255, 50, 50)
        close.Font = Enum.Font.GothamBold
        close.TextSize = 16
        
        close.MouseButton1Click:Connect(function()
            self:Destroy()
        end)
        
        -- Minimize button
        local min = Instance.new("TextButton", header)
        min.Size = UDim2.new(0, 35, 0, 35)
        min.Position = UDim2.new(1, -70, 0, 5)
        min.BackgroundTransparency = 1
        min.Text = "-"
        min.TextColor3 = Color3.fromRGB(255, 200, 50)
        min.Font = Enum.Font.GothamBold
        min.TextSize = 20
        
        min.MouseButton1Click:Connect(function()
            self:Minimize()
        end)
        
        self.Elements.Header = header
    end
    
    -- Create tabs
    function UI:CreateTabs()
        local tabFrame = Instance.new("Frame", self.Elements.Main)
        tabFrame.Size = UDim2.new(1, -20, 0, 35)
        tabFrame.Position = UDim2.new(0, 10, 0, 50)
        tabFrame.BackgroundTransparency = 1
        
        local tabs = {"LOGS", "ANALYSIS", "REMOTES", "SCAN", "CONSOLE"}
        local tabWidth = 0.2 -- 100/5 = 20% each
        
        for i, name in ipairs(tabs) do
            local btn = Instance.new("TextButton", tabFrame)
            btn.Size = UDim2.new(tabWidth, -2, 1, 0)
            btn.Position = UDim2.new((i-1) * tabWidth, 2, 0, 0)
            btn.BackgroundColor3 = Color3.fromRGB(20, 22, 30)
            btn.Text = name
            btn.TextColor3 = Color3.fromRGB(200, 200, 200)
            btn.Font = Enum.Font.GothamBold
            btn.TextSize = 12
            
            -- Corner
            local corner = Instance.new("UICorner", btn)
            corner.CornerRadius = UDim.new(0, 6)
            
            -- Hover effect
            btn.MouseEnter:Connect(function()
                btn.BackgroundColor3 = Color3.fromRGB(30, 32, 40)
            end)
            
            btn.MouseLeave:Connect(function()
                btn.BackgroundColor3 = Color3.fromRGB(20, 22, 30)
            end)
            
            btn.MouseButton1Click:Connect(function()
                self:SwitchTab(i)
            end)
        end
        
        self.Elements.Tabs = tabFrame
        self.CurrentTab = 1
    end
    
    -- Create log area
    function UI:CreateLogArea()
        local frame = Instance.new("Frame", self.Elements.Main)
        frame.Size = UDim2.new(1, -20, 1, -140)
        frame.Position = UDim2.new(0, 10, 0, 90)
        frame.BackgroundColor3 = Color3.fromRGB(12, 14, 20)
        frame.BorderSizePixel = 0
        
        -- Corner
        local corner = Instance.new("UICorner", frame)
        corner.CornerRadius = UDim.new(0, 8)
        
        -- Scrolling frame
        local scroll = Instance.new("ScrollingFrame", frame)
        scroll.Size = UDim2.new(1, -10, 1, -10)
        scroll.Position = UDim2.new(0, 5, 0, 5)
        scroll.BackgroundTransparency = 1
        scroll.BorderSizePixel = 0
        scroll.ScrollBarThickness = 4
        scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
        scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
        
        -- Layout
        local layout = Instance.new("UIListLayout", scroll)
        layout.Padding = UDim.new(0, 4)
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        
        self.Elements.LogScroll = scroll
        self.Elements.LogLayout = layout
    end
    
    -- Create control bar
    function UI:CreateControlBar()
        local bar = Instance.new("Frame", self.Elements.Main)
        bar.Size = UDim2.new(1, -20, 0, 40)
        bar.Position = UDim2.new(0, 10, 1, -48)
        bar.BackgroundTransparency = 1
        
        local buttons = {
            {Name = "OUT", Color = Color3.fromRGB(0, 150, 100), Toggle = true},
            {Name = "IN", Color = Color3.fromRGB(200, 50, 50), Toggle = true},
            {Name = "TAMPER", Color = Color3.fromRGB(150, 0, 150), Toggle = true},
            {Name = "CLEAR", Color = Color3.fromRGB(200, 100, 0), Toggle = false},
            {Name = "EXPORT", Color = Color3.fromRGB(0, 100, 200), Toggle = false}
        }
        
        local btnWidth = 0.19 -- 19% each (5 buttons)
        
        for i, btnData in ipairs(buttons) do
            local btn = Instance.new("TextButton", bar)
            btn.Size = UDim2.new(btnWidth, -2, 1, 0)
            btn.Position = UDim2.new((i-1) * btnWidth, 2, 0, 0)
            btn.BackgroundColor3 = btnData.Color
            btn.Text = btnData.Toggle and "🔴 " .. btnData.Name or btnData.Name
            btn.TextColor3 = Color3.new(1, 1, 1)
            btn.Font = Enum.Font.GothamBold
            btn.TextSize = 11
            
            -- Corner
            local corner = Instance.new("UICorner", btn)
