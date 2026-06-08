-- Loads the REAL DefaultLayout (with fonts/canvas) and calls render() with a
-- mock shop state, to catch a layout-time crash that would blank the monitor.
package.path = "./?.lua;./?/init.lua;" .. package.path

-- ---- CC environment stubs ---------------------------------------------
_G.colors = { white=1, orange=2, magenta=4, lightBlue=8, yellow=16, lime=32, pink=64,
    gray=128, lightGray=256, cyan=512, purple=1024, blue=2048, brown=4096, green=8192,
    red=16384, black=32768 }
_G.keys = {}
_G.bit32 = _G.bit32 or { band=function(a,b) return 0 end, bor=function() return 0 end,
    bxor=function() return 0 end, lshift=function() return 0 end, rshift=function() return 0 end,
    extract=function() return 0 end }
_G.textutils = { serialize=tostring, serializeJSON=tostring, unserialize=function() end }
_G.os = { epoch=function() return 0 end, time=function() return 0 end, clock=function() return 0 end,
    queueEvent=function() end, startTimer=function() return 1 end }
_G.sleep = function() end
_G.parallel = { waitForAll=function(...) for _,f in ipairs({...}) do f() end end, waitForAny=function() end }

local drawCalls = 0
local function fakeMon()
    local m = {}
    function m.getSize() return 82, 38 end
    function m.setTextScale() end
    function m.getTextScale() return 0.5 end
    function m.isColor() return true end
    function m.isColour() return true end
    function m.setCursorPos() end
    function m.setBackgroundColor() end
    function m.setBackgroundColour() end
    function m.setTextColor() end
    function m.setTextColour() end
    function m.setPaletteColor() drawCalls = drawCalls + 1 end
    function m.setPaletteColour() end
    function m.write() drawCalls = drawCalls + 1 end
    function m.blit() drawCalls = drawCalls + 1 end
    function m.clear() end
    function m.clearLine() end
    function m.getCursorPos() return 1,1 end
    return m
end
_G.term = fakeMon()
_G.peripheral = { find=function() return fakeMon() end, getName=function() return "monitor_0" end,
    wrap=function() return fakeMon() end, getType=function() return "monitor" end }
_G.fs = { exists=function() return false end, isDir=function() return false end,
    open=function() return nil end }
_G.window = { create=function() return fakeMon() end }

print("loading DefaultLayout...")
local ok, render = pcall(require, "DefaultLayout")
if not ok then print("LOAD FAILED: " .. tostring(render)) return end
print("DefaultLayout loaded OK")

local Display = require("modules.display")
local Pricing = require("core.Pricing")
Pricing.setPricing({ enabled=true, targetStock=1024, exponent=0.5, floor=0.01, ceiling=0.02, round=0.01 })

local theme = dofile("./config.lua").theme
local display = Display.new({ theme = theme, monitor = nil })

local products = { { modid="minecraft:dried_kelp_block", name="Dried Kelp Block",
    address="dried_kelp_block", price=0.01, quantity=243 } }
local props = {
    configState = { config = { ready=true, branding={title="Sustainable Biofuel", subtitle="Space Efficient"},
        settings={ smallTextKristPayCompatability=true, hideUnavailableProducts=false, hideNegativePrices=true },
        theme = theme } },
    shopState = { kryptonReady=true, selectedCurrency={ id="kromer",
        krypton={ currency={ currency_symbol="KRO" } } }, selectedCategory=1, products=products },
    peripherals = {},
}

print("calling render()...")
local rok, rerr = pcall(render, display.bgCanvas, display, props, theme, "1.3.33")
if rok then
    print("RENDER OK -- no crash. Layout computed.")
else
    print("RENDER CRASHED: " .. tostring(rerr))
end
