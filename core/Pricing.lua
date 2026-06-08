-- Pricing.lua
--
-- getProductPrice is the single source of truth for price across Radon: the
-- product list render, the render helpers, AND the purchase charge in
-- ShopState all call it. So applying the supply (stock) curve here makes the
-- displayed price and the charged price identical automatically.
--
-- Stock curve (supply-only dynamic pricing):
--   price = clamp( base * (targetStock / stock) ^ exponent, floor, ceiling )
-- rounded to `round`. Lots of stock -> price sits at the floor; as stock runs
-- low the price climbs, capped at the ceiling. Stateless: computed purely from
-- the current stock each call, so it can't oscillate and needs no save file.

local pricingCfg = nil

local function setPricing(cfg)
    pricingCfg = cfg
end

local function round(value, step)
    if not step or step <= 0 then
        return value
    end
    return math.floor(value / step + 0.5) * step
end

local function applyStockCurve(basePrice, product)
    local cfg = pricingCfg
    if not cfg or not cfg.enabled then
        return basePrice
    end
    local stock = product.quantity
    if type(stock) ~= "number" then
        return basePrice -- no stock info yet (e.g. before first scan): leave base
    end
    if stock < 1 then
        stock = 1 -- out of stock: price is moot (can't buy), keep it finite
    end

    local target = cfg.targetStock or 64
    local k = cfg.exponent or 0.8
    local price = basePrice * (target / stock) ^ k

    local floor = cfg.floor or basePrice
    local ceiling = cfg.ceiling
    if ceiling and price > ceiling then
        price = ceiling
    end
    if price < floor then
        price = floor
    end

    price = round(price, cfg.round)
    if price < floor then
        price = floor -- never round below the floor
    end
    return price
end

local function getProductPrice(product, currency)
    local price = product.price / currency.value
    if product.priceOverrides then
        for i = 1, #product.priceOverrides do
            local override = product.priceOverrides[i]
            if override.currency == currency.id then
                price = override.price
                break
            end
        end
    end
    price = applyStockCurve(price, product)
    return price
end

return {
    getProductPrice = getProductPrice,
    setPricing = setPricing,
}
