-- products.lua
--
-- Auto-builds one product per distinct item currently in the TURTLE'S OWN
-- inventory (pairs with settings.selfStock = true). You only set prices below;
-- the item id and display name come from the item itself.
--
-- NOTE: the product list is built when Radon STARTS, from what's in the turtle
-- at that moment. If you add a brand-new TYPE of item later, restart `radon`
-- so it picks it up. (Restocking more of an existing item is fine live.)

-- Price per item id, in KRO. Items not listed here are NOT sold, unless you
-- set DEFAULT_PRICE below. (Skipping unpriced items protects you from
-- accidentally selling something valuable for nothing.)
local prices = {
    ["minecraft:stick"]       = 0.1,
    ["minecraft:lapis_block"] = 9.0,
}

-- Optional: override the auto pay-address (the metaname customers /pay to).
-- Default is the id without its namespace, e.g.
-- "minecraft:lapis_block" -> "lapis_block".
local addresses = {
    -- ["minecraft:lapis_block"] = "lapis",
}

-- Set to a number to sell EVERY item in the turtle at that price even if it
-- isn't in `prices`. Leave nil to only sell items you've priced.
local DEFAULT_PRICE = nil

-- You can still add fully manual products too (categories, predicates,
-- bundles, priceOverrides -- see the README). These are always included.
local manual = {
    -- { modid = "minecraft:diamond_pickaxe", name = "Eff V Pick", address = "dpick",
    --   price = 50.0, predicates = { enchantments = { { displayName = "Efficiency V" } } } },
}

--------------------------------------------------------------------------------
local function defaultAddress(modid)
    return (modid:gsub("^.-:", ""))
end

local products = {}
for _, p in ipairs(manual) do
    products[#products + 1] = p
end

if turtle then
    local seen = {}
    for slot = 1, 16 do
        local detail = turtle.getItemDetail(slot, true)
        if detail and not seen[detail.name] then
            local price = prices[detail.name] or DEFAULT_PRICE
            if price then
                seen[detail.name] = true
                products[#products + 1] = {
                    modid = detail.name,
                    name = detail.displayName or detail.name,
                    address = addresses[detail.name] or defaultAddress(detail.name),
                    price = price,
                }
            end
        end
    end
end

return products
