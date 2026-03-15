-- ============================================
-- 🌊 MIZUKAGE PATTERN ANALYZER
-- ============================================

return function()
    local Core = Modules.Core
    local Network = Modules.Network
    
    local Analyzer = {
        Patterns = {},
        Detections = {},
        Learning = {
            Enabled = false,
            Baseline = {}
        }
    }
    
    -- Initialize patterns
    function Analyzer:Init()
        Core:Log("INFO", "Pattern analyzer initializing...")
        
        -- Load patterns
        self.Patterns = {
            -- Auto-farm patterns
            AutoFarm = {
                {Name = "FishGiver", Weight = 10},
                {Name = "PrecalcFish", Weight = 10},
                {Name = "CastReplication.*CleanupCast", Weight = 15, Sequence = true},
                {Name = "SellFish.*Buy.*", Weight = 8, Sequence = true}
            },
            
            -- Exploit patterns
            Exploit = {
                {Name = "Damage", Weight = 8, Mod = "Damage multiplier"},
                {Name = "Reward.*1000", Weight = 12},
                {Name = "Buy.*-", Weight = 10, Mod = "Negative values"}
            },
            
            -- Injection patterns
            Injection = {
                {Name = "LoadString", Weight = 20},
                {Name = "Require.*rbxasset", Weight = 15},
                {Name = "ReplicatePullAlert.*%d+", Weight = 12}
            },
            
            -- Spam patterns
            Spam = {
                {Name = "Rate > 50/sec", Weight = 8},
                {Name = "Same remote > 100 in 5s", Weight = 10}
            }
        }
        
        Core:Log("INFO", "Loaded " .. self:CountPatterns() .. " patterns")
    end
    
    -- Count patterns
    function Analyzer:CountPatterns()
        local count = 0
        for category, patterns in pairs(self.Patterns) do
            count = count + #patterns
        end
        return count
    end
    
    -- Analyze a remote call
    function Analyzer:Analyze(remoteName, direction, args, timestamp)
        local score = 0
        local matches = {}
        
        -- Check each category
        for category, patterns in pairs(self.Patterns) do
            for _, pattern in ipairs(patterns) do
                if self:MatchPattern(remoteName, pattern, args) then
                    score = score + pattern.Weight
                    table.insert(matches, {
                        category = category,
                        pattern = pattern.Name,
                        weight = pattern.Weight
                    })
                    
                    -- Record detection
                    self:RecordDetection(category, remoteName, pattern)
                end
            end
        end
        
        -- Alert if high score
        if score > 20 then
            Core:DetectSuspicious("PATTERN", remoteName, 
                string.format("High score: %d (%d patterns)", score, #matches))
        end
        
        return {
            score = score,
            matches = matches,
            timestamp = timestamp
        }
    end
    
    -- Match pattern
    function Analyzer:MatchPattern(remoteName, pattern, args)
        -- Simple name match
        if not pattern.Sequence then
            return remoteName:lower():match(pattern.Name:lower())
        end
        
        -- Sequence detection (simplified)
        local recent = self:GetRecentRemotes(5)
        local sequence = pattern.Name:lower()
        
        for i, r in ipairs(recent) do
            if sequence:match(r.name:lower()) then
                return true
            end
        end
        
        return false
    end
    
    -- Get recent remotes
    function Analyzer:GetRecentRemotes(count)
        local recent = {}
        local logs = Core.State.Logs
        
        for i = #logs, math.max(1, #logs - count + 1), -1 do
            if logs[i].data then
                table.insert(recent, {
                    name = logs[i].data.name,
                    time = logs[i].time
                })
            end
        end
        
        return recent
    end
    
    -- Record detection
    function Analyzer:RecordDetection(category, remote, pattern)
        local detection = {
            time = os.clock(),
            category = category,
            remote = remote,
            pattern = pattern.Name
        }
        
        table.insert(self.Detections, detection)
        
        -- Trim if too many
        if #self.Detections > 100 then
            table.remove(self.Detections, 1)
        end
    end
    
    -- Get statistics
    function Analyzer:GetStats()
        local stats = {
            totalDetections = #self.Detections,
            byCategory = {},
            topRemotes = {}
        }
        
        -- Count by category
        for _, d in ipairs(self.Detections) do
            stats.byCategory[d.category] = (stats.byCategory[d.category] or 0) + 1
        end
        
        -- Get top remotes from core
        local remotes = Core.State.RemoteStats
        local top = {}
        for name, data in pairs(remotes) do
            table.insert(top, {name = name, calls = data.calls})
        end
        
        table.sort(top, function(a, b) return a.calls > b.calls end)
        
        for i = 1, math.min(5, #top) do
            table.insert(stats.topRemotes, top[i])
        end
        
        return stats
    end
    
    -- Generate report
    function Analyzer:GenerateReport()
        local stats = self:GetStats()
        local report = {}
        
        table.insert(report, "╔══════════════════════════════════════╗")
        table.insert(report, "║     MIZUKAGE ANALYSIS REPORT        ║")
        table.insert(report, "╚══════════════════════════════════════╝")
        table.insert(report, "")
        table.insert(report, "📊 STATISTICS")
        table.insert(report, string.format("   Total Detections: %d", stats.totalDetections))
        table.insert(report, "")
        
        table.insert(report, "📈 DETECTIONS BY CATEGORY")
        for cat, count in pairs(stats.byCategory) do
            table.insert(report, string.format("   %s: %d", cat, count))
        end
        table.insert(report, "")
        
        table.insert(report, "🔥 TOP REMOTES")
        for i, remote in ipairs(stats.topRemotes) do
            table.insert(report, string.format("   %d. %s (%d calls)", i, remote.name, remote.calls))
        end
        
        return table.concat(report, "\n")
    end
    
    -- Initialize
    Analyzer:Init()
    
    return Analyzer
end
