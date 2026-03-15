-- ============================================
-- 🌊 MIZUKAGE NETWORK SNIFFER
-- ============================================

return function()
    local Core = Modules.Core
    if not Core then error("Core module required") end
    
    local Network = {
        Hooks = {},
        InboundConnections = {},
        OutboundHook = nil,
        Blacklist = {"kick", "ban", "report", "crash", "anticheat"},
        Whitelist = {"mouse", "camera", "move", "walk", "heartbeat"},
        TamperRules = {}
    }
    
    -- Initialize
    function Network:Init()
        Core:Log("INFO", "Network sniffer initializing...")
        
        -- Setup tamper rules
        self.TamperRules = {
            {Pattern = "damage", Mod = function(args) 
                if type(args[1]) == "number" then args[1] = math.huge end
                return args
            end},
            {Pattern = "buy", Mod = function(args)
                if type(args[1]) == "number" then args[1] = -math.huge end
                return args
            end},
            {Pattern = "sell", Mod = function(args)
                if type(args[1]) == "number" then args[1] = math.huge end
                return args
            end},
            {Pattern = "reward", Mod = function(args)
                if type(args[1]) == "number" then args[1] = args[1] * 100 end
                return args
            end}
        }
        
        -- Start sniffing
        self:SetupOutboundHook()
        self:SetupInboundListener()
        
        Core:Log("INFO", "Network sniffer ready")
    end
    
    -- Check if ignored
    function Network:IsIgnored(name)
        local low = name:lower()
        for _, v in ipairs(self.Whitelist) do
            if low:match(v) then return true end
        end
        return false
    end
    
    -- Check if blocked
    function Network:IsBlocked(name)
        local low = name:lower()
        for _, v in ipairs(self.Blacklist) do
            if low:match(v) then return true end
        end
        return false
    end
    
    -- Outbound hook (Client -> Server)
    function Network:SetupOutboundHook()
        local oldNamecall
        oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
            local method = getnamecallmethod()
            
            if not checkcaller() and (method == "FireServer" or method == "InvokeServer") then
                local remoteName = tostring(self)
                
                -- Track in core
                Core:TrackRemote(remoteName, "OUT", getcallingscript and getcallingscript().Name)
                
                -- Block check
                if self:IsBlocked(remoteName) then
                    Core.State.Stats.Blocked = Core.State.Stats.Blocked + 1
                    Core:Log("WARN", "Blocked: " .. remoteName)
                    return method == "InvokeServer" and nil or nil
                end
                
                -- Record if enabled
                local args = table.pack(...)
                
                if Core.State.Recording.Outbound and not self:IsIgnored(remoteName) then
                    task.spawn(function()
                        local serialized = Core:Serialize(args)
                        Core:Log("INFO", string.format("[OUT] %s | %s", remoteName, serialized))
                    end)
                end
                
                -- Apply tamper if enabled
                if Core.State.TamperEnabled then
                    for _, rule in ipairs(self.TamperRules) do
                        if remoteName:lower():match(rule.Pattern) then
                            args = rule.Mod(args)
                            Core:Log("INFO", "Tampered: " .. remoteName .. " with " .. rule.Pattern)
                        end
                    end
                end
                
                return oldNamecall(self, table.unpack(args, 1, args.n))
            end
            
            return oldNamecall(self, ...)
        end)
        
        self.OutboundHook = oldNamecall
        Core:Log("INFO", "Outbound hook installed")
    end
    
    -- Inbound listener (Server -> Client)
    function Network:SetupInboundListener()
        -- Clear old connections
        for _, conn in ipairs(self.InboundConnections) do
            conn:Disconnect()
        end
        self.InboundConnections = {}
        
        -- Attach to existing remotes
        local function AttachToRemote(remote)
            if remote:IsA("RemoteEvent") then
                local connection = remote.OnClientEvent:Connect(function(...)
                    if Core.State.Recording.Inbound and not self:IsIgnored(remote.Name) then
                        local args = table.pack(...)
                        
                        task.spawn(function()
                            Core:TrackRemote(remote.Name, "IN", "SERVER")
                            local serialized = Core:Serialize(args)
                            Core:Log("INFO", string.format("[IN] %s | %s", remote.Name, serialized))
                            
                            -- Pattern detection
                            self:DetectPatterns(remote.Name, args)
                        end)
                    end
                end)
                table.insert(self.InboundConnections, connection)
            end
        end
        
        -- Scan existing
        for _, v in ipairs(game:GetDescendants()) do
            pcall(AttachToRemote, v)
        end
        
        -- Listen for new remotes
        table.insert(self.InboundConnections, game.DescendantAdded:Connect(function(v)
            pcall(AttachToRemote, v)
        end))
        
        Core:Log("INFO", "Inbound listener installed")
    end
    
    -- Pattern detection
    function Network:DetectPatterns(remoteName, args)
        -- Auto-farm detection
        if remoteName:match("FishGiver") or remoteName:match("PrecalcFish") then
            Core:DetectSuspicious("AUTOFARM", remoteName, "Farming remote triggered")
        end
        
        -- Economy exploit detection
        if remoteName:match("Sell") or remoteName:match("Buy") then
            if args[1] and type(args[1]) == "number" and args[1] > 1000000 then
                Core:DetectSuspicious("ECONOMY", remoteName, "Large value: " .. args[1])
            end
        end
        
        -- Asset injection detection
        if remoteName:match("ReplicatePullAlert") or remoteName:match("LoadAsset") then
            Core:DetectSuspicious("INJECTION", remoteName, "Asset load triggered")
        end
    end
    
    -- Get remote stats
    function Network:GetStats()
        return Core.State.RemoteStats
    end
    
    -- Get top remotes
    function Network:GetTopRemotes(limit)
        limit = limit or 10
        local list = {}
        
        for name, data in pairs(Core.State.RemoteStats) do
            table.insert(list, {
                name = name,
                calls = data.calls,
                rate = data.calls / (data.last - data.first + 1)
            })
        end
        
        table.sort(list, function(a, b) return a.calls > b.calls end)
        
        local top = {}
        for i = 1, math.min(limit, #list) do
            table.insert(top, list[i])
        end
        
        return top
    end
    
    -- Cleanup
    function Network:Cleanup()
        for _, conn in ipairs(self.InboundConnections) do
            conn:Disconnect()
        end
        self.InboundConnections = {}
        Core:Log("INFO", "Network sniffer cleaned up")
    end
    
    -- Initialize
    Network:Init()
    
    return Network
end
