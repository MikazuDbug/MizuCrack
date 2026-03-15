-- ============================================
-- 🌊 MIZUKAGE COMMAND CONSOLE
-- ============================================

return function()
    local Core = Modules.Core
    local UI = Modules.UI
    
    local Console = {
        Commands = {},
        History = {},
        Aliases = {}
    }
    
    -- Initialize commands
    function Console:Init()
        Core:Log("INFO", "Command console initializing...")
        
        -- Register commands
        self:RegisterCommand("help", "Show this help", function(args)
            local output = {"Available commands:"}
            for name, cmd in pairs(self.Commands) do
                table.insert(output, string.format("  %s - %s", name, cmd.desc))
            end
            return table.concat(output, "\n")
        end)
        
        self:RegisterCommand("stats", "Show statistics", function(args)
            local stats = Core.State
            return string.format([[
=== MIZUKAGE STATS ===
Uptime: %.1fs
Logs: %d
Remotes: %d
Suspicious: %d
Blocked: %d
Recording: OUT=%s IN=%s TAMPER=%s
            ]],
                os.clock() - stats.Stats.StartTime,
                stats.Count,
                Core:TableLength(stats.RemoteStats),
                #stats.Suspicious,
                stats.Stats.Blocked,
                tostring(stats.Recording.Outbound),
                tostring(stats.Recording.Inbound),
                tostring(stats.TamperEnabled)
            )
        end)
        
        self:RegisterCommand("remotes", "List top remotes", function(args)
            local limit = tonumber(args[1]) or 10
            local Network = Modules.Network
            local top = Network:GetTopRemotes(limit)
            
            local output = {"Top Remotes:"}
            for i, r in ipairs(top) do
                table.insert(output, string.format("  %d. %s - %d calls (%.1f/sec)", 
                    i, r.name, r.calls, r.rate))
            end
            
            return table.concat(output, "\n")
        end)
        
        self:RegisterCommand("analyze", "Run pattern analysis", function(args)
            local Analyzer = Modules.Analyzer
            if Analyzer then
                return Analyzer:GenerateReport()
            else
                return "Analyzer not loaded"
            end
        end)
        
        self:RegisterCommand("scan", "Scan for remotes", function(args)
            local Scanner = Modules.Scanner
            if Scanner then
                Scanner:ScanRemotes()
                return "Scan complete. Check logs."
            else
                return "Scanner not loaded"
            end
        end)
        
        self:RegisterCommand("clear", "Clear logs", function(args)
            Core.State.Logs = {}
            Core.State.Count = 0
            return "Logs cleared"
        end)
        
        self:RegisterCommand("export", "Export logs", function(args)
            if UI then
                UI:ExportLogs()
                return "Exporting logs..."
            end
            return "UI not available"
        end)
        
        self:RegisterCommand("toggle", "Toggle features", function(args)
            local feature = args[1]
            if feature == "out" then
                Core.State.Recording.Outbound = not Core.State.Recording.Outbound
                return "Outbound recording: " .. tostring(Core.State.Recording.Outbound)
            elseif feature == "in" then
                Core.State.Recording.Inbound = not Core.State.Recording.Inbound
                return "Inbound recording: " .. tostring(Core.State.Recording.Inbound)
            elseif feature == "tamper" then
                Core.State.TamperEnabled = not Core.State.TamperEnabled
                return "Tamper: " .. tostring(Core.State.TamperEnabled)
            end
            return "Usage: toggle [out/in/tamper]"
        end)
        
        self:RegisterCommand("exit", "Exit Mizukage", function(args)
            Core.State.Active = false
            if UI then
                UI:Destroy()
            end
            return "Goodbye"
        end)
        
        -- Aliases
        self.Aliases = {
            ["?"] = "help",
            ["ls"] = "remotes",
            ["clr"] = "clear",
            ["q"] = "exit"
        }
        
        Core:Log("INFO", "Console ready with " .. self:CountCommands() .. " commands")
    end
    
    -- Register command
    function Console:RegisterCommand(name, desc, handler)
        self.Commands[name] = {
            desc = desc,
            handler = handler
        }
    end
    
    -- Count commands
    function Console:CountCommands()
        local count = 0
        for _ in pairs(self.Commands) do
            count = count + 1
        end
        return count
    end
    
    -- Execute command
    function Console:Execute(input)
        if not input or input == "" then return end
        
        -- Add to history
        table.insert(self.History, input)
        if #self.History > 50 then
            table.remove(self.History, 1)
        end
        
        -- Parse
        local parts = {}
        for part in input:gmatch("%S+") do
            table.insert(parts, part)
        end
        
        local cmdName = parts[1]:lower()
        local args = {table.unpack(parts, 2)}
        
        -- Check alias
        if self.Aliases[cmdName] then
            cmdName = self.Aliases[cmdName]
        end
        
        -- Find and execute
        local cmd = self.Commands[cmdName]
        if cmd then
            local success, result = pcall(cmd.handler, args)
            if success then
                if result then
                    print(result)
                    if UI then
                        UI:AddLog("INFO", "> " .. input)
                        UI:AddLog("INFO", result)
                    end
                end
            else
                warn("Command error: " .. tostring(result))
            end
        else
            print("Unknown command: " .. cmdName)
        end
    end
    
    -- Create console UI
    function Console:CreateUI(parent)
        local frame = Instance.new("Frame", parent)
        frame.Size = UDim2.new(1, 0, 0, 100)
        frame.Position = UDim2.new(0, 0, 1, -100)
        frame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
        frame.BackgroundTransparency = 0.3
        frame.BorderSizePixel = 0
        
        -- Input box
        local input = Instance.new("TextBox", frame)
        input.Size = UDim2.new(1, -10, 0, 30)
        input.Position = UDim2.new(0, 5, 1, -35)
        input.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        input.Text = ""
        input.PlaceholderText = "Enter command..."
        input.TextColor3 = Color3.fromRGB(200, 200, 200)
        input.Font = Enum.Font.Code
        input.TextSize = 12
        input.ClearTextOnFocus = false
        
        -- Corner
        local corner = Instance.new("UICorner", input)
        corner.CornerRadius = UDim.new(0, 4)
        
        -- Output area
        local output = Instance.new("TextLabel", frame)
        output.Size = UDim2.new(1, -10, 0, 60)
        output.Position = UDim2.new(0, 5, 0, 5)
        output.BackgroundTransparency = 1
        output.Text = "Console ready. Type 'help'"
        output.TextColor3 = Color3.fromRGB(150, 255, 150)
        output.Font = Enum.Font.Code
        output.TextSize = 11
        output.TextXAlignment = Enum.TextXAlignment.Left
        output.TextYAlignment = Enum.TextYAlignment.Top
        output.RichText = true
        
        -- Handle enter
        input.FocusLost:Connect(function(enterPressed)
            if enterPressed and input.Text ~= "" then
                self:Execute(input.Text)
                input.Text = ""
            end
        end)
        
        self.UI = {
            Frame = frame,
            Input = input,
            Output = output
        }
    end
    
    -- Initialize
    Console:Init()
    
    return Console
end
