-- Drives the REAL ShopState through mockKromer to prove that, once "connected",
-- the kelp product reaches the display pipeline -- isolating the grey bug to
-- the connection (kryptonReady) rather than products/render.
-- getCategories/getDisplayedProducts are inlined from util/renderHelpers.lua
-- (the real module pulls in fonts -> encoded res only present in the bundle).
package.path = "./?.lua;./?/init.lua;" .. package.path

-- ---- stubbed CC world --------------------------------------------------
local TURTLE_INV = { [1] = { name = "minecraft:dried_kelp_block", count = 64, displayName = "Dried Kelp Block" } }
_G.turtle = { getItemDetail = function(s) return TURTLE_INV[s] end }
_G.peripheral = { getNames = function() return {} end, getMethods = function() return {} end,
                  getName = function() return "?" end, call = function() error("no peripheral.call in mock") end }
_G.parallel = { waitForAll = function(...) for _, f in ipairs({ ... }) do f() end end }
_G.textutils = { serialize = tostring, unserialize = function() return nil end, serializeJSON = tostring }
local queued = {}
_G.os = { epoch = function() return 0 end, queueEvent = function(e) queued[#queued + 1] = e end, time = function() return 0 end }
_G.sleep = function() end
_G.bit32 = _G.bit32 or { band = function() return 0 end, bxor = function() return 0 end, lshift = function() return 0 end, rshift = function() return 0 end }

local ShopState = require("core.ShopState").ShopState
local Pricing = require("core.Pricing")
Pricing.setPricing({ enabled = true, targetStock = 1024, exponent = 0.5, floor = 0.01, ceiling = 0.02, round = 0.01 })
require("core.inventory.ScanInventory").setSelfStock(true)

-- ---- inlined display filter (verbatim logic) --------------------------
local function getCategories(products)
    local categories = {}
    for _, product in ipairs(products) do
        local category = product.category or "*"
        local found
        for i = 1, #categories do if categories[i].name == category then found = i break end end
        if not found then
            if category == "*" then table.insert(categories, 1, { name = category, products = {} }) found = 1
            else table.insert(categories, { name = category, products = {} }) found = #categories end
        end
        table.insert(categories[found].products, product)
    end
    return categories
end
local function getDisplayedProducts(all, settings, currency)
    local out = {}
    for i = 1, #all do
        local p = all[i]
        local price = Pricing.getProductPrice(p, currency)
        if (not settings.hideUnavailableProducts or (p.quantity and p.quantity > 0))
            and (not settings.hideNegativePrices or (price and price >= 0)) then
            table.insert(out, p)
        end
    end
    return out
end

-- ---- build a shop and run the mock connection -------------------------
local config = {
    settings = { selfStock = true, mockKromer = true, hideUnavailableProducts = false, hideNegativePrices = true },
    pricing = { enabled = true, targetStock = 1024, exponent = 0.5, floor = 0.01, ceiling = 0.02, round = 0.01 },
    currencies = { { id = "kromer", node = "https://kromer.reconnected.cc/api/krist/", pkey = "x", pkeyFormat = "raw", value = 1.0 } },
}
local products = { { modid = "minecraft:dried_kelp_block", name = "Dried Kelp Block", address = "dried_kelp_block", price = 0.01 } }

local shop = ShopState.new(config, products, {}, "test", {}, {})

-- SCENARIO 1: grey -- before connection, the render gate is false
local config_ready = true
print("scenario grey  : config.ready=" .. tostring(config_ready) .. " kryptonReady=" .. tostring(shop.kryptonReady)
    .. " -> render shop? " .. tostring(config_ready and shop.kryptonReady and true or false))
assert(not (config_ready and shop.kryptonReady), "expected grey before connect")

-- SCENARIO 2: connected via MOCK
shop:setupKrypton()
local cur = shop.currencies[1]
print("after mock setupKrypton: kryptonReady=" .. tostring(shop.kryptonReady)
    .. " currencySymbol=" .. tostring(cur.krypton.currency.currency_symbol)
    .. " host=" .. tostring(cur.host) .. " radon_ready queued=" .. tostring(queued[1]))
assert(shop.kryptonReady == true, "mock should set kryptonReady")
assert(cur.krypton.currency.currency_symbol == "KRO", "mock currency symbol")

Pricing.setPricing(config.pricing)
require("core.inventory.ScanInventory").updateProductInventory(products)
local cats = getCategories(products)
local shopProducts = cats[1] and getDisplayedProducts(cats[1].products, config.settings, cur) or {}
print("render gate now: config.ready and kryptonReady = " .. tostring(config_ready and shop.kryptonReady))
print("shopProducts displayed: " .. #shopProducts)
for _, p in ipairs(shopProducts) do
    print(string.format("   - %s qty=%s price=%.2f", p.address, tostring(p.quantity), Pricing.getProductPrice(p, cur)))
end
assert(config_ready and shop.kryptonReady, "connected scenario should pass render gate")
assert(#shopProducts == 1, "kelp must display once connected")
print("\nPASS: mock-connected -> 1 product displays. Grey == kryptonReady false == real connection.")
