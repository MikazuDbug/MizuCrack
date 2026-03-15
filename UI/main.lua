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
            corner.CornerRadius = UDim.new(0, 6)
            
            -- Store reference
            self.Elements[btnData.Name] = btn
            
            -- Click handler
            btn.MouseButton1Click:Connect(function()
                if btnData.Toggle then
                    local state = not Core.State.Recording[btnData.Name:lower()]
                    Core.State.Recording[btnData.Name:lower()] = state
                    btn.Text = (state and "🟢 " or "🔴 ") .. btnData.Name
                    btn.BackgroundColor3 = state and Color3.fromRGB(0, 200, 0) or btnData.Color
                else
                    self:HandleAction(btnData.Name)
                end
            end)
        end
        
        -- Status text
        local status = Instance.new("TextLabel", bar)
        status.Size = UDim2.new(1, 0, 0, 15)
        status.Position = UDim2.new(0, 0, 1, 5)
        status.BackgroundTransparency = 1
        status.Text = "Ready | Logs: 0 | Remotes: 0"
        status.TextColor3 = Color3.fromRGB(150, 150, 150)
        status.Font = Enum.Font.Gotham
        status.TextSize = 10
        status.TextXAlignment = Enum.TextXAlignment.Left
        
        self.Elements.Status = status
    end
    
    -- Create minimized button
    function UI:CreateMinimizedButton()
        local btn = Instance.new("TextButton", self.Elements.Screen)
        btn.Size = UDim2.new(0, 45, 0, 45)
        btn.Position = UDim2.new(0, 50, 0, 50)
        btn.BackgroundColor3 = self.Colors.Main
        btn.Text = "M"
        btn.TextColor3 = self.Colors.Stroke
        btn.Font = Enum.Font.GothamBlack
        btn.TextSize = 20
        btn.Visible = false
        btn.ClipsDescendants = true
        
        -- Corner
        local corner = Instance.new("UICorner", btn)
        corner.CornerRadius = UDim.new(1, 0)
        
        -- Stroke
        local stroke = Instance.new("UIStroke", btn)
        stroke.Color = self.Colors.Stroke
        stroke.Thickness = 2
        
        -- Click to restore
        btn.MouseButton1Click:Connect(function()
            self:Restore()
        end)
        
        -- Make draggable
        self:MakeDraggable(btn, btn)
        
        self.Elements.MinButton = btn
    end
    
    -- Add log entry to UI
    function UI:AddLog(level, message, data)
        if not self.Elements.LogScroll then return end
        
        -- Create entry frame
        local entry = Instance.new("Frame", self.Elements.LogScroll)
        entry.Size = UDim2.new(1, -8, 0, 30)
        entry.BackgroundColor3 = Color3.fromRGB(20, 22, 30)
        entry.BorderSizePixel = 0
        
        -- Corner
        local corner = Instance.new("UICorner", entry)
        corner.CornerRadius = UDim.new(0, 4)
        
        -- Text
        local text = Instance.new("TextLabel", entry)
        text.Size = UDim2.new(1, -10, 1, 0)
        text.Position = UDim2.new(0, 5, 0, 0)
        text.BackgroundTransparency = 1
        text.Text = message
        text.TextColor3 = Color3.fromRGB(200, 200, 200)
        text.Font = Enum.Font.Code
        text.TextSize = 11
        text.TextXAlignment = Enum.TextXAlignment.Left
        text.TextYAlignment = Enum.TextYAlignment.Center
        text.TextTruncate = Enum.TextTruncate.AtEnd
        
        -- Color based on level
        if level == "ERROR" then
            text.TextColor3 = Color3.fromRGB(255, 80, 80)
        elseif level == "WARN" then
            text.TextColor3 = Color3.fromRGB(255, 200, 50)
        end
        
        -- Auto-scroll
        task.wait()
        self.Elements.LogScroll.CanvasPosition = Vector2.new(0, 999999)
        
        -- Limit entries
        if #self.Elements.LogScroll:GetChildren() > 150 then
            self.Elements.LogScroll:GetChildren()[2]:Destroy()
        end
    end
    
    -- Update status
    function UI:UpdateStatus()
        if not self.Elements.Status then return end
        
        local text = string.format("OUT: %s | IN: %s | TAMPER: %s | Logs: %d | Remotes: %d",
            Core.State.Recording.Outbound and "ON" or "OFF",
            Core.State.Recording.Inbound and "ON" or "OFF",
            Core.State.TamperEnabled and "ON" or "OFF",
            Core.State.Count,
            Core:TableLength(Core.State.RemoteStats)
        )
        
        self.Elements.Status.Text = text
    end
    
    -- Switch tab
    function UI:SwitchTab(tab)
        self.CurrentTab = tab
        -- Clear and show appropriate content
        self:UpdateStatus()
    end
    
    -- Handle actions
    function UI:HandleAction(action)
        if action == "CLEAR" then
            Core.State.Logs = {}
            Core.State.Count = 0
            
            -- Clear UI
            for _, v in ipairs(self.Elements.LogScroll:GetChildren()) do
                if v:IsA("Frame") then
                    v:Destroy()
                end
            end
            
            self:AddLog("INFO", "Logs cleared")
            
        elseif action == "EXPORT" then
            self:ExportLogs()
        end
        
        self:UpdateStatus()
    end
    
    -- Export logs
    function UI:ExportLogs()
        self:AddLog("INFO", "Exporting logs...")
        
        -- Format logs
        local lines = {
            "MIZUKAGE " .. Core.Config.Version .. " EXPORT",
            "Game: " .. Core.State.Game.Name,
            "ID: " .. Core.State.Game.ID,
            "Time: " .. os.date("%Y-%m-%d %H:%M:%S"),
            "Total Logs: " .. Core.State.Count,
            "Remotes Tracked: " .. Core:TableLength(Core.State.RemoteStats),
            "========================================"
        }
        
        for _, log in ipairs(Core.State.Logs) do
            table.insert(lines, string.format("[%s] %s", 
                os.date("%H:%M:%S", log.time),
                log.message
            ))
        end
        
        local content = table.concat(lines, "\n")
        
        -- Save to file if possible
        if writefile then
            local filename = "Mizukage_" .. Core.State.Game.ID .. "_" .. os.time() .. ".txt"
            pcall(function() writefile(filename, content) end)
            self:AddLog("INFO", "Saved to: " .. filename)
        end
        
        -- Copy to clipboard
        if setclipboard then
            setclipboard(content)
            self:AddLog("INFO", "Copied to clipboard")
        end
    end
    
    -- Minimize
    function UI:Minimize()
        self.Elements.Main.Visible = false
        self.Elements.MinButton.Visible = true
        self.Elements.MinButton.Position = UDim2.new(0, self.Elements.Main.AbsolutePosition.X, 
                                                      0, self.Elements.Main.AbsolutePosition.Y)
        self.Minimized = true
    end
    
    -- Restore
    function UI:Restore()
        self.Elements.Main.Visible = true
        self.Elements.MinButton.Visible = false
        self.Minimized = false
    end
    
    -- Make draggable
    function UI:MakeDraggable(dragObj, moveObj)
        local dragging = false
        local dragStart
        local startPos
        
        dragObj.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                dragStart = input.Position
                startPos = moveObj.Position
                
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                    end
                end)
            end
        end)
        
        dragObj.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement then
                if dragging then
                    local delta = input.Position - dragStart
                    moveObj.Position = UDim2.new(
                        startPos.X.Scale,
                        startPos.X.Offset + delta.X,
                        startPos.Y.Scale,
                        startPos.Y.Offset + delta.Y
                    )
                end
            end
        end)
    end
    
    -- Start color animation
    function UI:StartAnimation()
        task.spawn(function()
            local hue = 0
            while self.Elements.Screen and self.Elements.Screen.Parent do
                hue = (hue + 0.002) % 1
                
                if self.Elements.Main then
                    local stroke = self.Elements.Main:FindFirstChild("UIStroke")
                    if stroke then
                        stroke.Color = Color3.fromHSV(hue, 0.8, 1)
                    end
                end
                
                if self.Elements.MinButton then
                    local stroke = self.Elements.MinButton:FindFirstChild("UIStroke")
                    if stroke then
                        stroke.Color = Color3.fromHSV(hue, 0.8, 1)
                    end
                end
                
                task.wait(0.03)
            end
        end)
    end
    
    -- Destroy UI
    function UI:Destroy()
        self.Elements.Screen:Destroy()
        Core.State.Active = false
        getgenv().MizukageV11Loaded = false
    end
    
    -- Create the UI
    UI:Create()
    
    return UI
end
