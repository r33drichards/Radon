-- Loads the REAL config.lua + configDefaults.lua + products.lua and runs the
-- REAL validators -- reproducing exactly how radon.lua decides config.ready.
-- If this reports errors, config.ready=false -> shop shows the blank/grey
-- "Waiting on config..." state even with kryptonReady mocked true.
package.path = "./?.lua;./?/init.lua;" .. package.path

-- CC colors must be exact powers of two 1..32768 to pass the "color" check.
_G.colors = {
    white = 1, orange = 2, magenta = 4, lightBlue = 8, yellow = 16, lime = 32,
    pink = 64, gray = 128, lightGray = 256, cyan = 512, purple = 1024,
    blue = 2048, brown = 4096, green = 8192, red = 16384, black = 32768,
}
_G.turtle = { getItemDetail = function(s)
    local inv = { [1] = { name = "minecraft:dried_kelp_block", count = 64, displayName = "Dried Kelp Block" } }
    return inv[s]
end }
_G.peripheral = { getType = function() return nil end, getMethods = function() return nil end, getNames = function() return {} end }
_G.fs = { exists = function() return false end, isDir = function() return false end }
_G.textutils = { serialize = tostring }
_G.os = { epoch = function() return 0 end }

local configDefaults = dofile("./configDefaults.lua")
local config = dofile("./config.lua")
local products = dofile("./products.lua")
local configHelpers = require("util.configHelpers")
local ConfigValidator = require("core.ConfigValidator")

configHelpers.loadDefaults(config, configDefaults)

-- BEFORE credentials: reproduces the grey (pkey missing -> config.ready false)
local before = ConfigValidator.validateConfig(config)
print("pkey before credentials: " .. tostring(config.currencies[1].pkey)
    .. "  errors=" .. tostring(type(before) == "table" and before[1] and #before or 0))

-- radon runs this between loadDefaults and validation:
require("util.credentials").ensureCredentials(config)
print("pkey after credentials : " .. tostring(config.currencies[1].pkey) .. " (mockKromer="
    .. tostring(config.settings.mockKromer) .. ")")

local configErrors = ConfigValidator.validateConfig(config)
local productsErrors = ConfigValidator.validateProducts(products)

local function dump(label, errs)
    if type(errs) == "table" and errs[1] then
        print(label .. ": " .. #errs .. " ERROR(S)")
        for _, e in ipairs(errs) do
            print("   - " .. tostring(e.path) .. " : " .. tostring(e.error))
        end
        return #errs
    elseif type(errs) == "table" and next(errs) then
        print(label .. ": " .. tostring(errs.path) .. " : " .. tostring(errs.error))
        return 1
    else
        print(label .. ": none")
        return 0
    end
end

print("products generated: " .. #products)
local c = dump("configErrors", configErrors)
local p = dump("productsErrors", productsErrors)

local ready = not ((configErrors and #configErrors > 0) or (productsErrors and #productsErrors > 0))
print("")
print("=> config.ready would be: " .. tostring(ready))
if not ready then
    print(">> THIS is the grey: config.ready=false -> 'Waiting on config...' state")
end
