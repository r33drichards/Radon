-- diag.lua -- run this on the turtle to debug "no products".
-- Prints what's physically in the turtle and what products.lua generates.
term.clear()
term.setCursorPos(1, 1)

print("== TURTLE INVENTORY ==")
local any = false
for i = 1, 16 do
    local d = turtle and turtle.getItemDetail and turtle.getItemDetail(i, true)
    if d then
        any = true
        print(i .. ": " .. tostring(d.name) .. " x" .. tostring(d.count))
    end
end
if not any then print("  (turtle is EMPTY -- this is why no products show)") end

print("")
print("== products.lua OUTPUT ==")
local fn, err = loadfile("products.lua")
if not fn then
    print("  CANNOT LOAD products.lua: " .. tostring(err))
else
    local ok, p = pcall(fn)
    if not ok then
        print("  ERROR running products.lua: " .. tostring(p))
    else
        print("  products generated: " .. tostring(#p))
        for _, x in ipairs(p) do
            print("   - " .. tostring(x.address) .. " <- " .. tostring(x.modid) .. " @ " .. tostring(x.price))
        end
        if #p == 0 then
            print("  (0 products -> shop will look empty/grey)")
        end
    end
end
