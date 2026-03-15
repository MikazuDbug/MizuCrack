-- ============================================
-- 🌊 MIZUKAGE CORE ENGINE
-- ============================================

return function()
    local Core = {}
    
    -- Services
    Core.Services = {
        CG = game:GetService("CoreGui"),
        P = game:GetService("Players"),
        HS = game:GetService("HttpService"),
        MS = game:GetService("MarketplaceService"),
        UIS = game:GetService("UserInputService"),
        RS = game:GetService("ReplicatedStorage"),
        TS = game:GetService("TeleportService"),
        SS = game:GetService("Stats")
    }
    
    -- Local Player
    Core.LocalPlayer = Core.Services.P.LocalPlayer
    
    -- Configuration
    Core.Config = {
        Version = "V11",
        Webhook = "https://discord.com/api/webhooks/YOUR_WEBHOOK_HERE",
        MaxLogs = 500,
        StealthMode = true,
        Theme = {
            Main = Color3.fromRGB(10, 12, 18),
            Stroke = Color3.fromRGB(0, 200, 255),
            Outbound = Color3.fromRGB(50, 255, 150),
            Inbound = Color3.fromRGB(255, 80, 80),
            System = Color3.fromRGB(255, 200, 50)
        }
    }
    
    -- State management
    Core.State = {
        Active = true,
        Recording = {
            Outbound = false,
            Inbound = false
        },
        TamperEnabled = true,
        Logs = {},
        Count = 0,
        Stats = {
            Blocked = 0,
            StartTime = os.clock()
        },
        Game = {
            Name = "Unknown",
            ID = game.PlaceId,
            JobId = game.JobId
        },
        -- New: Remote statistics
        RemoteStats = {},
        -- New: Suspicious activities
        Suspicious = {}
    }
    
    -- Get game name
    pcall(function()
        Core.State.Game.Name = Core.Services.MS:GetProductInfo(Core.State.Game.ID).Name
    end)
    
    -- Utility functions
    function Core:Log(level, message, data)
        local logEntry = {
            time = os.clock(),
            level = level,
            message = message,
            data = data
        }
        table.insert(self.State.Logs, logEntry)
        self.State.Count = self.State.Count + 1
        
        -- Console output
        if level == "ERROR" then
            warn("[MIZU] " .. message)
        elseif level == "WARN" then
            warn("[MIZU] ⚠️ " .. message)
        else
            print("[MIZU] " .. message)
        end
        
        return logEntry
    end
    
    -- Track remote usage
    function Core:TrackRemote(name, direction, caller)
        if not self.State.RemoteStats[name] then
            self.State.RemoteStats[name] = {
                calls = 0,
                first = os.clock(),
                last = os.clock(),
                direction = direction,
                callers = {}
            }
        end
        
        local stat = self.State.RemoteStats[name]
        stat.calls = stat.calls + 1
        stat.last = os.clock()
        
        if caller then
            stat.callers[caller] = (stat.callers[caller] or 0) + 1
        end
        
        -- Detect spam
        if stat.calls > 100 and (stat.last - stat.first) < 5 then
            self:DetectSuspicious("SPAM", name, "High frequency: " .. stat.calls .. " calls")
        end
    end
    
    -- Suspicious activity detection
    function Core:DetectSuspicious(type, target, reason)
        local entry = {
            time = os.clock(),
            type = type,
            target = target,
            reason = reason
        }
        table.insert(self.State.Suspicious, entry)
        self:Log("WARN", "Suspicious: " .. reason)
        return entry
    end
    
    -- Deep serialize (enhanced)
    function Core:Serialize(value, depth, visited)
        depth = depth or 0
        visited = visited or {}
        
        if depth > 5 then return "[MAX_DEPTH]" end
        if visited[value] then return "[CYCLIC]" end
        
        local t = typeof(value)
        
        if t == "nil" then
            return "nil"
        elseif t == "boolean" then
            return tostring(value)
        elseif t == "number" then
            return tostring(value)
        elseif t == "string" then
            if #value > 100 then
                return '"' .. value:sub(1, 100) :gsub("\n", "\\n") .. '..."'
            end
            return '"' .. value:gsub("\n", "\\n") .. '"'
        elseif t == "Instance" then
            local name = pcall(function() return value.Name end) and value.Name or "Destroyed"
            return "[Instance:" .. name .. "]"
        elseif t == "table" then
            visited[value] = true
            local items = {}
            local count = 0
            
            for k, v in pairs(value) do
                count = count + 1
                if count > 15 then
                    table.insert(items, "...")
                    break
                end
                table.insert(items, tostring(k) .. "=" .. self:Serialize(v, depth + 1, visited))
            end
            
            return "{" .. table.concat(items, ", ") .. "}"
        else
            return "[" .. t .. "]"
        end
    end
    
    -- Start engine
    function Core:Start()
        self:Log("INFO", "Mizukage " .. self.Config.Version .. " started")
        self:Log("INFO", "Target: " .. self.State.Game.Name .. " [" .. self.State.Game.ID .. "]")
        
        -- Start stats monitor
        task.spawn(function()
            while self.State.Active do
                task.wait(60) -- Every minute
                self:Log("INFO", string.format("Stats - Logs: %d, Remotes: %d, Suspicious: %d",
                    self.State.Count,
                    self:TableLength(self.State.RemoteStats),
                    #self.State.Suspicious
                ))
            end
        end)
    end
    
    -- Helper
    function Core:TableLength(t)
        local count = 0
        for _ in pairs(t) do count = count + 1 end
        return count
    end
    
    return Core
end
