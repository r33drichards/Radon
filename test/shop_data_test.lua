-- Reproduces the "no products displayed" path with the REAL Radon modules
-- (products.lua, ScanInventory, Pricing) under a stubbed CC/turtle world.
-- getCategories/getDisplayedProducts are inlined from util/renderHelpers.lua
-- (verbatim) because the real module pulls in fonts -> encoded res modules
-- that only exist in the built bundle.
package.path = "./?.lua;./?/init.lua;" .. package.path

-- ---- stubbed CC world --------------------------------------------------
local TURTLE_INV = {} -- set per-scenario
_G.turtle = {
    getItemDetail = function(slot, _detailed)
        return TURTLE_INV[slot]
    end,
}
_G.peripheral = {
    getNames = function() return {} end,
    getMethods = function() return {} end,
    getName = function() return "?" end,
    call = function() error("peripheral.call should not run for self-stock") end,
}
_G.parallel = { waitForAll = function(...) for _, f in ipairs({ ... }) do f() end end }
_G.textutils = { serialize = tostring, unserialize = function() return nil end }
_G.os = { epoch = function() return 0 end }
_G.print = function() end

local Scan = require("core.inventory.ScanInventory")
local Pricing = require("core.Pricing")
Scan.setSelfStock(true)
Pricing.setPricing({ enabled = true, targetStock = 1024, exponent = 0.5, floor = 0.01, ceiling = 0.02, round = 0.01 })

-- ---- inlined from util/renderHelpers.lua (data-only) -------------------
local function getCategories(products)
    local categories = {}
    for _, product in ipairs(products) do
        local category = product.category
        if not category then category = "*" end
        local found = nil
        for i = 1, #categories do
            if categories[i].name == category then found = i break end
        end
        if not found then
            if category == "*" then
                table.insert(categories, 1, { name = category, products = {} })
                found = 1
            else
                table.insert(categories, { name = category, products = {} })
                found = #categories
            end
        end
        table.insert(categories[found].products, product)
    end
    return categories
end

local function getDisplayedProducts(allProducts, settings, currency)
    local displayed = {}
    for i = 1, #allProducts do
        local product = allProducts[i]
        local productPrice = Pricing.getProductPrice(product, currency)
        if (not settings.hideUnavailableProducts or (product.quantity and product.quantity > 0))
            and (not settings.hideNegativePrices or (productPrice and productPrice >= 0)) then
            table.insert(displayed, product)
        end
    end
    return displayed
end

-- ---- the pipeline the monitor actually shows --------------------------
local SETTINGS = { hideUnavailableProducts = false, hideNegativePrices = true }
local CURRENCY = { id = "kromer", value = 1.0 }

local function pipeline()
    local products = dofile("./products.lua") -- auto-gen from turtle
    Scan.updateProductInventory(products)     -- self-stock quantities
    local categories = getCategories(products)
    local selectedCategory = 1
    local shopProducts = {}
    if categories[selectedCategory] then
        shopProducts = getDisplayedProducts(categories[selectedCategory].products, SETTINGS, CURRENCY)
    end
    return products, categories, shopProducts
end

local function show(label)
    local products, categories, shopProducts = pipeline()
    io.write(string.format("[%s]\n", label))
    io.write(string.format("  products.lua generated : %d\n", #products))
    io.write(string.format("  categories             : %d  (selected #1 = %s)\n",
        #categories, categories[1] and categories[1].name or "<none>"))
    io.write(string.format("  shopProducts (DISPLAYED): %d\n", #shopProducts))
    for _, p in ipairs(shopProducts) do
        io.write(string.format("    - %s  qty=%s  price=%.2f\n", p.address, tostring(p.quantity),
            Pricing.getProductPrice(p, CURRENCY)))
    end
    io.write("\n")
    return #shopProducts
end

-- Scenario A: kelp in the turtle, current products.lua -> SHOULD show.
TURTLE_INV = { [1] = { name = "minecraft:kelp", count = 64, displayName = "Kelp" } }
local a = show("A: kelp in turtle (expected: 1 product)")

-- Scenario B: empty turtle -> reproduces grey/no-products.
TURTLE_INV = {}
local b = show("B: empty turtle at startup (expected: 0 products = grey)")

print(string.format("RESULT: A=%d shown, B=%d shown", a, b))
assert(a == 1, "BUG: kelp did not reach the display pipeline")
assert(b == 0, "control: empty turtle should show nothing")
print("DATA PATH OK -> 'no products' == empty product list (turtle empty at boot or stale products.lua)")
