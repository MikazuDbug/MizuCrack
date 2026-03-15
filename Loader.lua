-- ============================================
-- 🌊 MIZUKAGE V11 - OMNI LOADER
-- https://github.com/MikazuDbug/MizuCrack
-- ============================================

-- Anti double-run
if getgenv().MizukageV11Loaded then
    warn("⚠️ Mizukage V11 already loaded!")
    return
end
getgenv().MizukageV11Loaded = true

-- Environment check
local Executor = {
    syn = syn and true,
    fluxus = fluxus and true,
    krnl = iskrnl and true,
    scriptware = is_sirhurt and true
}

print([[
    ╔══════════════════════════════════════╗
    ║     🌊 MIZUKAGE V11 ENGINE           ║
    ║     Advanced Network Toolkit          ║
    ║     Loading modules...                ║
    ╚══════════════════════════════════════╝
]])

-- Module system
local Modules = {}
local Loader = {
    Version = "V11.0",
    Path = "MizukageV11/",
    Dependencies = {
        Core = {},
        Network = {"Core"},
        UI = {"Core"},
        Security = {"Core"},
        Tools = {"Core", "Network"}
    }
}

-- Module loader dengan dependency resolution
function Loader:Require(moduleName)
    if Modules[moduleName] then
        return Modules[moduleName]
    end
    
    -- Load dependencies first
    if self.Dependencies[moduleName] then
        for _, dep in ipairs(self.Dependencies[moduleName]) do
            self:Require(dep)
        end
    end
    
    -- Load module
    local success, module = pcall(function()
        local code = self:GetModuleCode(moduleName)
        return loadstring(code)()
    end)
    
    if success and module then
        Modules[moduleName] = module
        print("✅ Loaded: " .. moduleName)
        return module
    else
        warn("❌ Failed to load: " .. moduleName .. " - " .. tostring(module))
        return nil
    end
end

-- Module code storage (akan diisi dari file lain)
function Loader:GetModuleCode(moduleName)
    local codes = {
        Core = core_code,          -- Dari core.lua
        Network = network_code,      -- Dari network/sniffer.lua
        UI = ui_code,               -- Dari ui/main.lua
        Security = security_code,    -- Dari security/stealth.lua
        Tools = tools_code          -- Dari tools/scanner.lua
    }
    return codes[moduleName] or ""
end

-- Initialize
function Loader:Init()
    print("🔧 Initializing Mizukage " .. self.Version)
    
    -- Load core first
    local Core = self:Require("Core")
    if not Core then
        warn("❌ Core module failed to load!")
        return
    end
    
    -- Load other modules
    self:Require("Network")
    self:Require("UI")
    self:Require("Security")
    self:Require("Tools")
    
    -- Start engine
    Core:Start()
    
    print("✅ Mizukage V11 ready!")
end

-- Run
Loader:Init()
